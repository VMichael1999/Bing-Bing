import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

const _letras = ['B', 'I', 'N', 'G', 'O'];

/// `org-09-ganador`: la app verifica la fila y avisa a todos.
class GanadorPage extends StatelessWidget {
  const GanadorPage({
    super.key,
    required this.nombre,
    required this.fila,
    required this.numeros,
    required this.bolillaFinal,
    required this.cantidadBolillas,
    required this.jugadores,
    this.alSeguir,
    this.alTerminar,
  });

  final String nombre;
  final int fila;
  final List<int> numeros;
  final int bolillaFinal;
  final int cantidadBolillas;

  /// Cuántos jugadores recibieron el aviso.
  final int jugadores;
  final VoidCallback? alSeguir;
  final VoidCallback? alTerminar;

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
                          Text(
                            '¡Bingo!',
                            textAlign: TextAlign.center,
                            style: BingTexto.bingo.copyWith(
                              color: paleta.dauber,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '$nombre · fila $fila',
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
                                    letra: _letras[columnaDe(numeros[i])],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Con la ${etiqueta(bolillaFinal, 5)}, la bolilla '
                            '$cantidadBolillas de la partida.',
                            textAlign: TextAlign.center,
                            style: BingTexto.figtree(
                              13.5,
                              400,
                            ).copyWith(color: paleta.apagado),
                          ),
                          const SizedBox(height: 14),
                          BingEncontrada(
                            verificacion: true,
                            titulo: 'La app verificó la fila',
                            detalle:
                                'Los ${numeros.length} números salieron. '
                                'Ya se avisó a los $jugadores jugadores.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                BingPie(
                  boton: Column(
                    children: [
                      BingBoton(
                        texto: 'Seguir por el segundo puesto',
                        tipo: BingBotonTipo.dauber,
                        alPresionar: alSeguir,
                      ),
                      const SizedBox(height: 8),
                      BingBoton(
                        texto: 'Terminar partida',
                        tipo: BingBotonTipo.linea,
                        alPresionar: alTerminar,
                      ),
                    ],
                  ),
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
