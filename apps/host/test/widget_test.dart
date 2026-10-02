import 'package:flutter_test/flutter_test.dart';
import 'package:bing_host/main.dart';

void main() {
  testWidgets('muestra el nombre de la app', (tester) async {
    await tester.pumpWidget(const BingApp());
    expect(find.text('Bing Bing Host'), findsOneWidget);
  });
}
