import 'package:bing_core/bing_core.dart';
import 'package:bing_host/main.dart';
import 'package:bing_host/src/demo.dart';
import 'package:bing_host/src/paginas/juego_page.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cargar_fuentes.dart';

final _bolillaGrande = find.byWidgetPredicate(
  (w) => w is BingBolilla && w.tamano == BingBolillaTamano.xl,
);

JuegoPage _juego(int iniciales) => JuegoPage(
  salaNombre: salaDemoNombre,
  codigo: salaDemoCodigo,
  cartillas: cartillasDemo,
  nombres: jugadoresDemo,
  bolillasIniciales: bolillasDemo.take(iniciales).toList(),
  sorteo: sorteoDemo,
);

void main() {
  setUpAll(cargarFuentesBing);

  testWidgets(
    'tocar la bolilla saca la siguiente tras la animación de 660 ms',
    (tester) async {
      await tester.pumpWidget(BingHostApp(inicio: _juego(17)));
      expect(find.text('17/75'), findsOneWidget);
      expect(find.textContaining('se marcó en 2 filas'), findsOneWidget);

      await tester.tap(_bolillaGrande);
      await tester.pump(const Duration(milliseconds: 300));
      // A mitad del sorteo todavía no se contó.
      expect(find.text('17/75'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.text('18/75'), findsOneWidget);
      // La 18.ª del orden de la partida es la 53 (G-53).
      expect(find.textContaining('G-53'), findsWidgets);
    },
  );

  testWidgets('no se puede sacar otra bolilla mientras se sortea', (
    tester,
  ) async {
    await tester.pumpWidget(BingHostApp(inicio: _juego(17)));
    await tester.tap(_bolillaGrande);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(_bolillaGrande);
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('18/75'), findsOneWidget);
  });

  testWidgets('deshacer devuelve la última bolilla', (tester) async {
    await tester.pumpWidget(BingHostApp(inicio: _juego(17)));
    await tester.tap(find.text('Deshacer'));
    await tester.pump();
    expect(find.text('16/75'), findsOneWidget);
  });

  testWidgets('con la bolilla 32 gana Lucía y se muestra el ganador', (
    tester,
  ) async {
    await tester.pumpWidget(BingHostApp(inicio: _juego(31)));
    await tester.tap(_bolillaGrande);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('¡Bingo!'), findsOneWidget);
    expect(find.text('Lucía · fila 5'), findsOneWidget);
    expect(
      find.text('Con la B-12, la bolilla 32 de la partida.'),
      findsOneWidget,
    );
    expect(find.text('Seguir por el segundo puesto'), findsOneWidget);
  });

  testWidgets('las pestañas cambian entre bolilla, cartilla y tablero', (
    tester,
  ) async {
    await tester.pumpWidget(BingHostApp(inicio: _juego(17)));
    await tester.tap(find.text('Cartilla'));
    await tester.pump();
    expect(find.text('17 bolillas · 1 fila a una'), findsOneWidget);
    await tester.tap(find.text('Tablero'));
    await tester.pump();
    expect(find.text('17 de 75 · quedan 58 en la tómbola'), findsOneWidget);
  });
}
