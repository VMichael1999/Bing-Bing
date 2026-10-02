import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'ajustes_real.dart';
import 'compartir.dart';
import 'paginas/cartilla_llena_sheet.dart';
import 'paginas/cerrar_sala_hoja.dart';
import 'paginas/entrar_page.dart';
import 'paginas/juego_page.dart';
import 'paginas/mis_partidas_page.dart';
import 'paginas/nueva_partida_page.dart';
import 'paginas/sala_abierta_page.dart';

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

/// "2 oct · sala abierta", "26 set · terminada · ganó la fila 5"…
String detalleDeSala(SalaEnVivo sala) {
  final fecha = sala.creadaEn;
  final cuando =
      fecha == null ? null : '${fecha.day} ${_meses[fecha.month - 1]}';
  final estado = switch (sala.estado) {
    EstadoSala.abierta => 'sala abierta',
    EstadoSala.llena => 'sala llena',
    EstadoSala.enJuego => 'en juego',
    EstadoSala.terminada => 'terminada',
    EstadoSala.cancelada => 'cerrada',
  };
  final gano =
      sala.ganadoras.isEmpty
          ? null
          : 'ganó la fila ${sala.ganadoras.first.fila}';
  return [
    if (cuando != null) cuando,
    estado,
    if (gano != null) gano,
  ].join(' · ');
}

/// Mensaje en español para un error del servidor.
String mensajeDeError(Object error) {
  if (error is! ErrorSalaBing) {
    return 'No pudimos conectar. Revisa tu internet e inténtalo de nuevo.';
  }
  return switch (error.codigo) {
    'nombre_invalido' => 'Escribe un nombre de 1 a 40 caracteres.',
    'sala_no_llena' => 'Aún faltan jugadores para llenar la cartilla.',
    'permission-denied' => 'Esta cuenta no puede organizar partidas.',
    'columnas_no_disponible' => 'Las 6 columnas llegan pronto.',
    'sala_ya_empezada' => 'La partida ya empezó: se juega hasta el final.',
    'motivo_invalido' => 'El motivo admite hasta 120 caracteres.',
    'filas_invalidas' => 'Las filas por jugador deben ser de 1 a 20.',
    'precio_invalido' => 'El precio por fila debe ser un número de 0 a 1000.',
    'premio_invalido' =>
      'El premio no puede pasar de lo que queda tras la comisión.',
    _ => 'No se pudo completar la acción. Inténtalo de nuevo.',
  };
}

String _hora(DateTime? f) =>
    f == null
        ? '—'
        : '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';

/// Lista de la sala abierta como la dibuja el diseño: las 5 primeras filas
/// reservadas, un salto con las del medio, la última en llegar en verde y las
/// libres. Las reservas llegan en cualquier orden, no en el de las filas.
List<BingJugador> jugadoresDeLaSala(List<FilaEnVivo> filas) {
  final ocupadas = [
    for (var i = 0; i < filas.length; i++)
      if (!filas[i].libre) i,
  ];
  BingJugador normal(int i) => BingJugador.normal(
    '${i + 1}',
    filas[i].nombre ?? '',
    _hora(filas[i].reservadaEn),
  );
  final libres = [
    for (var i = 0; i < filas.length; i++)
      if (filas[i].libre) BingJugador.libre('${i + 1}'),
  ];
  if (ocupadas.length <= 6) {
    return [for (final i in ocupadas) normal(i), ...libres];
  }

  // La última en llegar es la de reserva más reciente.
  final reciente = ocupadas.reduce(
    (a, b) =>
        (filas[b].reservadaEn ?? DateTime(0)).isAfter(
              filas[a].reservadaEn ?? DateTime(0),
            )
            ? b
            : a,
  );
  final resto = ocupadas.where((i) => i != reciente).toList();
  final medio = resto.skip(5).toList();
  final contiguas =
      medio.isNotEmpty && medio.last - medio.first == medio.length - 1;
  return [
    for (final i in resto.take(5)) normal(i),
    if (medio.length == 1)
      normal(medio.single)
    else if (medio.length > 1)
      BingJugador.salto(
        contiguas
            ? 'filas ${medio.first + 1} a ${medio.last + 1}'
            : '${medio.length} filas más',
      ),
    BingJugador.nuevo(
      '${reciente + 1}',
      filas[reciente].nombre ?? '',
      'recién entró',
    ),
    ...libres,
  ];
}

