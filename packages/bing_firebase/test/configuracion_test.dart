import 'package:bing_firebase/bing_firebase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _completa = ConfigFirebase(
  proyecto: 'demo',
  remitente: '123',
  region: 'us-central1',
  claveAndroid: 'clave-android',
  claveIos: 'clave-ios',
  idAndroidHost: '1:123:android:host',
  idAndroidPlay: '1:123:android:play',
  idIosHost: '1:123:ios:host',
  idIosPlay: '1:123:ios:play',
  clienteWebGoogle: '',
  usarEmulador: false,
  anfitrionEmulador: '10.0.2.2',
);

void main() {
  group('ConfigFirebase.opciones', () {
    test('elige la clave y el id según la app y la plataforma', () {
      final host = _completa.opciones(AppBing.host, TargetPlatform.android)!;
      expect(host.apiKey, 'clave-android');
      expect(host.appId, '1:123:android:host');

      final play = _completa.opciones(AppBing.play, TargetPlatform.iOS)!;
      expect(play.apiKey, 'clave-ios');
      expect(play.appId, '1:123:ios:play');
      expect(play.projectId, 'demo');
      expect(play.storageBucket, 'demo.firebasestorage.app');
    });

    test('sin proyecto o sin id devuelve null y la app queda en demo', () {
      expect(
        ConfigFirebase.entorno.opciones(AppBing.host, TargetPlatform.android),
        isNull,
      );
    });
  });

  test('iniciarFirebase no hace nada sin configuración', () async {
    expect(await iniciarFirebase(AppBing.play), isFalse);
  });
}
