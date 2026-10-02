import 'dart:io';

import 'package:bing_play/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _cargarFuente(String familia, String ruta) async {
  final cargador = FontLoader('packages/bing_ui/$familia')
    ..addFont(Future.value(ByteData.sublistView(File(ruta).readAsBytesSync())));
  await cargador.load();
}

void main() {
  testWidgets('jug-01-codigo a 320 × 700 dp', (tester) async {
    await _cargarFuente(
      'Bungee',
      '../../packages/bing_ui/assets/fonts/Bungee-Regular.ttf',
    );
    await _cargarFuente(
      'Figtree',
      '../../packages/bing_ui/assets/fonts/Figtree-Variable.ttf',
    );
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = const Size(320 * 3, 700 * 3)
      ..padding = const FakeViewPadding(top: 44 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const BingPlayApp());
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(WidgetsApp),
      matchesGoldenFile('goldens/jug-01-codigo.png'),
    );
  }, skip: !Platform.isMacOS);
}
