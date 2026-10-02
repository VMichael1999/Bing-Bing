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

Decidido:

- **No se puede cancelar con la partida ya empezada.** Solo antes de la primera bolilla;
  después se juega hasta terminar.
- **Pasado el plazo, la persona que organiza decide** si cierra la sala o sigue. No se
  cierra sola.
- **Devolución completa.** Ni quien organiza ni la plataforma se quedan con nada, porque
  la partida no se jugó.

Aviso al jugador (hecho): si quien organiza cierra la sala, en Play sube un diálogo "La
sala se cerró" **esté la persona donde esté dentro de la sala** (aunque tenga Mi billetera u
otra pantalla encima). Con motivo: "Carmen cerró «X» antes de empezar. Motivo: …". **Sin
motivo**: "… porque no se llegó al número de jugadores necesario". Si había pagado filas,
dice cuántos créditos se le devolvieron.

Por decidir:

- Si pasa el plazo y hay jugadores, ¿qué opciones se le ofrecen a quien organiza?
  Propuesta: **cancelar y devolver** o **jugar con las filas que hay** (con el premio
  recalculado, ver comisión).
- Pantallas nuevas del HTML: confirmar cierre de sala, aviso de sala cancelada para el
  jugador y el movimiento "Devolución" en el historial.

## Precio, premio y comisión: lo que ya está hecho

- Al crear la sala, quien organiza fija el **precio por fila** (créditos) y el **premio**
  en una segunda pantalla (`org-10b`). Por defecto, 5 por fila y premio 80.
- El **servidor valida** los números: el precio es un entero de 0 a 1000, sin precio no
  hay premio y el premio no puede pasar de lo que queda tras la comisión (con 5 por fila,
  100 recaudados, 10 de comisión, 90 como máximo). Lo que sobra es de quien organiza.
- La **comisión es 10 %** mientras no se defina, configurable en el servidor con la
  variable `COMISION_PORCENTAJE` (sin tocar el código). Cada sala guarda la comisión
  que tenía al crearse. La app muestra el cálculo con una constante propia
  (`comisionPorcentaje` en `bing_core`): **si se cambia en el servidor, hay que cambiarla
  también allí** hasta que el servidor la entregue a la app.
- Las tarjetas de Play muestran "5 por fila · premio 80" (o "Gratis" si no hay precio).
- Cambia lo que decía el prototipo: ya no se "paga el premio con lo recaudado" si no se
  llenan las 20 filas. La partida solo empieza con las 20 filas llenas; si no se llenan,
  quien organiza cierra la sala y se devuelve todo (ver "Cerrar una sala que no se llenó").

Por definir con el negocio: el porcentaje de comisión, si se cobra al cerrar una sala
sin jugar (decidido: no) y qué pasa con lo que sobra tras el premio.

## Billetera con créditos de prueba: lo que ya está hecho

- Cada cuenta (no los invitados) tiene una **billetera en el servidor** (`billeteras/{uid}`)
  con **25 créditos de prueba** de bienvenida, sin valor en dinero y que no se retiran.
  El saldo y los movimientos solo los modifica el servidor; el cliente los lee.
- **Recargar** agrega 10, 20, 50 o 100 créditos al instante, sin cobro.
- **Elegir filas:** cada persona puede elegir **las filas que quiera** mientras le alcance el
  saldo; cada fila cuesta lo que fijó quien organiza. Quien organiza puede limitarlo a una
  fila por persona ("Solo 1"). La reserva es **todo o nada** y se cobra en la misma
  transacción: sin saldo no se reserva nada.
- **Sin saldo:** las filas se ven pero no se pueden elegir, y se ofrece recargar. La
  comprobación se repite en el servidor.
- **Cerrar una sala devuelve todo** lo pagado, fila por fila, una sola vez (aparece como
  "Devolución" en el historial).
- Una sala **gratis** (sin precio) no toca la billetera.

Pendiente de la billetera:

- **Pagar el premio** a quien gana: hoy la fila ganadora se muestra pero **no se acredita** el
  premio. Falta decidir qué pasa si ganan varias filas a la vez (empate): propuesta, dividir
  el premio en partes iguales (el resto, a quien organiza).
- **Lo de quien organiza:** lo que queda tras el premio y la comisión (en el prototipo,
  "Te quedan 10 créditos") aún no se acredita a su billetera.
- Recargas con dinero real, solo tras validar lo legal.
- Con el emulador, Play entra con una cuenta de prueba en vez de Google (no hay Google real
  contra el emulador).

## Pendientes menores

- Estados que el diseño no define: vacío, error, sin conexión y permiso de cámara
  para escanear el QR.
- Decidir si "Van ganando" y la cartilla van por avance (como el diseño) o por número
  de fila.
