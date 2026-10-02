import 'dart:async';

import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

import 'paginas/billetera_page.dart';
import 'paginas/cuenta_page.dart';
import 'paginas/iniciar_sesion_hoja.dart';

/// Pone la sesión y la billetera del jugador al alcance de todas las pantallas.
///
/// El saldo se escucha mientras haya una cuenta con sesión: sin ella (invitado)
/// no hay billetera y el saldo es `null`.
class AlcanceSesion extends StatefulWidget {
  const AlcanceSesion({
    super.key,
    required this.sesion,
    this.billetera,
    required this.child,
  });

  /// `null` en la demostración: no hay cuentas.
  final SesionJugador? sesion;

  /// `null` en la demostración: no hay billetera.
  final RepositorioBilletera? billetera;
  final Widget child;

  static SesionJugador? de(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_Alcance>()?.sesion;

  static RepositorioBilletera? billeteraDe(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_Alcance>()?.billetera;

  /// Los créditos de prueba de la cuenta; la pantalla se reconstruye al cambiar.
  static int? saldoDe(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Alcance>()?.saldo;

  @override
  State<AlcanceSesion> createState() => _AlcanceSesionState();
}

class _AlcanceSesionState extends State<AlcanceSesion> {
  StreamSubscription<UsuarioBing?>? _usuarioSub;
  StreamSubscription<int?>? _saldoSub;
  String? _uid;
  int? _saldo;

  @override
  void initState() {
    super.initState();
    _usuarioSub = widget.sesion?.cambios.listen(_alCambiarUsuario);
  }

  void _alCambiarUsuario(UsuarioBing? usuario) {
    final uid = usuario.tieneCuenta ? usuario!.uid : null;
    if (uid == _uid) return;
    _uid = uid;
    _saldoSub?.cancel();
    _saldoSub = null;
    final billetera = widget.billetera;
    if (uid == null || billetera == null) {
      if (_saldo != null && mounted) setState(() => _saldo = null);
      return;
    }
    _saldoSub = billetera.saldo().listen(
      (s) {
        if (mounted) setState(() => _saldo = s);
      },
      onError: (_) {
        if (mounted) setState(() => _saldo = null);
      },
    );
  }

  @override
  void dispose() {
    _usuarioSub?.cancel();
    _saldoSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Alcance(
    sesion: widget.sesion,
    billetera: widget.billetera,
    saldo: _saldo,
    child: widget.child,
  );
}

class _Alcance extends InheritedWidget {
  const _Alcance({
    required this.sesion,
    required this.billetera,
    required this.saldo,
    required super.child,
  });

  final SesionJugador? sesion;
  final RepositorioBilletera? billetera;
  final int? saldo;

  @override
  bool updateShouldNotify(_Alcance anterior) => saldo != anterior.saldo;
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

class _HojaEliminar extends StatelessWidget {
  const _HojaEliminar();

  @override
  Widget build(BuildContext context) => BingConfirmarEliminar(
    alConfirmar: () => Navigator.of(context).pop(true),
    alCancelar: () => Navigator.of(context).pop(false),
  );
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
    ).push<bool>(_rutaSobrePantalla(const _HojaEliminar()));
    if (confirmado != true || !mounted) return;
    setState(() => _ocupado = true);
    try {
      await widget.sesion.eliminarCuenta();
      if (!mounted) return;
      final navegador = Navigator.of(context);
      navegador.pop();
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
        final saldo = AlcanceSesion.saldoDe(context);
        final billetera = AlcanceSesion.billeteraDe(context);
        return CuentaPage(
          nombre: usuario?.nombreVisible ?? '',
          correo: usuario?.correo ?? '',
          ocupado: _ocupado,
          saldo: saldo,
          alBilletera:
              billetera == null
                  ? null
                  : () => Navigator.of(context).push(
                    PageRouteBuilder<void>(
                      pageBuilder:
                          (c, _, __) => BilleteraReal(billetera: billetera),
                    ),
                  ),
          alVolver: () => Navigator.of(context).pop(),
          alCerrarSesion: _cerrarSesion,
          alEliminar: _eliminar,
        );
      },
    );
  }
}

/// Lo que se muestra arriba a la derecha del inicio: entrar, o los créditos y
/// la cuenta abierta.
class AccesoCuenta extends StatelessWidget {
  const AccesoCuenta({
    super.key,
    required this.usuario,
    required this.alEntrar,
    required this.alAbrirCuenta,
    this.saldo,
    this.alAbrirBilletera,
  });

  final UsuarioBing? usuario;
  final VoidCallback alEntrar;
  final VoidCallback alAbrirCuenta;

  /// Créditos de prueba; si llega, aparece su chip junto a la cuenta.
  final int? saldo;
  final VoidCallback? alAbrirBilletera;

  /// Con cuenta y saldo ocupa más ancho: el inicio le deja su propia fila.
  bool get ancho => usuario.tieneCuenta && saldo != null;

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
    final cuenta = Semantics(
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
    if (saldo == null) return cuenta;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: 'Billetera, $saldo créditos',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: alAbrirBilletera,
            child: ExcludeSemantics(
              child: BingChip(
                '$saldo créditos',
                tipo: BingChipTipo.pronto,
                icono: 'wallet',
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        cuenta,
      ],
    );
  }
}

/// Mi billetera: el saldo, los movimientos y recargar créditos de prueba.
class BilleteraReal extends StatefulWidget {
  const BilleteraReal({super.key, required this.billetera});

  final RepositorioBilletera billetera;

  @override
  State<BilleteraReal> createState() => _BilleteraRealState();
}

class _BilleteraRealState extends State<BilleteraReal> {
  late final Stream<List<Movimiento>> _movimientos =
      widget.billetera.movimientos().asBroadcastStream();

  Future<void> _recargar() async {
    final monto = await Navigator.of(
      context,
    ).push<int>(_rutaSobrePantalla(const _HojaRecarga()));
    if (monto == null || !mounted) return;
    try {
      await widget.billetera.recargar(monto);
      if (!mounted) return;
      mostrarAvisoBing(context, 'Se agregaron $monto créditos');
    } catch (_) {
      if (!mounted) return;
      mostrarAvisoBing(
        context,
        'No pudimos agregar los créditos. Inténtalo otra vez.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saldo = AlcanceSesion.saldoDe(context);
    return StreamBuilder<List<Movimiento>>(
      stream: _movimientos,
      builder:
          (context, foto) => BilleteraPage(
            saldo: saldo,
            movimientos: foto.data,
            alVolver: () => Navigator.of(context).pop(),
            alRecargar: _recargar,
          ),
    );
  }
}

/// La hoja de recarga: se cierra con el monto elegido, o sin nada si se cancela.
class _HojaRecarga extends StatelessWidget {
  const _HojaRecarga();

  @override
  Widget build(BuildContext context) => RecargarHoja(
    fondo: const SizedBox.shrink(),
    alAgregar: (monto) => Navigator.of(context).pop(monto),
    alCerrar: () => Navigator.of(context).pop(),
  );
}
