import 'package:bing_core/bing_core.dart';
import 'package:bing_firebase/bing_firebase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

const _fila = [1, 16, 31, 46, 61];

Future<void> _sala(
  FakeFirebaseFirestore db,
  String codigo, {
  String organizador = 'carmen',
  DateTime? creada,
  String estado = 'abierta',
  bool publica = true,
  int ocupadas = 0,
}) => db.collection('salas').doc(codigo).set({
  'nombre': 'Sala $codigo',
  'organizadorUid': organizador,
  'organizadorNombre': 'Carmen',
  'estado': estado,
  'publica': publica,
  'ocupadas': ocupadas,
  'columnas': 5,
  'filasTotal': 20,
  'bolillas': [9, 30],
  'ganadores': [
    {'fila': 5, 'bolillaIndice': 2},
  ],
  if (creada != null) 'creadaEn': Timestamp.fromDate(creada),
});

void main() {
  late FakeFirebaseFirestore db;
  late List<(String, Map<String, Object?>)> llamadas;
  late Object? respuesta;
  Object? fallo;

  RepositorioFirestore repo({String uid = 'carmen'}) => RepositorioFirestore(
    db: db,
    auth: MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: uid, displayName: 'Carmen'),
    ),
    llamador: (funcion, datos) async {
      llamadas.add((funcion, datos));
      if (fallo != null) throw fallo!;
      return respuesta;
    },
  );

  setUp(() {
    db = FakeFirebaseFirestore();
    llamadas = [];
    respuesta = {};
    fallo = null;
  });

  group('lectura', () {
    test('buscar devuelve la sala o null si no existe', () async {
      await _sala(db, 'K7Q4');
      final sala = await repo().buscar('K7Q4');
      expect(sala?.nombre, 'Sala K7Q4');
      expect(sala?.organizador, 'Carmen');
      expect(sala?.ganoLaFila(4), isTrue);
      expect(await repo().buscar('ZZZZ'), isNull);
    });

    test('sala emite cada cambio del documento', () async {
      await _sala(db, 'K7Q4');
      final estados = <EstadoSala?>[];
      final suscripcion = repo()
          .sala('K7Q4')
          .listen((s) => estados.add(s?.estado));
      await Future<void>.delayed(Duration.zero);
      await db.collection('salas').doc('K7Q4').update({'estado': 'llena'});
      await Future<void>.delayed(Duration.zero);
      await suscripcion.cancel();
      expect(estados, [EstadoSala.abierta, EstadoSala.llena]);
    });

    test('filas llegan ordenadas por número, con dueño y hora', () async {
      await _sala(db, 'K7Q4');
      final filas = db.collection('salas').doc('K7Q4').collection('filas');
      await filas.doc('10').set({'numeros': _fila});
      await filas.doc('2').set({
        'numeros': _fila,
        'jugadorUid': 'lucia',
        'nombre': 'Lucía',
        'reservadaEn': Timestamp.fromDate(DateTime(2026, 10, 2, 20, 44)),
      });
      await filas.doc('1').set({'numeros': _fila});
      final lista = await repo().filas('K7Q4').first;
      expect(lista, hasLength(3));
      expect(lista[1].nombre, 'Lucía');
      expect(lista[1].reservadaEn, DateTime(2026, 10, 2, 20, 44));
      expect(lista[0].libre, isTrue);
      expect(lista[2].libre, isTrue);
    });

    test(
      'misSalas solo trae las propias, de la más nueva a la más vieja',
      () async {
        await _sala(db, 'VIEJ', creada: DateTime(2026, 9, 1));
        await _sala(db, 'NUEV', creada: DateTime(2026, 10, 1));
        await _sala(
          db,
          'AJEN',
          organizador: 'otra',
          creada: DateTime(2026, 10, 2),
        );
        final salas = await repo().misSalas().first;
        expect(salas.map((s) => s.codigo), ['NUEV', 'VIEJ']);
      },
    );

    test(
      'salasAbiertas solo trae las públicas que reciben jugadores',
      () async {
        await _sala(db, 'ABRT', creada: DateTime(2026, 10, 1), ocupadas: 4);
        await _sala(
          db,
          'LLEN',
          creada: DateTime(2026, 10, 2),
          estado: 'llena',
          ocupadas: 20,
        );
        await _sala(db, 'PRIV', creada: DateTime(2026, 10, 3), publica: false);
        await _sala(
          db,
          'JUGA',
          creada: DateTime(2026, 10, 4),
          estado: 'en_juego',
        );
        await _sala(
          db,
          'TERM',
          creada: DateTime(2026, 10, 5),
          estado: 'terminada',
        );
        final salas = await repo().salasAbiertas().first;
        // La más nueva primero; ni la privada ni las que ya empezaron.
        expect(salas.map((s) => s.codigo), ['LLEN', 'ABRT']);
        expect(salas.first.ocupadas, 20);
        expect(salas.last.libres, 16);
        expect(salas.every((s) => s.publica), isTrue);
      },
    );

    test('uid es el de la sesión', () {
      expect(repo(uid: 'lucia').uid, 'lucia');
    });
  });

  group('llamadas al servidor', () {
    test('reservarFila envía el código, la fila y el nombre', () async {
      await repo().reservarFila(codigo: 'K7Q4', fila: 5, nombre: 'Lucía');
      expect(llamadas.single.$1, 'reservarFila');
      expect(llamadas.single.$2, {
        'codigo': 'K7Q4',
        'fila': 5,
        'nombre': 'Lucía',
      });
    });

    test('crearSala devuelve el código que responde el servidor', () async {
      respuesta = {'codigo': 'AB23'};
      final codigo = await repo().crearSala(nombre: 'Bingo', columnas: 5);
      expect(codigo, 'AB23');
      expect(llamadas.single.$2, {
        'nombre': 'Bingo',
        'columnas': 5,
        'publica': true,
      });
    });

    test('crearSala envía que es privada cuando se pide', () async {
      respuesta = {'codigo': 'AB23'};
      await repo().crearSala(nombre: 'Familia', columnas: 5, publica: false);
      expect(llamadas.single.$2['publica'], isFalse);
    });

    test('sacarBolilla devuelve el número del servidor', () async {
      respuesta = {'numero': 47, 'indice': 12, 'ganadoras': <int>[]};
      expect(await repo().sacarBolilla('K7Q4'), 47);
    });

    test('empezar, deshacer y terminar llaman a su Function', () async {
      final r = repo();
      await r.empezar('K7Q4');
      await r.deshacerBolilla('K7Q4');
      await r.terminar('K7Q4');
      expect(llamadas.map((l) => l.$1), [
        'empezarPartida',
        'deshacerBolilla',
        'terminarPartida',
      ]);
      expect(llamadas.every((l) => l.$2['codigo'] == 'K7Q4'), isTrue);
    });

    test(
      'un error del servidor llega como ErrorSalaBing con su código',
      () async {
        fallo = FirebaseFunctionsException(
          message: 'Esa fila ya tiene dueño',
          code: 'failed-precondition',
          details: {'codigo': 'fila_ocupada'},
        );
        await expectLater(
          repo().reservarFila(codigo: 'K7Q4', fila: 5, nombre: 'Lucía'),
          throwsA(
            isA<ErrorSalaBing>()
                .having((e) => e.codigo, 'codigo', 'fila_ocupada')
                .having((e) => e.mensaje, 'mensaje', 'Esa fila ya tiene dueño'),
          ),
        );
      },
    );
  });
}
