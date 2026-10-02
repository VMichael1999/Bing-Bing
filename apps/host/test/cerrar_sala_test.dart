import 'package:bing_core/bing_core.dart';
import 'package:bing_host/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cargar_fuentes.dart';

void main() {
  setUpAll(cargarFuentesBing);

  Future<RepositorioMemoria> abrirSala(
    WidgetTester tester, {
    int ocupadas = 5,
  }) async {
    tester.view
      ..devicePixelRatio = 2
      ..physicalSize = const Size(360 * 2, 800 * 2);
    addTearDown(tester.view.reset);
    final repo = RepositorioMemoria(
      cartillas: cartillasDemo,
      ordenBolillas: bolillasDemo,
    );
    for (var i = 1; i <= ocupadas; i++) {
      repo.ocupar(i, 'Jugador $i', 'u$i');
    }
    await tester.pumpWidget(
      BingHostApp(
        repositorio: repo,
        entrar: () async => 'Carmen',
        organizadorActual: 'Carmen',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bingo de los sábados'));
    await tester.pumpAndSettle();
    expect(find.text('Cerrar sala'), findsOneWidget);
    return repo;
  }

  testWidgets('cerrar la sala pide confirmar y avisa a cuántos', (
    tester,
  ) async {
    await abrirSala(tester);
    await tester.tap(find.text('Cerrar sala'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cerrar la sala?'), findsOneWidget);
    expect(
      find.textContaining('Las 5 personas que ya eligieron fila'),
      findsOneWidget,
    );
  });

  testWidgets('"Seguir esperando" deja la sala como estaba', (tester) async {
    final repo = await abrirSala(tester);
    await tester.tap(find.text('Cerrar sala'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seguir esperando'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cerrar la sala?'), findsNothing);
    expect((await repo.buscar('K7Q4'))?.estado, EstadoSala.abierta);
  });

  testWidgets('confirmada, la sala se cierra con el motivo y se vuelve', (
    tester,
  ) async {
    final repo = await abrirSala(tester);
    await tester.tap(find.text('Cerrar sala'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).last, 'No llegó gente');
    await tester.tap(find.text('Sí, cerrar la sala'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final sala = await repo.buscar('K7Q4');
    expect(sala?.estado, EstadoSala.cancelada);
    expect(sala?.motivoCierre, 'No llegó gente');
    expect(find.text('Sala cerrada'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Tus partidas'), findsOneWidget);
    expect(find.textContaining('cerrada'), findsOneWidget);
  });

  testWidgets('sin jugadores no habla de avisar a nadie', (tester) async {
    await abrirSala(tester, ocupadas: 0);
    await tester.tap(find.text('Cerrar sala'));
    await tester.pumpAndSettle();
    expect(
      find.text('Nadie más podrá entrar con el código ni con el QR.'),
      findsOneWidget,
    );
  });

  testWidgets('una sala cerrada no se vuelve a abrir desde la lista', (
    tester,
  ) async {
    final repo = await abrirSala(tester);
    await repo.cancelarSala('K7Q4');
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Volver'));
    await tester.pumpAndSettle();
    expect(find.textContaining('cerrada'), findsOneWidget);
    await tester.tap(find.textContaining('cerrada'));
    await tester.pumpAndSettle();
    expect(find.text('Tus partidas'), findsOneWidget);
  });
}
