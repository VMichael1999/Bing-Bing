import 'package:bing_core/bing_core.dart';
import 'package:bing_firebase/bing_firebase.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

import 'src/demo.dart';
import 'src/flujo_real.dart';
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
  if (!await iniciarFirebase(AppBing.play)) {
    runApp(const BingPlayApp());
    return;
  }
  try {
    await SesionBing().entrarAnonimo();
    runApp(BingPlayApp(repositorio: RepositorioFirestore()));
  } catch (e) {
    debugPrint('Play: no se pudo iniciar sesión: $e');
    runApp(const BingPlayApp(inicio: _SinConexion()));
  }
}

class BingPlayApp extends StatelessWidget {
  const BingPlayApp({super.key, this.inicio, this.repositorio});

  /// Pantalla con la que arranca; por defecto, la del código de sala.
  final Widget? inicio;

  /// Sala real (Firebase o en memoria); sin ella corre la demostración.
  final RepositorioSala? repositorio;

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
        home:
            inicio ??
            pantallaDemo(_pantallaElegida) ??
            (repositorio == null
                ? const _FlujoDemo()
                : FlujoReal(repositorio: repositorio!)),
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

/// Pantalla mínima cuando Firebase está configurado pero no hay conexión.
class _SinConexion extends StatelessWidget {
  const _SinConexion();

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return ColoredBox(
      color: paleta.fondo,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No pudimos conectar con el servidor.\n'
              'Revisa tu internet y vuelve a abrir la app.',
              textAlign: TextAlign.center,
              style: BingTexto.figtree(15, 700).copyWith(color: paleta.tinta),
            ),
          ),
        ),
      ),
    );
  }
}
