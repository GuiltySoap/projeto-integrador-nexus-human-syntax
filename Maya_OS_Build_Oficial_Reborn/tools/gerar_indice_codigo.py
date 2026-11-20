#!/usr/bin/env python3
"""Gera o índice de código (tabelas) de docs/06_codigo.md a partir dos próprios scripts.

Uso (a partir da raiz do projeto, onde fica o project.godot):
    python3 -I tools/gerar_indice_codigo.py

O script só LÊ os .gd/.tscn/.json e reescreve o trecho entre os marcadores
<!-- INICIO_INDICE --> e <!-- FIM_INDICE --> em docs/06_codigo.md. O resto do arquivo é texto manual.
Apenas biblioteca padrão; não executa nenhum código do projeto.
"""
import json
import os
import re
import sys

RAIZ = os.getcwd()
if not os.path.exists(os.path.join(RAIZ, "project.godot")):
    sys.exit("Execute a partir da raiz do projeto (onde está o project.godot).")

DOC = os.path.join(RAIZ, "docs", "06_codigo.md")
INI = "<!-- INICIO_INDICE -->"
FIM = "<!-- FIM_INDICE -->"
IGNORAR = {".godot", "tools", "backend", "docs", "tests", "addons"}

# Controles/nós da engine criados em código (ignora classes do próprio projeto).
NOS_ENGINE = {
    "Timer", "AudioStreamPlayer", "Button", "Label", "RichTextLabel", "LineEdit", "TextEdit", "HSlider", "CheckBox",
    "OptionButton", "ProgressBar", "ScrollContainer", "VBoxContainer", "HBoxContainer", "GridContainer", "VFlowContainer",
    "HFlowContainer", "PanelContainer", "MarginContainer", "Panel", "ColorRect", "TextureRect", "ItemList", "SpinBox",
    "ButtonGroup", "Tween", "Control", "CenterContainer", "HSeparator", "VSeparator", "Line2D", "AudioStreamWAV",
}


def listar_scripts():
    achados = []
    for dp, dns, fns in os.walk(RAIZ):
        dns[:] = sorted(d for d in dns if d not in IGNORAR)
        for f in sorted(fns):
            if f.endswith(".gd"):
                achados.append(os.path.relpath(os.path.join(dp, f), RAIZ).replace(os.sep, "/"))
    return sorted(achados)


def analisar(caminho):
    with open(os.path.join(RAIZ, caminho), encoding="utf-8") as f:
        linhas = f.read().split("\n")
    classe = ""
    base = ""
    sinais = []
    for l in linhas:
        m = re.match(r"class_name\s+(\w+)", l)
        if m and not classe:
            classe = m.group(1)
        m = re.match(r"extends\s+(\w+)", l)
        if m and not base:
            base = m.group(1)
        m = re.match(r"signal\s+(\w+)\s*(\([^)]*\))?", l)
        if m:
            sinais.append(m.group(1) + (m.group(2) or "()"))
    doc = []
    i = 0
    while i < len(linhas) and not linhas[i].startswith("extends"):
        i += 1
    i += 1
    while i < len(linhas) and linhas[i].startswith("##"):
        doc.append(linhas[i][2:].strip())
        i += 1
    texto = "\n".join(linhas)
    nos = sorted({n for n in re.findall(r"\b([A-Z]\w+)\.new\(", texto) if n in NOS_ENGINE})
    uikit = len(re.findall(r"\bUiKit\.\w+\(", texto))
    return {"caminho": caminho, "classe": classe, "base": base, "doc": " ".join(doc), "sinais": sinais, "nos": nos, "uikit": uikit, "linhas": len(linhas)}


def cena_do_script(caminho):
    """Cenas .tscn que usam este script."""
    usadas = []
    for dp, dns, fns in os.walk(RAIZ):
        dns[:] = [d for d in dns if d not in IGNORAR]
        for f in fns:
            if f.endswith(".tscn"):
                p = os.path.join(dp, f)
                with open(p, encoding="utf-8") as fh:
                    if 'path="res://%s"' % caminho in fh.read():
                        usadas.append(os.path.relpath(p, RAIZ).replace(os.sep, "/"))
    return usadas


