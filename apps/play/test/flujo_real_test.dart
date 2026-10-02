import 'package:bing_core/bing_core.dart';
import 'package:bing_play/main.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cargar_fuentes.dart';

void main() {
  setUpAll(cargarFuentesBing);

  RepositorioMemoria sala({int ocupadas = 4}) {
    final repo = RepositorioMemoria(cartillas: cartillasDemo);
    for (var i = 1; i <= ocupadas; i++) {
      repo.ocupar(i, 'Jugador $i', 'u$i');
    }
    return repo;
  }

  /// Abre la app en un teléfono alto, donde las salas quedan a la vista.
  Future<void> abrir(WidgetTester tester, RepositorioMemoria repo) async {
    tester.view
      ..devicePixelRatio = 2
      ..physicalSize = const Size(360 * 2, 800 * 2);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(BingPlayApp(repositorio: repo));
  }

  Future<void> escribirCodigo(WidgetTester tester, String codigo) async {
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, codigo);
    await tester.pumpAndSettle();
  }

  group('salas abiertas', () {
    testWidgets('el inicio lista las públicas con sus filas libres', (
      tester,
    ) async {
      await abrir(tester, sala());
      await tester.pumpAndSettle();
      expect(find.text('SALAS ABIERTAS AHORA'), findsOneWidget);
      expect(find.text('Bingo de los sábados'), findsOneWidget);
      expect(find.text('Organiza Carmen'), findsOneWidget);
      expect(find.text('Quedan 16'), findsOneWidget);
    });

    testWidgets('tocar una sala lleva directo a elegir fila, sin código', (
      tester,
    ) async {
      await abrir(tester, sala());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bingo de los sábados'));
      await tester.pumpAndSettle();
      expect(find.text('Elige tu fila'), findsOneWidget);
      expect(find.text('Seguir con la fila 5'), findsOneWidget);
    });

    testWidgets('una sala privada no se lista y avisa que no hay salas', (
      tester,
    ) async {
      final privada = RepositorioMemoria(
        cartillas: cartillasDemo,
        publica: false,
      );
      await abrir(tester, privada);
      await tester.pumpAndSettle();
      expect(find.text('Bingo de los sábados'), findsNothing);
      expect(
        find.textContaining('Ahora no hay salas abiertas'),
        findsOneWidget,
      );
      // Con su código sí se entra.
      await escribirCodigo(tester, 'K7Q4');
      expect(find.text('Bingo de los sábados'), findsOneWidget);
    });

    testWidgets('una sala llena no se muestra en el inicio', (tester) async {
      final repo = sala(ocupadas: 20);
      await abrir(tester, repo);
      await tester.pumpAndSettle();
      expect(find.text('Bingo de los sábados'), findsNothing);
      expect(
        find.textContaining('Ahora no hay salas abiertas'),
        findsOneWidget,
      );
    });

    testWidgets('el inicio es el código y el QR, con las salas debajo', (
      tester,
    ) async {
      await abrir(tester, sala());
      await tester.pumpAndSettle();
      expect(
        find.text('Escribe el código que te dio quien organiza'),
        findsOneWidget,
      );
      expect(find.text('Escanear el QR'), findsOneWidget);
      expect(find.text('Ver filas libres'), findsOneWidget);
    });

    testWidgets('al escribir el código se esconden las salas', (tester) async {
      await abrir(tester, sala());
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .ancestor(
              of: find.byType(BingCasillasCodigo),
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.text('SALAS ABIERTAS AHORA'), findsNothing);
      // Al soltar el foco vuelven.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.text('SALAS ABIERTAS AHORA'), findsOneWidget);
    });

    testWidgets('al volver de elegir fila se regresa al inicio', (
      tester,
    ) async {
      await abrir(tester, sala());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bingo de los sábados'));
      await tester.pumpAndSettle();
      expect(find.text('Elige tu fila'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Volver'));
      await tester.pumpAndSettle();
      expect(find.text('SALAS ABIERTAS AHORA'), findsOneWidget);
    });

    testWidgets('una sala nueva aparece sola en la lista', (tester) async {
      final repo = sala(ocupadas: 0);
      await abrir(tester, repo);
      await tester.pumpAndSettle();
      expect(find.text('Quedan 20'), findsOneWidget);
      repo.ocupar(1, 'Ana', 'u1');
      await tester.pumpAndSettle();
      expect(find.text('Quedan 19'), findsOneWidget);
    });
  });

  testWidgets('un código que no existe avisa y no deja avanzar', (
    tester,
  ) async {
    await tester.pumpWidget(BingPlayApp(repositorio: sala()));
    await escribirCodigo(tester, 'zzzz');
    expect(find.textContaining('No encontramos una sala'), findsOneWidget);
    await tester.tap(find.text('Ver filas libres'));
    await tester.pumpAndSettle();
    expect(find.text('Elige tu fila'), findsNothing);
  });

  testWidgets(
    'recorrido real: código, fila, reserva, espera, en vivo y ganaste',
    (tester) async {
      final repo = sala();
      await tester.pumpWidget(BingPlayApp(repositorio: repo));

      // El código se escribe en minúsculas y se muestra en mayúsculas.
      await escribirCodigo(tester, 'k7q4');
      expect(
        find.text('Organiza Carmen · quedan 16 filas libres'),
        findsOneWidget,
      );

      await tester.tap(find.text('Ver filas libres'));
      await tester.pumpAndSettle();
      expect(find.text('Elige tu fila'), findsOneWidget);
      // La primera libre es la 5.
      expect(find.text('Seguir con la fila 5'), findsOneWidget);
      await tester.tap(find.text('Seguir con la fila 5'));
      await tester.pumpAndSettle();

      // Sin nombre no se reserva.
      await tester.tap(find.text('Reservar fila 5'));
      await tester.pumpAndSettle();
      expect(
        find.text('Escribe tu nombre para reservar la fila.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(EditableText).first, 'Lucía');
      await tester.tap(find.text('Reservar fila 5'));
      await tester.pumpAndSettle();
      expect(find.text('Tu fila está reservada'), findsOneWidget);
      expect(find.text('5 de 20'), findsOneWidget);

      // Otros jugadores van llegando y la sala se llena sola.
      for (var i = 6; i <= 20; i++) {
        repo.ocupar(i, 'Jugador $i', 'u$i');
      }
      await tester.pumpAndSettle();
      expect(find.text('20 de 20'), findsOneWidget);

      // Carmen empieza, pero hasta la primera bolilla se sigue esperando.
      repo.empezarPartida();
      await tester.pumpAndSettle();
      expect(find.text('En vivo'), findsNothing);
      repo.sacar(bolillasDemo.first);
      await tester.pumpAndSettle();
      expect(find.text('En vivo'), findsOneWidget);

      // Salen las bolillas hasta que la fila 5 gana con la 32 (B-12).
      bolillasDemo.skip(1).forEach(repo.sacar);
      await tester.pump(); // llegan las bolillas
      await tester.pump(); // se detecta la fila ganadora y arranca el retardo
      await tester.pump(const Duration(milliseconds: 600)); // entra la victoria
      await tester.pumpAndSettle();
      expect(find.text('¡Ganaste!'), findsOneWidget);
      expect(find.text('Lucía, completaste la fila 5'), findsOneWidget);
    },
  );

  testWidgets('si otra persona se queda la fila antes, se explica el rechazo', (
    tester,
  ) async {
    final repo = sala();
    await tester.pumpWidget(BingPlayApp(repositorio: repo));
    await escribirCodigo(tester, 'K7Q4');
    await tester.tap(find.text('Ver filas libres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seguir con la fila 5'));
    await tester.pumpAndSettle();

    // Mientras Lucía escribe su nombre, otra persona toma la fila 5.
    repo.ocupar(5, 'Rápida', 'otra');
    await tester.enterText(find.byType(EditableText).first, 'Lucía');
    await tester.tap(find.text('Reservar fila 5'));
    await tester.pumpAndSettle();
    expect(
      find.text('Esa fila ya la tomó otra persona. Vuelve atrás y elige otra.'),
      findsOneWidget,
    );
    expect(find.text('Tu fila está reservada'), findsNothing);
  });
}