void _ir(
  BuildContext context,
  Widget pantalla, {
  bool reemplazar = false,
  String? nombre,
}) {
  final ruta = PageRouteBuilder<void>(
    settings: RouteSettings(name: nombre),
    pageBuilder: (c, _, __) => pantalla,
  );
  final navegador = Navigator.of(context);
  reemplazar ? navegador.pushReplacement(ruta) : navegador.push(ruta);
}

Widget _espera(BuildContext context) =>
    ColoredBox(color: BingTema.of(context).fondo);

/// Recorrido con la sala de verdad: entrar, ver mis partidas, crear una sala,
/// esperar a que se llene, sortear y ver quién gana. El azar y los permisos los
/// resuelve el servidor.
class FlujoHostReal extends StatefulWidget {
  const FlujoHostReal({
    super.key,
    required this.repositorio,
    required this.entrar,
    this.organizadorActual,
    this.sesion,
  });

  final RepositorioOrganizador repositorio;

  /// La cuenta de quien organiza; sin ella la tuerca de ajustes no hace nada.
  final SesionJugador? sesion;

  /// Inicia sesión y devuelve el nombre de quien organiza; `null` si cancela.
  final Future<String?> Function() entrar;

  /// Si ya hay una sesión de organizadora, se salta la pantalla de entrar.
  final String? organizadorActual;

  @override
  State<FlujoHostReal> createState() => _FlujoHostRealState();
}

class _FlujoHostRealState extends State<FlujoHostReal> {
  String? _error;
  bool _entrando = false;
  late String? _organizador = widget.organizadorActual;

  Future<void> _entrar() async {
    setState(() {
      _error = null;
      _entrando = true;
    });
    try {
      final nombre = await widget.entrar();
      if (!mounted) return;
      setState(() {
        _entrando = false;
        _organizador = nombre;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _entrando = false;
        _error = 'No pudimos iniciar sesión. Inténtalo de nuevo.';
      });
    }
  }

  /// Tras cerrar sesión o borrar la cuenta: se cierran las pantallas abiertas y
  /// se vuelve a pedir que entre.
  void _salir() {
    Navigator.of(context).popUntil((ruta) => ruta.isFirst);
    setState(() => _organizador = null);
  }

  @override
  Widget build(BuildContext context) {
    final actual = _organizador;
    if (actual != null) {
      final sesion = widget.sesion;
      return _MisPartidasReal(
        repositorio: widget.repositorio,
        organizador: actual,
        alAjustes:
            sesion == null
                ? null
                : () =>
                    _ir(context, AjustesReal(sesion: sesion, alSalir: _salir)),
      );
    }
    return EntrarPage(
      alContinuarConGoogle: _entrar,
      error: _error,
      entrando: _entrando,
    );
  }
}

class _MisPartidasReal extends StatelessWidget {
  const _MisPartidasReal({
    required this.repositorio,
    required this.organizador,
    this.alAjustes,
  });

