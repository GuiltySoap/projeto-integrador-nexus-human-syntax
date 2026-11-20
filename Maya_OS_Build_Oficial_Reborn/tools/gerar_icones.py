#!/usr/bin/env python3
"""Gerador dos ícones dos aplicativos do HumaxOS (SVG, 128x128, fundo transparente).

Uso (a partir da raiz do projeto, onde fica o project.godot):
    python3 -I tools/gerar_icones.py            # escreve shared/assets/icons/apps/<id>.svg (12 apps + lixeira)
    python3 -I tools/gerar_icones.py --folha    # também grava a folha de contato (PNG) em tests/_saida/icones_folha.png

Estilo: azulejo arredondado com a cor do catálogo (core/data/catalogo_apps.json) e um glifo geométrico em azul-marinho,
com os detalhes recortados em um tom claro do azulejo. A tinta tem contraste altíssimo com todos os azulejos (conferido e
impresso ao gerar) e o azulejo claro continua visível sobre painéis escuros e no tema de alto contraste. O arquivo é
determinístico. O jogo NÃO depende dos ícones: IconeApp cai no bloco colorido com emoji quando o arquivo falta.
Só biblioteca padrão (a folha de contato usa `rsvg-convert` e Pillow, ambos opcionais). Não faz parte da exportação.
"""
import math
import os
import sys

RAIZ = os.path.abspath(os.getcwd())
SAIDA_ICONES = os.path.join(RAIZ, "shared", "assets", "icons", "apps")
SAIDA_TEXTURAS = os.path.join(RAIZ, "shared", "assets", "textures")
SAIDA_AUDIO = os.path.join(RAIZ, "shared", "assets", "audio")

# ------------------------------------------------------------------ ícones
TINTA = "#0f172a"  # azul-marinho dos glifos: contraste alto sobre qualquer cor de azulejo do catálogo


def _hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def _rgb_hex(c):
    return "#%02x%02x%02x" % tuple(max(0, min(255, int(round(v)))) for v in c)


def misturar(a, b, t):
    """Mistura a cor hex `a` com `b` (t = 0 devolve a, t = 1 devolve b)."""
    ca, cb = _hex_rgb(a), _hex_rgb(b)
    return _rgb_hex(tuple(ca[i] + (cb[i] - ca[i]) * t for i in range(3)))


def _lum(c):
    def f(v):
        v /= 255.0
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = _hex_rgb(c)
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def contraste(a, b):
    la, lb = _lum(a), _lum(b)
    if la < lb:
        la, lb = lb, la
    return (la + 0.05) / (lb + 0.05)


# Cada glifo desenha em 128x128; {t} = tinta (escura), {p} = "papel" (tom claro do azulejo), {b} = cor base do azulejo.
def _g_explorer():
    return (
        '<path d="M22 46 Q22 36 32 36 H54 Q58 36 61 40 L67 48 H96 Q106 48 106 58 V92 Q106 102 96 102 H32 Q22 102 22 92 Z" fill="{t}"/>'
        '<rect x="22" y="58" width="84" height="44" rx="10" fill="{p}" stroke="{t}" stroke-width="6"/>'
        '<rect x="34" y="70" width="30" height="6" rx="3" fill="{t}" fill-opacity="0.55"/>'
    )


def _g_text_editor():
    return (
        '<rect x="30" y="24" width="58" height="80" rx="9" fill="{t}"/>'
        '<rect x="40" y="40" width="38" height="7" rx="3.5" fill="{p}"/>'
        '<rect x="40" y="55" width="38" height="7" rx="3.5" fill="{p}"/>'
        '<rect x="40" y="70" width="24" height="7" rx="3.5" fill="{p}"/>'
        '<g transform="rotate(38 92 78)">'
        '<rect x="85" y="42" width="15" height="46" rx="3" fill="{p}" stroke="{t}" stroke-width="5"/>'
        '<path d="M85 90 H100 L92.5 106 Z" fill="{t}"/>'
        '</g>'
    )


def _g_messenger():
    return (
        '<rect x="22" y="28" width="84" height="60" rx="22" fill="{t}"/>'
        '<path d="M40 84 L32 108 L66 86 Z" fill="{t}"/>'
        '<circle cx="46" cy="58" r="7" fill="{p}"/>'
        '<circle cx="64" cy="58" r="7" fill="{p}"/>'
        '<circle cx="82" cy="58" r="7" fill="{p}"/>'
    )


def _g_email():
    return (
        '<rect x="20" y="34" width="88" height="62" rx="12" fill="{t}"/>'
        '<path d="M28 46 L64 74 L100 46" fill="none" stroke="{p}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>'
    )


