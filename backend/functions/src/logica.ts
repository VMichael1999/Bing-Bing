// Reglas puras de la sala. No dependen de Firebase para poder probarlas solas.

export const RANGO_COLUMNA = 15;
const ALFABETO_CODIGO = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // sin 0/O ni 1/I

export type EstadoSala = "abierta" | "llena" | "en_juego" | "terminada";

export interface Sala {
  nombre: string;
  organizadorUid: string;
  organizadorNombre: string;
  columnas: 5 | 6;
  filasTotal: number;
  filasPorJugador: number;
  estado: EstadoSala;
  bolillas: number[];
  ganadores: { fila: number; bolillaIndice: number }[];
}

export interface Fila {
  numeros: number[];
  jugadorUid?: string;
  nombre?: string;
}

/** Error de negocio con un código estable para que el cliente lo traduzca. */
export class ErrorSala extends Error {
  constructor(
    public readonly codigo:
      | "sala_no_abierta"
      | "fila_inexistente"
      | "fila_ocupada"
      | "limite_de_filas"
      | "nombre_invalido"
      | "no_es_organizador"
      | "sala_no_en_juego"
      | "tombola_vacia"
      | "sala_no_llena",
    mensaje: string,
  ) {
    super(mensaje);
  }
}

/** Azar inyectable: devuelve un entero en [0, n). */
export type Azar = (n: number) => number;

export const azarReal: Azar = (n) => Math.floor(Math.random() * n);

export function totalBolillas(columnas: number): number {
  return columnas * RANGO_COLUMNA;
}

/** Código de sala de 4 caracteres, sin 0/O ni 1/I. */
export function generarCodigo(azar: Azar = azarReal): string {
  let codigo = "";
  for (let i = 0; i < 4; i++) {
    codigo += ALFABETO_CODIGO[azar(ALFABETO_CODIGO.length)];
  }
  return codigo;
}

/** Cartillas: cada columna usa su rango de 15 y los números pueden repetirse entre filas. */
export function generarCartillas(
  filas: number,
  columnas: number,
  azar: Azar = azarReal,
): number[][] {
  return Array.from({ length: filas }, () =>
    Array.from({ length: columnas }, (_, c) => c * RANGO_COLUMNA + 1 + azar(RANGO_COLUMNA)),
  );
}

function limpiarNombre(nombre: unknown, maximo: number): string {
  if (typeof nombre !== "string") {
    throw new ErrorSala("nombre_invalido", "El nombre debe ser texto");
  }
  const limpio = nombre.trim().replace(/\s+/g, " ");
  if (limpio.length < 1 || limpio.length > maximo) {
    throw new ErrorSala("nombre_invalido", `El nombre debe tener entre 1 y ${maximo} caracteres`);
  }
  return limpio;
}

/** Nombre de quien juega: hasta 18 caracteres (el campo de la fila). */
export function validarNombre(nombre: unknown): string {
  return limpiarNombre(nombre, 18);
}

/** Nombre de la sala: hasta 40 caracteres (el campo de "Nueva partida"). */
export function validarNombreSala(nombre: unknown): string {
  return limpiarNombre(nombre, 40);
}

/**
 * Valida una reserva y devuelve el estado de sala que resulta. No escribe nada.
 * `filas` son todas las filas de la sala (índice 0 = fila 1).
 */
export function aplicarReserva(
  sala: Sala,
  filas: Fila[],
  numeroFila: number,
  uid: string,
  nombre: unknown,
): { fila: Fila; estado: EstadoSala; nombre: string } {
  if (sala.estado !== "abierta") {
    throw new ErrorSala("sala_no_abierta", "La sala ya no está abierta");
  }
  const fila = filas[numeroFila - 1];
  if (!Number.isInteger(numeroFila) || fila === undefined) {
    throw new ErrorSala("fila_inexistente", "Esa fila no existe");
  }
  if (fila.jugadorUid !== undefined) {
    throw new ErrorSala("fila_ocupada", "Esa fila ya tiene dueño");
  }
  const propias = filas.filter((f) => f.jugadorUid === uid).length;
  if (propias >= sala.filasPorJugador) {
    throw new ErrorSala("limite_de_filas", "Ya reservaste tu fila");
  }
  const limpio = validarNombre(nombre);
  const ocupadas = filas.filter((f) => f.jugadorUid !== undefined).length + 1;
  return {
    fila: { ...fila, jugadorUid: uid, nombre: limpio },
    estado: ocupadas === sala.filasTotal ? "llena" : "abierta",
    nombre: limpio,
  };
}

export function exigirOrganizador(sala: Sala, uid: string): void {
  if (sala.organizadorUid !== uid) {
    throw new ErrorSala("no_es_organizador", "Solo quien organiza puede hacer esto");
  }
}

/** El organizador cierra la sala y empieza la partida. Solo con la cartilla llena. */
export function empezar(sala: Sala, uid: string): EstadoSala {
  exigirOrganizador(sala, uid);
  if (sala.estado !== "llena") {
    throw new ErrorSala("sala_no_llena", "Faltan jugadores para empezar");
  }
  return "en_juego";
}

/** Elige en el servidor una bolilla que aún no salió. */
export function siguienteBolilla(sala: Sala, uid: string, azar: Azar = azarReal): number {
  exigirOrganizador(sala, uid);
  if (sala.estado !== "en_juego") {
    throw new ErrorSala("sala_no_en_juego", "La partida no está en juego");
  }
  const salidas = new Set(sala.bolillas);
  const quedan: number[] = [];
  for (let n = 1; n <= totalBolillas(sala.columnas); n++) {
    if (!salidas.has(n)) quedan.push(n);
  }
  if (quedan.length === 0) {
    throw new ErrorSala("tombola_vacia", "Ya salieron todas las bolillas");
  }
  return quedan[azar(quedan.length)];
}

function faltan(numeros: number[], salidas: Set<number>): number {
  return numeros.filter((n) => !salidas.has(n)).length;
}

/**
 * Filas (base 1) que se completan justo con la última bolilla de `orden`.
 * Si hay más de una es un empate: la regla la decide el organizador.
 */
export function ganadoresNuevos(cartillas: number[][], orden: number[]): number[] {
  if (orden.length === 0) return [];
  const antes = new Set(orden.slice(0, -1));
  const ahora = new Set(orden);
  const fila: number[] = [];
  cartillas.forEach((numeros, i) => {
    if (faltan(numeros, antes) > 0 && faltan(numeros, ahora) === 0) fila.push(i + 1);
  });
  return fila;
}

/** Quita la última bolilla (deshacer). Devuelve las que quedan. */
export function sinUltima(sala: Sala, uid: string): number[] {
  exigirOrganizador(sala, uid);
  if (sala.estado !== "en_juego" && sala.estado !== "terminada") {
    throw new ErrorSala("sala_no_en_juego", "La partida no está en juego");
  }
  return sala.bolillas.slice(0, -1);
}
