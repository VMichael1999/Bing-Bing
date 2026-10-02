import 'dart:async';
import 'dart:math' as math;

import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

import 'ganador_page.dart';

const _letras = ['B', 'I', 'N', 'G', 'O'];

/// Decide qué bolilla sale. En producción lo resuelve el servidor; el modo demo
/// devuelve la siguiente de la partida del diseño.
typedef Sorteo = int? Function(List<int> salidas);

/// `JuegoPage`: pestañas Bolilla (`org-06`), Cartilla (`org-07`) y Tablero
/// (`org-08`). Al tocar la bolilla grande se saca la siguiente.
class JuegoPage extends StatefulWidget {
  const JuegoPage({
    super.key,
    required this.salaNombre,
    required this.codigo,
    required this.cartillas,
    required this.nombres,
    required this.bolillasIniciales,
    required this.sorteo,
    this.pestanaInicial = 0,
    this.alTerminar,
    this.conAutomatico = false,
    this.cadaAutomatico = const Duration(milliseconds: 2800),
  });

  final String salaNombre;
  final String codigo;
  final List<List<int>> cartillas;
  final List<String> nombres;
  final List<int> bolillasIniciales;
  final Sorteo sorteo;
  final int pestanaInicial;
  final VoidCallback? alTerminar;

  /// Muestra el interruptor "Automático" (solo para la simulación).
  final bool conAutomatico;
  final Duration cadaAutomatico;

  @override
  State<JuegoPage> createState() => _JuegoPageState();
}

