import 'dart:async';

import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

/// Vigila una sala mientras la persona está en ella: si quien organiza la
/// cierra, sube [SalaCerradaHoja] y, al entenderla, se vuelve al inicio.
class VigilaSalaCerrada extends StatefulWidget {
  const VigilaSalaCerrada({
    super.key,
    required this.repositorio,
    required this.codigo,
    required this.child,
  });

  final RepositorioSala repositorio;
  final String codigo;
  final Widget child;

  @override
  State<VigilaSalaCerrada> createState() => _VigilaSalaCerradaState();
}

/// Las salas que ya se avisaron, por repositorio: varias pantallas de la misma
/// sala vigilan a la vez y solo debe avisar una.
final _avisadas = Expando<Set<String>>('salas avisadas');

class _VigilaSalaCerradaState extends State<VigilaSalaCerrada> {
  StreamSubscription<SalaEnVivo?>? _suscripcion;

  @override
  void initState() {
    super.initState();
    _suscripcion = widget.repositorio.sala(widget.codigo).listen((sala) {
      if (sala?.estado == EstadoSala.cancelada) unawaited(_avisar(sala!));
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }

  Future<void> _avisar(SalaEnVivo sala) async {
    // Aviso a la persona esté donde esté dentro de la sala: aunque haya otra
    // pantalla encima (billetera, cuenta…), el aviso sube sobre ella.
    final ya = _avisadas[widget.repositorio] ??= {};
    if (!ya.add(widget.codigo) || !mounted) return;
    var devueltos = 0;
    if (sala.precioFila > 0) {
      try {
        final filas = await widget.repositorio.filas(widget.codigo).first;
        final suyas = filas.where(
          (f) => f.jugadorUid != null && f.jugadorUid == widget.repositorio.uid,
        );
        devueltos = suyas.length * sala.precioFila;
      } catch (_) {
        // Sin saber cuántas tenía, el aviso sale igual, sin la línea del saldo.
      }
    }
    if (!mounted) return;
    final navegador = Navigator.of(context);
    unawaited(
      navegador
          .push<void>(
            PageRouteBuilder<void>(
              opaque: false,
              pageBuilder:
                  (c, _, __) => SalaCerradaHoja(
                    sala: sala,
                    devueltos: devueltos,
                    alEntender: () => Navigator.of(c).pop(),
                  ),
              transitionsBuilder:
                  (_, animacion, __, hijo) =>
                      FadeTransition(opacity: animacion, child: hijo),
            ),
          )
          .then((_) => navegador.popUntil((ruta) => ruta.isFirst)),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// "La sala se cerró": se explica sin culpar a nadie y se vuelve al inicio.
class SalaCerradaHoja extends StatelessWidget {
  const SalaCerradaHoja({
    super.key,
    required this.sala,
    this.devueltos = 0,
    this.alEntender,
    this.fondo = const SizedBox.shrink(),
  });

  final SalaEnVivo sala;

  /// Créditos que se le devolvieron a esta persona (0 si no pagó filas).
  final int devueltos;
  final VoidCallback? alEntender;
  final Widget fondo;

  @override
  Widget build(BuildContext context) {
    final motivo = sala.motivoCierre;
    return BingHoja(
      fondo: fondo,
      alIzquierda: true,
      titulo: 'La sala se cerró',
      texto:
          motivo == null
              ? '${sala.organizador} cerró «${sala.nombre}» porque no se llegó '
                  'al número de jugadores necesario. La partida no se juega.'
              : '${sala.organizador} cerró «${sala.nombre}» antes de empezar. '
                  'Motivo: $motivo. La partida no se juega.',
      children: [
        if (devueltos > 0)
          BingAviso(
            icono: 'wallet',
            destacado: 'Te devolvimos $devueltos créditos.',
            texto: 'Ya están en tu billetera.',
          ),
        BingBoton(
          texto: 'Entendido',
          tipo: BingBotonTipo.tinta,
          alPresionar: alEntender,
        ),
      ],
    );
  }
}
