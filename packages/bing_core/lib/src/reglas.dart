import 'dart:math';

/// Cantidad de números de cada columna (B 1–15, I 16–30, …).
const int rangoColumna = 15;

const List<String> _letras = ['B', 'I', 'N', 'G', 'O'];

/// Total de bolillas de la tómbola: 75 con 5 columnas, 90 con 6.
int totalBolillas(int columnas) => columnas * rangoColumna;

/// Índice de columna (0 = B) al que pertenece la bolilla [n].
int columnaDe(int n) => (n - 1) ~/ rangoColumna;

/// Texto de la bolilla: "B-12" con 5 columnas, "12" con 6.
String etiqueta(int n, int columnas) =>
    columnas == 5 ? '${_letras[columnaDe(n)]}-$n' : '$n';

/// Genera [filas] cartillas de [columnas] números.
///
/// Cada columna usa su rango de 15. Los números pueden repetirse entre filas.
List<List<int>> generarCartillas({
  int filas = 20,
  int columnas = 5,
  Random? random,
}) {
  final azar = random ?? Random();
  return List.generate(
    filas,
    (_) => List.generate(
      columnas,
      (c) => c * rangoColumna + 1 + azar.nextInt(rangoColumna),
    ),
  );
}

/// Cuántos números le faltan a [fila] para completarse.
int faltan(List<int> fila, Set<int> salidas) =>
    fila.where((n) => !salidas.contains(n)).length;

/// Índices (base 0) de las filas completas.
List<int> filasCompletas(List<List<int>> cartillas, Set<int> salidas) => [
  for (var i = 0; i < cartillas.length; i++)
    if (faltan(cartillas[i], salidas) == 0) i,
];

/// Índices (base 0) de las filas a una bolilla de completarse.
List<int> filasAUnaBolilla(List<List<int>> cartillas, Set<int> salidas) => [
  for (var i = 0; i < cartillas.length; i++)
    if (faltan(cartillas[i], salidas) == 1) i,
];

/// Filas que se completan justo al salir la última bolilla de [salidas].
///
/// Si hay más de una, es un empate: la regla la decide el organizador.
List<int> ganadoresNuevos(List<List<int>> cartillas, List<int> orden) {
  if (orden.isEmpty) return const [];
  final antes = orden.sublist(0, orden.length - 1).toSet();
  final ahora = orden.toSet();
  return [
    for (var i = 0; i < cartillas.length; i++)
      if (faltan(cartillas[i], antes) > 0 && faltan(cartillas[i], ahora) == 0)
        i,
  ];
}

/// Elige al azar una bolilla que todavía no salió, o `null` si no quedan.
int? sacarBolilla({
  required int columnas,
  required Iterable<int> salidas,
  Random? random,
}) {
  final yaSalio = salidas.toSet();
  final quedan = [
    for (var n = 1; n <= totalBolillas(columnas); n++)
      if (!yaSalio.contains(n)) n,
  ];
  if (quedan.isEmpty) return null;
  return quedan[(random ?? Random()).nextInt(quedan.length)];
}
