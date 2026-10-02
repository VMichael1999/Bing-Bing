import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

/// `jug-07-salas`: salas públicas abiertas, para entrar con un toque, y la
/// salida de siempre para las privadas (escribir el código o escanear el QR).
class SalasPage extends StatelessWidget {
  const SalasPage({
    super.key,
    required this.salas,
    this.error = false,
    this.alElegirSala,
    this.alEscribirCodigo,
    this.alEscanear,
  });

  /// Salas a mostrar; `null` mientras llegan.
  final List<SalaEnVivo>? salas;

  /// No se pudo leer la lista.
  final bool error;
  final ValueChanged<SalaEnVivo>? alElegirSala;
  final VoidCallback? alEscribirCodigo;

  /// Si es `null` no se muestra el botón del QR.
  final VoidCallback? alEscanear;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final lista = salas;
    return ColoredBox(
      color: paleta.fondo,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BingEncabezado(
                conVolver: false,
                titulo: 'Salas abiertas',
                subtitulo: 'Entra a una y elige tu fila',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _CampoCodigo(alPresionar: alEscribirCodigo)),
                  if (alEscanear != null) ...[
                    const SizedBox(width: 8),
                    _BotonQr(alPresionar: alEscanear),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (error)
                const BingAviso(
                  icono: 'bell',
                  texto:
                      'No pudimos cargar las salas. Revisa tu internet o '
                      'escribe el código.',
                )
              else if (lista != null && lista.isEmpty)
                const _SinSalas()
              else if (lista != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    'ABIERTAS AHORA',
                    style: BingTexto.cabeceraSeccion.copyWith(
                      color: paleta.apagado,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < lista.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _TarjetaSala(
                    sala: lista[i],
                    alPresionar:
                        lista[i].estado == EstadoSala.abierta
                            ? () => alElegirSala?.call(lista[i])
                            : null,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Se ve como un campo, pero al tocarlo abre la pantalla del código.
class _CampoCodigo extends StatelessWidget {
  const _CampoCodigo({this.alPresionar});

  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Semantics(
      button: true,
      label: 'Escribir el código de una sala',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: alPresionar,
        child: ExcludeSemantics(
          child: Container(
            height: BingMedidas.alturaCampo,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: paleta.tarjeta,
              borderRadius: BorderRadius.circular(BingMedidas.radioCampo),
              border: Border.all(
                color: paleta.linea,
                width: BingMedidas.bordeCampo,
              ),
            ),
            child: Row(
              children: [
                BingIcono('pen', color: paleta.apagado),
                const SizedBox(width: 10),
                Text(
                  'Escribir el código',
                  style: BingTexto.figtree(
                    14.5,
                    500,
                  ).copyWith(color: paleta.apagado),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BotonQr extends StatelessWidget {
  const _BotonQr({this.alPresionar});

  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Semantics(
      button: true,
      label: 'Escanear el QR',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: alPresionar,
        child: ExcludeSemantics(
          child: Container(
            width: 52,
            height: BingMedidas.alturaCampo,
            decoration: BoxDecoration(
              color: paleta.tinta,
              borderRadius: BorderRadius.circular(BingMedidas.radioCampo),
            ),
            child: Center(child: BingIcono('qr', color: paleta.fondo)),
          ),
        ),
      ),
    );
  }
}

/// Una sala de la lista (`.sala`): nombre, quién organiza, cuántos quedan y
/// una barra de avance. Las llenas se ven apagadas y no se tocan.
class _TarjetaSala extends StatelessWidget {
  const _TarjetaSala({required this.sala, this.alPresionar});

  final SalaEnVivo sala;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final llena = sala.estado != EstadoSala.abierta;
    final libres = sala.libres;
    final avance = sala.filasTotal == 0 ? 0.0 : sala.ocupadas / sala.filasTotal;
    return Semantics(
      button: !llena,
      label:
          '${sala.nombre}. Organiza ${sala.organizador}. '
          '${llena ? 'Llena' : 'Quedan $libres filas'}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: alPresionar,
        child: ExcludeSemantics(
          child: Opacity(
            opacity: llena ? 0.58 : 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: paleta.tarjeta,
                borderRadius: BorderRadius.circular(BingMedidas.radioTarjeta),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sala.nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: BingTexto.figtree(
                                15,
                                800,
                              ).copyWith(color: paleta.tinta),
                            ),
                            Text(
                              'Organiza ${sala.organizador}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: BingTexto.subtitulo.copyWith(
                                color: paleta.apagado,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      BingChip(
                        llena
                            ? 'Llena'
                            : (libres == 1 ? 'Queda 1' : 'Quedan $libres'),
                        tipo: llena ? BingChipTipo.normal : BingChipTipo.ok,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 6,
                      color: paleta.suave,
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: avance.clamp(0.0, 1.0),
                        child: ColoredBox(
                          color: paleta.dauber,
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${sala.ocupadas} de ${sala.filasTotal} filas',
                    style: BingTexto.figtree(
                      12,
                      700,
                    ).copyWith(color: paleta.apagado),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SinSalas extends StatelessWidget {
  const _SinSalas();

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: paleta.tarjeta,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Center(
              child: BingIcono(
                'users',
                color: paleta.apagado,
                tamano: BingIconoTamano.l,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No hay salas abiertas',
            style: BingTexto.figtree(19, 800).copyWith(color: paleta.tinta),
          ),
          const SizedBox(height: 6),
          Text(
            'Cuando alguien abra una sala pública aparecerá aquí. Si te dieron '
            'un código o un QR, úsalo arriba.',
            textAlign: TextAlign.center,
            style: BingTexto.figtree(14, 500).copyWith(color: paleta.apagado),
          ),
        ],
      ),
    );
  }
}
