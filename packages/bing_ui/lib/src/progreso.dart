import 'package:flutter/widgets.dart';

import 'tema.dart';
import 'tipografia.dart';

/// Círculos de ocupación (`.slots`): 10 columnas, gap 4. Los ocupados van en
/// `dauber` con su número.
class BingOcupacion extends StatelessWidget {
  const BingOcupacion({super.key, required this.total, required this.ocupadas});

  final int total;
  final int ocupadas;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        const columnas = 10, gap = 4.0;
        final lado = (c.maxWidth - gap * (columnas - 1)) / columnas;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 1; i <= total; i++)
              Container(
                width: lado,
                height: lado,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= ocupadas ? paleta.dauber : paleta.suave,
                ),
                child: Text(
                  '$i',
                  style: BingTexto.figtree(9, 800).copyWith(
                    color: i <= ocupadas ? paleta.dauberTinta : paleta.apagado,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Tarjeta de progreso (`.progress`): contador, texto y barra de 8 dp.
class BingProgreso extends StatelessWidget {
  const BingProgreso({
    super.key,
    required this.ocupadas,
    required this.total,
    required this.texto,
    this.conCirculos = false,
  });

  final int ocupadas;
  final int total;
  final String texto;

  /// Agrega los círculos de ocupación debajo (`jug-04`).
  final bool conCirculos;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: paleta.tarjeta,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _CabeceraProgreso(contador: '$ocupadas de $total', texto: texto),
          const SizedBox(height: 6),
          if (conCirculos)
            BingOcupacion(total: total, ocupadas: ocupadas)
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 8,
                color: paleta.suave,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: (ocupadas / total).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: paleta.dauber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Fila "contador + texto" con el reparto de ancho de `flex-shrink` de CSS: si
/// no caben, cada uno se encoge en proporción a su ancho natural y puede
/// partirse en varias líneas (así sale en el diseño de `jug-04`).
class _CabeceraProgreso extends StatelessWidget {
  const _CabeceraProgreso({required this.contador, required this.texto});

  final String contador;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final estiloContador = BingTexto.contadorProgreso.copyWith(
      color: paleta.tinta,
    );
    final estiloTexto = BingTexto.figtree(
      12,
      700,
    ).copyWith(color: paleta.apagado);

    double natural(String t, TextStyle e) =>
        (TextPainter(
          text: TextSpan(text: t, style: e),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout()).width;

    return LayoutBuilder(
      builder: (context, c) {
        final nc = natural(contador, estiloContador);
        final nt = natural(texto, estiloTexto);
        final exceso = nc + nt - c.maxWidth;
        final wc =
            (exceso > 0 ? nc - exceso * nc / (nc + nt) : nc).ceilToDouble();
        final wt = exceso > 0 ? c.maxWidth - wc : nt.ceilToDouble();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(width: wc, child: Text(contador, style: estiloContador)),
            SizedBox(
              width: wt,
              child: Text(
                texto,
                textAlign: TextAlign.right,
                style: estiloTexto,
              ),
            ),
          ],
        );
      },
    );
  }
}