def curto(texto, limite=170):
    texto = texto.replace("|", "\\|")
    return texto if len(texto) <= limite else texto[: limite - 1].rstrip() + "…"


def secao(titulo, itens):
    if not itens:
        return []
    saida = ["### " + titulo, "", "| Arquivo | Classe | Base | Responsabilidade | Cena / nós criados em código (conteúdo dinâmico) | Sinais |", "|---|---|---|---|---|---|"]
    for a in itens:
        nos = ", ".join(a["nos"]) if a["nos"] else "—"
        cenas = cena_do_script(a["caminho"])
        if cenas:
            nos = "cena: `%s`; %s" % (cenas[0].split("/")[-1], nos if a["nos"] else "nada criado em código")
        sinais = ", ".join("`%s`" % s for s in a["sinais"]) if a["sinais"] else "—"
        saida.append("| `%s` | %s | %s | %s | %s | %s |" % (a["caminho"], "`%s`" % a["classe"] if a["classe"] else "(autoload)", a["base"], curto(a["doc"]) or "—", curto(nos, 140), curto(sinais, 260)))
    saida.append("")
    return saida


def tabela_dados():
    saida = ["### Dados (JSON em `res://core/data/`)", "", "| Arquivo | Conteúdo |", "|---|---|"]
    base = os.path.join(RAIZ, "core", "data")
    descricoes = {
        "catalogo_apps.json": "Catálogo dos aplicativos (id, nome, ícone, cena, tamanhos, dia de desbloqueio, condição). Lido por menu, barra de tarefas, atalhos e gerenciador de janelas.",
        "vfs_inicial.json": "Árvore inicial do sistema de arquivos virtual (pastas, arquivos, metadados, ocultos, criptografados, puzzles).",
        "narrativa/dias.json": "Dias 1–5: título, paleta, estado da IA, corrupção/segurança, apps liberados, objetivos, eventos e segredos.",
        "narrativa/conversas.json": "Contatos, mensagens (com dia, tipo e escolhas), respostas genéricas e respostas automáticas do Dia 4.",
        "narrativa/emails.json": "E-mails por dia.",
        "narrativa/calendario.json": "Compromissos da agenda e como a Maya os altera/oculta/cancela.",
        "narrativa/paginas_web.json": "Páginas `humax://` do navegador simulado por dia.",
        "narrativa/processos.json": "Processos maliciosos (duração, penalidades), processos do sistema simulados e multiplicadores de dificuldade.",
        "narrativa/finais.json": "Os 4 finais e as 4 evidências usadas para a negociação.",
    }
    for dp, _, fns in os.walk(base):
        for f in sorted(fns):
            if f.endswith(".json"):
                rel = os.path.relpath(os.path.join(dp, f), base).replace(os.sep, "/")
                try:
                    with open(os.path.join(dp, f), encoding="utf-8") as fh:
                        json.load(fh)
                    ok = "válido"
                except Exception as e:  # noqa: BLE001 - só relatório
                    ok = "INVÁLIDO: %s" % e
                saida.append("| `core/data/%s` | %s (%s) |" % (rel, descricoes.get(rel, "—"), ok))
    saida.append("")
    return saida


def autoloads_do_projeto():
    """{Nome: caminho_relativo} lido da seção [autoload] do project.godot."""
    saida = {}
    dentro = False
    with open(os.path.join(RAIZ, "project.godot"), encoding="utf-8") as f:
        for linha in f:
            linha = linha.strip()
            if linha.startswith("["):
                dentro = linha == "[autoload]"
                continue
            m = re.match(r'(\w+)="\*?res://([^"]+)"', linha)
            if dentro and m:
                saida[m.group(1)] = m.group(2)
    return saida


