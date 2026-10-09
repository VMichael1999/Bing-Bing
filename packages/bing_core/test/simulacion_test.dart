import 'package:bing_core/bing_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'los jugadores van entrando en orden y la última fila llena la sala',
    () {
      final sala = SalaSimulada();
      expect(sala.ocupadas, 0);
      for (var i = 0; i < 19; i++) {
        expect(sala.llegaSiguiente(), i);
      }
      expect(sala.estado, EstadoSalaSim.abierta);
      expect(sala.faltan, 1);
      expect(sala.llegaSiguiente(), 19);
      expect(sala.estado, EstadoSalaSim.llena);
      expect(sala.llegaSiguiente(), isNull);
      expect(sala.duenos[4], 'Lucía');
    },
  );

  test('las 5 primeras horas son las del diseño y luego avanzan', () {
    final sala = SalaSimulada(ocupadasIniciales: 7);
    expect(sala.horas.take(5), horasReservaDemo);
    expect(sala.horas[5], '20:44');
    expect(sala.horas[6], '20:45');
  });

  test('reservar una fila libre funciona y una ocupada se rechaza', () {
    final sala = SalaSimulada(ocupadasIniciales: 4);
    expect(sala.reservar(4, 'Lucía'), isTrue);
    expect(sala.misFilas, {4});
    expect(sala.reservar(4, 'Otra'), isFalse);
    expect(sala.reservar(0, 'Otra'), isFalse);
    expect(sala.duenos[4], 'Lucía');
  });

  test(
    'no se puede empezar hasta que se llene, y entonces no entra nadie más',
    () {
      final sala = SalaSimulada(ocupadasIniciales: 19);
      expect(sala.empezar(), isFalse);
      sala.llegaSiguiente();
      expect(sala.empezar(), isTrue);
      expect(sala.estado, EstadoSalaSim.enJuego);
      expect(sala.reservar(0, 'x'), isFalse);
    },
  );

  test('con la bolilla 32 gana Lucía, la fila 5 (índice 4)', () {
    final sala = SalaSimulada(ocupadasIniciales: 20)..empezar();
    List<int>? ganadoras;
    for (var i = 0; i < 32; i++) {
      ganadoras = sala.sacar();
    }
    expect(sala.bolillas.last, 12);
    expect(ganadoras, [4]);
    expect(sala.sacar(), isNull); // la partida del diseño termina en la 32
  });

  test(
    'antes de empezar no sale ninguna bolilla y deshacer quita la última',
    () {
      final sala = SalaSimulada(ocupadasIniciales: 20);
      expect(sala.sacar(), isNull);
      sala.empezar();
      sala.sacar();
      sala.sacar();
      sala.deshacer();
      expect(sala.bolillas, [36]);
    },
  );

  test('avisa a quien escucha en cada cambio', () {
    final sala = SalaSimulada();
    var avisos = 0;
    sala.addListener(() => avisos++);
    sala.llegaSiguiente();
    sala.reservar(5, 'Yo');
    expect(avisos, 2);
  });
}
