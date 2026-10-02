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

## Decisiones del 2 de octubre de 2026

Salas abiertas, QR, cuenta y billetera. Prototipos en
`tools/html_ref/bolilla-pantallas-nuevas.html`, **pendientes de aprobar**.

- **Salas públicas y privadas.** Quien organiza elige la visibilidad al crear la sala.
  Una **pública** aparece en la lista de Play para cualquiera, aunque no haya iniciado
  sesión. Una **privada** solo se entra con el código, el enlace o el QR.
- **Elegir fila exige cuenta con saldo.** Mirar la sala es libre; si no hay sesión, al
  tocar "Seguir con la fila" sube una hoja para iniciarla. Sin saldo suficiente las
  filas se ven pero no se pueden elegir. La comprobación se hace **en el servidor**.
- **Inicio de sesión del jugador:** Google y celular (el SMS tiene costo). La sesión
  anónima se **vincula** a la cuenta para no perder la fila ni el historial. Hay que
  poder borrar la cuenta desde la app (requisito de las tiendas).
- **Billetera en dos etapas.** Primero **créditos de prueba** (sin valor en dinero, no
  se retiran): saldo, precio por fila, premio e historial. Los pagos reales solo
  después de validar lo legal (ver arriba).
- **Precio, comisión y premio.** Quien organiza fija el precio por fila y el **premio es
  editable**. Bing Bing retiene un **porcentaje** de lo recaudado (en los prototipos,
  10 % como ejemplo: **por definir**) y el premio no puede pasar de lo que queda. Lo que
  sobra es para quien organiza (por confirmar). Si no se llenan las 20 filas, el premio
  se mantiene y se paga con lo recaudado.
- **Enlaces y QR.** Dominio gratis de Firebase Hosting
  (`bingbing-f1491.web.app/sala/CÓDIGO`); el QR contiene ese enlace. Sin la app
  instalada, el enlace muestra una página con las tiendas.

Orden previsto: prototipos aprobados → compartir y QR → escanear → salas disponibles →
cuenta del jugador → billetera con créditos de prueba.

## Decisiones del inicio de Play y de las cuentas (2 de octubre, después)

Inicio de Play (hecho en `feature/play-salas`):

- **El inicio es siempre la pantalla del código y el QR.** Debajo van las salas
  públicas abiertas, con scroll **solo en esa zona**; lo de arriba y "Ver filas libres"
  quedan fijos. En pantallas muy bajas todo se mueve junto.
- **Orden:** las más llenas primero (las más cerca de empezar); a igual llenado, la más
  antigua. Las llenas no se muestran. Tope de 10 salas.
- **Con el teclado a la vista** las salas se esconden.

Pendiente de este bloque:

- **Caducidad de salas:** una sala abierta que nadie usa debe desaparecer. Propuesta
  por confirmar: sin jugadores, 2 horas; con jugadores pero sin empezar, 12 a 24 horas;
  empezada o terminada, no se lista. Función programada en el servidor (necesita Blaze).
  Mientras tanto, la lista puede ignorar salas viejas según `creadaEn`. Falta decidir
  qué se hace con una sala caducada que ya tenía jugadores (toca la billetera).
- **Chip "Iniciar sesión"** arriba a la derecha del inicio de Play (hoy no existe).

Sesión y perfil (**por diseñar**, hoy no hay forma de salir en ninguna app):

- **Host:** la tuerca de "Tus partidas" ya está dibujada pero no hace nada. Debe abrir
  **Ajustes** con el perfil de quien organiza (nombre, cuenta con la que entró) y
  **Cerrar sesión**. `SesionBing.salir()` ya existe; falta la pantalla y la
  confirmación.
- **Play:** la sesión es opcional. Sin cuenta se puede mirar y entrar a la sala; al
  elegir fila sube la hoja para iniciar sesión. Con cuenta, el chip de arriba lleva a
  **Mi cuenta** (perfil, saldo, historial, cerrar sesión y **borrar cuenta**, requisito
  de las tiendas).
- Al cerrar sesión: volver al inicio sin datos de la cuenta y, en Play, volver a la
  sesión anónima. Decidir qué pasa si hay una partida en curso.
- Pantallas nuevas que el HTML aún no define: Ajustes del Host, Mi cuenta de Play,
  confirmar cerrar sesión y confirmar borrar cuenta.

## Cerrar una sala que no se llenó (idea decidida, por diseñar)

Caso: la sala es de 20 filas y solo se registraron 5. Pasó el **plazo de registro** y
quien organiza decide no seguir.

- **Plazo de registro.** Quien organiza lo fija al crear la sala (por ejemplo, hasta una
  hora o fecha). Es distinto de la caducidad automática por abandono: este plazo lo
  decide la persona y se muestra a los jugadores.
- **Botón para cerrar la sala** (nombre por definir: "Cancelar partida", "Cerrar sala" o
  "Terminar sin jugar"), con un motivo opcional. Pide confirmación y explica que se
  **devolverá el dinero** a quienes ya reservaron. Disponible en la sala abierta, antes
  de empezar la partida.
- **Aviso a los jugadores.** Una ventana flotante (diálogo) que dice que la sala se cerró
  porque no se completó el número de filas, y que se les devolvió el saldo. Debe quedar
  guardado en la sala (estado `cancelada` con motivo), no solo enviarse una vez, para que
  lo vea quien abra la app después. Si la app está cerrada, una notificación push.
- **Devolución.** El servidor devuelve a la **billetera** de cada jugador lo que pagó,
  en **una sola operación atómica** (sala cancelada + abonos + historial), para que no
  quede nadie sin reembolso ni se devuelva dos veces. Aparece en el historial como
  "Devolución · sala cancelada". Con los créditos de prueba es igual, sin dinero real.
- **La sala sale de la lista pública** y su código deja de aceptar jugadores.
- Quien organiza también puede **borrar** una partida en borrador (sin jugadores) desde
  "Tus partidas".

Por decidir:

- ¿Se puede cancelar con la partida ya empezada? Propuesta: no; solo antes de la primera
  bolilla. Después se juega hasta terminar.
- Si pasa el plazo y hay jugadores, ¿se cierra sola o la persona decide? Propuesta:
  avisar a quien organiza y dejar elegir entre **cancelar y devolver** o **jugar con las
  filas que hay** (con el premio recalculado, ver comisión).
- ¿Quien organiza o la plataforma se queda con alguna parte si cancela? Propuesta: no,
  devolución completa.
- Pantallas nuevas del HTML: confirmar cierre de sala, aviso de sala cancelada para el
  jugador y el movimiento "Devolución" en el historial.

## Pendientes menores

- Estados que el diseño no define: vacío, error, sin conexión y permiso de cámara
  para escanear el QR.
- Decidir si "Van ganando" y la cartilla van por avance (como el diseño) o por número
  de fila.
