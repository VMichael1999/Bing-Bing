import 'package:flutter/widgets.dart';

import 'medidas.dart';
import 'punto.dart';
import 'tema.dart';
import 'tipografia.dart';

/// Contenedor de la cartilla (`.grid`): fila de cabecera con los puntos de
/// columna y debajo las filas compactas.
class BingCartilla extends StatelessWidget {
  const BingCartilla({super.key, required this.letras, required this.filas});

  /// Texto de cada columna (B-I-N-G-O o 1-6).
  final List<String> letras;
  final List<Widget> filas;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: paleta.tarjeta,
        borderRadius: BorderRadius.circular(BingMedidas.radioTarjeta),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(4, 3, 4, 6),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: paleta.linea)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: BingMedidas.filaIndice,
                  child: Text(
                    '#',
                    textAlign: TextAlign.center,
                    style: BingTexto.figtree(
                      11,
                      700,
                      tabular: true,
                    ).copyWith(color: paleta.apagado),
                  ),
                ),
                for (var i = 0; i < letras.length; i++) ...[
                  const SizedBox(width: BingMedidas.filaGap),
                  SizedBox(
                    width: BingMedidas.filaCelda,
                    child: Center(
                      child: BingPunto(columna: i, texto: letras[i]),
                    ),
                  ),
                ],
                const SizedBox(width: BingMedidas.filaGap),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: Text(
                      'Jugador',
                      style: BingTexto.figtree(
                        11,
                        800,
                      ).copyWith(color: paleta.apagado),
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < filas.length; i++) ...[
            if (i > 0) const SizedBox(height: 2),
            filas[i],
          ],
        ],
      ),
    );
  }
}

/// Bolilla más reciente con su texto (`.trayline`).
class BingUltimaBolilla extends StatelessWidget {
  const BingUltimaBolilla({
    super.key,
    required this.bolilla,
    required this.titulo,
    required this.detalle,
  });

  final Widget bolilla;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: paleta.tarjeta,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          bolilla,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: BingTexto.figtree(
                    15,
                    800,
                  ).copyWith(color: paleta.tinta),
                ),
                Text(
                  detalle,
                  style: BingTexto.figtree(
                    12,
                    600,
                  ).copyWith(color: paleta.apagado),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
