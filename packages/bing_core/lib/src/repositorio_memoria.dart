import 'dart:async';

import 'billetera.dart';
import 'sala_en_vivo.dart';

/// [RepositorioSala] en memoria para probar las apps sin Firebase.
///
/// Se comporta como el servidor: una fila solo se reserva una vez y cada
/// persona solo puede tener una. Los métodos de "servidor" ([ocupar],
/// [empezar], [sacar]) permiten simular lo que hacen otros jugadores y quien
/// organiza.
class RepositorioMemoria implements RepositorioOrganizador {
  RepositorioMemoria({
    required this.cartillas,
    this.codigo = 'K7Q4',
    this.nombreSala = 'Bingo de los sábados',
    this.organizador = 'Carmen',
    this.miUid = 'yo',
    this.ordenBolillas = const [],
    this.publica = true,
    this.precioFila = 0,
    this.premio = 0,
    this.filasPorJugador = 20,
    this.billetera,
  }) : _filas = [for (final n in cartillas) FilaEnVivo(numeros: n)];

  final List<List<int>> cartillas;
  final String codigo;
  final String nombreSala;
  final String organizador;
  final String miUid;

  /// Orden en que salen las bolillas cuando se sortea como organizador.
  final List<int> ordenBolillas;

  /// Visibilidad de la sala; cambia al crearla con `crearSala`.
  bool publica;

  /// Precio y premio de la sala; cambian al crearla con `crearSala`.
  int precioFila;
  int premio;
  int filasPorJugador;

  /// Si se da, cobra y devuelve como lo hace el servidor.
  final BilleteraMemoria? billetera;

  final List<FilaEnVivo> _filas;
  final List<int> _bolillas = [];
  final List<GanadoraEnVivo> _ganadoras = [];
  EstadoSala _estado = EstadoSala.abierta;
  String? _motivoCierre;
  int _llegadas = 0;

  final _salaCambios = StreamController<void>.broadcast();

  @override
  String? get uid => miUid;

  SalaEnVivo get _foto => SalaEnVivo(
    codigo: codigo,
    nombre: nombreSala,
    organizador: organizador,
    estado: _estado,
    columnas: cartillas.first.length,
    filasTotal: cartillas.length,
    bolillas: List.of(_bolillas),
    ganadoras: List.of(_ganadoras),
    organizadorUid: miUid,
    publica: publica,
    ocupadas: _filas.where((f) => !f.libre).length,
    motivoCierre: _motivoCierre,
    precioFila: precioFila,
    premio: premio,
    filasPorJugador: filasPorJugador,
  );

  @override
  Future<SalaEnVivo?> buscar(String codigo) async =>
      codigo == this.codigo ? _foto : null;

  @override
  Stream<SalaEnVivo?> sala(String codigo) async* {
    if (codigo != this.codigo) {
      yield null;
      return;
    }
    yield _foto;
    yield* _salaCambios.stream.map((_) => _foto);
  }

  @override
  Stream<List<SalaEnVivo>> salasAbiertas() async* {
    List<SalaEnVivo> visibles() => [
      if (publica &&
          (_estado == EstadoSala.abierta || _estado == EstadoSala.llena))
        _foto,
    ];
    yield visibles();
    yield* _salaCambios.stream.map((_) => visibles());
  }

  @override
  Stream<List<FilaEnVivo>> filas(String codigo) async* {
    yield List.of(_filas);
    yield* _salaCambios.stream.map((_) => List.of(_filas));
  }

  @override
  Future<void> reservarFilas({
    required String codigo,
    required List<int> filas,
    required String nombre,
  }) async {
    if (codigo != this.codigo) {
      throw const ErrorSalaBing('no_existe', 'No existe esa sala');
    }
    if (_estado != EstadoSala.abierta) {
      throw const ErrorSalaBing(
        'sala_no_abierta',
        'La sala ya no está abierta',
      );
    }
    if (filas.isEmpty || filas.toSet().length != filas.length) {
      throw const ErrorSalaBing('filas_invalidas', 'Elige filas distintas');
    }
    for (final fila in filas) {
      if (fila < 1 || fila > _filas.length) {
        throw const ErrorSalaBing('fila_inexistente', 'Esa fila no existe');
      }
      if (!_filas[fila - 1].libre) {
        throw const ErrorSalaBing('fila_ocupada', 'Esa fila ya tiene dueño');
      }
    }
    final propias = _filas.where((f) => f.jugadorUid == miUid).length;
    if (propias + filas.length > filasPorJugador) {
      throw const ErrorSalaBing(
        'limite_de_filas',
        'Superas el límite de filas por jugador',
      );
    }
    final costo = precioFila * filas.length;
    final cartera = billetera;
    if (costo > 0 && cartera != null) {
      if (costo > cartera.saldoActual) {
        throw const ErrorSalaBing(
          'saldo_insuficiente',
          'No te alcanza el saldo',
        );
      }
      for (final fila in [...filas]..sort()) {
        cartera.aplicar(
          Movimiento(
            tipo: TipoMovimiento.fila,
            monto: -precioFila,
            detalle: 'Fila $fila · $nombreSala',
            creadaEn: DateTime.now(),
          ),
        );
      }
    }
    for (final fila in filas) {
      ocupar(fila, nombre, miUid);
    }
  }

