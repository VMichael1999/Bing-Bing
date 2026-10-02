import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import 'paginas/compartir_page.dart';
import 'paginas/qr_pantalla_page.dart';

/// Abre la hoja de compartir de una sala con el portapapeles y el menú del
/// sistema de verdad. Sirve igual para la sala real y para la demo.
void abrirCompartirSala(
  BuildContext context, {
  required String nombre,
  required String codigo,
}) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      pageBuilder:
          (contexto, _, __) => CompartirPage(
            salaNombre: nombre,
            codigo: codigo,
            alVolver: () => Navigator.of(contexto).pop(),
            alCopiarEnlace: () async {
              await Clipboard.setData(ClipboardData(text: enlaceSala(codigo)));
              if (contexto.mounted) {
                mostrarAvisoBing(contexto, 'Enlace copiado');
              }
            },
            alCompartir:
                () => Share.share(
                  textoCompartirSala(nombre: nombre, codigo: codigo),
                ),
            alPantallaCompleta:
                () => Navigator.of(contexto).push(
                  PageRouteBuilder<void>(
                    pageBuilder:
                        (c, _, __) => QrPantallaPage(
                          codigo: codigo,
                          alCerrar: () => Navigator.of(c).pop(),
                        ),
                  ),
                ),
          ),
    ),
  );
}
