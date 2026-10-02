import 'package:flutter/widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'icono.dart';
import 'tema.dart';
import 'tipografia.dart';

/// Botón pequeño de 32 dp con ícono (`.mini`): Compartir, Copiar…
class BingMini extends StatelessWidget {
  const BingMini({
    super.key,
    required this.texto,
    required this.icono,
    this.alPresionar,
  });

  final String texto;
  final String icono;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Semantics(
      button: true,
      label: texto,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: alPresionar,
        child: ExcludeSemantics(
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: paleta.suave,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BingIcono(
                  icono,
                  color: paleta.tinta,
                  tamano: BingIconoTamano.xs,
                ),
                const SizedBox(width: 6),
                Text(
                  texto,
                  style: BingTexto.figtree(
                    12.5,
                    800,
                  ).copyWith(color: paleta.tinta),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta del código de sala (`.code`): código grande, QR real de 72 dp y las
/// acciones de compartir y copiar.
class BingCodigoSala extends StatelessWidget {
  const BingCodigoSala({
    super.key,
    required this.codigo,
    this.datosQr,
    this.alCompartir,
    this.alCopiar,
  });

  final String codigo;

  /// Lo que codifica el QR; por defecto, el código solo.
  final String? datosQr;
  final VoidCallback? alCompartir;
  final VoidCallback? alCopiar;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: paleta.tarjeta,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                // El QR de 72 dp abarca las dos filas de la rejilla y reparte su
                // altura sobrante entre ellas: etiqueta (16.56) + gap (4) + código
                // (36) = 56.56, sobran 15.44. Arriba 3.86, entre ambos 4 + 7.72.
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 3.86),
                    Text(
                      'CÓDIGO DE LA SALA',
                      style: BingTexto.figtree(
                        12,
                        700,
                      ).copyWith(color: paleta.apagado),
                    ),
                    const SizedBox(height: 11.72),
                    Text(
                      codigo,
                      style: BingTexto.codigoSala.copyWith(color: paleta.tinta),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Semantics(
                label: 'Código QR de la sala $codigo',
                image: true,
                child: Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: datosQr ?? codigo,
                    padding: EdgeInsets.zero,
                    backgroundColor: const Color(0xFFFFFFFF),
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF181C33),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF181C33),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              BingMini(
                texto: 'Compartir',
                icono: 'share',
                alPresionar: alCompartir,
              ),
              const SizedBox(width: 8),
              BingMini(texto: 'Copiar', icono: 'copy', alPresionar: alCopiar),
            ],
          ),
        ],
      ),
    );
  }
}

/// Estados de una fila de la lista de jugadores (`.pl`).
enum BingJugadorEstado { normal, nuevo, libre, salto }

/// Una fila de la lista de jugadores de la sala.
class BingJugador {
  const BingJugador.normal(this.numero, this.nombre, this.hora)
    : estado = BingJugadorEstado.normal;
  const BingJugador.nuevo(this.numero, this.nombre, this.hora)
    : estado = BingJugadorEstado.nuevo;
  const BingJugador.libre(this.numero)
    : estado = BingJugadorEstado.libre,
      nombre = 'Libre',
      hora = '—';
  const BingJugador.salto(this.nombre)
    : estado = BingJugadorEstado.salto,
      numero = '⋮',
      hora = '';

  final String numero;
  final String nombre;
  final String hora;
  final BingJugadorEstado estado;
}

/// Lista de jugadores (`.plist`): una fila por reserva, con la hora, la fila
/// nueva resaltada en verde y las libres atenuadas.
class BingListaJugadores extends StatelessWidget {
  const BingListaJugadores({super.key, required this.jugadores});

  final List<BingJugador> jugadores;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: paleta.tarjeta,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < jugadores.length; i++)
            _FilaJugador(jugador: jugadores[i], primera: i == 0),
        ],
      ),
    );
  }
}

class _FilaJugador extends StatelessWidget {
  const _FilaJugador({required this.jugador, required this.primera});

  final BingJugador jugador;
  final bool primera;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final nuevo = jugador.estado == BingJugadorEstado.nuevo;
    final libre = jugador.estado == BingJugadorEstado.libre;
    final salto = jugador.estado == BingJugadorEstado.salto;
    final borde = primera ? null : Border(top: BorderSide(color: paleta.linea));

    final contenido = SizedBox(
      height: 40,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child:
                salto
                    ? _PuntosVerticales(color: paleta.apagado)
                    : Text(
                      jugador.numero,
                      textAlign: TextAlign.center,
                      style: BingTexto.figtree(
                        12,
                        800,
                        tabular: true,
                      ).copyWith(color: paleta.apagado),
                    ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              jugador.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  salto
                      ? BingTexto.figtree(
                        11.5,
                        700,
                      ).copyWith(color: paleta.apagado)
                      : BingTexto.figtree(
                        13.5,
                        libre ? 400 : 800,
                      ).copyWith(color: libre ? paleta.apagado : paleta.tinta),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            jugador.hora,
            style: BingTexto.figtree(
              11.5,
              700,
              tabular: true,
            ).copyWith(color: nuevo ? paleta.ok : paleta.apagado),
          ),
        ],
      ),
    );

    if (nuevo) {
      // `.pl.new`: el fondo y la línea superior ocupan todo el ancho.
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: paleta.okSuave, border: borde),
        child: contenido,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(border: borde),
        child: contenido,
      ),
    );
  }
}

/// "⋮" dibujado: Figtree no tiene ese glifo y el navegador usa una fuente de
/// respaldo, así que se pinta igual en todas las plataformas.
class _PuntosVerticales extends StatelessWidget {
  const _PuntosVerticales({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: 2.4),
            Container(
              width: 2.2,
              height: 2.2,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ],
      ),
    );
  }
}