  @override
  Future<void> reservarFila({
    required String codigo,
    required int fila,
    required String nombre,
  }) => reservarFilas(codigo: codigo, filas: [fila], nombre: nombre);

  /// Otra persona toma la fila [fila] (base 1).
  void ocupar(int fila, String nombre, String uid) {
    _filas[fila - 1] = FilaEnVivo(
      numeros: cartillas[fila - 1],
      nombre: nombre,
      jugadorUid: uid,
      reservadaEn: DateTime(
        2026,
        10,
        2,
        20,
        44,
      ).add(Duration(minutes: _llegadas++)),
    );
    if (_filas.every((f) => !f.libre)) _estado = EstadoSala.llena;
    _salaCambios.add(null);
  }

  /// Quien organiza empieza la partida (sin validar que esté llena).
  void empezarPartida() {
    _estado = EstadoSala.enJuego;
    _salaCambios.add(null);
  }

  /// Quien organiza saca la bolilla [numero]; marca las filas que completan.
  void sacar(int numero) {
    _bolillas.add(numero);
    final salidas = _bolillas.toSet();
    for (var i = 0; i < cartillas.length; i++) {
      if (_ganadoras.any((g) => g.fila == i + 1)) continue;
      if (cartillas[i].every(salidas.contains)) {
        _ganadoras.add((fila: i + 1, bolillaIndice: _bolillas.length));
      }
    }
    _salaCambios.add(null);
  }

  // --- Quien organiza -------------------------------------------------------

  @override
  Stream<List<SalaEnVivo>> misSalas() async* {
    yield [_foto];
    yield* _salaCambios.stream.map((_) => [_foto]);
  }

  @override
  Future<String> crearSala({
    required String nombre,
    required int columnas,
    bool publica = true,
    int precioFila = 0,
    int premio = 0,
    int filasPorJugador = 20,
  }) async {
    this.publica = publica;
    this.precioFila = precioFila;
    this.premio = premio;
    this.filasPorJugador = filasPorJugador;
    return codigo;
  }

  @override
  Future<void> empezar(String codigo) async {
    if (_estado != EstadoSala.llena) {
      throw const ErrorSalaBing(
        'sala_no_llena',
        'La cartilla aún no está llena',
      );
    }
    empezarPartida();
  }

  /// Saca la siguiente bolilla en el orden fijo de [ordenBolillas].
  @override
  Future<int> sacarBolilla(String codigo) async {
    if (_estado != EstadoSala.enJuego) {
      throw const ErrorSalaBing('sala_no_en_juego', 'La partida no empezó');
    }
    if (_bolillas.length >= ordenBolillas.length) {
      throw const ErrorSalaBing('tombola_vacia', 'No quedan bolillas');
    }
    final numero = ordenBolillas[_bolillas.length];
    sacar(numero);
    return numero;
  }

  @override
  Future<void> deshacerBolilla(String codigo) async {
    if (_bolillas.isEmpty) return;
    _bolillas.removeLast();
    _ganadoras.removeWhere((g) => g.bolillaIndice > _bolillas.length);
    _salaCambios.add(null);
  }

  @override
  Future<void> terminar(String codigo) async {
    _estado = EstadoSala.terminada;
    _salaCambios.add(null);
  }

  @override
  Future<void> cancelarSala(String codigo, {String? motivo}) async {
    if (_estado == EstadoSala.enJuego || _estado == EstadoSala.terminada) {
      throw const ErrorSalaBing(
        'sala_ya_empezada',
        'La partida ya empezó y no se puede cerrar',
      );
    }
    final limpio = motivo?.trim();
    _motivoCierre = limpio == null || limpio.isEmpty ? null : limpio;
    // Cada fila que pagó la persona de esta app vuelve a su billetera.
    final cartera = billetera;
    if (_estado != EstadoSala.cancelada && cartera != null && precioFila > 0) {
      for (var i = 0; i < _filas.length; i++) {
        if (_filas[i].jugadorUid == miUid) {
          cartera.aplicar(
            Movimiento(
              tipo: TipoMovimiento.devolucion,
              monto: precioFila,
              detalle: 'Devolución · fila ${i + 1} de $nombreSala',
              creadaEn: DateTime.now(),
            ),
          );
        }
      }
    }
    _estado = EstadoSala.cancelada;
    _salaCambios.add(null);
  }

  void cerrar() => _salaCambios.close();
}
