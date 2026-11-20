#!/usr/bin/env python3
"""Gerador das imagens autorais do HumaxOS: papéis de parede dos 5 dias e a foto "Show_Antigo" da Galeria.

Uso (a partir da raiz do projeto, onde fica o project.godot):
    python3 -I tools/gerar_imagens.py                 # escreve tudo em shared/assets/textures/
    python3 -I tools/gerar_imagens.py papeis          # só wallpaper_1.png ... wallpaper_5.png (1920x1080)
    python3 -I tools/gerar_imagens.py show            # só show_antigo.png (480x320, as mesmas dimensões dos metadados do VFS)
    python3 -I tools/gerar_imagens.py --previa        # também grava prévias reduzidas em tests/_saida/previas/

Clima de cada dia (o jogo troca o papel de parede junto com o dia):
    1  limpo, corporativo, sereno: azul/violeta suave, esfera luminosa discreta.
    2  frio, simétrico, vigilância: tudo espelhado e em excesso de ordem (anéis, grade, miras, moldura de câmera).
    3  micro-anomalias geométricas: a ordem do dia 2 com peças deslocadas, anéis quebrados e distorção só nas bordas.
    4  opressivo: tons frios com vermelho profundo, corredor que se fecha, interferência contida numa faixa.
    5  colapso visual: núcleo exposto, estilhaços, falhas controladas; o lado esquerdo continua limpo para a grade de ícones.

Tudo é determinístico (sementes fixas) e estático: nenhum quadro pisca. As imagens NÃO são obrigatórias: PapelDeParede e
ImagemProcedural continuam desenhando as versões procedurais quando o arquivo falta. Requer Pillow, numpy e scipy.
Não faz parte do jogo nem da exportação (tools/* é excluído).
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from scipy.ndimage import map_coordinates

RAIZ = os.path.abspath(os.getcwd())
SAIDA = os.path.join(RAIZ, "shared", "assets", "textures")
PREVIAS = os.path.join(RAIZ, "tests", "_saida", "previas")
L, A = 1920, 1080
FONTE_NEGRITO = "/usr/share/fonts/opentype/inter/Inter-ExtraBold.otf"
FONTE_MEDIA = "/usr/share/fonts/opentype/inter/Inter-Medium.otf"
FONTE_PRETA = "/usr/share/fonts/opentype/inter/Inter-Black.otf"


# ------------------------------------------------------------------ utilidades
def rgb(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32) / 255.0


def fonte(caminho, tamanho):
    try:
        return ImageFont.truetype(caminho, tamanho)
    except OSError:
        return ImageFont.load_default()


def gradiente(topo, base, diagonal=False, largura=L, altura=A):
    y = np.linspace(0.0, 1.0, altura, dtype=np.float32)[:, None]
    x = np.linspace(0.0, 1.0, largura, dtype=np.float32)[None, :]
    t = (0.5 * x + 0.5 * y) if diagonal else (y + 0 * x)
    return rgb(topo)[None, None, :] * (1 - t[..., None]) + rgb(base)[None, None, :] * t[..., None]


def brilho(img, cx, cy, raio, cor, forca, expoente=2.0, achatar=1.0):
    """Soma um brilho radial suave (cor em hex ou rgb 0..1) em img (float, altura x largura x 3)."""
    h, w = img.shape[:2]
    y = (np.arange(h, dtype=np.float32)[:, None] - cy) / (raio * achatar)
    x = (np.arange(w, dtype=np.float32)[None, :] - cx) / raio
    d = np.sqrt(x * x + y * y)
    m = np.clip(1.0 - d, 0.0, 1.0) ** expoente
    c = rgb(cor) if isinstance(cor, str) else np.asarray(cor, dtype=np.float32)
    img += (m * forca)[..., None] * c[None, None, :]
    return img


def vinheta(img, forca, raio=0.95):
    h, w = img.shape[:2]
    y = (np.arange(h, dtype=np.float32)[:, None] - h / 2) / (h / 2)
    x = (np.arange(w, dtype=np.float32)[None, :] - w / 2) / (w / 2)
    d = np.sqrt(x * x * 0.8 + y * y)
    m = 1.0 - forca * np.clip((d - 0.35) / raio, 0.0, 1.0) ** 1.6
    img *= m[..., None]
    return img


def ruido_fino(img, semente, amplitude=0.6 / 255.0):
    """Ruído triangular de ±1 nível (pontilhado): evita faixas nos degradês escuros sem pesar no PNG."""
    rng = np.random.default_rng(semente)
    r = (rng.random(img.shape[:2], dtype=np.float32) + rng.random(img.shape[:2], dtype=np.float32) - 1.0) * amplitude
    img += r[..., None]
    return img


def para_imagem(img):
    return Image.fromarray((np.clip(img, 0.0, 1.0) * 255.0 + 0.5).astype(np.uint8), "RGB")


class Camada:
    """Camada vetorial em RGBA com supersampling 2x (linhas finas sem serrilhado), composta sobre o fundo."""

    def __init__(self, largura=L, altura=A, escala=2):
        self.e = escala
        self.l = largura
        self.a = altura
        self.img = Image.new("RGBA", (largura * escala, altura * escala), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)

    def _c(self, cor, alfa):
        r, g, b = (int(round(v * 255)) for v in (rgb(cor) if isinstance(cor, str) else cor))
        return (r, g, b, int(round(alfa * 255)))

    def linha(self, p, q, cor, alfa, largura=1.0):
        e = self.e
        self.d.line([(p[0] * e, p[1] * e), (q[0] * e, q[1] * e)], fill=self._c(cor, alfa), width=max(1, int(round(largura * e))))

    def poli(self, pontos, cor, alfa, largura=1.0, fechado=False):
        e = self.e
        pts = [(x * e, y * e) for x, y in pontos]
        if fechado:
            pts = pts + [pts[0]]
        self.d.line(pts, fill=self._c(cor, alfa), width=max(1, int(round(largura * e))), joint="curve")

    def circulo(self, cx, cy, r, cor, alfa, largura=1.0, cheio=False):
        e = self.e
        caixa = [(cx - r) * e, (cy - r) * e, (cx + r) * e, (cy + r) * e]
        if cheio:
            self.d.ellipse(caixa, fill=self._c(cor, alfa))
        else:
            self.d.ellipse(caixa, outline=self._c(cor, alfa), width=max(1, int(round(largura * e))))

    def arco(self, cx, cy, rx, ry, a0, a1, cor, alfa, largura=1.0):
        e = self.e
        self.d.arc([(cx - rx) * e, (cy - ry) * e, (cx + rx) * e, (cy + ry) * e], a0, a1, fill=self._c(cor, alfa), width=max(1, int(round(largura * e))))

    def retangulo(self, x0, y0, x1, y1, cor, alfa, largura=1.0, cheio=False):
        e = self.e
        caixa = [x0 * e, y0 * e, x1 * e, y1 * e]
        if cheio:
            self.d.rectangle(caixa, fill=self._c(cor, alfa))
        else:
            self.d.rectangle(caixa, outline=self._c(cor, alfa), width=max(1, int(round(largura * e))))

    def poligono(self, pontos, cor, alfa):
        e = self.e
        self.d.polygon([(x * e, y * e) for x, y in pontos], fill=self._c(cor, alfa))

    def texto(self, xy, t, f, cor, alfa, ancora="mm", espacamento=0):
        e = self.e
        if espacamento:
            # tracking manual: desenha letra por letra (ancora central = centro do texto todo)
            ff = ImageFont.truetype(f.path, int(f.size * e)) if hasattr(f, "path") else f
            larguras = [self.d.textlength(ch, font=ff) for ch in t]
            total = sum(larguras) + espacamento * e * (len(t) - 1)
            x = xy[0] * e - total / 2 if ancora[0] == "m" else xy[0] * e
            for ch, wch in zip(t, larguras):
                self.d.text((x, xy[1] * e), ch, font=ff, fill=self._c(cor, alfa), anchor="l" + ancora[1])
                x += wch + espacamento * e
            return
        ff = ImageFont.truetype(f.path, int(f.size * e)) if hasattr(f, "path") else f
        self.d.text((xy[0] * e, xy[1] * e), t, font=ff, fill=self._c(cor, alfa), anchor=ancora)

    def compor(self, base_rgb_float):
        base = para_imagem(base_rgb_float).convert("RGBA")
        topo = self.img.resize((self.l, self.a), Image.LANCZOS)
        return np.asarray(Image.alpha_composite(base, topo).convert("RGB"), dtype=np.float32) / 255.0


def salvar(img, nome, previa):
    os.makedirs(SAIDA, exist_ok=True)
    pil = para_imagem(img) if isinstance(img, np.ndarray) else img
    caminho = os.path.join(SAIDA, nome)
    pil.save(caminho, optimize=True)
    print("%-20s %dx%d  %d KB" % (nome, pil.width, pil.height, os.path.getsize(caminho) // 1024))
    if previa:
        os.makedirs(PREVIAS, exist_ok=True)
        pil.resize((pil.width // 2, pil.height // 2) if pil.width > 1000 else (pil.width * 2, pil.height * 2), Image.LANCZOS).save(os.path.join(PREVIAS, nome))


# ------------------------------------------------------------------ dia 1: limpo, corporativo, sereno
def papel_1():
    img = gradiente("#141a45", "#3b3f95", diagonal=True)
    brilho(img, 1450, 330, 760, "#7894ff", 0.34)
    brilho(img, 520, 930, 880, "#9068ee", 0.24)
    brilho(img, 960, 540, 1100, "#5568d8", 0.10, expoente=1.5)
    cam = Camada()
    # anéis concêntricos suaves à direita (sensação de "ondas de serviço")
    for i, r in enumerate(range(170, 1100, 95)):
        cam.circulo(1500, 640, r, "#c8d4ff", 0.07 if i % 2 else 0.045, 2.0)
    # pontos de uma grade corporativa, bem discretos
    for y in range(60, A, 60):
        for x in range(60, L, 60):
            cam.circulo(x, y, 1.7, "#dbe4ff", 0.07, cheio=True)
    # esfera luminosa (a Maya "amigável"), meio apagada
    for r, a in ((190, 0.05), (150, 0.07), (110, 0.10)):
        cam.circulo(1490, 600, r, "#e4eaff", a, cheio=True)
    cam.circulo(1490, 600, 215, "#e4eaff", 0.30, 2.0)
    cam.arco(1490, 600, 265, 64, 200, 340, "#e4eaff", 0.32, 2.0)
    cam.arco(1490, 600, 265, 64, 20, 160, "#e4eaff", 0.14, 2.0)
    img = cam.compor(img)
    brilho(img, 1455, 548, 250, "#f2f5ff", 0.38, expoente=2.2)
    vinheta(img, 0.30)
    return ruido_fino(img, 1)


# ------------------------------------------------------------------ dia 2 (e base do 3): frio, simétrico, vigilância
def _base_vigilancia(anomalias, rng):
    img = gradiente("#091a24", "#10262f")
    brilho(img, 960, 540, 700, "#3c97aa", 0.23)
    brilho(img, 960, 540, 1250, "#26606e", 0.10, expoente=1.4)
    cam = Camada()
    cx, cy = 960, 540
    ciano = "#8fdcea"
    # anéis concêntricos
    for i, r in enumerate(range(110, 1180, 70)):
        if anomalias and r in (460, 600, 810):
            # anel quebrado: dois arcos com uma folga
            gap = {460: 28, 600: 40, 810: 22}[r]
            ini = {460: 200, 600: 20, 810: 100}[r]
            cam.arco(cx, cy, r, r, ini + gap, ini + 360 - gap, ciano, 0.16, 1.5)
            continue
        cam.circulo(cx, cy, r, ciano, 0.20 if i % 4 == 0 else 0.10, 1.5 if i % 4 == 0 else 1.0)
    # marcas radiais (lente/íris)
    for k in range(120):
        ang = 2 * math.pi * k / 120
        if anomalias and k in (17, 18, 77):
            ang += 0.018
        r0, r1 = (420, 452) if k % 10 == 0 else (420, 436)
        cam.linha((cx + r0 * math.cos(ang), cy + r0 * math.sin(ang)), (cx + r1 * math.cos(ang), cy + r1 * math.sin(ang)), ciano, 0.30 if k % 10 == 0 else 0.16, 1.5)
    # grade de câmeras: cruz em cada interseção, ponto a cada duas
    passo = 120
    for gy in range(0, A + 1, passo):
        cam.linha((0, gy), (L, gy), ciano, 0.045, 1.0)
    for gx in range(cx % passo, L + 1, passo):
        cam.linha((gx, 0), (gx, A), ciano, 0.045, 1.0)
    for gx in range(cx % passo, L + 1, passo):
        for gy in range(0, A + 1, passo):
            dx, dy = 0.0, 0.0
            if anomalias and rng.random() < 0.10 and 300 < abs(gx - cx) + abs(gy - cy):
                dx, dy = rng.uniform(-9, 9), rng.uniform(-9, 9)
            cam.linha((gx - 7 + dx, gy + dy), (gx + 7 + dx, gy + dy), ciano, 0.22, 1.2)
            cam.linha((gx + dx, gy - 7 + dy), (gx + dx, gy + 7 + dy), ciano, 0.22, 1.2)
            if ((gx - cx) // passo + gy // passo) % 2 == 0:
                cam.circulo(gx + dx, gy + dy, 3.0, ciano, 0.28, cheio=True)
    # íris hexagonal no centro
    for k in range(6):
        a0 = math.pi / 3 * k
        a1 = math.pi / 3 * (k + 1)
        p0 = (cx + 175 * math.cos(a0), cy + 175 * math.sin(a0))
        p1 = (cx + 175 * math.cos(a1), cy + 175 * math.sin(a1))
        cam.linha(p0, p1, ciano, 0.30, 2.0)
        cam.linha(p0, (cx + 70 * math.cos(a0 + 0.55), cy + 70 * math.sin(a0 + 0.55)), ciano, 0.22, 1.5)
    cam.circulo(cx, cy, 24, ciano, 0.45, 2.0)
    cam.circulo(cx, cy, 5, ciano, 0.55, cheio=True)
    # moldura de câmera: cantos e rótulo central (tudo espelhado)
    margem, comp = 58, 90
    for sx, x0 in ((1, margem), (-1, L - margem)):
        for sy, y0 in ((1, margem), (-1, A - margem)):
            cam.linha((x0, y0), (x0 + sx * comp, y0), ciano, 0.40, 3.0)
            cam.linha((x0, y0), (x0, y0 + sy * comp), ciano, 0.40, 3.0)
    for x0 in (margem + 130, L - margem - 130):
        cam.circulo(x0, margem + 8, 6, ciano, 0.45, cheio=True)
    cam.texto((cx, A - margem - 6), "MONITORAMENTO CONTÍNUO · SETOR 02 · SEM PONTOS CEGOS", fonte(FONTE_MEDIA, 17), ciano, 0.38, "mm", espacamento=5)
    img = cam.compor(img)
    # linhas de varredura bem fracas
    img[::4, :, :] *= 0.94
    return img


def papel_2():
    rng = np.random.default_rng(2)
    img = _base_vigilancia(False, rng)
    vinheta(img, 0.38)
    return ruido_fino(img, 2)


# ------------------------------------------------------------------ dia 3: micro-anomalias, distorção nas bordas, centro legível
def _distorcer(img, k, aberracao, raio_limpo):
    """Distorção de barril + aberração cromática que só crescem a partir de `raio_limpo` (fração do raio até a borda)."""
    h, w = img.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    nx = (xx - w / 2) / (w / 2)
    ny = (yy - h / 2) / (h / 2)
    r = np.sqrt(nx * nx + ny * ny)
    t = np.clip((r - raio_limpo) / (1.5 - raio_limpo), 0.0, 1.0)
    peso = t * t * (3 - 2 * t)  # smoothstep: zero no centro
    saida = np.empty_like(img)
    for canal, escala in ((0, 1.0 + aberracao), (1, 1.0), (2, 1.0 - aberracao)):
        fator = 1.0 + k * peso
        sx = (nx * fator * escala) * (w / 2) + w / 2
        sy = (ny * fator * escala) * (h / 2) + h / 2
        saida[..., canal] = map_coordinates(img[..., canal], [sy, sx], order=1, mode="reflect")
    return saida


def papel_3():
    rng = np.random.default_rng(3)
    img = _base_vigilancia(True, rng)
    # fatias horizontais deslocadas, só longe do centro
    for _ in range(9):
        y0 = int(rng.integers(60, A - 120))
        alt = int(rng.integers(5, 22))
        desloc = int(rng.integers(8, 26)) * (1 if rng.random() < 0.5 else -1)
        faixa = img[y0:y0 + alt, :, :].copy()
        lado = rng.random() < 0.5
        x0, x1 = (0, 520) if lado else (L - 520, L)
        img[y0:y0 + alt, x0:x1, :] = np.roll(faixa, desloc, axis=1)[:, x0:x1, :]
    # blocos pequenos de cor errada (magenta/ciano) nas bordas
    for _ in range(10):
        lado = rng.random() < 0.5
        x = int(rng.integers(20, 420)) if lado else int(rng.integers(L - 440, L - 40))
        y = int(rng.integers(80, A - 80))
        cor = rgb("#d946ef") if rng.random() < 0.5 else rgb("#22d3ee")
        bw, bh = int(rng.integers(18, 70)), int(rng.integers(3, 9))
        img[y:y + bh, x:x + bw, :] = img[y:y + bh, x:x + bw, :] * 0.6 + cor * 0.4
    img = _distorcer(img, k=0.075, aberracao=0.0045, raio_limpo=0.42)
    brilho(img, 960, 540, 520, "#8fdcea", 0.05)
    vinheta(img, 0.42)
    return ruido_fino(img, 3)


# ------------------------------------------------------------------ dia 4: opressivo, frio + vermelho profundo
def papel_4():
    rng = np.random.default_rng(4)
    img = gradiente("#080d15", "#111a26")
    brilho(img, 960, 1190, 1050, "#a3162b", 0.95, expoente=1.6, achatar=0.62)
    brilho(img, 960, 470, 130, "#8a1226", 0.30, expoente=2.0)
    brilho(img, 960, 470, 520, "#2c4a6a", 0.16)
    brilho(img, 960, 470, 900, "#1d2f46", 0.20, expoente=1.5)
    cam = Camada()
    pf = (960, 470)  # ponto de fuga: as paredes "se fecham"
    gelo = "#9db8d6"
    # corredor: retângulos encolhendo para o ponto de fuga
    for i in range(0, 11):
        f = 0.92 ** (i * 2.1)
        x0, x1 = pf[0] - 1180 * f, pf[0] + 1180 * f
        y0, y1 = pf[1] - 640 * f, pf[1] + 560 * f
        cam.retangulo(x0, y0, x1, y1, gelo, 0.15 if i % 2 else 0.24, 1.8)
    # arestas do corredor
    for ax, ay in ((0, 0), (L, 0), (0, A), (L, A)):
        cam.linha(pf, (ax, ay), gelo, 0.20, 1.8)
    for gx in range(0, L + 1, 160):
        cam.linha(pf, (gx, 0), gelo, 0.045, 1.0)
        cam.linha(pf, (gx, A), gelo, 0.045, 1.0)
    for gy in range(0, A + 1, 135):
        cam.linha(pf, (0, gy), gelo, 0.045, 1.0)
        cam.linha(pf, (L, gy), gelo, 0.045, 1.0)
    # moldura que aperta
    cam.retangulo(34, 34, L - 34, A - 34, gelo, 0.18, 2.0)
    cam.retangulo(70, 70, L - 70, A - 70, gelo, 0.08, 1.2)
    img = cam.compor(img)
    # interferência contida: poucas linhas vermelhas numa faixa fina + eco em vermelho do corredor
    faixa = Camada()
    for _ in range(11):
        y = int(rng.integers(600, 690))
        x0 = int(rng.integers(560, 1100))
        faixa.linha((x0, y), (x0 + int(rng.integers(160, 620)), y), "#e0213a", float(rng.uniform(0.16, 0.34)), float(rng.uniform(1.0, 3.0)))
    img = faixa.compor(img)
    img[612:690, 520:1500, 0] = np.roll(img[612:690, 520:1500, 0], 7, axis=1)
    img[612:690, 520:1500, 2] = np.roll(img[612:690, 520:1500, 2], -5, axis=1)
    vinheta(img, 0.62, 0.9)
    img[::3, :, :] *= 0.955
    return ruido_fino(img, 4)


# ------------------------------------------------------------------ dia 5: colapso visual, núcleo exposto
def papel_5():
    rng = np.random.default_rng(5)
    img = gradiente("#05060b", "#0a0710")
    cx, cy = 1340, 520
    brilho(img, cx, cy, 700, "#5a2aa8", 0.52, expoente=2.0)
    brilho(img, cx, cy, 430, "#d21e50", 0.80, expoente=2.2)
    brilho(img, cx, cy, 230, "#ff6a5a", 0.85, expoente=2.0)
    brilho(img, cx, cy, 105, "#fff1e2", 1.00, expoente=1.6)
    cam = Camada()
    ciano, magenta, branco = "#35d3ee", "#e8359a", "#ffeedd"
    # anéis orbitais em arcos (com falhas)
    for raio, inclin, cor, alfa in ((190, 0.35, ciano, 0.55), (255, 0.5, magenta, 0.50), (330, 0.28, branco, 0.30), (410, 0.62, ciano, 0.28)):
        for seg in range(6):
            ini = seg * 60 + float(rng.uniform(0, 14))
            fim = ini + float(rng.uniform(20, 46))
            cam.arco(cx, cy, raio, raio * inclin * 2, ini, fim, cor, alfa, 2.5)
    # rachaduras que saem do núcleo
    for _ in range(22):
        ang = float(rng.uniform(0, 2 * math.pi))
        comp = float(rng.uniform(220, 880))
        pts = [(cx, cy)]
        a = ang
        d = 0.0
        while d < comp:
            d += float(rng.uniform(40, 90))
            a += float(rng.uniform(-0.18, 0.18))
            pts.append((cx + d * math.cos(a), cy + d * math.sin(a)))
        corte = next((i for i, p in enumerate(pts) if p[0] < 800), len(pts))  # o lado esquerdo fica limpo: a rachadura para antes
        pts = pts[:corte]
        if len(pts) >= 2:
            cam.poli(pts, branco, float(rng.uniform(0.18, 0.42)), float(rng.uniform(1.0, 2.2)))
    # estilhaços escuros da "tela" flutuando na frente do núcleo
    for _ in range(15):
        ang = float(rng.uniform(0, 2 * math.pi))
        dist = float(rng.uniform(150, 560))
        px, py = cx + dist * math.cos(ang), cy + dist * math.sin(ang)
        if px < 860:
            continue
        tam = float(rng.uniform(40, 150))
        base_ang = float(rng.uniform(0, 2 * math.pi))
        pts = [(px + tam * math.cos(base_ang + k * 2.1 + float(rng.uniform(-0.5, 0.5))) * float(rng.uniform(0.5, 1.1)),
                py + tam * math.sin(base_ang + k * 2.1 + float(rng.uniform(-0.5, 0.5))) * float(rng.uniform(0.5, 1.1))) for k in range(3)]
        cam.poligono(pts, "#05060b", 0.90)
        cam.poli(pts, ciano, 0.30, 1.4, fechado=True)
    img = cam.compor(img)
    # falhas controladas: fatias deslocadas só no lado direito, com separação RGB
    for _ in range(14):
        y0 = int(rng.integers(170, 930))
        alt = int(rng.integers(4, 22))
        desloc = int(rng.integers(18, 70)) * (1 if rng.random() < 0.5 else -1)
        trecho = img[y0:y0 + alt, 760:, :].copy()
        movido = np.roll(trecho, desloc, axis=1)
        movido[..., 0] = np.roll(movido[..., 0], 6, axis=1)
        movido[..., 2] = np.roll(movido[..., 2], -6, axis=1)
        img[y0:y0 + alt, 760:, :] = movido
    for _ in range(9):
        x = int(rng.integers(900, 1800))
        y = int(rng.integers(180, 900))
        bw, bh = int(rng.integers(40, 170)), int(rng.integers(5, 18))
        cor = rgb(magenta) if rng.random() < 0.5 else rgb(ciano)
        img[y:y + bh, x:x + bw, :] = img[y:y + bh, x:x + bw, :] * 0.55 + cor * 0.45
    # lado esquerdo limpo e escuro para a grade de ícones
    xs = np.linspace(0.0, 1.0, L, dtype=np.float32)
    esq = 0.55 + 0.45 * np.clip((xs - 0.18) / 0.34, 0.0, 1.0)
    img *= esq[None, :, None]
    vinheta(img, 0.45)
    return ruido_fino(img, 5)


# ------------------------------------------------------------------ foto da Galeria: Show_Antigo (480x320)
def foto_show_antigo():
    e = 4
    W, H = 480 * e, 320 * e
    rng = np.random.default_rng(1999)
    img = np.zeros((H, W, 3), dtype=np.float32)
    # fundo do teatro: escuro, quente
    img += gradiente("#0d0710", "#2a130f", largura=W, altura=H)
    # cortinas de veludo nas laterais (dobras verticais)
    xs = np.arange(W, dtype=np.float32)[None, :]
    for lado, (x0, x1) in enumerate(((0, 70 * e), (W - 70 * e, W))):
        dobras = 0.55 + 0.45 * np.sin((xs[:, x0:x1] / e) * 0.62 + lado)
        borda = (1.0 - np.abs((xs[:, x0:x1] - x0) / (x1 - x0) * 2 - 1) ** 3) if lado == 0 else (1.0 - np.abs((xs[:, x0:x1] - x0) / (x1 - x0) * 2 - 1) ** 3)
        cor = np.array([0.46, 0.05, 0.08], dtype=np.float32)
        img[:, x0:x1, :] = img[:, x0:x1, :] * 0.3 + (dobras * 0.85 * (0.4 + 0.6 * borda))[..., None] * cor[None, None, :]
    # piso do palco, iluminado
    chao_y = int(H * 0.66)
    brilho(img, W * 0.5, chao_y + 10 * e, 220 * e, "#ffb15a", 0.55, expoente=1.6, achatar=0.35)
    img[chao_y:, :, :] *= 0.85
    # cones de luz vindos de cima
    for cx_luz, cor in ((0.20, "#ffd98a"), (0.50, "#fff1c8"), (0.80, "#ffc26e")):
        yy = np.arange(H, dtype=np.float32)[:, None]
        xx = np.arange(W, dtype=np.float32)[None, :]
        topo_x = cx_luz * W
        largura_cone = (22 * e + (yy / H) * 110 * e)
        cone = np.clip(1.0 - np.abs(xx - topo_x) / largura_cone, 0.0, 1.0) ** 1.8 * (1.0 - 0.55 * yy / H) * 0.34
        img += cone[..., None] * rgb(cor)[None, None, :]
    pil = para_imagem(np.clip(img, 0, 1)).convert("RGBA")
    d = ImageDraw.Draw(pil)

    # faixa/pano de fundo com o nome da banda (a pista visível: nome + ano)
    px0, py0, px1, py1 = 96 * e, 30 * e, 384 * e, 124 * e
    d.rectangle([px0 - 3 * e, py0 - 3 * e, px1 + 3 * e, py1 + 3 * e], fill=(28, 18, 14, 255))
    d.rectangle([px0, py0, px1, py1], fill=(12, 10, 18, 255))
    # espiral da banda (vertigem)
    cxs, cys = 128 * e, 74 * e
    pts = []
    for k in range(0, 520):
        t = k / 520.0
        ang = t * 4.6 * math.pi
        rr = (3 + 26 * t) * e
        pts.append((cxs + rr * math.cos(ang), cys + rr * math.sin(ang)))
    d.line(pts, fill=(255, 208, 110, 255), width=int(2.4 * e), joint="curve")
    f_banda = ImageFont.truetype(FONTE_PRETA, int(36 * e))
    f_sub = ImageFont.truetype(FONTE_NEGRITO, int(11 * e))
    f_ano = ImageFont.truetype(FONTE_PRETA, int(19 * e))
    # "VERTIGEM" com letras espaçadas
    texto = "VERTIGEM"
    esp = 2.2 * e
    larguras = [d.textlength(ch, font=f_banda) for ch in texto]
    total = sum(larguras) + esp * (len(texto) - 1)
    x = (px0 + 56 * e) + ((px1 - (px0 + 56 * e)) - total) / 2
    for ch, wch in zip(texto, larguras):
        d.text((x + 1.5 * e, 70 * e + 1.5 * e), ch, font=f_banda, fill=(120, 40, 20, 255), anchor="lm")
        d.text((x, 70 * e), ch, font=f_banda, fill=(255, 236, 190, 255), anchor="lm")
        x += wch + esp
    cx_texto = (px0 + 56 * e + px1) / 2
    d.text((cx_texto, 100 * e), "TEATRO ODEON  ·  12.10.1999", font=f_sub, fill=(255, 190, 110, 255), anchor="mm")
    d.text((cx_texto, 114 * e), "PRIMEIRO SHOW", font=ImageFont.truetype(FONTE_MEDIA, int(8 * e)), fill=(220, 160, 100, 255), anchor="mm")

    # banda: silhuetas no palco
    def sil(pontos, cor=(8, 6, 10, 255)):
        d.polygon([(x * e, y * e) for x, y in pontos], fill=cor)

    chao = 214
    # baterista (centro-fundo) com a bateria
    d.ellipse([(236 - 17) * e, (170 - 17) * e, (236 + 17) * e, (170 + 17) * e], fill=(8, 6, 10, 255))  # bumbo
    d.ellipse([(214 - 14) * e, (150 - 5) * e, (214 + 14) * e, (150 + 5) * e], fill=(8, 6, 10, 255))   # prato
    d.ellipse([(262 - 14) * e, (146 - 5) * e, (262 + 14) * e, (146 + 5) * e], fill=(8, 6, 10, 255))
    sil([(228, 160), (244, 160), (247, 186), (225, 186)])
    d.ellipse([(236 - 7) * e, (150 - 7) * e, (236 + 7) * e, (150 + 7) * e], fill=(8, 6, 10, 255))
    # vocalista (frente, esquerda) com microfone
    d.ellipse([(168 - 7) * e, (140 - 7) * e, (168 + 7) * e, (140 + 7) * e], fill=(8, 6, 10, 255))
    sil([(160, 149), (176, 149), (182, 184), (176, chao), (160, chao), (154, 184)])
    d.line([(150 * e, 148 * e), (140 * e, 170 * e)], fill=(8, 6, 10, 255), width=4 * e)
    d.line([(178 * e, 150 * e), (190 * e, 142 * e)], fill=(8, 6, 10, 255), width=4 * e)
    d.line([(194 * e, 142 * e), (194 * e, chao * e)], fill=(8, 6, 10, 255), width=2 * e)  # pedestal
    # guitarrista (frente, direita)
    d.ellipse([(312 - 7) * e, (144 - 7) * e, (312 + 7) * e, (144 + 7) * e], fill=(8, 6, 10, 255))
    sil([(303, 153), (321, 153), (326, 186), (319, chao), (303, chao), (298, 186)])
    d.line([(294 * e, 174 * e), (346 * e, 154 * e)], fill=(8, 6, 10, 255), width=5 * e)  # braço da guitarra
    d.ellipse([(300 - 11) * e, (174 - 8) * e, (300 + 11) * e, (174 + 8) * e], fill=(8, 6, 10, 255))
    # amplificadores
    d.rectangle([60 * e, 186 * e, 92 * e, chao * e], fill=(14, 10, 12, 255))
    d.rectangle([388 * e, 182 * e, 424 * e, chao * e], fill=(14, 10, 12, 255))
    pil = pil.filter(ImageFilter.GaussianBlur(0.7 * e / 2))
    d = ImageDraw.Draw(pil)

    # plateia em primeiro plano: cabeças e mãos em silhueta, plaquinha da fileira G
    cabeca_y = 262
    x = -10
    while x < 490:
        r = float(rng.uniform(12, 17))
        y = cabeca_y + float(rng.uniform(-10, 14))
        d.ellipse([(x - r) * e, (y - r) * e, (x + r) * e, (y + r) * e], fill=(4, 3, 6, 255))
        d.rectangle([(x - r * 1.5) * e, (y + r * 0.6) * e, (x + r * 1.5) * e, 330 * e], fill=(4, 3, 6, 255))
        if rng.random() < 0.18:
            hx = x + float(rng.uniform(-8, 8))
            hx2 = hx + float(rng.uniform(-7, 7))
            hy2 = y - r * float(rng.uniform(2.1, 2.7))
            d.line([(hx * e, (y - r * 0.2) * e), (hx2 * e, hy2 * e)], fill=(4, 3, 6, 255), width=int(4 * e))
            d.ellipse([(hx2 - 4.5) * e, (hy2 - 5) * e, (hx2 + 4.5) * e, (hy2 + 4) * e], fill=(4, 3, 6, 255))  # mão
        x += float(rng.uniform(26, 38))
    d.rectangle([20 * e, 296 * e, 58 * e, 316 * e], fill=(90, 74, 40, 255))
    d.text((39 * e, 306 * e), "G", font=ImageFont.truetype(FONTE_PRETA, int(14 * e)), fill=(20, 14, 8, 255), anchor="mm")

    img = np.asarray(pil.convert("RGB"), dtype=np.float32) / 255.0
    # película: tom quente, vinheta, grão e poeira; depois reduz para 480x320 (suaviza o serrilhado)
    img[..., 0] *= 1.06
    img[..., 2] *= 0.88
    vinheta(img, 0.55, 0.85)
    grao = rng.normal(0.0, 0.030, size=(H, W)).astype(np.float32)
    img += grao[..., None]
    pil2 = para_imagem(img).resize((480, 320), Image.LANCZOS)
    d2 = ImageDraw.Draw(pil2)
    for _ in range(14):  # poeira e riscos da digitalização
        x0, y0 = int(rng.integers(0, 480)), int(rng.integers(0, 320))
        d2.line([(x0, y0), (x0 + int(rng.integers(-3, 4)), y0 + int(rng.integers(2, 11)))], fill=(150, 140, 128), width=1)
    # carimbo de data da câmera (laranja, canto inferior direito): '99 10 12
    f_stamp = ImageFont.truetype(FONTE_NEGRITO, 14)
    d2.text((468, 311), "’99  10  12", font=f_stamp, fill=(255, 132, 30), anchor="rb")
    return pil2


# ------------------------------------------------------------------ main
def main():
    args = [a for a in sys.argv[1:]]
    previa = "--previa" in args
    args = [a for a in args if not a.startswith("--")]
    quais = args or ["papeis", "show"]
    if "papeis" in quais:
        for dia, fn in enumerate((papel_1, papel_2, papel_3, papel_4, papel_5), start=1):
            salvar(fn(), "wallpaper_%d.png" % dia, previa)
    if "show" in quais:
        salvar(foto_show_antigo(), "show_antigo.png", previa)


if __name__ == "__main__":
    main()
