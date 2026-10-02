import 'package:flutter/widgets.dart';

import 'bolilla.dart';
import 'tema.dart';
import 'tipografia.dart';

/// Bolilla de adorno del hero: columna (0 = B), número y letra.
typedef BingBolillaHero = ({int columna, int numero, String letra});

/// Cabecera de marca (`.hero`): bolillas, "Bing Bing" y una frase.
class BingHero extends StatelessWidget {
  const BingHero({
    super.key,
    required this.bolillas,
    required this.texto,
    this.arriba = 26,
  });

  final List<BingBolillaHero> bolillas;
  final String texto;

  /// Relleno superior (`.hero` usa 26; `jug-01` lo baja a 14).
  final double arriba;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(8, arriba, 8, 6),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < bolillas.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                BingBolilla(
                  columna: bolillas[i].columna,
                  numero: bolillas[i].numero,
                  letra: bolillas[i].letra,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Bing Bing',
            textAlign: TextAlign.center,
            style: BingTexto.marca.copyWith(color: paleta.tinta),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 250),
            child: Text(
              texto,
              textAlign: TextAlign.center,
              style: BingTexto.figtree(
                14.5,
                400,
              ).copyWith(color: paleta.apagado),
            ),
          ),
        ],
      ),
    );
  }
}
