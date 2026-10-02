import 'dart:async';

import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

import 'cartilla_llena_sheet.dart';
import 'sala_abierta_page.dart';

/// Filas de la lista de la sala como las dibuja el diseño (`org-04`): las 5
/// primeras, un salto "filas 6 a N", la que acaba de entrar en verde y las
/// libres. Con pocas filas ocupadas se muestran todas.
List<BingJugador> jugadoresVisibles(SalaSimulada sala) {
  final ocupadas = sala.ocupadas;
  BingJugador fila(int i, {bool nueva = false}) =>
      nueva
          ? BingJugador.nuevo('${i + 1}', sala.duenos[i]!, 'recién entró')
          : BingJugador.normal('${i + 1}', sala.duenos[i]!, sala.horas[i]!);
  return [
    if (ocupadas <= 6)
      for (var i = 0; i < ocupadas; i++) fila(i)
    else ...[
      for (var i = 0; i < 5; i++) fila(i),
      if (ocupadas - 1 > 5)
        BingJugador.salto('filas 6 a ${ocupadas - 1}')
      else
        fila(5),
      fila(ocupadas - 1, nueva: sala.ultimaEnEntrar == ocupadas - 1),
    ],
    for (var i = ocupadas; i < sala.total; i++) BingJugador.libre('${i + 1}'),
  ];
}

/// `org-04` y `org-05` en vivo con datos falsos: los jugadores van entrando
/// solos hasta llenar la sala y entonces sube "¡Cartilla llena!".
class SalaSimuladaPage extends StatefulWidget {
  const SalaSimuladaPage({
    super.key,
    required this.sala,
    required this.salaNombre,
    required this.alEmpezar,
    this.alVolver,
    this.cadaJugador = const Duration(milliseconds: 2200),
  });

  final SalaSimulada sala;
  final String salaNombre;
  final VoidCallback alEmpezar;
  final VoidCallback? alVolver;
  final Duration cadaJugador;

  @override
  State<SalaSimuladaPage> createState() => _SalaSimuladaPageState();
}

class _SalaSimuladaPageState extends State<SalaSimuladaPage> {
  Timer? _reloj;
  bool _hojaMostrada = false;

  @override
  void initState() {
    super.initState();
    _reloj = Timer.periodic(widget.cadaJugador, (t) {
      if (widget.sala.llegaSiguiente() == null) t.cancel();
    });
    widget.sala.addListener(_alCambiar);
  }

  void _alCambiar() {
    if (!mounted || _hojaMostrada || !widget.sala.estaLlena) return;
    _hojaMostrada = true;
    // La hoja sube un instante después de que entra la última fila.
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _mostrarHoja();
    });
  }

  void _mostrarHoja() {
    final sala = widget.sala;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder:
            (context, _, __) => CartillaLlenaSheet(
              salaNombre: widget.salaNombre,
              total: sala.total,
              ultimos: [
                for (var i = sala.total - 6; i < sala.total; i++)
                  BingJugador.normal('${i + 1}', sala.duenos[i]!, 'listo'),
              ],
              alEmpezar: () {
                Navigator.of(context).pop();
                _empezar();
              },
              alEsperar: () => Navigator.of(context).pop(),
            ),
      ),
    );
  }

  void _empezar() {
    if (widget.sala.empezar()) widget.alEmpezar();
  }

  @override
  void dispose() {
    _reloj?.cancel();
    widget.sala.removeListener(_alCambiar);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.sala,
      builder:
          (context, _) => SalaAbiertaPage(
            salaNombre: widget.salaNombre,
            codigo: salaDemoCodigo,
            ocupadas: widget.sala.ocupadas,
            total: widget.sala.total,
            jugadores: jugadoresVisibles(widget.sala),
            alVolver: widget.alVolver,
            alEmpezar: widget.sala.estaLlena ? _empezar : null,
          ),
    );
  }
}
