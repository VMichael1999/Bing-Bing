import 'dart:io';

import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _cargarFuente(String familia, String ruta) async {
  final cargador = FontLoader('packages/bing_ui/$familia')
    ..addFont(Future.value(ByteData.sublistView(File(ruta).readAsBytesSync())));
  await cargador.load();
}

void main() {
  setUpAll(() async {
    await _cargarFuente('Figtree', 'assets/fonts/Figtree-Variable.ttf');
  });

  testWidgets('el aviso aparece y desaparece solo', (tester) async {
    await tester.pumpWidget(
      BingTema(
        paleta: BingPaleta.claro,
        child: WidgetsApp(
          color: const Color(0xFFFFFFFF),
          pageRouteBuilder:
              <T>(settings, builder) => PageRouteBuilder<T>(
                settings: settings,
                pageBuilder: (c, _, __) => builder(c),
              ),
          home: Builder(
            builder:
                (context) => GestureDetector(
                  onTap: () => mostrarAvisoBing(context, 'Enlace copiado'),
                  child: const Center(child: Text('Tocar')),
                ),
          ),
        ),
      ),
    );
    expect(find.text('Enlace copiado'), findsNothing);
    await tester.tap(find.text('Tocar'));
    await tester.pump();
    expect(find.text('Enlace copiado'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1700));
    expect(find.text('Enlace copiado'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Enlace copiado'), findsNothing);
  });

  testWidgets('sin Overlay no hace nada ni falla', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            mostrarAvisoBing(context, 'x');
            return const SizedBox();
          },
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
