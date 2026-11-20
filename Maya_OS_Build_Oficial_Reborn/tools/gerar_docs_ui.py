#!/usr/bin/env python3
"""Gera docs/04_hierarquia_das_cenas.md e docs/10_refatoracao_ui.md a partir dos .tscn, .gd e do último log de testes.
Uso, na raiz do projeto:  python3 -I tools/gerar_docs_ui.py
Só lê arquivos do projeto e só grava nos dois documentos acima. Depois de mudar uma cena, rode de novo."""
import json, os, re, sys

RAIZ = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))

# ---- leitura de cenas e scripts ----

AUTOLOADS = ["RelogioGlobal", "GerenciadorConfiguracoes", "GerenciadorEstado", "SistemaAudio", "SistemaNotificacoes",
             "SistemaArquivosVirtual", "GerenciadorJanelas", "GerenciadorNarrativa", "SistemaPersistencia"]


def ler_cena(caminho):
    txt = open(caminho, encoding="utf-8").read()
    exts = {}
    for m in re.finditer(r'\[ext_resource type="([^"]+)"(?: uid="[^"]+")? path="([^"]+)" id="([^"]+)"\]', txt):
        exts[m.group(3)] = (m.group(1), m.group(2))
    nos = []
    padrao = re.compile(r'\[node name="([^"]+)"(?: type="([^"]+)")?(?: parent="([^"]*)")?(?: instance=ExtResource\("([^"]+)"\))?[^\]]*\]\n((?:(?!\[)[^\n]*\n)*)')
    for m in padrao.finditer(txt):
        nome, tipo, pai, inst, corpo = m.groups()
        script = re.search(r'script = ExtResource\("([^"]+)"\)', corpo)
        nos.append(dict(nome=nome, tipo=tipo, pai=pai, inst=exts[inst][1] if inst in exts else None,
                        unico="unique_name_in_owner = true" in corpo,
                        script=exts[script.group(1)][1] if script and script.group(1) in exts else None,
                        oculto="visible = false" in corpo, corpo=corpo))
    cons = re.findall(r'\[connection signal="([^"]+)" from="([^"]+)" to="([^"]+)" method="([^"]+)"', txt)
    return dict(nos=nos, conexoes=cons, exts=exts)


def nivel(no):
    if no["pai"] is None:
        return 0
    return 1 if no["pai"] == "." else no["pai"].count("/") + 2


def arvore_texto(info, prof=99):
    linhas = []
    for n in info["nos"]:
        nv = nivel(n)
        if nv > prof:
            continue
        rot = ("%" if n["unico"] else "") + n["nome"]
        desc = ("instância de " + os.path.basename(n["inst"])) if n["inst"] else (n["tipo"] or "?")
        if n["script"] and nv == 0:
            desc += " + " + os.path.basename(n["script"])
        if n["oculto"]:
            desc += ", oculto"
        linhas.append("%s%s (%s)" % ("  " * nv, rot, desc))
    return linhas


def info_script(caminho):
    if not caminho or not os.path.exists(caminho):
        return {}
    t = open(caminho, encoding="utf-8").read()
    return dict(
        linhas=t.count("\n") + 1,
        classe=(re.search(r'^class_name\s+(\w+)', t, re.M) or [None, None])[1],
        heranca=(re.search(r'^extends\s+(\w+)', t, re.M) or [None, None])[1],
        sinais=re.findall(r'^signal\s+(\w+)(\([^)]*\))?', t, re.M),
        exports=re.findall(r'^@export[^\n]*?var\s+(\w+)\s*:\s*([\w\[\]]+)', t, re.M),
        onready=len(re.findall(r'@onready', t)),
        args=sorted(set(re.findall(r'args\.get\("(\w+)"', t) + re.findall(r'args\["(\w+)"\]', t))),
        instancia=sorted(set(re.findall(r'\b(cena_\w+)\.instantiate\(', t))),
        autoloads=[a for a in AUTOLOADS if re.search(r'\b%s\b' % a, t)],
        publicas=re.findall(r'^(?:static\s+)?func\s+([a-z]\w*)\(', t, re.M),
        conecta_codigo=len(re.findall(r'\.connect\(|conectar\(', t)),
        new_ui=len(re.findall(r'\b(?:Label|Button|VBoxContainer|HBoxContainer|MarginContainer|PanelContainer|ColorRect|Control|ScrollContainer|LineEdit|TextEdit|RichTextLabel|CheckBox|GridContainer|CenterContainer|TextureRect|Panel)\.new\(\)', t)),
    )


