import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// `org-12-qr-pantalla`: el QR lo más grande posible para proyectarlo o
/// mostrarlo en la reunión. Mantiene la pantalla encendida mientras está abierta.
class QrPantallaPage extends StatefulWidget {
  const QrPantallaPage({super.key, required this.codigo, this.alCerrar});

  final String codigo;
  final VoidCallback? alCerrar;

  @override
  State<QrPantallaPage> createState() => _QrPantallaPageState();
}

class _QrPantallaPageState extends State<QrPantallaPage> {
  @override
  void initState() {
    super.initState();
    _encendida(true);
  }

  @override
  void dispose() {
    _encendida(false);
    super.dispose();
  }

  /// Sin el plugin (pruebas, plataformas sin soporte) simplemente no hace nada.
  Future<void> _encendida(bool si) async {
    try {
      await (si ? WakelockPlus.enable() : WakelockPlus.disable());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return ColoredBox(
      color: paleta.fondo,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Escanea para entrar',
                      style: BingTexto.tituloPantalla.copyWith(
                        color: paleta.tinta,
                      ),
                    ),
                  ),
                  BingBotonIcono(
                    icono: 'close',
                    etiqueta: 'Cerrar',
                    alPresionar: widget.alCerrar,
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    // 18 dp más de margen que el resto de pantallas (`.full`).
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BingTarjetaQr(
                          datos: enlaceSala(widget.codigo),
                          codigo: widget.codigo,
                          grande: true,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Abre Bing Bing\nPlay y escanea,\no escribe el código',
                          textAlign: TextAlign.center,
                          style: BingTexto.figtree(
                            18,
                            800,
                          ).copyWith(color: paleta.tinta),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