  final RepositorioOrganizador repositorio;
  final String organizador;
  final VoidCallback? alAjustes;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SalaEnVivo>>(
      stream: repositorio.misSalas(),
      builder: (context, foto) {
        final salas = foto.data ?? const <SalaEnVivo>[];
        return MisPartidasPage(
          organizador: organizador,
          alAjustes: alAjustes,
          partidas: [
            for (final s in salas)
              (
                icono: switch (s.estado) {
                  EstadoSala.terminada => 'trophy',
                  EstadoSala.cancelada => 'close',
                  _ => 'cal',
                },
                titulo: s.nombre,
                detalle: detalleDeSala(s),
              ),
          ],
          alNuevaPartida:
              () => _ir(context, _NuevaPartidaReal(repositorio: repositorio)),
          alAbrirPartida: (i) {
            final sala = salas[i];
            switch (sala.estado) {
              case EstadoSala.abierta || EstadoSala.llena:
                _ir(
                  context,
                  _SalaAbiertaReal(
                    repositorio: repositorio,
                    codigo: sala.codigo,
                  ),
                );
              case EstadoSala.enJuego:
                _ir(
                  context,
                  _AbrirJuego(repositorio: repositorio, codigo: sala.codigo),
                );
              case EstadoSala.terminada || EstadoSala.cancelada:
                break;
            }
          },
        );
      },
    );
  }
}

class _NuevaPartidaReal extends StatefulWidget {
  const _NuevaPartidaReal({required this.repositorio});

  final RepositorioOrganizador repositorio;

  @override
  State<_NuevaPartidaReal> createState() => _NuevaPartidaRealState();
}

class _NuevaPartidaRealState extends State<_NuevaPartidaReal> {
  String? _error;
  bool _creando = false;

  Future<void> _abrir(
    String nombre,
    int columnas,
    bool publica,
    int precioFila,
    int premio,
    int filasPorJugador,
  ) async {
    if (columnas == 6) {
      // La pantalla de partida aún dibuja solo las 75 bolillas de 5 columnas.
      setState(() => _error = 'Las 6 columnas llegan pronto.');
      return;
    }
    setState(() {
      _error = null;
      _creando = true;
    });
    try {
      final codigo = await widget.repositorio.crearSala(
        nombre: nombre,
        columnas: columnas,
        publica: publica,
        precioFila: precioFila,
        premio: premio,
        filasPorJugador: filasPorJugador,
      );
      if (!mounted) return;
      _ir(
        context,
        _SalaAbiertaReal(repositorio: widget.repositorio, codigo: codigo),
        reemplazar: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = mensajeDeError(e);
        _creando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NuevaPartidaPage(
      alVolver: () => Navigator.of(context).pop(),
      alAbrirSala: _abrir,
      error: _error,
      creando: _creando,
    );
  }
}

class _SalaAbiertaReal extends StatefulWidget {
  const _SalaAbiertaReal({required this.repositorio, required this.codigo});

  final RepositorioOrganizador repositorio;
  final String codigo;

  @override
  State<_SalaAbiertaReal> createState() => _SalaAbiertaRealState();
}

class _SalaAbiertaRealState extends State<_SalaAbiertaReal> {
  bool _hojaMostrada = false;
  bool _empezando = false;
  String? _error;

  Future<void> _empezar(SalaEnVivo sala, List<FilaEnVivo> filas) async {
    if (_empezando) return;
    setState(() {
      _empezando = true;
      _error = null;
    });
    try {
      await widget.repositorio.empezar(widget.codigo);
      if (!mounted) return;
      _ir(
        context,
        _Juego(repositorio: widget.repositorio, sala: sala, filas: filas),
        reemplazar: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _empezando = false;
        _error = mensajeDeError(e);
      });
    }
  }

  Future<void> _cerrarSala(int ocupadas) async {
    final cierre = await Navigator.of(context).push<CierreDeSala>(
      PageRouteBuilder<CierreDeSala>(
        opaque: false,
        pageBuilder:
            (c, _, __) => CerrarSalaHoja(
              ocupadas: ocupadas,
              alConfirmar: (cierre) => Navigator.of(c).pop(cierre),
              alSeguir: () => Navigator.of(c).pop(),
            ),
      ),
    );
    if (cierre == null || !mounted) return;
    try {
      await widget.repositorio.cancelarSala(
        widget.codigo,
        motivo: cierre.motivo,
      );
      if (!mounted) return;
      final navegador = Navigator.of(context);
      navegador.pop();
      final overlay = navegador.overlay;
      if (overlay != null) mostrarAvisoBingEn(overlay, 'Sala cerrada');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = mensajeDeError(e));
    }
  }