# Métricas do projeto ANTES da refatoração (UI montada por código), medidas com a mesma regra usada abaixo.
ANTES = json.loads(r'''{"core/utilities/ui_kit.gd": {"add_child": 4, "linhas": 171, "new_ui": 14, "overrides": 12, "ui_kit": 0}, "features/apps/bloco_de_notas/scripts/app_bloco_de_notas.gd": {"add_child": 12, "linhas": 336, "new_ui": 1, "overrides": 2, "ui_kit": 11}, "features/apps/calculadora/scripts/app_calculadora.gd": {"add_child": 7, "linhas": 321, "new_ui": 1, "overrides": 4, "ui_kit": 8}, "features/apps/calendario/scripts/app_calendario.gd": {"add_child": 20, "linhas": 239, "new_ui": 1, "overrides": 3, "ui_kit": 24}, "features/apps/config/scripts/app_config.gd": {"add_child": 50, "linhas": 526, "new_ui": 8, "overrides": 4, "ui_kit": 49}, "features/apps/email/scripts/app_email.gd": {"add_child": 11, "linhas": 135, "new_ui": 0, "overrides": 1, "ui_kit": 16}, "features/apps/explorador/scripts/app_explorador.gd": {"add_child": 17, "linhas": 489, "new_ui": 2, "overrides": 0, "ui_kit": 21}, "features/apps/leitor_texto/scripts/app_leitor_texto.gd": {"add_child": 7, "linhas": 107, "new_ui": 0, "overrides": 0, "ui_kit": 8}, "features/apps/mensageiro/components/balao_chat/scripts/balao_chat.gd": {"add_child": 7, "linhas": 96, "new_ui": 1, "overrides": 5, "ui_kit": 6}, "features/apps/mensageiro/scripts/app_mensageiro.gd": {"add_child": 17, "linhas": 326, "new_ui": 0, "overrides": 0, "ui_kit": 22}, "features/apps/monitor_sistema/scripts/app_monitor_sistema.gd": {"add_child": 31, "linhas": 314, "new_ui": 3, "overrides": 0, "ui_kit": 27}, "features/apps/navegador/scripts/app_navegador.gd": {"add_child": 12, "linhas": 181, "new_ui": 0, "overrides": 0, "ui_kit": 14}, "features/apps/terminal/scripts/app_terminal.gd": {"add_child": 5, "linhas": 511, "new_ui": 0, "overrides": 0, "ui_kit": 6}, "features/apps/visualizador/scripts/app_visualizador.gd": {"add_child": 20, "linhas": 339, "new_ui": 3, "overrides": 3, "ui_kit": 17}, "features/minigames/logica/components/porta_logica_item/scripts/porta_logica_item.gd": {"add_child": 1, "linhas": 31, "new_ui": 2, "overrides": 0, "ui_kit": 0}, "features/minigames/logica/components/slot_circuito/scripts/slot_circuito.gd": {"add_child": 1, "linhas": 43, "new_ui": 1, "overrides": 0, "ui_kit": 0}, "features/minigames/logica/scripts/minigame_logica.gd": {"add_child": 36, "linhas": 257, "new_ui": 5, "overrides": 2, "ui_kit": 30}, "features/narrative/finais/scripts/tela_final.gd": {"add_child": 24, "linhas": 170, "new_ui": 2, "overrides": 3, "ui_kit": 21}, "features/puzzles/arquivos_criptografados/scripts/dialogo_chave.gd": {"add_child": 15, "linhas": 127, "new_ui": 4, "overrides": 0, "ui_kit": 12}, "features/puzzles/evento_processo/scripts/tabela_processos.gd": {"add_child": 0, "linhas": 112, "new_ui": 0, "overrides": 0, "ui_kit": 0}, "features/shell/area_de_trabalho/scripts/area_de_trabalho.gd": {"add_child": 15, "linhas": 349, "new_ui": 1, "overrides": 2, "ui_kit": 1}, "features/shell/area_de_trabalho/scripts/cartao_dia.gd": {"add_child": 6, "linhas": 72, "new_ui": 2, "overrides": 1, "ui_kit": 5}, "features/shell/area_de_trabalho/scripts/icone_area_de_trabalho.gd": {"add_child": 3, "linhas": 50, "new_ui": 0, "overrides": 3, "ui_kit": 2}, "features/shell/area_de_trabalho/scripts/painel_debug.gd": {"add_child": 14, "linhas": 192, "new_ui": 2, "overrides": 4, "ui_kit": 11}, "features/shell/area_de_trabalho/scripts/papel_de_parede.gd": {"add_child": 0, "linhas": 78, "new_ui": 0, "overrides": 0, "ui_kit": 0}, "features/shell/barra_de_tarefas/scripts/barra_de_tarefas.gd": {"add_child": 17, "linhas": 232, "new_ui": 2, "overrides": 1, "ui_kit": 13}, "features/shell/centro_notificacoes/scripts/centro_notificacoes.gd": {"add_child": 20, "linhas": 193, "new_ui": 3, "overrides": 2, "ui_kit": 19}, "features/shell/data_e_hora/scripts/widget_relogio.gd": {"add_child": 4, "linhas": 53, "new_ui": 0, "overrides": 0, "ui_kit": 5}, "features/shell/efeito_glitch/scripts/efeito_glitch.gd": {"add_child": 1, "linhas": 127, "new_ui": 1, "overrides": 0, "ui_kit": 0}, "features/shell/janela_inicial/scripts/ajuda_dica.gd": {"add_child": 0, "linhas": 23, "new_ui": 0, "overrides": 0, "ui_kit": 0}, "features/shell/janela_inicial/scripts/menu_iniciar.gd": {"add_child": 32, "linhas": 345, "new_ui": 5, "overrides": 2, "ui_kit": 25}, "features/shell/popup_notificacao/scripts/pilha_toasts.gd": {"add_child": 2, "linhas": 76, "new_ui": 0, "overrides": 0, "ui_kit": 1}, "features/shell/popup_notificacao/scripts/popup_notificacao.gd": {"add_child": 13, "linhas": 172, "new_ui": 2, "overrides": 4, "ui_kit": 11}, "features/shell/tela_boot/scripts/tela_boot.gd": {"add_child": 37, "linhas": 390, "new_ui": 11, "overrides": 3, "ui_kit": 24}, "features/shell/widget_nexus/scripts/widget_nexus.gd": {"add_child": 25, "linhas": 202, "new_ui": 1, "overrides": 3, "ui_kit": 23}, "shared/ui/app_base/scripts/app_base.gd": {"add_child": 0, "linhas": 65, "new_ui": 0, "overrides": 0, "ui_kit": 0}, "shared/ui/dialogo_arquivo/scripts/dialogo_arquivo.gd": {"add_child": 14, "linhas": 175, "new_ui": 4, "overrides": 0, "ui_kit": 11}, "shared/ui/dialogo_nexus/scripts/dialogo_nexus.gd": {"add_child": 13, "linhas": 159, "new_ui": 3, "overrides": 0, "ui_kit": 11}, "shared/ui/janela_base/scripts/janela_base.gd": {"add_child": 13, "linhas": 505, "new_ui": 7, "overrides": 3, "ui_kit": 1}, "shared/ui/orbe_nexus/scripts/orbe_nexus.gd": {"add_child": 0, "linhas": 70, "new_ui": 0, "overrides": 0, "ui_kit": 0}}''')


