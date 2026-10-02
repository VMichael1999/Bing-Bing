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
    this.conVolver = true,
    this.accion,
  });

  final String titulo;
  final String subtitulo;
  final VoidCallback? alVolver;

  /// Muestra el botón redondo de volver (no está en `jug-05`).
  final bool conVolver;

  /// Widget alineado a la derecha, por ejemplo el chip "En vivo".
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Row(
      children: [
        if (conVolver)
          BingBotonIcono(
            icono: 'left',
            etiqueta: 'Volver',
            alPresionar: alVolver,
          ),
        if (conVolver) const SizedBox(width: 10),
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
        if (accion != null) ...[const SizedBox(width: 10), accion!],
      ],
    );
  }
}

/// Pie fijo de pantalla (`.foot`): botón principal y una nota debajo.
class BingPie extends StatelessWidget {
  const BingPie({super.key, this.boton, this.nota});

  final Widget? boton;
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
          if (boton != null) boton!,
          if (nota != null) ...[
            if (boton != null) const SizedBox(height: 8),
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

/// Botón redondo de 40 dp con borde (`.icb`).
class BingBotonIcono extends StatelessWidget {
  const BingBotonIcono({
    super.key,
    required this.icono,
    required this.etiqueta,
    this.alPresionar,
  });

  final String icono;
  final String etiqueta;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Semantics(
      button: true,
      label: etiqueta,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: alPresionar,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: paleta.tarjeta,
            border: Border.all(color: paleta.linea),
          ),
          child: BingIcono(icono, color: paleta.tinta),
        ),
      ),
    );
  }
}
