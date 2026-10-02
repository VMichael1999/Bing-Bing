import 'dart:async';

import 'package:bing_core/bing_core.dart';
import 'package:bing_play/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cargar_fuentes.dart';

void main() {
  setUpAll(cargarFuentesBing);

  late StreamController<Uri> enlaces;

  setUp(() => enlaces = StreamController<Uri>());
  tearDown(() => enlaces.close());

  Future<void> abrir(WidgetTester tester, {int ocupadas = 4}) async {
    tester.view
      ..devicePixelRatio = 2
      ..physicalSize = const Size(360 * 2, 800 * 2);
    addTearDown(tester.view.reset);
    final repo = RepositorioMemoria(cartillas: cartillasDemo);
    for (var i = 1; i <= ocupadas; i++) {
      repo.ocupar(i, 'Jugador $i', 'u$i');
    }
    await tester.pumpWidget(
      BingPlayApp(repositorio: repo, enlaces: enlaces.stream),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('el enlace web de una sala abre elegir fila', (tester) async {
    await abrir(tester);
    enlaces.add(Uri.parse('https://bingbing-f1491.web.app/sala/K7Q4'));
    await tester.pumpAndSettle();
    expect(find.text('Elige tus filas'), findsOneWidget);
  });

  testWidgets('el enlace de la app abre la sala', (tester) async {
    await abrir(tester);
    enlaces.add(Uri.parse('bingbing://sala/K7Q4'));
    await tester.pumpAndSettle();
    expect(find.text('Elige tus filas'), findsOneWidget);
  });

  testWidgets('un enlace que no es de una sala se ignora', (tester) async {
    await abrir(tester);
    enlaces.add(Uri.parse('https://ejemplo.com/sala/K7Q4'));
    await tester.pumpAndSettle();
    expect(find.text('Elige tus filas'), findsNothing);
    expect(find.text('Escanear el QR'), findsOneWidget);
  });

  testWidgets('una sala que no existe avisa y deja en el inicio', (
    tester,
  ) async {
    await abrir(tester);
    enlaces.add(Uri.parse('bingbing://sala/ZZZ2'));
    await tester.pump();
    await tester.pump();
    expect(
      find.text('No encontramos esa sala. Revisa el código.'),
      findsOneWidget,
    );
    expect(find.text('Elige tus filas'), findsNothing);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('una sala llena avisa y no entra', (tester) async {
    await abrir(tester, ocupadas: 20);
    enlaces.add(Uri.parse('bingbing://sala/K7Q4'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Esa sala ya está llena.'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('el mismo enlace dos veces seguidas abre una sola pantalla', (
    tester,
  ) async {
    await abrir(tester);
    enlaces
      ..add(Uri.parse('bingbing://sala/K7Q4'))
      ..add(Uri.parse('bingbing://sala/K7Q4'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Elige tus filas'), findsNothing);
    expect(find.text('Escanear el QR'), findsOneWidget);
  });
}
