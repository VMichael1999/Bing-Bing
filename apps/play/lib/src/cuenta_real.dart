import 'dart:async';

import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

import 'paginas/cuenta_page.dart';
import 'paginas/iniciar_sesion_hoja.dart';

/// Pone la sesión del jugador al alcance de todas las pantallas.
class AlcanceSesion extends InheritedWidget {
  const AlcanceSesion({super.key, required this.sesion, required super.child});

  /// `null` en la demostración: no hay cuentas.
  final SesionJugador? sesion;

  static SesionJugador? de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AlcanceSesion>()?.sesion;

  @override
  bool updateShouldNotify(AlcanceSesion anterior) => sesion != anterior.sesion;
}

Route<T> _rutaSobrePantalla<T>(Widget pantalla) => PageRouteBuilder<T>(
  opaque: false,
  pageBuilder: (_, __, ___) => pantalla,
  transitionsBuilder:
      (_, animacion, __, hijo) =>
          FadeTransition(opacity: animacion, child: hijo),
);

/// Sube la hoja "Inicia sesión para jugar". Devuelve `true` si al cerrarse la
/// persona ya tiene cuenta.
Future<bool> mostrarHojaSesion(
  BuildContext context,
  SesionJugador sesion,
) async {
  final entro = await Navigator.of(
    context,
  ).push<bool>(_rutaSobrePantalla(_HojaSesionReal(sesion: sesion)));
  return entro ?? false;
}

class _HojaSesionReal extends StatefulWidget {
  const _HojaSesionReal({required this.sesion});

  final SesionJugador sesion;

  @override
  State<_HojaSesionReal> createState() => _HojaSesionRealState();
}

class _HojaSesionRealState extends State<_HojaSesionReal> {
  String? _error;
  bool _entrando = false;

  Future<void> _conGoogle() async {
    if (_entrando) return;
    setState(() {
      _entrando = true;
      _error = null;
    });
    try {
      final usuario = await widget.sesion.entrarConGoogle();
      if (!mounted) return;
      if (usuario == null) {
        // La persona cerró la ventana de Google: sigue donde estaba.
        setState(() => _entrando = false);
        return;
      }
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _entrando = false;
        _error = 'No pudimos iniciar sesión con Google. Inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IniciarSesionHoja(
      fondo: const SizedBox.shrink(),
      celularDisponible: false,
      alGoogle: _entrando ? null : _conGoogle,
      alAhoraNo: () => Navigator.of(context).pop(false),
      error: _error,
    );
  }
}

/// Mi cuenta: quién eres, cerrar sesión y borrar la cuenta.
class CuentaReal extends StatefulWidget {
  const CuentaReal({super.key, required this.sesion});

  final SesionJugador sesion;

  @override
  State<CuentaReal> createState() => _CuentaRealState();
}

class _CuentaRealState extends State<CuentaReal> {
  bool _ocupado = false;

  Future<void> _cerrarSesion() async {
    setState(() => _ocupado = true);
    try {
      await widget.sesion.cerrarSesion();
      if (!mounted) return;
      Navigator.of(context).pop();
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
    ).push<bool>(_rutaSobrePantalla(const _ConfirmarEliminar()));
    if (confirmado != true || !mounted) return;
    setState(() => _ocupado = true);
    try {
      await widget.sesion.eliminarCuenta();
      if (!mounted) return;
      final navegador = Navigator.of(context);
      navegador.pop();
      // El aviso se muestra sobre la pantalla a la que se vuelve.
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        final contexto = navegador.context;
        if (contexto.mounted) {
          mostrarAvisoBing(contexto, 'Tu cuenta se eliminó');
        }
      });
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
        return CuentaPage(
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

class _ConfirmarEliminar extends StatelessWidget {
  const _ConfirmarEliminar();

  @override
  Widget build(BuildContext context) {
    return BingHoja(
      fondo: const SizedBox.shrink(),
      alIzquierda: true,
      titulo: '¿Eliminar tu cuenta?',
      texto:
          'Se borran tu cuenta y tus datos. Esto no se puede deshacer. Las '
          'filas que ya reservaste dejarán de estar a tu nombre.',
      children: [
        Column(
          children: [
            BingBoton(
              texto: 'Sí, eliminar mi cuenta',
              tipo: BingBotonTipo.dauber,
              alPresionar: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 8),
            BingBoton(
              texto: 'Cancelar',
              tipo: BingBotonTipo.linea,
              alPresionar: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ],
    );
  }
}

/// Lo que se muestra arriba a la derecha del inicio: entrar o abrir la cuenta.
class AccesoCuenta extends StatelessWidget {
  const AccesoCuenta({
    super.key,
    required this.usuario,
    required this.alEntrar,
    required this.alAbrirCuenta,
  });

  final UsuarioBing? usuario;
  final VoidCallback alEntrar;
  final VoidCallback alAbrirCuenta;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    if (!usuario.tieneCuenta) {
      return Semantics(
        button: true,
        label: 'Iniciar sesión',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: alEntrar,
          child: const ExcludeSemantics(
            child: BingChip('Iniciar sesión', icono: 'user'),
          ),
        ),
      );
    }
    final nombre = usuario!.nombreVisible;
    final inicial = nombre.isEmpty ? '?' : nombre[0].toUpperCase();
    return Semantics(
      button: true,
      label: 'Mi cuenta',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: alAbrirCuenta,
        child: ExcludeSemantics(
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: paleta.dauber,
              shape: BoxShape.circle,
            ),
            child: Text(
              inicial,
              style: BingTexto.bungee(14).copyWith(color: paleta.dauberTinta),
            ),
          ),
        ),
      ),
    );
  }
}
