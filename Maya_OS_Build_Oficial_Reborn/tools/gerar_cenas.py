#!/usr/bin/env python3
"""DESATIVADO. Este gerador criava cenas mínimas (raiz + script) porque a interface era montada em código.
Hoje as cenas do projeto são editadas no editor do Godot e têm hierarquia própria: rodar este script sobrescreveria
essas cenas. Para recriar uma cena mínima de propósito, rode com --forcar-stubs e confira o que será sobrescrito."""
import sys
if "--forcar-stubs" not in sys.argv:
    sys.exit("tools/gerar_cenas.py está desativado: as cenas agora são feitas no editor (veja docs/04_hierarquia_das_cenas.md).")


import json
import os
import re
import sys

RAIZ = os.getcwd()
if not os.path.exists(os.path.join(RAIZ, "project.godot")):
    sys.exit("Execute a partir da raiz do projeto (onde está o project.godot).")

CAMADAS_DESKTOP = [
    "CamadaFundo", "CamadaIcones", "CamadaWidgets", "CamadaJanelas", "CamadaShell",
    "CamadaToasts", "CamadaEfeitos", "CamadaModais", "CamadaDebug",
]
# (cena, script, tipo da raiz, tela cheia?, camadas filhas)
CENAS_FIXAS = [
    ("res://features/shell/tela_boot/scenes/tela_boot.tscn", "res://features/shell/tela_boot/scripts/tela_boot.gd", "Control", True, []),
    ("res://features/shell/area_de_trabalho/scenes/area_de_trabalho.tscn", "res://features/shell/area_de_trabalho/scripts/area_de_trabalho.gd", "Control", True, CAMADAS_DESKTOP),
    ("res://features/narrative/finais/scenes/tela_final.tscn", "res://features/narrative/finais/scripts/tela_final.gd", "Control", True, []),
    ("res://shared/ui/janela_base/scenes/janela_base.tscn", "res://shared/ui/janela_base/scripts/janela_base.gd", "Control", False, []),
]


def caminho_real(res):
    return os.path.join(RAIZ, res[len("res://"):])


def ler(p):
    with open(p, encoding="utf-8") as f:
        return f.read()


def uid_da_cena(res):
    p = caminho_real(res)
    if not os.path.exists(p):
        return None
    m = re.match(r'\[gd_scene[^\]]*uid="([^"]+)"', ler(p))
    return m.group(1) if m else None


def uid_do_script(res):
    p = caminho_real(res) + ".uid"
    if not os.path.exists(p):
        return None
    u = ler(p).strip()
    return u if u.startswith("uid://") else None


def classe_do_script(res):
    texto = ler(caminho_real(res))
    nome = re.search(r"^class_name\s+(\w+)", texto, re.M)
    base = re.search(r"^extends\s+(\w+)", texto, re.M)
    return (nome.group(1) if nome else None), (base.group(1) if base else "Control")


def id_curto(res):
    base = os.path.basename(res).replace(".gd", "")
    return "1_" + re.sub(r"[^a-z0-9]", "", base.lower())[:8]


def gerar(cena, script, raiz_tipo, tela_cheia, camadas):
    if not os.path.exists(caminho_real(script)):
        print("PULADO (script inexistente): %s" % script)
        return False
    nome_classe, base = classe_do_script(script)
    # raiz: Control (todos os scripts do projeto estendem Control ou AppBase, que estende Control)
    tipo = raiz_tipo if base in ("Control", "AppBase") else base
    nome_no = nome_classe or os.path.basename(cena).replace(".tscn", "").title().replace("_", "")
    uid_c = uid_da_cena(cena)
    uid_s = uid_do_script(script)
    cabecalho = '[gd_scene format=3'
    if uid_c:
        cabecalho += ' uid="%s"' % uid_c
    cabecalho += "]\n\n"
    ext = '[ext_resource type="Script"'
    if uid_s:
        ext += ' uid="%s"' % uid_s
    ext += ' path="%s" id="%s"]\n\n' % (script, id_curto(script))
    linhas = ['[node name="%s" type="%s"]' % (nome_no, tipo)]
    linhas.append("layout_mode = 3")
    if tela_cheia:
        linhas += ["anchors_preset = 15", "anchor_right = 1.0", "anchor_bottom = 1.0", "grow_horizontal = 2", "grow_vertical = 2"]
    else:
        linhas.append("anchors_preset = 0")
    linhas.append('script = ExtResource("%s")' % id_curto(script))
    corpo = "\n".join(linhas) + "\n"
    for camada in camadas:
        corpo += '\n[node name="%s" type="Control" parent="."]\n' % camada
        corpo += "layout_mode = 1\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2\nmouse_filter = 2\n"
    destino = caminho_real(cena)
    os.makedirs(os.path.dirname(destino), exist_ok=True)
    with open(destino, "w", encoding="utf-8", newline="\n") as f:
        f.write(cabecalho + ext + corpo)
    print("gerada: %s%s" % (cena, "" if uid_c else "  (sem uid: o Godot cria na primeira abertura)"))
    return True


def main():
    total = 0
    with open(os.path.join(RAIZ, "core", "data", "catalogo_apps.json"), encoding="utf-8") as f:
        dados = json.load(f)
    apps = dados if isinstance(dados, list) else dados.get("apps", [])
    for app in apps:
        cena = str(app.get("cena", ""))
        if not cena.startswith("res://") or "/scenes/" not in cena:
            continue
        script = cena.replace("/scenes/", "/scripts/").replace(".tscn", ".gd")
        if gerar(cena, script, "Control", True, []):
            total += 1
    for item in CENAS_FIXAS:
        if gerar(*item):
            total += 1
    print("total: %d cena(s)" % total)


main()
