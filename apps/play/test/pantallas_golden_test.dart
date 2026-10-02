import 'dart:io';

import 'package:bing_core/bing_core.dart';
import 'package:bing_play/main.dart';
import 'package:bing_play/src/demo.dart';
import 'package:bing_play/src/paginas/en_vivo_page.dart';
import 'package:bing_play/src/paginas/esperando_page.dart';
import 'package:bing_play/src/paginas/ganaste_page.dart';
import 'package:bing_play/src/paginas/reservar_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _cargarFuente(String familia, String ruta) async {
  final cargador = FontLoader('packages/bing_ui/$familia')
    ..addFont(Future.value(ByteData.sublistView(File(ruta).readAsBytesSync())));
  await cargador.load();
}

/// Captura la pantalla a 320 × 700 dp, ×3 y con 44 dp de barra de estado.
Future<void> _capturar(
  WidgetTester tester,
  String id,
  Widget pantalla, {
  bool sinMovimiento = false,
}) async {
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
  if (sinMovimiento) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  await tester.pumpWidget(BingPlayApp(inicio: pantalla));
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(WidgetsApp),
    matchesGoldenFile('goldens/$id.png'),
  );
}

void main() {
  final skip = !Platform.isMacOS; // El render de texto cambia entre sistemas.
  final lucia = cartillasDemo[4];

  testWidgets('jug-07-salas', (tester) async {
    await _capturar(tester, 'jug-07-salas', pantallaDemo('jug-07-salas')!);
  }, skip: skip);

  testWidgets('jug-03-reservar', (tester) async {
    await _capturar(
      tester,
      'jug-03-reservar',
      ReservarPage(
        salaNombre: salaDemoNombre,
        organizador: salaDemoOrganizador,
        fila: 5,
        numeros: lucia,
        nombreInicial: 'Lucía',
      ),
    );
  }, skip: skip);

  testWidgets('jug-04-esperando', (tester) async {
    await _capturar(
      tester,
      'jug-04-esperando',
      EsperandoPage(
        nombre: 'Lucía',
        salaNombre: salaDemoNombre,
        organizador: salaDemoOrganizador,
        fila: 5,
        numeros: lucia,
        ocupadas: 17,
        total: 20,
      ),
    );
  }, skip: skip);

  testWidgets('jug-05-en-vivo', (tester) async {
    await _capturar(
      tester,
      'jug-05-en-vivo',
      EnVivoPage(
        salaNombre: salaDemoNombre,
        organizador: salaDemoOrganizador,
        cartillas: cartillasDemo,
        nombres: jugadoresDemo,
        miFila: 5,
        bolillas: bolillasDemo.take(17).toList(),
        hace: 'hace 3 s',
      ),
    );
  }, skip: skip);

  testWidgets('jug-06-ganaste (sin confeti)', (tester) async {
    await _capturar(
      tester,
      'jug-06-ganaste',
      GanastePage(
        nombre: 'Lucía',
        fila: 5,
        numeros: lucia,
        bolillaFinal: 12,
        cantidadBolillas: 32,
        organizador: salaDemoOrganizador,
      ),
      sinMovimiento: true,
    );
  }, skip: skip);
}
