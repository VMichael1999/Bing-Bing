import 'package:bing_core/bing_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'configuracion.dart';
import 'iniciar.dart';

/// Lee la sala de Firestore (solo lectura) y reserva filas con la Function
/// `reservarFila`: el servidor es quien decide quién se queda con cada fila.
class RepositorioFirestore implements RepositorioSala {
  RepositorioFirestore({
    FirebaseFirestore? db,
    FirebaseFunctions? funciones,
    FirebaseAuth? auth,
    ConfigFirebase config = ConfigFirebase.entorno,
  }) : _db = db ?? FirebaseFirestore.instance,
       _funciones = funciones ?? funcionesBing(config),
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _funciones;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> _sala(String codigo) =>
      _db.collection('salas').doc(codigo);

  @override
  String? get uid => _auth.currentUser?.uid;

  @override
  Future<SalaEnVivo?> buscar(String codigo) async {
    final doc = await _sala(codigo).get();
    final datos = doc.data();
    return datos == null ? null : salaDesdeMapa(codigo, datos);
  }

  @override
  Stream<SalaEnVivo?> sala(String codigo) => _sala(codigo).snapshots().map((d) {
    final datos = d.data();
    return datos == null ? null : salaDesdeMapa(codigo, datos);
  });

  @override
  Stream<List<FilaEnVivo>> filas(String codigo) => _sala(codigo)
      .collection('filas')
      .snapshots()
      .map(
        (q) => filasDesdeDocumentos({for (final d in q.docs) d.id: d.data()}),
      );

  @override
  Future<void> reservarFila({
    required String codigo,
    required int fila,
    required String nombre,
  }) async {
    try {
      await _funciones.httpsCallable('reservarFila').call<Object?>({
        'codigo': codigo,
        'fila': fila,
        'nombre': nombre,
      });
    } on FirebaseFunctionsException catch (e) {
      throw errorDeFunciones(e.code, e.message, e.details);
    }
  }
}

/// Convierte el documento `salas/{codigo}` en una [SalaEnVivo].
SalaEnVivo salaDesdeMapa(String codigo, Map<String, dynamic> datos) {
  return SalaEnVivo(
    codigo: codigo,
    nombre: datos['nombre'] as String? ?? '',
    organizador: datos['organizadorNombre'] as String? ?? 'quien organiza',
    estado: EstadoSala.desde(datos['estado'] as String?),
    columnas: (datos['columnas'] as num?)?.toInt() ?? 5,
    filasTotal: (datos['filasTotal'] as num?)?.toInt() ?? 20,
    bolillas: [
      for (final n in datos['bolillas'] as List? ?? []) (n as num).toInt(),
    ],
    ganadoras: [
      for (final g in datos['ganadores'] as List? ?? [])
        (
          fila: ((g as Map)['fila'] as num).toInt(),
          bolillaIndice: (g['bolillaIndice'] as num).toInt(),
        ),
    ],
  );
}

/// Ordena los documentos `filas/{n}` por número de fila (1, 2, … 20).
List<FilaEnVivo> filasDesdeDocumentos(Map<String, Map<String, dynamic>> docs) {
  final ids =
      docs.keys.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
  return [
    for (final id in ids)
      FilaEnVivo(
        numeros: [
          for (final n in docs[id]!['numeros'] as List) (n as num).toInt(),
        ],
        nombre: docs[id]!['nombre'] as String?,
        jugadorUid: docs[id]!['jugadorUid'] as String?,
      ),
  ];
}

/// Traduce el error del servidor a uno que las pantallas pueden explicar.
ErrorSalaBing errorDeFunciones(String code, String? mensaje, Object? detalles) {
  final codigo =
      detalles is Map && detalles['codigo'] is String
          ? detalles['codigo'] as String
          : (code == 'not-found' ? 'no_existe' : code);
  return ErrorSalaBing(codigo, mensaje ?? 'No se pudo completar la acción');
}