def mapa_sinais(scripts):
    """Quem escuta cada sinal dos autoloads (conexões feitas em código: .connect, ligar e conectar)."""
    autos = autoloads_do_projeto()
    por_caminho = {a["caminho"]: a for a in scripts}
    escutas = {}
    padroes = [
        r"\b({n})\.(\w+)\.connect\(",
        r"\.ligar\(\s*({n})\.(\w+)\b",
        r"\bconectar\(\s*({n})\.(\w+)\b",
    ]
    nomes = "|".join(sorted(autos, key=len, reverse=True))
    for a in scripts:
        with open(os.path.join(RAIZ, a["caminho"]), encoding="utf-8") as f:
            texto = "\n".join(l for l in f.read().split("\n") if not l.strip().startswith("#"))
        for pad in padroes:
            for m in re.finditer(pad.format(n=nomes), texto):
                chave = (m.group(1), m.group(2))
                escutas.setdefault(chave, set()).add(os.path.basename(a["caminho"])[:-3])
    saida = ["### Quem escuta cada sinal dos autoloads", "", "| Sinal | Escutado em |", "|---|---|"]
    for nome in autos:
        a = por_caminho.get(autos[nome])
        if not a:
            continue
        for sinal in a["sinais"]:
            nome_sinal = sinal.split("(")[0]
            ouvintes = sorted(escutas.get((nome, nome_sinal), []))
            saida.append("| `%s.%s` | %s |" % (nome, sinal, ", ".join("`%s`" % o for o in ouvintes) if ouvintes else "— (emitido para quem quiser escutar)"))
    saida.append("")
    return saida


def main():
    scripts = [analisar(c) for c in listar_scripts()]
    grupos = [
        ("Autoloads (`core/autoload/`)", lambda a: a["caminho"].startswith("core/autoload/")),
        ("Utilitários (`core/utilities/`)", lambda a: a["caminho"].startswith("core/utilities/")),
        ("Componentes compartilhados (`shared/ui/`)", lambda a: a["caminho"].startswith("shared/ui/")),
        ("Shell: boot, área de trabalho, barra, menu, toasts, widgets, efeitos (`features/shell/`)", lambda a: a["caminho"].startswith("features/shell/")),
        ("Aplicativos (`features/apps/`)", lambda a: a["caminho"].startswith("features/apps/")),
        ("Minigame de lógica (`features/minigames/`)", lambda a: a["caminho"].startswith("features/minigames/")),
        ("Puzzles (`features/puzzles/`)", lambda a: a["caminho"].startswith("features/puzzles/")),
        ("Narrativa: finais (`features/narrative/`)", lambda a: a["caminho"].startswith("features/narrative/")),
    ]
    saida = [
        "Total: **%d scripts do jogo**, %d linhas de GDScript (sem `tests/`, que traz o teste de fumaça). Tabelas geradas por `tools/gerar_indice_codigo.py`." % (len(scripts), sum(a["linhas"] for a in scripts)),
        "",
    ]
    usados = set()
    for titulo, filtro in grupos:
        itens = [a for a in scripts if filtro(a) and a["caminho"] not in usados]
        usados.update(a["caminho"] for a in itens)
        saida += secao(titulo, itens)
    resto = [a for a in scripts if a["caminho"] not in usados]
    saida += secao("Outros", resto)
    saida += mapa_sinais(scripts)
    saida += tabela_dados()
    bloco = INI + "\n" + "\n".join(saida).rstrip() + "\n" + FIM
    with open(DOC, encoding="utf-8") as f:
        atual = f.read()
    if INI not in atual or FIM not in atual:
        sys.exit("Marcadores não encontrados em docs/06_codigo.md.")
    antes = atual.split(INI)[0]
    depois = atual.split(FIM, 1)[1]
    with open(DOC, "w", encoding="utf-8", newline="\n") as f:
        f.write(antes + bloco + depois)
    print("índice atualizado: %d scripts" % len(scripts))


main()
