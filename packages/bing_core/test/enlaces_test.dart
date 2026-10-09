import 'package:bing_core/bing_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el enlace de la sala usa el dominio de Firebase Hosting', () {
    expect(enlaceSala('K7Q4'), 'https://bingbing-f1491.web.app/sala/K7Q4');
  });

  test('el texto para compartir lleva el nombre, el código y el enlace', () {
    final texto = textoCompartirSala(
      nombre: 'Bingo de los sábados',
      codigo: 'K7Q4',
    );
    expect(texto, contains('"Bingo de los sábados"'));
    expect(texto, contains('Código: K7Q4'));
    expect(texto, endsWith('https://bingbing-f1491.web.app/sala/K7Q4'));
  });

  group('codigoDeEnlace', () {
    test('acepta el código solo, en cualquier caja y con espacios', () {
      expect(codigoDeEnlace('K7Q4'), 'K7Q4');
      expect(codigoDeEnlace(' k7q4 '), 'K7Q4');
    });

    test('lee el enlace web y el de la app', () {
      expect(
        codigoDeEnlace('https://bingbing-f1491.web.app/sala/K7Q4'),
        'K7Q4',
      );
      expect(
        codigoDeEnlace('https://bingbing-f1491.web.app/sala/k7q4?x=1'),
        'K7Q4',
      );
      expect(codigoDeEnlace('bingbing://sala/K7Q4'), 'K7Q4');
    });

    test('lo que sale de enlaceSala vuelve a ser el mismo código', () {
      expect(codigoDeEnlace(enlaceSala('AB23')), 'AB23');
    });

    test('rechaza lo que no es una sala de Bing Bing', () {
      expect(codigoDeEnlace(''), isNull);
      expect(codigoDeEnlace('K7Q'), isNull);
      expect(codigoDeEnlace('K7Q41'), isNull);
      // 0, 1, O e I no existen en los códigos.
      expect(codigoDeEnlace('K0Q1'), isNull);
      expect(codigoDeEnlace('https://otro.com/sala/K7Q4'), isNull);
      expect(
        codigoDeEnlace('https://bingbing-f1491.web.app/otra/K7Q4'),
        isNull,
      );
      expect(codigoDeEnlace('https://bingbing-f1491.web.app/sala/'), isNull);
      expect(codigoDeEnlace('hola mundo'), isNull);
    });
  });
}
