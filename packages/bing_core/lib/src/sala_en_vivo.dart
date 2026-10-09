/// Estado de una sala, igual que el campo `estado` de Firestore.
enum EstadoSala {
  abierta,
  llena,
  enJuego,
  terminada,
  cancelada;

  static EstadoSala desde(String? texto) => switch (texto) {
    'llena' => EstadoSala.llena,
    'en_juego' => EstadoSala.enJuego,
    'terminada' => EstadoSala.terminada,
    'cancelada' => EstadoSala.cancelada,
    _ => EstadoSala.abierta,
  };
}

/// Una fila que ya salió ganadora y con qué bolilla se completó.
///
/// Las dos cuentas son **base 1**, como las guarda el servidor: `fila: 15` es
/// la fila número 15 y `bolillaIndice: 47` es la bolilla 47 de la partida.
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
    this.organizadorUid,
    this.creadaEn,
    this.publica = false,
    this.ocupadas = 0,
    this.motivoCierre,
    this.precioFila = 0,
    this.premio = 0,
    this.filasPorJugador = 20,
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
  final String? organizadorUid;
  final DateTime? creadaEn;

  /// Aparece en la lista de salas abiertas; si no, solo con el código o el enlace.
  final bool publica;

  /// Filas con jugador.
  final int ocupadas;

  /// Créditos que cuesta cada fila; 0 es una partida sin premio.
  final int precioFila;

  /// Créditos que gana la fila ganadora.
  final int premio;

  /// Cuántas filas puede tener una persona; por defecto, las que quiera (con
  /// saldo para pagarlas).
  final int filasPorJugador;

  /// Por qué quien organiza cerró la sala (si lo dijo); solo en las canceladas.
  final String? motivoCierre;

  int get libres => filasTotal - ocupadas;

  /// Ganó la fila en la posición [indice] de la lista de filas (base 0).
  bool ganoLaFila(int indice) => ganadoras.any((g) => g.fila == indice + 1);
}

/// Una fila de la sala: sus números y, si está tomada, quién la tiene.
class FilaEnVivo {
  const FilaEnVivo({
    required this.numeros,
    this.nombre,
    this.jugadorUid,
    this.reservadaEn,
  });

  final List<int> numeros;
  final String? nombre;
  final String? jugadorUid;

  /// Cuándo se reservó, para ordenar las llegadas y mostrar la hora.
  final DateTime? reservadaEn;

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

  /// Salas públicas que aún reciben jugadores o están llenas, de la más nueva a
  /// la más antigua. Es lo que ve cualquiera en la pantalla de inicio de Play.
  Stream<List<SalaEnVivo>> salasAbiertas();
  Stream<List<FilaEnVivo>> filas(String codigo);

  /// Reserva las [filas] (base 1) a nombre de [nombre], todas o ninguna, y cobra
  /// su precio de la billetera. Lanza [ErrorSalaBing] (`fila_ocupada`,
  /// `saldo_insuficiente`, `limite_de_filas`…).
  Future<void> reservarFilas({
    required String codigo,
    required List<int> filas,
    required String nombre,
  });

  /// Reserva una sola fila (base 1).
  Future<void> reservarFila({
    required String codigo,
    required int fila,
    required String nombre,
  }) => reservarFilas(codigo: codigo, filas: [fila], nombre: nombre);

  /// Uid de quien usa la app, para saber cuál es su fila.
  String? get uid;
}

/// Lo que quien organiza puede hacer con sus salas. El servidor decide el azar
/// del sorteo y quién puede organizar; la app solo pide y muestra.
abstract class RepositorioOrganizador implements RepositorioSala {
  /// Las salas creadas por quien usa la app, de la más nueva a la más antigua.
  Stream<List<SalaEnVivo>> misSalas();

  /// Crea una sala nueva y devuelve su código.
  Future<String> crearSala({
    required String nombre,
    required int columnas,
    bool publica = true,
    int precioFila = 0,
    int premio = 0,
    int filasPorJugador = 20,
  });

  Future<void> empezar(String codigo);

  /// Saca una bolilla al azar y devuelve su número.
  Future<int> sacarBolilla(String codigo);

  Future<void> deshacerBolilla(String codigo);
  Future<void> terminar(String codigo);

  /// Cierra una sala que no se jugó. Solo antes de empezar (si no, lanza
  /// [ErrorSalaBing] `sala_ya_empezada`). [motivo] se muestra a los jugadores.
  Future<void> cancelarSala(String codigo, {String? motivo});
}
