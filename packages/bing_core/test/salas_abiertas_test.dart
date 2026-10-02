import 'package:bing_core/bing_core.dart';
import 'package:flutter_test/flutter_test.dart';

SalaEnVivo sala(
  String codigo, {
  int ocupadas = 0,
  EstadoSala estado = EstadoSala.abierta,
  DateTime? creadaEn,
}) => SalaEnVivo(
  codigo: codigo,
  nombre: 'Sala $codigo',
  organizador: 'Carmen',
  estado: estado,
  columnas: 5,
  filasTotal: 20,
  bolillas: const [],
  ganadoras: const [],
  ocupadas: ocupadas,
  creadaEn: creadaEn,
);

List<String> codigos(Iterable<SalaEnVivo> salas) => [
  for (final s in salas) s.codigo,
];

void main() {
  group('salasConSitio', () {
    test('pone primero las más llenas', () {
      final r = salasConSitio([
        sala('A', ocupadas: 4),
        sala('B', ocupadas: 19),
        sala('C', ocupadas: 11),
      ]);
      expect(codigos(r), ['B', 'C', 'A']);
    });

    test('quita las llenas y las que ya no están abiertas', () {
      final r = salasConSitio([
        sala('A', ocupadas: 20, estado: EstadoSala.llena),
        sala('B', ocupadas: 20),
        sala('C', ocupadas: 3, estado: EstadoSala.enJuego),
        sala('D', ocupadas: 3),
      ]);
      expect(codigos(r), ['D']);
    });

    test('a igual llenado, la más antigua primero y sin fecha al final', () {
      final r = salasConSitio([
        sala('A', ocupadas: 5),
        sala('B', ocupadas: 5, creadaEn: DateTime(2026, 1, 2)),
        sala('C', ocupadas: 5, creadaEn: DateTime(2026, 1, 1)),
      ]);
      expect(codigos(r), ['C', 'B', 'A']);
    });

    test('muestra como mucho el tope', () {
      final r = salasConSitio([
        for (var i = 0; i < 15; i++) sala('S$i', ocupadas: i),
      ]);
      expect(r, hasLength(topeSalasAbiertas));
      expect(r.first.codigo, 'S14');
    });
  });
}
