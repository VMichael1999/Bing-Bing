import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

import 'src/paginas/codigo_page.dart';
import 'src/paginas/elegir_fila_page.dart';

void main() => runApp(const BingPlayApp());

class BingPlayApp extends StatelessWidget {
  const BingPlayApp({super.key, this.inicio});

  /// Pantalla con la que arranca; por defecto, la del código de sala.
  final Widget? inicio;

  @override
  Widget build(BuildContext context) {
    return BingTema(
      paleta: BingPaleta.claro,
      child: WidgetsApp(
        color: BingPaleta.claro.fondo,
        debugShowCheckedModeBanner: false,
        title: 'Bing Bing Play',
        pageRouteBuilder:
            <T>(settings, builder) => PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (context, _, __) => builder(context),
            ),
        home: inicio ?? const _FlujoDemo(),
      ),
    );
  }
}

/// Recorrido en modo demo con los datos del diseño.
class _FlujoDemo extends StatelessWidget {
  const _FlujoDemo();

  @override
  Widget build(BuildContext context) {
    return CodigoPage(
      codigo: salaDemoCodigo,
      salaNombre: salaDemoNombre,
      organizador: salaDemoOrganizador,
      filasLibres: 16,
      alVerFilas:
          () => Navigator.of(context).push(
            PageRouteBuilder<void>(
              pageBuilder:
                  (context, _, __) => ElegirFilaPage(
                    salaNombre: salaDemoNombre,
                    cartillas: cartillasDemo,
                    duenos: filasDemoDuenos,
                    seleccionInicial: 5,
                    alVolver: () => Navigator.of(context).pop(),
                  ),
            ),
          ),
    );
  }
}
