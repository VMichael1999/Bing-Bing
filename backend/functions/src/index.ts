import { initializeApp } from "firebase-admin/app";
import { FieldValue, Firestore, Transaction, getFirestore } from "firebase-admin/firestore";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";

import {
  ErrorSala,
  Fila,
  Sala,
  aplicarReservas,
  cancelar,
  cobrar,
  repartirPremio,
  validarFilasPorJugador,
  validarRecarga,
  CREDITOS_INICIALES,
  empezar,
  exigirOrganizador,
  generarCartillas,
  generarCodigo,
  ganadoresNuevos,
  siguienteBolilla,
  sinUltima,
  validarNombreSala,
  validarPrecioPremio,
  COMISION_PORCENTAJE_POR_DEFECTO,
} from "./logica";

initializeApp();
const db: Firestore = getFirestore();

const FILAS_TOTAL = 20;

/** Comisión de Bing Bing en %: configurable sin tocar el código (por definir). */
const COMISION_PORCENTAJE = (() => {
  const valor = Number(process.env.COMISION_PORCENTAJE);
  return Number.isFinite(valor) && valor >= 0 && valor < 100 ? valor : COMISION_PORCENTAJE_POR_DEFECTO;
})();

// El sorteo y las reservas se resuelven aquí: los clientes solo leen. Las reglas
// de Firestore (`firestore.rules`) prohíben cualquier escritura directa.

/** Convierte un error de negocio en un error que el cliente puede traducir. */
function aHttps(e: unknown): never {
  if (e instanceof ErrorSala) {
    throw new HttpsError("failed-precondition", e.message, { codigo: e.codigo });
  }
  throw e;
}

function uidDe(request: CallableRequest): string {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Hay que iniciar sesión");
  }
  return request.auth.uid;
}

/** Organizar exige cuenta (Google o celular); jugar basta con una sesión anónima. */
function uidOrganizador(request: CallableRequest): string {
  const uid = uidDe(request);
  if (request.auth?.token.firebase.sign_in_provider === "anonymous") {
    throw new HttpsError("permission-denied", "Organizar requiere una cuenta");
  }
  return uid;
}

/** Nombre que ven los jugadores: el de la cuenta de Google, si lo tiene. */
function organizadorNombre(request: CallableRequest): string {
  const nombre = request.auth?.token.name;
  return typeof nombre === "string" && nombre.trim() ? nombre.trim().slice(0, 40) : "quien organiza";
}

function codigoDe(datos: unknown): string {
  const codigo = (datos as { codigo?: unknown } | null)?.codigo;
  if (typeof codigo !== "string" || !/^[A-Z2-9]{4}$/.test(codigo)) {
    throw new HttpsError("invalid-argument", "Código de sala inválido");
  }
  return codigo;
}

async function leerSala(
  t: Transaction,
  codigo: string,
): Promise<{ ref: FirebaseFirestore.DocumentReference; sala: Sala }> {
  const ref = db.collection("salas").doc(codigo);
  const doc = await t.get(ref);
  if (!doc.exists) throw new HttpsError("not-found", "No existe esa sala");
  return { ref, sala: doc.data() as Sala };
}

async function leerFilas(t: Transaction, codigo: string, total: number): Promise<Fila[]> {
  const refs = Array.from({ length: total }, (_, i) =>
    db.collection("salas").doc(codigo).collection("filas").doc(String(i + 1)),
  );
  return (await t.getAll(...refs)).map((d) => d.data() as Fila);
}

