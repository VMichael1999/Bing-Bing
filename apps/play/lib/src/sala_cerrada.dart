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

class _VigilaSalaCerradaState extends State<VigilaSalaCerrada> {
  StreamSubscription<SalaEnVivo?>? _suscripcion;
  bool _avisada = false;

  @override
  void initState() {
    super.initState();
    _suscripcion = widget.repositorio.sala(widget.codigo).listen((sala) {
      if (sala?.estado == EstadoSala.cancelada) _avisar(sala!);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }

  void _avisar(SalaEnVivo sala) {
    // Varias pantallas de la misma sala vigilan a la vez: solo avisa la de arriba.
    if (_avisada || !mounted || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _avisada = true;
    final navegador = Navigator.of(context);
    navegador
        .push<void>(
          PageRouteBuilder<void>(
            opaque: false,
            pageBuilder:
                (c, _, __) => SalaCerradaHoja(
                  sala: sala,
                  alEntender: () => Navigator.of(c).pop(),
                ),
            transitionsBuilder:
                (_, animacion, __, hijo) =>
                    FadeTransition(opacity: animacion, child: hijo),
          ),
        )
        .then((_) => navegador.popUntil((ruta) => ruta.isFirst));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// "La sala se cerró": se explica sin culpar a nadie y se vuelve al inicio.
class SalaCerradaHoja extends StatelessWidget {
  const SalaCerradaHoja({
    super.key,
    required this.sala,
    this.alEntender,
    this.fondo = const SizedBox.shrink(),
  });

  final SalaEnVivo sala;
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
          '${sala.organizador} cerró «${sala.nombre}» antes de empezar, así '
          'que la partida no se juega.'
          '${motivo == null ? '' : ' Motivo: $motivo.'}',
      children: [
        BingBoton(
          texto: 'Entendido',
          tipo: BingBotonTipo.tinta,
          alPresionar: alEntender,
        ),
      ],
    );
  }
}
