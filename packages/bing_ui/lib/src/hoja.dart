import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'tema.dart';
import 'tipografia.dart';

/// Hoja inferior sobre la pantalla (`.modal` + `.sheet`): el fondo se desenfoca
/// 1 dp y se cubre con un velo `rgba(4,5,14,.66)`.
class BingHoja extends StatelessWidget {
  const BingHoja({
    super.key,
    required this.fondo,
    required this.titulo,
    required this.texto,
    required this.children,
    this.alIzquierda = false,
    this.alCerrar,
  });

  /// Pantalla que queda detrás.
  final Widget fondo;
  final String titulo;
  final String texto;

  /// Contenido entre el texto y los botones (por ejemplo, los círculos).
  final List<Widget> children;

  /// Variante `.sheet.left`: agarradera arriba, título de 26 y texto a la
  /// izquierda, sin ancho máximo.
  final bool alIzquierda;

  /// Se llama al tocar el velo de atrás.
  final VoidCallback? alCerrar;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 1, sigmaY: 1),
            child: fondo,
          ),
        ),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: alCerrar,
            child: const ColoredBox(color: Color(0xA804050E)),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
            decoration: BoxDecoration(
              color: paleta.tarjeta,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  alIzquierda
                      ? CrossAxisAlignment.stretch
                      : CrossAxisAlignment.center,
              children: [
                if (alIzquierda) ...[
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: paleta.linea,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Text(
                  titulo,
                  textAlign: alIzquierda ? TextAlign.left : TextAlign.center,
                  style: (alIzquierda
                          ? BingTexto.tituloHoja.copyWith(fontSize: 26)
                          : BingTexto.tituloHoja)
                      .copyWith(color: paleta.dauber),
                ),
                if (texto.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: alIzquierda ? double.infinity : 260,
                    ),
                    child: Text(
                      texto,
                      textAlign:
                          alIzquierda ? TextAlign.left : TextAlign.center,
                      style: BingTexto.figtree(
                        14,
                        400,
                      ).copyWith(color: paleta.apagado),
                    ),
                  ),
                ],
                for (final c in children) ...[const SizedBox(height: 14), c],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
