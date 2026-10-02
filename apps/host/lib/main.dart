import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

import 'src/demo.dart';
import 'src/paginas/entrar_page.dart';
import 'src/paginas/mis_partidas_page.dart';
import 'src/paginas/nueva_partida_page.dart';
import 'src/paginas/sala_abierta_page.dart';

/// Abre una pantalla del diseño directamente:
/// `--dart-define=BING_PANTALLA=org-06-bolilla`.
const _pantallaElegida = String.fromEnvironment('BING_PANTALLA');

void main() => runApp(const BingHostApp());

class BingHostApp extends StatelessWidget {
  const BingHostApp({super.key, this.inicio});

  /// Pantalla con la que arranca; por defecto, el recorrido demo.
  final Widget? inicio;

  @override
  Widget build(BuildContext context) {
    return BingTema(
      paleta: BingPaleta.oscuro,
      child: WidgetsApp(
        color: BingPaleta.oscuro.fondo,
        debugShowCheckedModeBanner: false,
        title: 'Bing Bing Host',
        pageRouteBuilder:
            <T>(settings, builder) => PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (context, _, __) => builder(context),
            ),
        home: inicio ?? pantallaDemo(_pantallaElegida) ?? const _FlujoDemo(),
      ),
    );
  }
}

/// Recorrido demo: entrar → mis partidas → nueva partida → sala abierta.
class _FlujoDemo extends StatelessWidget {
  const _FlujoDemo();

  void _ir(BuildContext context, WidgetBuilder pantalla) => Navigator.of(
    context,
  ).push(PageRouteBuilder<void>(pageBuilder: (c, _, __) => pantalla(c)));

  @override
  Widget build(BuildContext context) {
    return EntrarPage(
      alContinuarConGoogle:
          () => _ir(
            context,
            (context) => MisPartidasPage(
              organizador: 'Carmen',
              partidas: partidasDemo,
              alNuevaPartida:
                  () => _ir(
                    context,
                    (context) => NuevaPartidaPage(
                      nombreInicial: salaDemoNombre,
                      alVolver: () => Navigator.of(context).pop(),
                      alAbrirSala:
                          (nombre, columnas) => _ir(
                            context,
                            (context) => SalaAbiertaPage(
                              salaNombre:
                                  nombre.isEmpty ? salaDemoNombre : nombre,
                              codigo: salaDemoCodigo,
                              ocupadas: 17,
                              total: 20,
                              jugadores: jugadoresSalaAbiertaDemo(),
                              alVolver: () => Navigator.of(context).pop(),
                            ),
                          ),
                    ),
                  ),
            ),
          ),
    );
  }
}
