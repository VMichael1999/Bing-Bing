import 'dart:io';

import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _cargarFuente(String familia, String ruta) async {
  final cargador = FontLoader('packages/bing_ui/$familia')
    ..addFont(Future.value(ByteData.sublistView(File(ruta).readAsBytesSync())));
  await cargador.load();
}

Widget _tema(BingPaleta paleta, Widget hijo, {double ancho = 284}) =>
    Directionality(
      textDirection: TextDirection.ltr,
      child: BingTema(
        paleta: paleta,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Center(
            child: RepaintBoundary(
              child: ColoredBox(
                color: paleta.tarjeta,
                child: SizedBox(width: ancho, child: hijo),
              ),
            ),
          ),
        ),
      ),
    );

const _fila = [12, 21, 36, 49, 70];

void main() {
  setUpAll(() async {
    await _cargarFuente('Bungee', 'assets/fonts/Bungee-Regular.ttf');
    await _cargarFuente('Figtree', 'assets/fonts/Figtree-Variable.ttf');
  });

  group('BingFilaCompacta', () {
    BingFilaCompacta fila(Set<int> salidas, {bool mia = false}) =>
        BingFilaCompacta(
          indice: 5,
          numeros: _fila,
          salidas: salidas,
          nombre: 'Lucía',
          esMia: mia,
        );

    testWidgets('mide 39 dp de alto y la celda 33 × 33', (tester) async {
      await tester.pumpWidget(_tema(BingPaleta.claro, fila({12})));
      expect(tester.getSize(find.byType(BingFilaCompacta)).height, 39);
      expect(tester.getSize(find.byType(BingCelda).first), const Size(33, 33));
    });

    testWidgets('muestra el avance en cada estado', (tester) async {
      await tester.pumpWidget(_tema(BingPaleta.claro, fila({12, 21})));
      expect(find.text('2 de 5'), findsOneWidget);

      await tester.pumpWidget(_tema(BingPaleta.claro, fila({12, 21, 36, 49})));
      expect(find.text('Le falta 1'), findsOneWidget);
      expect(
        tester.widget<BingFilaCompacta>(find.byType(BingFilaCompacta)).estado,
        BingEstadoFila.cerca,
      );

      await tester.pumpWidget(_tema(BingPaleta.claro, fila(_fila.toSet())));
      expect(find.text('¡Bingo!'), findsOneWidget);
      expect(
        tester.widget<BingFilaCompacta>(find.byType(BingFilaCompacta)).estado,
        BingEstadoFila.ganadora,
      );
    });

    testWidgets('el nombre largo se recorta en una línea', (tester) async {
      await tester.pumpWidget(
        _tema(
          BingPaleta.claro,
          BingFilaCompacta(
            indice: 1,
            numeros: _fila,
            salidas: const {},
            nombre: 'Un nombre larguísimo que no cabe',
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('golden de los estados en claro y oscuro', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 520));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final (nombre, paleta) in [
        ('claro', BingPaleta.claro),
        ('oscuro', BingPaleta.oscuro),
      ]) {
        await tester.pumpWidget(
          _tema(
            paleta,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                fila({12, 21}),
                fila({12, 21, 36, 49}),
                fila(_fila.toSet()),
                fila({12}, mia: true),
                BingFilaCompacta(
                  indice: 5,
                  numeros: _fila,
                  salidas: const {12, 21},
                  recientes: const {21},
                  nombre: 'Lucía',
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(RepaintBoundary).first,
          matchesGoldenFile('goldens/fila_compacta_$nombre.png'),
        );
      }
    }, skip: !Platform.isMacOS);
  });

  group('BingFilaGrande', () {
    testWidgets('pinta de dauber solo los números que salieron', (
      tester,
    ) async {
      await tester.pumpWidget(
        _tema(
          BingPaleta.claro,
          const BingFilaGrande(
            numeros: _fila,
            salidas: {12, 36},
            letras: ['B', 'I', 'N', 'G', 'O'],
          ),
        ),
      );
      final circulos = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.constraints?.maxWidth == 44);
      final marcados = circulos.where((c) {
        final d = c.decoration! as BoxDecoration;
        return d.color == BingPaleta.claro.dauber;
      });
      expect(circulos, hasLength(5));
      expect(marcados, hasLength(2));
    });

    testWidgets('golden claro y oscuro', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 260));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final (nombre, paleta) in [
        ('claro', BingPaleta.claro),
        ('oscuro', BingPaleta.oscuro),
      ]) {
        await tester.pumpWidget(
          _tema(
            paleta,
            const Padding(
              padding: EdgeInsets.all(12),
              child: BingFilaGrande(
                numeros: _fila,
                salidas: {12, 21, 36},
                recientes: {36},
                letras: ['B', 'I', 'N', 'G', 'O'],
              ),
            ),
            ancho: 296,
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(RepaintBoundary).first,
          matchesGoldenFile('goldens/fila_grande_$nombre.png'),
        );
      }
    }, skip: !Platform.isMacOS);
  });

  group('BingCelda', () {
    testWidgets('anima 420 ms al marcarse y salta con movimiento reducido', (
      tester,
    ) async {
      Widget celda(bool marcada, {bool reducir = false}) => Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: reducir),
          child: BingTema(
            paleta: BingPaleta.claro,
            child: BingCelda(numero: 12, marcada: marcada),
          ),
        ),
      );
      double escala() => tester
          .widget<Transform>(
            find
                .descendant(
                  of: find.byType(BingCelda),
                  matching: find.byType(Transform),
                )
                .last,
          )
          .transform
          .entry(0, 0);

      await tester.pumpWidget(celda(false));
      expect(escala(), 0);
      await tester.pumpWidget(celda(true));
      await tester.pump(const Duration(milliseconds: 210));
      expect(escala(), inInclusiveRange(0.01, 1.6));
      await tester.pump(const Duration(milliseconds: 210));
      await tester.pumpAndSettle();
      expect(escala(), 1);

      await tester.pumpWidget(celda(false, reducir: true));
      await tester.pump();
      expect(escala(), 0);
    });
  });
}
