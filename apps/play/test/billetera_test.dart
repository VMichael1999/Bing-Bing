import 'package:bing_core/bing_core.dart';
import 'package:bing_play/main.dart';
import 'package:bing_play/src/paginas/billetera_page.dart';
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

  Future<({SesionMemoria sesion, BilleteraMemoria cartera})> abrir(
    WidgetTester tester, {
    UsuarioBing? usuario = _lucia,
    int saldo = 25,
  }) async {
    tester.view
      ..devicePixelRatio = 2
      ..physicalSize = const Size(360 * 2, 800 * 2);
    addTearDown(tester.view.reset);
    final sesion = SesionMemoria(inicial: usuario);
    final cartera = BilleteraMemoria(saldo: saldo);
    final repo = RepositorioMemoria(
      cartillas: cartillasDemo,
      billetera: cartera,
    );
    await tester.pumpWidget(
      BingPlayApp(repositorio: repo, sesion: sesion, billetera: cartera),
    );
    await tester.pumpAndSettle();
    return (sesion: sesion, cartera: cartera);
  }

  testWidgets('con cuenta, el inicio muestra los créditos', (tester) async {
    await abrir(tester);
    expect(find.text('25 créditos'), findsOneWidget);
    expect(find.bySemanticsLabel('Mi cuenta'), findsOneWidget);
  });

  testWidgets('un invitado no ve créditos', (tester) async {
    await abrir(tester, usuario: null);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.textContaining('créditos'), findsNothing);
  });

  testWidgets('el chip abre Mi billetera con el saldo y los movimientos', (
    tester,
  ) async {
    final r = await abrir(tester);
    r.cartera.aplicar(
      Movimiento(
        tipo: TipoMovimiento.fila,
        monto: -5,
        detalle: 'Fila 5 · Bingo de los sábados',
        creadaEn: DateTime.now(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('20 créditos'), findsOneWidget); // el chip se actualizó
    await tester.tap(find.text('20 créditos'));
    await tester.pumpAndSettle();
    expect(find.text('Mi billetera'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('Fila 5 · Bingo de los sábados'), findsOneWidget);
    expect(find.text('−5'), findsOneWidget);
    expect(find.text('De prueba · sin valor en dinero'), findsOneWidget);
  });

  testWidgets('recargar suma los créditos al instante', (tester) async {
    final r = await abrir(tester);
    await tester.tap(find.text('25 créditos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recargar'));
    await tester.pumpAndSettle();
    expect(find.text('Recargar créditos'), findsOneWidget);
    expect(find.text('Agregar 20 créditos'), findsOneWidget);
    await tester.tap(find.text('50'));
    await tester.pump();
    expect(find.text('Agregar 50 créditos'), findsOneWidget);
    await tester.tap(find.text('Agregar 50 créditos'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(r.cartera.saldoActual, 75);
    expect(find.text('Se agregaron 50 créditos'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('75'), findsOneWidget);
    expect(find.text('Recarga'), findsOneWidget);
  });

  testWidgets('tocar fuera de la hoja la cierra sin recargar', (tester) async {
    final r = await abrir(tester);
    await tester.tap(find.text('25 créditos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recargar'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(180, 60));
    await tester.pumpAndSettle();
    expect(find.text('Recargar créditos'), findsNothing);
    expect(r.cartera.saldoActual, 25);
  });

  testWidgets('Mi cuenta tiene la fila de la billetera', (tester) async {
    await abrir(tester);
    await tester.tap(find.bySemanticsLabel('Mi cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('25 créditos de prueba'), findsOneWidget);
    await tester.tap(find.text('Billetera'));
    await tester.pumpAndSettle();
    expect(find.text('Mi billetera'), findsOneWidget);
  });

  testWidgets('al cerrar sesión desaparecen los créditos', (tester) async {
    final r = await abrir(tester);
    expect(find.text('25 créditos'), findsOneWidget);
    await r.sesion.cerrarSesion();
    await tester.pumpAndSettle();
    expect(find.text('25 créditos'), findsNothing);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  group('cuandoFue', () {
    final ahora = DateTime(2026, 10, 2, 21);
    test('hoy, ayer y fecha corta', () {
      expect(
        cuandoFue(DateTime(2026, 10, 2, 20, 45), ahora: ahora),
        'Hoy 20:45',
      );
      expect(
        cuandoFue(DateTime(2026, 10, 1, 9, 5), ahora: ahora),
        'Ayer 09:05',
      );
      expect(cuandoFue(DateTime(2026, 9, 19, 21), ahora: ahora), '19 set');
      expect(cuandoFue(null, ahora: ahora), '');
    });
  });
}
