import 'package:bing_core/bing_core.dart';
import 'package:bing_play/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cargar_fuentes.dart';

void main() {
  setUpAll(cargarFuentesBing);

  RepositorioMemoria sala({int ocupadas = 4, bool abierta = true}) {
    final repo = RepositorioMemoria(cartillas: cartillasDemo);
    for (var i = 1; i <= ocupadas; i++) {
      repo.ocupar(i, 'Jugador $i', 'u$i');
    }
    if (!abierta) repo.empezarPartida();
    return repo;
  }

  /// Abre la app, entra al escáner y devuelve la función que simula una lectura.
  Future<ValueChanged<String>> abrirEscaner(
    WidgetTester tester,
    RepositorioMemoria repo,
  ) async {
    tester.view
      ..devicePixelRatio = 2
      ..physicalSize = const Size(360 * 2, 800 * 2);
    addTearDown(tester.view.reset);
    // Sin movimiento las bolillas no animan y la pantalla puede asentarse.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    late ValueChanged<String> leer;
    await tester.pumpWidget(
      BingPlayApp(
        repositorio: repo,
        camaraEscaner: (context, alLeerTexto) {
          leer = alLeerTexto;
          return const SizedBox.expand();
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escanear el QR'));
    await tester.pumpAndSettle();
    expect(find.text('Apunta al QR de la sala'), findsOneWidget);
    return leer;
  }

  testWidgets('un QR con el enlace de la sala abre elegir fila', (
    tester,
  ) async {
    final leer = await abrirEscaner(tester, sala());
    leer('https://bingbing-f1491.web.app/sala/K7Q4');
    await tester.pumpAndSettle();
    expect(find.text('Elige tu fila'), findsOneWidget);
    // El escáner no queda en la pila: volver lleva al inicio.
    await tester.tap(find.bySemanticsLabel('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Escanear el QR'), findsOneWidget);
    expect(find.text('Apunta al QR de la sala'), findsNothing);
  });

  testWidgets('también lee el código suelto y el enlace de la app', (
    tester,
  ) async {
    final leer = await abrirEscaner(tester, sala());
    leer('bingbing://sala/k7q4');
    await tester.pumpAndSettle();
    expect(find.text('Elige tu fila'), findsOneWidget);
  });

  testWidgets('un QR que no es de una sala avisa y sigue escaneando', (
    tester,
  ) async {
    final leer = await abrirEscaner(tester, sala());
    leer('https://ejemplo.com/otra-cosa');
    await tester.pump();
    expect(find.text('Ese QR no es de una sala de Bing Bing'), findsOneWidget);
    expect(find.text('Elige tu fila'), findsNothing);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    // Un QR bueno después sí entra.
    leer('K7Q4');
    await tester.pumpAndSettle();
    expect(find.text('Elige tu fila'), findsOneWidget);
  });

  testWidgets('una sala que no existe se explica', (tester) async {
    final leer = await abrirEscaner(tester, sala());
    leer('bingbing://sala/ZZZ2');
    await tester.pump();
    await tester.pump();
    expect(
      find.text('No encontramos esa sala. Revisa el código.'),
      findsOneWidget,
    );
    expect(find.text('Elige tu fila'), findsNothing);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('una sala llena no deja entrar', (tester) async {
    final leer = await abrirEscaner(tester, sala(ocupadas: 20));
    leer('K7Q4');
    await tester.pump();
    await tester.pump();
    expect(find.text('Esa sala ya está llena.'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('una sala que ya empezó no deja entrar', (tester) async {
    final leer = await abrirEscaner(tester, sala(abierta: false));
    leer('K7Q4');
    await tester.pump();
    await tester.pump();
    expect(find.text('Esa sala ya no recibe jugadores.'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('"Escribir el código" vuelve al inicio con el teclado listo', (
    tester,
  ) async {
    await abrirEscaner(tester, sala());
    await tester.tap(find.text('Escribir el código'));
    await tester.pumpAndSettle();
    expect(find.text('Apunta al QR de la sala'), findsNothing);
    expect(find.text('Escanear el QR'), findsOneWidget);
    expect(FocusManager.instance.primaryFocus, isNotNull);
  });
}
