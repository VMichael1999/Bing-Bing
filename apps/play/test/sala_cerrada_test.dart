import 'dart:async';

import 'package:bing_core/bing_core.dart';
import 'package:bing_play/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cargar_fuentes.dart';

void main() {
  setUpAll(cargarFuentesBing);

  Future<RepositorioMemoria> abrir(
    WidgetTester tester, {
    Stream<Uri>? enlaces,
  }) async {
    tester.view
      ..devicePixelRatio = 2
      ..physicalSize = const Size(360 * 2, 800 * 2);
    addTearDown(tester.view.reset);
    final repo = RepositorioMemoria(cartillas: cartillasDemo);
    for (var i = 1; i <= 4; i++) {
      repo.ocupar(i, 'Jugador $i', 'u$i');
    }
    await tester.pumpWidget(BingPlayApp(repositorio: repo, enlaces: enlaces));
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('una sala cerrada deja de verse en el inicio', (tester) async {
    final repo = await abrir(tester);
    expect(find.text('Bingo de los sábados'), findsOneWidget);
    await repo.cancelarSala('K7Q4');
    await tester.pumpAndSettle();
    expect(find.text('Bingo de los sábados'), findsNothing);
    expect(find.textContaining('Ahora no hay salas abiertas'), findsOneWidget);
  });

  testWidgets('quien está eligiendo fila ve el aviso con el motivo', (
    tester,
  ) async {
    final repo = await abrir(tester);
    await tester.tap(find.text('Bingo de los sábados'));
    await tester.pumpAndSettle();
    expect(find.text('Elige tus filas'), findsOneWidget);

    await repo.cancelarSala('K7Q4', motivo: 'No se llenó');
    await tester.pumpAndSettle();
    expect(find.text('La sala se cerró'), findsOneWidget);
    expect(find.textContaining('Motivo: No se llenó.'), findsOneWidget);
    expect(find.textContaining('la partida no se juega'), findsOneWidget);

    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.text('La sala se cerró'), findsNothing);
    expect(find.text('Elige tus filas'), findsNothing);
    expect(find.text('Escanear el QR'), findsOneWidget);
  });

  testWidgets('sin motivo el aviso no inventa uno', (tester) async {
    final repo = await abrir(tester);
    await tester.tap(find.text('Bingo de los sábados'));
    await tester.pumpAndSettle();
    await repo.cancelarSala('K7Q4');
    await tester.pumpAndSettle();
    expect(find.text('La sala se cerró'), findsOneWidget);
    expect(find.textContaining('Motivo:'), findsNothing);
  });

  testWidgets('quien ya reservó y espera también lo ve, una sola vez', (
    tester,
  ) async {
    final repo = await abrir(tester);
    await tester.tap(find.text('Bingo de los sábados'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seguir con la fila 5'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, 'Lucía');
    await tester.tap(find.text('Reservar fila 5'));
    await tester.pumpAndSettle();
    expect(find.text('Tu fila está reservada'), findsOneWidget);

    await repo.cancelarSala('K7Q4', motivo: 'Nos vamos');
    await tester.pumpAndSettle();
    expect(find.text('La sala se cerró'), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.text('Tu fila está reservada'), findsNothing);
    expect(find.text('Escanear el QR'), findsOneWidget);
  });

  testWidgets('un enlace a una sala cerrada avisa y no entra', (tester) async {
    final enlaces = StreamController<Uri>();
    addTearDown(enlaces.close);
    final repo = await abrir(tester, enlaces: enlaces.stream);
    await repo.cancelarSala('K7Q4');
    await tester.pumpAndSettle();
    enlaces.add(Uri.parse('bingbing://sala/K7Q4'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Esa sala se cerró.'), findsOneWidget);
    expect(find.text('Elige tus filas'), findsNothing);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
