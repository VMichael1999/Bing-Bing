import 'package:bing_ui/bing_ui.dart';
import 'package:flutter/widgets.dart';

/// `jug-01-codigo`: entrar a una sala con el código o el QR.
class CodigoPage extends StatelessWidget {
  const CodigoPage({
    super.key,
    required this.codigo,
    required this.salaNombre,
    required this.organizador,
    required this.filasLibres,
    this.alVerFilas,
    this.alEscanear,
  });

  final String codigo;
  final String salaNombre;
  final String organizador;
  final int filasLibres;
  final VoidCallback? alVerFilas;
  final VoidCallback? alEscanear;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return ColoredBox(
      color: paleta.fondo,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                child: Column(
                  children: [
                    const _Encabezado(),
                    const SizedBox(height: 14),
                    BingCasillasCodigo(codigo: codigo),
                    const SizedBox(height: 14),
                    BingEncontrada(
                      titulo: salaNombre,
                      detalle:
                          'Organiza $organizador · quedan $filasLibres '
                          'filas libres',
                    ),
                    const SizedBox(height: 14),
                    const BingSeparadorO(),
                    const SizedBox(height: 14),
                    BingBoton(
                      texto: 'Escanear el QR',
                      tipo: BingBotonTipo.linea,
                      icono: 'qr',
                      alPresionar: alEscanear,
                    ),
                  ],
                ),
              ),
            ),
            _Pie(alVerFilas: alVerFilas),
          ],
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
      child: Column(
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BingBolilla(columna: 0, numero: 9, letra: 'B'),
              SizedBox(width: 6),
              BingBolilla(columna: 1, numero: 30, letra: 'I'),
              SizedBox(width: 6),
              BingBolilla(columna: 2, numero: 38, letra: 'N'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Bing Bing',
            textAlign: TextAlign.center,
            style: BingTexto.marca.copyWith(color: paleta.tinta),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 250),
            child: Text(
              'Escribe el código que te dio quien organiza',
              textAlign: TextAlign.center,
              style: BingTexto.figtree(
                14.5,
                400,
                altura: 1.38,
              ).copyWith(color: paleta.apagado),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pie extends StatelessWidget {
  const _Pie({this.alVerFilas});

  final VoidCallback? alVerFilas;

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 22),
      decoration: BoxDecoration(
        color: paleta.fondo,
        border: Border(
          top: BorderSide(color: paleta.linea, width: BingMedidas.pieBorde),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BingBoton(
            texto: 'Ver filas libres',
            tipo: BingBotonTipo.tinta,
            alPresionar: alVerFilas,
          ),
          const SizedBox(height: 8),
          Text(
            'Sin cuenta. Tu nombre lo pones al elegir la fila.',
            textAlign: TextAlign.center,
            style: BingTexto.figtree(
              12,
              600,
              altura: 1.38,
            ).copyWith(color: paleta.apagado),
          ),
        ],
      ),
    );
  }
}
