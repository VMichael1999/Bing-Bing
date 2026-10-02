# Bing Bing

Bingo para reuniones, en dos apps Flutter para Android e iOS.

| App | Para quién | Qué hace |
| --- | --- | --- |
| **Bing Bing Host** | Quien organiza | Crea la sala, comparte el código y saca las bolillas. |
| **Bing Bing Play** | Quien juega | Entra con código o QR, reserva una fila y sigue la partida en vivo. |

La sala tiene 20 filas, una por jugador, de 5 números (75 bolillas) o de 6 (90 bolillas). Gana la primera fila completa.

> **Estado:** en construcción. Por ahora existe la estructura del proyecto; las pantallas, la bolilla y las reglas del juego llegan en PRs pequeños.

## Estructura

```
apps/host/          Bing Bing Host (tema oscuro)
apps/play/          Bing Bing Play (tema claro)
packages/bing_ui/   Tokens visuales, bolilla y componentes
packages/bing_core/ Entidades y reglas del juego
```

## Empezar

Requisitos: Flutter 3.29.2 o superior (Dart 3.7+).

```bash
flutter pub get
flutter analyze
cd apps/host && flutter test
```

Para correr una app: `cd apps/host && flutter run` (o `apps/play`).

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
