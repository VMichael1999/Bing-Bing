// Mide cajas de elementos del HTML de referencia (en dp, relativas al .app).
// HTML_REF=ruta.html cambia el archivo (por defecto, el de esta carpeta).
// Uso: node medir.mjs <id-pantalla> "<selector>" ["<selector>" ...]
import { chromium } from 'playwright';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const aqui = dirname(fileURLToPath(import.meta.url));
const [id, ...selectores] = process.argv.slice(2);
const navegador = await chromium.launch();
const pagina = await navegador.newPage({ viewport: { width: 1240, height: 900 }, deviceScaleFactor: 3 });
await pagina.goto(pathToFileURL(process.env.HTML_REF ?? join(aqui, 'bolilla-dos-apps.html')).href, { waitUntil: 'networkidle' });
await pagina.evaluate(() => document.fonts.ready);
const filas = await pagina.evaluate(({ id, selectores }) => {
  const app = document.querySelector(`figure[data-screen="${id}"] .app`);
  const o = app.getBoundingClientRect();
  return selectores.flatMap((sel) =>
    [...app.querySelectorAll(sel)].slice(0, 4).map((el, i) => {
      const r = el.getBoundingClientRect();
      return `${sel}[${i}]  y=${(r.top - o.top).toFixed(2)}  h=${r.height.toFixed(2)}  x=${(r.left - o.left).toFixed(2)}  w=${r.width.toFixed(2)}`;
    }));
}, { id, selectores });
console.log(filas.join('\n'));
await navegador.close();
