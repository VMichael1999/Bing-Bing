import 'dart:math';

import 'package:bing_core/bing_core.dart';
import 'package:flutter_test/flutter_test.dart';

// Datos del modo demo: 20 cartillas y bolillas en orden de salida.
const cartillasDemo = [
  [6, 24, 39, 52, 72],
  [14, 26, 41, 57, 67],
  [10, 28, 45, 58, 75],
  [6, 28, 31, 59, 72],
  [12, 21, 36, 49, 70],
  [8, 29, 32, 56, 62],
  [4, 16, 44, 58, 75],
  [10, 20, 40, 60, 64],
  [10, 27, 33, 53, 74],
  [4, 25, 45, 59, 62],
  [2, 25, 32, 52, 65],
  [9, 17, 32, 47, 73],
  [15, 24, 39, 60, 70],
  [13, 28, 33, 50, 62],
  [3, 24, 39, 46, 75],
  [10, 29, 44, 57, 63],
  [3, 26, 39, 46, 69],
  [12, 20, 31, 58, 67],
  [8, 21, 36, 49, 67],
  [13, 19, 41, 47, 62],
];
const ordenDemo = [
  36, 40, 57, 64, 14, 66, 21, 60, 50, 68, 49, 8, 63, 59, 56, 26, //
  31, 53, 38, 69, 65, 43, 74, 58, 61, 62, 73, 39, 13, 70, 6, 12,
];

void main() {
  group('generarCartillas', () {
    test('respeta el rango de cada columna', () {
      for (final columnas in [5, 6]) {
        final cartillas = generarCartillas(
          columnas: columnas,
          random: Random(1),
        );
        expect(cartillas, hasLength(20));
        for (final fila in cartillas) {
          expect(fila, hasLength(columnas));
          for (var c = 0; c < columnas; c++) {
            expect(columnaDe(fila[c]), c);
          }
        }
      }
    });
  });

  group('etiqueta y totales', () {
    test('B-12 con 5 columnas y 12 con 6', () {
      expect(etiqueta(12, 5), 'B-12');
      expect(etiqueta(75, 5), 'O-75');
      expect(etiqueta(12, 6), '12');
    });
    test('total de bolillas', () {
      expect(totalBolillas(5), 75);
      expect(totalBolillas(6), 90);
    });
  });

  group('partida de demostración', () {
    test(
      'con las 17 primeras bolillas nadie ha ganado y solo la fila 19 está a una',
      () {
        final salidas = ordenDemo.take(17).toSet();
        expect(filasCompletas(cartillasDemo, salidas), isEmpty);
        expect(filasAUnaBolilla(cartillasDemo, salidas), [18]);
      },
    );

    test('con la bolilla 32 (B-12) gana Lucía, la fila 5', () {
      expect(ganadoresNuevos(cartillasDemo, ordenDemo), [4]);
      expect(ordenDemo.last, 12);
      expect(ganadoresNuevos(cartillasDemo, ordenDemo.sublist(0, 31)), isEmpty);
    });
  });

  group('ganadoresNuevos', () {
    test(
      'detecta el empate cuando dos filas completan con la misma bolilla',
      () {
        final cartillas = [
          [1, 16, 31, 46, 61],
          [1, 17, 32, 47, 62],
        ];
        expect(
          ganadoresNuevos(cartillas, [16, 31, 46, 61, 17, 32, 47, 62, 1]),
          [0, 1],
        );
      },
    );
    test('sin bolillas no hay ganadores', () {
      expect(ganadoresNuevos(cartillasDemo, const []), isEmpty);
    });
  });

  group('sacarBolilla', () {
    test('nunca repite y se vacía al agotarse', () {
      final azar = Random(7);
      final salidas = <int>[];
      for (var i = 0; i < 75; i++) {
        final n = sacarBolilla(columnas: 5, salidas: salidas, random: azar);
        expect(n, isNotNull);
        expect(salidas, isNot(contains(n)));
        salidas.add(n!);
      }
      expect(sacarBolilla(columnas: 5, salidas: salidas), isNull);
    });
  });
}
