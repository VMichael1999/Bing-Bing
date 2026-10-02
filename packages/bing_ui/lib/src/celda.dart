import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'medidas.dart';
import 'tema.dart';
import 'tipografia.dart';

/// Curva con la que se marca una celda (`cubic-bezier(.3,1.6,.5,1)`).
const Curve bingCurvaMarcar = Cubic(0.3, 1.6, 0.5, 1);

/// Celda compacta de la cartilla (`.cell`): 33 × 33 dp, radio 9.
///
/// Marcada: círculo `dauber` al 92 % con 3 dp de margen y el número encima.
/// [reciente] agrega los dos anillos (2 dp `tarjeta` y 4 dp `dauber`).
/// Al marcarse anima 420 ms (escala 0→1 y giro −20°→0°); al desmarcarse, 180 ms.
class BingCelda extends StatefulWidget {
  const BingCelda({
    super.key,
    required this.numero,
    this.marcada = false,
    this.reciente = false,
  });

  final int numero;
  final bool marcada;
  final bool reciente;

  @override
  State<BingCelda> createState() => _BingCeldaState();
}

class _BingCeldaState extends State<BingCelda>
    with SingleTickerProviderStateMixin {
  late final AnimationController _control = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    reverseDuration: const Duration(milliseconds: 180),
    value: widget.marcada ? 1 : 0,
  );

  @override
  void didUpdateWidget(BingCelda old) {
    super.didUpdateWidget(old);
    if (old.marcada == widget.marcada) return;
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _control.value = widget.marcada ? 1 : 0;
    } else if (widget.marcada) {
      _control.forward();
    } else {
      _control.reverse();
    }
  }

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return SizedBox(
      width: BingMedidas.filaCelda,
      height: BingMedidas.filaCelda,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paleta.suave,
          borderRadius: BorderRadius.circular(BingMedidas.celdaRadio),
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            AnimatedBuilder(
              animation: _control,
              builder: (context, _) {
                final avance =
                    widget.marcada
                        ? bingCurvaMarcar.transform(_control.value)
                        : Curves.easeOut.transform(_control.value);
                return Transform.rotate(
                  angle: -20 * math.pi / 180 * (1 - avance),
                  child: Transform.scale(
                    scale: math.max(0, avance),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: paleta.dauber.withValues(alpha: 0.92),
                        boxShadow:
                            widget.reciente
                                ? [
                                  BoxShadow(
                                    color: paleta.tarjeta,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: paleta.dauber,
                                    spreadRadius: 4,
                                  ),
                                ]
                                : null,
                      ),
                    ),
                  ),
                );
              },
            ),
            Text(
              '${widget.numero}',
              style: BingTexto.celda.copyWith(
                color: widget.marcada ? paleta.dauberTinta : paleta.tinta,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
