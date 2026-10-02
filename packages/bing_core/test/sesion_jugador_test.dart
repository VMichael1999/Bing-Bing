import 'package:bing_core/bing_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const lucia = UsuarioBing(
    uid: 'u1',
    nombre: 'Lucía Torres',
    correo: 'lucia@correo.com',
  );

  group('UsuarioBing', () {
    test('usa el nombre y, sin él, lo que va antes de la @', () {
      expect(lucia.nombreVisible, 'Lucía Torres');
      expect(lucia.primerNombre, 'Lucía');
      const sinNombre = UsuarioBing(uid: 'u2', correo: 'pepe@correo.com');
      expect(sinNombre.nombreVisible, 'pepe');
    });

    test('solo tiene cuenta quien no es anónimo', () {
      expect(lucia.tieneCuenta, isTrue);
      expect(const UsuarioBing(uid: 'a', esAnonimo: true).tieneCuenta, isFalse);
      const UsuarioBing? nadie = null;
      expect(nadie.tieneCuenta, isFalse);
    });
  });

  group('SesionMemoria', () {
    test('arranca de invitado', () {
      final sesion = SesionMemoria();
      expect(sesion.actual.tieneCuenta, isFalse);
    });

    test('entrar con Google deja la cuenta y avisa del cambio', () async {
      final sesion = SesionMemoria(cuentaGoogle: lucia);
      final vistos = <UsuarioBing?>[];
      final sub = sesion.cambios.listen(vistos.add);
      await Future<void>.delayed(Duration.zero);
      expect(await sesion.entrarConGoogle(), lucia);
      await Future<void>.delayed(Duration.zero);
      expect(sesion.actual.tieneCuenta, isTrue);
      expect(vistos.map((u) => u.tieneCuenta), [false, true]);
      await sub.cancel();
    });

    test('si la persona cancela, sigue de invitado', () async {
      final sesion = SesionMemoria();
      expect(await sesion.entrarConGoogle(), isNull);
      expect(sesion.actual.tieneCuenta, isFalse);
    });

    test('cerrar sesión y eliminar la cuenta vuelven a invitado', () async {
      final sesion = SesionMemoria(inicial: lucia);
      await sesion.cerrarSesion();
      expect(sesion.actual.tieneCuenta, isFalse);
      expect(sesion.cierres, 1);
      await sesion.eliminarCuenta();
      expect(sesion.borrados, 1);
      expect(sesion.actual.tieneCuenta, isFalse);
    });
  });
}