/** `crearSala({nombre, columnas, publica})` → `{codigo}`. Reparte las 20 cartillas. */
export const crearSala = onCall(async (request) => {
  const uid = uidOrganizador(request);
  const nombre = (() => {
    try {
      return validarNombreSala((request.data as { nombre?: unknown }).nombre);
    } catch (e) {
      return aHttps(e);
    }
  })();
  const columnas = (request.data as { columnas?: unknown }).columnas === 6 ? 6 : 5;
  // Pública por defecto, como en "Nueva partida".
  const publica = (request.data as { publica?: unknown }).publica !== false;
  const filasPorJugador = (() => {
    try {
      return validarFilasPorJugador(
        (request.data as { filasPorJugador?: unknown }).filasPorJugador,
        FILAS_TOTAL,
      );
    } catch (e) {
      return aHttps(e);
    }
  })();
  const { precioFila, premio } = (() => {
    try {
      const d = request.data as { precioFila?: unknown; premio?: unknown };
      return validarPrecioPremio(d.precioFila, d.premio, FILAS_TOTAL, COMISION_PORCENTAJE);
    } catch (e) {
      return aHttps(e);
    }
  })();

  for (let intento = 0; intento < 10; intento++) {
    const codigo = generarCodigo();
    const creada = await db.runTransaction(async (t) => {
      const ref = db.collection("salas").doc(codigo);
      if ((await t.get(ref)).exists) return false;
      const sala: Sala = {
        nombre,
        organizadorUid: uid,
        organizadorNombre: organizadorNombre(request),
        publica,
        ocupadas: 0,
        precioFila,
        premio,
        comisionPorcentaje: COMISION_PORCENTAJE,
        columnas,
        filasTotal: FILAS_TOTAL,
        filasPorJugador,
        estado: "abierta",
        bolillas: [],
        ganadores: [],
      };
      t.set(ref, { ...sala, creadaEn: FieldValue.serverTimestamp() });
      generarCartillas(FILAS_TOTAL, columnas).forEach((numeros, i) => {
        t.set(ref.collection("filas").doc(String(i + 1)), { numeros });
      });
      return true;
    });
    if (creada) return { codigo };
  }
  throw new HttpsError("resource-exhausted", "No se pudo crear la sala, intenta de nuevo");
});

/** La billetera de una cuenta: `billeteras/{uid}` con su saldo y sus movimientos. */
const billetera = (uid: string) => db.collection("billeteras").doc(uid);

type TipoMovimiento = "regalo" | "recarga" | "fila" | "devolucion" | "premio";

/** Anota un movimiento en el historial de la billetera (dentro de la transacción). */
function anotar(
  t: Transaction,
  uid: string,
  mov: { tipo: TipoMovimiento; monto: number; detalle: string; sala?: string },
): void {
  t.set(billetera(uid).collection("movimientos").doc(), {
    ...mov,
    creadaEn: FieldValue.serverTimestamp(),
  });
}

/** Lee el saldo; si la cuenta no tiene billetera, nace con los créditos de prueba. */
async function leerSaldo(t: Transaction, uid: string): Promise<{ saldo: number; nueva: boolean }> {
  const doc = await t.get(billetera(uid));
  if (doc.exists) return { saldo: Number((doc.data() as { saldo: number }).saldo), nueva: false };
  return { saldo: CREDITOS_INICIALES, nueva: true };
}

/** Escribe el saldo nuevo (y el regalo de bienvenida si la billetera acaba de nacer). */
function guardarSaldo(t: Transaction, uid: string, saldo: number, nueva: boolean): void {
  if (nueva) {
    anotar(t, uid, { tipo: "regalo", monto: CREDITOS_INICIALES, detalle: "Créditos de bienvenida" });
  }
  t.set(billetera(uid), { saldo, actualizadaEn: FieldValue.serverTimestamp() });
}

/** Elegir fila con precio exige una cuenta: sin ella no hay billetera. */
function exigirCuenta(request: CallableRequest): void {
  if (request.auth?.token.firebase.sign_in_provider === "anonymous") {
    throw new HttpsError("permission-denied", "Hace falta iniciar sesión con una cuenta");
  }
}

/**
 * `reservarFilas({codigo, filas: [n…], nombre})`. En transacción y todo o nada:
 * sin dobles reservas y cobrando el precio de cada fila de la billetera. También
 * responde a `reservarFila({codigo, fila, nombre})`.
 */
