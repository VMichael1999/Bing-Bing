import 'dart:io';

import 'package:flutter/services.dart';

/// Carga Bungee y Figtree para que las pruebas midan el texto como la app.
Future<void> cargarFuentesBing() async {
  for (final (familia, ruta) in [
    ('Bungee', '../../packages/bing_ui/assets/fonts/Bungee-Regular.ttf'),
    ('Figtree', '../../packages/bing_ui/assets/fonts/Figtree-Variable.ttf'),
  ]) {
    final cargador = FontLoader('packages/bing_ui/$familia')..addFont(
      Future.value(ByteData.sublistView(File(ruta).readAsBytesSync())),
    );
    await cargador.load();
  }
}
