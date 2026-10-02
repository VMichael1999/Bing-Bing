import 'package:bing_core/bing_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'configuracion.dart';
import 'iniciar.dart';
import 'repositorio_firestore.dart';

/// [RepositorioBilletera] sobre Firestore: lee `billeteras/{uid}` (el saldo y los
/// movimientos) y recarga con la Function `recargar`. Solo el servidor escribe.
class BilleteraFirestore implements RepositorioBilletera {
  BilleteraFirestore({
    FirebaseFirestore? db,
    FirebaseFunctions? funciones,
    FirebaseAuth? auth,
    ConfigFirebase config = ConfigFirebase.entorno,
    LlamadaFuncion? llamador,
  }) : _db = db ?? FirebaseFirestore.instance,
       _config = config,
       _funcionesDadas = funciones,
       _llamador = llamador,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final ConfigFirebase _config;
  final FirebaseFunctions? _funcionesDadas;
  final LlamadaFuncion? _llamador;
  final FirebaseAuth _auth;

  late final FirebaseFunctions _funciones =
      _funcionesDadas ?? funcionesBing(_config);

  DocumentReference<Map<String, dynamic>>? get _billetera {
    final uid = _auth.currentUser?.uid;
    return uid == null ? null : _db.collection('billeteras').doc(uid);
  }

  Future<Map<String, dynamic>> _llamar(
    String funcion,
    Map<String, Object?> datos,
  ) async {
    try {
      final resultado =
          _llamador != null
              ? await _llamador(funcion, datos)
              : (await _funciones
                  .httpsCallable(funcion)
                  .call<Object?>(datos)).data;
      return resultado is Map ? Map<String, dynamic>.from(resultado) : {};
    } on FirebaseFunctionsException catch (e) {
      throw errorDeFunciones(e.code, e.message, e.details);
    }
  }

  /// Crea la billetera con los créditos de bienvenida si la cuenta aún no la
  /// tiene (el servidor lo hace una sola vez).
  Future<void> asegurar() async {
    final doc = await _billetera?.get();
    if (doc != null && !doc.exists) await _llamar('obtenerBilletera', {});
  }

  @override
  Stream<int?> saldo() async* {
    final ref = _billetera;
    if (ref == null) {
      yield null;
      return;
    }
    try {
      await asegurar();
    } catch (_) {
      // Sin red, o sin cuenta: se sigue escuchando; si no hay billetera, `null`.
    }
    yield* ref.snapshots().map(
      (d) => d.exists ? (d.data()?['saldo'] as num?)?.toInt() : null,
    );
  }

  @override
  Stream<List<Movimiento>> movimientos() {
    final ref = _billetera;
    if (ref == null) return Stream.value(const []);
    return ref
        .collection('movimientos')
        .orderBy('creadaEn', descending: true)
        .limit(50)
        .snapshots()
        .map((q) => [for (final d in q.docs) movimientoDesdeMapa(d.data())]);
  }

  @override
  Future<void> recargar(int monto) async {
    await _llamar('recargar', {'monto': monto});
  }
}

/// Convierte un documento de `movimientos` en un [Movimiento].
Movimiento movimientoDesdeMapa(Map<String, dynamic> datos) => Movimiento(
  tipo: TipoMovimiento.desde(datos['tipo'] as String?),
  monto: (datos['monto'] as num?)?.toInt() ?? 0,
  detalle: datos['detalle'] as String? ?? '',
  creadaEn: fechaDe(datos['creadaEn']),
);
