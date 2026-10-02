import 'package:flutter/widgets.dart';

import 'celda.dart';
import 'medidas.dart';
import 'punto.dart';
import 'tema.dart';
import 'tipografia.dart';

/// Estado visual de una fila de la cartilla.
enum BingEstadoFila { normal, cerca, ganadora }

/// Fila compacta (`.row`): índice, celdas, nombre y avance.
///
/// Columnas `18 · 33 × n · 1fr`, gap 4, padding 3/4, radio 11. [esMia] dibuja
/// el borde interior de 2 dp en `tinta` (la fila del jugador).
class BingFilaCompacta extends StatelessWidget {
  const BingFilaCompacta({
    super.key,
    required this.indice,
    required this.numeros,
    required this.salidas,
    required this.nombre,
    this.recientes = const {},
    this.esMia = false,
  });

  /// Número de fila que se muestra (base 1).
  final int indice;
  final List<int> numeros;
  final Set<int> salidas;
  final String nombre;

  /// Números que acaban de salir (llevan el anillo de "recién marcada").
  final Set<int> recientes;
  final bool esMia;

  int get _faltan => numeros.where((n) => !salidas.contains(n)).length;

  BingEstadoFila get estado => switch (_faltan) {
    0 => BingEstadoFila.ganadora,
    1 => BingEstadoFila.cerca,
    _ => BingEstadoFila.normal,
  };

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final faltan = _faltan;
    final colorAvance = switch (estado) {
      BingEstadoFila.ganadora => paleta.victoria,
      BingEstadoFila.cerca => paleta.cerca,
      BingEstadoFila.normal => paleta.apagado,
    };
    final textoAvance = switch (estado) {
      BingEstadoFila.ganadora => '¡Bingo!',
      BingEstadoFila.cerca => 'Le falta 1',
      BingEstadoFila.normal =>
        '${numeros.length - faltan} de ${numeros.length}',
    };
    final fondo = switch (estado) {
      BingEstadoFila.ganadora => paleta.victoriaSuave,
      BingEstadoFila.cerca => paleta.cercaSuave,
      BingEstadoFila.normal => null,
    };
    final borde =
        esMia
            ? paleta.tinta
            : (estado == BingEstadoFila.ganadora ? paleta.victoria : null);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(BingMedidas.filaRadio),
      ),
      foregroundDecoration:
          borde == null
              ? null
              : BoxDecoration(
                borderRadius: BorderRadius.circular(BingMedidas.filaRadio),
                border: Border.all(color: borde, width: 2),
              ),
      child: Row(
        children: [
          SizedBox(
            width: BingMedidas.filaIndice,
            child: Text(
              '$indice',
              textAlign: TextAlign.center,
              style: BingTexto.figtree(
                11,
                700,
                tabular: true,
              ).copyWith(color: paleta.apagado),
            ),
          ),
          for (final n in numeros) ...[
            const SizedBox(width: BingMedidas.filaGap),
            BingCelda(
              numero: n,
              marcada: salidas.contains(n),
              reciente: recientes.contains(n),
            ),
          ],
          const SizedBox(width: BingMedidas.filaGap),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BingTexto.nombreFila.copyWith(color: paleta.tinta),
                  ),
                  Text(
                    textoAvance,
                    maxLines: 1,
                    style: BingTexto.avanceFila.copyWith(color: colorAvance),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila grande (`.bigrow`): una celda por número con su punto de columna y un
/// círculo de 44 dp que se pinta de `dauber` al salir el número.
class BingFilaGrande extends StatelessWidget {
  const BingFilaGrande({
    super.key,
    required this.numeros,
    required this.salidas,
    required this.letras,
    this.recientes = const {},
  });

  final List<int> numeros;
  final Set<int> salidas;

  /// Texto del punto de cada columna (B-I-N-G-O o 1-6).
  final List<String> letras;
  final Set<int> recientes;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Row(
      children: [
        for (var i = 0; i < numeros.length; i++) ...[
          if (i > 0) const SizedBox(width: BingMedidas.filaGrandeGap),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: paleta.suave,
                borderRadius: BorderRadius.circular(
                  BingMedidas.filaGrandeRadioCelda,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BingPunto(columna: i, texto: letras[i]),
                    const SizedBox(height: 6),
                    _CirculoGrande(
                      numero: numeros[i],
                      marcada: salidas.contains(numeros[i]),
                      reciente: recientes.contains(numeros[i]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CirculoGrande extends StatelessWidget {
  const _CirculoGrande({
    required this.numero,
    required this.marcada,
    required this.reciente,
  });

  final int numero;
  final bool marcada;
  final bool reciente;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Container(
      width: BingMedidas.filaGrandeCirculo,
      height: BingMedidas.filaGrandeCirculo,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: marcada ? paleta.dauber : null,
        boxShadow:
            marcada && reciente
                ? [
                  BoxShadow(color: paleta.suave, spreadRadius: 3),
                  BoxShadow(color: paleta.dauber, spreadRadius: 5),
                ]
                : null,
      ),
      child: Text(
        '$numero',
        style: BingTexto.celdaGrande.copyWith(
          color: marcada ? paleta.dauberTinta : paleta.tinta,
        ),
      ),
    );
  }
}
