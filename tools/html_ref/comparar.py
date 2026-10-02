#!/usr/bin/env python3
"""Compara la captura del HTML con la de Flutter, desde y = 44 dp hacia abajo.

Uso: comparar.py referencia.png flutter.png salida.png
Escribe una imagen de tres paneles (HTML, Flutter, diferencia) e imprime el
porcentaje de píxeles distintos. Las capturas son de 320 dp a 3×.
"""
import sys
from PIL import Image, ImageChops

ESCALA = 3
Y0 = 44 * ESCALA  # se ignora la barra de estado falsa del HTML
UMBRAL = 24  # diferencia mínima por canal para contar un píxel

ref = Image.open(sys.argv[1]).convert('RGB')
fl = Image.open(sys.argv[2]).convert('RGB')
alto = min(ref.height, fl.height)
a, b = ref.crop((0, Y0, ref.width, alto)), fl.crop((0, Y0, ref.width, alto))
mascara = ImageChops.difference(a, b).convert('L').point(lambda v: 255 if v > UMBRAL else 0)
distintos = sum(1 for v in mascara.getdata() if v)
print(f'diferencia: {100 * distintos / (mascara.width * mascara.height):.2f}% ({distintos} px)')

rojo = Image.new('RGB', a.size, (255, 255, 255))
rojo.paste(Image.new('RGB', a.size, (220, 0, 0)), mask=mascara)
w = a.width
hoja = Image.new('RGB', (w * 3 + 40, a.height), (120, 120, 120))
hoja.paste(a, (0, 0))
hoja.paste(b, (w + 20, 0))
hoja.paste(rojo, (2 * w + 40, 0))
hoja.resize((hoja.width // 3, hoja.height // 3)).save(sys.argv[3])
