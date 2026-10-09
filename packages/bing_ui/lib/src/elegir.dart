import 'package:flutter/widgets.dart';

import 'icono.dart';
import 'tema.dart';
import 'tipografia.dart';

/// Fila elegible de la pantalla "Elige tu fila" (`.pick`).
///
/// Tomada: opacidad 0.5, candado y nombre del dueño. Elegida: borde interior
/// de 2 dp `dauber` y la palabra "Elegida". Libre: "Libre".
class BingFilaElegir extends StatelessWidget {
  const BingFilaElegir({
    super.key,
    required this.indice,
    required this.numeros,
    this.dueno,
    this.elegida = false,
    this.bloqueada = false,
    this.alPresionar,
  });

  final int indice;
  final List<int> numeros;

  /// Nombre de quien la reservó; `null` si está libre.
  final String? dueno;
  final bool elegida;

  /// Está libre pero no se puede elegir (por ejemplo, sin saldo): se ve apagada.
  final bool bloqueada;
  final VoidCallback? alPresionar;

  bool get tomada => dueno != null;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final colorEstado = elegida ? paleta.dauber : paleta.apagado;
    final fila = Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: paleta.tarjeta,
        borderRadius: BorderRadius.circular(12),
      ),
      foregroundDecoration:
          elegida
              ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: paleta.dauber, width: 2),
              )
              : null,
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$indice',
              textAlign: TextAlign.center,
              style: BingTexto.figtree(
                11,
                700,
                tabular: true,
              ).copyWith(color: paleta.apagado),
            ),
          ),
          for (final n in numeros) ...[
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: paleta.suave,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$n',
                  style: BingTexto.figtree(
                    13,
                    800,
                    tabular: true,
                  ).copyWith(color: paleta.tinta),
                ),
              ),
            ),
          ],
          const SizedBox(width: 4),
          SizedBox(
            width: 74,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (tomada) ...[
                  BingIcono(
                    'lock',
                    color: colorEstado,
                    tamano: BingIconoTamano.xs,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    tomada ? dueno! : (elegida ? 'Elegida' : 'Libre'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BingTexto.figtree(
                      11.5,
                      800,
                    ).copyWith(color: colorEstado),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: !tomada && !bloqueada,
      selected: elegida,
      label: 'Fila $indice, ${tomada ? 'de $dueno' : 'libre'}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tomada || bloqueada ? null : alPresionar,
        child: Opacity(
          opacity: tomada ? 0.5 : (bloqueada ? 0.55 : 1),
          child: ExcludeSemantics(child: fila),
        ),
      ),
    );
  }
}
