import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

/// Resumen de una partida guardada de la lista.
typedef PartidaResumen = ({String icono, String titulo, String detalle});

/// `org-02-mis-partidas`: partidas guardadas y el botón "Nueva partida".
class MisPartidasPage extends StatelessWidget {
  const MisPartidasPage({
    super.key,
    required this.organizador,
    required this.partidas,
    this.alNuevaPartida,
    this.alAbrirPartida,
  });

  final String organizador;
  final List<PartidaResumen> partidas;
  final VoidCallback? alNuevaPartida;

  /// Recibe la posición de la partida tocada en [partidas].
  final ValueChanged<int>? alAbrirPartida;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return ColoredBox(
      color: paleta.fondo,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
          child: Column(
            children: [
              BingEncabezado(
                conVolver: false,
                titulo: 'Tus partidas',
                subtitulo: '$organizador · organizadora',
                accion: const BingBotonIcono(
                  icono: 'gear',
                  etiqueta: 'Ajustes',
                ),
              ),
              const SizedBox(height: 12),
              BingBoton(
                texto: 'Nueva partida',
                tipo: BingBotonTipo.dauber,
                icono: 'plus',
                alPresionar: alNuevaPartida,
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < partidas.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                BingItemLista(
                  icono: partidas[i].icono,
                  titulo: partidas[i].titulo,
                  detalle: partidas[i].detalle,
                  alPresionar:
                      alAbrirPartida == null ? null : () => alAbrirPartida!(i),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
