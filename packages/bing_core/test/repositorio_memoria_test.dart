import 'package:bing_core/bing_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  pruebasOrganizador();
  pruebasVisibilidad();
  pruebasVariasFilas();
  RepositorioMemoria nueva() => RepositorioMemoria(cartillas: cartillasDemo);

  test('buscar solo encuentra el código de la sala', () async {
    final repo = nueva();
    expect((await repo.buscar('K7Q4'))?.nombre, 'Bingo de los sábados');
    expect(await repo.buscar('ZZZZ'), isNull);
  });

  test('reservar toma la fila y el servidor rechaza repetirla', () async {
    final repo = RepositorioMemoria(
      cartillas: cartillasDemo,
      filasPorJugador: 1,
    )..ocupar(1, 'Ana', 'otra');
    await expectLater(
      repo.reservarFila(codigo: 'K7Q4', fila: 1, nombre: 'Yo'),
      throwsA(
        isA<ErrorSalaBing>().having((e) => e.codigo, 'codigo', 'fila_ocupada'),
      ),
    );
    await repo.reservarFila(codigo: 'K7Q4', fila: 5, nombre: 'Lucía');
    await expectLater(
      repo.reservarFila(codigo: 'K7Q4', fila: 6, nombre: 'Lucía'),
      throwsA(
        isA<ErrorSalaBing>().having(
          (e) => e.codigo,
          'codigo',
          'limite_de_filas',
        ),
      ),
    );
    final filas = await repo.filas('K7Q4').first;
    expect(filas[4].nombre, 'Lucía');
    expect(filas[4].jugadorUid, 'yo');
  });

  test('la sala se llena y con la bolilla 32 gana la fila 5', () async {
    final repo = nueva();
    for (var i = 1; i <= 20; i++) {
      repo.ocupar(i, 'J$i', 'u$i');
    }
    expect((await repo.sala('K7Q4').first)!.estado, EstadoSala.llena);
    await expectLater(
      repo.reservarFila(codigo: 'K7Q4', fila: 1, nombre: 'Tarde'),
      throwsA(isA<ErrorSalaBing>()),
    );
    repo.empezarPartida();
    bolillasDemo.forEach(repo.sacar);
    final sala = (await repo.sala('K7Q4').first)!;
    expect(sala.estado, EstadoSala.enJuego);
    expect(sala.ganoLaFila(4), isTrue);
    // Como el servidor: la fila ganadora cuenta desde 1.
    expect(sala.ganadoras.single.fila, 5);
    expect(sala.ganadoras.single.bolillaIndice, 32);
  });

  test('sala emite la foto actual y luego cada cambio', () async {
    final repo = nueva();
    final estados = <EstadoSala>[];
    final suscripcion = repo.sala('K7Q4').listen((s) => estados.add(s!.estado));
    await Future<void>.delayed(Duration.zero);
    repo.empezarPartida();
    await Future<void>.delayed(Duration.zero);
    await suscripcion.cancel();
    expect(estados, [EstadoSala.abierta, EstadoSala.enJuego]);
  });
}

void pruebasVisibilidad() {
  group('visibilidad', () {
    RepositorioMemoria nueva({bool publica = true}) =>
        RepositorioMemoria(cartillas: cartillasDemo, publica: publica);

    test(
      'una sala pública aparece en salasAbiertas con sus filas ocupadas',
      () async {
        final repo = nueva()..ocupar(1, 'Ana', 'u1');
        final salas = await repo.salasAbiertas().first;
        expect(salas.single.codigo, 'K7Q4');
        expect(salas.single.publica, isTrue);
        expect(salas.single.ocupadas, 1);
        expect(salas.single.libres, 19);
      },
    );

    test('una privada no se lista, pero se abre con su código', () async {
      final repo = nueva(publica: false);
      expect(await repo.salasAbiertas().first, isEmpty);
      expect((await repo.buscar('K7Q4'))?.publica, isFalse);
    });

    test('crearSala fija el precio y el premio', () async {
      final repo = nueva();
      await repo.crearSala(nombre: 'X', columnas: 5, precioFila: 5, premio: 80);
      final sala = await repo.buscar('K7Q4');
      expect(sala?.precioFila, 5);
      expect(sala?.premio, 80);
    });

    test('crearSala fija la visibilidad', () async {
      final repo = nueva();
      await repo.crearSala(nombre: 'X', columnas: 5, publica: false);
      expect(await repo.salasAbiertas().first, isEmpty);
    });

    test('una sala cerrada deja de listarse y no recibe jugadores', () async {
      final repo = nueva()..ocupar(1, 'Ana', 'u1');
      await repo.cancelarSala('K7Q4', motivo: '  No se llenó ');
      expect(await repo.salasAbiertas().first, isEmpty);
      final sala = await repo.buscar('K7Q4');
      expect(sala?.estado, EstadoSala.cancelada);
      expect(sala?.motivoCierre, 'No se llenó');
      await expectLater(
        repo.reservarFila(codigo: 'K7Q4', fila: 5, nombre: 'Yo'),
        throwsA(
          isA<ErrorSalaBing>().having(
            (e) => e.codigo,
            'codigo',
            'sala_no_abierta',
          ),
        ),
      );
    });

    test(
      'cerrar sin motivo lo deja vacío y cerrar dos veces no falla',
      () async {
        final repo = nueva();
        await repo.cancelarSala('K7Q4', motivo: '   ');
        await repo.cancelarSala('K7Q4');
        expect((await repo.buscar('K7Q4'))?.motivoCierre, isNull);
      },
    );

    test('una partida empezada no se puede cerrar', () async {
      final repo = nueva();
      for (var i = 1; i <= 20; i++) {
        repo.ocupar(i, 'J$i', 'u$i');
      }
      repo.empezarPartida();
      await expectLater(
        repo.cancelarSala('K7Q4'),
        throwsA(
          isA<ErrorSalaBing>().having(
            (e) => e.codigo,
            'codigo',
            'sala_ya_empezada',
          ),
        ),
      );
    });

    test('al empezar la partida deja de listarse', () async {
      final repo = nueva();
      for (var i = 1; i <= 20; i++) {
        repo.ocupar(i, 'J$i', 'u$i');
      }
      expect(
        await repo.salasAbiertas().first,
        hasLength(1),
      ); // llena, aún se ve
      repo.empezarPartida();
      expect(await repo.salasAbiertas().first, isEmpty);
    });
  });
}

