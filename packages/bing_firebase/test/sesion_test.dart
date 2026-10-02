import 'package:bing_firebase/bing_firebase.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

const _emulador = ConfigFirebase(
  proyecto: 'demo',
  remitente: '1',
  region: 'us-central1',
  claveAndroid: '',
  claveIos: '',
  idAndroidHost: '',
  idAndroidPlay: '',
  idIosHost: '',
  idIosPlay: '',
  clienteWebGoogle: '',
  usarEmulador: true,
  anfitrionEmulador: '10.0.2.2',
);

void main() {
  test('sin sesión no hay usuario ni organizadora', () {
    final sesion = SesionBing(auth: MockFirebaseAuth());
    expect(sesion.usuario, isNull);
    expect(sesion.esOrganizador, isFalse);
  });

  test('entrarAnonimo crea una sesión anónima que no organiza', () async {
    final sesion = SesionBing(auth: MockFirebaseAuth());
    final usuario = await sesion.entrarAnonimo();
    expect(usuario.isAnonymous, isTrue);
    expect(sesion.esOrganizador, isFalse);
  });

  test('entrarAnonimo reutiliza la sesión que ya existe', () async {
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'lucia'),
    );
    final usuario = await SesionBing(auth: auth).entrarAnonimo();
    expect(usuario.uid, 'lucia');
  });

  test('una cuenta con nombre sí cuenta como organizadora', () {
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'carmen',
        isAnonymous: false,
        displayName: 'Carmen',
      ),
    );
    final sesion = SesionBing(auth: auth);
    expect(sesion.esOrganizador, isTrue);
    expect(sesion.usuario?.displayName, 'Carmen');
  });

  test('cambios avisa cuando se inicia sesión', () async {
    final sesion = SesionBing(auth: MockFirebaseAuth());
    final uids = <String?>[];
    final suscripcion = sesion.cambios.listen((u) => uids.add(u?.uid));
    await sesion.entrarAnonimo();
    await Future<void>.delayed(Duration.zero);
    await suscripcion.cancel();
    expect(uids.last, isNotNull);
  });

  test('entrarDePrueba da una cuenta con nombre para el emulador', () async {
    final auth = MockFirebaseAuth();
    final usuario =
        await SesionBing(auth: auth, config: _emulador).entrarDePrueba();
    expect(usuario.isAnonymous, isFalse);
    expect(auth.currentUser, isNotNull);
  });
}
