import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

import 'paginas/billetera_page.dart';
import 'paginas/codigo_page.dart';
import 'paginas/cuenta_page.dart';
import 'paginas/elegir_fila_page.dart';
import 'paginas/en_vivo_page.dart';
import 'paginas/escaner_page.dart';
import 'paginas/esperando_page.dart';
import 'paginas/ganaste_page.dart';
import 'paginas/iniciar_sesion_hoja.dart';
import 'sala_cerrada.dart';
import 'paginas/reservar_page.dart';
import 'paginas/salas_abiertas.dart';

/// Las salas públicas del inicio (`jug-07`).
List<SalaEnVivo> salasDemo() {
  SalaEnVivo sala(
    String codigo,
    String nombre,
    String organizador,
    int ocupadas, {
    int precioFila = 5,
    int premio = 80,
  }) => SalaEnVivo(
    codigo: codigo,
    nombre: nombre,
    organizador: organizador,
    estado: ocupadas == 20 ? EstadoSala.llena : EstadoSala.abierta,
    columnas: 5,
    filasTotal: 20,
    bolillas: const [],
    ganadoras: const [],
    publica: true,
    ocupadas: ocupadas,
    precioFila: precioFila,
    premio: premio,
  );
  return [
    sala('K7Q4', 'Bingo de los sábados', 'Carmen', 4),
    sala('PL23', 'Cumpleaños de Pilar', 'Renzo', 11, precioFila: 3, premio: 50),
    sala('FAM8', 'Bingo familiar', 'Don Luis', 19, precioFila: 10, premio: 160),
    sala('CLUB', 'Bingo del club', 'Marta', 20),
  ];
}

Widget _sinSalas(bool desplazable) =>
    SalasAbiertas(salas: const [], desplazable: desplazable);

/// El "ahora" del diseño: 2 de octubre, 20:50.
final _ahoraDemo = DateTime(2026, 10, 2, 20, 50);

Widget _billeteraDemo({bool historial = true}) => BilleteraPage(
  saldo: 25,
  ahora: _ahoraDemo,
  movimientos:
      historial
          ? [
            Movimiento(
              tipo: TipoMovimiento.recarga,
              monto: 30,
              detalle: 'Recarga',
              creadaEn: DateTime(2026, 10, 2, 20, 45),
            ),
            Movimiento(
              tipo: TipoMovimiento.fila,
              monto: -5,
              detalle: 'Fila 5 · Bingo de los sábados',
              creadaEn: DateTime(2026, 10, 2, 20, 46),
            ),
            Movimiento(
              tipo: TipoMovimiento.premio,
              monto: 60,
              detalle: 'Premio · Cumpleaños de Pilar',
              creadaEn: DateTime(2026, 9, 19, 21),
            ),
            Movimiento(
              tipo: TipoMovimiento.fila,
              monto: -3,
              detalle: 'Fila 12 · Cumpleaños de Pilar',
              creadaEn: DateTime(2026, 9, 19, 20, 30),
            ),
          ]
          : const [],
);

/// Pantalla del diseño por su identificador (`jug-01-codigo`, …), con los datos
/// del modo demo. Sirve para revisar una pantalla sin recorrer el flujo.
Widget? pantallaDemo(String id) => switch (id) {
  'jug-07-inicio-salas' => CodigoPage(
    codigo: '',
    salaNombre: '',
    organizador: '',
    filasLibres: 0,
    resultado: const SizedBox(height: 40),
    alEscanear: () {},
    accion: const BingChip('Iniciar sesión', icono: 'user'),
    bajoElQr:
        (desplazable) => SalasAbiertas(
          salas: salasConSitio(salasDemo()),
          desplazable: desplazable,
        ),
  ),
  'jug-07b-inicio-sin-salas' => const CodigoPage(
    codigo: '',
    salaNombre: '',
    organizador: '',
    filasLibres: 0,
    resultado: SizedBox(height: 40),
    bajoElQr: _sinSalas,
  ),
  'jug-09-iniciar-sesion' => IniciarSesionHoja(
    fondo: ElegirFilaPage(
      salaNombre: salaDemoNombre,
      cartillas: cartillasDemo.take(6).toList(),
      duenos: filasDemoDuenos.take(6).toList(),
      seleccionInicial: const {5},
    ),
    alAhoraNo: () {},
  ),
  'jug-14-sala-cerrada' => SalaCerradaHoja(
    sala: SalaEnVivo(
      codigo: salaDemoCodigo,
      nombre: salaDemoNombre,
      organizador: salaDemoOrganizador,
      estado: EstadoSala.cancelada,
      columnas: 5,
      filasTotal: 20,
      bolillas: const [],
      ganadoras: const [],
      motivoCierre: 'No se llenó',
    ),
    fondo: ElegirFilaPage(
      salaNombre: salaDemoNombre,
      cartillas: cartillasDemo.take(6).toList(),
      duenos: filasDemoDuenos.take(6).toList(),
      seleccionInicial: const {5},
    ),
  ),
  'jug-10-sin-saldo' => ElegirFilaPage(
    salaNombre: salaDemoNombre,
    // El diseño solo dibuja las filas libres 5 a 9.
    cartillas: cartillasDemo.sublist(4, 9),
    duenos: List<String?>.filled(5, null),
    precioFila: 5,
    premio: 80,
    saldo: 0,
  ),
  'jug-11-billetera' => _billeteraDemo(),
  'jug-12-recargar' => RecargarHoja(fondo: _billeteraDemo(historial: false)),
  'jug-13-cuenta' => const CuentaPage(
    nombre: 'Lucía Torres',
    correo: 'lucia@correo.com',
  ),
  'jug-08-escanear' => const EscanerPage(),
  'jug-08b-camara-denegada' => const CamaraDenegadaPage(),
  'jug-01-codigo' => const CodigoPage(
    codigo: salaDemoCodigo,
    salaNombre: salaDemoNombre,
    organizador: salaDemoOrganizador,
    filasLibres: 16,
  ),
  'jug-02-elegir-fila' => ElegirFilaPage(
    salaNombre: salaDemoNombre,
    // El diseño solo dibuja las 9 primeras filas.
    cartillas: cartillasDemo.take(9).toList(),
    duenos: filasDemoDuenos.take(9).toList(),
    seleccionInicial: const {5},
  ),
  'jug-03-reservar' => ReservarPage(
    salaNombre: salaDemoNombre,
    organizador: salaDemoOrganizador,
    filas: [5],
    cartillas: [cartillasDemo[4]],
    nombreInicial: 'Lucía',
  ),
  'jug-04-esperando' => EsperandoPage(
    nombre: 'Lucía',
    salaNombre: salaDemoNombre,
    organizador: salaDemoOrganizador,
    filas: [5],
    cartillas: [cartillasDemo[4]],
    ocupadas: 17,
    total: 20,
  ),
  'jug-05-en-vivo' => EnVivoPage(
    salaNombre: salaDemoNombre,
    organizador: salaDemoOrganizador,
    cartillas: cartillasDemo,
    nombres: jugadoresDemo,
    misFilas: [5],
    bolillas: bolillasDemo.take(17).toList(),
    hace: 'hace 3 s',
  ),
  'jug-06-ganaste' => GanastePage(
    nombre: 'Lucía',
    fila: 5,
    numeros: cartillasDemo[4],
    bolillaFinal: 12,
    cantidadBolillas: 32,
    organizador: salaDemoOrganizador,
  ),
  _ => null,
};
