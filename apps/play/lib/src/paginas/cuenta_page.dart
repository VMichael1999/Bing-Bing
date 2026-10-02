import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

/// `jug-13-cuenta`: datos de la cuenta, cómo inicia sesión y las acciones de
/// cuenta (borrarla es obligatorio en las tiendas).
class CuentaPage extends StatelessWidget {
  const CuentaPage({
    super.key,
    required this.nombre,
    required this.correo,
    this.googleVinculado = true,
    this.alVolver,
    this.alCerrarSesion,
    this.alEliminar,
    this.ocupado = false,
  });

  final String nombre;
  final String correo;
  final bool googleVinculado;
  final VoidCallback? alVolver;
  final VoidCallback? alCerrarSesion;
  final VoidCallback? alEliminar;

  /// Hay una operación en curso (cerrar sesión o eliminar): los botones se
  /// apagan para no repetirla.
  final bool ocupado;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final inicial =
        nombre.trim().isEmpty ? '?' : nombre.trim()[0].toUpperCase();
    return ColoredBox(
      color: paleta.fondo,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
          child: Column(
            children: [
              BingEncabezado(
                titulo: 'Mi cuenta',
                subtitulo: '',
                alVolver: alVolver,
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: paleta.tarjeta,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: paleta.dauber,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        inicial,
                        style: BingTexto.bungee(
                          28,
                        ).copyWith(color: paleta.dauberTinta),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nombre,
                      textAlign: TextAlign.center,
                      style: BingTexto.figtree(
                        18,
                        800,
                      ).copyWith(color: paleta.tinta),
                    ),
                    Text(
                      correo,
                      textAlign: TextAlign.center,
                      style: BingTexto.figtree(
                        13,
                        600,
                      ).copyWith(color: paleta.apagado),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _Seccion(
                titulo: 'INICIO DE SESIÓN',
                filas: [
                  _Fila(
                    icono: 'mail',
                    titulo: 'Google',
                    detalle: correo,
                    derecha:
                        googleVinculado
                            ? const BingChip(
                              'Vinculado',
                              tipo: BingChipTipo.ok,
                              icono: 'check',
                            )
                            : null,
                  ),
                  const _Fila(
                    icono: 'phone',
                    titulo: 'Celular',
                    detalle: 'Para entrar con un código SMS',
                    derecha: BingChip('Pronto', tipo: BingChipTipo.pronto),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Opacity(
                opacity: ocupado ? 0.5 : 1,
                child: BingBoton(
                  texto: 'Cerrar sesión',
                  tipo: BingBotonTipo.linea,
                  alPresionar: ocupado ? null : alCerrarSesion,
                ),
              ),
              const SizedBox(height: 10),
              Semantics(
                button: true,
                label: 'Eliminar mi cuenta',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: ocupado ? null : alEliminar,
                  child: ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Eliminar mi cuenta',
                        textAlign: TextAlign.center,
                        style: BingTexto.figtree(
                          13.5,
                          800,
                        ).copyWith(color: paleta.dauber),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta con título y filas separadas por una línea (`.sec`).
class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.filas});

  final String titulo;
  final List<_Fila> filas;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: paleta.tarjeta,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: BingTexto.figtree(
              12.5,
              800,
              espaciado: 0.03 * 12.5,
            ).copyWith(color: paleta.apagado),
          ),
          const SizedBox(height: 9),
          for (var i = 0; i < filas.length; i++) ...[
            if (i > 0) Container(height: 1, color: paleta.linea),
            filas[i],
          ],
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.icono,
    required this.titulo,
    required this.detalle,
    this.derecha,
  });

  final String icono;
  final String titulo;
  final String detalle;
  final Widget? derecha;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: [
          SizedBox(
            width: 24,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: BingTexto.figtree(
                    13.5,
                    700,
                  ).copyWith(color: paleta.tinta),
                ),
                Text(
                  detalle,
                  style: BingTexto.figtree(
                    12,
                    600,
                  ).copyWith(color: paleta.apagado),
                ),
              ],
            ),
          ),
          if (derecha != null) ...[const SizedBox(width: 10), derecha!],
        ],
      ),
    );
  }
}