const manejarReserva = async (request: CallableRequest) => {
  const uid = uidDe(request);
  const codigo = codigoDe(request.data);
  const { filas: varias, fila, nombre } = request.data as {
    filas?: unknown;
    fila?: unknown;
    nombre?: unknown;
  };
  const numeros = varias !== undefined ? varias : [fila];
  try {
    return await db.runTransaction(async (t) => {
      const { ref, sala } = await leerSala(t, codigo);
      const filas = await leerFilas(t, codigo, sala.filasTotal);
      const r = aplicarReservas(sala, filas, numeros, uid, nombre);
      let saldo: number | null = null;
      let cobro: { saldo: number; nueva: boolean } | null = null;
      if (r.costo > 0) {
        exigirCuenta(request);
        const actual = await leerSaldo(t, uid);
        cobro = { saldo: cobrar(actual.saldo, r.costo), nueva: actual.nueva };
        saldo = cobro.saldo;
      }
      for (const n of r.numeros) {
        t.update(ref.collection("filas").doc(String(n)), {
          jugadorUid: uid,
          nombre: r.nombre,
          reservadaEn: FieldValue.serverTimestamp(),
        });
      }
      t.update(ref, {
        ocupadas: filas.filter((f) => f.jugadorUid).length + r.numeros.length,
        ...(r.estado !== sala.estado ? { estado: r.estado } : {}),
      });
      if (cobro !== null) {
        guardarSaldo(t, uid, cobro.saldo, cobro.nueva);
        for (const n of r.numeros) {
          anotar(t, uid, {
            tipo: "fila",
            monto: -sala.precioFila,
            detalle: `Fila ${n} · ${sala.nombre}`,
            sala: codigo,
          });
        }
      }
      return { filas: r.numeros, estado: r.estado, costo: r.costo, saldo };
    });
  } catch (e) {
    return aHttps(e);
  }
};
export const reservarFilas = onCall(manejarReserva);
export const reservarFila = onCall(manejarReserva);

/** `obtenerBilletera()` → `{saldo}`. La primera vez regala los créditos de prueba. */
export const obtenerBilletera = onCall(async (request) => {
  const uid = uidDe(request);
  exigirCuenta(request);
  return db.runTransaction(async (t) => {
    const { saldo, nueva } = await leerSaldo(t, uid);
    if (nueva) guardarSaldo(t, uid, saldo, true);
    return { saldo };
  });
});

/** `recargar({monto})`: créditos de prueba que se agregan al instante, sin cobro. */
export const recargar = onCall(async (request) => {
  const uid = uidDe(request);
  exigirCuenta(request);
  try {
    const monto = validarRecarga((request.data as { monto?: unknown }).monto);
    return await db.runTransaction(async (t) => {
      const { saldo, nueva } = await leerSaldo(t, uid);
      guardarSaldo(t, uid, saldo + monto, nueva);
      anotar(t, uid, { tipo: "recarga", monto, detalle: "Recarga" });
      return { saldo: saldo + monto };
    });
  } catch (e) {
    return aHttps(e);
  }
});

/** `empezarPartida({codigo})`: solo el organizador y solo con la cartilla llena. */
export const empezarPartida = onCall(async (request) => {
  const uid = uidOrganizador(request);
  const codigo = codigoDe(request.data);
  try {
    return await db.runTransaction(async (t) => {
      const { ref, sala } = await leerSala(t, codigo);
      const estado = empezar(sala, uid);
      t.update(ref, { estado });
      return { estado };
    });
  } catch (e) {
    return aHttps(e);
  }
});

/** `sacarBolilla({codigo})`: el azar se resuelve aquí y el cliente solo lo anima. */
export const sacarBolilla = onCall(async (request) => {
  const uid = uidOrganizador(request);
  const codigo = codigoDe(request.data);
  try {
    return await db.runTransaction(async (t) => {
      const { ref, sala } = await leerSala(t, codigo);
      const numero = siguienteBolilla(sala, uid);
      const filas = await leerFilas(t, codigo, sala.filasTotal);
      const orden = [...sala.bolillas, numero];
      const ganadoras = ganadoresNuevos(filas.map((f) => f.numeros), orden);
      t.update(ref, {
        bolillas: FieldValue.arrayUnion(numero),
        ...(ganadoras.length > 0
          ? {
              ganadores: FieldValue.arrayUnion(
                ...ganadoras.map((fila) => ({ fila, bolillaIndice: orden.length })),
              ),
            }
          : {}),
      });
      return { numero, indice: orden.length, ganadoras };
    });
  } catch (e) {
    return aHttps(e);
  }
});

