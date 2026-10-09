import 'package:bing_play/main.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cargar_fuentes.dart';

void main() {
  setUpAll(cargarFuentesBing);

  testWidgets('recorrido completo de Play con datos falsos hasta ¡Ganaste!', (
    tester,
  ) async {
    await tester.pumpWidget(const BingPlayApp());

    // jug-01 → jug-02 → jug-03
    expect(
      find.text('Organiza Carmen · quedan 16 filas libres'),
      findsOneWidget,
    );
    await tester.tap(find.text('Ver filas libres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seguir con la fila 5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reservar fila 5'));
    await tester.pumpAndSettle();

    // jug-04: la reserva queda confirmada y la sala se va llenando sola.
    expect(find.text('Tu fila está reservada'), findsOneWidget);
    expect(find.text('5 de 20'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('6 de 20'), findsOneWidget);

    // Cuando se llena, "Carmen" inicia la partida y se ve la primera bolilla.
    for (var i = 0; i < 400 && find.text('En vivo').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('En vivo'), findsOneWidget);
    expect(find.text('Salió la G-36'), findsNothing);
    expect(find.textContaining('Salió la'), findsOneWidget);
    expect(find.text('Tu fila · la 5'), findsWidgets);

    // Las bolillas salen solas hasta que la fila 5 gana con la 32 (B-12).
    for (
      var i = 0;
      i < 1500 && find.text('¡Ganaste!').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('¡Ganaste!'), findsOneWidget);
    expect(find.text('Lucía, completaste la fila 5'), findsOneWidget);
    expect(
      find.text('Con la B-12, la bolilla 32. Carmen ya lo ve en su pantalla.'),
      findsOneWidget,
    );

    // "Ver la cartilla" vuelve a la pantalla en vivo.
    await tester.pump(const Duration(seconds: 4));
    await tester.tap(find.text('Ver la cartilla'));
    await tester.pumpAndSettle();
    expect(find.text('En vivo'), findsOneWidget);
  });

  testWidgets('quien reserva otra fila no recibe ¡Ganaste! con la bolilla 32', (
    tester,
  ) async {
    await tester.pumpWidget(const BingPlayApp());
    await tester.tap(find.text('Ver filas libres'));
    await tester.pumpAndSettle();
    // Elegir la fila 6 en lugar de la 5: se quita la 5 y se pone la 6.
    await tester.tap(find.text('Elegida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Libre').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seguir con la fila 6'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reservar fila 6'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2600; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('¡Ganaste!'), findsNothing);
    expect(find.text('Tu fila · la 6'), findsOneWidget);
  });
}
