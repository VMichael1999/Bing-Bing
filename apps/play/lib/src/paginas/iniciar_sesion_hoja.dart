import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

/// `jug-09-iniciar-sesion`: hoja que sube al querer elegir una fila sin cuenta.
/// Mirar la sala es libre; para jugar hay que iniciar sesión.
class IniciarSesionHoja extends StatelessWidget {
  const IniciarSesionHoja({
    super.key,
    required this.fondo,
    this.alGoogle,
    this.alCelular,
    this.alAhoraNo,
    this.celularDisponible = true,
    this.error,
  });

  /// Pantalla que queda detrás.
  final Widget fondo;
  final VoidCallback? alGoogle;
  final VoidCallback? alCelular;
  final VoidCallback? alAhoraNo;

  /// Mientras el SMS no esté listo, el botón se ve apagado y dice "Pronto".
  final bool celularDisponible;

  /// Lo que salió mal al iniciar sesión, si algo salió mal.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return BingHoja(
      fondo: fondo,
      alIzquierda: true,
      titulo: 'Inicia sesión para jugar',
      texto:
          'Puedes mirar la sala sin cuenta. Para elegir una fila necesitas '
          'iniciar sesión y tener saldo en tu billetera.',
      children: [
        if (error != null) BingAviso(icono: 'bell', texto: error!),
        Column(
          children: [
            BingBoton(
              texto: 'Continuar con Google',
              tipo: BingBotonTipo.tinta,
              icono: 'mail',
              alPresionar: alGoogle,
            ),
            const SizedBox(height: 8),
            BingBoton(
              texto:
                  celularDisponible
                      ? 'Continuar con celular'
                      : 'Celular · pronto',
              tipo: BingBotonTipo.linea,
              icono: 'phone',
              deshabilitado: !celularDisponible,
              alPresionar: alCelular,
            ),
          ],
        ),
        Semantics(
          button: true,
          label: 'Ahora no',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: alAhoraNo,
            child: ExcludeSemantics(
              child: Center(
                child: Text(
                  'Ahora no',
                  style: BingTexto.figtree(
                    13,
                    700,
                  ).copyWith(color: paleta.apagado),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
