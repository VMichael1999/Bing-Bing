import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

/// Letras de columna con 5 columnas.
const letrasBingo = ['B', 'I', 'N', 'G', 'O'];

/// `jug-03-reservar`: su fila en grande, el nombre y el aviso de bloqueo.
class ReservarPage extends StatefulWidget {
  const ReservarPage({
    super.key,
    required this.salaNombre,
    required this.organizador,
    required this.fila,
    required this.numeros,
    this.nombreInicial = '',
    this.alVolver,
    this.alReservar,
  });

  final String salaNombre;
  final String organizador;

  /// Número de fila (base 1).
  final int fila;
  final List<int> numeros;
  final String nombreInicial;
  final VoidCallback? alVolver;
  final ValueChanged<String>? alReservar;

  @override
  State<ReservarPage> createState() => _ReservarPageState();
}

class _ReservarPageState extends State<ReservarPage> {
  late final TextEditingController _nombre = TextEditingController(
    text: widget.nombreInicial,
  );

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
                      titulo: 'Reserva tu fila',
                      subtitulo: widget.salaNombre,
                      alVolver: widget.alVolver,
                    ),
                    const SizedBox(height: 12),
                    BingMiFila(
                      titulo: 'Fila ${widget.fila}',
                      chip: BingChip('${widget.numeros.length} números'),
                      numeros: widget.numeros,
                      salidas: const {},
                      letras: letrasBingo,
                    ),
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
                    BingAviso(
                      icono: 'lock',
                      texto:
                          'Al reservar, la fila ${widget.fila} queda a tu '
                          'nombre y ya no podrás cambiarla por otra.',
                    ),
                  ],
                ),
              ),
            ),
            BingPie(
              boton: BingBoton(
                texto: 'Reservar fila ${widget.fila}',
                tipo: BingBotonTipo.tinta,
                alPresionar: () => widget.alReservar?.call(_nombre.text.trim()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
