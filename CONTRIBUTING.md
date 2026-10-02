# Cómo contribuir

¡Gracias por querer ayudar! Este proyecto prefiere cambios pequeños y claros.

## Antes de empezar

1. Busca en los issues si ya existe lo que quieres hacer. Si no, abre uno.
2. Haz fork del repositorio y crea una rama con prefijo según el tipo de trabajo:
   `feature/`, `fix/`, `chore/`, `docs/`, `test/` o `refactor/`.

## Flujo

- Un PR por rama y un cambio útil por PR.
- Commits atómicos, en [Conventional Commits](https://www.conventionalcommits.org/es/) y en español, por ejemplo `fix: corrige el marcado de la celda`.
- No hagas commits directos en `master`.

## Antes de abrir el PR

```bash
dart format .
flutter analyze
flutter test   # dentro de cada app o paquete que toques
```

El CI ejecuta lo mismo y debe quedar en verde.

## Diseño

La interfaz replica un diseño ya aprobado. Si tu cambio toca lo visual, explica en el PR cómo se compara con el diseño de referencia. No añadas pantallas ni animaciones nuevas sin discutirlo antes en un issue.

## Código de conducta

Sé respetuoso. Las críticas van al código, no a las personas.