void pruebasOrganizador() {
  group('como organizador', () {
    RepositorioMemoria llena() {
      final repo = RepositorioMemoria(
        cartillas: cartillasDemo,
        ordenBolillas: bolillasDemo,
      );
      for (var i = 1; i <= 20; i++) {
        repo.ocupar(i, 'J$i', 'u$i');
      }
      return repo;
    }

    test('no se empieza con la cartilla a medias ni se sortea antes', () async {
      final repo = RepositorioMemoria(
        cartillas: cartillasDemo,
        ordenBolillas: bolillasDemo,
      );
      await expectLater(
        repo.empezar('K7Q4'),
        throwsA(
          isA<ErrorSalaBing>().having(
            (e) => e.codigo,
            'codigo',
            'sala_no_llena',
          ),
        ),
      );
      await expectLater(
        repo.sacarBolilla('K7Q4'),
        throwsA(isA<ErrorSalaBing>()),
      );
    });

    test(
      'sortea en orden, gana la fila 5 con la 32 y se puede deshacer',
      () async {
        final repo = llena();
        await repo.empezar('K7Q4');
        for (var i = 0; i < 32; i++) {
          await repo.sacarBolilla('K7Q4');
        }
        var sala = (await repo.buscar('K7Q4'))!;
        expect(sala.ganoLaFila(4), isTrue);
        await repo.deshacerBolilla('K7Q4');
        sala = (await repo.buscar('K7Q4'))!;
        expect(sala.bolillas.length, 31);
        expect(sala.ganadoras, isEmpty);
        await repo.terminar('K7Q4');
        expect((await repo.buscar('K7Q4'))!.estado, EstadoSala.terminada);
      },
    );

    test('misSalas emite la sala y las horas de reserva avanzan', () async {
      final repo = llena();
      expect((await repo.misSalas().first).single.codigo, 'K7Q4');
      final filas = await repo.filas('K7Q4').first;
      expect(filas[1].reservadaEn!.isAfter(filas[0].reservadaEn!), isTrue);
    });
  });
}

