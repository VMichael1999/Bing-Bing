import 'package:bing_core/bing_core.dart';
import 'package:bing_host/main.dart';
import 'package:bing_host/src/paginas/compartir_page.dart';
import 'package:bing_host/src/paginas/qr_pantalla_page.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cargar_fuentes.dart';

final _cerrar = find.byWidgetPredicate(
  (w) => w is BingBotonIcono && w.icono == 'close',
);

void main() {
  setUpAll(cargarFuentesBing);

  group('CompartirPage', () {
    testWidgets('muestra el código, el enlace sin https y los dos botones', (
      tester,
    ) async {
      await tester.pumpWidget(
        const BingHostApp(
          inicio: CompartirPage(
            salaNombre: 'Bingo de los sábados',
            codigo: 'K7Q4',
          ),
        ),
      );
      expect(find.text('Comparte tu sala'), findsOneWidget);
      expect(find.text('Bingo de los sábados'), findsOneWidget);
      expect(find.text('K7Q4'), findsOneWidget);
      expect(find.text('bingbing-f1491.web.app/sala/K7Q4'), findsOneWidget);
      expect(find.text('Compartir'), findsOneWidget);
      expect(find.text('Mostrar QR a pantalla completa'), findsOneWidget);
    });

    testWidgets('un chip indica si la sala es pública o privada', (
      tester,
    ) async {
      await tester.pumpWidget(
        const BingHostApp(
          inicio: CompartirPage(salaNombre: 'X', codigo: 'K7Q4', publica: true),
        ),
      );
      expect(find.text('Pública'), findsOneWidget);
      await tester.pumpWidget(
        const BingHostApp(
          inicio: CompartirPage(
            salaNombre: 'X',
            codigo: 'K7Q4',
            publica: false,
          ),
        ),
      );
      expect(find.text('Privada'), findsOneWidget);
      expect(find.text('Pública'), findsNothing);
    });

    testWidgets('cada botón y el enlace avisan al tocarlos', (tester) async {
      final tocados = <String>[];
      await tester.pumpWidget(
        BingHostApp(
          inicio: CompartirPage(
            salaNombre: 'X',
            codigo: 'K7Q4',
            alVolver: () => tocados.add('volver'),
            alCopiarEnlace: () => tocados.add('copiar'),
            alCompartir: () => tocados.add('compartir'),
            alPantallaCompleta: () => tocados.add('pantalla'),
          ),
        ),
      );
      await tester.tap(find.text('bingbing-f1491.web.app/sala/K7Q4'));
      await tester.tap(find.text('Compartir'));
      await tester.tap(find.text('Mostrar QR a pantalla completa'));
      expect(tocados, ['copiar', 'compartir', 'pantalla']);
    });
  });

  group('QrPantallaPage', () {
    testWidgets('muestra el QR grande con el código y se cierra', (
      tester,
    ) async {
      var cerrado = false;
      await tester.pumpWidget(
        BingHostApp(
          inicio: QrPantallaPage(
            codigo: 'K7Q4',
            alCerrar: () => cerrado = true,
          ),
        ),
      );
      expect(find.text('Escanea para entrar'), findsOneWidget);
      expect(find.text('K7Q4'), findsOneWidget);
      expect(find.textContaining('escribe el código'), findsOneWidget);
      await tester.tap(_cerrar);
      expect(cerrado, isTrue);
    });
  });

  group('desde la sala abierta', () {
    String? copiado;
    final compartidos = <String>[];

    setUp(() {
      copiado = null;
      compartidos.clear();
    });

    void simularPlataforma(WidgetTester tester) {
      final mensajero = tester.binding.defaultBinaryMessenger;
      mensajero.setMockMethodCallHandler(SystemChannels.platform, (
        llamada,
      ) async {
        if (llamada.method == 'Clipboard.setData') {
          copiado = (llamada.arguments as Map)['text'] as String?;
        }
        return null;
      });
      mensajero.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'),
        (llamada) async {
          compartidos.add('${llamada.arguments}');
          return 'dev.fluttercommunity.plus/share/unavailable';
        },
      );
      addTearDown(() {
        mensajero.setMockMethodCallHandler(SystemChannels.platform, null);
        mensajero.setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/share'),
          null,
        );
      });
    }

    testWidgets(
      'compartir copia el enlace, abre el menú y muestra el QR grande',
      (tester) async {
        simularPlataforma(tester);
        final repo = RepositorioMemoria(cartillas: cartillasDemo);
        await tester.pumpWidget(
          BingHostApp(repositorio: repo, entrar: () async => 'Carmen'),
        );
        await tester.tap(find.text('Continuar con Google'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Nueva partida'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(EditableText).first,
          'Bingo de los sábados',
        );
        await tester.tap(find.text('Abrir sala'));
        await tester.pumpAndSettle();

        // "Copiar" del código copia solo las cuatro letras.
        await tester.tap(find.text('Copiar'));
        await tester.pump();
        expect(copiado, 'K7Q4');
        expect(find.text('Código copiado'), findsOneWidget);
        await tester.pump(const Duration(seconds: 2));

        await tester.tap(find.text('Compartir'));
        await tester.pumpAndSettle();
        expect(find.text('Comparte tu sala'), findsOneWidget);

        await tester.tap(find.text('bingbing-f1491.web.app/sala/K7Q4'));
        await tester.pump();
        expect(copiado, 'https://bingbing-f1491.web.app/sala/K7Q4');
        expect(find.text('Enlace copiado'), findsOneWidget);
        await tester.pump(const Duration(seconds: 2));
        expect(find.text('Enlace copiado'), findsNothing);

        await tester.tap(find.text('Compartir').last);
        await tester.pump();
        expect(
          compartidos.single,
          contains('https://bingbing-f1491.web.app/sala/K7Q4'),
        );
        expect(compartidos.single, contains('"Bingo de los sábados"'));

        await tester.tap(find.text('Mostrar QR a pantalla completa'));
        await tester.pumpAndSettle();
        expect(find.text('Escanea para entrar'), findsOneWidget);
        await tester.tap(_cerrar);
        await tester.pumpAndSettle();
        expect(find.text('Comparte tu sala'), findsOneWidget);
      },
    );
  });
}
