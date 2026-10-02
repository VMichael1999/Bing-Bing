import 'package:flutter/painting.dart';

/// Colores de una app (Host usa [oscuro], Play usa [claro]).
class BingPaleta {
  const BingPaleta({
    required this.fondo,
    required this.tarjeta,
    required this.tinta,
    required this.apagado,
    required this.linea,
    required this.suave,
    required this.dauber,
    required this.dauberTinta,
    required this.cerca,
    required this.cercaSuave,
    required this.victoria,
    required this.victoriaSuave,
    required this.ok,
    required this.okSuave,
  });

  final Color fondo;
  final Color tarjeta;
  final Color tinta;
  final Color apagado;
  final Color linea;
  final Color suave;
  final Color dauber;
  final Color dauberTinta;
  final Color cerca;
  final Color cercaSuave;
  final Color victoria;
  final Color victoriaSuave;
  final Color ok;
  final Color okSuave;

  /// Play (`.app`).
  static const claro = BingPaleta(
    fondo: Color(0xFFEDF0F6),
    tarjeta: Color(0xFFFFFFFF),
    tinta: Color(0xFF181C33),
    apagado: Color(0xFF59607A),
    linea: Color(0xFFDCE1EC),
    suave: Color(0xFFF3F5FA),
    dauber: Color(0xFFC81B60),
    dauberTinta: Color(0xFFFFFFFF),
    cerca: Color(0xFF8A5A00),
    cercaSuave: Color(0xFFFFF1CC),
    victoria: Color(0xFFB07E00),
    victoriaSuave: Color(0xFFFFE9A8),
    ok: Color(0xFF13895A),
    okSuave: Color(0xFFDDF2E8),
  );

  /// Host (`.app.dark`).
  static const oscuro = BingPaleta(
    fondo: Color(0xFF10132A),
    tarjeta: Color(0xFF1A1E3A),
    tinta: Color(0xFFEEF0F8),
    apagado: Color(0xFFA5ABC6),
    linea: Color(0xFF2C3256),
    suave: Color(0xFF232849),
    dauber: Color(0xFFFF4C8B),
    dauberTinta: Color(0xFF1A0812),
    cerca: Color(0xFFF5C04A),
    cercaSuave: Color(0xFF3A3115),
    victoria: Color(0xFFF5C04A),
    victoriaSuave: Color(0xFF4A3C10),
    ok: Color(0xFF3DCB8E),
    okSuave: Color(0xFF163626),
  );
}

/// Color de una columna de bolillas y el color del texto que va encima.
class BingBolillaColor {
  const BingBolillaColor(this.fondo, this.tinta);
  final Color fondo;
  final Color tinta;

  static const b = BingBolillaColor(Color(0xFF2B6BE0), Color(0xFFFFFFFF));
  static const i = BingBolillaColor(Color(0xFFD93A33), Color(0xFFFFFFFF));
  static const n = BingBolillaColor(Color(0xFFEEF0F6), Color(0xFF181C33));
  static const g = BingBolillaColor(Color(0xFF13895A), Color(0xFFFFFFFF));
  static const o = BingBolillaColor(Color(0xFFF2B400), Color(0xFF181C33));

  /// Sexta columna (solo con 90 bolillas, sale del prototipo).
  static const x = BingBolillaColor(Color(0xFF7B45D0), Color(0xFFFFFFFF));

  static const porColumna = [b, i, n, g, o, x];

  static BingBolillaColor deColumna(int columna) => porColumna[columna];
}

/// Cara de la bolilla.
const Color bingCaraBolilla = Color(0xFFFFFFFF);
const Color bingNumeroBolilla = Color(0xFF181C33);
const Color bingLetraBolilla = Color(0xFF59607A);
