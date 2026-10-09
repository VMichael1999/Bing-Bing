import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Qué app de Bing Bing está arrancando.
enum AppBing { host, play }

/// Valores de Firebase leídos con `--dart-define-from-file=.env`.
///
/// Sin esos valores no hay proyecto al que conectarse: las apps siguen en modo
/// demostración con datos falsos.
class ConfigFirebase {
  const ConfigFirebase({
    required this.proyecto,
    required this.remitente,
    required this.region,
    required this.claveAndroid,
    required this.claveIos,
    required this.idAndroidHost,
    required this.idAndroidPlay,
    required this.idIosHost,
    required this.idIosPlay,
    required this.clienteWebGoogle,
    required this.usarEmulador,
    required this.anfitrionEmulador,
  });

  /// Lee las claves `FIREBASE_*` que se pasaron al compilar.
  static const entorno = ConfigFirebase(
    proyecto: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    remitente: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    region: String.fromEnvironment(
      'FIREBASE_REGION',
      defaultValue: 'us-central1',
    ),
    claveAndroid: String.fromEnvironment('FIREBASE_API_KEY_ANDROID'),
    claveIos: String.fromEnvironment('FIREBASE_API_KEY_IOS'),
    idAndroidHost: String.fromEnvironment('FIREBASE_APP_ID_ANDROID_HOST'),
    idAndroidPlay: String.fromEnvironment('FIREBASE_APP_ID_ANDROID_PLAY'),
    idIosHost: String.fromEnvironment('FIREBASE_APP_ID_IOS_HOST'),
    idIosPlay: String.fromEnvironment('FIREBASE_APP_ID_IOS_PLAY'),
    clienteWebGoogle: String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
    usarEmulador: bool.fromEnvironment('USE_FIREBASE_EMULATOR'),
    anfitrionEmulador: String.fromEnvironment(
      'FIREBASE_EMULATOR_HOST',
      defaultValue: '10.0.2.2',
    ),
  );

  final String proyecto;
  final String remitente;
  final String region;
  final String claveAndroid;
  final String claveIos;
  final String idAndroidHost;
  final String idAndroidPlay;
  final String idIosHost;
  final String idIosPlay;
  final String clienteWebGoogle;
  final bool usarEmulador;
  final String anfitrionEmulador;

  /// Opciones de Firebase para [app] en [plataforma], o `null` si faltan datos.
  FirebaseOptions? opciones(AppBing app, TargetPlatform plataforma) {
    final ios = plataforma == TargetPlatform.iOS;
    final clave = ios ? claveIos : claveAndroid;
    final id = switch ((ios, app)) {
      (false, AppBing.host) => idAndroidHost,
      (false, AppBing.play) => idAndroidPlay,
      (true, AppBing.host) => idIosHost,
      (true, AppBing.play) => idIosPlay,
    };
    if (proyecto.isEmpty || clave.isEmpty || id.isEmpty) return null;
    return FirebaseOptions(
      apiKey: clave,
      appId: id,
      messagingSenderId: remitente,
      projectId: proyecto,
      storageBucket: '$proyecto.firebasestorage.app',
    );
  }
}
