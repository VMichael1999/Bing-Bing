import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

/// Salas públicas con sitio, bajo el QR del inicio: las más llenas primero y,
/// si hay más de las que caben, se baja con el scroll de la pantalla.
class SalasAbiertas extends StatelessWidget {
  const SalasAbiertas({
    super.key,
    required this.salas,
    this.error = false,
    this.atenuada = false,
    this.desplazable = false,
    this.alElegirSala,
  });

  /// Salas a mostrar (ya filtradas y ordenadas); `null` mientras llegan.
  final List<SalaEnVivo>? salas;

  /// No se pudo leer la lista.
  final bool error;

  /// Hay un código escrito: la lista pasa a segundo plano.
  final bool atenuada;

  /// Ocupa el alto que le den y solo las tarjetas se mueven; si no, se ajusta.
  final bool desplazable;
  final ValueChanged<SalaEnVivo>? alElegirSala;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final lista = salas;
    final estilo = BingTexto.figtree(13, 600).copyWith(color: paleta.apagado);
    final titulo = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        'SALAS ABIERTAS AHORA',
        style: BingTexto.cabeceraSeccion.copyWith(color: paleta.apagado),
      ),
    );
    final Widget contenido;
    if (error) {
      contenido = const BingAviso(
        icono: 'bell',
        texto: 'No pudimos cargar las salas. Escribe el código o escanea.',
      );
    } else if (lista == null) {
      contenido = const Column(
        children: [_TarjetaFantasma(), SizedBox(height: 8), _TarjetaFantasma()],
      );
    } else if (lista.isEmpty) {
      contenido = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Text(
          'Ahora no hay salas abiertas. Escribe un código o escanea un QR.',
          style: estilo,
        ),
      );
    } else {
      contenido = Column(
        children: [
          for (var i = 0; i < lista.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _TarjetaSala(
              sala: lista[i],
              alPresionar: () => alElegirSala?.call(lista[i]),
            ),
          ],
        ],
      );
    }
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: atenuada ? 0.45 : 1,
      child:
          desplazable
              ? LayoutBuilder(
                builder: (context, caja) {
                  // Si casi no queda sitio, mejor no mostrar una franja cortada.
                  if (caja.maxHeight < _altoMinimoLista) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titulo,
                      const SizedBox(height: 10),
                      Expanded(child: _ConDesvanecido(hijo: contenido)),
                    ],
                  );
                },
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [titulo, const SizedBox(height: 10), contenido],
              ),
    );
  }
}

/// Alto mínimo de la zona de salas para mostrarla.
const _altoMinimoLista = 100.0;

/// Zona con scroll que se desvanece en el borde de abajo: así se nota que hay
/// más tarjetas.
class _ConDesvanecido extends StatelessWidget {
  const _ConDesvanecido({required this.hijo});

  final Widget hijo;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback:
          (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
            stops: [0, 0.88, 1],
          ).createShader(rect),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: hijo,
      ),
    );
  }
}

/// Una sala de la lista: nombre, quién organiza, cuántos quedan y una barra
/// fina de avance.
class _TarjetaSala extends StatelessWidget {
  const _TarjetaSala({required this.sala, this.alPresionar});

  final SalaEnVivo sala;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final libres = sala.libres;
    final avance = sala.filasTotal == 0 ? 0.0 : sala.ocupadas / sala.filasTotal;
    return Semantics(
      button: true,
      label:
          '${sala.nombre}. Organiza ${sala.organizador}. '
          '${libres == 1 ? 'Queda 1 fila' : 'Quedan $libres filas'}. '
          '${sala.precioFila == 0 ? 'Gratis' : '${sala.precioFila} créditos por fila, premio ${sala.premio}'}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: alPresionar,
        child: ExcludeSemantics(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
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
                      libres == 1 ? 'Queda 1' : 'Quedan $libres',
                      tipo: BingChipTipo.ok,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    height: 5,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${sala.ocupadas} de ${sala.filasTotal} filas',
                      style: BingTexto.figtree(
                        12,
                        700,
                      ).copyWith(color: paleta.apagado),
                    ),
                    _PrecioPremio(sala: sala),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "**5** por fila · premio **80**", o "Gratis" si la partida no tiene premio.
class _PrecioPremio extends StatelessWidget {
  const _PrecioPremio({required this.sala});

  final SalaEnVivo sala;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final normal = BingTexto.figtree(12, 700).copyWith(color: paleta.apagado);
    final fuerte = BingTexto.bungee(13).copyWith(color: paleta.tinta);
    if (sala.precioFila == 0) return Text('Gratis', style: normal);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '${sala.precioFila}', style: fuerte),
          TextSpan(text: ' por fila · premio ', style: normal),
          TextSpan(text: '${sala.premio}', style: fuerte),
        ],
      ),
    );
  }
}

/// Marcador gris mientras llega la lista.
class _TarjetaFantasma extends StatelessWidget {
  const _TarjetaFantasma();

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: paleta.tarjeta.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(BingMedidas.radioTarjeta),
      ),
    );
  }
}
