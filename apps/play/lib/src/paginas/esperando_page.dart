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
    required this.fila,
    required this.numeros,
    required this.ocupadas,
    required this.total,
  });

  final String nombre;
  final String salaNombre;
  final String organizador;
  final int fila;
  final List<int> numeros;
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
                titulo: 'Tu fila está reservada',
                detalle: '$nombre · fila $fila · $salaNombre',
              ),
              const SizedBox(height: 12),
              BingMiFila(
                titulo: 'Tu fila · la $fila',
                chip: const BingChip('Reservada', icono: 'lock'),
                numeros: numeros,
                salidas: const {},
                letras: letrasBingo,
              ),
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
