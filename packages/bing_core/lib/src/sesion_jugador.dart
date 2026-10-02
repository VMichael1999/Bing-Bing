import 'dart:async';

/// Quién está usando la app: con cuenta (Google) o solo de invitado.
class UsuarioBing {
  const UsuarioBing({
    required this.uid,
    this.nombre,
    this.correo,
    this.esAnonimo = false,
  });

  final String uid;
  final String? nombre;
  final String? correo;

  /// Entró sin cuenta: puede mirar salas pero no elegir fila.
  final bool esAnonimo;

  /// Nombre para mostrar: el de la cuenta o, a falta de él, el correo.
  String get nombreVisible {
    final n = nombre?.trim();
    if (n != null && n.isNotEmpty) return n;
    return correo?.split('@').first ?? '';
  }

  /// Primer nombre, para proponerlo al reservar una fila.
  String get primerNombre => nombreVisible.split(' ').first;
}

/// Sesión de quien juega. La app arranca siempre con alguien (anónimo) para
/// poder mirar las salas; con Google se vincula esa misma sesión.
abstract class SesionJugador {
  /// Quien está ahora, o `null` si aún no hay sesión.
  UsuarioBing? get actual;

  /// El estado actual y cada cambio posterior.
  Stream<UsuarioBing?> get cambios;

  /// Inicia sesión con Google y la une a la sesión de invitado. `null` si la
  /// persona cancela. Lanza si algo falla.
  Future<UsuarioBing?> entrarConGoogle();

  /// Cierra la cuenta y vuelve a ser invitado.
  Future<void> cerrarSesion();

  /// Borra la cuenta (lo exigen las tiendas) y vuelve a ser invitado.
  Future<void> eliminarCuenta();
}

extension UsuarioBingConCuenta on UsuarioBing? {
  /// Tiene cuenta: no es anónimo.
  bool get tieneCuenta => this != null && !this!.esAnonimo;
}

/// Sesión en memoria para pruebas y demostraciones.
class SesionMemoria implements SesionJugador {
  SesionMemoria({UsuarioBing? inicial, this.cuentaGoogle})
    : _actual = inicial ?? const UsuarioBing(uid: 'anonimo', esAnonimo: true);

  /// Cuenta que "elige" Google en la prueba; `null` simula que se cancela.
  UsuarioBing? cuentaGoogle;

  /// Si no es `null`, `entrarConGoogle` lanza esto.
  Object? fallo;

  int cierres = 0;
  int borrados = 0;

  UsuarioBing _actual;
  final _controlador = StreamController<UsuarioBing?>.broadcast();

  @override
  UsuarioBing? get actual => _actual;

  @override
  Stream<UsuarioBing?> get cambios async* {
    yield _actual;
    yield* _controlador.stream;
  }

  void _poner(UsuarioBing usuario) {
    _actual = usuario;
    _controlador.add(usuario);
  }

  @override
  Future<UsuarioBing?> entrarConGoogle() async {
    final error = fallo;
    if (error != null) throw error;
    final cuenta = cuentaGoogle;
    if (cuenta == null) return null;
    _poner(cuenta);
    return cuenta;
  }

  @override
  Future<void> cerrarSesion() async {
    cierres++;
    _poner(const UsuarioBing(uid: 'anonimo', esAnonimo: true));
  }

  @override
  Future<void> eliminarCuenta() async {
    borrados++;
    _poner(const UsuarioBing(uid: 'anonimo', esAnonimo: true));
  }

  void cerrar() => _controlador.close();
}
