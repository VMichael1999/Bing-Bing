<p align="center">
  <img src="docs/iconos/host/icon-redondeado-256.png" width="132" alt="Ícono de Bing Bing Host">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/iconos/play/icon-redondeado-256.png" width="132" alt="Ícono de Bing Bing Play">
</p>

<h1 align="center">Bing Bing</h1>

<p align="center"><b>Bingo para reuniones, en dos apps Flutter para Android e iOS.</b></p>

<table align="center">
  <tr>
    <td align="center"><b>Bing Bing Host</b><br><sub>Quien organiza: crea la sala,<br>comparte el código y saca las bolillas.</sub></td>
    <td align="center"><b>Bing Bing Play</b><br><sub>Quien juega: entra con código o QR,<br>reserva una fila y sigue la partida en vivo.</sub></td>
  </tr>
</table>

<p align="center">
  <a href="https://github.com/VMichael1999/Bing-Bing/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/VMichael1999/Bing-Bing/actions/workflows/ci.yml/badge.svg"></a>
  <img alt="Flutter 3.29.2" src="https://img.shields.io/badge/Flutter-3.29.2-02569B?logo=flutter&logoColor=white">
  <img alt="Dart 3.7.2" src="https://img.shields.io/badge/Dart-3.7.2-0175C2?logo=dart&logoColor=white">
  <img alt="Plataformas: Android e iOS" src="https://img.shields.io/badge/plataformas-Android%20%7C%20iOS-3DDC84">
  <img alt="Tema claro y oscuro" src="https://img.shields.io/badge/tema-claro%20%2B%20oscuro-181C33">
  <br>
  <img alt="132 pruebas pasan" src="https://img.shields.io/badge/pruebas-132%20pasan-13895A">
  <img alt="Cobertura 94 %" src="https://img.shields.io/badge/cobertura-94%25-13895A">
  <img alt="Backend: TypeScript y Firebase" src="https://img.shields.io/badge/backend-TypeScript%20%7C%20Firebase-3178C6?logo=typescript&logoColor=white">
  <img alt="Licencia MIT" src="https://img.shields.io/badge/licencia-MIT-C81B60">
</p>

La sala tiene 20 filas, una por jugador, de 5 números (75 bolillas) o de 6 (90 bolillas).
Gana la primera fila completa; el backend (Cloud Functions de Firebase) hace el sorteo,
verifica la fila y todos lo ven en vivo. Las apps replican un diseño HTML aprobado, con
tema oscuro en Host y claro en Play.

## Estado

Las **15 pantallas** del diseño están hechas (9 de Host y 6 de Play) y las dos apps
funcionan **de punta a punta contra el backend**: probadas en un emulador de Android
con el emulador local de Firebase (crear la sala, llenarla en vivo, sortear hasta el
bingo y ¡Ganaste!). Sin configuración de Firebase siguen en **modo demo** con datos
falsos. Todavía **no está publicado** en Firebase (faltan las reglas y las Functions).

| Parte | Estado |
| --- | --- |
| Reglas del juego (`bing_core`) | Hecho, con pruebas |
| Sistema visual (`bing_ui`): tokens, bolilla, celdas, filas, componentes | Hecho, con pruebas golden |
| Play `jug-01` a `jug-06` | Hecho: demo y conectado al backend |
| Host `org-01` a `org-09` | Hecho: demo y conectado al backend |
| Backend (`backend/`): reservas, sorteo y ganadores | Hecho; probado contra el emulador de Firebase |
| Conexión con Firebase (`bing_firebase`) | Hecho; sesión anónima y de prueba, Google sin probar |
| Publicar reglas y Functions en Firebase | Pendiente (plan Blaze y `firebase login`) |
| Inicio de sesión con Google real | Pendiente (huella SHA-1 en Android y esquema URL en iOS) |
| Partidas de 6 columnas (90 bolillas) en Host | Pendiente: avisa "llegan pronto" |

## Métricas

Medidas el 2 de octubre de 2026 sobre el proyecto completo.

| Métrica | Valor |
| --- | --- |
| Pruebas de Flutter | **115** (`bing_core` 23, `bing_ui` 19, `bing_firebase` 26, Host 31, Play 16) |
| Pruebas del backend | **17** |
| Cobertura de líneas | **94,4 %** (`bing_ui` 99,8 %, Play 93,8 %, `bing_core` 92,8 %, Host 91,1 %, `bing_firebase` 78,9 %) |
| Código Dart | 7 138 líneas en `lib` y 2 083 en pruebas (sin líneas en blanco) |
| Código TypeScript | 538 líneas (funciones y pruebas) y 194 en scripts de prueba |
| Pantallas del diseño | **15 de 15** (9 de Host y 6 de Play) |
| Fidelidad con el diseño | ≈ 2,8 % de píxeles distintos de media; solo 3 de 15 cumplen el objetivo de menos de 1,5 % |
| Versiones | Flutter 3.29.2 (estable), Dart 3.7.2, Node 20 |

