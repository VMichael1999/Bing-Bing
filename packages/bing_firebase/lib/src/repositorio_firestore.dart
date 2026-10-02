import 'package:bing_core/bing_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'configuracion.dart';
import 'iniciar.dart';

/// Llama a una Function del servidor por su nombre. Las pruebas la reemplazan.
typedef LlamadaFuncion =
    Future<Object?> Function(String funcion, Map<String, Object?> datos);

/// Lee la sala de Firestore (solo lectura) y reserva filas con la Function
/// `reservarFila`: el servidor es quien decide quién se queda con cada fila.
class RepositorioFirestore implements RepositorioOrganizador {
  RepositorioFirestore({
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

  /// Las Functions de la región del proyecto, solo si hace falta llamarlas.
  late final FirebaseFunctions _funciones =
      _funcionesDadas ?? funcionesBing(_config);

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
  Stream<List<SalaEnVivo>> salasAbiertas() => _db
      .collection('salas')
      .where('publica', isEqualTo: true)
      .where('estado', whereIn: ['abierta', 'llena'])
      .snapshots()
      .map(
        (q) => ordenarSalas([
          for (final d in q.docs) salaDesdeMapa(d.id, d.data()),
        ]),
      );

  @override
  Stream<List<FilaEnVivo>> filas(String codigo) => _sala(codigo)
      .collection('filas')
      .snapshots()
      .map(
        (q) => filasDesdeDocumentos({for (final d in q.docs) d.id: d.data()}),
      );

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

  @override
  Future<void> reservarFila({
    required String codigo,
    required int fila,
    required String nombre,
  }) async {
    await _llamar('reservarFila', {
      'codigo': codigo,
      'fila': fila,
      'nombre': nombre,
    });
  }

  // --- Quien organiza -------------------------------------------------------

  @override
  Stream<List<SalaEnVivo>> misSalas() => _db
      .collection('salas')
      .where('organizadorUid', isEqualTo: uid)
      .snapshots()
      .map(
        (q) => ordenarSalas([
          for (final d in q.docs) salaDesdeMapa(d.id, d.data()),
        ]),
      );

  @override
  Future<String> crearSala({
    required String nombre,
    required int columnas,
    bool publica = true,
  }) async {
    final r = await _llamar('crearSala', {
      'nombre': nombre,
      'columnas': columnas,
      'publica': publica,
    });
    return r['codigo'] as String;
  }

  @override
  Future<void> empezar(String codigo) async {
    await _llamar('empezarPartida', {'codigo': codigo});
  }

  @override
  Future<int> sacarBolilla(String codigo) async {
    final r = await _llamar('sacarBolilla', {'codigo': codigo});
    return (r['numero'] as num).toInt();
  }

  @override
  Future<void> deshacerBolilla(String codigo) async {
    await _llamar('deshacerBolilla', {'codigo': codigo});
  }

  @override
  Future<void> terminar(String codigo) async {
    await _llamar('terminarPartida', {'codigo': codigo});
  }

  @override
  Future<void> cancelarSala(String codigo, {String? motivo}) async {
    await _llamar('cancelarSala', {
      'codigo': codigo,
      if (motivo != null && motivo.trim().isNotEmpty) 'motivo': motivo.trim(),
    });
  }
}

/// Fecha de un campo de Firestore (`Timestamp`) o ya convertida.
DateTime? fechaDe(Object? valor) => switch (valor) {
  Timestamp() => valor.toDate(),
  DateTime() => valor,
  _ => null,
};

/// De la sala más nueva a la más antigua; las que no tienen fecha, al final.
List<SalaEnVivo> ordenarSalas(List<SalaEnVivo> salas) {
  final copia = [...salas];
  copia.sort((a, b) {
    final fa = a.creadaEn, fb = b.creadaEn;
    if (fa == null && fb == null) return 0;
    if (fa == null) return 1;
    if (fb == null) return -1;
    return fb.compareTo(fa);
  });
  return copia;
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
    organizadorUid: datos['organizadorUid'] as String?,
    creadaEn: fechaDe(datos['creadaEn']),
    publica: datos['publica'] == true,
    ocupadas: (datos['ocupadas'] as num?)?.toInt() ?? 0,
    motivoCierre: datos['motivoCierre'] as String?,
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
        reservadaEn: fechaDe(docs[id]!['reservadaEn']),
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
