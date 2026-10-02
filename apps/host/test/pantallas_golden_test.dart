import 'dart:io';

import 'package:bing_host/main.dart';
import 'package:bing_host/src/demo.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cargar_fuentes.dart';

/// Captura la pantalla a 320 × 700 dp, ×3 y con 44 dp de barra de estado.
Future<void> _capturar(WidgetTester tester, String id, Widget pantalla) async {
  await cargarFuentesBing();
  tester.view
    ..devicePixelRatio = 3
    ..physicalSize = const Size(320 * 3, 700 * 3)
    ..padding = const FakeViewPadding(top: 44 * 3);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(BingHostApp(inicio: pantalla));
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(WidgetsApp),
    matchesGoldenFile('goldens/$id.png'),
  );
}

void main() {
  final skip = !Platform.isMacOS; // El render de texto cambia entre sistemas.

  // Cada pantalla del diseño en modo demo, comparada con su golden.
  const ids = [
    'org-01-entrar',
    'org-02-mis-partidas',
    'org-03-nueva-partida',
    'org-04-sala-abierta',
    'org-05-cartilla-llena',
    'org-06-bolilla',
    'org-07-cartilla',
    'org-08-tablero',
    'org-09-ganador',
    'org-11-compartir',
    'org-12-qr-pantalla',
  ];
  for (final id in ids) {
    testWidgets(id, (tester) async {
      if (id == 'org-09-ganador') {
        // El confeti se compara apagado, como en la referencia.
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
      }
      await _capturar(tester, id, pantallaDemo(id)!);
    }, skip: skip);
  }
}
