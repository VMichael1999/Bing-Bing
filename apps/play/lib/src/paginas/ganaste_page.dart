import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

import 'reservar_page.dart';

/// `jug-06-ganaste`: la celebración en el celular de quien ganó.
class GanastePage extends StatelessWidget {
  const GanastePage({
    super.key,
    required this.nombre,
    required this.fila,
    required this.numeros,
    required this.bolillaFinal,
    required this.cantidadBolillas,
    required this.organizador,
    this.premio = 0,
    this.pagado = false,
    this.alVerCartilla,
  });

  final String nombre;
  final int fila;
  final List<int> numeros;

  /// Bolilla con la que se completó la fila.
  final int bolillaFinal;

  /// Cuántas bolillas habían salido en ese momento.
  final int cantidadBolillas;
  final String organizador;

  /// Créditos que le tocan por esta victoria; 0 si la partida no tenía premio.
  final int premio;

  /// Quien organiza ya terminó la partida y el premio está en la billetera.
  final bool pagado;
  final VoidCallback? alVerCartilla;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return ColoredBox(
      color: paleta.fondo,
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _TituloGanaste(color: paleta.dauber),
                          const SizedBox(height: 14),
                          Text(
                            '$nombre, completaste la fila $fila',
                            textAlign: TextAlign.center,
                            style: BingTexto.figtree(
                              22,
                              800,
                            ).copyWith(color: paleta.tinta),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: paleta.victoriaSuave,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < numeros.length; i++) ...[
                                  if (i > 0) const SizedBox(width: 6),
                                  BingBolilla(
                                    columna: columnaDe(numeros[i]),
                                    numero: numeros[i],
                                    letra: letrasBingo[columnaDe(numeros[i])],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (premio > 0) ...[
                            const SizedBox(height: 14),
                            BingAviso(
                              icono: 'trophy',
                              destacado: 'Ganaste $premio créditos.',
                              texto:
                                  pagado
                                      ? 'Ya están en tu billetera.'
                                      : 'Se suman a tu billetera cuando '
                                          '$organizador termine la partida.',
                            ),
                          ],
                          const SizedBox(height: 14),
                          Text(
                            'Con la ${etiqueta(bolillaFinal, 5)}, la bolilla '
                            '$cantidadBolillas. $organizador ya lo ve en su '
                            'pantalla.',
                            textAlign: TextAlign.center,
                            style: BingTexto.figtree(
                              13.5,
                              400,
                            ).copyWith(color: paleta.apagado),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                BingPie(
                  boton: BingBoton(
                    texto: 'Ver la cartilla',
                    tipo: BingBotonTipo.linea,
                    alPresionar: alVerCartilla,
                  ),
                  nota: 'No hace falta gritar: la app avisa sola.',
                ),
              ],
            ),
          ),
          const Positioned.fill(child: BingConfeti()),
        ],
      ),
    );
  }
}

/// "¡Ganaste!" en una sola línea. En CSS una palabra sin espacios no se parte:
/// si no cabe, desborda y se alinea al inicio en vez de quedar centrada.
class _TituloGanaste extends StatelessWidget {
  const _TituloGanaste({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final estilo = BingTexto.bingo.copyWith(color: color);
    final ancho =
        (TextPainter(
          text: TextSpan(text: '¡Ganaste!', style: estilo),
          textDirection: TextDirection.ltr,
        )..layout()).width;
    return SizedBox(
      height: 52,
      child: LayoutBuilder(
        builder:
            (context, c) => OverflowBox(
              maxWidth: double.infinity,
              alignment:
                  ancho > c.maxWidth ? Alignment.centerLeft : Alignment.center,
              child: Text('¡Ganaste!', softWrap: false, style: estilo),
            ),
      ),
    );
  }
}
