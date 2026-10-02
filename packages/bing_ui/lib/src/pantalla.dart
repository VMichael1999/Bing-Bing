import 'package:flutter/widgets.dart';

import 'icono.dart';
import 'medidas.dart';
import 'tema.dart';
import 'tipografia.dart';

/// Encabezado de pantalla (`.top`): botón redondo de volver, título y subtítulo.
class BingEncabezado extends StatelessWidget {
  const BingEncabezado({
    super.key,
    required this.titulo,
    required this.subtitulo,
    this.alVolver,
  });

  final String titulo;
  final String subtitulo;
  final VoidCallback? alVolver;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Volver',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: alVolver,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: paleta.tarjeta,
                border: Border.all(color: paleta.linea),
              ),
              child: BingIcono('left', color: paleta.tinta),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                titulo,
                style: BingTexto.tituloPantalla.copyWith(color: paleta.tinta),
              ),
              Text(
                subtitulo,
                style: BingTexto.subtitulo.copyWith(color: paleta.apagado),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Pie fijo de pantalla (`.foot`): botón principal y una nota debajo.
class BingPie extends StatelessWidget {
  const BingPie({super.key, required this.boton, this.nota});

  final Widget boton;
  final String? nota;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 22),
      decoration: BoxDecoration(
        color: paleta.fondo,
        border: Border(
          top: BorderSide(color: paleta.linea, width: BingMedidas.pieBorde),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          boton,
          if (nota != null) ...[
            const SizedBox(height: 8),
            Text(
              nota!,
              textAlign: TextAlign.center,
              style: BingTexto.subtitulo.copyWith(color: paleta.apagado),
            ),
          ],
        ],
      ),
    );
  }
}
