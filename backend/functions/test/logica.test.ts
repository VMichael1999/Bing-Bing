import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  ErrorSala,
  Fila,
  Sala,
  aplicarReserva,
  aplicarReservas,
  cobrar,
  repartirPremio,
  validarRecarga,
  validarFilasPorJugador,
  cancelar,
  comision,
  disponibleParaPremio,
  validarPrecioPremio,
  empezar,
  generarCartillas,
  generarCodigo,
  ganadoresNuevos,
  siguienteBolilla,
  sinUltima,
  totalBolillas,
  validarNombre,
  validarNombreSala,
} from "../src/logica";

// Datos del modo demo: las mismas cartillas y bolillas del diseño.
const CARTILLAS = [
  [6, 24, 39, 52, 72], [14, 26, 41, 57, 67], [10, 28, 45, 58, 75],
  [6, 28, 31, 59, 72], [12, 21, 36, 49, 70], [8, 29, 32, 56, 62],
  [4, 16, 44, 58, 75], [10, 20, 40, 60, 64], [10, 27, 33, 53, 74],
  [4, 25, 45, 59, 62], [2, 25, 32, 52, 65], [9, 17, 32, 47, 73],
  [15, 24, 39, 60, 70], [13, 28, 33, 50, 62], [3, 24, 39, 46, 75],
  [10, 29, 44, 57, 63], [3, 26, 39, 46, 69], [12, 20, 31, 58, 67],
  [8, 21, 36, 49, 67], [13, 19, 41, 47, 62],
];
const ORDEN = [
  36, 40, 57, 64, 14, 66, 21, 60, 50, 68, 49, 8, 63, 59, 56, 26,
  31, 53, 38, 69, 65, 43, 74, 58, 61, 62, 73, 39, 13, 70, 6, 12,
];

const sala = (extra: Partial<Sala> = {}): Sala => ({
  nombre: "Bingo de los sábados",
  organizadorUid: "carmen",
  organizadorNombre: "Carmen",
  publica: true,
  ocupadas: 0,
  precioFila: 5,
  premio: 80,
  comisionPorcentaje: 10,
  columnas: 5,
  filasTotal: 20,
  filasPorJugador: 1,
  estado: "abierta",
  bolillas: [],
  ganadores: [],
  ...extra,
});

const filasLibres = (n = 20): Fila[] => CARTILLAS.slice(0, n).map((numeros) => ({ numeros }));

const codigoDe = (f: () => unknown): string | undefined => {
  try {
    f();
  } catch (e) {
    return e instanceof ErrorSala ? e.codigo : "otro_error";
  }
  return undefined;
};

describe("generarCodigo", () => {
  it("tiene 4 caracteres y nunca usa 0, O, 1 ni I", () => {
    for (let i = 0; i < 500; i++) {
      assert.match(generarCodigo(), /^[A-HJ-NP-Z2-9]{4}$/);
    }
  });
});

describe("generarCartillas", () => {
  it("respeta el rango de cada columna", () => {
    for (const columnas of [5, 6]) {
      const cartillas = generarCartillas(20, columnas);
      assert.equal(cartillas.length, 20);
      for (const fila of cartillas) {
        assert.equal(fila.length, columnas);
        fila.forEach((n, c) => assert.ok(n >= c * 15 + 1 && n <= c * 15 + 15));
      }
    }
  });
});

describe("validarNombreSala", () => {
  it("acepta el nombre de ejemplo del diseño y rechaza más de 40", () => {
    assert.equal(validarNombreSala("Bingo de los sábados"), "Bingo de los sábados");
    assert.equal(codigoDe(() => validarNombreSala("x".repeat(41))), "nombre_invalido");
  });
});

describe("validarNombre", () => {
  it("recorta y junta espacios", () => {
    assert.equal(validarNombre("  Ana   Lucía "), "Ana Lucía");
  });
  it("rechaza vacío, muy largo y no texto", () => {
    assert.equal(codigoDe(() => validarNombre("   ")), "nombre_invalido");
    assert.equal(codigoDe(() => validarNombre("x".repeat(19))), "nombre_invalido");
    assert.equal(codigoDe(() => validarNombre(42)), "nombre_invalido");
  });
});

