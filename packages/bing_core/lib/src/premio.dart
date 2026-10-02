/// Lo que Bing Bing retiene de lo recaudado, en %. Es un valor por definir con
/// el negocio; el servidor usa el suyo (`COMISION_PORCENTAJE`) y es quien decide.
/// Aquí solo sirve para mostrar el cálculo antes de abrir la sala.
const comisionPorcentaje = 10;

/// Lo que se recauda si se llenan [filas] filas a [precioFila] créditos cada una.
int recaudado(int precioFila, int filas) => precioFila * filas;

/// La parte de Bing Bing, redondeada hacia arriba.
int comisionDe(int total, {int porcentaje = comisionPorcentaje}) =>
    (total * porcentaje + 99) ~/ 100;

/// Lo que queda tras la comisión: de ahí salen el premio y lo de quien organiza.
int disponibleParaPremio(
  int precioFila,
  int filas, {
  int porcentaje = comisionPorcentaje,
}) {
  final total = recaudado(precioFila, filas);
  return total - comisionDe(total, porcentaje: porcentaje);
}

/// Premio que se propone: casi todo lo disponible, en múltiplos de 5 (con 5
/// créditos por fila y 20 filas, 80 de 90).
int premioSugerido(int precioFila, int filas) {
  final disponible = disponibleParaPremio(precioFila, filas);
  return (disponible * 9 ~/ 10) ~/ 5 * 5;
}
