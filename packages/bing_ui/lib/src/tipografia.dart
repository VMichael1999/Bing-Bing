import 'package:flutter/painting.dart';

/// Estilos de texto del diseño. El color lo pone quien los usa.
abstract final class BingTexto {
  static const _cifras = [FontFeature.tabularFigures()];

  static TextStyle figtree(
    double tamano,
    int peso, {
    double? altura,
    double? espaciado,
    bool tabular = false,
  }) => TextStyle(
    fontFamily: 'Figtree',
    package: 'bing_ui',
    fontSize: tamano,
    fontWeight: FontWeight.values[(peso ~/ 100) - 1],
    fontVariations: [FontVariation('wght', peso.toDouble())],
    height: altura,
    letterSpacing: espaciado,
    fontFeatures: tabular ? _cifras : null,
  );

  static TextStyle bungee(
    double tamano, {
    double? altura,
    double? espaciado,
    bool tabular = false,
  }) => TextStyle(
    fontFamily: 'Bungee',
    package: 'bing_ui',
    fontSize: tamano,
    fontWeight: FontWeight.w400,
    height: altura,
    letterSpacing: espaciado,
    fontFeatures: tabular ? _cifras : null,
  );

  static final tituloPantalla = figtree(17, 800); // .top h2
  static final subtitulo = figtree(12, 600); // .top small
  static final cabeceraSeccion = figtree(12.5, 800, espaciado: 12.5 * 0.03);
  static final boton = figtree(15.5, 800);
  static final chip = figtree(12, 800);
  static final celda = figtree(13.5, 800, tabular: true);
  static final celdaGrande = figtree(22, 800, tabular: true);
  static final nombreFila = figtree(12.5, 800);
  static final avanceFila = figtree(11, 700);
  static final marca = bungee(42, altura: 1);
  static final codigoSala = bungee(36, altura: 1, espaciado: 36 * 0.08);
  static final casillaCodigo = bungee(28);
  static final contadorProgreso = bungee(20);
  static final tituloHoja = bungee(34, altura: 1.05);
  static final bingo = bungee(52, altura: 1);
  static final numeroBolillaXl = bungee(52, tabular: true);
}
