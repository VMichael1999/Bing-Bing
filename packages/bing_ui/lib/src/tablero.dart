import 'package:flutter/widgets.dart';

import 'colores.dart';
import 'bolilla.dart';
import 'punto.dart';
import 'tema.dart';
import 'tipografia.dart';

/// Tablero de la tómbola (`.brows`): una fila por columna con sus 15 números.
/// Los que ya salieron se pintan del color de su columna y el último lleva un
/// aro de `tinta`.
class BingTablero extends StatelessWidget {
  const BingTablero({
    super.key,
    required this.columnas,
    required this.salidas,
    required this.letras,
    this.ultima,
  });

  final int columnas;
  final Set<int> salidas;
  final List<String> letras;
  final int? ultima;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: paleta.tarjeta,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var c = 0; c < columnas; c++) ...[
            if (c > 0) const SizedBox(height: 5),
            _FilaTablero(
              columna: c,
              salidas: salidas,
              letra: letras[c],
              ultima: ultima,
            ),
          ],
        ],
      ),
    );
  }
}

class _FilaTablero extends StatelessWidget {
  const _FilaTablero({
    required this.columna,
    required this.salidas,
    required this.letra,
    required this.ultima,
  });

  final int columna;
  final Set<int> salidas;
  final String letra;
  final int? ultima;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final color = BingBolillaColor.deColumna(columna);
    return Row(
      children: [
        SizedBox(width: 22, child: BingPunto(columna: columna, texto: letra)),
        for (var k = 1; k <= 15; k++) ...[
          const SizedBox(width: 2),
          Expanded(
            child: _Numero(
              numero: columna * 15 + k,
              salio: salidas.contains(columna * 15 + k),
              esUltima: ultima == columna * 15 + k,
              color: color,
              paleta: paleta,
            ),
          ),
        ],
      ],
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero({
    required this.numero,
    required this.salio,
    required this.esUltima,
    required this.color,
    required this.paleta,
  });

  final int numero;
  final bool salio;
  final bool esUltima;
  final BingBolillaColor color;
  final BingPaleta paleta;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: salio ? color.fondo : paleta.suave,
          // CSS pinta la primera sombra encima: el aro exterior va primero.
          boxShadow:
              esUltima
                  ? [
                    BoxShadow(color: paleta.tinta, spreadRadius: 3),
                    BoxShadow(color: paleta.tarjeta, spreadRadius: 1.5),
                  ]
                  : null,
        ),
        child: Text(
          '$numero',
          style: BingTexto.figtree(
            8,
            800,
            tabular: true,
          ).copyWith(color: salio ? color.tinta : paleta.apagado),
        ),
      ),
    );
  }
}

/// Bolillas recientes en una fila: la primera grande y las demás normales.
class BingBandejaBolillas extends StatelessWidget {
  const BingBandejaBolillas({
    super.key,
    required this.ultimas,
    required this.letras,
    required this.columnas,
  });

  /// Bolillas de la más reciente a la más antigua.
  final List<int> ultimas;
  final List<String> letras;
  final int columnas;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Row(
        children: [
          for (var i = 0; i < ultimas.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            BingBolilla(
              columna: (ultimas[i] - 1) ~/ 15,
              numero: ultimas[i],
              letra: columnas == 5 ? letras[(ultimas[i] - 1) ~/ 15] : null,
              tamano: i == 0 ? BingBolillaTamano.lg : BingBolillaTamano.normal,
            ),
          ],
        ],
      ),
    );
  }
}
