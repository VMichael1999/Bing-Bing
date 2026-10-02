import 'package:bing_host/main.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cargar_fuentes.dart';

/// Avanza el reloj simulado en pasos cortos para que corran los temporizadores
/// y las animaciones.
Future<void> _avanzar(WidgetTester tester, Duration total) async {
  const paso = Duration(milliseconds: 100);
  for (var t = Duration.zero; t < total; t += paso) {
    await tester.pump(paso);
  }
}

void main() {
  setUpAll(cargarFuentesBing);

  testWidgets(
    'recorrido completo de Host con datos falsos hasta que gana Lucía',
    (tester) async {
      await tester.pumpWidget(const BingHostApp());

      // org-01 → org-02 → org-03
      await tester.tap(find.text('Continuar con Google'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nueva partida'));
      await tester.pumpAndSettle();

      // org-04: la sala abre con 16 de 20 y se llena sola.
      await tester.tap(find.text('Abrir sala'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('16 de 20'), findsOneWidget);
      await _avanzar(tester, const Duration(milliseconds: 2300));
      expect(find.text('17 de 20'), findsOneWidget);
      expect(find.text('recién entró'), findsOneWidget);

      // org-05: al entrar la fila 20 sube "¡Cartilla llena!".
      await _avanzar(tester, const Duration(seconds: 8));
      expect(find.text('¡Cartilla llena!'), findsOneWidget);
      expect(find.text('Esperar un momento'), findsOneWidget);

      // Empezar la partida → pestaña Bolilla, sin bolillas todavía.
      await tester.tap(find.text('Empezar partida'));
      await tester.pumpAndSettle();
      expect(find.text('0/75'), findsOneWidget);

      // Modo automático: salen las 32 bolillas del diseño y gana Lucía.
      await tester.tap(find.text('Automático: no'));
      await tester.pump();
      for (
        var i = 0;
        i < 1800 && find.text('La app verificó la fila').evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('La app verificó la fila'), findsOneWidget);
      expect(find.text('Lucía · fila 5'), findsOneWidget);
      expect(
        find.text('Con la B-12, la bolilla 32 de la partida.'),
        findsOneWidget,
      );

      // "Terminar partida" vuelve a "Tus partidas".
      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.text('Terminar partida'));
      await tester.pumpAndSettle();
      expect(find.text('Tus partidas'), findsOneWidget);
    },
  );

  testWidgets('"Esperar un momento" deja la sala abierta y se puede empezar', (
    tester,
  ) async {
    await tester.pumpWidget(const BingHostApp());
    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva partida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir sala'));
    await _avanzar(tester, const Duration(seconds: 11));
    expect(find.text('¡Cartilla llena!'), findsOneWidget);

    await tester.tap(find.text('Esperar un momento'));
    await tester.pumpAndSettle();
    expect(find.text('20 de 20'), findsOneWidget);
    expect(find.text('Empezar partida'), findsOneWidget);
  });
}
