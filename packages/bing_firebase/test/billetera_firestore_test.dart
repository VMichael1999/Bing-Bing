import 'package:bing_core/bing_core.dart';
import 'package:bing_firebase/bing_firebase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late List<(String, Map<String, Object?>)> llamadas;
  Object? fallo;

  BilleteraFirestore billetera({String uid = 'lucia', bool conSesion = true}) =>
      BilleteraFirestore(
        db: db,
        auth: MockFirebaseAuth(
          signedIn: conSesion,
          mockUser: MockUser(uid: uid),
        ),
        llamador: (funcion, datos) async {
          llamadas.add((funcion, datos));
          if (fallo != null) throw fallo!;
          // El servidor crea la billetera con los créditos de bienvenida.
          if (funcion == 'obtenerBilletera') {
            await db.collection('billeteras').doc(uid).set({'saldo': 25});
          }
          return {};
        },
      );

  setUp(() {
    db = FakeFirebaseFirestore();
    llamadas = [];
    fallo = null;
  });

  test('si la cuenta aún no tiene billetera, la pide al servidor', () async {
    final saldo = await billetera().saldo().first;
    expect(llamadas.single.$1, 'obtenerBilletera');
    expect(saldo, 25);
  });

  test('si ya la tiene, solo lee el saldo y avisa de cada cambio', () async {
    await db.collection('billeteras').doc('lucia').set({'saldo': 40});
    final vistos = <int?>[];
    final sub = billetera().saldo().listen(vistos.add);
    await Future<void>.delayed(Duration.zero);
    await db.collection('billeteras').doc('lucia').set({'saldo': 35});
    await Future<void>.delayed(Duration.zero);
    expect(llamadas, isEmpty);
    expect(vistos, [40, 35]);
    await sub.cancel();
  });

  test('sin sesión no hay saldo', () async {
    expect(await billetera(conSesion: false).saldo().first, isNull);
  });

  test('si el servidor falla al crearla, no se rompe el flujo', () async {
    fallo = FirebaseFunctionsException(message: 'x', code: 'unavailable');
    final vistos = <int?>[];
    final sub = billetera().saldo().listen(vistos.add);
    await Future<void>.delayed(Duration.zero);
    // No hay billetera todavía: el saldo se queda en `null`, sin lanzar.
    expect(vistos, [null]);
    await sub.cancel();
  });

  test('los movimientos llegan del más reciente al más antiguo', () async {
    final col = db
        .collection('billeteras')
        .doc('lucia')
        .collection('movimientos');
    await col.add({
      'tipo': 'regalo',
      'monto': 25,
      'detalle': 'Créditos de bienvenida',
      'creadaEn': Timestamp.fromDate(DateTime(2026, 10, 2, 20, 0)),
    });
    await col.add({
      'tipo': 'fila',
      'monto': -5,
      'detalle': 'Fila 5 · Bingo',
      'creadaEn': Timestamp.fromDate(DateTime(2026, 10, 2, 20, 46)),
    });
    final lista = await billetera().movimientos().first;
    expect(lista.map((m) => m.tipo), [
      TipoMovimiento.fila,
      TipoMovimiento.regalo,
    ]);
    expect(lista.first.monto, -5);
    expect(lista.first.detalle, 'Fila 5 · Bingo');
    expect(lista.first.creadaEn, DateTime(2026, 10, 2, 20, 46));
  });

  test('recargar llama a la Function con el monto', () async {
    await billetera().recargar(20);
    expect(llamadas.single.$1, 'recargar');
    expect(llamadas.single.$2, {'monto': 20});
  });

  test('un monto inválido llega como ErrorSalaBing', () async {
    fallo = FirebaseFunctionsException(
      message: 'Los montos son 10, 20, 50, 100',
      code: 'failed-precondition',
      details: {'codigo': 'monto_invalido'},
    );
    await expectLater(
      billetera().recargar(15),
      throwsA(
        isA<ErrorSalaBing>().having(
          (e) => e.codigo,
          'codigo',
          'monto_invalido',
        ),
      ),
    );
  });

  test('movimientoDesdeMapa tolera datos incompletos', () {
    final m = movimientoDesdeMapa({'tipo': 'otro'});
    expect(m.tipo, TipoMovimiento.regalo);
    expect(m.monto, 0);
    expect(m.detalle, '');
    expect(m.creadaEn, isNull);
  });
}
