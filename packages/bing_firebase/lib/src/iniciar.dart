import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'configuracion.dart';

/// Conecta con Firebase y devuelve `true`, o `false` si no hay configuración.
///
/// Con `USE_FIREBASE_EMULATOR=true` apunta Auth, Firestore y Functions al
/// emulador local (puertos por defecto de `firebase emulators:start`).
Future<bool> iniciarFirebase(
  AppBing app, {
  ConfigFirebase config = ConfigFirebase.entorno,
  TargetPlatform? plataforma,
}) async {
  final opciones = config.opciones(app, plataforma ?? defaultTargetPlatform);
  if (opciones == null) return false;

  await Firebase.initializeApp(options: opciones);
  if (config.usarEmulador) {
    final host = config.anfitrionEmulador;
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    funcionesBing(config).useFunctionsEmulator(host, 5001);
  }
  return true;
}

/// Cloud Functions de la región del proyecto.
FirebaseFunctions funcionesBing(ConfigFirebase config) =>
    FirebaseFunctions.instanceFor(region: config.region);