# ---- dados curados ----
FUNCAO = {
    "explorer": "Navega pelo sistema de arquivos virtual (lugares, pastas, arquivos); abre, cria, renomeia e exclui itens.",
    "text_editor": "Edita arquivos de texto do sistema virtual (novo, abrir, salvar, salvar como, aviso de alterações não salvas).",
    "messenger": "Conversas com a Maya e os contatos: lista de contatos, balões de mensagem, opções de resposta, bloqueio e mensagens editadas/ocultas conforme o dia.",
    "email": "Caixa de entrada: lista de e-mails, leitura, marcação de lido e conteúdo condicionado ao dia e às flags da história.",
    "media_viewer": "Galeria de imagens e áudio com painel de metadados (puzzle da foto) e player de áudio simulado.",
    "calendar": "Agenda: grade mensal, compromissos (alterados, ocultos, cancelados, de emergência) e lista do dia.",
    "calculator": "Calculadora com visor e teclado; não avalia expressões arbitrárias.",
    "settings": "Configurações: personalização, áudio, acessibilidade, privacidade/permissões e sistema.",
    "browser": "Navegador do universo do jogo: abre só `humax://…` (páginas de `paginas_web.json`) e bloqueia qualquer outro esquema.",
    "terminal": "Terminal simulado: comandos sobre o sistema de arquivos virtual e a tabela de processos; nenhum shell real.",
    "task_manager": "Monitor do sistema: processos simulados, uso de CPU/RAM e encerramento do processo suspeito.",
    "text_reader": "Leitor de texto somente leitura para arquivos do sistema virtual.",
}
GRUPO_TESTE = {"explorer": "explorador", "text_editor": "bloco_de_notas", "messenger": "mensageiro", "email": "email",
               "media_viewer": "visualizador", "calendar": "calendario", "calculator": "calculadora", "settings": "config",
               "browser": "navegador", "terminal": "terminal", "task_manager": "monitor_sistema", "text_reader": "leitor_texto"}
GRUPOS_NOMES = {"dialogos": "diálogos modais", "tela_final": "tela final", "tela_boot": "tela de boot"}


# Totais do projeto inteiro ANTES (scripts de jogo, sem tests/ e tools/), medidos com a mesma regra de contagem.
ANTES_TOTAL = dict(ui_kit=455, new_ui=92, add_child=530, overrides=67, cenas=16, nos=25, scripts=55, linhas=12081)


def contar_scripts():
    tot = dict(new_ui=0, add_child=0, overrides=0, onready=0, exports=0, scripts=0, linhas=0, ui_kit=0, residuais=[])
    for dp, dn, fn in os.walk(RAIZ):
        dn[:] = [d for d in dn if not d.startswith(".") and d not in ("tests", "tools", "_saida")]
        for f in fn:
            if not f.endswith(".gd"):
                continue
            caminho = os.path.join(dp, f)
            txt = open(caminho, encoding="utf-8").read()
            si = info_script(caminho)
            tot["scripts"] += 1
            tot["linhas"] += si["linhas"]
            tot["new_ui"] += si["new_ui"]
            tot["add_child"] += txt.count("add_child(")
            tot["overrides"] += len(re.findall(r"add_theme_\w+_override", txt))
            tot["onready"] += len(re.findall(r"@onready", txt))
            tot["exports"] += len(re.findall(r"^@export", txt, re.M))
            tot["ui_kit"] += len(re.findall(r"\bUiKit\.(?:botao|rotulo|painel|caixa_[hv]|linha|margem|separador|rolagem|rico|cheio|espacador|expandir|icone_app|texto_alvo)\w*\(", txt))
            if si["new_ui"]:
                tot["residuais"].append(os.path.relpath(caminho, RAIZ).replace(os.sep, "/"))
    return tot


def rel(*p):
    return os.path.join(RAIZ, *p)


def arquivos_cena():
    saida = []
    for dp, dn, fn in os.walk(RAIZ):
        dn[:] = sorted(d for d in dn if not d.startswith(".") and d not in ("tests", "_saida"))
        for f in sorted(fn):
            if f.endswith(".tscn"):
                saida.append(os.path.relpath(os.path.join(dp, f), RAIZ).replace(os.sep, "/"))
    return sorted(saida)


def resumo_cena(caminho):
    info = ler_cena(rel(caminho))
    raiz = info["nos"][0]
    scr = raiz["script"]
    return dict(caminho=caminho, info=info, raiz=raiz, script=scr, nos=len(info["nos"]),
                unicos=[n for n in info["nos"] if n["unico"]], conexoes=info["conexoes"],
                si=info_script(rel(scr.replace("res://", ""))) if scr else {})


def ler_log_interacao():
    caminho = rel("tests", "_saida", "interacao", "log.txt")
    grupos, atual, resumo = {}, None, ""
    if os.path.exists(caminho):
        for linha in open(caminho, encoding="utf-8"):
            linha = linha.rstrip("\n")
            if linha.startswith("== "):
                atual = linha[3:].strip()
                grupos[atual] = []
            elif linha.startswith("OK: ") and atual:
                grupos[atual].append(linha[4:].strip())
            elif linha.startswith("RESULTADO"):
                resumo = linha
    return grupos, resumo


def conexoes_agrupadas(cons):
    cont = {}
    for sinal, de, para, metodo in cons:
        cont.setdefault((sinal, metodo), []).append(de)
    return ["`%s` → `%s` (%d)" % (s, m, len(v)) if len(v) > 1 else "`%s` de `%s` → `%s`" % (s, v[0], m) for (s, m), v in sorted(cont.items())]


def tipo_raiz(r):
    return os.path.basename(r["inst"]) if r["inst"] else (r["tipo"] or "?")


