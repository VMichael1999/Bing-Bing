import 'package:bing_host/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
    expect(find.text('PARTIDA CON PREMIO'), findsOneWidget);
    expect(find.text('Pronto'), findsOneWidget);
  });

  testWidgets('la opción "Hasta 3" está bloqueada y no se puede elegir', (
    tester,
  ) async {
    await tester.pumpWidget(const BingHostApp());
    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva partida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hasta 3'));
    await tester.pump();
    expect(find.text('1 fila'), findsOneWidget);
  });
}
