import 'package:bing_core/bing_core.dart';
import 'package:bing_host/main.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cargar_fuentes.dart';

const _carmen = UsuarioBing(
  uid: 'g1',
  nombre: 'Carmen Ruiz',
  correo: 'carmen@correo.com',
);

void main() {
  setUpAll(cargarFuentesBing);

  Future<SesionMemoria> abrir(WidgetTester tester) async {
    final sesion = SesionMemoria(inicial: _carmen);
    await tester.pumpWidget(
      BingHostApp(
        repositorio: RepositorioMemoria(
          cartillas: cartillasDemo,
          ordenBolillas: bolillasDemo,
        ),
        entrar: () async => 'Carmen',
        organizadorActual: 'Carmen',
        sesion: sesion,
      ),
    );
    await tester.pumpAndSettle();
    return sesion;
  }

  testWidgets('la tuerca abre los ajustes con la cuenta', (tester) async {
    await abrir(tester);
    expect(find.text('Tus partidas'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Carmen Ruiz'), findsOneWidget);
    expect(find.text('carmen@correo.com'), findsWidgets);
  });

  testWidgets('cerrar sesión vuelve a la pantalla de entrar', (tester) async {
    final sesion = await abrir(tester);
    await tester.tap(find.bySemanticsLabel('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(sesion.cierres, 1);
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.text('Tus partidas'), findsNothing);
  });

  testWidgets('eliminar la cuenta pide confirmar y luego vuelve a entrar', (
    tester,
  ) async {
    final sesion = await abrir(tester);
    await tester.tap(find.bySemanticsLabel('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar mi cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('¿Eliminar tu cuenta?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(sesion.borrados, 0);

    await tester.tap(find.text('Eliminar mi cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí, eliminar mi cuenta'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(sesion.borrados, 1);
    expect(find.text('Tu cuenta se eliminó'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Continuar con Google'), findsOneWidget);
  });

  testWidgets('después de salir se puede volver a entrar', (tester) async {
    await abrir(tester);
    await tester.tap(find.bySemanticsLabel('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();
    expect(find.text('Tus partidas'), findsOneWidget);
  });

  testWidgets('sin sesión la tuerca no abre nada', (tester) async {
    await tester.pumpWidget(
      BingHostApp(
        repositorio: RepositorioMemoria(
          cartillas: cartillasDemo,
          ordenBolillas: bolillasDemo,
        ),
        entrar: () async => 'Carmen',
        organizadorActual: 'Carmen',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('Tus partidas'), findsOneWidget);
  });
}
