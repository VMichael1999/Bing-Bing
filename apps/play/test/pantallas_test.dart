import 'package:bing_core/bing_core.dart';
import 'package:bing_play/main.dart';
import 'package:bing_play/src/paginas/ganaste_page.dart';
import 'package:bing_play/src/paginas/reservar_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reservar entrega el nombre escrito y sin espacios sobrantes', (
    tester,
  ) async {
    String? recibido;
    await tester.pumpWidget(
      BingPlayApp(
        inicio: ReservarPage(
          salaNombre: salaDemoNombre,
          organizador: salaDemoOrganizador,
          fila: 5,
          numeros: cartillasDemo[4],
          nombreInicial: '  Lucía ',
          alReservar: (n) => recibido = n,
        ),
      ),
    );
    expect(find.text('Reservar fila 5'), findsOneWidget);
    await tester.tap(find.text('Reservar fila 5'));
    expect(recibido, 'Lucía');
  });

  testWidgets('ganaste muestra los textos del diseño', (tester) async {
    await tester.pumpWidget(
      BingPlayApp(
        inicio: GanastePage(
          nombre: 'Lucía',
          fila: 5,
          numeros: cartillasDemo[4],
          bolillaFinal: 12,
          cantidadBolillas: 32,
          organizador: salaDemoOrganizador,
        ),
      ),
    );
    expect(find.text('¡Ganaste!'), findsOneWidget);
    expect(find.text('Lucía, completaste la fila 5'), findsOneWidget);
    expect(
      find.text('Con la B-12, la bolilla 32. Carmen ya lo ve en su pantalla.'),
      findsOneWidget,
    );
    expect(
      find.text('No hace falta gritar: la app avisa sola.'),
      findsOneWidget,
    );
    // El confeti dura 160 cuadros y termina solo.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
