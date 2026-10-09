import 'sala_en_vivo.dart';

/// Máximo de salas que muestra el inicio del jugador.
const topeSalasAbiertas = 10;

/// Las salas a las que aún se puede entrar, las más llenas primero: están más
/// cerca de empezar. A igual llenado va antes la más antigua; sin fecha, al final.
List<SalaEnVivo> salasConSitio(
  Iterable<SalaEnVivo> salas, {
  int tope = topeSalasAbiertas,
}) {
  final con =
      salas
          .where((s) => s.estado == EstadoSala.abierta && s.libres > 0)
          .toList()
        ..sort((a, b) {
          final porLlenado = b.ocupadas.compareTo(a.ocupadas);
          if (porLlenado != 0) return porLlenado;
          final fa = a.creadaEn, fb = b.creadaEn;
          if (fa == null && fb == null) return 0;
          if (fa == null) return 1;
          if (fb == null) return -1;
          return fa.compareTo(fb);
        });
  return con.take(tope).toList();
}
