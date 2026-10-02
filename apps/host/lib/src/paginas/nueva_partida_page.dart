import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

import 'precio_premio_page.dart';

/// `org-03-nueva-partida` y `org-10-nueva-partida-v2`: nombre, visibilidad
/// (pública o privada), columnas, filas por jugador y una fila de precio y
/// premio que abre `org-10b-precio-premio`.
class NuevaPartidaPage extends StatefulWidget {
  const NuevaPartidaPage({
    super.key,
    this.nombreInicial = '',
    this.alVolver,
    this.alAbrirSala,
    this.error,
    this.creando = false,
  });

  final String nombreInicial;
  final VoidCallback? alVolver;

  /// Recibe el nombre, las columnas elegidas (5 o 6), si la sala es pública, el
  /// precio por fila, el premio y cuántas filas puede tener cada persona.
  final void Function(
    String nombre,
    int columnas,
    bool publica,
    int precioFila,
    int premio,
    int filasPorJugador,
  )?
  alAbrirSala;

  /// Por qué falló crear la sala, si falló.
  final String? error;
  final bool creando;

  @override
  State<NuevaPartidaPage> createState() => _NuevaPartidaPageState();
}

class _NuevaPartidaPageState extends State<NuevaPartidaPage> {
  late final TextEditingController _nombre = TextEditingController(
    text: widget.nombreInicial,
  );
  int _columnas = 0; // índice: 0 = 5 columnas, 1 = 6 columnas.
  int _visibilidad = 0; // índice: 0 = pública, 1 = privada.
  int _filasPorJugador = 0; // índice: 0 = las que quiera, 1 = solo 1.
  int _precio = 5;
  int _premio = premioSugerido(5, 20);

  void _abrir() => widget.alAbrirSala?.call(
    _nombre.text.trim(),
    _columnas == 0 ? 5 : 6,
    _visibilidad == 0,
    _precio,
    _premio,
    _filasPorJugador == 0 ? 20 : 1,
  );

  /// Abre la parte 2 (precio y premio); al "Abrir sala" de allí se crea la sala.
  Future<void> _elegirPrecio() async {
    final r = await Navigator.of(context).push<PrecioPremio>(
      PageRouteBuilder<PrecioPremio>(
        pageBuilder:
            (c, _, __) => PrecioPremioPage(
              precioInicial: _precio,
              premioInicial: _premio,
              alVolver: () => Navigator.of(c).pop(),
              alAbrirSala: (v) => Navigator.of(c).pop(v),
            ),
      ),
    );
    if (r == null || !mounted) return;
    setState(() {
      _precio = r.precioFila;
      _premio = r.premio;
    });
    _abrir();
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final filaPremio = BingTexto.figtree(
      13.5,
      700,
    ).copyWith(color: paleta.apagado);
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
                      titulo: 'Nueva partida',
                      subtitulo: 'Puedes cambiarlo antes de abrir la sala',
                      alVolver: widget.alVolver,
                    ),
                    const SizedBox(height: 10),
                    BingSeccion(
                      cabecera: 'NOMBRE',
                      children: [BingCampo(controlador: _nombre, maxLargo: 40)],
                    ),
                    const SizedBox(height: 10),
                    BingSeccion(
                      cabecera: 'VISIBILIDAD',
                      children: [
                        BingSegmento(
                          opciones: const ['Pública', 'Privada'],
                          seleccion: _visibilidad,
                          alCambiar: (i) => setState(() => _visibilidad = i),
                        ),
                        Text(
                          'Pública: la ve cualquiera en Play. Privada: solo con '
                          'código, enlace o QR.',
                          style: BingTexto.figtree(
                            12,
                            600,
                          ).copyWith(color: paleta.apagado),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    BingSeccion(
                      cabecera: 'COLUMNAS POR FILA',
                      children: [
                        BingSegmento(
                          opciones: const [
                            '5 · 75 bolillas',
                            '6 · 90 bolillas',
                          ],
                          seleccion: _columnas,
                          alCambiar: (i) => setState(() => _columnas = i),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    BingSeccion(
                      cabecera: 'FILAS POR JUGADOR',
                      children: [
                        BingSegmento(
                          opciones: const ['Las que quiera', 'Solo 1'],
                          seleccion: _filasPorJugador,
                          alCambiar:
                              (i) => setState(() => _filasPorJugador = i),
                        ),
                        Text(
                          _filasPorJugador == 0
                              ? 'Cada persona elige las filas que quiera, '
                                  'mientras le alcance el saldo.'
                              : 'Cada persona puede tener una sola fila.',
                          style: BingTexto.figtree(
                            12,
                            600,
                          ).copyWith(color: paleta.apagado),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    BingSeccion(
                      cabecera: 'PRECIO Y PREMIO',
                      children: [
                        Semantics(
                          button: true,
                          label: 'Precio y premio',
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _elegirPrecio,
                            child: ExcludeSemantics(
                              child: Row(
                                children: [
                                  BingIcono(
                                    'trophy',
                                    color: paleta.tinta,
                                    tamano: BingIconoTamano.s,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _precio == 0
                                          ? 'Gratis · sin premio'
                                          : '$_precio por fila · premio $_premio',
                                      style: filaPremio.copyWith(
                                        color: paleta.tinta,
                                      ),
                                    ),
                                  ),
                                  BingIcono(
                                    'right',
                                    color: paleta.apagado,
                                    tamano: BingIconoTamano.s,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.error != null) ...[
                      const SizedBox(height: 10),
                      BingAviso(icono: 'bell', texto: widget.error!),
                    ],
                  ],
                ),
              ),
            ),
            BingPie(
              boton: BingBoton(
                texto: 'Abrir sala',
                tipo: BingBotonTipo.dauber,
                deshabilitado: widget.creando,
                alPresionar: _abrir,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
