import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

/// Precio por fila y premio elegidos.
typedef PrecioPremio = ({int precioFila, int premio});

const _filas = 20;

/// `org-10b-precio-premio`: parte 2 de "Nueva partida". Quien organiza fija el
/// precio por fila y el premio; Bing Bing retiene un porcentaje y el premio no
/// puede pasar de lo que queda.
class PrecioPremioPage extends StatefulWidget {
  const PrecioPremioPage({
    super.key,
    this.precioInicial = 5,
    this.premioInicial,
    this.alVolver,
    this.alAbrirSala,
    this.creando = false,
    this.error,
  });

  final int precioInicial;

  /// Si no se da, se propone casi todo lo disponible.
  final int? premioInicial;
  final VoidCallback? alVolver;
  final ValueChanged<PrecioPremio>? alAbrirSala;
  final bool creando;
  final String? error;

  @override
  State<PrecioPremioPage> createState() => _PrecioPremioPageState();
}

class _PrecioPremioPageState extends State<PrecioPremioPage> {
  late int _precio = widget.precioInicial;
  late int _premio =
      widget.premioInicial ?? premioSugerido(widget.precioInicial, _filas);

  int get _disponible => disponibleParaPremio(_precio, _filas);

  void _cambiarPrecio(int nuevo) {
    final antes = _precio;
    setState(() {
      _precio = nuevo;
      // Si el premio seguía la propuesta, la sigue; si no, solo se acota.
      _premio =
          _premio == premioSugerido(antes, _filas)
              ? premioSugerido(nuevo, _filas)
              : _premio;
      if (_premio > disponibleParaPremio(nuevo, _filas)) {
        _premio = disponibleParaPremio(nuevo, _filas);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final fila = BingTexto.figtree(13.5, 700).copyWith(color: paleta.tinta);
    final tenue = fila.copyWith(color: paleta.apagado);
    final total = recaudado(_precio, _filas);
    final comision = comisionDe(total);
    final quedan = _disponible - _premio;
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
                      subtitulo: 'Precio y premio',
                      alVolver: widget.alVolver,
                    ),
                    const SizedBox(height: 9),
                    BingSeccion(
                      cabecera: 'PRECIO POR FILA',
                      children: [
                        _FilaPaso(
                          etiqueta: 'Créditos por fila',
                          estilo: fila,
                          paso: BingPaso(
                            valor: _precio,
                            max: 1000,
                            etiqueta: 'créditos por fila',
                            alCambiar: _cambiarPrecio,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    BingSeccion(
                      cabecera: 'SI SE LLENAN LAS $_filas FILAS',
                      children: [
                        _FilaKv('Recaudado', '$total', fila),
                        _FilaKv(
                          'Comisión de Bing Bing · $comisionPorcentaje %',
                          '−$comision',
                          tenue,
                        ),
                        Container(height: 1, color: paleta.linea),
                        _FilaKv(
                          'Disponible para premio',
                          '$_disponible',
                          fila.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    BingSeccion(
                      cabecera: 'PREMIO',
                      children: [
                        _FilaPaso(
                          etiqueta: 'Premio',
                          icono: 'trophy',
                          estilo: fila,
                          paso: BingPaso(
                            valor: _premio,
                            max: _disponible,
                            etiqueta: 'premio',
                            alCambiar: (v) => setState(() => _premio = v),
                          ),
                        ),
                        Text(
                          _precio == 0
                              ? 'Sin precio por fila no hay premio.'
                              : 'Puedes subirlo o bajarlo; no puede pasar de $_disponible.',
                          style: BingTexto.figtree(
                            12,
                            600,
                          ).copyWith(color: paleta.apagado),
                        ),
                        Container(height: 1, color: paleta.linea),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Te quedan',
                              style: fila.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '$quedan ${quedan == 1 ? 'CRÉDITO' : 'CRÉDITOS'}',
                              style: BingTexto.bungee(
                                18,
                              ).copyWith(color: paleta.tinta),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    const BingAviso(
                      icono: 'bell',
                      texto:
                          'La partida empieza cuando se llenan las 20 filas. Si '
                          'no se llenan, puedes cerrar la sala y se devuelve todo.',
                    ),
                    if (widget.error != null) ...[
                      const SizedBox(height: 9),
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
                    () => widget.alAbrirSala?.call((
                      precioFila: _precio,
                      premio: _premio,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaPaso extends StatelessWidget {
  const _FilaPaso({
    required this.etiqueta,
    required this.estilo,
    required this.paso,
    this.icono,
  });

  final String etiqueta;
  final TextStyle estilo;
  final Widget paso;
  final String? icono;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icono != null) ...[
              BingIcono(icono!, color: paleta.tinta, tamano: BingIconoTamano.s),
              const SizedBox(width: 8),
            ],
            Text(etiqueta, style: estilo),
          ],
        ),
        paso,
      ],
    );
  }
}

class _FilaKv extends StatelessWidget {
  const _FilaKv(this.izquierda, this.derecha, this.estilo);

  final String izquierda;
  final String derecha;
  final TextStyle estilo;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Flexible(child: Text(izquierda, style: estilo)),
      const SizedBox(width: 8),
      Text(derecha, style: estilo),
    ],
  );
}
