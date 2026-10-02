import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  ErrorSala,
  Fila,
  Sala,
  aplicarReserva,
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
