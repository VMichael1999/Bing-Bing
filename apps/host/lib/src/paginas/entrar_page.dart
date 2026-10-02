import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

/// `org-01-entrar`: Google o celular. No hay opción de invitado.
class EntrarPage extends StatefulWidget {
  const EntrarPage({super.key, this.alContinuarConGoogle});

  final VoidCallback? alContinuarConGoogle;

  @override
  State<EntrarPage> createState() => _EntrarPageState();
}

class _EntrarPageState extends State<EntrarPage> {
  final _celular = TextEditingController();

  @override
  void dispose() {
    _celular.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return ColoredBox(
      color: paleta.fondo,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                child: Column(
                  children: [
                    const BingHero(
                      bolillas: [
                        (columna: 0, numero: 3, letra: 'B'),
                        (columna: 1, numero: 22, letra: 'I'),
                        (columna: 2, numero: 41, letra: 'N'),
                        (columna: 3, numero: 53, letra: 'G'),
                        (columna: 4, numero: 70, letra: 'O'),
                      ],
                      texto: 'Organiza bingos con tu familia o tu local',
                    ),
                    const SizedBox(height: 14),
                    BingBoton(
                      texto: 'Continuar con Google',
                      tipo: BingBotonTipo.tinta,
                      icono: 'mail',
                      alPresionar: widget.alContinuarConGoogle,
                    ),
                    const SizedBox(height: 14),
                    BingCampo(
                      controlador: _celular,
                      icono: 'phone',
                      pista: 'Tu número de celular',
                    ),
                  ],
                ),
              ),
            ),
            const BingPie(
              nota: 'Necesitas una cuenta para guardar tus partidas.',
            ),
          ],
        ),
      ),
    );
  }
}