describe("aplicarReserva", () => {
  it("reserva una fila libre", () => {
    const r = aplicarReserva(sala(), filasLibres(), 5, "lucia", "Lucía");
    assert.equal(r.fila.jugadorUid, "lucia");
    assert.equal(r.fila.nombre, "Lucía");
    assert.equal(r.estado, "abierta");
  });

  it("la reserva de la última fila llena la cartilla", () => {
    const filas = filasLibres();
    filas.slice(0, 19).forEach((f, i) => (f.jugadorUid = `j${i}`));
    assert.equal(aplicarReserva(sala(), filas, 20, "hector", "Héctor").estado, "llena");
  });

  it("no deja reservar una fila ocupada", () => {
    const filas = filasLibres();
    filas[4].jugadorUid = "otra";
    assert.equal(codigoDe(() => aplicarReserva(sala(), filas, 5, "lucia", "Lucía")), "fila_ocupada");
  });

  it("no deja pasar el límite de filas por jugador", () => {
    const filas = filasLibres();
    filas[0].jugadorUid = "lucia";
    assert.equal(codigoDe(() => aplicarReserva(sala(), filas, 5, "lucia", "Lucía")), "limite_de_filas");
    // Con 3 filas por jugador sí se puede (el modelo lo deja preparado).
    const r = aplicarReserva(sala({ filasPorJugador: 3 }), filas, 5, "lucia", "Lucía");
    assert.equal(r.fila.jugadorUid, "lucia");
  });

  it("rechaza filas inexistentes y salas que no están abiertas", () => {
    assert.equal(codigoDe(() => aplicarReserva(sala(), filasLibres(), 21, "u", "Ana")), "fila_inexistente");
    assert.equal(codigoDe(() => aplicarReserva(sala(), filasLibres(), 0, "u", "Ana")), "fila_inexistente");
    assert.equal(codigoDe(() => aplicarReserva(sala(), filasLibres(), 1.5, "u", "Ana")), "fila_inexistente");
    assert.equal(
      codigoDe(() => aplicarReserva(sala({ estado: "en_juego" }), filasLibres(), 1, "u", "Ana")),
      "sala_no_abierta",
    );
  });
});

describe("empezar", () => {
  it("solo el organizador y solo con la cartilla llena", () => {
    assert.equal(empezar(sala({ estado: "llena" }), "carmen"), "en_juego");
    assert.equal(codigoDe(() => empezar(sala({ estado: "llena" }), "otra")), "no_es_organizador");
    assert.equal(codigoDe(() => empezar(sala(), "carmen")), "sala_no_llena");
  });
});

describe("siguienteBolilla", () => {
  it("solo el organizador y solo en juego", () => {
    assert.equal(codigoDe(() => siguienteBolilla(sala({ estado: "en_juego" }), "otra")), "no_es_organizador");
    assert.equal(codigoDe(() => siguienteBolilla(sala(), "carmen")), "sala_no_en_juego");
  });

  it("no repite y se agota a las 75", () => {
    const s = sala({ estado: "en_juego" });
    for (let i = 0; i < 75; i++) {
      const n = siguienteBolilla(s, "carmen");
      assert.ok(!s.bolillas.includes(n));
      s.bolillas.push(n);
    }
    assert.equal(codigoDe(() => siguienteBolilla(s, "carmen")), "tombola_vacia");
  });

  it("con 6 columnas hay 90 bolillas", () => {
    assert.equal(totalBolillas(6), 90);
    const s = sala({ estado: "en_juego", columnas: 6 });
    const max = Math.max(...Array.from({ length: 200 }, () => siguienteBolilla(s, "carmen")));
    assert.ok(max <= 90);
  });
});

describe("ganadoresNuevos", () => {
  it("con la bolilla 32 (B-12) gana la fila 5 (Lucía)", () => {
    assert.deepEqual(ganadoresNuevos(CARTILLAS, ORDEN), [5]);
    assert.deepEqual(ganadoresNuevos(CARTILLAS, ORDEN.slice(0, 31)), []);
  });

  it("detecta el empate entre dos filas", () => {
    const c = [[1, 16, 31, 46, 61], [1, 17, 32, 47, 62]];
    assert.deepEqual(ganadoresNuevos(c, [16, 31, 46, 61, 17, 32, 47, 62, 1]), [1, 2]);
  });
});

describe("sinUltima", () => {
  it("quita la última bolilla y exige ser el organizador", () => {
    assert.deepEqual(sinUltima(sala({ estado: "en_juego", bolillas: [1, 2, 3] }), "carmen"), [1, 2]);
    assert.equal(
      codigoDe(() => sinUltima(sala({ estado: "en_juego", bolillas: [1] }), "otra")),
      "no_es_organizador",
    );
  });
});

