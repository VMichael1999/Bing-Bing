import 'package:bing_play/main.dart';
import 'package:bing_play/src/paginas/escaner_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cargar_fuentes.dart';

void main() {
  setUpAll(cargarFuentesBing);

  double alturaLinea(WidgetTester tester) =>
      tester.getTopLeft(find.byKey(const ValueKey('linea-de-lectura'))).dy;

  testWidgets('la línea de lectura sube y baja dentro del marco', (
    tester,
  ) async {
    await tester.pumpWidget(const BingPlayApp(inicio: EscanerPage()));
    await tester.pump();
    final inicio = alturaLinea(tester);
    await tester.pump(const Duration(milliseconds: 1100));
    final mitad = alturaLinea(tester);
    await tester.pump(const Duration(milliseconds: 1100));
    final fin = alturaLinea(tester);
    // Baja hasta el final del recorrido y luego vuelve a subir.
    expect(mitad, greaterThan(inicio));
    expect(fin, greaterThan(mitad));
    await tester.pump(const Duration(milliseconds: 2200));
    expect(alturaLinea(tester), lessThan(fin));
  });

  testWidgets('sin animaciones la línea queda quieta', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const BingPlayApp(inicio: EscanerPage()));
    await tester.pump();
    final inicio = alturaLinea(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(alturaLinea(tester), inicio);
  });
}