def _g_media_viewer():
    return (
        '<rect x="20" y="30" width="88" height="68" rx="12" fill="{t}"/>'
        '<rect x="29" y="39" width="70" height="50" rx="5" fill="{p}"/>'
        '<path d="M29 89 L50 62 L64 78 L77 64 L99 89 Z" fill="{t}"/>'
        '<circle cx="84" cy="52" r="7" fill="{t}"/>'
    )


def _g_calendar():
    return (
        '<rect x="22" y="30" width="84" height="76" rx="12" fill="{t}"/>'
        '<rect x="22" y="30" width="84" height="22" rx="12" fill="{t}"/>'
        '<rect x="30" y="58" width="68" height="40" rx="5" fill="{p}"/>'
        '<rect x="40" y="19" width="9" height="22" rx="4.5" fill="{t}" stroke="{b}" stroke-width="3"/>'
        '<rect x="79" y="19" width="9" height="22" rx="4.5" fill="{t}" stroke="{b}" stroke-width="3"/>'
        '<rect x="38" y="66" width="12" height="9" rx="2.5" fill="{t}"/>'
        '<rect x="58" y="66" width="12" height="9" rx="2.5" fill="{t}"/>'
        '<rect x="78" y="66" width="12" height="9" rx="2.5" fill="{t}"/>'
        '<rect x="38" y="81" width="12" height="9" rx="2.5" fill="{t}"/>'
        '<rect x="58" y="81" width="12" height="9" rx="2.5" fill="{t}"/>'
    )


def _g_calculator():
    teclas = ""
    for i in range(3):
        for j in range(3):
            teclas += '<rect x="%d" y="%d" width="12" height="12" rx="3.5" fill="{p}"/>' % (41 + i * 17, 62 + j * 14)
    return (
        '<rect x="30" y="20" width="68" height="88" rx="12" fill="{t}"/>'
        '<rect x="39" y="29" width="50" height="20" rx="5" fill="{p}"/>'
        + teclas
    )


def _g_settings():
    dentes = "".join('<rect x="55" y="22" width="18" height="24" rx="4" fill="{t}" transform="rotate(%d 64 64)"/>' % (a * 45) for a in range(8))
    return (
        dentes +
        '<circle cx="64" cy="64" r="30" fill="{t}"/>'
        '<circle cx="64" cy="64" r="12" fill="{p}"/>'
    )


def _g_browser():
    return (
        '<circle cx="64" cy="64" r="40" fill="{t}"/>'
        '<circle cx="64" cy="64" r="31" fill="none" stroke="{p}" stroke-width="5"/>'
        '<ellipse cx="64" cy="64" rx="14" ry="31" fill="none" stroke="{p}" stroke-width="5"/>'
        '<path d="M33 64 H95 M38 49 H90 M38 79 H90" fill="none" stroke="{p}" stroke-width="5" stroke-linecap="round"/>'
    )


def _g_terminal():
    return (
        '<rect x="18" y="28" width="92" height="72" rx="12" fill="{t}"/>'
        '<path d="M36 50 L54 64 L36 78" fill="none" stroke="{p}" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>'
        '<rect x="62" y="75" width="28" height="8" rx="4" fill="{p}"/>'
    )


def _g_task_manager():
    return (
        '<rect x="18" y="26" width="92" height="64" rx="12" fill="{t}"/>'
        '<rect x="32" y="62" width="11" height="18" rx="3" fill="{p}"/>'
        '<rect x="49" y="50" width="11" height="30" rx="3" fill="{p}"/>'
        '<rect x="66" y="40" width="11" height="40" rx="3" fill="{p}"/>'
        '<rect x="83" y="54" width="11" height="26" rx="3" fill="{p}"/>'
        '<rect x="54" y="92" width="20" height="8" rx="2" fill="{t}"/>'
        '<rect x="40" y="99" width="48" height="8" rx="4" fill="{t}"/>'
    )


def _g_text_reader():
    return (
        '<path d="M34 22 H78 L98 42 V106 H34 Z" fill="{t}" stroke="{t}" stroke-width="8" stroke-linejoin="round"/>'
        '<path d="M78 22 V42 H98 Z" fill="{p}"/>'
        '<rect x="45" y="54" width="42" height="7" rx="3.5" fill="{p}"/>'
        '<rect x="45" y="68" width="42" height="7" rx="3.5" fill="{p}"/>'
        '<rect x="45" y="82" width="26" height="7" rx="3.5" fill="{p}"/>'
    )


