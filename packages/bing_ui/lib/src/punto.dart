import 'package:flutter/widgets.dart';

import 'colores.dart';
import 'tipografia.dart';

/// Punto de columna (`.dot`): círculo de 22 dp con la letra o el número.
class BingPunto extends StatelessWidget {
  const BingPunto({
    super.key,
    required this.columna,
    required this.texto,
    this.diametro = 22,
  });

  final int columna;
  final String texto;
  final double diametro;

  @override
  Widget build(BuildContext context) {
    final color = BingBolillaColor.deColumna(columna);
    return CustomPaint(
      size: Size.square(diametro),
      painter: _PintorPunto(color.fondo, blanco: columna == 2),
      child: SizedBox(
        width: diametro,
        height: diametro,
        child: Center(
          child: Text(
            texto,
            style: BingTexto.bungee(11).copyWith(color: color.tinta),
          ),
        ),
      ),
    );
  }
}

class _PintorPunto extends CustomPainter {
  const _PintorPunto(this.fondo, {required this.blanco});

  final Color fondo;
  final bool blanco;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final circulo = Path()..addOval(rect);
    canvas.drawOval(rect, Paint()..color = fondo);
    if (blanco) {
      // `.k-n.dot`: solo anillo interior de 1 px.
      canvas.drawOval(
        rect.deflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0x2E181C33),
      );
      return;
    }
    // `inset 0 -2px 4px rgba(0,0,0,.15)`.
    canvas.save();
    canvas.clipPath(circulo);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect.inflate(size.width)),
        circulo.shift(const Offset(0, -2)),
      ),
      Paint()
        ..color = const Color(0x26000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PintorPunto old) =>
      old.fondo != fondo || old.blanco != blanco;
}
