import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

/// `org-05-cartilla-llena`: hoja inferior que sube al reservarse la última fila.
///
/// "Empezar partida" cierra la sala; "Esperar un momento" la deja abierta.
class CartillaLlenaSheet extends StatelessWidget {
  const CartillaLlenaSheet({
    super.key,
    required this.salaNombre,
    required this.total,
    required this.ultimos,
    this.alEmpezar,
    this.alEsperar,
  });

  final String salaNombre;
  final int total;

  /// Últimas filas, que se ven borrosas detrás de la hoja.
  final List<BingJugador> ultimos;
  final VoidCallback? alEmpezar;
  final VoidCallback? alEsperar;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return BingHoja(
      fondo: ColoredBox(
        color: paleta.fondo,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: Column(
              children: [
                BingEncabezado(titulo: salaNombre, subtitulo: 'Sala abierta'),
                const SizedBox(height: 10),
                BingProgreso(
                  ocupadas: total,
                  total: total,
                  texto: 'todas las filas tienen jugador',
                ),
                const SizedBox(height: 10),
                BingListaJugadores(jugadores: ultimos),
              ],
            ),
          ),
        ),
      ),
      titulo: '¡Cartilla llena!',
      texto:
          'Las $total filas tienen jugador y todos ya ven su fila. '
          'Cuando empieces, nadie más podrá entrar.',
      children: [
        SizedBox(
          width: double.infinity,
          child: BingOcupacion(total: total, ocupadas: total),
        ),
        Column(
          children: [
            BingBoton(
              texto: 'Empezar partida',
              tipo: BingBotonTipo.dauber,
              alPresionar: alEmpezar,
            ),
            const SizedBox(height: 8),
            BingBoton(
              texto: 'Esperar un momento',
              tipo: BingBotonTipo.linea,
              alPresionar: alEsperar,
            ),
          ],
        ),
      ],
    );
  }
}
