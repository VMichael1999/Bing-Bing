import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'tema.dart';

/// Ajusta la barra de estado y la de navegación del sistema al tema: íconos
/// oscuros sobre fondo claro (Play) y claros sobre fondo oscuro (Host).
class BingSistema extends StatelessWidget {
  const BingSistema({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fondo = BingTema.of(context).fondo;
    final iconos =
        fondo.computeLuminance() > 0.5 ? Brightness.dark : Brightness.light;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: const Color(0x00000000),
        statusBarIconBrightness: iconos,
        statusBarBrightness:
            iconos == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: const Color(0x00000000),
        systemNavigationBarIconBrightness: iconos,
        systemNavigationBarDividerColor: const Color(0x00000000),
        systemNavigationBarContrastEnforced: false,
      ),
      child: child,
    );
  }
}
