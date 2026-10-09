import 'package:bing_core/bing_core.dart';
import 'package:bing_play/main.dart';
import 'package:bing_play/src/paginas/ganaste_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cargar_fuentes.dart';

void main() {
  setUpAll(cargarFuentesBing);

  Future<void> abrir(
    WidgetTester tester, {
    int premio = 0,
    bool pagado = false,
  }) async {
    tester.view
      ..devicePixelRatio = 2
      ..physicalSize = const Size(360 * 2, 800 * 2);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BingPlayApp(
        inicio: GanastePage(
          nombre: 'Lucía',
          fila: 5,
          numeros: cartillasDemo[4],
          bolillaFinal: 12,
          cantidadBolillas: 32,
          organizador: 'Carmen',
          premio: premio,
          pagado: pagado,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('con premio avisa cuántos créditos ganó y cuándo llegan', (
    tester,
  ) async {
    await abrir(tester, premio: 80);
    expect(find.textContaining('Ganaste 80 créditos.'), findsOneWidget);
    expect(
      find.textContaining('cuando Carmen termine la partida'),
      findsOneWidget,
    );
  });

  testWidgets('al terminar la partida dice que ya están en la billetera', (
    tester,
  ) async {
    await abrir(tester, premio: 80, pagado: true);
    expect(find.textContaining('Ya están en tu billetera.'), findsOneWidget);
  });

  testWidgets('sin premio no habla de créditos', (tester) async {
    await abrir(tester);
    expect(find.textContaining('créditos'), findsNothing);
  });
}
