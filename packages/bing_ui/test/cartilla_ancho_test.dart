import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _cartilla(double ancho) => Directionality(
  textDirection: TextDirection.ltr,
  child: BingTema(
    paleta: BingPaleta.oscuro,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: ancho,
          child: BingCartilla(
            letras: const ['B', 'I', 'N', 'G', 'O'],
            filas: const [
              BingFilaCompacta(
                indice: 1,
                numeros: [6, 24, 39, 52, 72],
                salidas: {6},
                nombre: 'Rosa',
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);

double _anchoCelda(WidgetTester tester) =>
    tester.getSize(find.byType(BingCelda).first).width;

void main() {
  testWidgets('con el ancho del diseño (320 dp) las celdas miden 33', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_cartilla(292));
    expect(_anchoCelda(tester), 33);
  });

  testWidgets('en un teléfono ancho las celdas crecen y llenan el espacio', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(450, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_cartilla(420));
    final celda = _anchoCelda(tester);
    expect(celda, greaterThan(33));
    expect(celda, lessThanOrEqualTo(BingMedidas.filaCeldaMax));
    // El nombre sigue teniendo al menos tanto sitio como en el diseño.
    final nombre = tester.getSize(find.text('Rosa'));
    expect(nombre.width, greaterThan(0));
  });

  testWidgets('en una tablet las celdas no pasan del tope', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_cartilla(860));
    expect(_anchoCelda(tester), BingMedidas.filaCeldaMax);
  });

  testWidgets('la cabecera de columnas se alinea con las celdas', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(450, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_cartilla(420));
    final punto = tester.getCenter(find.text('B'));
    final celda = tester.getCenter(find.byType(BingCelda).first);
    expect((punto.dx - celda.dx).abs(), lessThan(1));
  });

  test('paraContenido no encoge por debajo del diseño', () {
    expect(BingAnchoCelda.paraContenido(200), 33);
    expect(BingAnchoCelda.paraContenido(BingMedidas.filaContenidoDiseno), 33);
  });
}
