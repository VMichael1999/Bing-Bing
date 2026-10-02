import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

/// `jug-01-codigo`: entrar a una sala con el código o el QR.
class CodigoPage extends StatelessWidget {
  const CodigoPage({
    super.key,
    required this.codigo,
    required this.salaNombre,
    required this.organizador,
    required this.filasLibres,
    this.alVerFilas,
    this.alEscanear,
    this.casillas,
    this.resultado,
    this.verFilasHabilitado = true,
    this.alVolver,
    this.bajoElQr,
  });

  final String codigo;
  final String salaNombre;
  final String organizador;
  final int filasLibres;
  final VoidCallback? alVerFilas;
  final VoidCallback? alEscanear;

  /// Casillas del código; por defecto las del diseño, con [codigo] escrito.
  final Widget? casillas;

  /// Lo que se muestra bajo las casillas; por defecto la sala encontrada.
  final Widget? resultado;
  final bool verFilasHabilitado;

  /// Con él aparece un botón de volver arriba a la izquierda (cuando la pantalla
  /// se abre desde otra); sin él queda idéntica al diseño.
  final VoidCallback? alVolver;

  /// Contenido bajo el botón del QR (las salas abiertas); sin él, el diseño.
  final Widget? bajoElQr;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return ColoredBox(
      color: paleta.fondo,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                    child: Column(
                      children: [
                        const BingHero(
                          arriba: 14,
                          bolillas: [
                            (columna: 0, numero: 9, letra: 'B'),
                            (columna: 1, numero: 30, letra: 'I'),
                            (columna: 2, numero: 38, letra: 'N'),
                          ],
                          texto: 'Escribe el código que te dio quien organiza',
                        ),
                        const SizedBox(height: 14),
                        casillas ?? BingCasillasCodigo(codigo: codigo),
                        const SizedBox(height: 14),
                        resultado ??
                            BingEncontrada(
                              titulo: salaNombre,
                              detalle:
                                  'Organiza $organizador · quedan $filasLibres '
                                  'filas libres',
                            ),
                        const SizedBox(height: 14),
                        const BingSeparadorO(),
                        const SizedBox(height: 14),
                        BingBoton(
                          texto: 'Escanear el QR',
                          tipo: BingBotonTipo.linea,
                          icono: 'qr',
                          alPresionar: alEscanear,
                        ),
                        if (bajoElQr != null) ...[
                          const SizedBox(height: 22),
                          bajoElQr!,
                        ],
                      ],
                    ),
                  ),
                  if (alVolver != null)
                    Positioned(
                      left: 14,
                      top: 4,
                      child: BingBotonIcono(
                        icono: 'left',
                        etiqueta: 'Volver',
                        alPresionar: alVolver,
                      ),
                    ),
                ],
              ),
            ),
            BingPie(
              boton: BingBoton(
                texto: 'Ver filas libres',
                tipo: BingBotonTipo.tinta,
                deshabilitado: !verFilasHabilitado,
                alPresionar: alVerFilas,
              ),
              nota: 'Sin cuenta. Tu nombre lo pones al elegir la fila.',
            ),
          ],
        ),
      ),
    );
  }
}
