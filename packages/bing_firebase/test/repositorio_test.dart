import 'package:bing_core/bing_core.dart';
import 'package:bing_firebase/bing_firebase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  pruebasOrganizador();
  test('salaDesdeMapa lee el documento de la sala', () {
    final sala = salaDesdeMapa('K7Q4', {
      'nombre': 'Bingo de los sábados',
      'organizadorNombre': 'Carmen',
      'estado': 'en_juego',
      'columnas': 5,
      'filasTotal': 20,
      'bolillas': [9, 30, 12],
      'ganadores': [
        {'fila': 5, 'bolillaIndice': 3},
      ],
    });
    expect(sala.codigo, 'K7Q4');
    expect(sala.organizador, 'Carmen');
    expect(sala.estado, EstadoSala.enJuego);
    expect(sala.bolillas, [9, 30, 12]);
    // El servidor guarda la fila 5 (base 1): es la posición 4 de la lista.
    expect(sala.ganoLaFila(4), isTrue);
    expect(sala.ganoLaFila(5), isFalse);
    expect(sala.ganadoras.single.fila, 5);
  });

  test('salaDesdeMapa lee las filas por jugador, 20 si no hay', () {
    expect(salaDesdeMapa('K7Q4', {'filasPorJugador': 3}).filasPorJugador, 3);
    expect(salaDesdeMapa('K7Q4', {}).filasPorJugador, 20);
  });

  test('salaDesdeMapa lee el precio y el premio, o 0 si no hay', () {
    final sala = salaDesdeMapa('K7Q4', {'precioFila': 5, 'premio': 80});
    expect(sala.precioFila, 5);
    expect(sala.premio, 80);
    final vieja = salaDesdeMapa('K7Q4', {'nombre': 'X'});
    expect(vieja.precioFila, 0);
    expect(vieja.premio, 0);
  });

  test('una sala cerrada trae el motivo con el que se cerró', () {
    final sala = salaDesdeMapa('K7Q4', {
      'nombre': 'Bingo',
      'estado': 'cancelada',
      'motivoCierre': 'No se llenó',
    });
    expect(sala.estado, EstadoSala.cancelada);
    expect(sala.motivoCierre, 'No se llenó');
    expect(salaDesdeMapa('K7Q4', {'estado': 'cancelada'}).motivoCierre, isNull);
  });

  test('una sala sin datos opcionales usa valores por defecto', () {
    final sala = salaDesdeMapa('AAAA', {'nombre': 'X'});
    expect(sala.estado, EstadoSala.abierta);
    expect(sala.organizador, 'quien organiza');
    expect(sala.bolillas, isEmpty);
  });

  test('filasDesdeDocumentos ordena 1, 2, … 10 como números', () {
    final filas = filasDesdeDocumentos({
      '10': {
        'numeros': [1, 16, 31, 46, 61],
      },
      '2': {
        'numeros': [2, 17, 32, 47, 62],
        'nombre': 'Lucía',
        'jugadorUid': 'u1',
      },
      '1': {
        'numeros': [3, 18, 33, 48, 63],
      },
    });
    expect(filas.map((f) => f.numeros.first), [3, 2, 1]);
    expect(filas[1].libre, isFalse);
    expect(filas[1].nombre, 'Lucía');
    expect(filas[0].libre, isTrue);
  });

  test('errorDeFunciones usa el código del servidor o el de la excepción', () {
    expect(
      errorDeFunciones('failed-precondition', 'ocupada', {
        'codigo': 'fila_ocupada',
      }).codigo,
      'fila_ocupada',
    );
    expect(errorDeFunciones('not-found', null, null).codigo, 'no_existe');
    expect(errorDeFunciones('unavailable', null, null).codigo, 'unavailable');
  });
}

void pruebasOrganizador() {
  test('salaDesdeMapa lee quién organiza y cuándo se creó', () {
    final sala = salaDesdeMapa('K7Q4', {
      'nombre': 'X',
      'organizadorUid': 'carmen',
      'creadaEn': DateTime(2026, 10, 2, 21),
    });
    expect(sala.organizadorUid, 'carmen');
    expect(sala.creadaEn, DateTime(2026, 10, 2, 21));
  });

  test('ordenarSalas pone primero la más nueva y al final las sin fecha', () {
    SalaEnVivo sala(String c, DateTime? f) =>
        salaDesdeMapa(c, {'nombre': c, if (f != null) 'creadaEn': f});
    final orden = ordenarSalas([
      sala('SIN', null),
      sala('VIEJA', DateTime(2026, 9, 1)),
      sala('NUEVA', DateTime(2026, 10, 1)),
    ]);
    expect(orden.map((s) => s.codigo), ['NUEVA', 'VIEJA', 'SIN']);
  });

  test('filasDesdeDocumentos lee la hora de reserva', () {
    final filas = filasDesdeDocumentos({
      '1': {
        'numeros': [1, 16, 31, 46, 61],
        'jugadorUid': 'u',
        'nombre': 'Ana',
        'reservadaEn': DateTime(2026, 10, 2, 20, 44),
      },
    });
    expect(filas.single.reservadaEn, DateTime(2026, 10, 2, 20, 44));
  });
}