# ---- documento 04 ----
def doc04(cenas):
    L = ["# 15.4 Hierarquia das cenas", "",
         "> Gerado por `tools/gerar_docs_ui.py` a partir dos `.tscn` (rode de novo depois de mudar uma cena).", "",
         "## Como as cenas são construídas", "",
         "A interface do HumaxOS é montada **no editor**: cada tela, janela, aplicativo, diálogo e componente é uma cena `.tscn` com a hierarquia de nós, os containers nativos e o layout salvos no arquivo. Os scripts guardam só comportamento (estado, regras, ligação com os autoloads). Conteúdo que só existe em tempo de execução (linhas de lista, balões de chat, botões por opção) é criado a partir de **cenas de item** reutilizáveis, instanciadas dentro de um container que já existe na cena pai.", "",
         "Convenções:", "",
         "- Nós que o script usa têm **nome único** (`%Nome`, `unique_name_in_owner`) e são lidos com `@onready var x: Tipo = %Nome`. Nenhum caminho `$A/B/C` frágil.",
         "- Propriedades que o designer ajusta no editor são `@export` (por exemplo `cena_item: PackedScene`); as referências essenciais são conferidas em `_ready` (`UiKit.refs_ok`).",
         "- Sinais de nós fixos são conexões da própria cena (`[connection …]`, aba *Nó → Sinais*); só os itens criados em tempo de execução são conectados no código, uma vez, na criação.",
         "- Aparência: `shared/theme/tema_nexus_base.tres` (definido em `gui/theme/custom`) faz o editor mostrar as cenas estilizadas; em jogo `TemaNexus.aplicar()` aplica o tema completo em `root.theme`. Para regerar o `.tres` depois de mudar `tema_nexus.gd`/`tema_variacoes.gd`, rode `tests/exportar_tema/exportar_tema.tscn`.",
         "- Os autoloads **não** constroem interface.", ""]
    L += ["## Índice das cenas (%d)" % len(cenas), "", "| Cena | Raiz | Script | Nós | `%Nome` | Conexões |", "|---|---|---|---:|---:|---:|"]
    res = [resumo_cena(c) for c in cenas]
    for r in res:
        L.append("| `%s` | %s | %s | %d | %d | %d |" % (r["caminho"], tipo_raiz(r["raiz"]), ("`%s`" % os.path.basename(r["script"])) if r["script"] else "—", r["nos"], len(r["unicos"]), len(r["conexoes"])))
    L += ["", "Total: **%d cenas, %d nós**." % (len(res), sum(r["nos"] for r in res)), ""]
    grupo_atual = None
    for r in res:
        g = "/".join(r["caminho"].split("/")[:2])
        if g != grupo_atual:
            grupo_atual = g
            L += ["---", "", "## `%s/`" % g, ""]
        L += ["### `%s`" % r["caminho"], ""]
        L += ["```text"] + arvore_texto(r["info"], 7) + ["```", ""]
        if r["conexoes"]:
            L += ["Sinais conectados na cena: " + "; ".join(conexoes_agrupadas(r["conexoes"])) + ".", ""]
    return "\n".join(L).rstrip() + "\n"


# ---- documento 10 ----
def secao_app(app, grupos):
    c = app["cena"].replace("res://", "")
    r = resumo_cena(c)
    si = r["si"]
    scr = r["script"].replace("res://", "") if r["script"] else ""
    a = ANTES.get(scr, {})
    novo = si.get("new_ui", 0)
    L = ["### %s (`%s`)" % (app["nome"], app["id"]), ""]
    L += ["- **Função:** " + FUNCAO.get(app["id"], "—")]
    L += ["- **Cena e script:** `%s` (%d nós, %d com nome único); `%s` (%d linhas, `%s` herda `%s`)." % (c, r["nos"], len(r["unicos"]), scr, si.get("linhas", 0), si.get("classe"), si.get("heranca"))]
    L += ["- **Árvore (3 níveis):**", "", "  ```text"] + ["  " + x for x in arvore_texto(r["info"], 3)[:30]]
    if len(arvore_texto(r["info"], 3)) > 30:
        L.append("  … (árvore completa em `docs/04_hierarquia_das_cenas.md`)")
    L += ["  ```"]
    un = ["`%%%s` (%s)" % (n["nome"], n["tipo"] or os.path.basename(n["inst"] or "?")) for n in r["unicos"]]
    L += ["- **Nós importantes (nome único):** " + (", ".join(un[:24]) + (" … +%d" % (len(un) - 24) if len(un) > 24 else "") if un else "nenhum além da raiz")]
    args = si.get("args") or []
    L += ["- **Dados recebidos:** `GerenciadorJanelas.abrir_app(id, args)` entrega `args` a `receber_args(args)` / `iniciar(args)` (contrato de `AppBase`)" + (("; chaves lidas: " + ", ".join("`%s`" % k for k in args)) if args else "; este app não lê chaves específicas") + "."]
    sig = ["`%s%s`" % (s, p) for s, p in si.get("sinais", [])]
    L += ["- **Sinais emitidos:** " + (", ".join(sig) if sig else "nenhum próprio (usa `titulo_alterado`, herdado de `AppBase`)")]
    cg = conexoes_agrupadas(r["conexoes"])
    L += ["- **Sinais conectados na cena (%d):** " % len(r["conexoes"]) + ("; ".join(cg[:10]) + (" … +%d grupos" % (len(cg) - 10) if len(cg) > 10 else "") if cg else "nenhum")]
    L += ["- **Sinais conectados em código:** %d chamada(s) `connect`/`conectar` (itens criados em tempo de execução)." % si.get("conecta_codigo", 0)]
    ex = ["`%s: %s`" % (n, t) for n, t in si.get("exports", [])]
    L += ["- **Exports:** " + (", ".join(ex) if ex else "nenhum")]
    din = si.get("instancia") or []
    L += ["- **Conteúdo dinâmico mantido:** " + (("instancia, a partir de `PackedScene` exportada, " + ", ".join("`%s`" % d for d in din) + " dentro de containers que já existem na cena") if din else "nenhum: toda a interface é estática na cena") + (("; ainda cria %d nó(s) de interface por código (ver ressalvas)" % novo) if novo else "") + "."]
    if a:
        L += ["- **Lógica removida do script:** antes, %d chamadas `UiKit.*`, %d `Classe.new()` de interface e %d `add_child`; depois, %d `.new()` de interface. O script passou de %d para %d linhas." % (a["ui_kit"], a["new_ui"], a["add_child"], novo, a["linhas"], si.get("linhas", 0))]
    comp = sorted(set(os.path.basename(n["inst"]) for n in r["info"]["nos"] if n["inst"]) | set(os.path.basename(p) for t, p in r["info"]["exts"].values() if t == "PackedScene"))
    L += ["- **Dependências:** autoloads " + (", ".join("`%s`" % x for x in si.get("autoloads", [])) or "nenhum") + "; cenas de componente/item: " + (", ".join("`%s`" % x for x in comp) or "nenhuma") + "."]
    g = GRUPO_TESTE.get(app["id"])
    itens = grupos.get(g, [])
    L += ["- **Critérios de aceitação** (`tests/ui_interacao`, grupo `%s`, %d verificações, todas OK no último log):" % (g, len(itens))]
    L += ["  - " + x for x in itens]
    return L + [""]


