import 'dart:async';

import 'package:flutter/widgets.dart';

import 'tema.dart';
import 'tipografia.dart';

/// Muestra un aviso breve ("Enlace copiado") sobre la pantalla actual.
///
/// Desaparece solo a los [duracion]. Necesita un `Overlay`, que ya trae el
/// `Navigator` de la app.
void mostrarAvisoBing(
  BuildContext context,
  String texto, {
  Duration duracion = const Duration(milliseconds: 1800),
}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  late final OverlayEntry entrada;
  entrada = OverlayEntry(
    builder: (context) => _Aviso(texto: texto, alTerminar: entrada.remove),
  );
  overlay.insert(entrada);
  Timer(duracion, () {
    if (entrada.mounted) entrada.remove();
  });
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto, required this.alTerminar});

  final String texto;
  final VoidCallback alTerminar;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Positioned(
      left: 24,
      right: 24,
      bottom: 110,
      child: IgnorePointer(
        child: Semantics(
          liveRegion: true,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: paleta.tinta,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                texto,
                style: BingTexto.figtree(13, 800).copyWith(color: paleta.fondo),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
