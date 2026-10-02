import 'package:flutter/widgets.dart';

import 'icono.dart';
import 'tema.dart';
import 'tipografia.dart';

/// Selector de dos o más opciones (`.seg`). La activa va sobre fondo de tarjeta.
///
/// Las opciones en [bloqueadas] se muestran pero no se pueden elegir.
class BingSegmento extends StatelessWidget {
  const BingSegmento({
    super.key,
    required this.opciones,
    required this.seleccion,
    this.alCambiar,
    this.bloqueadas = const {},
  });

  final List<String> opciones;
  final int seleccion;
  final ValueChanged<int>? alCambiar;
  final Set<int> bloqueadas;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: paleta.suave,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < opciones.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == seleccion,
                enabled: !bloqueadas.contains(i),
                label: opciones[i],
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap:
                      bloqueadas.contains(i) ? null : () => alCambiar?.call(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == seleccion ? paleta.tarjeta : null,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow:
                          i == seleccion
                              ? const [
                                BoxShadow(
                                  color: Color(0x1F000000),
                                  offset: Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ]
                              : null,
                    ),
                    child: ExcludeSemantics(
                      child: Text(
                        opciones[i],
                        style: BingTexto.figtree(13, 800).copyWith(
                          color: i == seleccion ? paleta.tinta : paleta.apagado,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Elemento de lista con ícono, título, detalle y flecha (`.list .it`).
class BingItemLista extends StatelessWidget {
  const BingItemLista({
    super.key,
    required this.icono,
    required this.titulo,
    required this.detalle,
    this.alPresionar,
  });

  final String icono;
  final String titulo;
  final String detalle;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Semantics(
      button: true,
      label: '$titulo. $detalle',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: alPresionar,
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: paleta.tarjeta,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                BingIcono(icono, color: paleta.tinta),
                const SizedBox(width: 10),
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
                        ).copyWith(color: paleta.tinta),
                      ),
                      // `<small>` es inline: su línea toma el interlineado del
                      // padre (14 px × 1.38), no el propio.
                      Text(
                        detalle,
                        strutStyle: const StrutStyle(
                          fontFamily: 'Figtree',
                          package: 'bing_ui',
                          fontSize: 14,
                          height: BingTexto.alturaBase,
                          leadingDistribution: TextLeadingDistribution.even,
                          forceStrutHeight: true,
                        ),
                        style: BingTexto.figtree(
                          12,
                          600,
                        ).copyWith(color: paleta.apagado),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                BingIcono(
                  'right',
                  color: paleta.tinta,
                  tamano: BingIconoTamano.s,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
