import 'package:flutter/widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'tipografia.dart';

const _tinta = Color(0xFF181C33);
const _apagado = Color(0xFF59607A);
const _blanco = Color(0xFFFFFFFF);

/// Tarjeta blanca con el QR de la sala, su código y una leyenda (`.qrcard`).
///
/// Es blanca en los dos temas porque un QR sobre fondo oscuro no se lee bien.
/// Con [grande] el QR ocupa todo el ancho, para proyectarlo.
class BingTarjetaQr extends StatelessWidget {
  const BingTarjetaQr({
    super.key,
    required this.datos,
    required this.codigo,
    this.leyenda,
    this.grande = false,
  });

  /// Lo que codifica el QR (el enlace de la sala).
  final String datos;
  final String codigo;
  final String? leyenda;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final qr = QrImageView(
      data: datos,
      padding: EdgeInsets.zero,
      backgroundColor: _blanco,
      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: _tinta),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: _tinta,
      ),
    );
    return Semantics(
      label: 'Código QR de la sala $codigo',
      image: true,
      child: Container(
        width: double.infinity,
        padding:
            grande
                ? const EdgeInsets.symmetric(horizontal: 18, vertical: 20)
                : const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _blanco,
          borderRadius: BorderRadius.circular(grande ? 26 : 22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (grande)
              AspectRatio(aspectRatio: 1, child: qr)
            else
              SizedBox(width: 196, height: 196, child: qr),
            const SizedBox(height: 6),
            Text(
              codigo,
              style: BingTexto.bungee(
                grande ? 50 : 32,
                altura: 1,
                espaciado: (grande ? 50 : 32) * 0.1,
              ).copyWith(color: _tinta),
            ),
            if (leyenda != null) ...[
              const SizedBox(height: 6),
              Text(
                leyenda!,
                textAlign: TextAlign.center,
                style: BingTexto.figtree(12, 700).copyWith(color: _apagado),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
