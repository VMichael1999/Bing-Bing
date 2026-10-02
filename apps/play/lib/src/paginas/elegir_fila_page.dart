import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

/// `jug-02-elegir-fila` y `jug-10-sin-saldo`: el jugador elige las filas libres
/// que quiera, mientras la billetera alcance para pagarlas.
class ElegirFilaPage extends StatefulWidget {
  const ElegirFilaPage({
    super.key,
    required this.salaNombre,
    required this.cartillas,
    required this.duenos,
    this.seleccionInicial = const {},
    this.precioFila = 0,
    this.premio = 0,
    this.saldo,
    this.limite = 20,
    this.alVolver,
    this.alSeguir,
    this.alRecargar,
  });

  final String salaNombre;
  final List<List<int>> cartillas;

  /// Dueño de cada fila (misma longitud que [cartillas]); `null` si está libre.
  final List<String?> duenos;

  /// Filas elegidas al abrir (base 1).
  final Set<int> seleccionInicial;

  /// Créditos que cuesta cada fila; 0 si la partida es gratis.
  final int precioFila;
  final int premio;

  /// Créditos de prueba que tiene la persona; `null` si aún no se sabe (el
  /// servidor lo comprueba igual al reservar).
  final int? saldo;

  /// Cuántas filas puede tener una persona.
  final int limite;
  final VoidCallback? alVolver;

  /// Recibe las filas elegidas (base 1), de menor a mayor.
  final ValueChanged<List<int>>? alSeguir;
  final VoidCallback? alRecargar;

  @override
  State<ElegirFilaPage> createState() => _ElegirFilaPageState();
}

class _ElegirFilaPageState extends State<ElegirFilaPage> {
  late final Set<int> _elegidas = {...widget.seleccionInicial};

  bool get _cobra => widget.precioFila > 0;

  /// Sin saldo para ni una fila: se ven pero no se pueden elegir (`jug-10`).
  bool get _sinSaldo =>
      _cobra && widget.saldo != null && widget.saldo! < widget.precioFila;

  /// Cuántas filas se pueden elegir: el límite de la sala y lo que alcanza el saldo.
  int get _tope {
    final porSaldo =
        _cobra && widget.saldo != null
            ? widget.saldo! ~/ widget.precioFila
            : widget.limite;
    return porSaldo < widget.limite ? porSaldo : widget.limite;
  }

  void _alternar(int fila) {
    if (_sinSaldo) return;
    if (_elegidas.contains(fila)) {
      setState(() => _elegidas.remove(fila));
      return;
    }
    if (_elegidas.length >= _tope) {
      mostrarAvisoBing(
        context,
        _tope >= widget.limite
            ? 'Esta sala permite hasta ${widget.limite} filas por persona'
            : 'Con tu saldo alcanzas para $_tope ${_tope == 1 ? 'fila' : 'filas'}',
      );
      return;
    }
    setState(() => _elegidas.add(fila));
  }

  @override
  void didUpdateWidget(ElegirFilaPage anterior) {
    super.didUpdateWidget(anterior);
    // Si el saldo bajó (o llegó), no se puede quedar con más filas de las que paga.
    final tope = _tope;
    if (_elegidas.length > tope) {
      final ordenadas = _elegidas.toList()..sort();
      _elegidas
        ..clear()
        ..addAll(ordenadas.take(tope));
    }
  }

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final n = _elegidas.length;
    final total = n * widget.precioFila;
    final ordenadas = _elegidas.toList()..sort();
    final subtitulo =
        _cobra
            ? '${widget.salaNombre} · ${widget.precioFila} por fila · '
                'premio ${widget.premio}'
            : '${widget.salaNombre} · elige las que quieras';
    final nota =
        _sinSaldo
            ? 'Con saldo podrás elegir tu fila'
            : (_cobra
                ? (n == 0
                    ? '${widget.precioFila} créditos por fila'
                    : 'Total: $total créditos'
                        '${widget.saldo == null ? '' : ' · te quedan ${widget.saldo! - total}'}')
                : 'Las filas con candado ya tienen dueño');
    return ColoredBox(
      color: paleta.fondo,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                child: Column(
                  children: [
                    BingEncabezado(
                      titulo: 'Elige tus filas',
                      subtitulo: subtitulo,
                      alVolver: widget.alVolver,
                    ),
                    const SizedBox(height: 10),
                    if (_sinSaldo) ...[
                      BingAviso(
                        icono: 'wallet',
                        destacado: 'Tu saldo es ${widget.saldo} créditos.',
                        texto:
                            'Cada fila cuesta ${widget.precioFila} créditos. '
                            'Recarga para poder elegir.',
                      ),
                      const SizedBox(height: 10),
                    ],
                    for (var i = 0; i < widget.cartillas.length; i++) ...[
                      if (i > 0) const SizedBox(height: 5),
                      BingFilaElegir(
                        indice: i + 1,
                        numeros: widget.cartillas[i],
                        dueno: widget.duenos[i],
                        elegida: _elegidas.contains(i + 1),
                        bloqueada: _sinSaldo,
                        alPresionar: () => _alternar(i + 1),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            BingPie(
              boton:
                  _sinSaldo
                      ? BingBoton(
                        texto: 'Recargar créditos',
                        tipo: BingBotonTipo.dauber,
                        icono: 'wallet',
                        alPresionar: widget.alRecargar,
                      )
                      : BingBoton(
                        texto:
                            n == 0
                                ? 'Elige al menos una fila'
                                : (n == 1
                                    ? 'Seguir con la fila ${ordenadas.first}'
                                    : 'Seguir con $n filas'),
                        tipo: BingBotonTipo.tinta,
                        deshabilitado: n == 0,
                        alPresionar: () => widget.alSeguir?.call(ordenadas),
                      ),
              nota: nota,
            ),
          ],
        ),
      ),
    );
  }
}
