import 'package:bing_core/bing_core.dart';
import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

import 'paginas/cartilla_llena_sheet.dart';
import 'paginas/entrar_page.dart';
import 'paginas/ganador_page.dart';
import 'paginas/juego_page.dart';
import 'paginas/mis_partidas_page.dart';
import 'paginas/nueva_partida_page.dart';
import 'paginas/sala_abierta_page.dart';

/// Partidas guardadas del modo demo.
const partidasDemo = <PartidaResumen>[
  (
    icono: 'cal',
    titulo: 'Bingo de los sábados',
    detalle: 'Hoy 21:00 · borrador · 0 jugadores',
  ),
  (
    icono: 'trophy',
    titulo: 'Bingo de los sábados',
    detalle: '26 set · 20 jugadores · ganó Kiara',
  ),
  (
    icono: 'trophy',
    titulo: 'Cumpleaños de Pilar',
    detalle: '19 set · 14 jugadores · ganó Renzo',
  ),
];

/// La partida del diseño: la siguiente bolilla es la que sigue en el orden fijo.
int? sorteoDemo(List<int> salidas) =>
    salidas.length < bolillasDemo.length ? bolillasDemo[salidas.length] : null;

/// Jugadores de la sala abierta del diseño (`org-04`).
List<BingJugador> jugadoresSalaAbiertaDemo() => [
  for (var i = 0; i < 5; i++)
    BingJugador.normal('${i + 1}', jugadoresDemo[i], horasReservaDemo[i]),
  const BingJugador.salto('filas 6 a 16'),
  const BingJugador.nuevo('17', 'Claudia', 'recién entró'),
  const BingJugador.libre('18'),
  const BingJugador.libre('19'),
  const BingJugador.libre('20'),
];

JuegoPage juegoDemo({int pestana = 0}) => JuegoPage(
  // El diseño solo dibuja 3 filas en "Van ganando".
  filasGanando: 3,
  salaNombre: salaDemoNombre,
  codigo: salaDemoCodigo,
  cartillas: cartillasDemo,
  nombres: jugadoresDemo,
  bolillasIniciales: bolillasDemo.take(17).toList(),
  sorteo: sorteoDemo,
  pestanaInicial: pestana,
);

/// Pantalla del diseño por su identificador (`org-01-entrar`, …), con los datos
/// del modo demo. Sirve para revisar una pantalla sin recorrer el flujo.
Widget? pantallaDemo(String id) => switch (id) {
  'org-01-entrar' => const EntrarPage(),
  'org-02-mis-partidas' => const MisPartidasPage(
    organizador: 'Carmen',
    partidas: partidasDemo,
  ),
  'org-03-nueva-partida' => const NuevaPartidaPage(
    nombreInicial: 'Bingo de los sábados',
  ),
  'org-04-sala-abierta' => SalaAbiertaPage(
    salaNombre: salaDemoNombre,
    codigo: salaDemoCodigo,
    ocupadas: 17,
    total: 20,
    jugadores: jugadoresSalaAbiertaDemo(),
  ),
  'org-05-cartilla-llena' => CartillaLlenaSheet(
    salaNombre: salaDemoNombre,
    total: 20,
    ultimos: [
      for (var i = 14; i < 20; i++)
        BingJugador.normal('${i + 1}', jugadoresDemo[i], 'listo'),
    ],
  ),
  'org-06-bolilla' => juegoDemo(),
  'org-07-cartilla' => juegoDemo(pestana: 1),
  'org-08-tablero' => juegoDemo(pestana: 2),
  'org-09-ganador' => GanadorPage(
    nombre: 'Lucía',
    fila: 5,
    numeros: cartillasDemo[4],
    bolillaFinal: 12,
    cantidadBolillas: 32,
    jugadores: 20,
  ),
  _ => null,
};