La cobertura cuenta las líneas ejecutables que cargan las pruebas. En `bing_firebase`
no se prueban con pruebas automáticas el arranque real de Firebase ni el inicio de
sesión con Google (dependen del dispositivo); esos caminos se verifican a mano con el
emulador (ver [Backend](#backend)). Los valores de las
insignias son fijos: hay que actualizarlos a mano al volver a medir. Las pruebas golden
solo corren en macOS.

```bash
cd apps/host && flutter test --coverage --coverage-package='^(bing_ui|bing_core|bing_host)$'
cd backend/functions && npm test
```

## Capturas

Tomadas en un emulador Pixel 10 Pro XL (Android 17) con **datos falsos**: la sala se
llena sola, las bolillas salen una tras otra y gana Lucía con la B-12.

### Bing Bing Play

<table>
<tr><td align="center"><img src="docs/capturas/play/01-codigo.png" width="170"><br><sub>Código de sala</sub></td><td align="center"><img src="docs/capturas/play/02-elegir-fila.png" width="170"><br><sub>Elegir fila</sub></td><td align="center"><img src="docs/capturas/play/03-reservar.png" width="170"><br><sub>Reservar</sub></td><td align="center"><img src="docs/capturas/play/04c-esperando-lleno.png" width="170"><br><sub>Esperando (20 de 20)</sub></td></tr>
<tr><td align="center"><img src="docs/capturas/play/05a-en-vivo-inicio.png" width="170"><br><sub>En vivo</sub></td><td align="center"><img src="docs/capturas/play/05c-en-vivo-final.png" width="170"><br><sub>En vivo, casi al final</sub></td><td align="center"><img src="docs/capturas/play/06b-ganaste-confeti.png" width="170"><br><sub>¡Ganaste!</sub></td></tr>
</table>

### Bing Bing Host

<table>
<tr><td align="center"><img src="docs/capturas/host/01-entrar.png" width="170"><br><sub>Entrar</sub></td><td align="center"><img src="docs/capturas/host/02-mis-partidas.png" width="170"><br><sub>Mis partidas</sub></td><td align="center"><img src="docs/capturas/host/03-nueva-partida.png" width="170"><br><sub>Nueva partida</sub></td><td align="center"><img src="docs/capturas/host/04c-sala-abierta-20.png" width="170"><br><sub>Sala abierta</sub></td></tr>
<tr><td align="center"><img src="docs/capturas/host/05-cartilla-llena.png" width="170"><br><sub>¡Cartilla llena!</sub></td><td align="center"><img src="docs/capturas/host/06b-sorteando.png" width="170"><br><sub>Sacando bolilla</sub></td><td align="center"><img src="docs/capturas/host/06d-bolilla-mitad.png" width="170"><br><sub>Partida en juego</sub></td><td align="center"><img src="docs/capturas/host/07-cartilla.png" width="170"><br><sub>Cartilla</sub></td></tr>
<tr><td align="center"><img src="docs/capturas/host/08-tablero.png" width="170"><br><sub>Tablero</sub></td><td align="center"><img src="docs/capturas/host/09a-ganador-confeti.png" width="170"><br><sub>¡Bingo!</sub></td></tr>
</table>

## Modo demo

Las dos apps arrancan con los datos exactos del diseño (sala K7Q4, "Bingo de los
sábados", organiza Carmen). Para abrir una pantalla concreta sin recorrer el flujo:

```bash
cd apps/host && flutter run --dart-define=BING_PANTALLA=org-06-bolilla
cd apps/play && flutter run --dart-define=BING_PANTALLA=jug-05-en-vivo
```

Sin esa opción, cada app arranca un **recorrido simulado** de punta a punta con datos
falsos: en Play, la sala se va llenando sola tras reservar y las bolillas salen solas
hasta que gana tu fila; en Host, la sala se llena, sube "¡Cartilla llena!" y la
partida se puede jugar a mano o con el interruptor "Automático".

### Modo real

Con los valores de Firebase en `.env` (ver [Configurar Firebase](#configurar-firebase)),
las apps usan la sala de verdad: Play entra de forma anónima, busca la sala por su
código y reserva la fila en el servidor; Host entra con Google, crea la sala, ve
cómo se llena en vivo y sortea con el servidor.

Los identificadores son los del diseño: `org-01-entrar` … `org-09-ganador` y
`jug-01-codigo` … `jug-06-ganaste`. En Host, `org-06-bolilla` parte con 17 bolillas y
cada toque saca la siguiente de la partida del diseño; con la 32 gana Lucía.

## Fidelidad con el diseño

Cada pantalla se compara con una captura del HTML de referencia
(`tools/html_ref`). Porcentaje de píxeles distintos desde y = 44 dp, con las pruebas
golden de macOS:

| Pantalla | Diferencia | Pantalla | Diferencia |
| --- | --- | --- | --- |
| `org-01` | 2,63 % | `jug-01` | 3,00 % |
| `org-02` | 1,15 % | `jug-02` | 2,36 % |
| `org-03` | 0,99 % | `jug-03` | 3,88 % |
| `org-04` | 3,79 % | `jug-04` | 3,23 % |
| `org-05` | 2,38 % | `jug-05` | 4,69 % |
| `org-06` | 3,37 % | `jug-06` | 4,24 % |
| `org-07` | 1,09 % | | |
| `org-08` | 1,75 % | | |
| `org-09` | 2,87 % | | |

El objetivo era menos de 1,5 %; solo `org-02`, `org-03` y `org-07` lo cumplen. Una
parte son diferencias intencionadas ("Bing Bing" en lugar de "Bolilla", el QR real)
y otra es suavizado de texto entre Chromium y Skia. Para repetir la comparación:
`python3 tools/html_ref/comparar.py referencia.png flutter.png salida.png`.

## Backend

`backend/functions` son Cloud Functions en TypeScript (`crearSala`, `reservarFila`,
`empezarPartida`, `sacarBolilla`, `deshacerBolilla`, `terminarPartida`). El azar y
las reservas se resuelven en el servidor y las reglas de Firestore
(`backend/firestore.rules`) no permiten escribir desde los clientes.

```bash
cd backend/functions && npm install && npm test     # pruebas de la lógica
```

### Probar con el emulador (gratis, sin Blaze)

```bash
npx firebase-tools emulators:start --only auth,functions,firestore --project bingbing-f1491
node backend/scripts/humo.mjs                       # una partida completa, sin apps
```

Con el emulador en marcha, las apps se conectan con `--dart-define=USE_FIREBASE_EMULATOR=true`
(desde el emulador de Android, el Mac es `10.0.2.2`):

```bash
cd apps/play && flutter run --dart-define-from-file=../../.env --dart-define=USE_FIREBASE_EMULATOR=true
cd apps/host && flutter run --dart-define-from-file=../../.env --dart-define=USE_FIREBASE_EMULATOR=true
```

En ese modo Host entra con una cuenta de prueba en lugar de Google. Para simular a
la organizadora y a los demás jugadores mientras pruebas una app:

```bash
node backend/scripts/sala-demo.mjs crear            # sala nueva con 4 filas tomadas
node backend/scripts/sala-demo.mjs llenar CODIGO    # el resto de jugadores
node backend/scripts/sala-demo.mjs empezar CODIGO
node backend/scripts/sala-demo.mjs ganar CODIGO 5   # hace ganar la fila 5
```

## Configurar Firebase

Las claves y archivos de tu proyecto **no se suben a git**:

| Archivo | Para qué | En git |
| --- | --- | --- |
| `.env` | Valores del proyecto (ver `.env.example`) | No |
| `apps/*/android/app/google-services.json` | Configuración de Android | No |
| `apps/*/ios/Runner/GoogleService-Info.plist` | Configuración de iOS | No |
| `.env.example` | Plantilla sin valores reales | Sí |

```bash
cp .env.example .env     # rellénalo con los datos de la consola de Firebase
cd apps/host && flutter run --dart-define-from-file=../../.env
```

Registra las apps en Firebase con estos identificadores:

- Android: `pe.bingbing.bing_host` y `pe.bingbing.bing_play`
- iOS: `pe.bingbing.bingHost` y `pe.bingbing.bingPlay`

En Authentication activa **Anónimo** (jugadores) y **Google** (organizadores) y crea
una base de datos de Firestore en modo producción; las reglas se publican desde
`backend/firestore.rules`.

Para el inicio de sesión con Google en Android, Firebase pide el SHA-1 de tu llave de
depuración: `cd apps/host/android && ./gradlew signingReport`. Las Cloud Functions
necesitan el plan Blaze de Firebase.

## Contribuir

Lee [CONTRIBUTING.md](CONTRIBUTING.md). Las ideas y los errores se reportan en los issues.

## Licencia

[MIT](LICENSE)
