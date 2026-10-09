import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'configuracion.dart';

/// Sesión de la persona: anónima para jugar, con Google para organizar.
class SesionBing {
  SesionBing({
    FirebaseAuth? auth,
    ConfigFirebase config = ConfigFirebase.entorno,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _config = config;

  final FirebaseAuth _auth;
  final ConfigFirebase _config;

  User? get usuario => _auth.currentUser;
  Stream<User?> get cambios => _auth.authStateChanges();

  /// Quien organiza necesita una cuenta; el servidor rechaza a las anónimas.
  bool get esOrganizador => usuario != null && !usuario!.isAnonymous;

  /// Entra sin cuenta (jugadores). Reutiliza la sesión si ya existe.
  Future<User> entrarAnonimo() async {
    final actual = _auth.currentUser;
    if (actual != null) return actual;
    return (await _auth.signInAnonymously()).user!;
  }

  /// Pide la cuenta de Google y devuelve su credencial; `null` si la persona
  /// cancela.
  Future<OAuthCredential?> credencialGoogle() async {
    final google = GoogleSignIn(
      serverClientId:
          _config.clienteWebGoogle.isEmpty ? null : _config.clienteWebGoogle,
    );
    final cuenta = await google.signIn();
    if (cuenta == null) return null;
    final datos = await cuenta.authentication;
    return GoogleAuthProvider.credential(
      accessToken: datos.accessToken,
      idToken: datos.idToken,
    );
  }

  /// Entra con Google (organizadores). `null` si la persona cancela.
  Future<User?> entrarConGoogle() async {
    final credencial = await credencialGoogle();
    if (credencial == null) return null;
    return (await _auth.signInWithCredential(credencial)).user;
  }

  /// Solo con el emulador de Firebase: entra con una cuenta de prueba, porque
  /// el inicio de sesión con Google necesita una cuenta real y la huella SHA-1.
  Future<User> entrarDePrueba({String nombre = 'Carmen'}) async {
    assert(
      _config.usarEmulador,
      'La cuenta de prueba es solo para el emulador',
    );
    const correo = 'organizadora@prueba.bingbing.pe';
    const clave = 'clave-de-prueba';
    try {
      await _auth.signInWithEmailAndPassword(email: correo, password: clave);
    } on FirebaseAuthException {
      final nueva = await _auth.createUserWithEmailAndPassword(
        email: correo,
        password: clave,
      );
      await nueva.user!.updateDisplayName(nombre);
    }
    // Renueva el token para que lleve el nombre.
    await _auth.currentUser!.getIdToken(true);
    return _auth.currentUser!;
  }

  Future<void> salir() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}
