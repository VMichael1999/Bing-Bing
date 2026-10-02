import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'colores.dart';
import 'tema.dart';

/// Confeti de celebración, igual que el del prototipo.
///
/// 150 piezas salen desde x = centro ± 17.5 % del ancho e y = 38 % del alto.
/// Velocidad por cuadro (a 60 fps): vx en ±7.5, vy entre −19 y −4; gravedad
/// +0.35 y fricción ×0.99 en vx; rotación +0.15 rad; tamaño de 5 a 11; mitad
/// círculos y mitad rectángulos. Dura 160 cuadros y desaparece. Con "Reducir
/// movimiento" no se dibuja.
class BingConfeti extends StatefulWidget {
  const BingConfeti({super.key, this.semilla = 7});

  final int semilla;

  static const int cuadros = 160;

  @override
  State<BingConfeti> createState() => _BingConfetiState();
}

class _BingConfetiState extends State<BingConfeti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _control = AnimationController(
    vsync: this,
    duration: Duration(microseconds: (BingConfeti.cuadros * 1e6 / 60).round()),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducir = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!reducir && !_control.isAnimating && _control.value == 0) {
      _control.forward();
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
    final colores = [
      BingBolillaColor.b.fondo,
      BingBolillaColor.i.fondo,
      BingBolillaColor.g.fondo,
      BingBolillaColor.o.fondo,
      BingBolillaColor.x.fondo,
      paleta.dauber,
    ];
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _control,
          builder:
              (context, _) =>
                  _control.value == 0 || _control.isCompleted
                      ? const SizedBox.expand()
                      : CustomPaint(
                        size: Size.infinite,
                        painter: _PintorConfeti(
                          cuadro:
                              (_control.value * BingConfeti.cuadros).floor(),
                          colores: colores,
                          semilla: widget.semilla,
                        ),
                      ),
        ),
      ),
    );
  }
}

class _PintorConfeti extends CustomPainter {
  _PintorConfeti({
    required this.cuadro,
    required this.colores,
    required this.semilla,
  });

  final int cuadro;
  final List<Color> colores;
  final int semilla;

  @override
  void paint(Canvas canvas, Size size) {
    final azar = math.Random(semilla);
    for (var i = 0; i < 150; i++) {
      var x = size.width / 2 + (azar.nextDouble() - 0.5) * size.width * 0.35;
      var y = size.height * 0.38;
      var vx = (azar.nextDouble() - 0.5) * 15;
      var vy = -azar.nextDouble() * 15 - 4;
      final tamano = 5 + azar.nextDouble() * 6;
      final color = colores[azar.nextInt(colores.length)];
      final redonda = azar.nextDouble() < 0.5;
      var giro = azar.nextDouble() * 6;
      for (var f = 0; f < cuadro; f++) {
        vy += 0.35;
        x += vx;
        y += vy;
        vx *= 0.99;
        giro += 0.15;
      }
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(giro);
      final pintura = Paint()..color = color;
      if (redonda) {
        canvas.drawCircle(Offset.zero, tamano * 0.6, pintura);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: tamano,
            height: tamano / 2,
          ),
          pintura,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PintorConfeti old) => old.cuadro != cuadro;
}
