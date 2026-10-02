import 'package:bing_core/bing_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'configuracion.dart';
import 'sesion.dart';

/// [SesionJugador] sobre Firebase Auth.
///
/// Quien juega arranca como invitado (sesión anónima). Al entrar con Google esa
/// misma sesión se **vincula** a la cuenta, así la fila y el historial no se
/// pierden. Si la cuenta de Google ya existía, se entra en ella.
class SesionJugadorFirebase implements SesionJugador {
  SesionJugadorFirebase({
    FirebaseAuth? auth,
    Future<AuthCredential?> Function()? credencialGoogle,
    Future<void> Function()? cerrarGoogle,
    bool? usarEmulador,
    this.nombreDePrueba = 'Lucía',
  }) : _usarEmulador = usarEmulador ?? ConfigFirebase.entorno.usarEmulador,
       _auth = auth ?? FirebaseAuth.instance,
       _credencialGoogle = credencialGoogle ?? SesionBing().credencialGoogle,
       _cerrarGoogle = cerrarGoogle ?? (() => GoogleSignIn().signOut());

  final FirebaseAuth _auth;
  final Future<AuthCredential?> Function() _credencialGoogle;
  final Future<void> Function() _cerrarGoogle;

  /// Con el emulador de Firebase no hay Google real: entra una cuenta de prueba.
  final bool _usarEmulador;
  final String nombreDePrueba;

  static UsuarioBing? _usuario(User? u) =>
      u == null
          ? null
          : UsuarioBing(
            uid: u.uid,
            nombre: u.displayName,
            correo: u.email ?? _correoDeProveedor(u),
            esAnonimo: u.isAnonymous,
          );

  static String? _correoDeProveedor(User u) {
    for (final p in u.providerData) {
      final correo = p.email;
      if (correo != null && correo.isNotEmpty) return correo;
    }
    return null;
  }

  @override
  UsuarioBing? get actual => _usuario(_auth.currentUser);

  @override
  Stream<UsuarioBing?> get cambios => _auth.userChanges().map(_usuario);

  /// Solo con el emulador: entra (o crea la primera vez) una cuenta de prueba,
  /// porque el inicio de sesión con Google necesita una cuenta real.
  Future<UsuarioBing?> _entrarDePrueba() async {
    const correo = 'jugadora@prueba.bingbing.pe';
    const clave = 'clave-de-prueba';
    try {
      await _auth.signInWithEmailAndPassword(email: correo, password: clave);
    } on FirebaseAuthException {
      final nueva = await _auth.createUserWithEmailAndPassword(
        email: correo,
        password: clave,
      );
      await nueva.user!.updateDisplayName(nombreDePrueba);
    }
    await _auth.currentUser!.reload();
    return actual;
  }

  @override
  Future<UsuarioBing?> entrarConGoogle() async {
    if (_usarEmulador) return _entrarDePrueba();
    final credencial = await _credencialGoogle();
    if (credencial == null) return null;
    final actual = _auth.currentUser;
    if (actual != null && actual.isAnonymous) {
      try {
        final r = await actual.linkWithCredential(credencial);
        return _usuario(r.user);
      } on FirebaseAuthException catch (e) {
        // La cuenta ya existía (otro teléfono u otra vez): se entra en ella.
        final existente = e.credential;
        if ((e.code == 'credential-already-in-use' ||
                e.code == 'email-already-in-use') &&
            existente != null) {
          return _usuario((await _auth.signInWithCredential(existente)).user);
        }
        rethrow;
      }
    }
    return _usuario((await _auth.signInWithCredential(credencial)).user);
  }

  Future<void> _volverAInvitado() async {
    await _auth.signInAnonymously();
  }

  @override
  Future<void> cerrarSesion() async {
    await _cerrarGoogle();
    await _auth.signOut();
    await _volverAInvitado();
  }

  @override
  Future<void> eliminarCuenta() async {
    final usuario = _auth.currentUser;
    if (usuario == null) return;
    try {
      await usuario.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') rethrow;
      // Borrar pide haber entrado hace poco: se confirma con Google y se repite.
      final credencial = await _credencialGoogle();
      if (credencial == null) return;
      await usuario.reauthenticateWithCredential(credencial);
      await usuario.delete();
    }
    await _cerrarGoogle();
    await _volverAInvitado();
  }
}
