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

  /// Entra con Google (organizadores). `null` si la persona cancela.
  Future<User?> entrarConGoogle() async {
    final google = GoogleSignIn(
      serverClientId:
          _config.clienteWebGoogle.isEmpty ? null : _config.clienteWebGoogle,
    );
    final cuenta = await google.signIn();
    if (cuenta == null) return null;
    final datos = await cuenta.authentication;
    final credencial = GoogleAuthProvider.credential(
      accessToken: datos.accessToken,
      idToken: datos.idToken,
    );
    return (await _auth.signInWithCredential(credencial)).user;
  }

  Future<void> salir() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}
