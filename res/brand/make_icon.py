#!/usr/bin/env python3
"""Gera app_icon.ico (multi-res, fundo transparente) a partir da logo Hiperfarma."""
import os
from PIL import Image

SRC = os.path.join(os.path.dirname(__file__), "logo.png")
OUT_ICO = os.path.join(os.path.dirname(__file__), "app_icon.ico")
OUT_PNG = os.path.join(os.path.dirname(__file__), "app_icon_512.png")

img = Image.open(SRC).convert("RGBA")

# 1) fundo quase-branco -> transparente (logo é vermelho puro sobre claro)
px = img.load()
w, h = img.size
for y in range(h):
    for x in range(w):
        r, g, b, a = px[x, y]
        # pixel claro (todos os canais altos e pouca saturação) => transparente
        if r > 235 and g > 235 and b > 235:
            px[x, y] = (r, g, b, 0)

# 2) recortar no bounding box do conteúdo visível
bbox = img.getbbox()
if bbox:
    img = img.crop(bbox)

# 3) padronizar em quadrado (centralizado) com margem leve
side = max(img.size)
margin = int(side * 0.08)
canvas = Image.new("RGBA", (side + 2 * margin, side + 2 * margin), (0, 0, 0, 0))
canvas.paste(img, ((canvas.size[0] - img.size[0]) // 2,
                   (canvas.size[1] - img.size[1]) // 2), img)

# 4) exportar
base = canvas.resize((512, 512), Image.LANCZOS)
base.save(OUT_PNG)
base.save(OUT_ICO, sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
print("OK ->", OUT_ICO, "| sizes 16..256 | quadrado", base.size)
