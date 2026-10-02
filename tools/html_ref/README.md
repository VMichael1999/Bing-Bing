# Referencia visual (HTML)

Los dos HTML del diseño aprobado y el script que captura cada pantalla.

- `bolilla-dos-apps.html`: fuente de verdad visual (pantallas de Host y Play).
- `bolilla-prototipo.html`: fuente de verdad del movimiento y de la lógica.
- `png/<id>.png`: captura de cada `figure[data-screen]` (`.app`, 320 × 700 dp a 3×).

Las capturas incluyen las esquinas redondeadas del marco del teléfono y la barra de
estado falsa; al comparar con Flutter se ignora todo lo que está sobre y = 44 dp.

## Volver a capturar

```bash
cd tools/html_ref
npm install
npx playwright install chromium
npm run capturar
```
