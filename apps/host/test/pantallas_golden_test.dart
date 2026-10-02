import 'dart:io';

import 'package:bing_host/main.dart';
import 'package:bing_host/src/paginas/entrar_page.dart';
import 'package:bing_host/src/paginas/mis_partidas_page.dart';
import 'package:bing_host/src/paginas/nueva_partida_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _cargarFuente(String familia, String ruta) async {
  final cargador = FontLoader('packages/bing_ui/$familia')
    ..addFont(Future.value(ByteData.sublistView(File(ruta).readAsBytesSync())));
  await cargador.load();
}

/// Captura la pantalla a 320 × 700 dp, ×3 y con 44 dp de barra de estado.
Future<void> _capturar(WidgetTester tester, String id, Widget pantalla) async {
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
  await tester.pumpWidget(BingHostApp(inicio: pantalla));
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(WidgetsApp),
    matchesGoldenFile('goldens/$id.png'),
  );
}

void main() {
  final skip = !Platform.isMacOS; // El render de texto cambia entre sistemas.

  testWidgets('org-01-entrar', (tester) async {
    await _capturar(tester, 'org-01-entrar', const EntrarPage());
  }, skip: skip);

  testWidgets('org-02-mis-partidas', (tester) async {
    await _capturar(
      tester,
      'org-02-mis-partidas',
      const MisPartidasPage(organizador: 'Carmen', partidas: partidasDemo),
    );
  }, skip: skip);

  testWidgets('org-03-nueva-partida', (tester) async {
    await _capturar(
      tester,
      'org-03-nueva-partida',
      const NuevaPartidaPage(nombreInicial: 'Bingo de los sábados'),
    );
  }, skip: skip);
}
