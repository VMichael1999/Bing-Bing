import 'package:flutter/foundation.dart';

import 'demo.dart';
import 'reglas.dart';

/// Estado de la sala simulada (el mismo ciclo que tendrá en Firestore).
enum EstadoSalaSim { abierta, llena, enJuego, terminada }

/// Sala en memoria para recorrer las dos apps sin Firebase.
///
/// Usa los datos del diseño: las 20 cartillas, los 20 nombres y la partida de
/// bolillas en el orden fijo, de modo que con la 32 (B-12) gana Lucía, la fila 5.
/// Quien la use decide cuándo llegan jugadores ([llegaSiguiente]) y cuándo sale
/// cada bolilla ([sacar]); aquí no hay temporizadores, así que es fácil de probar.
class SalaSimulada extends ChangeNotifier {
  SalaSimulada({int ocupadasIniciales = 0})
    : duenos = List<String?>.filled(cartillasDemo.length, null),
      horas = List<String?>.filled(cartillasDemo.length, null) {
    for (var i = 0; i < ocupadasIniciales; i++) {
      llegaSiguiente();
    }
  }

  final List<List<int>> cartillas = cartillasDemo;
  final List<String?> duenos;
  final List<String?> horas;
  final List<int> bolillas = [];
  EstadoSalaSim estado = EstadoSalaSim.abierta;

  /// Fila (base 0) de quien entró última, para resaltarla ("recién entró").
  int? ultimaEnEntrar;

  /// Cuándo salió la última bolilla, para el "hace 3 s".
  DateTime? ultimaSalida;

  int _minutos = 20 * 60 + 44; // 20:44, la primera hora del diseño.
  final Set<int> _reservadasPorMi = {};

  int get total => cartillas.length;
  int get ocupadas => duenos.where((d) => d != null).length;
  bool get estaLlena => ocupadas == total;
  int get faltan => total - ocupadas;

  String _hora() {
    final h = (_minutos ~/ 60).toString().padLeft(2, '0');
    final m = (_minutos % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _ocupar(int fila, String nombre) {
    duenos[fila] = nombre;
    horas[fila] =
        fila < horasReservaDemo.length ? horasReservaDemo[fila] : _hora();
    if (fila >= horasReservaDemo.length) _minutos += 1;
    ultimaEnEntrar = fila;
    if (estaLlena) estado = EstadoSalaSim.llena;
  }

  /// Reserva de quien usa la app. Devuelve `false` si la fila ya tiene dueño.
  bool reservar(int fila, String nombre) {
    if (estado != EstadoSalaSim.abierta || duenos[fila] != null) return false;
    _ocupar(fila, nombre);
    _reservadasPorMi.add(fila);
    notifyListeners();
    return true;
  }

  /// Entra el siguiente jugador simulado en la primera fila libre.
  /// Devuelve la fila (base 0) o `null` si la sala ya está llena o cerrada.
  int? llegaSiguiente() {
    if (estado != EstadoSalaSim.abierta) return null;
    final fila = duenos.indexWhere((d) => d == null);
    if (fila == -1) return null;
    final nombre = jugadoresDemo.firstWhere(
      (n) => !duenos.contains(n),
      orElse: () => 'Jugador ${fila + 1}',
    );
    _ocupar(fila, nombre);
    notifyListeners();
    return fila;
  }

  /// El organizador cierra la sala y empieza la partida (solo con la sala llena).
  bool empezar() {
    if (estado != EstadoSalaSim.llena) return false;
    estado = EstadoSalaSim.enJuego;
    notifyListeners();
    return true;
  }

  /// Siguiente bolilla de la partida del diseño, o `null` si no está en juego.
  int? siguienteBolilla() {
    if (estado != EstadoSalaSim.enJuego) return null;
    if (bolillas.length >= bolillasDemo.length) return null;
    return bolillasDemo[bolillas.length];
  }

  /// Saca la siguiente bolilla y devuelve las filas (base 0) que completan.
  List<int>? sacar() {
    final n = siguienteBolilla();
    if (n == null) return null;
    bolillas.add(n);
    ultimaSalida = DateTime.now();
    final ganadoras = [for (final i in ganadoresNuevos(cartillas, bolillas)) i];
    notifyListeners();
    return ganadoras;
  }

  /// Devuelve la última bolilla a la tómbola.
  void deshacer() {
    if (bolillas.isEmpty) return;
    bolillas.removeLast();
    notifyListeners();
  }

  void terminar() {
    estado = EstadoSalaSim.terminada;
    notifyListeners();
  }

  /// Filas (base 0) que reservó quien usa la app.
  Set<int> get misFilas => Set.unmodifiable(_reservadasPorMi);
}
