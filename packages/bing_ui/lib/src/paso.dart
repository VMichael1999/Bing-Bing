import 'dart:async';

import 'package:flutter/widgets.dart';

import 'icono.dart';
import 'tema.dart';
import 'tipografia.dart';

/// Control de menos y más con el número en medio (`.stepper`).
///
/// Mantener pulsado un botón repite el cambio. Los botones se apagan en los
/// límites [min] y [max].
class BingPaso extends StatelessWidget {
  const BingPaso({
    super.key,
    required this.valor,
    required this.alCambiar,
    this.min = 0,
    this.max = 999,
    this.etiqueta = '',
  });

  final int valor;
  final ValueChanged<int> alCambiar;
  final int min;
  final int max;

  /// Qué se está cambiando, para los lectores de pantalla ("Créditos por fila").
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Boton(
          icono: 'minus',
          etiqueta: 'Bajar $etiqueta'.trim(),
          activo: valor > min,
          alPulsar: () => alCambiar(valor - 1),
        ),
        const SizedBox(width: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 26),
          child: Semantics(
            label: '$etiqueta $valor'.trim(),
            child: ExcludeSemantics(
              child: Text(
                '$valor',
                textAlign: TextAlign.center,
                style: BingTexto.bungee(
                  20,
                  tabular: true,
                ).copyWith(color: paleta.tinta),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _Boton(
          icono: 'plus',
          etiqueta: 'Subir $etiqueta'.trim(),
          activo: valor < max,
          alPulsar: () => alCambiar(valor + 1),
        ),
      ],
    );
  }
}

class _Boton extends StatefulWidget {
  const _Boton({
    required this.icono,
    required this.etiqueta,
    required this.activo,
    required this.alPulsar,
  });

  final String icono;
  final String etiqueta;
  final bool activo;
  final VoidCallback alPulsar;

  @override
  State<_Boton> createState() => _BotonState();
}

class _BotonState extends State<_Boton> {
  Timer? _repeticion;

  void _soltar() {
    _repeticion?.cancel();
    _repeticion = null;
  }

  void _mantener() {
    if (!widget.activo) return;
    _repeticion = Timer.periodic(const Duration(milliseconds: 90), (_) {
      if (!widget.activo) return _soltar();
      widget.alPulsar();
    });
  }

  @override
  void dispose() {
    _soltar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Semantics(
      button: true,
      enabled: widget.activo,
      label: widget.etiqueta,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.activo ? widget.alPulsar : null,
        onLongPressStart: (_) => _mantener(),
        onLongPressEnd: (_) => _soltar(),
        onLongPressCancel: _soltar,
        child: ExcludeSemantics(
          // El área de toque es de 44 dp aunque el botón dibuje 32.
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Opacity(
                opacity: widget.activo ? 1 : 0.4,
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: paleta.suave,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: BingIcono(
                    widget.icono,
                    color: paleta.tinta,
                    tamano: BingIconoTamano.s,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
