import 'package:flutter/widgets.dart';

void main() => runApp(const BingApp());

class BingApp extends StatelessWidget {
  const BingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: Color(0xFF10132A),
      debugShowCheckedModeBanner: false,
      onGenerateRoute: _route,
    );
  }
}

Route<void> _route(RouteSettings settings) => PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => const Center(
        child: Text('Bing Bing Play', textDirection: TextDirection.ltr),
      ),
    );
