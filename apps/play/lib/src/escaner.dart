import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'paginas/escaner_page.dart';

/// Cámara que lee el QR de una sala.
///
/// Cada QR válido se entrega a [alLeer] con el código de la sala. Si devuelve un
/// texto es un motivo por el que no se pudo entrar y se muestra como aviso; si
/// devuelve `null`, quien llama ya cambió de pantalla. [camara] sustituye a la
/// cámara real (pruebas): recibe una función a la que pasar cada texto leído.
class EscanerReal extends StatefulWidget {
  const EscanerReal({
    super.key,
    required this.alLeer,
    required this.alEscribir,
    this.camara,
  });

  final Future<String?> Function(String codigo) alLeer;
  final VoidCallback alEscribir;
  final Widget Function(BuildContext context, ValueChanged<String> alLeerTexto)?
  camara;

  @override
  State<EscanerReal> createState() => _EscanerRealState();
}

class _EscanerRealState extends State<EscanerReal> with WidgetsBindingObserver {
  MobileScannerController? _controlador;
  bool _leyendo = false;
  DateTime _ultimoAviso = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.camara == null) {
      _controlador = MobileScannerController(
        formats: const [BarcodeFormat.qrCode],
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controlador?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    // Al volver de los ajustes con el permiso dado, la cámara arranca de nuevo.
    final controlador = _controlador;
    if (estado == AppLifecycleState.resumed &&
        controlador != null &&
        controlador.value.error != null) {
      unawaited(controlador.start());
    }
  }

  void _avisar(String texto) {
    final ahora = DateTime.now();
    if (ahora.difference(_ultimoAviso) < const Duration(seconds: 3)) return;
    _ultimoAviso = ahora;
    mostrarAvisoBing(context, texto);
  }

  Future<void> _alLeerTexto(String texto) async {
    if (_leyendo) return;
    final codigo = codigoDeEnlace(texto);
    if (codigo == null) {
      _avisar('Ese QR no es de una sala de Bing Bing');
      return;
    }
    _leyendo = true;
    final motivo = await widget.alLeer(codigo);
    if (!mounted) return;
    if (motivo != null) {
      _avisar(motivo);
      // Se deja pasar un momento para no repetir el aviso con el mismo QR.
      await Future<void>.delayed(const Duration(seconds: 2));
      _leyendo = false;
    }
  }

  void _alDetectar(BarcodeCapture captura) {
    for (final b in captura.barcodes) {
      final texto = b.rawValue;
      if (texto != null) {
        unawaited(_alLeerTexto(texto));
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controlador = _controlador;
    if (controlador == null) {
      return EscanerPage(
        camara: widget.camara!(context, (t) => unawaited(_alLeerTexto(t))),
        alEscribir: widget.alEscribir,
        alVolver: () => Navigator.of(context).pop(),
      );
    }
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: controlador,
      builder: (context, estado, _) {
        final error = estado.error;
        if (error?.errorCode == MobileScannerErrorCode.permissionDenied) {
          return CamaraDenegadaPage(
            alAbrirAjustes: () => unawaited(AppSettings.openAppSettings()),
            alEscribir: widget.alEscribir,
            alVolver: () => Navigator.of(context).pop(),
          );
        }
        return EscanerPage(
          camara: MobileScanner(
            controller: controlador,
            onDetect: _alDetectar,
            errorBuilder: (context, _, __) => const SizedBox.shrink(),
          ),
          linternaEncendida: estado.torchState == TorchState.on,
          alLinterna:
              estado.torchState == TorchState.unavailable
                  ? null
                  : () => unawaited(controlador.toggleTorch()),
          alEscribir: widget.alEscribir,
          alVolver: () => Navigator.of(context).pop(),
        );
      },
    );
  }
}
