import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

/// `org-11-compartir`: QR, código y enlace para pasar la sala por WhatsApp o
/// donde sea. "Compartir" abre el menú del sistema.
class CompartirPage extends StatelessWidget {
  const CompartirPage({
    super.key,
    required this.salaNombre,
    required this.codigo,
    this.alVolver,
    this.alCopiarEnlace,
    this.alCompartir,
    this.alPantallaCompleta,
  });

  final String salaNombre;
  final String codigo;
  final VoidCallback? alVolver;
  final VoidCallback? alCopiarEnlace;
  final VoidCallback? alCompartir;
  final VoidCallback? alPantallaCompleta;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final enlace = enlaceSala(codigo);
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
                    BingEncabezado(
                      titulo: 'Comparte tu sala',
                      subtitulo: salaNombre,
                      alVolver: alVolver,
                    ),
                    const SizedBox(height: 12),
                    BingTarjetaQr(
                      datos: enlace,
                      codigo: codigo,
                      leyenda: 'Escanéalo con Bing Bing Play',
                    ),
                    const SizedBox(height: 12),
                    _FilaEnlace(enlace: enlace, alCopiar: alCopiarEnlace),
                  ],
                ),
              ),
            ),
            BingPie(
              boton: BingBoton(
                texto: 'Compartir',
                tipo: BingBotonTipo.dauber,
                icono: 'share',
                alPresionar: alCompartir,
              ),
              botonSecundario: BingBoton(
                texto: 'Mostrar QR a pantalla completa',
                tipo: BingBotonTipo.linea,
                icono: 'qr',
                alPresionar: alPantallaCompleta,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enlace de la sala con el ícono de copiar (`.linkf`).
class _FilaEnlace extends StatelessWidget {
  const _FilaEnlace({required this.enlace, this.alCopiar});

  final String enlace;
  final VoidCallback? alCopiar;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    // El enlace se muestra sin "https://", como en el diseño.
    final visible = enlace.replaceFirst('https://', '');
    return Semantics(
      button: true,
      label: 'Copiar el enlace $visible',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: alCopiar,
        child: ExcludeSemantics(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: paleta.tarjeta,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                BingIcono(
                  'link',
                  color: paleta.apagado,
                  tamano: BingIconoTamano.s,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    visible,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BingTexto.figtree(
                      13,
                      700,
                    ).copyWith(color: paleta.apagado),
                  ),
                ),
                const SizedBox(width: 10),
                BingIcono(
                  'copy',
                  color: paleta.tinta,
                  tamano: BingIconoTamano.s,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
