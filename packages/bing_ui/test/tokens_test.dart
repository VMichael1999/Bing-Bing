import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la paleta oscura y la clara usan los valores del diseño', () {
    expect(BingPaleta.claro.dauber, const Color(0xFFC81B60));
    expect(BingPaleta.oscuro.dauber, const Color(0xFFFF4C8B));
    expect(BingPaleta.claro.fondo, const Color(0xFFEDF0F6));
    expect(BingPaleta.oscuro.fondo, const Color(0xFF10132A));
  });

  test('cada columna tiene su color y la sexta es la morada', () {
    expect(BingBolillaColor.deColumna(0), BingBolillaColor.b);
    expect(BingBolillaColor.deColumna(5).fondo, const Color(0xFF7B45D0));
    expect(BingBolillaColor.n.tinta, const Color(0xFF181C33));
  });

  test('los estilos usan la familia y el peso del diseño', () {
    expect(BingTexto.boton.fontSize, 15.5);
    expect(BingTexto.boton.fontWeight, FontWeight.w800);
    expect(BingTexto.codigoSala.fontFamily, endsWith('Bungee'));
    expect(BingTexto.codigoSala.letterSpacing, closeTo(2.88, 1e-9));
    expect(BingTexto.celda.fontFeatures, isNotNull);
  });

  testWidgets('BingTema entrega la paleta', (tester) async {
    late BingPaleta leida;
    await tester.pumpWidget(
      BingTema(
        paleta: BingPaleta.oscuro,
        child: Builder(
          builder: (context) {
            leida = BingTema.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(leida, BingPaleta.oscuro);
  });
}
