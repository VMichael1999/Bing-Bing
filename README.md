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

## Contribuir

Lee [CONTRIBUTING.md](CONTRIBUTING.md). Las ideas y los errores se reportan en los issues.

## Licencia

[MIT](LICENSE)
