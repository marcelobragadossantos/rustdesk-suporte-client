#!/usr/bin/env python3
"""Gera TODOS os assets de ícone/logo do app a partir da logo Hiperfarma.
Rodar da raiz do repo: python res/brand/make_brand_assets.py"""
import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "res", "brand", "logo.png")

def squared_transparent(src):
    img = Image.open(src).convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if r > 235 and g > 235 and b > 235:   # fundo claro -> transparente
                px[x, y] = (r, g, b, 0)
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
    side = max(img.size)
    m = int(side * 0.08)
    canvas = Image.new("RGBA", (side + 2 * m, side + 2 * m), (0, 0, 0, 0))
    canvas.paste(img, ((canvas.size[0] - img.size[0]) // 2,
                       (canvas.size[1] - img.size[1]) // 2), img)
    return canvas

base = squared_transparent(SRC)

def png(rel, size):
    p = os.path.join(ROOT, rel)
    base.resize((size, size), Image.LANCZOS).save(p)
    print("png ", rel, size)

def ico(rel, sizes):
    p = os.path.join(ROOT, rel)
    base.resize((max(sizes), max(sizes)), Image.LANCZOS).save(p, sizes=[(s, s) for s in sizes])
    print("ico ", rel, sizes)

# PNGs de logo/app
png("res/icon.png", 512)
png("res/128x128.png", 128)
png("res/128x128@2x.png", 256)
png("res/64x64.png", 64)
png("res/32x32.png", 32)

# ICOs (app principal, empacotador+MSI, tray)
ICO_SIZES = [16, 32, 48, 64, 128, 256]
ico("flutter/windows/runner/resources/app_icon.ico", ICO_SIZES)
ico("res/icon.ico", ICO_SIZES)
ico("res/tray-icon.ico", [16, 24, 32, 48, 64])

# Logos DENTRO do app Flutter (janela/home/barra de título).
# loadLogo() -> assets/logo.png ; loadIcon() -> assets/icon.png (fallback assets/icon.svg).
# Esses PNGs NÃO existem no upstream (cai no icon.svg azul do RustDesk) -> criamos vermelhos.
png("flutter/assets/icon.png", 512)
png("flutter/assets/logo.png", 512)

# icon.svg de fallback: SVG que embute o PNG vermelho (garante nada de azul mesmo no fallback).
import base64, io
buf = io.BytesIO()
base.resize((256, 256), Image.LANCZOS).save(buf, format="PNG")
b64 = base64.b64encode(buf.getvalue()).decode()
svg = ('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
       'viewBox="0 0 256 256"><image width="256" height="256" '
       f'xlink:href="data:image/png;base64,{b64}"/></svg>')
with open(os.path.join(ROOT, "flutter/assets/icon.svg"), "w", encoding="utf-8") as f:
    f.write(svg)
print("svg  flutter/assets/icon.svg (embedded png)")

print("OK: assets de marca gerados.")
