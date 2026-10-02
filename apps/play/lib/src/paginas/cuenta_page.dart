import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

/// `jug-13-cuenta`: la pantalla de cuenta compartida, con el título de Play.
class CuentaPage extends StatelessWidget {
  const CuentaPage({
    super.key,
    required this.nombre,
    required this.correo,
    this.googleVinculado = true,
    this.alVolver,
    this.alCerrarSesion,
    this.alEliminar,
    this.ocupado = false,
    this.saldo,
    this.alBilletera,
  });

  final String nombre;
  final String correo;
  final bool googleVinculado;
  final VoidCallback? alVolver;
  final VoidCallback? alCerrarSesion;
  final VoidCallback? alEliminar;
  final bool ocupado;
  final int? saldo;
  final VoidCallback? alBilletera;

  @override
  Widget build(BuildContext context) => BingCuenta(
    nombre: nombre,
    correo: correo,
    googleVinculado: googleVinculado,
    alVolver: alVolver,
    alCerrarSesion: alCerrarSesion,
    alEliminar: alEliminar,
    ocupado: ocupado,
    saldo: saldo,
    alBilletera: alBilletera,
  );
}
