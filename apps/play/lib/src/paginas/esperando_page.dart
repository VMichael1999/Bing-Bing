import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

import 'reservar_page.dart';

/// `jug-04-esperando`: reserva confirmada y cuánto falta para llenar la sala.
class EsperandoPage extends StatelessWidget {
  const EsperandoPage({
    super.key,
    required this.nombre,
    required this.salaNombre,
    required this.organizador,
    required this.filas,
    required this.cartillas,
    required this.ocupadas,
    required this.total,
  });

  final String nombre;
  final String salaNombre;
  final String organizador;

  /// Filas reservadas (base 1) y sus números, en el mismo orden.
  final List<int> filas;
  final List<List<int>> cartillas;
  final int ocupadas;
  final int total;

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
              BingEncontrada(
                titulo:
                    filas.length == 1
                        ? 'Tu fila está reservada'
                        : 'Tus filas están reservadas',
                detalle:
                    filas.length == 1
                        ? '$nombre · fila ${filas.first} · $salaNombre'
                        : '$nombre · filas ${listaDeFilas(filas)} · $salaNombre',
              ),
              for (var i = 0; i < filas.length; i++) ...[
                const SizedBox(height: 12),
                BingMiFila(
                  titulo: 'Tu fila · la ${filas[i]}',
                  chip: const BingChip('Reservada', icono: 'lock'),
                  numeros: cartillas[i],
                  salidas: const {},
                  letras: letrasBingo,
                ),
              ],
              const SizedBox(height: 12),
              BingProgreso(
                ocupadas: ocupadas,
                total: total,
                texto: 'esperando que se llene la cartilla',
                conCirculos: true,
              ),
              const SizedBox(height: 12),
              BingSeccion(
                espacio: 4,
                children: [
                  Text(
                    'La partida empieza cuando $organizador la inicie',
                    style: BingTexto.figtree(
                      13.5,
                      800,
                    ).copyWith(color: paleta.tinta),
                  ),
                  Text(
                    'Puedes cerrar la app: te avisaremos con una notificación.',
                    style: BingTexto.figtree(
                      12.5,
                      400,
                    ).copyWith(color: paleta.apagado),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