/** `deshacerBolilla({codigo})`: devuelve la última bolilla a la tómbola. */
export const deshacerBolilla = onCall(async (request) => {
  const uid = uidOrganizador(request);
  const codigo = codigoDe(request.data);
  try {
    return await db.runTransaction(async (t) => {
      const { ref, sala } = await leerSala(t, codigo);
      const bolillas = sinUltima(sala, uid);
      const ganadores = sala.ganadores.filter((g) => g.bolillaIndice <= bolillas.length);
      t.update(ref, { bolillas, ganadores });
      return { bolillas: bolillas.length };
    });
  } catch (e) {
    return aHttps(e);
  }
});

/** `terminarPartida({codigo})`. */
export const terminarPartida = onCall(async (request) => {
  const uid = uidOrganizador(request);
  const codigo = codigoDe(request.data);
  try {
    return await db.runTransaction(async (t) => {
      const { ref, sala } = await leerSala(t, codigo);
      exigirOrganizador(sala, uid);
      if (sala.estado === "en_juego") {
        // Se paga una sola vez: solo al pasar de en_juego a terminada.
        const filas = await leerFilas(t, codigo, sala.filasTotal);
        const pagos = repartirPremio(sala, filas);
        const cuentas = [...new Set(pagos.map((p) => p.uid))];
        const saldos = new Map<string, { saldo: number; nueva: boolean }>();
        for (const cuenta of cuentas) saldos.set(cuenta, await leerSaldo(t, cuenta));
        for (const cuenta of cuentas) {
          const actual = saldos.get(cuenta);
          if (actual === undefined) continue;
          const mios = pagos.filter((p) => p.uid === cuenta);
          guardarSaldo(t, cuenta, actual.saldo + mios.reduce((a, p) => a + p.monto, 0), actual.nueva);
          for (const p of mios) {
            anotar(t, cuenta, {
              tipo: "premio",
              monto: p.monto,
              detalle:
                p.motivo === "premio"
                  ? `Premio · ${sala.nombre}`
                  : `Lo que sobró · ${sala.nombre}`,
              sala: codigo,
            });
          }
        }
      }
      t.update(ref, { estado: "terminada" });
      return { estado: "terminada" };
    });
  } catch (e) {
    return aHttps(e);
  }
});

/**
 * `cancelarSala({codigo, motivo?})`: quien organiza cierra una sala que no se
 * jugó (por ejemplo, porque no se llenó). Solo antes de empezar. La sala deja de
 * recibir jugadores y de aparecer en la lista; los jugadores ven el aviso.
 */
export const cancelarSala = onCall(async (request) => {
  const uid = uidOrganizador(request);
  const codigo = codigoDe(request.data);
  try {
    return await db.runTransaction(async (t) => {
      const { ref, sala } = await leerSala(t, codigo);
      const motivo = cancelar(sala, uid, (request.data as { motivo?: unknown }).motivo);
      if (sala.estado !== "cancelada") {
        // Cada fila reservada vuelve a su billetera: devolución completa.
        const filas = await leerFilas(t, codigo, sala.filasTotal);
        const porJugador = new Map<string, number[]>();
        filas.forEach((f, i) => {
          if (f.jugadorUid !== undefined) {
            porJugador.set(f.jugadorUid, [...(porJugador.get(f.jugadorUid) ?? []), i + 1]);
          }
        });
        const saldos = new Map<string, { saldo: number; nueva: boolean }>();
        if (sala.precioFila > 0) {
          for (const jugador of porJugador.keys()) saldos.set(jugador, await leerSaldo(t, jugador));
        }
        for (const [jugador, numeros] of porJugador) {
          const actual = saldos.get(jugador);
          if (actual === undefined) continue;
          guardarSaldo(t, jugador, actual.saldo + sala.precioFila * numeros.length, actual.nueva);
          for (const n of numeros) {
            anotar(t, jugador, {
              tipo: "devolucion",
              monto: sala.precioFila,
              detalle: `Devolución · fila ${n} de ${sala.nombre}`,
              sala: codigo,
            });
          }
        }
        t.update(ref, {
          estado: "cancelada",
          motivoCierre: motivo,
          canceladaEn: FieldValue.serverTimestamp(),
        });
      }
      return { estado: "cancelada" };
    });
  } catch (e) {
    return aHttps(e);
  }
});