def _g_lixeira():
    return (
        '<rect x="50" y="20" width="28" height="12" rx="5" fill="{t}"/>'
        '<rect x="26" y="32" width="76" height="11" rx="5.5" fill="{t}"/>'
        '<path d="M33 49 H95 L90 100 Q89 108 81 108 H47 Q39 108 38 100 Z" fill="{t}"/>'
        '<rect x="48" y="58" width="7" height="38" rx="3.5" fill="{p}"/>'
        '<rect x="60.5" y="58" width="7" height="38" rx="3.5" fill="{p}"/>'
        '<rect x="73" y="58" width="7" height="38" rx="3.5" fill="{p}"/>'
    )


# id -> (cor do azulejo = cor do catálogo/área de trabalho, função do glifo)
ICONES = {
    "explorer": ("#f59e0b", _g_explorer),
    "text_editor": ("#38bdf8", _g_text_editor),
    "messenger": ("#60a5fa", _g_messenger),
    "email": ("#c084fc", _g_email),
    "media_viewer": ("#f472b6", _g_media_viewer),
    "calendar": ("#34d399", _g_calendar),
    "calculator": ("#fbbf24", _g_calculator),
    "settings": ("#94a3b8", _g_settings),
    "browser": ("#22d3ee", _g_browser),
    "terminal": ("#4ade80", _g_terminal),
    "task_manager": ("#f87171", _g_task_manager),
    "text_reader": ("#e2e8f0", _g_text_reader),
    "lixeira": ("#94a3b8", _g_lixeira),
}


def montar_svg(base, glifo):
    topo = misturar(base, "#ffffff", 0.30)
    fundo = misturar(base, TINTA, 0.10)
    papel = misturar(base, "#ffffff", 0.78)
    corpo = glifo().replace("{t}", TINTA).replace("{p}", papel).replace("{b}", base)
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">\n'
        '  <defs>\n'
        '    <linearGradient id="azulejo" x1="0" y1="0" x2="0" y2="1">\n'
        '      <stop offset="0" stop-color="%s"/>\n'
        '      <stop offset="1" stop-color="%s"/>\n'
        '    </linearGradient>\n'
        '  </defs>\n'
        '  <rect x="5" y="5" width="118" height="118" rx="28" fill="url(#azulejo)" stroke="%s" stroke-opacity="0.55" stroke-width="3"/>\n'
        '  <rect x="7.5" y="7.5" width="113" height="113" rx="25.5" fill="none" stroke="#ffffff" stroke-opacity="0.35" stroke-width="2"/>\n'
        '  %s\n'
        '</svg>\n'
    ) % (topo, fundo, TINTA, corpo)


def gerar_icones():
    os.makedirs(SAIDA_ICONES, exist_ok=True)
    for id_app, (base, glifo) in ICONES.items():
        caminho = os.path.join(SAIDA_ICONES, id_app + ".svg")
        with open(caminho, "w", encoding="utf-8", newline="\n") as f:
            f.write(montar_svg(base, glifo))
        papel = misturar(base, "#ffffff", 0.78)
        print("%-13s tinta/azulejo %.1f:1  tinta/papel %.1f:1" % (id_app, contraste(TINTA, base), contraste(TINTA, papel)))


def folha_de_contato():
    """PNG com cada ícone em 128, 52, 40 e 22 px sobre fundo escuro e claro (conferência visual; não entra no jogo)."""
    import subprocess
    from PIL import Image
    pasta = os.path.join(RAIZ, "tests", "_saida")
    os.makedirs(pasta, exist_ok=True)
    tmp = os.path.join(pasta, "_tmp_icone.png")
    tamanhos = [128, 52, 40, 22]
    ids = list(ICONES.keys())
    por_bloco = (len(ids) + 1) // 2
    painel = 10 + sum(t + 14 for t in tamanhos)
    altura_linha = 144
    folha = Image.new("RGB", (painel * 4, 10 + por_bloco * altura_linha), (15, 23, 42))
    for k in (1, 3):
        folha.paste(Image.new("RGB", (painel, folha.height), (226, 232, 240)), (painel * k, 0))
    for n, id_app in enumerate(ids):
        bloco, linha = divmod(n, por_bloco)
        for cor in (0, 1):
            x = (bloco * 2 + cor) * painel + 10
            y = 10 + linha * altura_linha
            for t in tamanhos:
                subprocess.run(["rsvg-convert", "-w", str(t), "-h", str(t), "-o", tmp, os.path.join(SAIDA_ICONES, id_app + ".svg")], check=True)
                img = Image.open(tmp).convert("RGBA")
                folha.paste(img, (x, y + (128 - t) // 2), img)
                x += t + 14
    folha.save(os.path.join(pasta, "icones_folha.png"))
    os.remove(tmp)


def main():
    gerar_icones()
    if "--folha" in sys.argv[1:]:
        folha_de_contato()


if __name__ == "__main__":
    main()
