import 'package:flutter/widgets.dart';

import 'colores.dart';
import 'tipografia.dart';

/// Tamaños de la bolilla (`.ball`, `.ball.lg`, `.ball.xl`).
enum BingBolillaTamano {
  normal(34),
  lg(48),
  xl(150);

  const BingBolillaTamano(this.diametro);
  final double diametro;
}

/// Bolilla de bingo: color de columna, brillo, sombras y cara con el número.
///
/// Con 5 columnas muestra la letra B-I-N-G-O sobre el número; con 6 no.
class BingBolilla extends StatelessWidget {
  const BingBolilla({
    super.key,
    required this.columna,
    required this.numero,
    this.letra,
    this.tamano = BingBolillaTamano.normal,
  });

  /// Índice de columna (0 = B).
  final int columna;

  /// `null` muestra un signo de pregunta (aún no ha salido ninguna).
  final int? numero;

  /// Letra pequeña sobre el número (solo con 5 columnas).
  final String? letra;
  final BingBolillaTamano tamano;

  @override
  Widget build(BuildContext context) {
    final s = tamano.diametro;
    final color = BingBolillaColor.deColumna(columna);
    final xl = tamano == BingBolillaTamano.xl;
    final grande = tamano != BingBolillaTamano.normal;

    final tamanoNumero = xl ? 52.0 : s * 0.3;
    final tamanoLetra = xl ? tamanoNumero * 0.28 : tamanoNumero * 0.5;
    final estiloNumero = (grande
            ? BingTexto.bungee(tamanoNumero, altura: 1, tabular: true)
            : BingTexto.figtree(tamanoNumero, 800, altura: 1, tabular: true))
        .copyWith(color: bingNumeroBolilla);
    final estiloLetra = BingTexto.figtree(
      tamanoLetra,
      800,
      altura: 1,
    ).copyWith(color: bingLetraBolilla);

    return Semantics(
      label:
          numero == null
              ? 'Bolilla sin sacar'
              : (letra == null ? '$numero' : '$letra-$numero'),
      image: true,
      child: ExcludeSemantics(
        child: CustomPaint(
          size: Size.square(s),
          painter: _PintorBolilla(
            fondo: color.fondo,
            blanca: columna == 2,
            xl: xl,
          ),
          child: SizedBox(
            width: s,
            height: s,
            child: Center(
              child: Container(
                width: s * 0.66,
                height: s * 0.66,
                decoration: const BoxDecoration(
                  color: bingCaraBolilla,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (letra != null) ...[
                      Text(letra!, style: estiloLetra),
                      const SizedBox(height: 1),
                    ],
                    Text(numero?.toString() ?? '?', style: estiloNumero),
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

class _PintorBolilla extends CustomPainter {
  const _PintorBolilla({
    required this.fondo,
    required this.blanca,
    required this.xl,
  });

  final Color fondo;
  final bool blanca;
  final bool xl;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final rect = Offset.zero & size;
    final circulo = Path()..addOval(rect);

    // Sombra exterior.
    final sombraExterior =
        xl
            ? const _Sombra(Offset(0, 18), 34, Color(0x59000000))
            : const _Sombra(Offset(0, 2), 5, Color(0x330E1126));
    canvas.drawPath(
      circulo.shift(sombraExterior.desplazamiento),
      Paint()
        ..color = sombraExterior.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sombraExterior.sigma),
    );

    // Color base.
    canvas.drawOval(rect, Paint()..color = fondo);

    // Sombra inferior (`radial-gradient(circle at 50% 120%, …)`).
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 1.4),
          radius: 1.3,
          colors: const [Color(0x47000000), Color(0x00000000)],
          stops: const [0, 0.6],
        ).createShader(rect),
    );

    // Brillo (`radial-gradient(circle at 32% 26%, …)`).
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.36, -0.48),
          radius: 1.005,
          colors: const [
            Color(0x99FFFFFF),
            Color(0x99FFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: const [0, 0.1, 0.34],
        ).createShader(rect),
    );

    // Sombra interior (`inset`): anillo desenfocado recortado al círculo.
    final interior =
        xl
            ? const _Sombra(Offset(0, -8), 16, Color(0x33000000))
            : _Sombra.interiorNormal(blanca);
    canvas.save();
    canvas.clipPath(circulo);
    final hueco = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect.inflate(s)),
      circulo.shift(interior.desplazamiento),
    );
    canvas.drawPath(
      hueco,
      Paint()
        ..color = interior.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, interior.sigma),
    );
    canvas.restore();

    // Anillo interior de 1 px solo en la bolilla N (blanca).
    if (blanca) {
      canvas.drawOval(
        rect.deflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0x1F181C33),
      );
    }
  }

  @override
  bool shouldRepaint(_PintorBolilla old) =>
      old.fondo != fondo || old.blanca != blanca || old.xl != xl;
}

class _Sombra {
  const _Sombra(this.desplazamiento, this.desenfoque, this.color);
  final Offset desplazamiento;
  final double desenfoque;
  final Color color;

  /// CSS `blur(Npx)` equivale a un sigma de N / 2.
  double get sigma => desenfoque / 2;

  static _Sombra interiorNormal(bool blanca) => _Sombra(
    const Offset(0, -3),
    6,
    blanca ? const Color(0x1F000000) : const Color(0x2E000000),
  );
}