describe("cancelar", () => {
  it("el organizador puede cerrar una sala abierta o llena", () => {
    assert.equal(cancelar(sala({ estado: "abierta" }), "carmen", undefined), null);
    assert.equal(cancelar(sala({ estado: "llena" }), "carmen", null), null);
  });

  it("devuelve el motivo limpio y vacío cuenta como sin motivo", () => {
    assert.equal(cancelar(sala(), "carmen", "  No llegó   gente  "), "No llegó gente");
    assert.equal(cancelar(sala(), "carmen", "   "), null);
  });

  it("solo quien organiza puede cerrarla", () => {
    assert.equal(codigoDe(() => cancelar(sala(), "otra", undefined)), "no_es_organizador");
  });

  it("no se puede cerrar una partida que ya empezó o terminó", () => {
    assert.equal(codigoDe(() => cancelar(sala({ estado: "en_juego" }), "carmen", undefined)), "sala_ya_empezada");
    assert.equal(codigoDe(() => cancelar(sala({ estado: "terminada" }), "carmen", undefined)), "sala_ya_empezada");
  });

  it("cerrar dos veces no falla", () => {
    assert.equal(cancelar(sala({ estado: "cancelada" }), "carmen", undefined), null);
  });

  it("rechaza un motivo que no es texto o es muy largo", () => {
    assert.equal(codigoDe(() => cancelar(sala(), "carmen", 5)), "motivo_invalido");
    assert.equal(codigoDe(() => cancelar(sala(), "carmen", "x".repeat(121))), "motivo_invalido");
  });
});

describe("precio y premio", () => {
  it("con 5 créditos por fila y 10 % quedan 90 para premio (como en el prototipo)", () => {
    assert.equal(comision(100, 10), 10);
    assert.equal(disponibleParaPremio(5, 20, 10), 90);
  });

  it("la comisión se redondea hacia arriba", () => {
    assert.equal(comision(35, 10), 4);
    assert.equal(disponibleParaPremio(1, 20, 10), 18);
  });

  it("acepta el premio del prototipo y el tope exacto", () => {
    assert.deepEqual(validarPrecioPremio(5, 80, 20), { precioFila: 5, premio: 80 });
    assert.deepEqual(validarPrecioPremio(5, 90, 20), { precioFila: 5, premio: 90 });
  });

  it("sin datos es una partida sin premio", () => {
    assert.deepEqual(validarPrecioPremio(undefined, undefined, 20), { precioFila: 0, premio: 0 });
    assert.deepEqual(validarPrecioPremio(null, null, 20), { precioFila: 0, premio: 0 });
  });

  it("el premio no puede pasar de lo disponible", () => {
    assert.equal(codigoDe(() => validarPrecioPremio(5, 91, 20)), "premio_invalido");
  });

  it("sin precio no hay premio", () => {
    assert.equal(codigoDe(() => validarPrecioPremio(0, 10, 20)), "premio_invalido");
    assert.deepEqual(validarPrecioPremio(0, 0, 20), { precioFila: 0, premio: 0 });
  });

  it("rechaza precios y premios que no son enteros válidos", () => {
    assert.equal(codigoDe(() => validarPrecioPremio(-1, 0, 20)), "precio_invalido");
    assert.equal(codigoDe(() => validarPrecioPremio(2.5, 0, 20)), "precio_invalido");
    assert.equal(codigoDe(() => validarPrecioPremio("5", 0, 20)), "precio_invalido");
    assert.equal(codigoDe(() => validarPrecioPremio(1001, 0, 20)), "precio_invalido");
    assert.equal(codigoDe(() => validarPrecioPremio(5, -1, 20)), "premio_invalido");
    assert.equal(codigoDe(() => validarPrecioPremio(5, 1.5, 20)), "premio_invalido");
  });

  it("usa la comisión que se le pase", () => {
    assert.equal(disponibleParaPremio(5, 20, 20), 80);
    assert.equal(codigoDe(() => validarPrecioPremio(5, 81, 20, 20)), "premio_invalido");
  });
});

