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
const { codigo } = await ok("crearSala", organizador, { nombre: "Bingo de los sábados", columnas: 5 });
assert.match(codigo, /^[A-Z2-9]{4}$/);
const datosSala = await (
  await fetch(`${DOCS}/salas/${codigo}`, { headers: { authorization: `Bearer ${organizador}` } })
).json();
assert.equal(datosSala.fields.organizadorNombre.stringValue, "quien organiza");
console.log(`✔ sala ${codigo} creada`);

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
