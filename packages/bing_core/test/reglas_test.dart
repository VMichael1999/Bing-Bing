import 'dart:math';

import 'package:bing_core/bing_core.dart';
import 'package:flutter_test/flutter_test.dart';

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
        final salidas = bolillasDemo.take(17).toSet();
        expect(filasCompletas(cartillasDemo, salidas), isEmpty);
        expect(filasAUnaBolilla(cartillasDemo, salidas), [18]);
      },
    );

    test('con la bolilla 32 (B-12) gana Lucía, la fila 5', () {
      expect(ganadoresNuevos(cartillasDemo, bolillasDemo), [4]);
      expect(bolillasDemo.last, 12);
      expect(
        ganadoresNuevos(cartillasDemo, bolillasDemo.sublist(0, 31)),
        isEmpty,
      );
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
