import 'dart:io';

import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

Widget _tema(Widget hijo) => Directionality(
  textDirection: TextDirection.ltr,
  child: BingTema(
    paleta: BingPaleta.oscuro,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 292, child: hijo),
      ),
    ),
  ),
);

/// Píxeles que dibuja [w]: el mismo QR da la misma imagen y otro dato, otra.
Future<List<int>> _pixeles(WidgetTester tester, Widget w) async {
  final llave = GlobalKey();
  await tester.pumpWidget(_tema(RepaintBoundary(key: llave, child: w)));
  return (await tester.runAsync(() async {
    final limite =
        llave.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final imagen = await limite.toImage();
    final datos = await imagen.toByteData();
    return datos!.buffer.asUint8List().toList();
  }))!;
}

Future<void> _cargarFuente(String familia, String ruta) async {
  final cargador = FontLoader('packages/bing_ui/$familia')
    ..addFont(Future.value(ByteData.sublistView(File(ruta).readAsBytesSync())));
  await cargador.load();
}

void main() {
  setUpAll(() async {
    await _cargarFuente('Bungee', 'assets/fonts/Bungee-Regular.ttf');
    await _cargarFuente('Figtree', 'assets/fonts/Figtree-Variable.ttf');
  });

  testWidgets('la tarjeta muestra el QR del enlace, el código y la leyenda', (
    tester,
  ) async {
    await tester.pumpWidget(
      _tema(
        const BingTarjetaQr(
          datos: 'https://bingbing-f1491.web.app/sala/K7Q4',
          codigo: 'K7Q4',
          leyenda: 'Escanéalo con Bing Bing Play',
        ),
      ),
    );
    expect(find.text('K7Q4'), findsOneWidget);
    expect(find.text('Escanéalo con Bing Bing Play'), findsOneWidget);
    expect(tester.getSize(find.byType(QrImageView)), const Size(196, 196));
  });

  testWidgets('la versión grande ocupa todo el ancho disponible', (
    tester,
  ) async {
    await tester.pumpWidget(
      _tema(const BingTarjetaQr(datos: 'x', codigo: 'K7Q4', grande: true)),
    );
    final qr = tester.getSize(find.byType(QrImageView));
    expect(qr.width, qr.height);
    // 292 de ancho menos el relleno de 18 a cada lado.
    expect(qr.width, 256);
  });

  testWidgets('BingCodigoSala codifica el enlace cuando se le da', (
    tester,
  ) async {
    const enlace = 'https://x/sala/K7Q4';
    final conEnlace = await _pixeles(
      tester,
      const BingCodigoSala(codigo: 'K7Q4', datosQr: enlace),
    );
    final porDefecto = await _pixeles(
      tester,
      const BingCodigoSala(codigo: 'K7Q4'),
    );
    final soloCodigo = await _pixeles(
      tester,
      const BingCodigoSala(codigo: 'K7Q4', datosQr: 'K7Q4'),
    );
    expect(porDefecto, soloCodigo);
    expect(conEnlace, isNot(porDefecto));
  });

  testWidgets('el pie admite un segundo botón', (tester) async {
    await tester.pumpWidget(
      _tema(
        const BingPie(
          boton: Text('Compartir'),
          botonSecundario: Text('Mostrar QR'),
        ),
      ),
    );
    expect(find.text('Compartir'), findsOneWidget);
    expect(find.text('Mostrar QR'), findsOneWidget);
  });
}
