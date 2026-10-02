import 'dart:io';

import 'package:bing_core/bing_core.dart';
import 'package:bing_host/main.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:bing_host/src/paginas/entrar_page.dart';
import 'package:bing_host/src/paginas/mis_partidas_page.dart';
import 'package:bing_host/src/paginas/cartilla_llena_sheet.dart';
import 'package:bing_host/src/paginas/nueva_partida_page.dart';
import 'package:bing_host/src/paginas/sala_abierta_page.dart';
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

  testWidgets('org-04-sala-abierta', (tester) async {
    await _capturar(
      tester,
      'org-04-sala-abierta',
      SalaAbiertaPage(
        salaNombre: salaDemoNombre,
        codigo: salaDemoCodigo,
        ocupadas: 17,
        total: 20,
        jugadores: [
          for (var i = 0; i < 5; i++)
            BingJugador.normal(
              '${i + 1}',
              jugadoresDemo[i],
              horasReservaDemo[i],
            ),
          const BingJugador.salto('filas 6 a 16'),
          const BingJugador.nuevo('17', 'Claudia', 'recién entró'),
          const BingJugador.libre('18'),
          const BingJugador.libre('19'),
          const BingJugador.libre('20'),
        ],
      ),
    );
  }, skip: skip);

  testWidgets('org-05-cartilla-llena', (tester) async {
    await _capturar(
      tester,
      'org-05-cartilla-llena',
      CartillaLlenaSheet(
        salaNombre: salaDemoNombre,
        total: 20,
        ultimos: [
          for (var i = 14; i < 20; i++)
            BingJugador.normal('${i + 1}', jugadoresDemo[i], 'listo'),
        ],
      ),
    );
  }, skip: skip);
}
