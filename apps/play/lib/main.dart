import 'package:bing_core/bing_core.dart';
import 'package:bing_firebase/bing_firebase.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

import 'src/demo.dart';
import 'src/paginas/codigo_page.dart';
import 'src/paginas/elegir_fila_page.dart';
import 'src/paginas/esperando_simulada_page.dart';
import 'src/paginas/reservar_page.dart';

/// Abre una pantalla del diseño directamente:
/// `--dart-define=BING_PANTALLA=jug-05-en-vivo`.
const _pantallaElegida = String.fromEnvironment('BING_PANTALLA');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Sin los valores de .env (ver .env.example) sigue el modo demostración.
  await iniciarFirebase(AppBing.play);
  runApp(const BingPlayApp());
}

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
        builder: (context, child) => BingSistema(child: child!),
        home: inicio ?? pantallaDemo(_pantallaElegida) ?? const _FlujoDemo(),
      ),
    );
  }
}

/// Recorrido demo completo con datos falsos:
/// código → elegir fila → reservar → esperando (la sala se llena sola) →
/// en vivo (las bolillas salen solas) → ¡Ganaste! si tu fila completa.
class _FlujoDemo extends StatefulWidget {
  const _FlujoDemo();

  @override
  State<_FlujoDemo> createState() => _FlujoDemoState();
}

class _FlujoDemoState extends State<_FlujoDemo> {
  // Las 4 primeras filas ya están tomadas, como en el diseño.
  final _sala = SalaSimulada(ocupadasIniciales: 4);

  void _ir(BuildContext context, WidgetBuilder pantalla) => Navigator.of(
    context,
  ).push(PageRouteBuilder<void>(pageBuilder: (c, _, __) => pantalla(c)));

  @override
  void dispose() {
    _sala.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CodigoPage(
      codigo: salaDemoCodigo,
      salaNombre: salaDemoNombre,
      organizador: salaDemoOrganizador,
      filasLibres: _sala.total - _sala.ocupadas,
      alVerFilas:
          () => _ir(
            context,
            (context) => ElegirFilaPage(
              salaNombre: salaDemoNombre,
              cartillas: cartillasDemo,
              duenos: _sala.duenos,
              seleccionInicial: 5,
              alVolver: () => Navigator.of(context).pop(),
              alSeguir:
                  (fila) => _ir(
                    context,
                    (context) => ReservarPage(
                      salaNombre: salaDemoNombre,
                      organizador: salaDemoOrganizador,
                      fila: fila,
                      numeros: cartillasDemo[fila - 1],
                      nombreInicial: 'Lucía',
                      alVolver: () => Navigator.of(context).pop(),
                      alReservar: (nombre) {
                        final nombreFinal = nombre.isEmpty ? 'Lucía' : nombre;
                        if (!_sala.reservar(fila - 1, nombreFinal)) return;
                        _ir(
                          context,
                          (context) => EsperandoSimuladaPage(
                            sala: _sala,
                            fila: fila - 1,
                            nombre: nombreFinal,
                          ),
                        );
                      },
                    ),
                  ),
            ),
          ),
    );
  }
}
