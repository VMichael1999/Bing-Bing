import 'package:flutter/widgets.dart';

import 'colores.dart';

/// Entrega la [BingPaleta] de la app a todo el árbol.
class BingTema extends InheritedWidget {
  const BingTema({super.key, required this.paleta, required super.child});

  final BingPaleta paleta;

  static BingPaleta of(BuildContext context) {
    final tema = context.dependOnInheritedWidgetOfExactType<BingTema>();
    assert(tema != null, 'Falta un BingTema sobre este widget');
    return tema!.paleta;
  }

  @override
  bool updateShouldNotify(BingTema old) => paleta != old.paleta;
}