  void _mostrarHoja(SalaEnVivo sala, List<FilaEnVivo> filas) {
    // La hoja sube un instante después de que entra la última fila.
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      Navigator.of(context).push(
        PageRouteBuilder<void>(
          opaque: false,
          pageBuilder:
              (context, _, __) => CartillaLlenaSheet(
                salaNombre: sala.nombre,
                total: filas.length,
                ultimos: [
                  for (final i in _ultimasFilas(filas))
                    BingJugador.normal(
                      '${i + 1}',
                      filas[i].nombre ?? '',
                      'listo',
                    ),
                ],
                alEmpezar: () {
                  Navigator.of(context).pop();
                  _empezar(sala, filas);
                },
                alEsperar: () => Navigator.of(context).pop(),
              ),
        ),
      );
    });
  }

  List<int> _ultimasFilas(List<FilaEnVivo> filas) {
    final i = List.generate(filas.length, (k) => k)..sort(
      (a, b) => (filas[a].reservadaEn ?? DateTime(0)).compareTo(
        filas[b].reservadaEn ?? DateTime(0),
      ),
    );
    return i.skip(i.length - 6).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SalaEnVivoBuilder(
      repositorio: widget.repositorio,
      codigo: widget.codigo,
      espera: _espera(context),
      constructor: (context, sala, filas) {
        final ocupadas = filas.where((f) => !f.libre).length;
        final llena = ocupadas == filas.length;
        if (llena && !_hojaMostrada) {
          _hojaMostrada = true;
          _mostrarHoja(sala, filas);
        }
        return SalaAbiertaPage(
          salaNombre: sala.nombre,
          codigo: widget.codigo,
          ocupadas: ocupadas,
          total: filas.length,
          jugadores: jugadoresDeLaSala(filas),
          alVolver: () => Navigator.of(context).pop(),
          datosQr: enlaceSala(widget.codigo),
          alCompartir:
              () => abrirCompartirSala(
                context,
                nombre: sala.nombre,
                codigo: widget.codigo,
                publica: sala.publica,
              ),
          alCopiar: () {
            Clipboard.setData(ClipboardData(text: widget.codigo));
            mostrarAvisoBing(context, 'Código copiado');
          },
          alEmpezar: llena && !_empezando ? () => _empezar(sala, filas) : null,
          alCerrarSala: () => _cerrarSala(ocupadas),
          error: _error,
        );
      },
    );
  }
}

/// Abre una partida en juego desde la lista: primero lee su estado.
class _AbrirJuego extends StatelessWidget {
  const _AbrirJuego({required this.repositorio, required this.codigo});

  final RepositorioOrganizador repositorio;
  final String codigo;

  @override
  Widget build(BuildContext context) {
    return SalaEnVivoBuilder(
      repositorio: repositorio,
      codigo: codigo,
      espera: _espera(context),
      constructor:
          (context, sala, filas) =>
              _Juego(repositorio: repositorio, sala: sala, filas: filas),
    );
  }
}

class _Juego extends StatelessWidget {
  const _Juego({
    required this.repositorio,
    required this.sala,
    required this.filas,
  });

  final RepositorioOrganizador repositorio;
  final SalaEnVivo sala;
  final List<FilaEnVivo> filas;

  @override
  Widget build(BuildContext context) {
    return JuegoPage(
      salaNombre: sala.nombre,
      codigo: sala.codigo,
      cartillas: [for (final f in filas) f.numeros],
      nombres: [for (final f in filas) f.nombre ?? ''],
      bolillasIniciales: sala.bolillas,
      sorteo: (_) => repositorio.sacarBolilla(sala.codigo),
      alDeshacer: () => repositorio.deshacerBolilla(sala.codigo),
      alTerminar: () {
        repositorio.terminar(sala.codigo).whenComplete(() {
          if (!context.mounted) return;
          Navigator.of(
            context,
          ).popUntil((r) => r.settings.name == 'mis_partidas' || r.isFirst);
        });
      },
    );
  }
}
