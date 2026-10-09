import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

/// Lo que se decide en la hoja de cerrar la sala.
typedef CierreDeSala = ({String? motivo});

/// Hoja que pide confirmar antes de cerrar una sala que no se jugó.
///
/// Quien organiza puede decir el motivo; los jugadores lo verán. Se cierra con
/// un [CierreDeSala] si confirma y con `null` si decide seguir esperando.
class CerrarSalaHoja extends StatefulWidget {
  const CerrarSalaHoja({
    super.key,
    required this.ocupadas,
    this.fondo = const SizedBox.shrink(),
    this.alConfirmar,
    this.alSeguir,
  });

  /// Filas que ya tienen jugador: ellos recibirán el aviso.
  final int ocupadas;
  final Widget fondo;
  final ValueChanged<CierreDeSala>? alConfirmar;
  final VoidCallback? alSeguir;

  @override
  State<CerrarSalaHoja> createState() => _CerrarSalaHojaState();
}

class _CerrarSalaHojaState extends State<CerrarSalaHoja> {
  final _motivo = TextEditingController();

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.ocupadas;
    return BingHoja(
      fondo: widget.fondo,
      alIzquierda: true,
      titulo: '¿Cerrar la sala?',
      texto:
          n == 0
              ? 'Nadie más podrá entrar con el código ni con el QR.'
              : 'Nadie más podrá entrar. ${n == 1 ? 'La persona que ya eligió fila verá' : 'Las $n personas que ya eligieron fila verán'} '
                  'que la sala se cerró, y la partida no se juega.',
      children: [
        BingCampo(
          controlador: _motivo,
          icono: 'pen',
          pista: 'Motivo (opcional)',
          maxLargo: 120,
        ),
        Column(
          children: [
            BingBoton(
              texto: 'Sí, cerrar la sala',
              tipo: BingBotonTipo.dauber,
              alPresionar:
                  () => widget.alConfirmar?.call((motivo: _motivo.text.trim())),
            ),
            const SizedBox(height: 8),
            BingBoton(
              texto: 'Seguir esperando',
              tipo: BingBotonTipo.linea,
              alPresionar: widget.alSeguir,
            ),
          ],
        ),
      ],
    );
  }
}