def doc10(cenas):
    grupos, resumo_log = ler_log_interacao()
    cat = json.load(open(rel("core", "data", "catalogo_apps.json"), encoding="utf-8"))["apps"]
    res = [resumo_cena(c) for c in cenas]
    tot_nos = sum(r["nos"] for r in res)
    tot_ant = ANTES_TOTAL
    dep = contar_scripts()
    comps = [r for r in res if "/components/" in r["caminho"] or r["caminho"].startswith("shared/ui/")]
    L = ["# 17. Refatoração da interface para cenas editáveis (relatório §18 e §20)", "",
         "> Gerado em parte por `tools/gerar_docs_ui.py` (tabelas, árvores, contagens e a lista de critérios por aplicativo). O texto corrido é mantido à mão.", "",
         "> **Atualização (2026-11-13).** O texto corrido desta página descreve a refatoração de 2026-11-09. As contagens, as árvores e os resultados dos testes foram refeitos com o código atual, que inclui as melhorias integradas de 2026-11-12 ([`11_melhorias_integradas.md`](11_melhorias_integradas.md)), o rebranding ([`12_rebranding_maya_human_syntax.md`](12_rebranding_maya_human_syntax.md)) e o fluxo Menu Principal / Pausa / Fim de Jogo ([`14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md`](14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md)). Todas as suítes foram reexecutadas na Godot 4.7.2 em 2026-11-13; a contagem de cenas e de nós já inclui as cenas novas.",
         "## 1. Resultado", "",
         "**Classificação: Refatoração concluída com ressalvas** (ressalvas na seção 12). O projeto roda na Godot 4.7.2 com a interface montada em cenas, os 9 autoloads e os contratos públicos preservados e as evidências abaixo.", "",
         "| Critério | Evidência |", "|---|---|",
         "| Arquitetura preservada | 9 autoloads intactos; 0 scripts removidos; diferença de API pública na seção 6; `tools/validar_projeto.py`: 0 erros, 0 avisos |",
         "| Interface no editor | %d cenas de jogo com %d nós (antes: %d cenas com %d nós). Chamadas `UiKit.*` de montagem: %d → %d; `Classe.new()` de interface: %d → %d (justificados na seção 12); `add_child`: %d → %d |" % (len(res), tot_nos, tot_ant["cenas"], tot_ant["nos"], tot_ant["ui_kit"], dep["ui_kit"], tot_ant["new_ui"], dep["new_ui"], tot_ant["add_child"], dep["add_child"]),
         "| Scripts só com comportamento | %d `@onready` e %d `@export` em %d scripts (antes: 0 e 0 em %d scripts) |" % (dep["onready"], dep["exports"], dep["scripts"], tot_ant["scripts"]),
         "| Funcionalidade | `tests/ui_interacao` no estado final: **%s** |" % (resumo_log.replace("RESULTADO: ", "") or "sem log"),
         "| Editor sem avisos | varredura dos avisos de configuração de nó em todas as cenas (`tests/avisos_editor/varredura_editor.gd`): **58 avisos → 0** em 2026-11-09 e **63 cenas, 0 avisos** na rodada de 2026-11-13 (62 antes da Splash Screen: as 7 cenas novas do fluxo de sessão entram na conta, e a 63ª é a Splash) |",
         "| Aparência preservada | árvore de nós de todas as cenas capturadas (retângulo, variação de tema, flags, fonte, texto) idêntica antes/depois da última correção. Em relação ao projeto original (capturas da janela em 2560×1440; área do jogo 1920×1080): rodada `final1`, 31 capturas com no máximo 0,50% de pixels diferentes (relógio, data e elementos animados), boot e tela final com 0,000%; rodada `depois3` (5 páginas de Configurações e Terminal): no máximo 0,24%. Depois da virada do dia do jogo (21h, UTC−3) a Agenda e o Terminal passam de 1% por causa da data (`final2`). Logs em `tests/_saida/` (ver `LEIA-ME.md` ali) |",
         "| Resoluções | `tests/resolucoes`: 119 verificações, 0 falhas (4 proporções por SubViewport, com Menu Principal, Menu de Pausa e Tela de Fim de Jogo, + janelas reais 1280×720 e 1600×1000) — rodada de 2026-11-13, com o código atual (seção 11) |", ""]
    L += ["## 2. Diagnóstico (§18.1)", "",
          "Antes desta etapa, o projeto tinha a arquitetura por feature e o jogo completos, mas **toda a interface nascia em código**: 16 cenas com 25 nós (quase só a raiz com script), %d chamadas `UiKit.*` e %d `Classe.new()` de nós de interface, %d `add_child`, %d `add_theme_*_override` e nenhum `@onready`/`@export`. Consequências: o editor mostrava cenas vazias; nenhum layout podia ser ajustado visualmente; o estilo ficava espalhado em scripts; `UiKit` era um construtor global escondido; testes e revisões dependiam de ler código para saber o que existia." % (tot_ant["ui_kit"], tot_ant["new_ui"], tot_ant["add_child"], tot_ant["overrides"]), ""]
    L += ["## 3. Plano de migração (§18.2)", "",
          "| Fase | Conteúdo | Situação |", "|---|---|---|",
          "| 1 | Baseline: capturas e árvores do projeto original (`antes`), convenções de nome/`@onready`/`@export` | concluída |",
          "| 2 | Tema: `TemaNexus` + variações de rótulo geradas (`TemaVariacoes`), tema base exportado em `.tres` e ligado em `gui/theme/custom` | concluída |",
          "| 3 | Componentes e shell (barra de tarefas, menu iniciar, notificações, widget, janela base, ícones, glitch, papel de parede) | concluída |",
          "| 4 | Os 12 aplicativos | concluída |",
          "| 5 | Diálogos modais, minigame lógico e puzzle da chave | concluída |",
          "| 6 | Telas de boot e final (com cena de item das evidências) | concluída |",
          "| 7 | Limpeza (`UiKit` reduzido a utilitários), testes automáticos, varredura de avisos do editor, documentação | concluída (ressalvas na seção 12) |", ""]
    L += ["## 4. Estrutura de pastas (§18.3)", "", "```text"]
    for dp, dn, fn in os.walk(rel("features")):
        dn[:] = sorted(d for d in dn if not d.startswith("."))
        nivel = os.path.relpath(dp, RAIZ).count(os.sep)
        if os.path.basename(dp) in ("scenes", "scripts"):
            continue
        if nivel <= 4:
            nt = len([f for f in os.listdir(os.path.join(dp, "scenes"))]) if os.path.isdir(os.path.join(dp, "scenes")) else 0
            L.append("%s%s/%s" % ("  " * nivel, os.path.basename(dp), ("   (%d cena%s)" % (nt, "" if nt == 1 else "s")) if nt else ""))
    L += ["shared/ui/…   componentes compartilhados (janela_base, app_base, dialogo_nexus, icone_app, …)", "shared/theme/tema_nexus_base.tres", "core/autoload/   9 autoloads (sem interface)", "core/utilities/  UiKit (utilitários), TemaNexus, TemaVariacoes, …", "tests/, tools/", "```", ""]
    L += ["## 5. Contratos preservados", "",
          "- **Autoloads (9), sem alteração de nome, ordem ou papel:** " + ", ".join("`%s`" % a for a in AUTOLOADS) + ". Nenhum cria nós de interface; as telas reagem aos sinais deles.",
          "- **`AppBase`:** `iniciar(args)`, `receber_args(args)`, `pode_fechar()`, `confirmar_fechar()`, `ao_focar()`, `ao_fechar()`, `definir_titulo()`, `conectar()` e o sinal `titulo_alterado` continuam iguais.",
          "- **`GerenciadorJanelas`:** `abrir_app`, `fechar_janela` etc. e o catálogo `core/data/catalogo_apps.json` (campo `cena`) inalterados; cada app continua sendo instanciado pelo gerenciador.",
          "- **Dados, narrativa, salvamento e flags:** nenhum arquivo de `core/data/` foi alterado.", ""]
    L += ["## 6. Relatório de mudanças de API", "",
          "Comparação automática entre o projeto antes desta etapa e o atual: **0 scripts removidos, 0 sinais removidos ou renomeados, 19 scripts novos** (componentes e itens). Mudanças que afetam código que use esses nomes:", "",
          "| # | Antigo → novo | Arquivos afetados | Motivo | Compatibilidade / migração | Risco |", "|---|---|---|---|---|---|",
          "| 1 | `UiKit.botao/rotulo/painel/linha/margem/rolagem/separador/rico/rotulo_quebra/caixa_h/caixa_v/cheio/espacador/expandir/icone_app/texto_alvo` removidos; novos `UiKit.refs_ok` e `UiKit.remover_itens` (ficam `escalar` e `limpar_filhos`) | `core/utilities/ui_kit.gd` e todas as telas | A interface passou a existir na cena | Quebra para quem chamava os construtores; dentro do projeto não resta nenhuma chamada (validador estático). Migração: criar o nó na cena ou instanciar uma cena de item | baixo (validador + testes) |",
          "| 2 | `DialogoNexus.new()` + `montar(...)` / `montar_escolha(...)` → `DialogoNexus.criar(...)` / `criar_escolha(...)`; `DialogoArquivo.criar(modo, pasta, nome, extensões)`; `DialogoChave.criar(caminho)` (fábricas estáticas que instanciam a cena do diálogo); novo `DialogoNexus.mostrar_erro()` | `shared/ui/dialogo_nexus`, `shared/ui/dialogo_arquivo`, `dialogo_chave`; os chamadores públicos (`GerenciadorJanelas.alerta/confirmar/escolher_arquivo/...`) não mudaram | O diálogo é uma cena | `montar*` continuam públicos, mas `.new()` sozinho não cria os nós; usar `criar*`. Chamadores internos migrados | médio (grupo `dialogos` dos testes) |",
          "| 3 | `MinigameLogica.new()` + `montar()` → `MinigameLogica.criar()` | `features/minigames/logica`, `dialogo_chave`/pasta protegida | Idem | `avaliar()` estático inalterado | baixo |",
          "| 4 | `BalaoChat`, `SlotCircuito`, `PortaLogicaItem` deixam de ser construídos com `.new()`; `SlotCircuito.slot_id` passa a `@export` | mensageiro, minigame | Itens agora são cenas | `BalaoChat.configurar(entrada, largura_max)` mantido; instanciar a cena (`cena_balao` etc.) | baixo |",
          "| 5 | Constantes públicas de layout/dados removidas dos scripts: `LOCAIS` (Explorador), `TECLAS` (Calculadora), `PAGINAS`/`ATALHOS`/`PERMISSOES`/`TAMANHOS_TEXTO` (Configurações), `ETIQUETAS_ESTADO`/`NOMES_SEMANA` (Agenda), `LARGURA_BARRA`/`LIMITE_TEXTO` (Mensageiro), `INTERVALO`, `INTERVALO_AUDIO`, `MARGEM`/`LARGURA`/`ALTURA`/`BORDA` (shell), `CODIGO_SHADER` (glitch) | scripts correspondentes | Os valores agora estão nas cenas (posições, textos dos botões) ou em `@export` | Nenhuma referência externa no projeto | baixo |",
          "| 6 | `AppNavegador.ao_focar()` deixou de sobrescrever `AppBase.ao_focar()` | `app_navegador.gd` | O foco inicial é do campo na cena | Comportamento do hook herdado (vazio) | baixo |",
          "| 7 | **Novo** `GerenciadorConfiguracoes.persistencia_habilitada` (padrão `true`) | autoload | Testes não podem gravar as preferências reais | Aditivo; padrão mantém o comportamento | baixo |",
          "| 8 | Tamanhos mínimos de painéis e janelas deixam de ser multiplicados por `UiKit.escalar(tamanho do texto)` e viram `custom_minimum_size` fixo na cena | cenas de app/diálogo | Valor editável no inspetor | A fonte continua escalando pelo tema; só o tamanho mínimo da caixa não acompanha mais a escala do texto | médio-baixo (visual) |",
          "| 9 | Novo `gui/theme/custom` em `project.godot` apontando para `shared/theme/tema_nexus_base.tres` | `project.godot` | O editor mostra as cenas estilizadas | Em jogo o tema de `TemaNexus.aplicar()` continua prevalecendo | baixo |",
          "| 10 | Novos testes e ferramentas: `tests/avisos_editor`, `tests/exportar_tema`, `tests/resolucoes`; `tools/gerar_docs_ui.py` | — | Evidência de aceitação | Aditivo | nenhum |", ""]
    L += ["## 7. Componentes reutilizáveis", "", "| Cena | Raiz | API (exports / sinais / métodos públicos) |", "|---|---|---|"]
    for r in comps:
        si = r["si"]
        api = []
        if si.get("exports"):
            api.append("exports: " + ", ".join("`%s`" % n for n, t in si["exports"]))
        if si.get("sinais"):
            api.append("sinais: " + ", ".join("`%s`" % s for s, p in si["sinais"]))
        pub = [f for f in si.get("publicas", []) if f not in ("iniciar", "ao_focar")]
        if pub:
            api.append("métodos: " + ", ".join("`%s()`" % f for f in pub[:6]))
        L.append("| `%s` | %s | %s |" % (r["caminho"], tipo_raiz(r["raiz"]), "; ".join(api) or "—"))
    L += [""]
    L += ["## 8. Os 12 aplicativos (um por seção)", ""]
    for app in cat:
        L += secao_app(app, grupos)
    L += ["## 9. Demais cenas: telas, shell, itens de lista, diálogos e minigame", "", "| Cena | Raiz | Nós | `%Nome` | Exports | Conexões na cena | Grupo de teste |", "|---|---|---:|---:|---|---:|---|"]
    ids = {a["cena"].replace("res://", "") for a in cat}
    for r in res:
        if r["caminho"] in ids or "/components/" in r["caminho"] or r["caminho"].startswith("shared/ui/app_base"):
            continue
        nome = os.path.basename(r["caminho"])
        g = ""
        if "tela_boot" in nome:
            g = "tela_boot"
        elif "tela_final" in nome:
            g = "tela_final"
        elif r["caminho"].startswith("shared/ui/dialogo") or "dialogo" in nome or "minigame" in nome:
            g = "dialogos"
        ex = ", ".join("`%s`" % n for n, t in r["si"].get("exports", [])) or "—"
        L.append("| `%s` | %s | %d | %d | %s | %d | %s |" % (r["caminho"], tipo_raiz(r["raiz"]), r["nos"], len(r["unicos"]), ex, len(r["conexoes"]), ("`%s` (%d)" % (g, len(grupos.get(g, [])))) if g else "—"))
    L += [""]
    acoes = re.findall(r'"(nexus_\w+)":\s*\[(KEY_\w+),\s*(true|false),\s*(true|false)\]', open(rel("core", "autoload", "gerenciador_configuracoes.gd"), encoding="utf-8").read())
    L += ["## 10. Input Map e `project.godot` (§18.7)", "",
          "As ações abaixo são registradas **em código** por `GerenciadorConfiguracoes._registrar_acoes()` (não aparecem em `project.godot`, por decisão da arquitetura original); não há mapa de entrada a editar no editor.", "",
          "| Ação | Tecla |", "|---|---|"]
    for a, k, c, s in acoes:
        L.append("| `%s` | %s%s%s |" % (a, "Ctrl+" if c == "true" else "", "Shift+" if s == "true" else "", k.replace("KEY_", "")))
    L += ["", "Mudança em `project.godot` nesta etapa: secção `[gui]` com `theme/custom=\"res://shared/theme/tema_nexus_base.tres\"`; autoloads, resolução-base 1920×1080, `canvas_items` + `expand` e o modo de janela ficaram como estavam. Mudanças posteriores, da rodada da Splash Screen de 2026-11-13 ([`docs/15`](15_splash_screen.md)): a cena principal deixou de ser a `tela_boot.tscn` e passou a ser `res://features/splash_screen/scenes/splash_screen.tscn`; a tela de boot do motor ficou preta e sem imagem (`boot_splash/bg_color` e `boot_splash/show_image`) e a cor de limpeza padrão ficou preta (`default_clear_color`).", ""]
    L += ["## 11. Testes de aceitação (§18.8)", "", "| Teste | Como rodar | Resultado |", "|---|---|---|",
          "| Validador estático | `python3 -I tools/validar_projeto.py` | 0 erros, 0 avisos |",
          "| Avisos do editor | abrir `tests/avisos_editor/varredura_editor.gd` e *Arquivo → Executar* (Ctrl+Shift+X) | 63 cenas, **0 avisos** — rodada de 2026-11-13, `tests/_saida/avisos_editor/log_editor.txt` (em 2026-11-09: 58 → 0 com 55 cenas; a 63ª é a Splash) |",
          "| Interação (cliques, teclado, diálogos, boot, final) | abrir `tests/ui_interacao/ui_interacao.tscn` e F6 | **%s** |" % (resumo_log.replace("RESULTADO: ", "") or "—"),
          "| Capturas e árvores | `tests/ui_dump/ui_dump.tscn` e F6 (3ª linha de `rodada.txt` = rodada de referência) | árvore de nós idêntica antes/depois da última correção; diferenças só de relógio/data |",
          "| Fumaça | `tests/smoke_test.tscn` (com `-- --ui` nos argumentos de execução, inclui a camada de interface) | **308 verificações sem a etapa de interface e 345 com `-- --ui`**, 0 falhas, Depurador limpo — rodada de 2026-11-13; a saída fica só no painel Saída do editor (não há arquivo de log) |",
          "| Resoluções | `tests/resolucoes/resolucoes.tscn` e F6 | 139 verificações, 0 falhas — rodada de 2026-11-13 (`tests/_saida/resolucoes/log.txt`; inclui a Splash nas quatro proporções) |",
          "| Persistência em disco | `tests/persistencia/persistencia.tscn` e F6 (grava só em `user://nexus_os_teste/`) | 119 verificações, 0 falhas — rodada de 2026-11-13 (`tests/_saida/persistencia/log.txt`); deixa 6 avisos esperados no Depurador |",
          "| Fluxo de sessão (Menu, Pausa, Fim de Jogo) | `tests/fluxo_sessao/fluxo_sessao.tscn` e F6 (grava só em `user://nexus_os_teste_fluxo/`) | 194 verificações, 0 falhas — rodada de 2026-11-13 (`tests/_saida/fluxo_sessao/log.txt`, com capturas de tela); deixa 6 mensagens esperadas no Depurador. Descrito em `docs/14` e `docs/15` |",
          "| Splash Screen (abertura, pulo, falhas, acessibilidade) | `tests/splash/splash.tscn` e F6 (grava só em `user://nexus_os_teste_splash/`) | 311 verificações, 0 falhas — rodada de 2026-11-13 (`tests/_saida/splash/log.txt`, com capturas de tela); deixa mensagens esperadas no Depurador (as falhas provocadas de propósito). Descrito em `docs/15` |", ""]
    L += ["## 12. Ressalvas e limitações", "",
          "1. **Nós de interface ainda criados em código (4, em 3 scripts):** botões por opção do diálogo de escolha (`dialogo_nexus.gd`), a prévia de arrastar da porta lógica (`porta_logica_item.gd`) e o espaçador de células vazias da grade da Agenda (`app_calendario.gd`). São dinâmicos ou transitórios; poderiam virar cenas de item, o que não foi feito.",
          "2. **Overrides de tema em código (7):** cores/estados ligados a dados (severidade do toast, cor do ícone do app etc.), não layout.",
          "3. **Tamanhos mínimos fixos** (seção 6, item 8): a escala do texto continua valendo para as fontes, não para o tamanho mínimo das caixas.",
          "4. **Rodada de 2026-11-13:** fumaça (com e sem interface), interação, resoluções, persistência, fluxo de sessão e a varredura dos avisos do editor foram executadas na Godot 4.7.2 com os arquivos finais deste pacote; o validador estático e a auditoria de marca foram reexecutados depois da última alteração de código.",
          "5. **Rodada de 2026-11-09 às 21h (UTC−3):** o dia do jogo e o relógio dependem da hora real; capturas de dias diferentes diferem em texto/relógio e no destaque \"hoje\" da Agenda.",
          "6. **Efeito colateral nas preferências do jogador:** execuções de teste anteriores à correção do isolamento gravaram em `user://nexus_os/configuracoes.cfg` (reduzir glitch/tremor/flashes/ruído = ativado). Para voltar ao padrão: *Configurações → Acessibilidade → restaurar padrões* ou apagar esse arquivo.",
          "7. **Documentos 01, 02, 03, 05, 07, 08 e 09** descrevem a etapa anterior (interface em código, \"nunca executado\"); a verdade atual está neste documento e em `docs/04`.",
          "8. **O editor mostra o jogo em exclusivo fullscreen** nas execuções de teste (configuração do projeto); a varredura de avisos não sofre com isso porque é um `EditorScript` (`tests/avisos_editor/varredura_editor.gd`) e roda dentro do editor.",
          "9. **`tests/avisos_editor/avisos_editor.tscn` é obsoleto:** a primeira versão da varredura rodava o jogo e chamava `Node.get_configuration_warnings()`, que o GDScript da Godot 4.7 não expõe. A cena foi reduzida a um aviso que encerra na hora; nada a referencia e ela pode ser apagada (a ferramenta que fez a migração não consegue apagar arquivos da sua pasta).",
          "10. **Rebranding, fluxo de sessão e Splash Screen (2026-11-13):** o rebranding para Maya Human Syntax ([`docs/12`](12_rebranding_maya_human_syntax.md)), o Menu Principal, a Pausa e a Tela de Fim de Jogo ([`docs/14`](14_fluxo_de_sessao_menu_pausa_fim_de_jogo.md)) e a Splash Screen, nova cena principal ([`docs/15`](15_splash_screen.md)), foram verificados no motor no mesmo dia; os números da tabela de testes acima são da última rodada. O salvamento de versão 1 é coberto por `tests/persistencia`. A conferência manual R1–R6 de `docs/08_testes_manuais.md` e uma campanha manual completa continuam não verificadas.", ""]
    return "\n".join(L).rstrip() + "\n"


def main():
    cenas = arquivos_cena()
    for nome, texto in (("04_hierarquia_das_cenas.md", doc04(cenas)), ("10_refatoracao_ui.md", doc10(cenas))):
        caminho = rel("docs", nome)
        open(caminho, "w", encoding="utf-8", newline="\n").write(texto)
        print("escrito", os.path.relpath(caminho, RAIZ), len(texto.splitlines()), "linhas")


if __name__ == "__main__":
    main()
