import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

import 'src/paginas/codigo_page.dart';

void main() => runApp(const BingPlayApp());

class BingPlayApp extends StatelessWidget {
  const BingPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BingTema(
      paleta: BingPaleta.claro,
      child: WidgetsApp(
        color: BingPaleta.claro.fondo,
        debugShowCheckedModeBanner: false,
        title: 'Bing Bing Play',
        pageRouteBuilder:
            <T>(settings, builder) => PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (context, _, __) => builder(context),
            ),
        home: const CodigoPage(
          codigo: 'K7Q4',
          salaNombre: 'Bingo de los sábados',
          organizador: 'Carmen',
          filasLibres: 16,
        ),
      ),
    );
  }
}
