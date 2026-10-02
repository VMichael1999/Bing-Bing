/// Datos del modo demo: exactamente los del diseño HTML.
library;

const String salaDemoCodigo = 'K7Q4';
const String salaDemoNombre = 'Bingo de los sábados';
const String salaDemoOrganizador = 'Carmen';

/// Jugadores en orden de fila (Lucía es la fila 5).
const List<String> jugadoresDemo = [
  'Rosa', 'Javier', 'Milagros', 'Carlos', 'Lucía', 'Jhon', 'Fiorella', //
  'Miguel', 'Kiara', 'Luis', 'Ana Lucía', 'Renzo', 'Pilar', 'Diego',
  'Yolanda', 'Bruno', 'Claudia', 'Marco', 'Sofía', 'Héctor',
];

/// Cartillas de la fila 1 a la 20.
const List<List<int>> cartillasDemo = [
  [6, 24, 39, 52, 72],
  [14, 26, 41, 57, 67],
  [10, 28, 45, 58, 75],
  [6, 28, 31, 59, 72],
  [12, 21, 36, 49, 70],
  [8, 29, 32, 56, 62],
  [4, 16, 44, 58, 75],
  [10, 20, 40, 60, 64],
  [10, 27, 33, 53, 74],
  [4, 25, 45, 59, 62],
  [2, 25, 32, 52, 65],
  [9, 17, 32, 47, 73],
  [15, 24, 39, 60, 70],
  [13, 28, 33, 50, 62],
  [3, 24, 39, 46, 75],
  [10, 29, 44, 57, 63],
  [3, 26, 39, 46, 69],
  [12, 20, 31, 58, 67],
  [8, 21, 36, 49, 67],
  [13, 19, 41, 47, 62],
];

/// Bolillas en orden de salida. Con las 17 primeras la partida está en juego;
/// con la 32 (B-12) gana Lucía.
const List<int> bolillasDemo = [
  36, 40, 57, 64, 14, 66, 21, 60, 50, 68, 49, 8, 63, 59, 56, 26, //
  31, 53, 38, 69, 65, 43, 74, 58, 61, 62, 73, 39, 13, 70, 6, 12,
];

/// Dueños de las filas en la pantalla "Elige tu fila": las 4 primeras ya están
/// tomadas y el resto está libre.
final List<String?> filasDemoDuenos = [
  for (var i = 0; i < jugadoresDemo.length; i++)
    i < 4 ? jugadoresDemo[i] : null,
];

/// Horas de reserva de las filas 1 a 5 en la sala abierta (`org-04`).
const List<String> horasReservaDemo = [
  '20:44',
  '20:44',
  '20:45',
  '20:46',
  '20:49',
];
