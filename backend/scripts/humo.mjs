// Prueba de humo del backend contra el emulador de Firebase:
//   npx firebase-tools emulators:start --only auth,functions,firestore --project demo-bingbing
//   node backend/scripts/humo.mjs
// Recorre una partida completa: sala, 20 reservas, sorteo hasta que alguien gana.
import assert from "node:assert/strict";

const PROYECTO = process.env.PROYECTO ?? "demo-bingbing";
const HOST = process.env.EMULADOR ?? "127.0.0.1";
const AUTH = `http://${HOST}:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=falsa`;
const FUNCIONES = `http://${HOST}:5001/${PROYECTO}/us-central1`;
const DOCS = `http://${HOST}:8080/v1/projects/${PROYECTO}/databases/(default)/documents`;

async function registrar(cuerpo = {}) {
  const r = await fetch(AUTH, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ returnSecureToken: true, ...cuerpo }),
  });
  const { idToken, error } = await r.json();
  assert.ok(idToken, `no se pudo registrar: ${JSON.stringify(error)}`);
  return idToken;
}

async function llamar(nombre, token, data = {}) {
  const r = await fetch(`${FUNCIONES}/${nombre}`, {
    method: "POST",
    headers: { "content-type": "application/json", authorization: `Bearer ${token}` },
    body: JSON.stringify({ data }),
  });
  return { http: r.status, ...(await r.json()) };
}

const ok = async (nombre, token, data) => {
  const r = await llamar(nombre, token, data);
  assert.ok(r.result, `${nombre} falló: ${JSON.stringify(r.error)}`);
  return r.result;
};
const rechazada = async (nombre, token, data, estado) => {
  const r = await llamar(nombre, token, data);
  assert.equal(r.error?.status, estado, `${nombre} debía dar ${estado}: ${JSON.stringify(r)}`);
};

const organizador = await registrar({ email: `carmen+${Date.now()}@prueba.pe`, password: "clave-de-prueba" });
const anonimo = await registrar();

// Quien juega no puede organizar.
await rechazada("crearSala", anonimo, { nombre: "X" }, "PERMISSION_DENIED");
const { codigo } = await ok("crearSala", organizador, { nombre: "Bingo de los sábados", columnas: 5, publica: true, precioFila: 5, premio: 80 });
const privada = await ok("crearSala", organizador, { nombre: "Solo familia", columnas: 5, publica: false });
assert.match(codigo, /^[A-Z2-9]{4}$/);
const datosSala = await (
  await fetch(`${DOCS}/salas/${codigo}`, { headers: { authorization: `Bearer ${organizador}` } })
).json();
assert.equal(datosSala.fields.organizadorNombre.stringValue, "quien organiza");
console.log(`✔ sala ${codigo} creada`);

// Precio y premio: el servidor los guarda y no deja un premio mayor a lo disponible.
assert.equal(Number(datosSala.fields.precioFila.integerValue), 5);
assert.equal(Number(datosSala.fields.premio.integerValue), 80);
assert.equal(Number(datosSala.fields.comisionPorcentaje.integerValue ?? datosSala.fields.comisionPorcentaje.doubleValue), 10);
await rechazada("crearSala", organizador, { nombre: "Premio de más", precioFila: 5, premio: 91 }, "FAILED_PRECONDITION");
await rechazada("crearSala", organizador, { nombre: "Premio sin precio", precioFila: 0, premio: 10 }, "FAILED_PRECONDITION");
await rechazada("crearSala", organizador, { nombre: "Precio raro", precioFila: 2.5 }, "FAILED_PRECONDITION");
const sinPremio = await ok("crearSala", organizador, { nombre: "Entre amigos" });
const docAmigos = await (await fetch(`${DOCS}/salas/${sinPremio.codigo}`, { headers: { authorization: `Bearer ${organizador}` } })).json();
assert.equal(Number(docAmigos.fields.precioFila.integerValue), 0);
assert.equal(Number(docAmigos.fields.premio.integerValue), 0);
console.log("✔ precio y premio: se guardan y el premio no pasa de lo disponible");

// No se puede empezar ni sortear con la cartilla a medias.
await rechazada("empezarPartida", organizador, { codigo }, "FAILED_PRECONDITION");

const nombres = Array.from({ length: 20 }, (_, i) => `Jugador ${i + 1}`);
const jugadores = [];
for (let i = 0; i < 20; i++) {
  const token = await registrar();
  jugadores.push(token);
  const r = await ok("reservarFila", token, { codigo, fila: i + 1, nombre: nombres[i] });
  assert.equal(r.fila, i + 1);
}
console.log("✔ 20 filas reservadas, una por jugador");

// Contador de filas ocupadas y visibilidad en el documento de la sala.
const doc = await (await fetch(`${DOCS}/salas/${codigo}`, { headers: { authorization: `Bearer ${jugadores[0]}` } })).json();
assert.equal(Number(doc.fields.ocupadas.integerValue), 20);
assert.equal(doc.fields.publica.booleanValue, true);

