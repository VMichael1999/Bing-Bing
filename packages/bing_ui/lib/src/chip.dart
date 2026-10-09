import 'package:flutter/widgets.dart';

import 'icono.dart';
import 'tema.dart';
import 'tipografia.dart';

/// Variantes del chip (`.chip`, `.chip.live`, `.chip.ok`, `.chip.soon`).
enum BingChipTipo { normal, vivo, ok, pronto }

/// Etiqueta de 26 dp de alto con radio 8.
class BingChip extends StatelessWidget {
  const BingChip(
    this.texto, {
    super.key,
    this.tipo = BingChipTipo.normal,
    this.icono,
  });

  final String texto;
  final BingChipTipo tipo;

  /// Nombre de un ícono `xs` a la izquierda del texto.
  final String? icono;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final (fondo, color) = switch (tipo) {
      BingChipTipo.normal => (paleta.suave, paleta.apagado),
      BingChipTipo.vivo => (paleta.dauber, paleta.dauberTinta),
      BingChipTipo.ok => (paleta.okSuave, paleta.ok),
      BingChipTipo.pronto => (paleta.cercaSuave, paleta.cerca),
    };
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tipo == BingChipTipo.vivo) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          if (icono != null) ...[
            BingIcono(icono!, color: color, tamano: BingIconoTamano.xs),
            const SizedBox(width: 5),
          ],
          Text(texto, style: BingTexto.chip.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// Aviso amarillo con candado u otro ícono (`.warn`).
class BingAviso extends StatelessWidget {
  const BingAviso({
    super.key,
    required this.icono,
    required this.texto,
    this.destacado,
  });

  final String icono;
  final String texto;

  /// Frase en negrita al empezar el aviso ("Tu saldo es 0 créditos.").
  final String? destacado;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: paleta.cercaSuave,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BingIcono(icono, color: paleta.cerca),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (destacado != null)
                    TextSpan(
                      text: '$destacado ',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  TextSpan(text: texto),
                ],
              ),
              style: BingTexto.figtree(13, 600).copyWith(color: paleta.tinta),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta con cabecera en mayúsculas (`.sec`).
class BingSeccion extends StatelessWidget {
  const BingSeccion({
    super.key,
    this.cabecera,
    required this.children,
    this.espacio = 9,
  });

  final String? cabecera;
  final List<Widget> children;
  final double espacio;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final hijos = [
      if (cabecera != null)
        Text(
          cabecera!,
          style: BingTexto.cabeceraSeccion.copyWith(color: paleta.apagado),
        ),
      ...children,
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: paleta.tarjeta,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < hijos.length; i++) ...[
            if (i > 0) SizedBox(height: espacio),
            hijos[i],
          ],
        ],
      ),
    );
  }
}
