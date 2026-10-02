import 'package:bing_host/src/demo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cada pantalla del diseño de Host tiene su versión demo', () {
    for (final id in [
      'org-01-entrar',
      'org-02-mis-partidas',
      'org-03-nueva-partida',
      'org-04-sala-abierta',
      'org-05-cartilla-llena',
      'org-06-bolilla',
      'org-07-cartilla',
      'org-08-tablero',
      'org-09-ganador',
    ]) {
      expect(pantallaDemo(id), isNotNull, reason: id);
    }
    expect(pantallaDemo('no-existe'), isNull);
  });

  test('el sorteo demo sigue el orden fijo y se agota', () {
    expect(sorteoDemo(const []), 36);
    expect(sorteoDemo([36, 40]), 57);
    expect(sorteoDemo(List.filled(32, 1)), isNull);
  });
}