// Listar: las públicas sí, las privadas no se pueden enumerar.
const consultar = async (token, filtro) => {
  const r = await fetch(`${DOCS}:runQuery`, {
    method: "POST",
    headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
    body: JSON.stringify({ structuredQuery: { from: [{ collectionId: "salas" }], ...(filtro && { where: filtro }) } }),
  });
  return { http: r.status, filas: await r.json() };
};
const campo = (nombre, valor) => ({ fieldFilter: { field: { fieldPath: nombre }, op: "EQUAL", value: valor } });
const publicas = await consultar(jugadores[0], campo("publica", { booleanValue: true }));
assert.equal(publicas.http, 200);
const codigos = publicas.filas.filter((f) => f.document).map((f) => f.document.name.split("/").pop());
assert.ok(codigos.includes(codigo), "la sala pública debe aparecer en la lista");
assert.ok(!codigos.includes(privada.codigo), "la sala privada no debe aparecer en la lista");
assert.equal((await consultar(jugadores[0], null)).http, 403, "listar todas las salas debe estar prohibido");
assert.equal((await consultar(jugadores[0], campo("publica", { booleanValue: false }))).http, 403, "listar las privadas debe estar prohibido");
const propias = await consultar(organizador, campo("organizadorUid", { stringValue: JSON.parse(Buffer.from(organizador.split(".")[1], "base64url")).user_id }));
assert.equal(propias.http, 200);
assert.ok(propias.filas.some((f) => f.document?.name.endsWith(privada.codigo)), "quien organiza ve sus salas privadas");
// Una sala privada sí se abre con su código.
const abierta = await fetch(`${DOCS}/salas/${privada.codigo}`, { headers: { authorization: `Bearer ${jugadores[0]}` } });
assert.equal(abierta.status, 200);
console.log("✔ visibilidad: públicas listables, privadas solo con código, contador de filas");

// Cerrar una sala que no se jugó: solo su organizador, solo antes de empezar.
const cerrable = await ok("crearSala", organizador, { nombre: "Se cierra", columnas: 5, publica: true });
await ok("reservarFila", jugadores[1], { codigo: cerrable.codigo, fila: 1, nombre: "Ana" });
await rechazada("cancelarSala", jugadores[1], { codigo: cerrable.codigo }, "PERMISSION_DENIED");
await ok("cancelarSala", organizador, { codigo: cerrable.codigo, motivo: "No se llenó" });
await ok("cancelarSala", organizador, { codigo: cerrable.codigo }); // cerrar dos veces no falla
const cerrada = await (await fetch(`${DOCS}/salas/${cerrable.codigo}`, { headers: { authorization: `Bearer ${jugadores[1]}` } })).json();
assert.equal(cerrada.fields.estado.stringValue, "cancelada");
assert.equal(cerrada.fields.motivoCierre.stringValue, "No se llenó");
await rechazada("reservarFila", jugadores[2], { codigo: cerrable.codigo, fila: 2, nombre: "Beto" }, "FAILED_PRECONDITION");
console.log("✔ cerrar una sala: solo quien organiza, avisa el motivo y ya no recibe jugadores");

// Doble reserva: la fila ya tiene dueño y el jugador ya tiene fila.
await rechazada("reservarFila", await registrar(), { codigo, fila: 1, nombre: "Intruso" }, "FAILED_PRECONDITION");

// Los clientes leen la sala, pero no pueden escribirla.
const leer = await fetch(`${DOCS}/salas/${codigo}`, { headers: { authorization: `Bearer ${jugadores[0]}` } });
assert.equal(leer.status, 200);
const escribir = await fetch(`${DOCS}/salas/${codigo}?updateMask.fieldPaths=estado`, {
  method: "PATCH",
  headers: { authorization: `Bearer ${jugadores[0]}`, "content-type": "application/json" },
  body: JSON.stringify({ fields: { estado: { stringValue: "terminada" } } }),
});
assert.equal(escribir.status, 403);
console.log("✔ lectura permitida y escritura directa bloqueada");

// Solo el organizador de esa sala sortea.
await rechazada("sacarBolilla", jugadores[0], { codigo }, "PERMISSION_DENIED");
await ok("empezarPartida", organizador, { codigo });
await rechazada("cancelarSala", organizador, { codigo }, "FAILED_PRECONDITION"); // empezada: se juega hasta el final

const salidas = new Set();
let ganadoras = [];
while (ganadoras.length === 0 && salidas.size < 75) {
  const r = await ok("sacarBolilla", organizador, { codigo });
  assert.ok(!salidas.has(r.numero), `se repitió la bolilla ${r.numero}`);
  salidas.add(r.numero);
  ganadoras = r.ganadoras;
}
assert.ok(ganadoras.length > 0, "nadie ganó con las 75 bolillas");
console.log(`✔ gana la fila ${ganadoras} con ${salidas.size} bolillas`);

const deshecha = await ok("deshacerBolilla", organizador, { codigo });
assert.equal(deshecha.bolillas, salidas.size - 1);
await ok("terminarPartida", organizador, { codigo });
console.log("✔ deshacer y terminar la partida");
console.log("\nPrueba de humo OK");
