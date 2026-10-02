import 'package:bing_core/bing_core.dart';
import 'package:bing_play/main.dart';
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

  Future<void> abrir(WidgetTester tester, SesionMemoria sesion) async {
    tester.view
      ..devicePixelRatio = 2
      ..physicalSize = const Size(360 * 2, 800 * 2);
    addTearDown(tester.view.reset);
    final repo = RepositorioMemoria(cartillas: cartillasDemo);
    for (var i = 1; i <= 4; i++) {
      repo.ocupar(i, 'Jugador $i', 'u$i');
    }
    await tester.pumpWidget(BingPlayApp(repositorio: repo, sesion: sesion));
    await tester.pumpAndSettle();
  }

  Future<void> entrarAElegirFila(WidgetTester tester) async {
    await tester.tap(find.text('Bingo de los sábados'));
    await tester.pumpAndSettle();
    expect(find.text('Elige tu fila'), findsOneWidget);
    await tester.tap(find.text('Seguir con la fila 5'));
    await tester.pumpAndSettle();
  }

  group('elegir fila exige cuenta', () {
    testWidgets('sin cuenta sube la hoja y no avanza', (tester) async {
      await abrir(tester, SesionMemoria());
      await entrarAElegirFila(tester);
      expect(find.text('Inicia sesión para jugar'), findsOneWidget);
      expect(find.text('Reservar fila 5'), findsNothing);
    });

    testWidgets('"Ahora no" deja la sala como estaba', (tester) async {
      await abrir(tester, SesionMemoria());
      await entrarAElegirFila(tester);
      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();
      expect(find.text('Inicia sesión para jugar'), findsNothing);
      expect(find.text('Elige tu fila'), findsOneWidget);
    });

    testWidgets('con Google sigue a reservar y propone el nombre', (
      tester,
    ) async {
      await abrir(tester, SesionMemoria(cuentaGoogle: _lucia));
      await entrarAElegirFila(tester);
      await tester.tap(find.text('Continuar con Google'));
      await tester.pumpAndSettle();
      expect(find.text('Inicia sesión para jugar'), findsNothing);
      expect(find.text('Reservar fila 5'), findsOneWidget);
      expect(find.text('Lucía'), findsOneWidget);
    });

    testWidgets('si se cierra la ventana de Google la hoja sigue', (
      tester,
    ) async {
      await abrir(tester, SesionMemoria());
      await entrarAElegirFila(tester);
      await tester.tap(find.text('Continuar con Google'));
      await tester.pumpAndSettle();
      expect(find.text('Inicia sesión para jugar'), findsOneWidget);
      expect(find.text('Reservar fila 5'), findsNothing);
    });

    testWidgets('si Google falla se explica y se puede reintentar', (
      tester,
    ) async {
      final sesion = SesionMemoria()..fallo = Exception('sin red');
      await abrir(tester, sesion);
      await entrarAElegirFila(tester);
      await tester.tap(find.text('Continuar con Google'));
      await tester.pumpAndSettle();
      expect(
        find.text('No pudimos iniciar sesión con Google. Inténtalo de nuevo.'),
        findsOneWidget,
      );
      sesion
        ..fallo = null
        ..cuentaGoogle = _lucia;
      await tester.tap(find.text('Continuar con Google'));
      await tester.pumpAndSettle();
      expect(find.text('Reservar fila 5'), findsOneWidget);
    });

    testWidgets('con cuenta no vuelve a preguntar', (tester) async {
      await abrir(tester, SesionMemoria(inicial: _lucia));
      await entrarAElegirFila(tester);
      expect(find.text('Inicia sesión para jugar'), findsNothing);
      expect(find.text('Reservar fila 5'), findsOneWidget);
    });

    testWidgets('el celular aún no está disponible', (tester) async {
      await abrir(tester, SesionMemoria());
      await entrarAElegirFila(tester);
      expect(find.text('Celular · pronto'), findsOneWidget);
    });
  });

  group('acceso desde el inicio', () {
    testWidgets(
      'el chip "Iniciar sesión" abre la hoja y luego muestra la cuenta',
      (tester) async {
        await abrir(tester, SesionMemoria(cuentaGoogle: _lucia));
        expect(find.text('Iniciar sesión'), findsOneWidget);
        await tester.tap(find.text('Iniciar sesión'));
        await tester.pumpAndSettle();
        expect(find.text('Inicia sesión para jugar'), findsOneWidget);
        await tester.tap(find.text('Continuar con Google'));
        await tester.pumpAndSettle();
        expect(find.text('Iniciar sesión'), findsNothing);
        expect(find.bySemanticsLabel('Mi cuenta'), findsOneWidget);
      },
    );

    testWidgets('sin sesión de jugador no hay chip', (tester) async {
      tester.view
        ..devicePixelRatio = 2
        ..physicalSize = const Size(360 * 2, 800 * 2);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        BingPlayApp(repositorio: RepositorioMemoria(cartillas: cartillasDemo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Iniciar sesión'), findsNothing);
    });
  });

  group('Mi cuenta', () {
    Future<void> abrirCuenta(WidgetTester tester, SesionMemoria sesion) async {
      await abrir(tester, sesion);
      await tester.tap(find.bySemanticsLabel('Mi cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('Mi cuenta'), findsWidgets);
    }

    testWidgets('muestra quién eres', (tester) async {
      await abrirCuenta(tester, SesionMemoria(inicial: _lucia));
      expect(find.text('Lucía Torres'), findsOneWidget);
      expect(find.text('lucia@correo.com'), findsWidgets);
      expect(find.text('Vinculado'), findsOneWidget);
    });

    testWidgets('cerrar sesión vuelve al inicio como invitado', (tester) async {
      final sesion = SesionMemoria(inicial: _lucia);
      await abrirCuenta(tester, sesion);
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(sesion.cierres, 1);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Escanear el QR'), findsOneWidget);
    });

    testWidgets('eliminar la cuenta pide confirmar', (tester) async {
      final sesion = SesionMemoria(inicial: _lucia);
      await abrirCuenta(tester, sesion);
      await tester.tap(find.text('Eliminar mi cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('¿Eliminar tu cuenta?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(sesion.borrados, 0);
      expect(find.text('Mi cuenta'), findsWidgets);
    });

    testWidgets('confirmada, se elimina y se vuelve al inicio', (tester) async {
      final sesion = SesionMemoria(inicial: _lucia);
      await abrirCuenta(tester, sesion);
      await tester.tap(find.text('Eliminar mi cuenta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sí, eliminar mi cuenta'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(sesion.borrados, 1);
      expect(find.text('Iniciar sesión'), findsOneWidget);
    });
  });
}
