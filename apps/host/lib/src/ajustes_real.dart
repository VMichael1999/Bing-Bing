import 'dart:async';

import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

Route<T> _rutaSobrePantalla<T>(Widget pantalla) => PageRouteBuilder<T>(
  opaque: false,
  pageBuilder: (_, __, ___) => pantalla,
  transitionsBuilder:
      (_, animacion, __, hijo) =>
          FadeTransition(opacity: animacion, child: hijo),
);

/// Ajustes de quien organiza: su cuenta, cerrar sesión y borrarla.
///
/// Al cerrar sesión o borrar la cuenta se llama a [alSalir] para volver a la
/// pantalla de entrar.
class AjustesReal extends StatefulWidget {
  const AjustesReal({super.key, required this.sesion, required this.alSalir});

  final SesionJugador sesion;
  final VoidCallback alSalir;

  @override
  State<AjustesReal> createState() => _AjustesRealState();
}

class _AjustesRealState extends State<AjustesReal> {
  bool _ocupado = false;

  Future<void> _cerrarSesion() async {
    setState(() => _ocupado = true);
    try {
      await widget.sesion.cerrarSesion();
      if (!mounted) return;
      widget.alSalir();
    } catch (_) {
      if (!mounted) return;
      setState(() => _ocupado = false);
      mostrarAvisoBing(
        context,
        'No pudimos cerrar la sesión. Inténtalo otra vez.',
      );
    }
  }

  Future<void> _eliminar() async {
    final confirmado = await Navigator.of(
      context,
    ).push<bool>(_rutaSobrePantalla(const _HojaEliminar()));
    if (confirmado != true || !mounted) return;
    setState(() => _ocupado = true);
    try {
      await widget.sesion.eliminarCuenta();
      if (!mounted) return;
      final navegador = Navigator.of(context);
      widget.alSalir();
      // El aviso se muestra sobre la pantalla a la que se vuelve.
      final overlay = navegador.overlay;
      if (overlay != null) mostrarAvisoBingEn(overlay, 'Tu cuenta se eliminó');
    } catch (_) {
      if (!mounted) return;
      setState(() => _ocupado = false);
      mostrarAvisoBing(
        context,
        'No pudimos eliminar la cuenta. Inténtalo otra vez.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UsuarioBing?>(
      stream: widget.sesion.cambios,
      initialData: widget.sesion.actual,
      builder: (context, foto) {
        final usuario = foto.data;
        return BingCuenta(
          titulo: 'Ajustes',
          nombre: usuario?.nombreVisible ?? '',
          correo: usuario?.correo ?? '',
          ocupado: _ocupado,
          alVolver: () => Navigator.of(context).pop(),
          alCerrarSesion: _cerrarSesion,
          alEliminar: _eliminar,
        );
      },
    );
  }
}

class _HojaEliminar extends StatelessWidget {
  const _HojaEliminar();

  @override
  Widget build(BuildContext context) => BingConfirmarEliminar(
    alConfirmar: () => Navigator.of(context).pop(true),
    alCancelar: () => Navigator.of(context).pop(false),
  );
}
