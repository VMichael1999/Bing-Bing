import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

/// `org-03-nueva-partida`: nombre, columnas, filas por jugador y la sección de
/// premio, bloqueada ("Pronto") y sin acción.
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

  /// Recibe el nombre y las columnas elegidas (5 o 6).
  final void Function(String nombre, int columnas)? alAbrirSala;

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
                    const BingSeccion(
                      cabecera: 'FILAS POR JUGADOR',
                      children: [
                        // Por ahora solo se permite 1 fila por jugador.
                        BingSegmento(
                          opciones: ['1 fila', 'Hasta 3'],
                          seleccion: 0,
                          bloqueadas: {1},
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    BingSeccion(
                      espacio: 8,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PARTIDA CON PREMIO',
                              style: BingTexto.cabeceraSeccion.copyWith(
                                color: paleta.apagado,
                              ),
                            ),
                            const BingChip(
                              'Pronto',
                              tipo: BingChipTipo.pronto,
                              icono: 'lock',
                            ),
                          ],
                        ),
                        Opacity(
                          opacity: 0.55,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Precio por fila', style: filaPremio),
                              Text('S/ 5.00', style: filaPremio),
                            ],
                          ),
                        ),
                        Opacity(
                          opacity: 0.55,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Premio', style: filaPremio),
                              Text('S/ 100.00', style: filaPremio),
                            ],
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
                alPresionar:
                    () => widget.alAbrirSala?.call(
                      _nombre.text.trim(),
                      _columnas == 0 ? 5 : 6,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
