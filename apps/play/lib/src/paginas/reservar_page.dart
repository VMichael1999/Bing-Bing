import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

/// Letras de columna con 5 columnas.
const letrasBingo = ['B', 'I', 'N', 'G', 'O'];

/// "5", "5 y 6" o "5, 6 y 7".
String listaDeFilas(List<int> filas) {
  final f = [...filas]..sort();
  if (f.length == 1) return '${f.first}';
  return '${f.take(f.length - 1).join(', ')} y ${f.last}';
}

/// `jug-03-reservar`: sus filas en grande, el nombre y el aviso de bloqueo.
class ReservarPage extends StatefulWidget {
  const ReservarPage({
    super.key,
    required this.salaNombre,
    required this.organizador,
    required this.filas,
    required this.cartillas,
    this.precioFila = 0,
    this.saldo,
    this.nombreInicial = '',
    this.alVolver,
    this.alReservar,
    this.error,
    this.reservando = false,
  });

  final String salaNombre;
  final String organizador;

  /// Filas elegidas (base 1) y sus números, en el mismo orden.
  final List<int> filas;
  final List<List<int>> cartillas;

  /// Créditos que cuesta cada fila; 0 si la partida es gratis.
  final int precioFila;

  /// Créditos de la persona, si se sabe, para decir cuántos le quedan.
  final int? saldo;
  final String nombreInicial;
  final VoidCallback? alVolver;
  final ValueChanged<String>? alReservar;

  /// Por qué falló la reserva, si falló.
  final String? error;
  final bool reservando;

  @override
  State<ReservarPage> createState() => _ReservarPageState();
}

class _ReservarPageState extends State<ReservarPage> {
  late final TextEditingController _nombre = TextEditingController(
    text: widget.nombreInicial,
  );

  bool get _varias => widget.filas.length > 1;
  int get _total => widget.filas.length * widget.precioFila;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
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
                      titulo: _varias ? 'Reserva tus filas' : 'Reserva tu fila',
                      subtitulo: widget.salaNombre,
                      alVolver: widget.alVolver,
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < widget.filas.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      BingMiFila(
                        titulo: 'Fila ${widget.filas[i]}',
                        chip: BingChip('${widget.cartillas[i].length} números'),
                        numeros: widget.cartillas[i],
                        salidas: const {},
                        letras: letrasBingo,
                      ),
                    ],
                    const SizedBox(height: 12),
                    BingSeccion(
                      cabecera: '¿CÓMO TE VEN LOS DEMÁS?',
                      children: [
                        BingCampo(
                          controlador: _nombre,
                          icono: 'user',
                          autofoco: true,
                        ),
                        Text(
                          'Este nombre aparece en la cartilla de todos y en '
                          'la pantalla de ${widget.organizador}.',
                          style: BingTexto.figtree(
                            12,
                            600,
                          ).copyWith(color: paleta.apagado),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.precioFila > 0) ...[
                      BingAviso(
                        icono: 'wallet',
                        destacado: 'Total: $_total créditos.',
                        texto:
                            widget.saldo == null
                                ? 'Se descuentan de tu billetera.'
                                : 'Se descuentan de tu billetera y te '
                                    'quedan ${widget.saldo! - _total}.',
                      ),
                      const SizedBox(height: 12),
                    ],
                    BingAviso(
                      icono: 'lock',
                      texto:
                          _varias
                              ? 'Al reservar, las filas ${listaDeFilas(widget.filas)} '
                                  'quedan a tu nombre y ya no podrás cambiarlas '
                                  'por otras.'
                              : 'Al reservar, la fila ${widget.filas.first} '
                                  'queda a tu nombre y ya no podrás cambiarla '
                                  'por otra.',
                    ),
                    if (widget.error != null) ...[
                      const SizedBox(height: 12),
                      BingAviso(icono: 'bell', texto: widget.error!),
                    ],
                  ],
                ),
              ),
            ),
            BingPie(
              boton: BingBoton(
                texto:
                    _varias
                        ? 'Reservar ${widget.filas.length} filas'
                        : 'Reservar fila ${widget.filas.first}',
                tipo: BingBotonTipo.tinta,
                deshabilitado: widget.reservando,
                alPresionar: () => widget.alReservar?.call(_nombre.text.trim()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
