import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

/// `org-04-sala-abierta`: código y QR, progreso y quién reservó cada fila.
///
/// No hay campos para escribir nombres: el organizador ve en vivo las
/// reservas y el botón de empezar espera a que se llene la cartilla.
class SalaAbiertaPage extends StatelessWidget {
  const SalaAbiertaPage({
    super.key,
    required this.salaNombre,
    required this.codigo,
    required this.ocupadas,
    required this.total,
    required this.jugadores,
    this.alVolver,
    this.alCompartir,
    this.alCopiar,
    this.alEmpezar,
  });

  final String salaNombre;
  final String codigo;
  final int ocupadas;
  final int total;
  final List<BingJugador> jugadores;
  final VoidCallback? alVolver;
  final VoidCallback? alCompartir;
  final VoidCallback? alCopiar;

  /// Con la cartilla llena el botón pasa a "Empezar partida" (estado que el
  /// diseño no muestra: solo enseña la hoja `org-05`).
  final VoidCallback? alEmpezar;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final faltan = total - ocupadas;
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
                      titulo: salaNombre,
                      subtitulo: 'Sala abierta · los jugadores eligen su fila',
                      alVolver: alVolver,
                    ),
                    const SizedBox(height: 10),
                    BingCodigoSala(
                      codigo: codigo,
                      alCompartir: alCompartir,
                      alCopiar: alCopiar,
                    ),
                    const SizedBox(height: 10),
                    BingProgreso(
                      ocupadas: ocupadas,
                      total: total,
                      texto:
                          faltan == 1
                              ? 'falta 1 jugador'
                              : 'faltan $faltan jugadores',
                    ),
                    const SizedBox(height: 10),
                    BingListaJugadores(jugadores: jugadores),
                  ],
                ),
              ),
            ),
            BingPie(
              boton:
                  faltan == 0 && alEmpezar != null
                      ? BingBoton(
                        texto: 'Empezar partida',
                        tipo: BingBotonTipo.dauber,
                        alPresionar: alEmpezar,
                      )
                      : BingBoton(
                        texto:
                            faltan == 1
                                ? 'Esperando a 1 jugador'
                                : 'Esperando a $faltan jugadores',
                        tipo: BingBotonTipo.linea,
                        deshabilitado: true,
                      ),
              nota:
                  faltan == 0
                      ? 'Las $total filas ya tienen jugador'
                      : 'Cuando se llenen las $total filas te avisamos para empezar',
            ),
          ],
        ),
      ),
    );
  }
}
