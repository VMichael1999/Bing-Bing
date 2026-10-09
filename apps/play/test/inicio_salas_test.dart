import 'package:bing_core/bing_core.dart';
import 'package:bing_play/main.dart';
import 'package:bing_play/src/paginas/codigo_page.dart';
import 'package:bing_play/src/paginas/salas_abiertas.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cargar_fuentes.dart';

List<SalaEnVivo> _salas(int n) => [
  for (var i = 0; i < n; i++)
    SalaEnVivo(
      codigo: 'S$i',
      nombre: 'Sala número $i',
      organizador: 'Carmen',
      estado: EstadoSala.abierta,
      columnas: 5,
      filasTotal: 20,
      bolillas: const [],
      ganadoras: const [],
      publica: true,
      ocupadas: 19 - i,
    ),
];

Widget _inicio(List<SalaEnVivo> salas) => BingPlayApp(
  inicio: CodigoPage(
    codigo: '',
    salaNombre: '',
    organizador: '',
    filasLibres: 0,
    resultado: const SizedBox(height: 40),
    bajoElQr:
        (desplazable) => SalasAbiertas(salas: salas, desplazable: desplazable),
  ),
);

void main() {
  setUpAll(cargarFuentesBing);

  void pantalla(WidgetTester tester, {double alto = 800}) {
    tester.view
      ..devicePixelRatio = 2
      ..physicalSize = Size(360 * 2, alto * 2);
    addTearDown(tester.view.reset);
  }

  testWidgets('solo se mueven las salas, no el resto de la pantalla', (
    tester,
  ) async {
    pantalla(tester);
    await tester.pumpWidget(_inicio(_salas(8)));
    await tester.pumpAndSettle();
    final qr = tester.getTopLeft(find.text('Escanear el QR'));
    expect(find.text('Sala número 7').hitTestable(), findsNothing);

    await tester.drag(find.text('Sala número 0'), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('Escanear el QR')), qr);
    expect(find.text('Sala número 7').hitTestable(), findsOneWidget);
    expect(find.text('Ver filas libres').hitTestable(), findsOneWidget);
  });

  testWidgets('en una pantalla muy baja todo se mueve junto y no se corta', (
    tester,
  ) async {
    pantalla(tester, alto: 480);
    await tester.pumpWidget(_inicio(_salas(3)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(find.text('Escanear el QR'), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Sala número 2').hitTestable(), findsOneWidget);
  });
}
