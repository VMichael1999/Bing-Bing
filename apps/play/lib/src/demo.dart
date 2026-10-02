import 'package:bing_core/bing_core.dart';
import 'package:flutter/widgets.dart';

import 'paginas/codigo_page.dart';
import 'paginas/elegir_fila_page.dart';
import 'paginas/en_vivo_page.dart';
import 'paginas/esperando_page.dart';
import 'paginas/ganaste_page.dart';
import 'paginas/reservar_page.dart';

/// Pantalla del diseño por su identificador (`jug-01-codigo`, …), con los datos
/// del modo demo. Sirve para revisar una pantalla sin recorrer el flujo.
Widget? pantallaDemo(String id) => switch (id) {
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
    seleccionInicial: 5,
  ),
  'jug-03-reservar' => ReservarPage(
    salaNombre: salaDemoNombre,
    organizador: salaDemoOrganizador,
    fila: 5,
    numeros: cartillasDemo[4],
    nombreInicial: 'Lucía',
  ),
  'jug-04-esperando' => EsperandoPage(
    nombre: 'Lucía',
    salaNombre: salaDemoNombre,
    organizador: salaDemoOrganizador,
    fila: 5,
    numeros: cartillasDemo[4],
    ocupadas: 17,
    total: 20,
  ),
  'jug-05-en-vivo' => EnVivoPage(
    salaNombre: salaDemoNombre,
    organizador: salaDemoOrganizador,
    cartillas: cartillasDemo,
    nombres: jugadoresDemo,
    miFila: 5,
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
