import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'cuenta_real.dart';
import 'escaner.dart';
import 'paginas/codigo_page.dart';
import 'paginas/elegir_fila_page.dart';
import 'paginas/en_vivo_page.dart';
import 'paginas/en_vivo_simulada_page.dart' show textoHace;
import 'paginas/esperando_page.dart';
import 'paginas/ganaste_page.dart';
import 'paginas/reservar_page.dart';
import 'paginas/salas_abiertas.dart';
import 'sala_cerrada.dart';

/// Mensaje en español para un error del servidor.
String mensajeDeError(Object error) {
  if (error is! ErrorSalaBing) {
    return 'No pudimos conectar. Revisa tu internet e inténtalo de nuevo.';
  }
  return switch (error.codigo) {
    'fila_ocupada' =>
      'Esa fila ya la tomó otra persona. Vuelve atrás y elige otra.',
    'limite_de_filas' => 'Ya tienes una fila en esta sala.',
    'sala_no_abierta' => 'La sala ya no recibe jugadores.',
    'nombre_invalido' => 'El nombre debe tener entre 1 y 18 caracteres.',
    'no_existe' => 'Esa sala ya no existe.',
    _ => 'No pudimos reservar la fila. Inténtalo de nuevo.',
  };
}

void _ir(BuildContext context, Widget pantalla, {bool reemplazar = false}) {
  final ruta = PageRouteBuilder<void>(pageBuilder: (c, _, __) => pantalla);
  final navegador = Navigator.of(context);
  reemplazar ? navegador.pushReplacement(ruta) : navegador.push(ruta);
}

enum _Busqueda { vacio, buscando, encontrada, noExiste, fallo }

/// Recorrido con la sala de verdad: la sala y las filas llegan en vivo y la
/// reserva la decide el servidor. Arranca en el código y el QR, con las salas
/// públicas abiertas debajo.
class FlujoReal extends StatefulWidget {
  const FlujoReal({
    super.key,
    required this.repositorio,
    this.camaraEscaner,
    this.enlaces,
    this.sesion,
  });

  final RepositorioSala repositorio;

  /// Quién juega; sin ella no hay cuentas ni se pide iniciar sesión.
  final SesionJugador? sesion;

  /// Sustituye a la cámara del escáner (pruebas).
  final Widget Function(BuildContext, ValueChanged<String>)? camaraEscaner;

  /// Enlaces que abren la app (el que la lanzó y los que lleguen después). Sin
  /// ellos se usan los del sistema.
  final Stream<Uri>? enlaces;

  @override
  State<FlujoReal> createState() => _FlujoRealState();
}

class _FlujoRealState extends State<FlujoReal> with WidgetsBindingObserver {
  // Una sola suscripción: el diseño cambia con el teclado y no debe abrir otra.
  StreamSubscription<List<SalaEnVivo>>? _suscripcion;
  StreamSubscription<Uri>? _enlaces;
  StreamSubscription<UsuarioBing?>? _usuarioSub;
  UsuarioBing? _usuario;
  List<SalaEnVivo>? _salas;
  bool _errorSalas = false;
  bool _tecladoVisible = false;
  final _editor = GlobalKey<EditableTextState>();

  final _texto = TextEditingController();
  final _foco = FocusNode();
  _Busqueda _busqueda = _Busqueda.vacio;
  SalaEnVivo? _sala;
  int _libres = 0;

