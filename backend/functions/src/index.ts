import { initializeApp } from "firebase-admin/app";
import { FieldValue, Firestore, Transaction, getFirestore } from "firebase-admin/firestore";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";

import {
  ErrorSala,
  Fila,
  Sala,
  aplicarReserva,
  empezar,
  exigirOrganizador,
  generarCartillas,
  generarCodigo,
  ganadoresNuevos,
  siguienteBolilla,
  sinUltima,
  validarNombre,
} from "./logica";

initializeApp();
const db: Firestore = getFirestore();

const FILAS_TOTAL = 20;

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

/** `crearSala({nombre, columnas})` → `{codigo}`. Reparte las 20 cartillas. */
export const crearSala = onCall(async (request) => {
  const uid = uidOrganizador(request);
  const nombre = (() => {
    try {
      return validarNombre((request.data as { nombre?: unknown }).nombre);
    } catch (e) {
      return aHttps(e);
    }
  })();
  const columnas = (request.data as { columnas?: unknown }).columnas === 6 ? 6 : 5;

  for (let intento = 0; intento < 10; intento++) {
    const codigo = generarCodigo();
    const creada = await db.runTransaction(async (t) => {
      const ref = db.collection("salas").doc(codigo);
      if ((await t.get(ref)).exists) return false;
      const sala: Sala = {
        nombre,
        organizadorUid: uid,
        columnas,
        filasTotal: FILAS_TOTAL,
        filasPorJugador: 1,
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

/** `reservarFila({codigo, fila, nombre})`. En transacción: sin dobles reservas. */
export const reservarFila = onCall(async (request) => {
  const uid = uidDe(request);
  const codigo = codigoDe(request.data);
  const { fila, nombre } = request.data as { fila?: unknown; nombre?: unknown };
  try {
    return await db.runTransaction(async (t) => {
      const { ref, sala } = await leerSala(t, codigo);
      const filas = await leerFilas(t, codigo, sala.filasTotal);
      const r = aplicarReserva(sala, filas, Number(fila), uid, nombre);
      t.update(ref.collection("filas").doc(String(fila)), {
        jugadorUid: uid,
        nombre: r.nombre,
        reservadaEn: FieldValue.serverTimestamp(),
      });
      if (r.estado !== sala.estado) t.update(ref, { estado: r.estado });
      return { fila: Number(fila), estado: r.estado };
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
      t.update(ref, { estado: "terminada" });
      return { estado: "terminada" };
    });
  } catch (e) {
    return aHttps(e);
  }
});
