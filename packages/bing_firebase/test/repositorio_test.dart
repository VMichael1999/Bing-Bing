import 'package:bing_core/bing_core.dart';
import 'package:bing_firebase/bing_firebase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('salaDesdeMapa lee el documento de la sala', () {
    final sala = salaDesdeMapa('K7Q4', {
      'nombre': 'Bingo de los sábados',
      'organizadorNombre': 'Carmen',
      'estado': 'en_juego',
      'columnas': 5,
      'filasTotal': 20,
      'bolillas': [9, 30, 12],
      'ganadores': [
        {'fila': 4, 'bolillaIndice': 3},
      ],
    });
    expect(sala.codigo, 'K7Q4');
    expect(sala.organizador, 'Carmen');
    expect(sala.estado, EstadoSala.enJuego);
    expect(sala.bolillas, [9, 30, 12]);
    expect(sala.ganoLaFila(4), isTrue);
    expect(sala.ganoLaFila(5), isFalse);
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
