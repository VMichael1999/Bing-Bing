import 'package:flutter/widgets.dart';

import 'icono.dart';
import 'medidas.dart';
import 'tema.dart';
import 'tipografia.dart';

/// Casillas del código de sala (`.codebox`): 4 columnas, gap 8, alto 62.
///
/// Las casillas con carácter llevan el borde en `tinta` (`.f`).
class BingCasillasCodigo extends StatelessWidget {
  const BingCasillasCodigo({super.key, required this.codigo, this.largo = 4});

  final String codigo;
  final int largo;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Row(
      children: [
        for (var i = 0; i < largo; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: BingMedidas.alturaCasillaCodigo,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: paleta.tarjeta,
                borderRadius: BorderRadius.circular(
                  BingMedidas.radioCasillaCodigo,
                ),
                border: Border.all(
                  color: i < codigo.length ? paleta.tinta : paleta.linea,
                  width: BingMedidas.bordeCasillaCodigo,
                ),
              ),
              child: Text(
                i < codigo.length ? codigo[i] : '',
                style: BingTexto.casillaCodigo.copyWith(color: paleta.tinta),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Tarjeta verde de sala encontrada (`.found`) o de verificación (`.verify`).
class BingEncontrada extends StatelessWidget {
  const BingEncontrada({
    super.key,
    required this.titulo,
    required this.detalle,
  });

  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: paleta.okSuave,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          BingIcono('check', color: paleta.ok),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: BingTexto.figtree(
                    14,
                    800,
                    altura: 1.38,
                  ).copyWith(color: paleta.tinta),
                ),
                const SizedBox(height: 2),
                Text(
                  detalle,
                  style: BingTexto.figtree(
                    12,
                    600,
                    altura: 1.38,
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

/// Separador "o" con una línea a cada lado (`.or`).
class BingSeparadorO extends StatelessWidget {
  const BingSeparadorO({super.key, this.texto = 'o'});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    // Interlineado medido contra la captura del HTML (el separador mide ~15,6 dp).
    final linea = Expanded(child: Container(height: 1, color: paleta.linea));
    return Row(
      children: [
        linea,
        const SizedBox(width: 10),
        Text(
          texto,
          style: BingTexto.figtree(
            12,
            700,
            altura: 1.3,
          ).copyWith(color: paleta.apagado),
        ),
        const SizedBox(width: 10),
        linea,
      ],
    );
  }
}
