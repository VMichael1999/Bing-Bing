import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'icono.dart';
import 'medidas.dart';
import 'tema.dart';
import 'tipografia.dart';

/// Campo de texto de 50 dp (`.field`), con ícono a la izquierda.
///
/// Con foco o con texto el borde pasa a `tinta` y el texto a peso 700.
class BingCampo extends StatefulWidget {
  const BingCampo({
    super.key,
    required this.controlador,
    required this.icono,
    this.pista,
    this.maxLargo = 18,
    this.alCambiar,
  });

  final TextEditingController controlador;
  final String icono;
  final String? pista;
  final int maxLargo;
  final ValueChanged<String>? alCambiar;

  @override
  State<BingCampo> createState() => _BingCampoState();
}

class _BingCampoState extends State<BingCampo> {
  final _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    _foco.addListener(_redibujar);
    widget.controlador.addListener(_redibujar);
  }

  void _redibujar() => setState(() {});

  @override
  void dispose() {
    widget.controlador.removeListener(_redibujar);
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paleta = BingTema.of(context);
    final activo = _foco.hasFocus || widget.controlador.text.isNotEmpty;
    final estilo = BingTexto.figtree(
      14.5,
      activo ? 700 : 400,
    ).copyWith(color: activo ? paleta.tinta : paleta.apagado);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _foco.requestFocus,
      child: Container(
        height: BingMedidas.alturaCampo,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: paleta.tarjeta,
          borderRadius: BorderRadius.circular(BingMedidas.radioCampo),
          border: Border.all(
            color: activo ? paleta.tinta : paleta.linea,
            width: BingMedidas.bordeCampo,
          ),
        ),
        child: Row(
          children: [
            BingIcono(
              widget.icono,
              color: activo ? paleta.tinta : paleta.apagado,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  if (widget.pista != null && widget.controlador.text.isEmpty)
                    Text(widget.pista!, style: estilo),
                  EditableText(
                    controller: widget.controlador,
                    focusNode: _foco,
                    style: estilo,
                    cursorColor: paleta.tinta,
                    cursorWidth: 1.5,
                    cursorHeight: 18,
                    backgroundCursorColor: paleta.linea,
                    maxLines: 1,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(widget.maxLargo),
                    ],
                    onChanged: widget.alCambiar,
                    autocorrect: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
