import 'dart:math' as math;

import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Bolillas que flotan detrás del marco: columna, número, letra, diámetro,
/// posición en el diseño de 320 × 656 dp y desfase de la animación (segundos).
const _flotantes = <
  ({int col, int num, String letra, double d, double x, double y, double fase})
>[
  (col: 0, num: 9, letra: 'B', d: 46, x: 10, y: 128, fase: 0),
  (col: 1, num: 23, letra: 'I', d: 34, x: 246, y: 112, fase: 1.1),
  (col: 2, num: 41, letra: 'N', d: 54, x: -14, y: 296, fase: 0.5),
  (col: 3, num: 52, letra: 'G', d: 40, x: 270, y: 262, fase: 1.7),
  (col: 4, num: 68, letra: 'O', d: 58, x: 26, y: 500, fase: 0.9),
  (col: 0, num: 3, letra: 'B', d: 36, x: 228, y: 520, fase: 0.3),
  (col: 1, num: 17, letra: 'I', d: 44, x: 262, y: 596, fase: 1.4),
  (col: 3, num: 58, letra: 'G', d: 30, x: 150, y: 478, fase: 0.7),
];

/// `radial-gradient(circle at 50% 46%, rgba(255,255,255,.07), rgba(0,0,0,.55) 70%)`.
/// CSS mezcla los colores con la opacidad ya aplicada; Flutter no, así que se
/// reparte en pasos con el color intermedio calculado a mano.
final _vineta = () {
  const pasos = 8;
  final colores = <Color>[];
  final paradas = <double>[];
  for (var i = 0; i <= pasos; i++) {
    final t = i / pasos;
    final alfa = 0.07 + (0.55 - 0.07) * t;
    final blanco = 255 * 0.07 * (1 - t) / alfa;
    colores.add(
      Color.fromRGBO(blanco.round(), blanco.round(), blanco.round(), alfa),
    );
    paradas.add(0.7 * t);
  }
  return RadialGradient(
    center: const Alignment(0, -0.012),
    radius: 1.215,
    colors: colores,
    stops: paradas,
  );
}();

const _mitadCiclo = 5.5; // s: de ida; otro tanto de vuelta.

/// `jug-08-escanear`: la cámara con un marco, la linterna y la salida de siempre
/// (escribir el código), con bolillas flotando.
class EscanerPage extends StatefulWidget {
  const EscanerPage({
    super.key,
    this.camara,
    this.linternaEncendida = false,
    this.alLinterna,
    this.alEscribir,
    this.alVolver,
  });

  /// Vista de la cámara; sin ella se ve el fondo oscuro del diseño.
  final Widget? camara;
  final bool linternaEncendida;
  final VoidCallback? alLinterna;
  final VoidCallback? alEscribir;
  final VoidCallback? alVolver;

  @override
  State<EscanerPage> createState() => _EscanerPageState();
}

class _EscanerPageState extends State<EscanerPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reloj = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2 * 11),
  );
  bool _conMovimiento = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final quieto = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _conMovimiento = !quieto;
    if (_conMovimiento) {
      if (!_reloj.isAnimating) _reloj.repeat();
    } else {
      _reloj.stop();
    }
  }

  @override
  void dispose() {
    _reloj.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final arriba = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0x00000000),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.26, -0.97),
            end: Alignment(0.26, 0.97),
            colors: [Color(0xFF222844), Color(0xFF0B0D1C)],
            stops: [0, 0.7],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.camara != null) Positioned.fill(child: widget.camara!),
            // Viñeta del diseño (`.cam::before`).
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: _vineta),
                ),
              ),
            ),
            Positioned.fill(
              top: arriba,
              child: LayoutBuilder(
                builder: (context, caja) {
                  final ancho = caja.maxWidth;
                  final alto = caja.maxHeight;
                  return Stack(
                    children: [
                      for (final b in _flotantes)
                        Positioned(
                          left: b.x / 320 * ancho,
                          top: b.y / 656 * alto,
                          child: _Flotante(reloj: _reloj, datos: b),
                        ),
                      Positioned(
                        top: 6,
                        left: 14,
                        right: 14,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _BotonCristal(
                              icono: 'left',
                              etiqueta: 'Volver',
                              alPresionar: widget.alVolver,
                            ),
                            _BotonCristal(
                              icono: 'flash',
                              etiqueta:
                                  widget.linternaEncendida
                                      ? 'Apagar linterna'
                                      : 'Encender linterna',
                              activo: widget.linternaEncendida,
                              alPresionar: widget.alLinterna,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 78,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            Text(
                              'Apunta al QR de la sala',
                              textAlign: TextAlign.center,
                              style: BingTexto.figtree(
                                16,
                                800,
                              ).copyWith(color: const Color(0xFFFFFFFF)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Lo lee solo, sin tocar nada',
                              textAlign: TextAlign.center,
                              style: BingTexto.figtree(
                                12.5,
                                600,
                              ).copyWith(color: const Color(0xBFFFFFFF)),
                            ),
                          ],
                        ),
                      ),
                      Center(child: _Marco(color: paleta.dauber)),
                      Positioned(
                        bottom: 24,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: _Pildora(alPresionar: widget.alEscribir),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una bolilla que sube y baja girando un poco (`@keyframes flota`).
class _Flotante extends StatelessWidget {
  const _Flotante({required this.reloj, required this.datos});

  final Animation<double> reloj;
  final ({
    int col,
    int num,
    String letra,
    double d,
    double x,
    double y,
    double fase,
  })
  datos;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.92,
      child: AnimatedBuilder(
        animation: reloj,
        child: BingBolilla(
          columna: datos.col,
          numero: datos.num,
          letra: datos.letra,
          diametro: datos.d,
        ),
        builder: (context, hijo) {
          // Sin movimiento el reloj está parado en 0 y la bolilla queda quieta.
          final quieto = !reloj.isAnimating;
          var u = 0.0;
          if (!quieto) {
            final t = (reloj.value * 22 + datos.fase) % (2 * _mitadCiclo);
            u = Curves.easeInOut.transform(
              t < _mitadCiclo
                  ? t / _mitadCiclo
                  : (2 * _mitadCiclo - t) / _mitadCiclo,
            );
          }
          final angulo = quieto ? 0.0 : (-8 + 17 * u) * math.pi / 180;
          return Transform.translate(
            offset: Offset(0, -16 * u),
            child: Transform.rotate(angle: angulo, child: hijo),
          );
        },
      ),
    );
  }
}

/// Botón redondo translúcido sobre la cámara (`.top2 .icb`).
class _BotonCristal extends StatelessWidget {
  const _BotonCristal({
    required this.icono,
    required this.etiqueta,
    this.activo = false,
    this.alPresionar,
  });

  final String icono;
  final String etiqueta;
  final bool activo;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Semantics(
      button: true,
      toggled: activo ? true : null,
      label: etiqueta,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: alPresionar,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: activo ? paleta.okSuave : const Color(0x24FFFFFF),
          ),
          child: BingIcono(
            icono,
            color: activo ? paleta.tinta : const Color(0xFFFFFFFF),
          ),
        ),
      ),
    );
  }
}

