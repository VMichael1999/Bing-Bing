import 'package:bing_core/bing_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RepositorioMemoria nueva() => RepositorioMemoria(cartillas: cartillasDemo);

  test('buscar solo encuentra el código de la sala', () async {
    final repo = nueva();
    expect((await repo.buscar('K7Q4'))?.nombre, 'Bingo de los sábados');
    expect(await repo.buscar('ZZZZ'), isNull);
  });

  test('reservar toma la fila y el servidor rechaza repetirla', () async {
    final repo = nueva()..ocupar(1, 'Ana', 'otra');
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
    repo.empezar();
    bolillasDemo.forEach(repo.sacar);
    final sala = (await repo.sala('K7Q4').first)!;
    expect(sala.estado, EstadoSala.enJuego);
    expect(sala.ganoLaFila(4), isTrue);
    expect(sala.ganadoras.single.bolillaIndice, 32);
  });

  test('sala emite la foto actual y luego cada cambio', () async {
    final repo = nueva();
    final estados = <EstadoSala>[];
    final suscripcion = repo.sala('K7Q4').listen((s) => estados.add(s!.estado));
    await Future<void>.delayed(Duration.zero);
    repo.empezar();
    await Future<void>.delayed(Duration.zero);
    await suscripcion.cancel();
    expect(estados, [EstadoSala.abierta, EstadoSala.enJuego]);
  });
}
