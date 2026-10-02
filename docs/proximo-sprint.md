# Próximo sprint

Ideas ya decididas que **no** están en el alcance actual.

## Monedero digital del jugador (idea en análisis)

Solo la app del jugador (Bing Bing Play) tendría un **saldo dentro del juego**:

- El jugador **recarga** su saldo.
- Al elegir filas, antes de que se ponga el candado con su nombre, se le muestra el
  **precio de cada fila** (en el diseño, S/ 5.00) y que **debe pagar**.
- Al reservar, el costo se **descuenta del saldo**. Ejemplo: con S/ 20 puede elegir
  hasta 4 filas de S/ 5.
- Quien organiza crea la sala y ve **cuánto pagó cada jugador**.

Esto es la "partida con premio" del diseño (`fut-01` a `fut-03`). Hoy en `org-03` esa
sección está bloqueada con "Pronto" y no tiene lógica.

### Antes de empezar (decisiones y riesgos)

- **Marco legal en Perú:** el bingo en línea con dinero lo regula la Ley 31557 (solo
  empresas autorizadas por el Mincetur). Hay que confirmar con asesoría legal si un
  saldo recargable con premio entra en esa regulación.
- **Google Play y App Store** exigen licencia o permisos para apps donde se paga por
  participar y se puede ganar dinero.
- **Proveedor de pagos** para las recargas (por definir) y cómo se guarda el saldo:
  debe vivir en el servidor, nunca en el teléfono.
- **Varias filas por jugador:** hoy la UI permite una (`filasPorJugador = 1`); el
  modelo y las reglas ya admiten más.
- Pantallas nuevas que el HTML no define: recarga, saldo insuficiente, historial de
  movimientos, y el listado de pagos para quien organiza.

## Pendientes menores

- Estados que el diseño no define: vacío, error, sin conexión y permiso de cámara
  para escanear el QR.
- Decidir si "Van ganando" y la cartilla van por avance (como el diseño) o por número
  de fila.