  @override
  void initState() {
    super.initState();
    _texto.addListener(_alEscribir);
    WidgetsBinding.instance.addObserver(this);
    _escucharEnlaces();
    _usuarioSub = widget.sesion?.cambios.listen(
      (u) => setState(() => _usuario = u),
    );
    _suscripcion = widget.repositorio.salasAbiertas().listen(
      (salas) => setState(() {
        _salas = salas;
        _errorSalas = false;
      }),
      onError: (_) => setState(() => _errorSalas = true),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _suscripcion?.cancel();
    _enlaces?.cancel();
    _usuarioSub?.cancel();
    _texto.dispose();
    _foco.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final visible = View.of(context).viewInsets.bottom > 0;
    if (visible != _tecladoVisible) setState(() => _tecladoVisible = visible);
  }

  void _escucharEnlaces() {
    final propios = widget.enlaces;
    if (propios != null) {
      _enlaces = propios.listen(_alEnlace);
      return;
    }
    final app = AppLinks();
    // La app puede haberla lanzado un enlace; los siguientes llegan por el flujo.
    unawaited(
      app.getInitialLink().then((uri) {
        if (uri != null) _alEnlace(uri);
      }, onError: (_) {}),
    );
    _enlaces = app.uriLinkStream.listen(_alEnlace, onError: (_) {});
  }

  String? _ultimoEnlace;
  DateTime _ultimoEnlaceHora = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _alEnlace(Uri uri) async {
    final codigo = codigoDeEnlace(uri.toString());
    if (codigo == null) return;
    // El sistema puede entregar el mismo enlace dos veces seguidas.
    final ahora = DateTime.now();
    if (codigo == _ultimoEnlace &&
        ahora.difference(_ultimoEnlaceHora) < const Duration(seconds: 2)) {
      return;
    }
    _ultimoEnlace = codigo;
    _ultimoEnlaceHora = ahora;
    final motivo = await _entrarPorCodigo(context, codigo);
    if (motivo != null && mounted) mostrarAvisoBing(context, motivo);
  }

  /// Abre la sala con ese código (de un QR o de un enlace). Devuelve el motivo
  /// si no se puede entrar; si entra, cambia de pantalla y devuelve `null`.
  Future<String?> _entrarPorCodigo(
    BuildContext contexto,
    String codigo, {
    bool reemplazar = false,
  }) async {
    try {
      final sala = await widget.repositorio.buscar(codigo);
      if (sala == null) return 'No encontramos esa sala. Revisa el código.';
      final llena =
          sala.estado == EstadoSala.llena ||
          (sala.estado == EstadoSala.abierta && sala.libres <= 0);
      if (llena) return 'Esa sala ya está llena.';
      if (sala.estado == EstadoSala.cancelada) return 'Esa sala se cerró.';
      if (sala.estado != EstadoSala.abierta) {
        return 'Esa sala ya no recibe jugadores.';
      }
      if (!contexto.mounted) return null;
      _ir(
        contexto,
        _ElegirFilaReal(repositorio: widget.repositorio, sala: sala),
        reemplazar: reemplazar,
      );
      return null;
    } catch (_) {
      return 'No pudimos conectar. Revisa tu internet.';
    }
  }

  void _abrirBilletera() {
    final billetera = AlcanceSesion.billeteraDe(context);
    if (billetera != null) _ir(context, BilleteraReal(billetera: billetera));
  }

  void _abrirEscaner() {
    _ir(
      context,
      Builder(
        builder:
            (contextoEscaner) => EscanerReal(
              camara: widget.camaraEscaner,
              alLeer:
                  (codigo) => _entrarPorCodigo(
                    contextoEscaner,
                    codigo,
                    reemplazar: true,
                  ),
              alEscribir: () {
                Navigator.of(contextoEscaner).pop();
                _foco.requestFocus();
                _editor.currentState?.requestKeyboard();
              },
            ),
      ),
    );
  }

  Future<void> _alEscribir() async {
    final codigo = _texto.text;
    if (codigo.length < 4) {
      setState(() => _busqueda = _Busqueda.vacio);
      return;
    }
    setState(() => _busqueda = _Busqueda.buscando);
    try {
      final sala = await widget.repositorio.buscar(codigo);
      final filas = sala == null ? <FilaEnVivo>[] : await _filas(codigo);
      if (!mounted || _texto.text != codigo) return;
      setState(() {
        _sala = sala;
        _libres = filas.where((f) => f.libre).length;
        _busqueda = sala == null ? _Busqueda.noExiste : _Busqueda.encontrada;
      });
    } catch (_) {
      if (mounted && _texto.text == codigo) {
        setState(() => _busqueda = _Busqueda.fallo);
      }
    }
  }

  Future<List<FilaEnVivo>> _filas(String codigo) =>
      widget.repositorio.filas(codigo).first;

  Widget _resultado(BuildContext context) {
    final paleta = BingTema.of(context);
    final estilo = BingTexto.figtree(13, 600).copyWith(color: paleta.apagado);
    final sala = _sala;
    return switch (_busqueda) {
      _Busqueda.vacio => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text('Pídele el código a quien organiza', style: estilo),
      ),
      _Busqueda.buscando => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text('Buscando la sala…', style: estilo),
      ),
      _Busqueda.encontrada when sala != null =>
        sala.estado == EstadoSala.abierta
            ? BingEncontrada(
              titulo: sala.nombre,
              detalle:
                  'Organiza ${sala.organizador} · quedan $_libres '
                  '${_libres == 1 ? 'fila libre' : 'filas libres'}',
            )
            : const BingAviso(
              icono: 'lock',
              texto: 'Esta sala ya no recibe jugadores.',
            ),
      _Busqueda.fallo => const BingAviso(
        icono: 'bell',
        texto: 'No pudimos conectar. Revisa tu internet e inténtalo de nuevo.',
      ),
      _ => BingAviso(
        icono: 'bell',
        texto:
            'No encontramos una sala con el código ${_texto.text}. '
            'Revisa que esté bien escrito.',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final sala = _sala;
    final puede =
        _busqueda == _Busqueda.encontrada &&
        sala != null &&
        sala.estado == EstadoSala.abierta &&
        _libres > 0;
    return CodigoPage(
      codigo: _texto.text,
      salaNombre: sala?.nombre ?? '',
      organizador: sala?.organizador ?? '',
      filasLibres: _libres,
      verFilasHabilitado: puede,
      // Quien escribe un código no necesita ver las salas.
      alEscanear: _abrirEscaner,
      accionAncha:
          widget.sesion != null && AlcanceSesion.saldoDe(context) != null,
      accion:
          widget.sesion == null
              ? null
              : AccesoCuenta(
                usuario: _usuario,
                saldo: AlcanceSesion.saldoDe(context),
                alAbrirBilletera: _abrirBilletera,
                alEntrar:
                    () => unawaited(mostrarHojaSesion(context, widget.sesion!)),
                alAbrirCuenta:
                    () => _ir(context, CuentaReal(sesion: widget.sesion!)),
              ),
      bajoElQr:
          (desplazable) =>
              _tecladoVisible
                  ? const SizedBox.shrink()
                  : SalasAbiertas(
                    salas: _salas == null ? null : salasConSitio(_salas!),
                    error: _errorSalas,
                    atenuada: _texto.text.isNotEmpty,
                    desplazable: desplazable,
                    alElegirSala:
                        (sala) => _ir(
                          context,
                          _ElegirFilaReal(
                            repositorio: widget.repositorio,
                            sala: sala,
                          ),
                        ),
                  ),
      casillas: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _foco.requestFocus();
          // Si el teclado se cerró con "atrás", el foco sigue y hay que pedirlo.
          _editor.currentState?.requestKeyboard();
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ListenableBuilder(
              listenable: _texto,
              builder: (_, __) => BingCasillasCodigo(codigo: _texto.text),
            ),
            // El teclado escribe aquí; las casillas solo muestran el texto.
            Positioned(
              left: 0,
              top: 0,
              width: 1,
              height: 1,
              child: Opacity(
                opacity: 0,
                child: EditableText(
                  key: _editor,
                  controller: _texto,
                  focusNode: _foco,
                  autofocus: false,
                  style: BingTexto.figtree(14, 700),
                  cursorColor: paleta.tinta,
                  backgroundCursorColor: paleta.linea,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                    TextInputFormatter.withFunction(
                      (_, nuevo) =>
                          nuevo.copyWith(text: nuevo.text.toUpperCase()),
                    ),
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      resultado: _resultado(context),
      alVerFilas:
          puede
              ? () => _ir(
                context,
                _ElegirFilaReal(repositorio: widget.repositorio, sala: sala),
              )
              : null,
    );
  }
}

class _ElegirFilaReal extends StatelessWidget {
  const _ElegirFilaReal({required this.repositorio, required this.sala});

  final RepositorioSala repositorio;
  final SalaEnVivo sala;

  @override
  Widget build(BuildContext context) {
    return VigilaSalaCerrada(
      repositorio: repositorio,
      codigo: sala.codigo,
      child: StreamBuilder<List<FilaEnVivo>>(
        stream: repositorio.filas(sala.codigo),
        builder: (context, foto) {
          final filas = foto.data;
          if (filas == null) {
            return ColoredBox(color: BingTema.of(context).fondo);
          }
          final primeraLibre = filas.indexWhere((f) => f.libre);
          return ElegirFilaPage(
            salaNombre: sala.nombre,
            cartillas: [for (final f in filas) f.numeros],
            duenos: [for (final f in filas) f.libre ? null : (f.nombre ?? '')],
            seleccionInicial: primeraLibre < 0 ? 1 : primeraLibre + 1,
            alVolver: () => Navigator.of(context).pop(),
            alSeguir: (fila) async {
              if (!filas[fila - 1].libre) return;
              // Mirar la sala es libre; para elegir fila hace falta una cuenta.
              final sesion = AlcanceSesion.de(context);
              if (sesion != null && !sesion.actual.tieneCuenta) {
                if (!await mostrarHojaSesion(context, sesion)) return;
                if (!context.mounted) return;
              }
              _ir(
                context,
                _ReservarReal(
                  repositorio: repositorio,
                  sala: sala,
                  fila: fila,
                  numeros: filas[fila - 1].numeros,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ReservarReal extends StatefulWidget {
  const _ReservarReal({
    required this.repositorio,
    required this.sala,
    required this.fila,
    required this.numeros,
  });

  final RepositorioSala repositorio;
  final SalaEnVivo sala;
  final int fila;
  final List<int> numeros;

  @override
  State<_ReservarReal> createState() => _ReservarRealState();
}

class _ReservarRealState extends State<_ReservarReal> {
  String? _error;
  bool _reservando = false;

  Future<void> _reservar(String nombre) async {
    if (nombre.isEmpty) {
      setState(() => _error = 'Escribe tu nombre para reservar la fila.');
      return;
    }
    setState(() {
      _error = null;
      _reservando = true;
    });
    try {
      await widget.repositorio.reservarFila(
        codigo: widget.sala.codigo,
        fila: widget.fila,
        nombre: nombre,
      );
      if (!mounted) return;
      _ir(
        context,
        _EsperandoReal(
          repositorio: widget.repositorio,
          sala: widget.sala,
          fila: widget.fila - 1,
          nombre: nombre,
        ),
        reemplazar: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = mensajeDeError(e);
        _reservando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return VigilaSalaCerrada(
      repositorio: widget.repositorio,
      codigo: widget.sala.codigo,
      child: ReservarPage(
        salaNombre: widget.sala.nombre,
        organizador: widget.sala.organizador,
        fila: widget.fila,
        numeros: widget.numeros,
        nombreInicial: AlcanceSesion.de(context)?.actual?.primerNombre ?? '',
        alVolver: () => Navigator.of(context).pop(),
        alReservar: _reservar,
        error: _error,
        reservando: _reservando,
      ),
    );
  }
}

class _EsperandoReal extends StatefulWidget {
  const _EsperandoReal({
    required this.repositorio,
    required this.sala,
    required this.fila,
    required this.nombre,
  });

  final RepositorioSala repositorio;
  final SalaEnVivo sala;

  /// Fila reservada (base 0).
  final int fila;
  final String nombre;

  @override
  State<_EsperandoReal> createState() => _EsperandoRealState();
}

class _EsperandoRealState extends State<_EsperandoReal> {
  bool _pasando = false;

  @override
  Widget build(BuildContext context) {
    return VigilaSalaCerrada(
      repositorio: widget.repositorio,
      codigo: widget.sala.codigo,
      child: SalaEnVivoBuilder(
        repositorio: widget.repositorio,
        codigo: widget.sala.codigo,
        espera: ColoredBox(color: BingTema.of(context).fondo),
        constructor: (context, sala, filas) {
          // La partida empieza cuando sale la primera bolilla.
          if (sala.estado == EstadoSala.enJuego &&
              sala.bolillas.isNotEmpty &&
              !_pasando) {
            _pasando = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _ir(
                context,
                _EnVivoReal(
                  repositorio: widget.repositorio,
                  sala: widget.sala,
                  fila: widget.fila,
                  nombre: widget.nombre,
                ),
                reemplazar: true,
              );
            });
          }
          return EsperandoPage(
            nombre: widget.nombre,
            salaNombre: sala.nombre,
            organizador: sala.organizador,
            fila: widget.fila + 1,
            numeros: filas[widget.fila].numeros,
            ocupadas: filas.where((f) => !f.libre).length,
            total: filas.length,
          );
        },
      ),
    );
  }
}

class _EnVivoReal extends StatefulWidget {
  const _EnVivoReal({
    required this.repositorio,
    required this.sala,
    required this.fila,
    required this.nombre,
  });

  final RepositorioSala repositorio;
  final SalaEnVivo sala;
  final int fila;
  final String nombre;

  @override
  State<_EnVivoReal> createState() => _EnVivoRealState();
}

class _EnVivoRealState extends State<_EnVivoReal> {
  Timer? _segundo;
  int _vistas = 0;
  DateTime _ultimaSalida = DateTime.now();
  bool _celebrado = false;

  @override
  void initState() {
    super.initState();
    // Reconstruye cada segundo para que el "hace N s" avance.
    _segundo = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _segundo?.cancel();
    super.dispose();
  }

  void _celebrar(SalaEnVivo sala, List<FilaEnVivo> filas) {
    final g = sala.ganadoras.firstWhere((g) => g.fila == widget.fila + 1);
    Future<void>.delayed(const Duration(milliseconds: 520), () {
      if (!mounted) return;
      _ir(
        context,
        GanastePage(
          nombre: widget.nombre,
          fila: widget.fila + 1,
          numeros: filas[widget.fila].numeros,
          bolillaFinal: sala.bolillas[g.bolillaIndice - 1],
          cantidadBolillas: g.bolillaIndice,
          organizador: sala.organizador,
          alVerCartilla: () => Navigator.of(context).pop(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return VigilaSalaCerrada(
      repositorio: widget.repositorio,
      codigo: widget.sala.codigo,
      child: SalaEnVivoBuilder(
        repositorio: widget.repositorio,
        codigo: widget.sala.codigo,
        espera: ColoredBox(color: BingTema.of(context).fondo),
        constructor: (context, sala, filas) {
          if (sala.bolillas.length != _vistas) {
            _vistas = sala.bolillas.length;
            _ultimaSalida = DateTime.now();
          }
          if (sala.ganoLaFila(widget.fila) && !_celebrado) {
            _celebrado = true;
            _celebrar(sala, filas);
          }
          if (sala.bolillas.isEmpty) {
            // Se deshizo la única bolilla: se vuelve a esperar la primera.
            return EsperandoPage(
              nombre: widget.nombre,
              salaNombre: sala.nombre,
              organizador: sala.organizador,
              fila: widget.fila + 1,
              numeros: filas[widget.fila].numeros,
              ocupadas: filas.where((f) => !f.libre).length,
              total: filas.length,
            );
          }
          return EnVivoPage(
            salaNombre: sala.nombre,
            organizador: sala.organizador,
            cartillas: [for (final f in filas) f.numeros],
            nombres: [for (final f in filas) f.nombre ?? ''],
            miFila: widget.fila + 1,
            bolillas: sala.bolillas,
            hace: textoHace(_ultimaSalida, DateTime.now()),
            mostrar: filas.length - 1,
          );
        },
      ),
    );
  }
}
