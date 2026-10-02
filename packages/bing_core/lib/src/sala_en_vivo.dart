/// Estado de una sala, igual que el campo `estado` de Firestore.
enum EstadoSala {
  abierta,
  llena,
  enJuego,
  terminada;

  static EstadoSala desde(String? texto) => switch (texto) {
    'llena' => EstadoSala.llena,
    'en_juego' => EstadoSala.enJuego,
    'terminada' => EstadoSala.terminada,
    _ => EstadoSala.abierta,
  };
}

/// Una fila que ya salió ganadora, y con qué bolilla (base 1) se completó.
typedef GanadoraEnVivo = ({int fila, int bolillaIndice});

/// Foto de la sala tal como la ven los jugadores.
class SalaEnVivo {
  const SalaEnVivo({
    required this.codigo,
    required this.nombre,
    required this.organizador,
    required this.estado,
    required this.columnas,
    required this.filasTotal,
    required this.bolillas,
    required this.ganadoras,
  });

  final String codigo;
  final String nombre;
  final String organizador;
  final EstadoSala estado;
  final int columnas;
  final int filasTotal;

  /// En orden de salida.
  final List<int> bolillas;
  final List<GanadoraEnVivo> ganadoras;

  /// Ganó [fila] (base 0).
  bool ganoLaFila(int fila) => ganadoras.any((g) => g.fila == fila);
}

/// Una fila de la sala: sus números y, si está tomada, quién la tiene.
class FilaEnVivo {
  const FilaEnVivo({required this.numeros, this.nombre, this.jugadorUid});

  final List<int> numeros;
  final String? nombre;
  final String? jugadorUid;

  bool get libre => jugadorUid == null;
}

/// La sala no existe o la reserva fue rechazada por el servidor.
class ErrorSalaBing implements Exception {
  const ErrorSalaBing(this.codigo, this.mensaje);

  /// Código estable para traducir: `no_existe`, `fila_ocupada`, `limite_de_filas`,
  /// `sala_no_abierta`, `nombre_invalido`.
  final String codigo;
  final String mensaje;

  @override
  String toString() => 'ErrorSalaBing($codigo): $mensaje';
}

/// Lo que las apps necesitan de una sala. Firestore lo implementa en
/// `bing_firebase`; las pruebas usan una versión en memoria.
abstract class RepositorioSala {
  /// Busca la sala por su código; `null` si no existe.
  Future<SalaEnVivo?> buscar(String codigo);

  Stream<SalaEnVivo?> sala(String codigo);
  Stream<List<FilaEnVivo>> filas(String codigo);

  /// Reserva [fila] (base 1) a nombre de [nombre]. Lanza [ErrorSalaBing].
  Future<void> reservarFila({
    required String codigo,
    required int fila,
    required String nombre,
  });

  /// Uid de quien usa la app, para saber cuál es su fila.
  String? get uid;
}
