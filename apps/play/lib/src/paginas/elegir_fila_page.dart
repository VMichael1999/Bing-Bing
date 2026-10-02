import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

/// `jug-02-elegir-fila`: el jugador elige una fila libre.
class ElegirFilaPage extends StatefulWidget {
  const ElegirFilaPage({
    super.key,
    required this.salaNombre,
    required this.cartillas,
    required this.duenos,
    required this.seleccionInicial,
    this.alVolver,
    this.alSeguir,
  });

  final String salaNombre;
  final List<List<int>> cartillas;

  /// Dueño de cada fila (misma longitud que [cartillas]); `null` si está libre.
  final List<String?> duenos;

  /// Fila elegida al abrir (base 1).
  final int seleccionInicial;
  final VoidCallback? alVolver;
  final ValueChanged<int>? alSeguir;

  @override
  State<ElegirFilaPage> createState() => _ElegirFilaPageState();
}

class _ElegirFilaPageState extends State<ElegirFilaPage> {
  late int _elegida = widget.seleccionInicial;

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
                      titulo: 'Elige tu fila',
                      subtitulo: '${widget.salaNombre} · puedes elegir 1',
                      alVolver: widget.alVolver,
                    ),
                    const SizedBox(height: 10),
                    for (var i = 0; i < widget.cartillas.length; i++) ...[
                      if (i > 0) const SizedBox(height: 5),
                      BingFilaElegir(
                        indice: i + 1,
                        numeros: widget.cartillas[i],
                        dueno: widget.duenos[i],
                        elegida: _elegida == i + 1,
                        alPresionar: () => setState(() => _elegida = i + 1),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            BingPie(
              boton: BingBoton(
                texto: 'Seguir con la fila $_elegida',
                tipo: BingBotonTipo.tinta,
                alPresionar: () => widget.alSeguir?.call(_elegida),
              ),
              nota: 'Las filas con candado ya tienen dueño',
            ),
          ],
        ),
      ),
    );
  }
}
