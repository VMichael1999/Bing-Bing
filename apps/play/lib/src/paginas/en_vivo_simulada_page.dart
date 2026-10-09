import 'dart:async';

import 'package:bing_core/bing_core.dart';
import 'package:flutter/widgets.dart';

import 'en_vivo_page.dart';
import 'ganaste_page.dart';

/// "hace 3 s" / "hace 2 min" según cuánto pasó desde [desde].
String textoHace(DateTime? desde, DateTime ahora) {
  if (desde == null) return 'hace un momento';
  final s = ahora.difference(desde).inSeconds.clamp(0, 86400);
  return s < 60 ? 'hace $s s' : 'hace ${s ~/ 60} min';
}

/// `jug-05` con datos falsos: sale una bolilla cada pocos segundos y, si la fila
/// de quien usa la app se completa, se muestra `jug-06` ("¡Ganaste!").
class EnVivoSimuladaPage extends StatefulWidget {
  const EnVivoSimuladaPage({
    super.key,
    required this.sala,
    required this.fila,
    this.cadaBolilla = const Duration(milliseconds: 3000),
  });

  final SalaSimulada sala;

  /// Fila de quien usa la app (base 0).
  final int fila;
  final Duration cadaBolilla;

  @override
  State<EnVivoSimuladaPage> createState() => _EnVivoSimuladaPageState();
}

class _EnVivoSimuladaPageState extends State<EnVivoSimuladaPage> {
  Timer? _bolillas;
  Timer? _segundo;
  bool _gano = false;

  @override
  void initState() {
    super.initState();
    _bolillas = Timer.periodic(widget.cadaBolilla, (t) {
      // Mientras se ve la pantalla del ganador no salen más bolillas.
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
      final ganadoras = widget.sala.sacar();
      if (ganadoras == null) {
        t.cancel();
        return;
      }
      if (ganadoras.contains(widget.fila) && !_gano) {
        _gano = true;
        t.cancel();
        // La celebración entra un instante después de detenerse la bolilla.
        Future<void>.delayed(const Duration(milliseconds: 520), _celebrar);
      }
    });
    // Reconstruye cada segundo para que el "hace N s" avance.
    _segundo = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _celebrar() {
    if (!mounted) return;
    final sala = widget.sala;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder:
            (context, _, __) => GanastePage(
              nombre: sala.duenos[widget.fila]!,
              fila: widget.fila + 1,
              numeros: sala.cartillas[widget.fila],
              bolillaFinal: sala.bolillas.last,
              cantidadBolillas: sala.bolillas.length,
              organizador: salaDemoOrganizador,
              alVerCartilla: () => Navigator.of(context).pop(),
            ),
      ),
    );
  }

  @override
  void dispose() {
    _bolillas?.cancel();
    _segundo?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.sala,
      builder:
          (context, _) => EnVivoPage(
            salaNombre: salaDemoNombre,
            organizador: salaDemoOrganizador,
            cartillas: widget.sala.cartillas,
            nombres: [for (final d in widget.sala.duenos) d ?? ''],
            misFilas: [widget.fila + 1],
            bolillas: List.of(widget.sala.bolillas),
            hace: textoHace(widget.sala.ultimaSalida, DateTime.now()),
            // La sala completa: los otros 19 jugadores (más la fila propia, arriba).
            mostrar: widget.sala.total - 1,
          ),
    );
  }
}
