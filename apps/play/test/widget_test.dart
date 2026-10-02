import 'package:bing_play/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra la pantalla de código con los textos del diseño', (
    tester,
  ) async {
    await tester.pumpWidget(const BingPlayApp());
    expect(find.text('Bing Bing'), findsOneWidget);
    expect(
      find.text('Escribe el código que te dio quien organiza'),
      findsOneWidget,
    );
    for (final c in ['K', '7', 'Q', '4']) {
      expect(find.text(c), findsOneWidget);
    }
    expect(find.text('Bingo de los sábados'), findsOneWidget);
    expect(
      find.text('Organiza Carmen · quedan 16 filas libres'),
      findsOneWidget,
    );
    expect(find.text('Escanear el QR'), findsOneWidget);
    expect(find.text('Ver filas libres'), findsOneWidget);
    expect(
      find.text('Sin cuenta. Tu nombre lo pones al elegir la fila.'),
      findsOneWidget,
    );
  });

  testWidgets('el recorrido demo llega de la pantalla de código a esperando', (
    tester,
  ) async {
    await tester.pumpWidget(const BingPlayApp());
    await tester.tap(find.text('Ver filas libres'));
    await tester.pumpAndSettle();
    expect(find.text('Elige tus filas'), findsOneWidget);
    await tester.tap(find.text('Seguir con la fila 5'));
    await tester.pumpAndSettle();
    expect(find.text('Reserva tu fila'), findsOneWidget);
    await tester.tap(find.text('Reservar fila 5'));
    await tester.pumpAndSettle();
    expect(find.text('Tu fila está reservada'), findsOneWidget);
    expect(find.text('Lucía · fila 5 · Bingo de los sábados'), findsOneWidget);
  });
}
