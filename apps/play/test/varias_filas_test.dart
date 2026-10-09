import 'package:bing_core/bing_core.dart';
import 'package:bing_play/main.dart';
import 'package:bing_play/src/paginas/elegir_fila_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cargar_fuentes.dart';

const _lucia = UsuarioBing(
  uid: 'g1',
  nombre: 'Lucía Torres',
  correo: 'lucia@correo.com',
);

void main() {
  setUpAll(cargarFuentesBing);

  void pantalla(WidgetTester tester) {
    tester.view
      ..devicePixelRatio = 2
      ..physicalSize = const Size(360 * 2, 800 * 2);
    addTearDown(tester.view.reset);
  }

  group('ElegirFilaPage', () {
    Future<void> abrir(
      WidgetTester tester, {
      int precio = 0,
      int? saldo,
      int limite = 20,
      Set<int> inicial = const {},
      ValueChanged<List<int>>? alSeguir,
      VoidCallback? alRecargar,
    }) async {
      pantalla(tester);
      await tester.pumpWidget(
        BingPlayApp(
          inicio: ElegirFilaPage(
            salaNombre: 'Bingo de los sábados',
            cartillas: cartillasDemo.take(9).toList(),
            duenos: List<String?>.filled(9, null),
            seleccionInicial: inicial,
            precioFila: precio,
            premio: precio * 16,
            saldo: saldo,
            limite: limite,
            alSeguir: alSeguir,
            alRecargar: alRecargar,
          ),
        ),
      );
    }

    Finder fila(int n) => find.bySemanticsLabel('Fila $n, libre');

    testWidgets('se pueden elegir varias filas y llegan ordenadas', (
      tester,
    ) async {
      List<int>? recibido;
      await abrir(tester, alSeguir: (f) => recibido = f);
      await tester.tap(fila(7));
      await tester.tap(fila(2));
      await tester.tap(fila(5));
      await tester.pump();
      expect(find.text('Seguir con 3 filas'), findsOneWidget);
      await tester.tap(find.text('Seguir con 3 filas'));
      expect(recibido, [2, 5, 7]);
    });

    testWidgets('tocar una elegida la quita; sin filas no se puede seguir', (
      tester,
    ) async {
      await abrir(tester, inicial: {5});
      expect(find.text('Seguir con la fila 5'), findsOneWidget);
      await tester.tap(fila(5));
      await tester.pump();
      expect(find.text('Elige al menos una fila'), findsOneWidget);
      var siguio = false;
      await abrir(tester, alSeguir: (_) => siguio = true);
      await tester.tap(find.text('Elige al menos una fila'));
      expect(siguio, isFalse);
    });

    testWidgets('el saldo limita cuántas filas se pueden elegir', (
      tester,
    ) async {
      await abrir(tester, precio: 5, saldo: 12);
      await tester.tap(fila(1));
      await tester.tap(fila(2));
      await tester.pump();
      expect(find.text('Total: 10 créditos · te quedan 2'), findsOneWidget);
      await tester.tap(fila(3));
      await tester.pump();
      expect(find.text('Con tu saldo alcanzas para 2 filas'), findsOneWidget);
      expect(find.text('Seguir con 2 filas'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('con un solo crédito de alcance lo dice en singular', (
      tester,
    ) async {
      await abrir(tester, precio: 5, saldo: 7, inicial: {1});
      await tester.tap(fila(2));
      await tester.pump();
      expect(find.text('Con tu saldo alcanzas para 1 fila'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('una sala de una sola fila lo dice en singular', (
      tester,
    ) async {
      await abrir(tester, limite: 1, inicial: {1});
      await tester.tap(fila(2));
      await tester.pump();
      expect(
        find.text('Esta sala permite una sola fila por persona'),
        findsOneWidget,
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('el límite de la sala también cuenta', (tester) async {
      await abrir(tester, limite: 2, saldo: 100, precio: 5);
      await tester.tap(fila(1));
      await tester.tap(fila(2));
      await tester.tap(fila(3));
      await tester.pump();
      expect(
        find.text('Esta sala permite hasta 2 filas por persona'),
        findsOneWidget,
      );
      expect(find.text('Seguir con 2 filas'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('sin saldo las filas no se eligen y se ofrece recargar', (
      tester,
    ) async {
      var recargo = false;
      await abrir(
        tester,
        precio: 5,
        saldo: 3,
        alRecargar: () => recargo = true,
      );
      expect(find.textContaining('Tu saldo es 3 créditos.'), findsOneWidget);
      expect(
        find.textContaining('Cada fila cuesta 5 créditos'),
        findsOneWidget,
      );
      expect(find.text('Con saldo podrás elegir tu fila'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Fila 1, libre'));
      await tester.pump();
      expect(find.text('Elegida'), findsNothing);
      await tester.tap(find.text('Recargar créditos'));
      expect(recargo, isTrue);
    });

    testWidgets('una partida gratis no mira el saldo', (tester) async {
      await abrir(tester, precio: 0, saldo: 0);
      await tester.tap(fila(1));
      await tester.tap(fila(2));
      await tester.pump();
      expect(find.text('Seguir con 2 filas'), findsOneWidget);
      expect(find.textContaining('Tu saldo es 0 créditos.'), findsNothing);
    });

    testWidgets('muestra el precio y el premio en el título', (tester) async {
      await abrir(tester, precio: 5, saldo: 25);
      expect(
        find.text('Bingo de los sábados · 5 por fila · premio 80'),
        findsOneWidget,
      );
    });
  });

  group('recorrido con varias filas', () {
    Future<({RepositorioMemoria repo, BilleteraMemoria cartera})> abrir(
      WidgetTester tester, {
      int saldo = 25,
      int precio = 5,
    }) async {
      pantalla(tester);
      final cartera = BilleteraMemoria(saldo: saldo);
      final repo = RepositorioMemoria(
        cartillas: cartillasDemo,
        ordenBolillas: bolillasDemo,
        precioFila: precio,
        premio: 80,
        billetera: cartera,
      );
      for (var i = 1; i <= 4; i++) {
        repo.ocupar(i, 'Jugador $i', 'u$i');
      }
      await tester.pumpWidget(
        BingPlayApp(
          repositorio: repo,
          sesion: SesionMemoria(inicial: _lucia),
          billetera: cartera,
        ),
      );
      await tester.pumpAndSettle();
      return (repo: repo, cartera: cartera);
    }

    Future<void> entrar(WidgetTester tester) async {
      await tester.tap(find.text('Bingo de los sábados'));
      await tester.pumpAndSettle();
    }

    testWidgets('elige tres filas, las reserva y se le cobran', (tester) async {
      final r = await abrir(tester);
      await entrar(tester);
      // La primera libre (5) viene elegida; se suman la 6 y la 8.
      await tester.tap(find.bySemanticsLabel('Fila 6, libre'));
      await tester.tap(find.bySemanticsLabel('Fila 8, libre'));
      await tester.pump();
      expect(find.text('Seguir con 3 filas'), findsOneWidget);
      await tester.tap(find.text('Seguir con 3 filas'));
      await tester.pumpAndSettle();

      expect(find.text('Reserva tus filas'), findsOneWidget);
      expect(find.text('Fila 5'), findsOneWidget);
      expect(find.text('Fila 6'), findsOneWidget);
      expect(find.text('Fila 8'), findsOneWidget);
      expect(find.textContaining('Total: 15 créditos.'), findsOneWidget);
      expect(find.textContaining('te quedan 10'), findsOneWidget);
      expect(
        find.textContaining('las filas 5, 6 y 8 quedan a tu nombre'),
        findsOneWidget,
      );
      await tester.tap(find.text('Reservar 3 filas'));
      await tester.pumpAndSettle();

      expect(r.cartera.saldoActual, 10);
      expect(find.text('Tus filas están reservadas'), findsOneWidget);
      expect(find.text('Tu fila · la 5'), findsOneWidget);
      expect(find.text('Tu fila · la 6'), findsOneWidget);
      expect(find.text('Tu fila · la 8'), findsOneWidget);
      final filas = await r.repo.filas('K7Q4').first;
      expect([
        for (final i in [4, 5, 7]) filas[i].jugadorUid,
      ], everyElement('yo'));
    });

    testWidgets('sin nombre no reserva y lo dice en plural', (tester) async {
      await abrir(tester);
      await entrar(tester);
      await tester.tap(find.bySemanticsLabel('Fila 6, libre'));
      await tester.pump();
      await tester.tap(find.text('Seguir con 2 filas'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).first, '');
      await tester.tap(find.text('Reservar 2 filas'));
      await tester.pumpAndSettle();
      expect(
        find.text('Escribe tu nombre para reservar las filas.'),
        findsOneWidget,
      );
    });

    testWidgets('sin saldo se ofrece recargar y se llega a la billetera', (
      tester,
    ) async {
      await abrir(tester, saldo: 2);
      await entrar(tester);
      expect(find.textContaining('Tu saldo es 2 créditos.'), findsOneWidget);
      await tester.tap(find.text('Recargar créditos'));
      await tester.pumpAndSettle();
      expect(find.text('Mi billetera'), findsOneWidget);
    });

    testWidgets('al recargar vuelve a poder elegir filas', (tester) async {
      final r = await abrir(tester, saldo: 2);
      await entrar(tester);
      expect(find.textContaining('Tu saldo es 2 créditos.'), findsOneWidget);
      await r.cartera.recargar(20);
      await tester.pumpAndSettle();
      expect(find.textContaining('Tu saldo es 2 créditos.'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Fila 5, libre'));
      await tester.pump();
      expect(find.text('Seguir con la fila 5'), findsOneWidget);
    });

    testWidgets('gana con la segunda de sus filas', (tester) async {
      final r = await abrir(tester);
      await entrar(tester);
      // La 5 gana con la bolilla 32; la 6 no.
      await tester.tap(find.bySemanticsLabel('Fila 6, libre'));
      await tester.pump();
      await tester.tap(find.text('Seguir con 2 filas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reservar 2 filas'));
      await tester.pumpAndSettle();
      for (var i = 7; i <= 20; i++) {
        r.repo.ocupar(i, 'Jugador $i', 'u$i');
      }
      await tester.pumpAndSettle();
      r.repo.empezarPartida();
      r.repo.sacar(bolillasDemo.first);
      await tester.pumpAndSettle();
      expect(find.text('En vivo'), findsOneWidget);
      expect(find.text('Tu fila · la 5'), findsOneWidget);
      expect(find.text('Tu fila · la 6'), findsOneWidget);
      bolillasDemo.skip(1).forEach(r.repo.sacar);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.text('¡Ganaste!'), findsOneWidget);
      expect(find.text('Lucía, completaste la fila 5'), findsOneWidget);
    });

    testWidgets('si cierran la sala, se le devuelve todo lo pagado', (
      tester,
    ) async {
      final r = await abrir(tester);
      await entrar(tester);
      await tester.tap(find.bySemanticsLabel('Fila 6, libre'));
      await tester.pump();
      await tester.tap(find.text('Seguir con 2 filas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reservar 2 filas'));
      await tester.pumpAndSettle();
      expect(r.cartera.saldoActual, 15);
      await r.repo.cancelarSala('K7Q4', motivo: 'No se llenó');
      await tester.pumpAndSettle();
      expect(find.text('La sala se cerró'), findsOneWidget);
      expect(r.cartera.saldoActual, 25);
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      expect(find.text('25 créditos'), findsOneWidget);
    });
  });
}
