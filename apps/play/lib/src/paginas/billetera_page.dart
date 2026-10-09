import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

const _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'set',
  'oct',
  'nov',
  'dic',
];

/// "Hoy 20:45", "Ayer 09:10" o "19 set".
String cuandoFue(DateTime? fecha, {DateTime? ahora}) {
  if (fecha == null) return '';
  final hoy = ahora ?? DateTime.now();
  final dia = DateTime(fecha.year, fecha.month, fecha.day);
  final dias = DateTime(hoy.year, hoy.month, hoy.day).difference(dia).inDays;
  final hora =
      '${fecha.hour.toString().padLeft(2, '0')}:'
      '${fecha.minute.toString().padLeft(2, '0')}';
  if (dias == 0) return 'Hoy $hora';
  if (dias == 1) return 'Ayer $hora';
  return '${fecha.day} ${_meses[fecha.month - 1]}';
}

/// `jug-11-billetera`: el saldo en créditos de prueba y el historial.
class BilleteraPage extends StatelessWidget {
  const BilleteraPage({
    super.key,
    required this.saldo,
    required this.movimientos,
    this.alVolver,
    this.alRecargar,
    this.ahora,
  });

  /// `null` mientras llega.
  final int? saldo;

  /// `null` mientras llegan.
  final List<Movimiento>? movimientos;
  final VoidCallback? alVolver;
  final VoidCallback? alRecargar;

  /// Para fijar "hoy" en las pruebas.
  final DateTime? ahora;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final lista = movimientos;
    return ColoredBox(
      color: paleta.fondo,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BingEncabezado(
                titulo: 'Mi billetera',
                subtitulo: 'Créditos de prueba',
                alVolver: alVolver,
              ),
              const SizedBox(height: 12),
              _TarjetaSaldo(saldo: saldo),
              const SizedBox(height: 12),
              BingBoton(
                texto: 'Recargar',
                tipo: BingBotonTipo.dauber,
                icono: 'plus',
                alPresionar: alRecargar,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  'MOVIMIENTOS',
                  style: BingTexto.cabeceraSeccion.copyWith(
                    color: paleta.apagado,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (lista == null)
                const SizedBox(height: 50)
              else if (lista.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    'Todavía no hay movimientos.',
                    style: BingTexto.figtree(
                      13,
                      600,
                    ).copyWith(color: paleta.apagado),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: paleta.tarjeta,
                    borderRadius: BorderRadius.circular(
                      BingMedidas.radioTarjeta,
                    ),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < lista.length; i++) ...[
                        if (i > 0) Container(height: 1, color: paleta.linea),
                        _FilaMovimiento(movimiento: lista[i], ahora: ahora),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaSaldo extends StatelessWidget {
  const _TarjetaSaldo({required this.saldo});

  final int? saldo;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: paleta.tarjeta,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SALDO',
            style: BingTexto.cabeceraSeccion.copyWith(color: paleta.apagado),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Semantics(
                label:
                    saldo == null ? 'Saldo cargando' : 'Saldo $saldo créditos',
                child: ExcludeSemantics(
                  child: Text(
                    saldo?.toString() ?? '–',
                    style: BingTexto.bungee(
                      54,
                      altura: 1,
                    ).copyWith(color: paleta.tinta),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'créditos',
                style: BingTexto.figtree(
                  16,
                  800,
                ).copyWith(color: paleta.apagado),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const BingChip(
            'De prueba · sin valor en dinero',
            tipo: BingChipTipo.pronto,
          ),
        ],
      ),
    );
  }
}

class _FilaMovimiento extends StatelessWidget {
  const _FilaMovimiento({required this.movimiento, this.ahora});

  final Movimiento movimiento;
  final DateTime? ahora;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final suma = movimiento.monto >= 0;
    final icono = switch (movimiento.tipo) {
      TipoMovimiento.fila => 'grid',
      TipoMovimiento.premio => 'trophy',
      TipoMovimiento.devolucion => 'undo',
      _ => 'plus',
    };
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 50),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: paleta.suave,
              borderRadius: BorderRadius.circular(11),
            ),
            child: BingIcono(
              icono,
              color: paleta.tinta,
              tamano: BingIconoTamano.s,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movimiento.detalle,
                  style: BingTexto.figtree(
                    13.5,
                    800,
                  ).copyWith(color: paleta.tinta),
                ),
                if (movimiento.creadaEn != null)
                  Text(
                    cuandoFue(movimiento.creadaEn, ahora: ahora),
                    style: BingTexto.figtree(
                      11.5,
                      600,
                    ).copyWith(color: paleta.apagado),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${suma ? '+' : '−'}${movimiento.monto.abs()}',
            style: BingTexto.figtree(
              14,
              800,
              tabular: true,
            ).copyWith(color: suma ? paleta.ok : paleta.tinta),
          ),
        ],
      ),
    );
  }
}

/// `jug-12-recargar`: montos fijos de créditos de prueba que se agregan al
/// instante, sin cobro.
class RecargarHoja extends StatefulWidget {
  const RecargarHoja({
    super.key,
    required this.fondo,
    this.montoInicial = 20,
    this.agregando = false,
    this.error,
    this.alAgregar,
    this.alCerrar,
  });

  final Widget fondo;
  final int montoInicial;
  final bool agregando;
  final String? error;
  final ValueChanged<int>? alAgregar;
  final VoidCallback? alCerrar;

  @override
  State<RecargarHoja> createState() => _RecargarHojaState();
}

class _RecargarHojaState extends State<RecargarHoja> {
  late int _monto = widget.montoInicial;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return BingHoja(
      fondo: widget.fondo,
      alIzquierda: true,
      titulo: 'Recargar créditos',
      texto: '',
      alCerrar: widget.alCerrar,
      children: [
        if (widget.error != null)
          BingAviso(icono: 'bell', texto: widget.error!),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.9,
          children: [
            for (final m in montosRecarga)
              _Monto(
                monto: m,
                elegido: m == _monto,
                alPresionar: () => setState(() => _monto = m),
              ),
          ],
        ),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Recibirás '),
              TextSpan(
                text: '$_monto créditos de prueba',
                style: TextStyle(
                  color: paleta.tinta,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const TextSpan(text: '. No tienen valor en dinero.'),
            ],
          ),
          style: BingTexto.figtree(14, 400).copyWith(color: paleta.apagado),
        ),
        BingBoton(
          texto: 'Agregar $_monto créditos',
          tipo: BingBotonTipo.dauber,
          deshabilitado: widget.agregando,
          alPresionar: () => widget.alAgregar?.call(_monto),
        ),
      ],
    );
  }
}

class _Monto extends StatelessWidget {
  const _Monto({
    required this.monto,
    required this.elegido,
    required this.alPresionar,
  });

  final int monto;
  final bool elegido;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Semantics(
      button: true,
      selected: elegido,
      label: '$monto créditos',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: alPresionar,
        child: ExcludeSemantics(
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: elegido ? paleta.suave : null,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: elegido ? paleta.tinta : paleta.linea,
                width: 1.5,
              ),
            ),
            child: Text(
              '$monto',
              style: BingTexto.figtree(16, 800).copyWith(color: paleta.tinta),
            ),
          ),
        ),
      ),
    );
  }
}
