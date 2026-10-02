// Captura cada pantalla del diseño (`figure[data-screen]`) como PNG de referencia.
// Uso: npm install && npx playwright install chromium && npm run capturar
// Otro archivo: HTML=bolilla-pantallas-nuevas.html npm run capturar
import { chromium } from 'playwright';
import { mkdir } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const aqui = dirname(fileURLToPath(import.meta.url));
const salida = join(aqui, 'png');
await mkdir(salida, { recursive: true });

const navegador = await chromium.launch();
const pagina = await navegador.newPage({
  viewport: { width: 1240, height: 900 },
  deviceScaleFactor: 3,
  colorScheme: 'light',
});
await pagina.goto(pathToFileURL(join(aqui, process.env.HTML ?? 'bolilla-dos-apps.html')).href, {
  waitUntil: 'networkidle',
});
await pagina.evaluate(() => document.fonts.ready);

const pantallas = pagina.locator('figure[data-screen]');
const total = await pantallas.count();
for (let i = 0; i < total; i++) {
  const figura = pantallas.nth(i);
  const id = await figura.getAttribute('data-screen');
  await figura.locator('.app').screenshot({ path: join(salida, `${id}.png`) });
  console.log(`capturada ${id}`);
}
await navegador.close();
console.log(`${total} pantallas en ${salida}`);