void pruebasVariasFilas() {
  group('varias filas y billetera', () {
    ErrorSalaBing? error;
    Future<void> intentar(Future<void> Function() f) async {
      error = null;
      try {
        await f();
      } on ErrorSalaBing catch (e) {
        error = e;
      }
    }

    test('se pueden reservar las filas que se quiera, de una vez', () async {
      final repo = RepositorioMemoria(cartillas: cartillasDemo);
      await repo.reservarFilas(codigo: 'K7Q4', filas: [5, 6, 7], nombre: 'Lu');
      final filas = await repo.filas('K7Q4').first;
      expect([
        for (final i in [4, 5, 6]) filas[i].jugadorUid,
      ], everyElement('yo'));
      expect(filas.where((f) => !f.libre), hasLength(3));
    });

    test('es todo o nada: una fila ocupada no deja reservar ninguna', () async {
      final repo = RepositorioMemoria(cartillas: cartillasDemo)
        ..ocupar(6, 'Ana', 'otra');
      await intentar(
        () => repo.reservarFilas(codigo: 'K7Q4', filas: [5, 6], nombre: 'Lu'),
      );
      expect(error?.codigo, 'fila_ocupada');
      final filas = await repo.filas('K7Q4').first;
      expect(filas[4].libre, isTrue);
    });

    test('respeta el límite de filas por jugador', () async {
      final repo = RepositorioMemoria(
        cartillas: cartillasDemo,
        filasPorJugador: 2,
      );
      await intentar(
        () =>
            repo.reservarFilas(codigo: 'K7Q4', filas: [1, 2, 3], nombre: 'Lu'),
      );
      expect(error?.codigo, 'limite_de_filas');
      await repo.reservarFilas(codigo: 'K7Q4', filas: [1, 2], nombre: 'Lu');
    });

    test('no acepta listas vacías ni repetidas', () async {
      final repo = RepositorioMemoria(cartillas: cartillasDemo);
      await intentar(
        () => repo.reservarFilas(codigo: 'K7Q4', filas: [], nombre: 'Lu'),
      );
      expect(error?.codigo, 'filas_invalidas');
      await intentar(
        () => repo.reservarFilas(codigo: 'K7Q4', filas: [3, 3], nombre: 'Lu'),
      );
      expect(error?.codigo, 'filas_invalidas');
    });

    test('cobra cada fila de la billetera y lo anota', () async {
      final cartera = BilleteraMemoria();
      final repo = RepositorioMemoria(
        cartillas: cartillasDemo,
        precioFila: 5,
        premio: 80,
        billetera: cartera,
      );
      await repo.reservarFilas(codigo: 'K7Q4', filas: [3, 1, 2], nombre: 'Lu');
      expect(cartera.saldoActual, 10);
      final movimientos = await cartera.movimientos().first;
      expect(movimientos.map((m) => m.monto), [-5, -5, -5]);
      expect(movimientos.map((m) => m.detalle).toSet(), {
        'Fila 1 · Bingo de los sábados',
        'Fila 2 · Bingo de los sábados',
        'Fila 3 · Bingo de los sábados',
      });
    });

    test('sin saldo suficiente no reserva ni cobra nada', () async {
      final cartera = BilleteraMemoria(saldo: 12);
      final repo = RepositorioMemoria(
        cartillas: cartillasDemo,
        precioFila: 5,
        billetera: cartera,
      );
      await intentar(
        () =>
            repo.reservarFilas(codigo: 'K7Q4', filas: [1, 2, 3], nombre: 'Lu'),
      );
      expect(error?.codigo, 'saldo_insuficiente');
      expect(cartera.saldoActual, 12);
      expect((await repo.filas('K7Q4').first).every((f) => f.libre), isTrue);
      // Con dos filas sí alcanza.
      await repo.reservarFilas(codigo: 'K7Q4', filas: [1, 2], nombre: 'Lu');
      expect(cartera.saldoActual, 2);
    });

    test('una sala gratis no toca la billetera', () async {
      final cartera = BilleteraMemoria(saldo: 0);
      final repo = RepositorioMemoria(
        cartillas: cartillasDemo,
        billetera: cartera,
      );
      await repo.reservarFilas(codigo: 'K7Q4', filas: [1, 2], nombre: 'Lu');
      expect(cartera.saldoActual, 0);
    });

    test('al cerrar la sala se devuelve todo, una sola vez', () async {
      final cartera = BilleteraMemoria();
      final repo = RepositorioMemoria(
        cartillas: cartillasDemo,
        precioFila: 5,
        billetera: cartera,
      );
      await repo.reservarFilas(codigo: 'K7Q4', filas: [1, 2, 3], nombre: 'Lu');
      await repo.cancelarSala('K7Q4');
      expect(cartera.saldoActual, 25);
      await repo.cancelarSala('K7Q4');
      expect(cartera.saldoActual, 25);
      final tipos = (await cartera.movimientos().first).map((m) => m.tipo);
      expect(tipos.where((t) => t == TipoMovimiento.devolucion), hasLength(3));
    });
  });

  group('BilleteraMemoria', () {
    test('empieza con los créditos de prueba y recarga', () async {
      final cartera = BilleteraMemoria();
      expect(await cartera.saldo().first, creditosIniciales);
      await cartera.recargar(20);
      expect(cartera.saldoActual, 45);
      final primero = (await cartera.movimientos().first).first;
      expect(primero.tipo, TipoMovimiento.recarga);
      expect(primero.monto, 20);
    });

    test('el saldo avisa de cada cambio', () async {
      final cartera = BilleteraMemoria();
      final vistos = <int?>[];
      final sub = cartera.saldo().listen(vistos.add);
      await Future<void>.delayed(Duration.zero);
      await cartera.recargar(10);
      await Future<void>.delayed(Duration.zero);
      expect(vistos, [25, 35]);
      await sub.cancel();
    });
  });
}
