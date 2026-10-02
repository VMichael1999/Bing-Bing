import 'package:flutter/widgets.dart';

import 'icono.dart';
import 'medidas.dart';
import 'tema.dart';
import 'tipografia.dart';

/// Variantes del botón (`.btn.ink`, `.btn.dau`, `.btn.line`).
enum BingBotonTipo { tinta, dauber, linea }

/// Botón de 52 dp con radio 16. Al presionarlo se achica a 0.95 en 150 ms.
class BingBoton extends StatefulWidget {
  const BingBoton({
    super.key,
    required this.texto,
    required this.tipo,
    this.icono,
    this.alPresionar,
    this.deshabilitado = false,
  });

  final String texto;
  final BingBotonTipo tipo;

  /// Nombre del ícono a la izquierda del texto.
  final String? icono;
  final VoidCallback? alPresionar;

  /// Se ve al 50 % y no responde (`aria-disabled`).
  final bool deshabilitado;

  @override
  State<BingBoton> createState() => _BingBotonState();
}

class _BingBotonState extends State<BingBoton> {
  bool _presionado = false;

  void _poner(bool valor) {
    if (_presionado != valor) setState(() => _presionado = valor);
  }

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final (fondo, texto, borde) = switch (widget.tipo) {
      BingBotonTipo.tinta => (paleta.tinta, paleta.fondo, null),
      BingBotonTipo.dauber => (paleta.dauber, paleta.dauberTinta, null),
      BingBotonTipo.linea => (paleta.tarjeta, paleta.tinta, paleta.linea),
    };
    final reducir = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Semantics(
      button: true,
      enabled: !widget.deshabilitado,
      label: widget.texto,
      child: Opacity(
        opacity: widget.deshabilitado ? 0.5 : 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.deshabilitado ? null : (_) => _poner(true),
          onTapUp: (_) => _poner(false),
          onTapCancel: () => _poner(false),
          onTap: widget.deshabilitado ? null : widget.alPresionar,
          child: AnimatedScale(
            scale: _presionado ? 0.95 : 1,
            duration:
                reducir ? Duration.zero : const Duration(milliseconds: 150),
            child: Container(
              height: BingMedidas.alturaBoton,
              decoration: BoxDecoration(
                color: fondo,
                borderRadius: BorderRadius.circular(BingMedidas.radioBoton),
                border:
                    borde == null ? null : Border.all(color: borde, width: 1.5),
              ),
              alignment: Alignment.center,
              child: ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icono != null) ...[
                      BingIcono(widget.icono!, color: texto),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.texto,
                      style: BingTexto.boton.copyWith(color: texto),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
