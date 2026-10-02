import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

import 'src/paginas/entrar_page.dart';
import 'src/paginas/mis_partidas_page.dart';
import 'src/paginas/nueva_partida_page.dart';

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
        home: inicio ?? const _FlujoDemo(),
      ),
    );
  }
}

/// Partidas guardadas del modo demo.
const partidasDemo = <PartidaResumen>[
  (
    icono: 'cal',
    titulo: 'Bingo de los sábados',
    detalle: 'Hoy 21:00 · borrador · 0 jugadores',
  ),
  (
    icono: 'trophy',
    titulo: 'Bingo de los sábados',
    detalle: '26 set · 20 jugadores · ganó Kiara',
  ),
  (
    icono: 'trophy',
    titulo: 'Cumpleaños de Pilar',
    detalle: '19 set · 14 jugadores · ganó Renzo',
  ),
];

/// Recorrido demo: entrar → mis partidas → nueva partida.
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
                      nombreInicial: 'Bingo de los sábados',
                      alVolver: () => Navigator.of(context).pop(),
                    ),
                  ),
            ),
          ),
    );
  }
}
