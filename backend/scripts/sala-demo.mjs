// Simula a quien organiza y a los demás jugadores contra el emulador, para
// probar las apps a mano desde un celular o un emulador de Android.
//
//   node backend/scripts/sala-demo.mjs crear            sala nueva con 4 filas tomadas
//   node backend/scripts/sala-demo.mjs llenar CODIGO [n] toma n filas libres (por defecto todas)
//   node backend/scripts/sala-demo.mjs empezar CODIGO   cierra la sala y empieza la partida
//   node backend/scripts/sala-demo.mjs sacar CODIGO [n] saca n bolillas (por defecto 1)
//   node backend/scripts/sala-demo.mjs ganar CODIGO FILA saca bolillas hasta que gane esa fila
//   node backend/scripts/sala-demo.mjs cerrar CODIGO [motivo]  cierra la sala que no se jugó (con motivo opcional)
//
// La cuenta de la organizadora se guarda en un archivo temporal para repetir.
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const PROYECTO = process.env.PROYECTO ?? "bingbing-f1491";
const HOST = process.env.EMULADOR ?? "127.0.0.1";
const AUTH = `http://${HOST}:9099/identitytoolkit.googleapis.com/v1/accounts`;
const FUNCIONES = `http://${HOST}:5001/${PROYECTO}/us-central1`;
const DOCS = `http://${HOST}:8080/v1/projects/${PROYECTO}/databases/(default)/documents`;
const CUENTA = join(tmpdir(), "bing-sala-demo.json");

async function post(url, cuerpo, token) {
  const r = await fetch(url, {
    method: "POST",
    headers: { "content-type": "application/json", ...(token && { authorization: `Bearer ${token}` }) },
    body: JSON.stringify(cuerpo),
  });
  return r.json();
}

async function organizador() {
  const cuerpo = { returnSecureToken: true };
  if (existsSync(CUENTA)) {
    const r = await post(`${AUTH}:signInWithPassword?key=x`, { ...cuerpo, ...JSON.parse(readFileSync(CUENTA, "utf8")) });
    if (r.idToken) return r.idToken;
  }
  const cuenta = { email: `carmen+${Date.now()}@prueba.pe`, password: "clave-de-prueba" };
  writeFileSync(CUENTA, JSON.stringify(cuenta));
  return (await post(`${AUTH}:signUp?key=x`, { ...cuerpo, ...cuenta })).idToken;
}

// Con precio hace falta una cuenta (el cobro sale de su billetera de prueba).
const anonimo = async () =>
  (await post(`${AUTH}:signUp?key=x`, { returnSecureToken: true, email: `jugador+${Date.now()}${Math.floor(Math.random() * 1e6)}@prueba.pe`, password: "clave-de-prueba" })).idToken;

async function llamar(nombre, token, data) {
  const r = await post(`${FUNCIONES}/${nombre}`, { data }, token);
  if (!r.result) throw new Error(`${nombre}: ${JSON.stringify(r.error)}`);
  return r.result;
}

async function filasLibres(codigo, token) {
  const r = await fetch(`${DOCS}/salas/${codigo}/filas`, { headers: { authorization: `Bearer ${token}` } });
  const { documents = [] } = await r.json();
  return documents
    .filter((d) => !d.fields.jugadorUid)
    .map((d) => Number(d.name.split("/").pop()))
    .sort((a, b) => a - b);
}

async function tomar(codigo, cantidad) {
  const token = await organizador();
  const libres = (await filasLibres(codigo, token)).slice(0, cantidad ?? Infinity);
  for (const fila of libres) {
    await llamar("reservarFila", await anonimo(), { codigo, fila, nombre: `Jugador ${fila}` });
  }
  return libres.length;
}

// Saca bolillas hasta que a FILA le falte una y, entonces, saca y deshace hasta
// que justo salga la que le falta. El azar sigue siendo del servidor.
async function ganar(codigo, fila, token) {
  const leer = async (ruta) =>
    (await (await fetch(`${DOCS}/salas/${codigo}${ruta}`, { headers: { authorization: `Bearer ${token}` } })).json());
  const numeros = (doc) => doc.fields.numeros.arrayValue.values.map((v) => Number(v.integerValue));
  const propios = numeros(await leer(`/filas/${fila}`));
  for (let vuelta = 0; vuelta < 500; vuelta++) {
    const sala = await leer("");
    const salidas = new Set((sala.fields.bolillas.arrayValue.values ?? []).map((v) => Number(v.integerValue)));
    const faltan = propios.filter((n) => !salidas.has(n));
    if (faltan.length === 0) return salidas.size;
    const r = await llamar("sacarBolilla", token, { codigo });
    if (faltan.length === 1 && r.numero !== faltan[0]) await llamar("deshacerBolilla", token, { codigo });
  }
  throw new Error("No se logró en 500 vueltas");
}

const [orden, codigo, cuantas] = process.argv.slice(2);
const token = await organizador();
switch (orden) {
  case "crear": {
    const r = await llamar("crearSala", token, { nombre: "Bingo de los sábados", columnas: 5, publica: true, precioFila: 5, premio: 80 });
    await tomar(r.codigo, 4);
    console.log(`Sala ${r.codigo} creada con 4 filas tomadas`);
    break;
  }
  case "llenar":
    console.log(`${await tomar(codigo, cuantas ? Number(cuantas) : undefined)} filas tomadas`);
    break;
  case "empezar":
    await llamar("empezarPartida", token, { codigo });
    console.log("Partida empezada");
    break;
  case "sacar":
    for (let i = 0; i < Number(cuantas ?? 1); i++) {
      const r = await llamar("sacarBolilla", token, { codigo });
      console.log(`Bolilla ${r.numero} (#${r.indice})${r.ganadoras.length ? ` · gana la fila ${r.ganadoras}` : ""}`);
      if (r.ganadoras.length) break;
    }
    break;
  case "ganar":
    console.log(`Gana la fila ${cuantas} con ${await ganar(codigo, Number(cuantas), token)} bolillas`);
    break;
  case "cerrar":
    await llamar("cancelarSala", token, { codigo, ...(cuantas ? { motivo: cuantas } : {}) });
    console.log(`Sala ${codigo} cerrada${cuantas ? ` · motivo: ${cuantas}` : " sin motivo"}`);
    break;
  default:
    console.log("Uso: crear | llenar CODIGO [n] | empezar CODIGO | sacar CODIGO [n] | ganar CODIGO FILA | cerrar CODIGO [motivo]");
}
