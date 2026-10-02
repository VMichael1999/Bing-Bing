import 'dart:async';

import 'package:bing_core/bing_core.dart';
import 'package:flutter/widgets.dart';

import 'en_vivo_simulada_page.dart';
import 'esperando_page.dart';

/// `jug-04` con datos falsos: los demás jugadores van entrando solos y, cuando
/// la sala se llena, "Carmen" inicia la partida y se pasa a la pantalla en vivo.
class EsperandoSimuladaPage extends StatefulWidget {
  const EsperandoSimuladaPage({
    super.key,
    required this.sala,
    required this.fila,
    required this.nombre,
    this.cadaJugador = const Duration(milliseconds: 900),
    this.antesDeEmpezar = const Duration(seconds: 3),
  });

  final SalaSimulada sala;

  /// Fila reservada por quien usa la app (base 0).
  final int fila;
  final String nombre;
  final Duration cadaJugador;
  final Duration antesDeEmpezar;

  @override
  State<EsperandoSimuladaPage> createState() => _EsperandoSimuladaPageState();
}

class _EsperandoSimuladaPageState extends State<EsperandoSimuladaPage> {
  Timer? _reloj;
  bool _empezando = false;

  @override
  void initState() {
    super.initState();
    _reloj = Timer.periodic(widget.cadaJugador, (t) {
      if (widget.sala.llegaSiguiente() == null) {
        t.cancel();
        _programarInicio();
      }
    });
  }

  void _programarInicio() {
    if (_empezando) return;
    _empezando = true;
    Future<void>.delayed(widget.antesDeEmpezar, () {
      if (!mounted) return;
      // "Carmen" empieza: se cierra la sala y sale la primera bolilla.
      widget.sala
        ..empezar()
        ..sacar();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder:
              (context, _, __) =>
                  EnVivoSimuladaPage(sala: widget.sala, fila: widget.fila),
        ),
      );
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.sala,
      builder:
          (context, _) => EsperandoPage(
            nombre: widget.nombre,
            salaNombre: salaDemoNombre,
            organizador: salaDemoOrganizador,
            filas: [widget.fila + 1],
            cartillas: [widget.sala.cartillas[widget.fila]],
            ocupadas: widget.sala.ocupadas,
            total: widget.sala.total,
          ),
    );
  }
}
