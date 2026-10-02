import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

import 'src/demo.dart';
import 'src/paginas/entrar_page.dart';
import 'src/paginas/juego_page.dart';
import 'src/paginas/sala_simulada_page.dart';
import 'src/paginas/mis_partidas_page.dart';
import 'src/paginas/nueva_partida_page.dart';

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
        builder: (context, child) => BingSistema(child: child!),
        home: inicio ?? pantallaDemo(_pantallaElegida) ?? const _FlujoDemo(),
      ),
    );
  }
}

/// Recorrido demo completo con datos falsos:
/// entrar → mis partidas → nueva partida → sala (se llena sola) →
/// ¡Cartilla llena! → partida (bolillas a mano o automáticas) → ganador.
class _FlujoDemo extends StatelessWidget {
  const _FlujoDemo();

  void _ir(BuildContext context, WidgetBuilder pantalla, {String? nombre}) =>
      Navigator.of(context).push(
        PageRouteBuilder<void>(
          settings: RouteSettings(name: nombre),
          pageBuilder: (c, _, __) => pantalla(c),
        ),
      );

  void _abrirSala(BuildContext context, String nombre) {
    final sala = SalaSimulada(ocupadasIniciales: 16);
    _ir(
      context,
      (context) => SalaSimuladaPage(
        sala: sala,
        salaNombre: nombre.isEmpty ? salaDemoNombre : nombre,
        alVolver: () => Navigator.of(context).pop(),
        alEmpezar:
            () => _ir(
              context,
              (context) => JuegoPage(
                salaNombre: nombre.isEmpty ? salaDemoNombre : nombre,
                codigo: salaDemoCodigo,
                cartillas: cartillasDemo,
                nombres: jugadoresDemo,
                bolillasIniciales: const [],
                sorteo: sorteoDemo,
                conAutomatico: true,
                alTerminar:
                    () => Navigator.of(
                      context,
                    ).popUntil((r) => r.settings.name == 'mis_partidas'),
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EntrarPage(
      alContinuarConGoogle:
          () => _ir(
            context,
            nombre: 'mis_partidas',
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
                          (nombre, columnas) => _abrirSala(context, nombre),
                    ),
                  ),
            ),
          ),
    );
  }
}
