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

Widget _lienzo(Widget hijo) => Directionality(
  textDirection: TextDirection.ltr,
  child: ColoredBox(
    color: const Color(0xFFEDF0F6),
    child: Center(child: RepaintBoundary(child: hijo)),
  ),
);

void main() {
  setUpAll(() async {
    await _cargarFuente('Bungee', 'assets/fonts/Bungee-Regular.ttf');
    await _cargarFuente('Figtree', 'assets/fonts/Figtree-Variable.ttf');
  });

  const letras = ['B', 'I', 'N', 'G', 'O'];
  const numeros = [7, 22, 38, 52, 68];

  for (final tamano in BingBolillaTamano.values) {
    testWidgets('bolilla ${tamano.name} en sus 5 colores', (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 220));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _lienzo(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var c = 0; c < 5; c++)
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: BingBolilla(
                    columna: c,
                    numero: numeros[c],
                    letra: letras[c],
                    tamano: tamano,
                  ),
                ),
            ],
          ),
        ),
      );
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/bolilla_${tamano.name}.png'),
      );
    }, skip: !Platform.isMacOS); // El render de texto cambia entre sistemas.
  }

  testWidgets('sin letra (6 columnas) solo muestra el número', (tester) async {
    await tester.pumpWidget(_lienzo(const BingBolilla(columna: 5, numero: 81)));
    expect(find.text('81'), findsOneWidget);
    expect(find.text('B'), findsNothing);
  });

  testWidgets('tiene el diámetro de cada variante', (tester) async {
    for (final tamano in BingBolillaTamano.values) {
      await tester.pumpWidget(
        _lienzo(BingBolilla(columna: 0, numero: 1, tamano: tamano)),
      );
      expect(
        tester.getSize(find.byType(CustomPaint).last),
        Size.square(tamano.diametro),
      );
    }
  });

  testWidgets('admite un diámetro propio', (tester) async {
    await tester.pumpWidget(
      _lienzo(const BingBolilla(columna: 1, numero: 23, diametro: 46)),
    );
    expect(
      tester.getSize(find.byType(CustomPaint).last),
      const Size.square(46),
    );
  });
}
