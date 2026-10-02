import 'package:flutter/widgets.dart';

import 'chip.dart';
import 'fila.dart';
import 'tema.dart';
import 'tipografia.dart';

/// Tarjeta de la fila del jugador (`.mine`): título, chip y fila grande, con
/// borde interior de 2 dp en `tinta`.
class BingMiFila extends StatelessWidget {
  const BingMiFila({
    super.key,
    required this.titulo,
    required this.chip,
    required this.numeros,
    required this.salidas,
    required this.letras,
    this.recientes = const {},
  });

  final String titulo;
  final BingChip chip;
  final List<int> numeros;
  final Set<int> salidas;
  final List<String> letras;
  final Set<int> recientes;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: paleta.tarjeta,
        borderRadius: BorderRadius.circular(18),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: paleta.tinta, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: BingTexto.figtree(15, 800).copyWith(color: paleta.tinta),
              ),
              chip,
            ],
          ),
          const SizedBox(height: 10),
          BingFilaGrande(
            numeros: numeros,
            salidas: salidas,
            letras: letras,
            recientes: recientes,
          ),
        ],
      ),
    );
  }
}
