import 'package:bing_host/main.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cargar_fuentes.dart';

void main() {
  setUpAll(cargarFuentesBing);

  testWidgets('el recorrido demo llega de entrar a nueva partida', (
    tester,
  ) async {
    await tester.pumpWidget(const BingHostApp());
    expect(find.text('Bing Bing'), findsOneWidget);
    expect(
      find.text('Necesitas una cuenta para guardar tus partidas.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();
    expect(find.text('Tus partidas'), findsOneWidget);
    expect(find.text('Carmen · organizadora'), findsOneWidget);
    await tester.tap(find.text('Nueva partida'));
    await tester.pumpAndSettle();
    expect(find.text('PRECIO Y PREMIO'), findsOneWidget);
    expect(find.text('5 por fila · premio 80'), findsOneWidget);
  });

  testWidgets('las filas por jugador se pueden limitar a una', (tester) async {
    await tester.pumpWidget(const BingHostApp());
    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva partida'));
    await tester.pumpAndSettle();
    expect(find.textContaining('elige las filas que quiera'), findsOneWidget);
    await tester.tap(find.text('Solo 1'));
    await tester.pump();
    expect(
      find.text('Cada persona puede tener una sola fila.'),
      findsOneWidget,
    );
  });
}
