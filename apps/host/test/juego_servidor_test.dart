import 'dart:async';

import 'package:bing_core/bing_core.dart';
import 'package:bing_host/main.dart';
import 'package:bing_host/src/paginas/juego_page.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cargar_fuentes.dart';

final _bolillaGrande = find.byWidgetPredicate(
  (w) => w is BingBolilla && w.tamano == BingBolillaTamano.xl,
);

JuegoPage _juego({
  required Sorteo sorteo,
  Future<void> Function()? alDeshacer,
}) => JuegoPage(
  salaNombre: salaDemoNombre,
  codigo: salaDemoCodigo,
  cartillas: cartillasDemo,
  nombres: jugadoresDemo,
  bolillasIniciales: bolillasDemo.take(17).toList(),
  sorteo: sorteo,
  alDeshacer: alDeshacer,
);

void main() {
  setUpAll(cargarFuentesBing);

  testWidgets('la bolilla es la que responde el servidor, aunque tarde', (
    tester,
  ) async {
    final respuesta = Completer<int?>();
    await tester.pumpWidget(
      BingHostApp(inicio: _juego(sorteo: (_) => respuesta.future)),
    );
    await tester.tap(_bolillaGrande);
    // La animación termina, pero sin respuesta no se cuenta nada.
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('17/75'), findsOneWidget);

    respuesta.complete(bolillasDemo[17]);
    await tester.pump();
    await tester.pump();
    expect(find.text('18/75'), findsOneWidget);
    expect(find.textContaining('G-53'), findsWidgets);
  });

  testWidgets('si el servidor falla se avisa y se puede reintentar', (
    tester,
  ) async {
    var intentos = 0;
    await tester.pumpWidget(
      BingHostApp(
        inicio: _juego(
          sorteo: (_) async {
            if (intentos++ == 0) throw const ErrorSalaBing('red', 'sin red');
            return bolillasDemo[17];
          },
        ),
      ),
    );
    await tester.tap(_bolillaGrande);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    expect(find.text('17/75'), findsOneWidget);
    expect(
      find.text('No se pudo sacar la bolilla. Revisa tu conexión.'),
      findsOneWidget,
    );

    await tester.tap(_bolillaGrande);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    expect(find.text('18/75'), findsOneWidget);
  });

  testWidgets('deshacer espera al servidor y, si falla, no quita la bolilla', (
    tester,
  ) async {
    var falla = true;
    await tester.pumpWidget(
      BingHostApp(
        inicio: _juego(
          sorteo: (_) => null,
          alDeshacer: () async {
            if (falla) throw const ErrorSalaBing('red', 'sin red');
          },
        ),
      ),
    );
    await tester.tap(find.text('Deshacer'));
    await tester.pump();
    await tester.pump();
    expect(find.text('17/75'), findsOneWidget);
    expect(
      find.text('No se pudo deshacer. Revisa tu conexión.'),
      findsOneWidget,
    );

    falla = false;
    await tester.tap(find.text('Deshacer'));
    await tester.pump();
    await tester.pump();
    expect(find.text('16/75'), findsOneWidget);
  });
}
