import 'package:bing_core/bing_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('con 5 créditos por fila y 20 filas el cálculo es el del prototipo', () {
    expect(recaudado(5, 20), 100);
    expect(comisionDe(100), 10);
    expect(disponibleParaPremio(5, 20), 90);
    expect(premioSugerido(5, 20), 80);
  });

  test('la comisión se redondea hacia arriba', () {
    expect(comisionDe(35), 4);
    expect(comisionDe(0), 0);
    expect(disponibleParaPremio(1, 20), 18);
  });

  test('el premio sugerido nunca pasa de lo disponible', () {
    for (var precio = 0; precio <= 100; precio++) {
      expect(
        premioSugerido(precio, 20),
        lessThanOrEqualTo(disponibleParaPremio(precio, 20)),
        reason: 'precio $precio',
      );
    }
  });

  test('sin precio no hay premio', () {
    expect(premioSugerido(0, 20), 0);
  });

  test('usa otra comisión si se le pide', () {
    expect(disponibleParaPremio(5, 20, porcentaje: 20), 80);
  });
}