describe("aplicarReservas (varias filas)", () => {
  const abierta = (extra: Partial<Sala> = {}) => sala({ filasPorJugador: 20, ...extra });

  it("reserva varias filas a la vez y calcula el costo", () => {
    const r = aplicarReservas(abierta(), filasLibres(), [7, 5, 6], "lucia", "Lucía");
    assert.deepEqual(r.numeros, [5, 6, 7]);
    assert.equal(r.costo, 15);
    assert.equal(r.estado, "abierta");
  });

  it("una sala sin precio no cuesta nada", () => {
    assert.equal(aplicarReservas(abierta({ precioFila: 0 }), filasLibres(), [1, 2], "a", "A").costo, 0);
  });

  it("es todo o nada: una fila ocupada rechaza la reserva entera", () => {
    const filas = filasLibres();
    filas[5].jugadorUid = "otra";
    assert.equal(
      codigoDe(() => aplicarReservas(abierta(), filas, [5, 6], "lucia", "Lucía")),
      "fila_ocupada",
    );
  });

  it("no acepta listas vacías, repetidas ni filas que no existen", () => {
    assert.equal(codigoDe(() => aplicarReservas(abierta(), filasLibres(), [], "a", "A")), "filas_invalidas");
    assert.equal(codigoDe(() => aplicarReservas(abierta(), filasLibres(), [3, 3], "a", "A")), "filas_invalidas");
    assert.equal(codigoDe(() => aplicarReservas(abierta(), filasLibres(), "5", "a", "A")), "filas_invalidas");
    assert.equal(codigoDe(() => aplicarReservas(abierta(), filasLibres(), [21], "a", "A")), "fila_inexistente");
    assert.equal(codigoDe(() => aplicarReservas(abierta(), filasLibres(), [0], "a", "A")), "fila_inexistente");
    assert.equal(codigoDe(() => aplicarReservas(abierta(), filasLibres(), [1.5], "a", "A")), "fila_inexistente");
  });

  it("respeta el límite de filas por jugador contando las que ya tiene", () => {
    const filas = filasLibres();
    filas[0].jugadorUid = "lucia";
    const limitada = abierta({ filasPorJugador: 3 });
    assert.equal(aplicarReservas(limitada, filas, [2, 3], "lucia", "Lucía").numeros.length, 2);
    assert.equal(codigoDe(() => aplicarReservas(limitada, filas, [2, 3, 4], "lucia", "Lucía")), "limite_de_filas");
  });

  it("sin límite, se pueden reservar todas las filas libres y la sala se llena", () => {
    const todas = Array.from({ length: 20 }, (_, i) => i + 1);
    const r = aplicarReservas(abierta(), filasLibres(), todas, "lucia", "Lucía");
    assert.equal(r.estado, "llena");
    assert.equal(r.costo, 100);
  });

  it("no reserva en una sala que no está abierta", () => {
    assert.equal(
      codigoDe(() => aplicarReservas(abierta({ estado: "cancelada" }), filasLibres(), [1], "a", "A")),
      "sala_no_abierta",
    );
  });
});

describe("billetera", () => {
  it("cobrar descuenta y falla si no alcanza", () => {
    assert.equal(cobrar(25, 15), 10);
    assert.equal(cobrar(5, 5), 0);
    assert.equal(codigoDe(() => cobrar(4, 5)), "saldo_insuficiente");
  });

  it("solo se recargan los montos fijos", () => {
    for (const m of [10, 20, 50, 100]) assert.equal(validarRecarga(m), m);
    assert.equal(codigoDe(() => validarRecarga(15)), "monto_invalido");
    assert.equal(codigoDe(() => validarRecarga("20")), "monto_invalido");
    assert.equal(codigoDe(() => validarRecarga(undefined)), "monto_invalido");
  });

  it("las filas por jugador son todas las filas si no se dice nada", () => {
    assert.equal(validarFilasPorJugador(undefined, 20), 20);
    assert.equal(validarFilasPorJugador(1, 20), 1);
    assert.equal(codigoDe(() => validarFilasPorJugador(0, 20)), "filas_invalidas");
    assert.equal(codigoDe(() => validarFilasPorJugador(21, 20)), "filas_invalidas");
    assert.equal(codigoDe(() => validarFilasPorJugador(2.5, 20)), "filas_invalidas");
  });
});

describe("repartirPremio", () => {
  const llenas = (dueños: Record<number, string>): Fila[] =>
    filasLibres().map((f, i) => ({ ...f, jugadorUid: dueños[i + 1] ?? `j${i + 1}` }));

  it("paga el premio a la ganadora y lo que sobra a quien organiza", () => {
    const pagos = repartirPremio(
      sala({ estado: "en_juego", ganadores: [{ fila: 3, bolillaIndice: 20 }] }),
      llenas({ 3: "ana" }),
    );
    assert.deepEqual(pagos, [
      { uid: "ana", monto: 80, motivo: "premio" },
      { uid: "carmen", monto: 10, motivo: "sobrante" },
    ]);
  });

  it("en un empate reparte a partes iguales y el resto es de quien organiza", () => {
    const pagos = repartirPremio(
      sala({
        premio: 25,
        ganadores: [
          { fila: 1, bolillaIndice: 9 },
          { fila: 2, bolillaIndice: 9 },
          { fila: 3, bolillaIndice: 9 },
        ],
      }),
      llenas({}),
    );
    assert.deepEqual(pagos.filter((p) => p.motivo === "premio").map((p) => p.monto), [8, 8, 8]);
    assert.equal(pagos.find((p) => p.motivo === "sobrante")?.monto, 66);
  });

  it("sin ganadora, todo lo disponible queda con quien organiza", () => {
    const pagos = repartirPremio(sala(), llenas({}));
    assert.deepEqual(pagos, [{ uid: "carmen", monto: 90, motivo: "sobrante" }]);
  });

  it("sin precio o sin jugadores no hay nada que repartir", () => {
    assert.deepEqual(repartirPremio(sala({ precioFila: 0, premio: 0 }), llenas({})), []);
    assert.deepEqual(repartirPremio(sala(), filasLibres()), []);
  });
});
