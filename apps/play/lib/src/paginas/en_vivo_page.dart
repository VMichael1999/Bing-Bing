import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

import 'reservar_page.dart';

/// `jug-05-en-vivo`: última bolilla, su fila grande y los demás (solo lectura).
class EnVivoPage extends StatelessWidget {
  const EnVivoPage({
    super.key,
    required this.salaNombre,
    required this.organizador,
    required this.cartillas,
    required this.nombres,
    required this.miFila,
    required this.bolillas,
    required this.hace,
    this.mostrar = 6,
  });

  final String salaNombre;
  final String organizador;
  final List<List<int>> cartillas;
  final List<String> nombres;

  /// Fila del jugador (base 1).
  final int miFila;

  /// Bolillas en orden de salida.
  final List<int> bolillas;

  /// Texto de cuánto hace que salió la última ("hace 3 s").
  final String hace;

  /// Cuántas filas de los demás se muestran.
  final int mostrar;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final salidas = bolillas.toSet();
    final ultima = bolillas.last;
    final mia = cartillas[miFila - 1];
    final hits = mia.where(salidas.contains).length;
    final orden = ordenarPorAvance(
      cartillas,
      salidas,
    ).where((i) => i != miFila - 1).take(mostrar);

    return ColoredBox(
      color: paleta.fondo,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
          child: Column(
            children: [
              BingEncabezado(
                conVolver: false,
                titulo: salaNombre,
                subtitulo: 'Organiza $organizador',
                accion: const BingChip('En vivo', tipo: BingChipTipo.vivo),
              ),
              const SizedBox(height: 10),
              BingUltimaBolilla(
                bolilla: BingBolilla(
                  columna: columnaDe(ultima),
                  numero: ultima,
                  letra: letrasBingo[columnaDe(ultima)],
                  tamano: BingBolillaTamano.lg,
                ),
                titulo: 'Salió la ${etiqueta(ultima, 5)}',
                detalle:
                    '$hace · bolilla ${bolillas.length} de ${totalBolillas(5)}',
              ),
              const SizedBox(height: 10),
              BingMiFila(
                titulo: 'Tu fila · la $miFila',
                chip: BingChip('$hits de ${mia.length}'),
                numeros: mia,
                salidas: salidas,
                letras: letrasBingo,
                recientes: {ultima},
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Los demás',
                    style: BingTexto.figtree(
                      14,
                      800,
                    ).copyWith(color: paleta.tinta),
                  ),
                  Text(
                    'Solo puedes mirar',
                    style: BingTexto.figtree(
                      12,
                      700,
                    ).copyWith(color: paleta.apagado),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              BingCartilla(
                letras: letrasBingo,
                filas: [
                  for (final i in orden)
                    BingFilaCompacta(
                      indice: i + 1,
                      numeros: cartillas[i],
                      salidas: salidas,
                      recientes: {ultima},
                      nombre: nombres[i],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