class _JuegoPageState extends State<JuegoPage>
    with SingleTickerProviderStateMixin {
  static const _cambiosAlSortear = 12;
  static const _msCambio = 55;
  static const _esperaGanador = Duration(milliseconds: 520);

  late final List<int> _salidas = [...widget.bolillasIniciales];
  late int _pestana = widget.pestanaInicial;
  late final AnimationController _balanceo;
  Timer? _reloj;
  Timer? _auto;
  bool _automatico = false;
  bool _ocupado = false;
  int? _mostrada;
  String _mensaje = '';

  @override
  void initState() {
    super.initState();
    _balanceo = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    if (_salidas.isNotEmpty) {
      _mostrada = _salidas.last;
      _mensaje = _textoSalio(_salidas.last);
    }
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _auto?.cancel();
    _balanceo.dispose();
    super.dispose();
  }

  void _alternarAutomatico() {
    setState(() => _automatico = !_automatico);
    _auto?.cancel();
    if (!_automatico) return;
    _auto = Timer.periodic(widget.cadaAutomatico, (t) {
      if (!mounted) return;
      // No saca bolillas mientras hay otra pantalla encima (el ganador).
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
      if (widget.sorteo(_salidas) == null) {
        t.cancel();
        setState(() => _automatico = false);
        return;
      }
      _sacar();
    });
  }

  int _filasCon(int n) => widget.cartillas.where((f) => f.contains(n)).length;

  String _textoSalio(int n) {
    final filas = _filasCon(n);
    return 'Salió la ${etiqueta(n, 5)} · ${filas == 0 ? 'ninguna fila la tiene' : 'se marcó en $filas ${filas == 1 ? 'fila' : 'filas'}'}';
  }

  void _sacar() {
    if (_ocupado) return;
    final n = widget.sorteo(_salidas);
    if (n == null) return;
    setState(() => _ocupado = true);
    final reducir = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reducir) {
      _terminarSorteo(n);
      return;
    }
    _balanceo.repeat(reverse: true);
    final azar = math.Random();
    final pool = [
      for (var k = 1; k <= totalBolillas(5); k++)
        if (!_salidas.contains(k)) k,
    ];
    var cambios = 0;
    _reloj = Timer.periodic(const Duration(milliseconds: _msCambio), (t) {
      if (!mounted) return;
      cambios++;
      if (cambios >= _cambiosAlSortear) {
        t.cancel();
        _balanceo
          ..stop()
          ..value = 0;
        _terminarSorteo(n);
      } else {
        setState(() => _mostrada = pool[azar.nextInt(pool.length)]);
      }
    });
  }

  void _terminarSorteo(int n) {
    setState(() {
      _salidas.add(n);
      _mostrada = n;
      _mensaje = _textoSalio(n);
    });
    final ganadoras = ganadoresNuevos(widget.cartillas, _salidas);
    if (ganadoras.isEmpty) {
      setState(() => _ocupado = false);
      return;
    }
    // Durante la espera no se puede sacar otra bolilla.
    final reducir = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    Future<void>.delayed(reducir ? Duration.zero : _esperaGanador, () {
      if (!mounted) return;
      setState(() => _ocupado = false);
      _mostrarGanador(ganadoras.first);
    });
  }

  void _mostrarGanador(int fila) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder:
            (context, _, __) => GanadorPage(
              nombre: widget.nombres[fila],
              fila: fila + 1,
              numeros: widget.cartillas[fila],
              bolillaFinal: _salidas.last,
              cantidadBolillas: _salidas.length,
              jugadores: widget.cartillas.length,
              alSeguir: () => Navigator.of(context).pop(),
              alTerminar:
                  widget.alTerminar ?? () => Navigator.of(context).pop(),
            ),
      ),
    );
  }

  void _deshacer() {
    if (_ocupado || _salidas.isEmpty) return;
    setState(() {
      _salidas.removeLast();
      _mostrada = _salidas.isEmpty ? null : _salidas.last;
      _mensaje = _salidas.isEmpty ? '' : _textoSalio(_salidas.last);
    });
  }

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final salidas = _salidas.toSet();
    final aUna = filasAUnaBolilla(widget.cartillas, salidas).length;
    final ultima = _salidas.isEmpty ? null : _salidas.last;
    return ColoredBox(
      color: paleta.fondo,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                child: switch (_pestana) {
                  0 => _bolilla(paleta, salidas, ultima),
                  1 => _cartilla(salidas, ultima, aUna),
                  _ => _tablero(salidas, ultima),
                },
              ),
            ),
            BingTabs(
              pestanas: const [
                (icono: 'grid', texto: 'Bolilla'),
                (icono: 'users', texto: 'Cartilla'),
                (icono: 'qr', texto: 'Tablero'),
              ],
              activa: _pestana,
              alCambiar: (i) => setState(() => _pestana = i),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bolilla(BingPaleta paleta, Set<int> salidas, int? ultima) {
    final orden = ordenarPorAvance(widget.cartillas, salidas).take(3);
    final recientes = _salidas.reversed.take(5).toList();
    return Column(
      children: [
        BingEncabezado(
          conVolver: false,
          titulo: widget.salaNombre,
          subtitulo:
              'Código ${widget.codigo} · ${widget.cartillas.length} jugadores',
          accion: const BingChip('En vivo', tipo: BingChipTipo.vivo),
        ),
        const SizedBox(height: 10),
        _Escenario(
          mostrada: _mostrada,
          balanceo: _balanceo,
          mensaje: _mensaje,
          alTocar: _sacar,
        ),
        if (widget.conAutomatico) ...[
          BingMini(
            texto: _automatico ? 'Automático: sí' : 'Automático: no',
            icono: 'swap',
            alPresionar: _alternarAutomatico,
          ),
        ],
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: paleta.tarjeta,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: BingBandejaBolillas(
                  ultimas: recientes,
                  letras: _letras,
                  columnas: 5,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_salidas.length}/${totalBolillas(5)}',
                    style: BingTexto.bungee(17).copyWith(color: paleta.tinta),
                  ),
                  Text(
                    'bolillas',
                    style: BingTexto.figtree(
                      11.5,
                      700,
                    ).copyWith(color: paleta.apagado),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Van ganando',
              style: BingTexto.figtree(14, 800).copyWith(color: paleta.tinta),
            ),
            BingMini(texto: 'Deshacer', icono: 'undo', alPresionar: _deshacer),
          ],
        ),
        const SizedBox(height: 10),
        BingCartilla(
          letras: _letras,
          filas: [
            for (final i in orden)
              BingFilaCompacta(
                indice: i + 1,
                numeros: widget.cartillas[i],
                salidas: salidas,
                recientes: {if (ultima != null) ultima},
                nombre: widget.nombres[i],
              ),
          ],
        ),
      ],
    );
  }

  Widget _cartilla(Set<int> salidas, int? ultima, int aUna) {
    final paleta = BingTema.of(context);
    final orden = ordenarPorAvance(widget.cartillas, salidas);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cartilla',
                    style: BingTexto.tituloPantalla.copyWith(
                      color: paleta.tinta,
                    ),
                  ),
                  Text(
                    '${_salidas.length} bolillas · $aUna ${aUna == 1 ? 'fila' : 'filas'} a una',
                    style: BingTexto.subtitulo.copyWith(color: paleta.apagado),
                  ),
                ],
              ),
            ),
            const BingMini(texto: 'Ordenar: avance', icono: 'swap'),
          ],
        ),
        const SizedBox(height: 10),
        BingCartilla(
          letras: _letras,
          filas: [
            for (final i in orden)
              BingFilaCompacta(
                indice: i + 1,
                numeros: widget.cartillas[i],
                salidas: salidas,
                recientes: {if (ultima != null) ultima},
                nombre: widget.nombres[i],
              ),
          ],
        ),
      ],
    );
  }

  Widget _tablero(Set<int> salidas, int? ultima) {
    final paleta = BingTema.of(context);
    final total = totalBolillas(5);
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tablero',
                style: BingTexto.tituloPantalla.copyWith(color: paleta.tinta),
              ),
              Text(
                '${_salidas.length} de $total · quedan ${total - _salidas.length} en la tómbola',
                style: BingTexto.subtitulo.copyWith(color: paleta.apagado),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        BingTablero(
          columnas: 5,
          salidas: salidas,
          letras: _letras,
          ultima: ultima,
        ),
        const SizedBox(height: 10),
        BingSeccion(
          cabecera: 'ÚLTIMAS',
          children: [
            BingBandejaBolillas(
              ultimas: _salidas.reversed.take(6).toList(),
              letras: _letras,
              columnas: 5,
            ),
          ],
        ),
      ],
    );
  }
}

