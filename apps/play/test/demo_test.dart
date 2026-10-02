import 'package:bing_play/src/demo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cada pantalla del diseño de Play tiene su versión demo', () {
    for (final id in [
      'jug-01-codigo',
      'jug-02-elegir-fila',
      'jug-03-reservar',
      'jug-04-esperando',
      'jug-05-en-vivo',
      'jug-06-ganaste',
    ]) {
      expect(pantallaDemo(id), isNotNull, reason: id);
    }
    expect(pantallaDemo('no-existe'), isNull);
    expect(pantallaDemo(''), isNull);
  });
}
