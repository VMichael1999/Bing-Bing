import 'package:flutter/widgets.dart';

import 'sala_en_vivo.dart';

/// Escucha la sala y sus filas a la vez y dibuja cuando llegan las dos.
///
/// Mientras tanto muestra [espera], para no dejar la pantalla en blanco.
class SalaEnVivoBuilder extends StatefulWidget {
  const SalaEnVivoBuilder({
    super.key,
    required this.repositorio,
    required this.codigo,
    required this.espera,
    required this.constructor,
  });

  final RepositorioSala repositorio;
  final String codigo;
  final Widget espera;
  final Widget Function(
    BuildContext context,
    SalaEnVivo sala,
    List<FilaEnVivo> filas,
  )
  constructor;

  @override
  State<SalaEnVivoBuilder> createState() => _SalaEnVivoBuilderState();
}

class _SalaEnVivoBuilderState extends State<SalaEnVivoBuilder> {
  late final _sala = widget.repositorio.sala(widget.codigo);
  late final _filas = widget.repositorio.filas(widget.codigo);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SalaEnVivo?>(
      stream: _sala,
      builder:
          (context, sala) => StreamBuilder<List<FilaEnVivo>>(
            stream: _filas,
            builder: (context, filas) {
              final s = sala.data;
              final f = filas.data;
              if (s == null || f == null) return widget.espera;
              return widget.constructor(context, s, f);
            },
          ),
    );
  }
}
