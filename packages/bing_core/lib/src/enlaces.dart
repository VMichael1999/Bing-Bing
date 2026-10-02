/// Dominio gratuito de Firebase Hosting donde vive la página de cada sala.
const dominioEnlaces = 'bingbing-f1491.web.app';

/// Esquema propio, para abrir la app aunque el enlace web aún no esté verificado.
const esquemaApp = 'bingbing';

final _codigo = RegExp(r'^[A-Z2-9]{4}$');

/// Enlace web de una sala: lo que lleva el QR y lo que se comparte.
String enlaceSala(String codigo) => 'https://$dominioEnlaces/sala/$codigo';

/// Texto que se manda por WhatsApp o donde sea.
String textoCompartirSala({required String nombre, required String codigo}) =>
    'Juega "$nombre" en Bing Bing.\n'
    'Código: $codigo\n'
    '${enlaceSala(codigo)}';

/// Código de sala dentro de [texto], o `null` si no hay uno válido.
///
/// Acepta el código solo (`k7q4`, con o sin espacios), el enlace web
/// (`https://…/sala/K7Q4`) y el enlace de la app (`bingbing://sala/K7Q4`). Es lo
/// que lee tanto el QR escaneado como un enlace que abre la app.
String? codigoDeEnlace(String texto) {
  final limpio = texto.trim();
  if (limpio.isEmpty) return null;

  final directo = limpio.toUpperCase();
  if (_codigo.hasMatch(directo)) return directo;

  final uri = Uri.tryParse(limpio);
  if (uri == null) return null;
  final esWeb =
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host == dominioEnlaces;
  final esApp = uri.scheme == esquemaApp;
  if (!esWeb && !esApp) return null;

  // `https://host/sala/K7Q4` → segmentos [sala, K7Q4];
  // `bingbing://sala/K7Q4` → host `sala` y segmento [K7Q4].
  final partes = [
    if (esApp && uri.host.isNotEmpty) uri.host,
    ...uri.pathSegments,
  ];
  final i = partes.indexOf('sala');
  if (i < 0 || i + 1 >= partes.length) return null;
  final candidato = partes[i + 1].toUpperCase();
  return _codigo.hasMatch(candidato) ? candidato : null;
}
