// Reglas puras de la sala. No dependen de Firebase para poder probarlas solas.

export const RANGO_COLUMNA = 15;
const ALFABETO_CODIGO = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // sin 0/O ni 1/I

export type EstadoSala = "abierta" | "llena" | "en_juego" | "terminada" | "cancelada";

/** Lo que retiene Bing Bing de lo recaudado, en %. Por definir con el negocio. */
export const COMISION_PORCENTAJE_POR_DEFECTO = 10;
/** Tope del precio por fila, en créditos. */
export const PRECIO_MAXIMO = 1000;

export interface Sala {
  nombre: string;
  organizadorUid: string;
  organizadorNombre: string;
  /** Visible en la lista de salas abiertas de Play; si no, solo con el código o el enlace. */
  publica: boolean;
  /** Filas con jugador. Se mantiene al reservar para listar sin leer las 20 filas. */
  ocupadas: number;
  /** Créditos que cuesta cada fila; 0 es una partida sin premio. */
  precioFila: number;
  /** Créditos que gana la fila ganadora; nunca más de lo que queda tras la comisión. */
  premio: number;
  /** Comisión vigente al crear la sala (se guarda para que no cambie después). */
  comisionPorcentaje: number;
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
      | "sala_ya_empezada"
      | "motivo_invalido"
      | "precio_invalido"
      | "premio_invalido"
      | "saldo_insuficiente"
      | "monto_invalido"
      | "filas_invalidas"
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

/** Créditos de prueba con los que empieza cada cuenta. */
export const CREDITOS_INICIALES = 25;
/** Montos que se pueden recargar (créditos de prueba, sin cobro). */
export const MONTOS_RECARGA = [10, 20, 50, 100];

/** Cuántas filas puede tener una persona: por defecto, las que quiera. */
export function validarFilasPorJugador(valor: unknown, total: number): number {
  if (valor === undefined || valor === null) return total;
  if (!Number.isInteger(valor) || (valor as number) < 1 || (valor as number) > total) {
    throw new ErrorSala("filas_invalidas", `Las filas por jugador deben ser de 1 a ${total}`);
  }
  return valor as number;
}

/**
 * Valida la reserva de una o varias filas y devuelve el estado de sala que
 * resulta y cuánto cuesta. No escribe nada. `filas` son todas las filas de la
 * sala (índice 0 = fila 1). Es todo o nada: si una fila falla, ninguna se reserva.
 */
export function aplicarReservas(
  sala: Sala,
  filas: Fila[],
  numeros: unknown,
  uid: string,
  nombre: unknown,
): { numeros: number[]; estado: EstadoSala; nombre: string; costo: number } {
  if (sala.estado !== "abierta") {
    throw new ErrorSala("sala_no_abierta", "La sala ya no está abierta");
  }
  if (!Array.isArray(numeros) || numeros.length === 0) {
    throw new ErrorSala("filas_invalidas", "Elige al menos una fila");
  }
  const elegidas = numeros as unknown[];
  if (new Set(elegidas).size !== elegidas.length) {
    throw new ErrorSala("filas_invalidas", "No repitas filas");
  }
  for (const n of elegidas) {
    if (!Number.isInteger(n) || filas[(n as number) - 1] === undefined) {
      throw new ErrorSala("fila_inexistente", "Esa fila no existe");
    }
    if (filas[(n as number) - 1].jugadorUid !== undefined) {
      throw new ErrorSala("fila_ocupada", "Esa fila ya tiene dueño");
    }
  }
  const propias = filas.filter((f) => f.jugadorUid === uid).length;
  if (propias + elegidas.length > sala.filasPorJugador) {
    throw new ErrorSala("limite_de_filas", "Superas el límite de filas por jugador");
  }
  const limpio = validarNombre(nombre);
  const ocupadas = filas.filter((f) => f.jugadorUid !== undefined).length + elegidas.length;
  return {
    numeros: (elegidas as number[]).slice().sort((x, y) => x - y),
    estado: ocupadas === sala.filasTotal ? "llena" : "abierta",
    nombre: limpio,
    costo: sala.precioFila * elegidas.length,
  };
}

/** Valida la reserva de una fila (caso de una sola). */
export function aplicarReserva(
  sala: Sala,
  filas: Fila[],
  numeroFila: number,
  uid: string,
  nombre: unknown,
): { fila: Fila; estado: EstadoSala; nombre: string } {
  const r = aplicarReservas(sala, filas, [numeroFila], uid, nombre);
  return {
    fila: { ...filas[numeroFila - 1], jugadorUid: uid, nombre: r.nombre },
    estado: r.estado,
    nombre: r.nombre,
  };
}

/** Lo que queda en la billetera tras pagar [costo]; falla si no alcanza. */
export function cobrar(saldo: number, costo: number): number {
  if (costo > saldo) {
    throw new ErrorSala("saldo_insuficiente", `Te faltan ${costo - saldo} créditos`);
  }
  return saldo - costo;
}

/** Monto de una recarga: solo los montos fijos. */
export function validarRecarga(monto: unknown): number {
  if (typeof monto !== "number" || !MONTOS_RECARGA.includes(monto)) {
    throw new ErrorSala("monto_invalido", `Los montos son ${MONTOS_RECARGA.join(", ")}`);
  }
  return monto;
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

/** Lo que se recauda si se llenan todas las filas. */
export function recaudado(precioFila: number, filas: number): number {
  return precioFila * filas;
}

/** La parte de Bing Bing, redondeada hacia arriba para no regalar centavos. */
export function comision(total: number, porcentaje: number): number {
  return Math.ceil((total * porcentaje) / 100);
}

/** Lo que queda para premio y para quien organiza. */
export function disponibleParaPremio(precioFila: number, filas: number, porcentaje: number): number {
  const total = recaudado(precioFila, filas);
  return total - comision(total, porcentaje);
}

/**
 * Valida el precio y el premio de una sala nueva. Sin precio no hay premio. El
 * premio no puede pasar de lo disponible con las filas llenas. Devuelve los
 * valores limpios; por defecto, una partida sin premio.
 */
export function validarPrecioPremio(
  precio: unknown,
  premio: unknown,
  filas: number,
  porcentaje: number = COMISION_PORCENTAJE_POR_DEFECTO,
): { precioFila: number; premio: number } {
  const precioFila = precio === undefined || precio === null ? 0 : precio;
  if (!Number.isInteger(precioFila) || (precioFila as number) < 0 || (precioFila as number) > PRECIO_MAXIMO) {
    throw new ErrorSala("precio_invalido", `El precio debe ser un entero de 0 a ${PRECIO_MAXIMO}`);
  }
  const p = precioFila as number;
  const premioFinal = premio === undefined || premio === null ? 0 : premio;
  if (!Number.isInteger(premioFinal) || (premioFinal as number) < 0) {
    throw new ErrorSala("premio_invalido", "El premio debe ser un entero de 0 en adelante");
  }
  const g = premioFinal as number;
  if (p === 0 && g > 0) {
    throw new ErrorSala("premio_invalido", "Sin precio por fila no hay premio");
  }
  const tope = disponibleParaPremio(p, filas, porcentaje);
  if (g > tope) {
    throw new ErrorSala("premio_invalido", `El premio no puede pasar de ${tope}`);
  }
  return { precioFila: p, premio: g };
}

/** Largo máximo del motivo con el que se cierra una sala. */
export const MOTIVO_MAXIMO = 120;

/**
 * Quien organiza cierra una sala que no se jugó. Solo antes de la primera
 * bolilla: una partida empezada se juega hasta terminar. Devuelve el motivo
 * limpio (o `null` si no se dio). Cerrar dos veces no falla.
 */
export function cancelar(sala: Sala, uid: string, motivo: unknown): string | null {
  exigirOrganizador(sala, uid);
  if (sala.estado === "en_juego" || sala.estado === "terminada") {
    throw new ErrorSala("sala_ya_empezada", "La partida ya empezó y no se puede cerrar");
  }
  if (motivo === undefined || motivo === null) return null;
  if (typeof motivo !== "string") {
    throw new ErrorSala("motivo_invalido", "El motivo debe ser texto");
  }
  const limpio = motivo.trim().replace(/\s+/g, " ");
  if (limpio.length > MOTIVO_MAXIMO) {
    throw new ErrorSala("motivo_invalido", `El motivo admite hasta ${MOTIVO_MAXIMO} caracteres`);
  }
  return limpio === "" ? null : limpio;
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
