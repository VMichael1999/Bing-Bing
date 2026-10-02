import 'dart:async';

/// Montos que se pueden recargar (créditos de prueba, sin cobro).
const montosRecarga = [10, 20, 50, 100];

/// Créditos de prueba con los que empieza cada cuenta.
const creditosIniciales = 25;

/// Qué movió el saldo.
enum TipoMovimiento {
  regalo,
  recarga,
  fila,
  devolucion,
  premio;

  static TipoMovimiento desde(String? texto) => switch (texto) {
    'recarga' => TipoMovimiento.recarga,
    'fila' => TipoMovimiento.fila,
    'devolucion' => TipoMovimiento.devolucion,
    'premio' => TipoMovimiento.premio,
    _ => TipoMovimiento.regalo,
  };
}

/// Una línea del historial: positivo suma, negativo resta.
class Movimiento {
  const Movimiento({
    required this.tipo,
    required this.monto,
    required this.detalle,
    this.creadaEn,
  });

  final TipoMovimiento tipo;
  final int monto;
  final String detalle;
  final DateTime? creadaEn;
}

/// La billetera de quien juega: créditos de prueba (sin valor en dinero y que no
/// se retiran). El saldo vive en el servidor; la app solo lo muestra.
abstract class RepositorioBilletera {
  /// El saldo y cada cambio; `null` mientras se carga o si no hay cuenta.
  Stream<int?> saldo();

  /// Del movimiento más reciente al más antiguo.
  Stream<List<Movimiento>> movimientos();

  /// Agrega [monto] créditos de prueba al instante. Lanza `ErrorSalaBing`.
  Future<void> recargar(int monto);
}

/// Billetera en memoria para pruebas y demostraciones.
class BilleteraMemoria implements RepositorioBilletera {
  BilleteraMemoria({int saldo = creditosIniciales, List<Movimiento>? historial})
    : _saldo = saldo,
      _movimientos = [...?historial];

  int _saldo;
  final List<Movimiento> _movimientos;
  final _cambios = StreamController<void>.broadcast();

  int get saldoActual => _saldo;

  @override
  Stream<int?> saldo() async* {
    yield _saldo;
    yield* _cambios.stream.map((_) => _saldo);
  }

  @override
  Stream<List<Movimiento>> movimientos() async* {
    List<Movimiento> recientes() => _movimientos.reversed.toList();
    yield recientes();
    yield* _cambios.stream.map((_) => recientes());
  }

  /// Suma o resta como lo hace el servidor y lo anota en el historial.
  void aplicar(Movimiento movimiento) {
    _saldo += movimiento.monto;
    _movimientos.add(movimiento);
    _cambios.add(null);
  }

  @override
  Future<void> recargar(int monto) async {
    aplicar(
      Movimiento(
        tipo: TipoMovimiento.recarga,
        monto: monto,
        detalle: 'Recarga',
        creadaEn: DateTime.now(),
      ),
    );
  }

  void cerrar() => _cambios.close();
}
