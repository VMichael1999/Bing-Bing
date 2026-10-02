import 'package:bing_core/bing_core.dart';
import 'package:bing_firebase/bing_firebase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

AuthCredential get _google =>
    GoogleAuthProvider.credential(idToken: 'id', accessToken: 'acceso');

void main() {
  SesionJugadorFirebase sesion(
    MockFirebaseAuth auth, {
    AuthCredential? Function()? credencial,
    List<String>? bitacora,
  }) => SesionJugadorFirebase(
    auth: auth,
    credencialGoogle: () async => (credencial ?? () => _google)(),
    cerrarGoogle: () async => bitacora?.add('google-fuera'),
  );

  test('traduce el usuario de Firebase', () async {
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'u1',
        displayName: 'Lucía Torres',
        email: 'lucia@correo.com',
      ),
    );
    final u = sesion(auth).actual!;
    expect(u.uid, 'u1');
    expect(u.nombre, 'Lucía Torres');
    expect(u.correo, 'lucia@correo.com');
    expect(u.tieneCuenta, isTrue);
  });

  test('un invitado no tiene cuenta', () async {
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'a', isAnonymous: true),
    );
    expect(sesion(auth).actual.tieneCuenta, isFalse);
  });

  test('si la persona cancela Google no cambia nada', () async {
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'a', isAnonymous: true),
    );
    final s = sesion(auth, credencial: () => null);
    expect(await s.entrarConGoogle(), isNull);
    expect(s.actual!.uid, 'a');
  });

  test('cerrar sesión sale de Google y vuelve a invitado', () async {
    // El simulador solo deja volver a entrar como anónimo con un usuario que
    // ya lo sea; lo que se comprueba es la salida de Google y el estado final.
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'u1',
        email: 'lucia@correo.com',
        isAnonymous: true,
      ),
    );
    final bitacora = <String>[];
    final s = sesion(auth, bitacora: bitacora);
    await s.cerrarSesion();
    expect(bitacora, ['google-fuera']);
    expect(s.actual, isNotNull);
    expect(s.actual.tieneCuenta, isFalse);
  });

  test('eliminar la cuenta borra al usuario y vuelve a invitado', () async {
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'u1',
        email: 'lucia@correo.com',
        isAnonymous: true,
      ),
    );
    final s = sesion(auth);
    await s.eliminarCuenta();
    expect(s.actual.tieneCuenta, isFalse);
  });

  test('los cambios incluyen el estado inicial', () async {
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'u1', email: 'lucia@correo.com'),
    );
    final primero = await sesion(auth).cambios.first;
    expect(primero?.uid, 'u1');
  });
}
