import 'package:bing_core/bing_core.dart';
import 'package:bing_host/main.dart';
import 'package:bing_host/src/flujo_real.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cargar_fuentes.dart';

final _bolillaGrande = find.byWidgetPredicate(
  (w) => w is BingBolilla && w.tamano == BingBolillaTamano.xl,
);

RepositorioMemoria _repo() =>
    RepositorioMemoria(cartillas: cartillasDemo, ordenBolillas: bolillasDemo);

Widget _app(RepositorioMemoria repo, {Future<String?> Function()? entrar}) =>
    BingHostApp(repositorio: repo, entrar: entrar ?? () async => 'Carmen');

void main() {
  setUpAll(cargarFuentesBing);

  testWidgets('entrar, crear la sala, llenarla, sortear y ver quién gana', (
    tester,
  ) async {
    final repo = _repo();
    await tester.pumpWidget(_app(repo));

    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();
    expect(find.text('Tus partidas'), findsOneWidget);
    expect(find.text('Carmen · organizadora'), findsOneWidget);
    expect(find.text('sala abierta'), findsOneWidget);

    await tester.tap(find.text('Nueva partida'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(EditableText).first,
      'Bingo de los sábados',
    );
    await tester.tap(find.text('Abrir sala'));
    await tester.pumpAndSettle();
    expect(find.text('K7Q4'), findsWidgets);
    expect(find.text('Esperando a 20 jugadores'), findsOneWidget);

    // Los jugadores reservan sus filas en cualquier orden.
    for (final i in [
      7,
      2,
      15,
      1,
      20,
      9,
      3,
      11,
      5,
      13,
      4,
      6,
      8,
      10,
      12,
      14,
      16,
      17,
      18,
    ]) {
      repo.ocupar(i, 'Jugador $i', 'u$i');
    }
    await tester.pumpAndSettle();
    expect(find.text('Esperando a 1 jugador'), findsOneWidget);

    // La última fila llena la cartilla y sube la hoja.
    repo.ocupar(19, 'Jugador 19', 'u19');
    await tester.pump(); // llega la fila
    await tester.pump(); // se detecta la sala llena y arranca el retardo
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('Esperar un momento'), findsOneWidget);
    await tester.tap(find.text('Empezar partida').last);
    await tester.pumpAndSettle();
    expect(find.text('0/75'), findsOneWidget);

    // El servidor saca las bolillas; con la 32 gana la fila 5.
    for (var i = 0; i < 32; i++) {
      await tester.tap(_bolillaGrande);
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.textContaining('Jugador 5'), findsWidgets);
    expect(find.textContaining('32'), findsWidgets);
  });

  testWidgets('si no se puede entrar se explica y no se avanza', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_repo(), entrar: () async => throw Exception('sin red')),
    );
    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();
    expect(
      find.text('No pudimos iniciar sesión. Inténtalo de nuevo.'),
      findsOneWidget,
    );
    expect(find.text('Tus partidas'), findsNothing);
  });

  testWidgets('cancelar Google se queda en la pantalla de entrar', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_repo(), entrar: () async => null));
    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();
    expect(find.text('Tus partidas'), findsNothing);
    expect(find.text('Continuar con Google'), findsOneWidget);
  });

  testWidgets('6 columnas todavía no se pueden abrir', (tester) async {
    await tester.pumpWidget(_app(_repo()));
    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva partida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6 · 90 bolillas'));
    await tester.pump();
    await tester.tap(find.text('Abrir sala'));
    await tester.pumpAndSettle();
    expect(find.text('Las 6 columnas llegan pronto.'), findsOneWidget);
    expect(
      find.text('Sala abierta · los jugadores eligen su fila'),
      findsNothing,
    );
  });

  group('jugadoresDeLaSala', () {
    List<FilaEnVivo> filas(Set<int> ocupadas) => [
      for (var i = 1; i <= 20; i++)
        FilaEnVivo(
          numeros: const [1, 16, 31, 46, 61],
          nombre: ocupadas.contains(i) ? 'J$i' : null,
          jugadorUid: ocupadas.contains(i) ? 'u$i' : null,
          reservadaEn: DateTime(2026, 10, 2, 20, i),
        ),
    ];

    test('con pocas filas muestra todas y luego las libres', () {
      final lista = jugadoresDeLaSala(filas({3, 1}));
      expect(lista.take(2).map((j) => j.numero), ['1', '3']);
      expect(lista.length, 20);
      expect(lista.last.estado, BingJugadorEstado.libre);
    });

    test('con muchas muestra 5, un salto y la última en llegar en verde', () {
      final lista = jugadoresDeLaSala(filas({for (var i = 1; i <= 17; i++) i}));
      expect(lista.take(5).map((j) => j.numero), ['1', '2', '3', '4', '5']);
      expect(lista[5].estado, BingJugadorEstado.salto);
      expect(lista[5].nombre, 'filas 6 a 16');
      expect(lista[6].estado, BingJugadorEstado.nuevo);
      expect(lista[6].numero, '17');
      expect(
        lista.skip(7).every((j) => j.estado == BingJugadorEstado.libre),
        isTrue,
      );
    });
  });

  test('detalleDeSala resume fecha, estado y ganadora', () {
    final sala = SalaEnVivo(
      codigo: 'K7Q4',
      nombre: 'X',
      organizador: 'Carmen',
      estado: EstadoSala.terminada,
      columnas: 5,
      filasTotal: 20,
      bolillas: const [],
      ganadoras: const [(fila: 4, bolillaIndice: 32)],
      creadaEn: DateTime(2026, 9, 26),
    );
    expect(detalleDeSala(sala), '26 set · terminada · ganó la fila 5');
  });
}
