import 'package:flutter/widgets.dart';

import 'icono.dart';
import 'tema.dart';
import 'tipografia.dart';

/// Una pestaña de la barra inferior.
typedef BingPestana = ({String icono, String texto});

/// Barra de pestañas inferior (`.tabs`): la activa lleva una píldora de
/// 52 × 28 dp y el texto en `tinta`.
class BingTabs extends StatelessWidget {
  const BingTabs({
    super.key,
    required this.pestanas,
    required this.activa,
    required this.alCambiar,
  });

  final List<BingPestana> pestanas;
  final int activa;
  final ValueChanged<int> alCambiar;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 7, 6, 20),
      decoration: BoxDecoration(
        color: paleta.tarjeta,
        border: Border(top: BorderSide(color: paleta.linea)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < pestanas.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == activa,
                label: pestanas[i].texto,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => alCambiar(i),
                  child: ExcludeSemantics(
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i == activa ? paleta.suave : null,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: BingIcono(
                            pestanas[i].icono,
                            color: i == activa ? paleta.tinta : paleta.apagado,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pestanas[i].texto,
                          style: BingTexto.figtree(11, 700).copyWith(
                            color: i == activa ? paleta.tinta : paleta.apagado,
                          ),
                        ),
                      ],
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
