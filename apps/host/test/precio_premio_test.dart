import 'package:bing_core/bing_core.dart';
import 'package:bing_host/main.dart';
import 'package:bing_host/src/paginas/precio_premio_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cargar_fuentes.dart';

void main() {
  setUpAll(cargarFuentesBing);

  Future<void> abrir(
    WidgetTester tester, {
    ValueChanged<PrecioPremio>? alAbrir,
    int precio = 5,
    int? premio,
  }) async {
    tester.view
      ..devicePixelRatio = 2
      ..physicalSize = const Size(360 * 2, 800 * 2);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BingHostApp(
        inicio: PrecioPremioPage(
          precioInicial: precio,
          premioInicial: premio,
          alAbrirSala: alAbrir,
        ),
      ),
    );
  }

  testWidgets('muestra el cálculo del prototipo con 5 créditos por fila', (
    tester,
  ) async {
    await abrir(tester);
    expect(find.text('100'), findsOneWidget); // recaudado
    expect(find.text('−10'), findsOneWidget);
    expect(find.text('90'), findsWidgets); // disponible y tope del premio
    expect(find.text('80'), findsOneWidget); // premio propuesto
    expect(find.text('10 CRÉDITOS'), findsOneWidget);
    expect(find.text('Comisión de Bing Bing · 10 %'), findsOneWidget);
  });

  testWidgets('subir el precio recalcula todo y sigue la propuesta', (
    tester,
  ) async {
    await abrir(tester);
    await tester.tap(find.bySemanticsLabel('Subir créditos por fila'));
    await tester.pump();
    // 6 por fila: 120 − 12 = 108 disponibles; propuesta 95 (múltiplo de 5).
    expect(find.text('120'), findsOneWidget);
    expect(find.text('−12'), findsOneWidget);
    expect(find.text('108'), findsWidgets);
    expect(find.text('95'), findsOneWidget);
  });

  testWidgets('el premio no pasa de lo disponible', (tester) async {
    await abrir(tester);
    final subir = find.bySemanticsLabel('Subir premio');
    for (var i = 0; i < 20; i++) {
      await tester.tap(subir);
      await tester.pump();
    }
    expect(find.text('10 CRÉDITOS'), findsNothing);
    expect(find.text('0 CRÉDITOS'), findsOneWidget);
    expect(
      find.text('Puedes subirlo o bajarlo; no puede pasar de 90.'),
      findsOneWidget,
    );
  });

  testWidgets('bajar el precio acota un premio que quedó de más', (
    tester,
  ) async {
    await abrir(tester, premio: 90);
    await tester.tap(find.bySemanticsLabel('Bajar créditos por fila'));
    await tester.pump();
    // 4 por fila: 80 − 8 = 72 disponibles, el premio de 90 baja a 72.
    expect(find.text('72'), findsWidgets);
    expect(find.text('90'), findsNothing);
    expect(find.text('0 CRÉDITOS'), findsOneWidget);
  });

  testWidgets('sin precio no hay premio', (tester) async {
    await abrir(tester, precio: 0);
    expect(find.text('0'), findsWidgets);
    expect(find.text('Sin precio por fila no hay premio.'), findsOneWidget);
  });

  testWidgets('"Abrir sala" entrega el precio y el premio elegidos', (
    tester,
  ) async {
    PrecioPremio? recibido;
    await abrir(tester, alAbrir: (v) => recibido = v);
    await tester.tap(find.bySemanticsLabel('Bajar premio'));
    await tester.pump();
    await tester.tap(find.text('Abrir sala'));
    expect(recibido, (precioFila: 5, premio: 79));
  });

  testWidgets('mantener pulsado repite el cambio', (tester) async {
    await abrir(tester);
    final gesto = await tester.startGesture(
      tester.getCenter(find.bySemanticsLabel('Bajar premio')),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 500));
    await gesto.up();
    await tester.pump();
    expect(find.text('80'), findsNothing);
  });

  testWidgets('desde Nueva partida se crea la sala con lo elegido', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 2
      ..physicalSize = const Size(360 * 2, 800 * 2);
    addTearDown(tester.view.reset);
    final repo = RepositorioMemoria(
      cartillas: cartillasDemo,
      ordenBolillas: bolillasDemo,
    );
    await tester.pumpWidget(
      BingHostApp(
        repositorio: repo,
        entrar: () async => 'Carmen',
        organizadorActual: 'Carmen',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva partida'));
    await tester.pumpAndSettle();
    expect(find.text('5 por fila · premio 80'), findsOneWidget);
    await tester.tap(find.text('5 por fila · premio 80'));
    await tester.pumpAndSettle();
    expect(find.text('Precio y premio'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Subir créditos por fila'));
    await tester.pump();
    await tester.tap(find.text('Abrir sala'));
    await tester.pumpAndSettle();
    final sala = await repo.buscar('K7Q4');
    expect(sala?.precioFila, 6);
    expect(sala?.premio, 95);
  });

  testWidgets('"Abrir sala" desde Nueva partida usa el precio por defecto', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 2
      ..physicalSize = const Size(360 * 2, 800 * 2);
    addTearDown(tester.view.reset);
    final repo = RepositorioMemoria(
      cartillas: cartillasDemo,
      ordenBolillas: bolillasDemo,
    );
    await tester.pumpWidget(
      BingHostApp(
        repositorio: repo,
        entrar: () async => 'Carmen',
        organizadorActual: 'Carmen',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva partida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir sala'));
    await tester.pumpAndSettle();
    final sala = await repo.buscar('K7Q4');
    expect(sala?.precioFila, 5);
    expect(sala?.premio, 80);
  });

  testWidgets('"Solo 1" fila por jugador llega a la sala', (tester) async {
    tester.view
      ..devicePixelRatio = 2
      ..physicalSize = const Size(360 * 2, 800 * 2);
    addTearDown(tester.view.reset);
    final repo = RepositorioMemoria(
      cartillas: cartillasDemo,
      ordenBolillas: bolillasDemo,
    );
    await tester.pumpWidget(
      BingHostApp(
        repositorio: repo,
        entrar: () async => 'Carmen',
        organizadorActual: 'Carmen',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva partida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Solo 1'));
    await tester.pump();
    await tester.tap(find.text('Abrir sala'));
    await tester.pumpAndSettle();
    expect((await repo.buscar('K7Q4'))?.filasPorJugador, 1);
  });

  testWidgets('por defecto cada persona elige las filas que quiera', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 2
      ..physicalSize = const Size(360 * 2, 800 * 2);
    addTearDown(tester.view.reset);
    final repo = RepositorioMemoria(
      cartillas: cartillasDemo,
      ordenBolillas: bolillasDemo,
    );
    await tester.pumpWidget(
      BingHostApp(
        repositorio: repo,
        entrar: () async => 'Carmen',
        organizadorActual: 'Carmen',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva partida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir sala'));
    await tester.pumpAndSettle();
    expect((await repo.buscar('K7Q4'))?.filasPorJugador, 20);
  });
}
