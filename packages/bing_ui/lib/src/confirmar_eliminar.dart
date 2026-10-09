import 'package:flutter/widgets.dart';

import 'boton.dart';
import 'hoja.dart';

/// Hoja que pide confirmar antes de borrar la cuenta. Se cierra con `true` si
/// la persona confirma y con `false` si cancela.
class BingConfirmarEliminar extends StatelessWidget {
  const BingConfirmarEliminar({
    super.key,
    this.fondo = const SizedBox.shrink(),
    this.alConfirmar,
    this.alCancelar,
  });

  final Widget fondo;
  final VoidCallback? alConfirmar;
  final VoidCallback? alCancelar;

  @override
  Widget build(BuildContext context) {
    return BingHoja(
      fondo: fondo,
      alIzquierda: true,
      titulo: '¿Eliminar tu cuenta?',
      texto:
          'Se borran tu cuenta y tus datos. Esto no se puede deshacer. Las '
          'filas que ya reservaste dejarán de estar a tu nombre.',
      children: [
        Column(
          children: [
            BingBoton(
              texto: 'Sí, eliminar mi cuenta',
              tipo: BingBotonTipo.dauber,
              alPresionar: alConfirmar,
            ),
            const SizedBox(height: 8),
            BingBoton(
              texto: 'Cancelar',
              tipo: BingBotonTipo.linea,
              alPresionar: alCancelar,
            ),
          ],
        ),
      ],
    );
  }
}