/// Bolilla grande (150 dp): al tocarla se saca la siguiente. Mientras sortea se
/// balancea −14° ↔ 14° con un desplazamiento de −3 a 2 dp cada 110 ms.
class _Escenario extends StatefulWidget {
  const _Escenario({
    required this.mostrada,
    required this.balanceo,
    required this.mensaje,
    required this.alTocar,
  });

  final int? mostrada;
  final Animation<double> balanceo;
  final String mensaje;
  final VoidCallback alTocar;

  @override
  State<_Escenario> createState() => _EscenarioState();
}

class _EscenarioState extends State<_Escenario> {
  bool _presionada = false;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final n = widget.mostrada;
    final reducir = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    // Sin bolilla aún se muestra la columna N con un signo de pregunta (estado
    // que el diseño no define: pendiente de confirmar).
    final bolilla = BingBolilla(
      columna: n == null ? 2 : columnaDe(n),
      numero: n,
      letra: n == null ? null : _letras[columnaDe(n)],
      tamano: BingBolillaTamano.xl,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Column(
        children: [
          Text(
            'Toca para sacar la siguiente',
            style: BingTexto.figtree(13, 800).copyWith(color: paleta.apagado),
          ),
          const SizedBox(height: 10),
          Semantics(
            button: true,
            label: 'Sacar bolilla',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => setState(() => _presionada = true),
              onTapUp: (_) => setState(() => _presionada = false),
              onTapCancel: () => setState(() => _presionada = false),
              onTap: widget.alTocar,
              child: AnimatedScale(
                scale: _presionada ? 0.95 : 1,
                duration:
                    reducir ? Duration.zero : const Duration(milliseconds: 150),
                child: AnimatedBuilder(
                  animation: widget.balanceo,
                  builder: (context, hijo) {
                    // En reposo la bolilla va derecha; solo se balancea mientras
                    // sortea (el controlador vale 0 al detenerse).
                    final rodando =
                        widget.balanceo.status == AnimationStatus.forward ||
                        widget.balanceo.status == AnimationStatus.reverse;
                    final v = rodando ? widget.balanceo.value : 0.5;
                    return Transform.translate(
                      offset: Offset(0, rodando ? -3 + 5 * v : 0),
                      child: Transform.rotate(
                        angle: rodando ? (-14 + 28 * v) * math.pi / 180 : 0,
                        child: hijo,
                      ),
                    );
                  },
                  child: bolilla,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _Dicho(mensaje: widget.mensaje),
        ],
      ),
    );
  }
}

/// "Salió la **N-31** · se marcó en 2 filas" con la etiqueta en negrita.
class _Dicho extends StatelessWidget {
  const _Dicho({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final base = BingTexto.figtree(14, 700).copyWith(color: paleta.tinta);
    final partes = mensaje.split(' · ');
    final cabeza = partes.first; // "Salió la N-31"
    final i = cabeza.lastIndexOf(' ');
    return Text.rich(
      textAlign: TextAlign.center,
      TextSpan(
        style: base,
        children: [
          if (mensaje.isNotEmpty) ...[
            TextSpan(text: cabeza.substring(0, i + 1)),
            TextSpan(
              text: cabeza.substring(i + 1),
              style: BingTexto.figtree(14, 800).copyWith(color: paleta.tinta),
            ),
            if (partes.length > 1) TextSpan(text: ' · ${partes[1]}'),
          ],
        ],
      ),
    );
  }
}
