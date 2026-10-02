import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

SystemUiOverlayStyle? _estilo(WidgetTester tester) =>
    tester
        .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        )
        .value;

void main() {
  testWidgets('en el tema claro los íconos del sistema son oscuros', (
    tester,
  ) async {
    await tester.pumpWidget(
      const BingTema(
        paleta: BingPaleta.claro,
        child: BingSistema(child: SizedBox()),
      ),
    );
    expect(_estilo(tester)!.statusBarIconBrightness, Brightness.dark);
    expect(_estilo(tester)!.systemNavigationBarIconBrightness, Brightness.dark);
  });

  testWidgets('en el tema oscuro los íconos del sistema son claros', (
    tester,
  ) async {
    await tester.pumpWidget(
      const BingTema(
        paleta: BingPaleta.oscuro,
        child: BingSistema(child: SizedBox()),
      ),
    );
    expect(_estilo(tester)!.statusBarIconBrightness, Brightness.light);
  });
}