/// "Escribir el código" (`.rb`).
class _Pildora extends StatelessWidget {
  const _Pildora({this.alPresionar});

  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Escribir el código',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: alPresionar,
        child: ExcludeSemantics(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0x24FFFFFF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BingIcono(
                  'pen',
                  color: Color(0xFFFFFFFF),
                  tamano: BingIconoTamano.s,
                ),
                const SizedBox(width: 8),
                Text(
                  'Escribir el código',
                  style: BingTexto.figtree(
                    14,
                    800,
                  ).copyWith(color: const Color(0xFFFFFFFF)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Marco de 226 × 226 con las cuatro esquinas y la línea de lectura.
class _Marco extends StatelessWidget {
  const _Marco({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 226,
      height: 226,
      child: Stack(
        children: [
          for (final e in _Esquina.values) e.dibujar(),
          Positioned(
            left: 14,
            right: 14,
            top: 226 * 0.52,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: color,
                boxShadow: [BoxShadow(color: color, blurRadius: 14)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Esquina {
  arribaIzq(true, true, false, false),
  arribaDer(true, false, false, true),
  abajoIzq(false, true, true, false),
  abajoDer(false, false, true, true);

  const _Esquina(this.arriba, this.izquierda, this.abajo, this.derecha);

  final bool arriba;
  final bool izquierda;
  final bool abajo;
  final bool derecha;

  Widget dibujar() {
    const blanco = BorderSide(color: Color(0xFFFFFFFF), width: 4);
    const ninguno = BorderSide.none;
    return Positioned(
      left: izquierda ? 0 : null,
      right: derecha ? 0 : null,
      top: arriba ? 0 : null,
      bottom: abajo ? 0 : null,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          border: Border(
            top: arriba ? blanco : ninguno,
            bottom: abajo ? blanco : ninguno,
            left: izquierda ? blanco : ninguno,
            right: derecha ? blanco : ninguno,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(arriba && izquierda ? 14 : 0),
            topRight: Radius.circular(arriba && derecha ? 14 : 0),
            bottomLeft: Radius.circular(abajo && izquierda ? 14 : 0),
            bottomRight: Radius.circular(abajo && derecha ? 14 : 0),
          ),
        ),
      ),
    );
  }
}

/// `jug-08b-camara-denegada`: explica por qué se pide la cámara y ofrece abrir
/// los ajustes o escribir el código.
class CamaraDenegadaPage extends StatelessWidget {
  const CamaraDenegadaPage({
    super.key,
    this.alAbrirAjustes,
    this.alEscribir,
    this.alVolver,
  });

  final VoidCallback? alAbrirAjustes;
  final VoidCallback? alEscribir;
  final VoidCallback? alVolver;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return ColoredBox(
      color: paleta.fondo,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                child: Column(
                  children: [
                    BingEncabezado(
                      titulo: 'Escanear el QR',
                      subtitulo: '',
                      alVolver: alVolver,
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
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
                                    'camera',
                                    color: paleta.apagado,
                                    tamano: BingIconoTamano.l,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Necesitamos la cámara',
                                textAlign: TextAlign.center,
                                style: BingTexto.figtree(
                                  19,
                                  800,
                                ).copyWith(color: paleta.tinta),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Solo la usamos para leer el QR de la sala. No '
                                'guardamos fotos ni video.',
                                textAlign: TextAlign.center,
                                style: BingTexto.figtree(
                                  14,
                                  500,
                                ).copyWith(color: paleta.apagado),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            BingPie(
              boton: BingBoton(
                texto: 'Abrir ajustes',
                tipo: BingBotonTipo.tinta,
                alPresionar: alAbrirAjustes,
              ),
              botonSecundario: BingBoton(
                texto: 'Escribir el código',
                tipo: BingBotonTipo.linea,
                icono: 'pen',
                alPresionar: alEscribir,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
