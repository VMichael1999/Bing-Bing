import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Tamaños de ícono (`.ic`, `.ic.s`, `.ic.xs`, `.ic.l`).
enum BingIconoTamano {
  normal(20),
  s(16),
  xs(13),
  l(24);

  const BingIconoTamano(this.lado);
  final double lado;
}

/// Ícono del diseño (SVG de trazo 1.9, puntas y uniones redondeadas).
///
/// [nombre] es el del archivo en `assets/icons` (`check`, `qr`, `lock`, …).
class BingIcono extends StatelessWidget {
  const BingIcono(
    this.nombre, {
    super.key,
    required this.color,
    this.tamano = BingIconoTamano.normal,
  });

  final String nombre;
  final Color color;
  final BingIconoTamano tamano;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/$nombre.svg',
      package: 'bing_ui',
      width: tamano.lado,
      height: tamano.lado,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
