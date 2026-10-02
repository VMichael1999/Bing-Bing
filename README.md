# Bing Bing

Bingo para reuniones, en dos apps Flutter para Android e iOS.

| App | Para quién | Qué hace |
| --- | --- | --- |
| **Bing Bing Host** | Quien organiza | Crea la sala, comparte el código y saca las bolillas. |
| **Bing Bing Play** | Quien juega | Entra con código o QR, reserva una fila y sigue la partida en vivo. |

La sala tiene 20 filas, una por jugador, de 5 números (75 bolillas) o de 6 (90 bolillas). Gana la primera fila completa.

## Estado

Las **15 pantallas** del diseño están hechas en **modo demo** (datos en memoria,
sin Firebase): 9 de Host y 6 de Play. La lógica del juego y el backend tienen
pruebas; **aún no hay conexión entre las apps y Firebase**.

| Parte | Estado |
| --- | --- |
| Reglas del juego (`bing_core`) | Hecho, con pruebas |
| Sistema visual (`bing_ui`): tokens, bolilla, celdas, filas, componentes | Hecho, con pruebas golden |
| Play `jug-01` a `jug-06` | Hecho en modo demo |
| Host `org-01` a `org-09` | Hecho en modo demo, con sorteo animado |
| Backend (`backend/`): reservas, sorteo y ganadores | Escrito y probado en lógica; sin probar con el emulador de Firebase |
| Conectar las apps a Firebase | Pendiente (necesita un proyecto de Firebase) |

## Modo demo

Las dos apps arrancan con los datos exactos del diseño (sala K7Q4, "Bingo de los
sábados", organiza Carmen). Para abrir una pantalla concreta sin recorrer el flujo:

```bash
cd apps/host && flutter run --dart-define=BING_PANTALLA=org-06-bolilla
cd apps/play && flutter run --dart-define=BING_PANTALLA=jug-05-en-vivo
```

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
cd backend/functions && npm install && npm test
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
- iOS: el *bundle id* de cada app en Xcode (revísalo en `ios/Runner.xcodeproj`)

Para el inicio de sesión con Google en Android, Firebase pide el SHA-1 de tu llave de
depuración: `cd apps/host/android && ./gradlew signingReport`. Las Cloud Functions
necesitan el plan Blaze de Firebase.

## Contribuir

Lee [CONTRIBUTING.md](CONTRIBUTING.md). Las ideas y los errores se reportan en los issues.

## Licencia

[MIT](LICENSE)
