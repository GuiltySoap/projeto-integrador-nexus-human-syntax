#!/usr/bin/env python3
"""Validador estático (heurístico) do projeto HumaxOS (Maya Human Syntax). Não substitui a Godot.

Uso (a partir da raiz do projeto, onde fica o project.godot):
    python3 -I tools/validar_projeto.py            # valida o projeto atual
    python3 -I tools/validar_projeto.py <pasta>    # valida outra pasta

O script só LÊ arquivos (.gd, .tscn, .godot, .json) e imprime ERRO (provável erro de parse ou de execução) e AVISO
(revisar). Termina com código 1 se houver ERRO. Apenas biblioteca padrão; não executa nada do projeto.

O que ele procura (heurísticas, escritas porque o ambiente de desenvolvimento não tinha a Godot):
  - indentação com tabs, brackets balanceados, sintaxe do Godot 3 e `:=` com valor Variant;
  - chamadas a autoloads e a classes (class_name) que não existem, e número de argumentos errado;
  - sinais conectados a métodos que não existem ou com número de parâmetros incompatível;
  - caminhos res:// que não existem e referências a nós ($Nome) ausentes nas cenas;
  - APIs proibidas pelo projeto: OS.execute, eval/Expression, OS.shell_open, kill/create_process, remoção de arquivos,
    classes de rede e escrita em res://;
  - parâmetros de função e variáveis locais que sombreiam um membro da própria classe: variável, constante, enum, função, sinal ou classe
    interna (a Godot avisa SHADOWED_VARIABLE);
  - divisão por literal inteiro (INTEGER_DIVISION) e ternário com ramos incompatíveis, como `texto if x else null` ou `int(v) if x else v`
    (INCOMPATIBLE_TERNARY): avisos de compilação que a Godot só mostra no Depurador quando o jogo roda no editor;
  - ordem dos autoloads: um autoload que, no seu _ready/_init, usa outro autoload instanciado DEPOIS dele no project.godot
    (o outro ainda não rodou o próprio _ready) — o equivalente aqui a um "ciclo" de dependências na inicialização.
Ele NÃO pega tudo o que o analisador da Godot pega. A confirmação final é abrir o projeto no editor (painel Output).
"""
import os
import re
import sys

RAIZ = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.getcwd())
if not os.path.exists(os.path.join(RAIZ, "project.godot")):
    sys.exit("Execute a partir da raiz do projeto (onde está o project.godot) ou passe a pasta como argumento.")
erros = []
avisos = []


def erro(arq, n, msg):
    erros.append("%s:%d: %s" % (os.path.relpath(arq, RAIZ), n, msg))


def aviso(arq, n, msg):
    avisos.append("%s:%d: %s" % (os.path.relpath(arq, RAIZ), n, msg))


def ler(p):
    with open(p, encoding="utf-8") as f:
        return f.read()


# ------------------------------------------------------------------ coleta
scripts = {}
cenas = {}
for dp, dn, fn in os.walk(RAIZ):
    partes = dp.split(os.sep)
    if ".godot" in partes or ".git" in partes:
        continue
    for f in fn:
        p = os.path.join(dp, f)
        if f.endswith(".gd"):
            scripts[p] = ler(p)
        elif f.endswith(".tscn"):
            cenas[p] = ler(p)


def limpar_linha(linha, estado):
    """Remove strings e comentários; estado é um dict {'bloco': bool} (strings multilinha não são usadas no projeto)."""
    saida = []
    i = 0
    n = len(linha)
    while i < n:
        c = linha[i]
        if c == "#":
            break
        if c == '"' or c == "'":
            q = c
            i += 1
            saida.append('"')
            while i < n and linha[i] != q:
                if linha[i] == "\\":
                    i += 1
                i += 1
            saida.append('"')
            i += 1
            continue
        saida.append(c)
        i += 1
    return "".join(saida)


def parse_script(p, texto):
    info = {"funcs": {}, "sinais": {}, "membros": set(), "class_name": None, "extends": None, "linhas": [], "inner": set()}
    for i, bruta in enumerate(texto.split("\n"), 1):
        cod = limpar_linha(bruta, {})
        info["linhas"].append((i, bruta, cod))
        m = re.match(r"^class_name\s+(\w+)", cod)
        if m:
            info["class_name"] = m.group(1)
        m = re.match(r"^extends\s+(\w+)", cod)
        if m and info["extends"] is None:
            info["extends"] = m.group(1)
        m = re.match(r"^(static\s+)?func\s+(\w+)\s*\((.*?)\)\s*(->\s*([\w\.\[\]]+))?\s*:", cod)
        if m:
            params = [x.strip() for x in split_args(m.group(3))] if m.group(3).strip() else []
            obrig = len([x for x in params if "=" not in x])
            info["funcs"][m.group(2)] = {"min": obrig, "max": len(params), "ret": m.group(5), "linha": i, "static": bool(m.group(1))}
            continue
        m = re.match(r"^signal\s+(\w+)\s*(\((.*)\))?", cod)
        if m:
            params = [x.strip() for x in split_args(m.group(3))] if m.group(3) and m.group(3).strip() else []
            info["sinais"][m.group(1)] = len(params)
            continue
        m = re.match(r"^(static\s+)?var\s+(\w+)", cod)
        if m:
            info["membros"].add(m.group(2))
            continue
        m = re.match(r"^const\s+(\w+)", cod)
        if m:
            info["membros"].add(m.group(1))
            continue
        m = re.match(r"^enum\s+(\w+)", cod)
        if m:
            info["membros"].add(m.group(1))
            continue
        m = re.match(r"^\s*class\s+(\w+)", cod)
        if m:
            info["inner"].add(m.group(1))
    return info


def split_args(s):
    saida = []
    prof = 0
    atual = ""
    for c in s:
        if c in "([{":
            prof += 1
        elif c in ")]}":
            prof -= 1
        if c == "," and prof == 0:
            saida.append(atual)
            atual = ""
        else:
            atual += c
    if atual.strip():
        saida.append(atual)
    return saida


infos = {p: parse_script(p, t) for p, t in scripts.items()}
classes = {i["class_name"]: p for p, i in infos.items() if i["class_name"]}

# autoloads a partir do project.godot
autoloads = {}
pg = os.path.join(RAIZ, "project.godot")
if os.path.exists(pg):
    sec = ""
    for l in ler(pg).split("\n"):
        l = l.strip()
        if l.startswith("["):
            sec = l
        elif sec == "[autoload]" and "=" in l:
            nome, val = l.split("=", 1)
            caminho = val.strip().strip('"').lstrip("*")
            if caminho.startswith("res://"):
                autoloads[nome.strip()] = os.path.join(RAIZ, caminho[6:])
            else:
                aviso(pg, 1, "autoload '%s' não usa caminho res:// (%s)" % (nome.strip(), caminho))

for nome, p in autoloads.items():
    if p not in infos:
        erro(pg, 1, "autoload '%s' aponta para arquivo inexistente: %s" % (nome, os.path.relpath(p, RAIZ)))
    if nome in classes:
        erro(pg, 1, "class_name '%s' conflita com o autoload de mesmo nome" % nome)

# membros herdados dentro do projeto
def membros_de(p, vistos=None):
    vistos = vistos or set()
    if p in vistos or p not in infos:
        return {"funcs": {}, "sinais": {}, "membros": set()}
    vistos.add(p)
    i = infos[p]
    funcs = dict(i["funcs"])
    sinais = dict(i["sinais"])
    membros = set(i["membros"])
    base = i["extends"]
    if base in classes:
        h = membros_de(classes[base], vistos)
        for k, v in h["funcs"].items():
            funcs.setdefault(k, v)
        for k, v in h["sinais"].items():
            sinais.setdefault(k, v)
        membros |= h["membros"]
    return {"funcs": funcs, "sinais": sinais, "membros": membros}


# ------------------------------------------------------------------ verificações por script
NOMES_VIRTUAIS = {"_ready", "_process", "_physics_process", "_input", "_unhandled_input", "_unhandled_key_input", "_gui_input",
                  "_draw", "_notification", "_enter_tree", "_exit_tree", "_init", "_get_drag_data", "_can_drop_data", "_drop_data",
                  "_get_minimum_size", "_make_custom_tooltip", "_has_point", "_to_string", "_get", "_set", "_get_property_list"}
VARIANT_FUNCS = ["pick_random", "pop_front", "pop_back", "front", "back", "get_meta", "callv", "call", "parse_string", "str_to_var",
                 "floor", "round", "ceil", "abs", "min", "max", "clamp", "lerp", "sign", "snapped", "wrap", "get_setting"]
PADROES_GODOT3 = [
    (r"\byield\s*\(", "yield() não existe no Godot 4 (use await)"),
    (r"^\s*onready\s+var", "onready var → @onready var"),
    (r"^\s*export\s*(\(|var)", "export → @export"),
    (r"\bsetget\b", "setget → propriedades com get/set"),
    (r"\.connect\(\s*\"", "connect(\"sinal\", ...) → sinal.connect(callable)"),
    (r"\binstance\(\)", "instance() → instantiate()"),
    (r"\bOS\.get_ticks_msec", "OS.get_ticks_msec → Time.get_ticks_msec"),
    (r"\brand_range\(", "rand_range → randf_range/randi_range"),
    (r"\bdeg2rad\(|\brad2deg\(", "deg2rad/rad2deg → deg_to_rad/rad_to_deg"),
    (r"\bPool\w+Array\b", "PoolXArray → PackedXArray"),
    (r"\bOS\.execute\b|\beval\(|\bExpression\.new\b|\bOS\.shell_open\b|\bOS\.kill\b|\bOS\.create_process\b", "API proibida pelas regras de segurança do projeto"),
    (r"\bDirAccess\.remove|\bDirAccess\.\w*remove|\.remove\(\s*\"", "remoção de arquivos é proibida pelas regras do projeto"),
    (r"\bOS\.execute_with_pipe\b|\bOS\.set_restart_on_exit\b|\bOS\.move_to_trash\b|\bOS\.crash\b", "API proibida pelas regras de segurança do projeto"),
    (r"\bHTTPRequest\b|\bHTTPClient\b|\bStreamPeerTCP\b|\bStreamPeerTLS\b|\bPacketPeerUDP\b|\bWebSocketPeer\b|\bTCPServer\b|\bUDPServer\b|\bENetConnection\b|\bENetMultiplayerPeer\b|\bWebRTC\w*\b", "acesso à rede é proibido (o jogo funciona 100% offline)"),
    (r"FileAccess\.open\(\s*\"res://[^\"]*\"\s*,\s*FileAccess\.(WRITE|READ_WRITE|WRITE_READ)", "gravação em res:// é proibida (dados persistentes vão para user://)"),
    (r"DirAccess\.(make_dir|make_dir_recursive|rename|copy)\w*\(\s*\"res://", "alteração de pastas/arquivos em res:// é proibida"),
]
BUILTINS_PRIVADOS = {"_init"}



def rhs_eh_get_simples(rhs):
    """True se a expressão inteira é uma cadeia simples terminando em .get(...) (resultado Variant)."""
    if re.search(r"\s+as\s+\w+\s*$", rhs) or re.search(r"\sif\s", rhs):
        return False
    m = re.match(r"^[\w\.\[\]\"]*?\.get\(", rhs)
    if not m:
        return False
    ini = m.end() - 1
    prof = 0
    for j in range(ini, len(rhs)):
        if rhs[j] == "(":
            prof += 1
        elif rhs[j] == ")":
            prof -= 1
            if prof == 0:
                return rhs[j + 1:].strip() == ""
    return False


def contar_args(cod, ini):
    """Dado o texto e o índice do '(' de abertura, devolve (n_args, fechou)."""
    prof = 0
    args = []
    atual = ""
    for j in range(ini, len(cod)):
        c = cod[j]
        if c in "([{":
            prof += 1
            if prof == 1:
                continue
        elif c in ")]}":
            prof -= 1
            if prof == 0:
                if atual.strip():
                    args.append(atual)
                return len(args), True
        if prof == 1 and c == ",":
            args.append(atual)
            atual = ""
        else:
            atual += c
    return 0, False


# Aridade (mín, máx) dos sinais comuns da engine. Sinais com assinatura diferente entre classes
# (ex.: TextEdit.text_changed() sem argumento x LineEdit.text_changed(texto)) aceitam uma faixa.
SINAIS_ENGINE = {
    "pressed": (0, 0), "toggled": (1, 1), "text_submitted": (1, 1), "text_changed": (0, 1), "item_selected": (1, 1),
    "item_activated": (1, 1), "value_changed": (1, 1), "meta_clicked": (1, 1), "meta_hover_started": (1, 1),
    "meta_hover_ended": (1, 1), "gui_input": (1, 1), "timeout": (0, 0), "finished": (0, 0), "drag_ended": (1, 1),
    "drag_started": (0, 0), "caret_changed": (0, 0), "mouse_entered": (0, 0), "mouse_exited": (0, 0),
    "focus_entered": (0, 0), "focus_exited": (0, 0), "visibility_changed": (0, 0), "resized": (0, 0),
    "tree_exited": (0, 0), "tree_entered": (0, 0), "button_down": (0, 0), "button_up": (0, 0), "item_clicked": (3, 3),
    "tab_changed": (1, 1), "text_set": (0, 0), "child_entered_tree": (1, 1), "size_changed": (0, 0),
    "close_requested": (0, 0), "minimum_size_changed": (0, 0), "item_rect_changed": (0, 0),
}


def bloco_balanceado(cod, ini):
    """Texto entre o '(' em `ini` e o ')' correspondente (None se não fechar na linha)."""
    prof = 0
    for j in range(ini, len(cod)):
        if cod[j] in "([{":
            prof += 1
        elif cod[j] in ")]}":
            prof -= 1
            if prof == 0:
                return cod[ini + 1:j]
    return None


def aridade_sinal(expr_sinal, tudo):
    """Faixa (mín, máx) de argumentos de um sinal: 'Autoload.sinal', 'sinal_local' ou 'obj.sinal_da_engine'."""
    partes = expr_sinal.split(".")
    nome = partes[-1]
    if len(partes) == 2 and (partes[0] in autoloads or partes[0] in classes):
        alvo = autoloads.get(partes[0]) or classes.get(partes[0])
        h = membros_de(alvo)
        if nome in h["sinais"]:
            return (h["sinais"][nome], h["sinais"][nome])
    if len(partes) == 1 and nome in tudo["sinais"]:
        return (tudo["sinais"][nome], tudo["sinais"][nome])
    if nome in SINAIS_ENGINE:
        return SINAIS_ENGINE[nome]
    return None


def faixa_texto(ar):
    return str(ar[0]) if ar[0] == ar[1] else "%d..%d" % ar


def compativel(f, ar, n_bind):
    """Existe uma quantidade de argumentos do sinal (dentro da faixa) que o método aceita junto com os binds?"""
    return any(f["min"] <= a + n_bind <= f["max"] for a in range(ar[0], ar[1] + 1))


def checar_conexoes(p, n, cod, tudo):
    """Aridade do método ligado a um sinal (com .bind) e dos callables passados a conectar()."""
    for mm in re.finditer(r"([\w\.]+)\.connect\(", cod):
        inner = bloco_balanceado(cod, mm.end() - 1)
        if inner is None:
            continue
        m2 = re.match(r"^\s*(?:self\.)?(_?[A-Za-z]\w*)\s*(\.bind\(|$)", inner)
        if not m2:
            continue
        metodo = m2.group(1)
        n_bind = 0
        if m2.group(2):
            ini_bind = inner.index(".bind(") + len(".bind")
            args_bind = bloco_balanceado(inner, ini_bind)
            n_bind = len(split_args(args_bind)) if args_bind is not None and args_bind.strip() else 0
        f = tudo["funcs"].get(metodo)
        if not f:
            continue
        ar = aridade_sinal(mm.group(1), tudo)
        if ar is None:
            continue
        if not compativel(f, ar, n_bind):
            erro(p, n, "%s ligado a '%s' (%s arg do sinal + %d bind) mas aceita %d..%d parâmetros" % (metodo, mm.group(1), faixa_texto(ar), n_bind, f["min"], f["max"]))
    for mm in re.finditer(r"\bconectar\(\s*([\w\.]+)\s*,\s*(?:self\.)?(_?[A-Za-z]\w*)\s*\)", cod):
        f = tudo["funcs"].get(mm.group(2))
        ar = aridade_sinal(mm.group(1), tudo)
        if f and ar is not None and not compativel(f, ar, 0):
            erro(p, n, "conectar(%s, %s): o sinal tem %s argumento(s), o método aceita %d..%d" % (mm.group(1), mm.group(2), faixa_texto(ar), f["min"], f["max"]))


def checar_script(p, texto):
    i = infos[p]
    tudo = membros_de(p)
    base_nativa = i["extends"]
    linhas = i["linhas"]
    # bracket balance global
    prof = 0
    for n, bruta, cod in linhas:
        for c in cod:
            if c in "([{":
                prof += 1
            elif c in ")]}":
                prof -= 1
        if prof < 0:
            erro(p, n, "parêntese/colchete fechado sem abrir")
            prof = 0
    if prof != 0:
        erro(p, len(linhas), "brackets desbalanceados no arquivo (saldo %d)" % prof)
    # funções duplicadas
    vistos = {}
    for n, bruta, cod in linhas:
        m = re.match(r"^(static\s+)?func\s+(\w+)", cod)
        if m:
            if m.group(2) in vistos:
                erro(p, n, "função '%s' definida duas vezes (primeira na linha %d)" % (m.group(2), vistos[m.group(2)]))
            vistos[m.group(2)] = n
    # parâmetros e locais que sombreiam membros da classe (Godot: SHADOWED_VARIABLE)
    em_inner = False
    em_func = False
    for n, bruta, cod in linhas:
        if bruta.strip() == "" or cod.strip() == "":
            continue
        if not bruta.startswith(("\t", " ")):
            em_inner = bool(re.match(r"^class\s+\w+", cod))
            em_func = False
            if em_inner:
                continue
            m = re.match(r"^(static\s+)?func\s+\w+\s*\((.*)\)", cod)
            if m:
                em_func = True
                for par in split_args(m.group(2)) if m.group(2).strip() else []:
                    nome_par = re.match(r"\s*(\w+)", par).group(1)
                    if nome_par in tudo["membros"]:
                        erro(p, n, "parâmetro '%s' sombreia um membro da classe (a Godot avisa SHADOWED_VARIABLE): renomeie" % nome_par)
                    elif nome_par in tudo["funcs"] or nome_par in tudo["sinais"] or nome_par in i["inner"]:
                        erro(p, n, "parâmetro '%s' sombreia uma função, sinal ou classe da própria classe (a Godot avisa SHADOWED_VARIABLE): renomeie" % nome_par)
            continue
        if em_inner or not em_func:
            continue
        m = re.match(r"^\s+(?:var\s+(\w+)|for\s+(\w+)\s+in\b)", cod)
        if m:
            nome_loc = m.group(1) or m.group(2)
            if nome_loc in tudo["membros"]:
                erro(p, n, "variável local '%s' sombreia um membro da classe (a Godot avisa SHADOWED_VARIABLE): renomeie" % nome_loc)
            elif nome_loc in tudo["funcs"] or nome_loc in tudo["sinais"] or nome_loc in i["inner"]:
                erro(p, n, "variável local '%s' sombreia uma função, sinal ou classe da própria classe (a Godot avisa SHADOWED_VARIABLE): renomeie" % nome_loc)
    prof = 0
    for n, bruta, cod in linhas:
        if bruta.strip() == "":
            continue
        # indentação
        ind = re.match(r"^[ \t]*", bruta).group(0)
        if prof == 0 and " " in ind:
            erro(p, n, "indentação com espaços (use tabs)")
        elif "\t" in ind and " " in ind:
            erro(p, n, "indentação mistura tabs e espaços")
        for c in cod:
            if c in "([{":
                prof += 1
            elif c in ")]}":
                prof = max(prof - 1, 0)
        if cod.strip() == "":
            continue
        # sintaxe Godot 3 / APIs proibidas
        for rx, msg in PADROES_GODOT3:
            if re.search(rx, bruta if ("connect" in rx or "res://" in rx or '\\"' in rx) else cod):
                erro(p, n, msg)
        # INTEGER_DIVISION: `/ 2` com literal inteiro (o projeto escreve `/ 2.0` para dividir decimais; para a divisão inteira de
        # propósito, use @warning_ignore("integer_division") na linha de cima)
        if re.search(r"[\w\)\]]\s*/\s*\d+(?![\d\.])", cod):
            anterior = linhas[n - 2][1] if n >= 2 else ""
            if "integer_division" not in anterior and "integer_division" not in bruta:
                erro(p, n, "divisão por literal inteiro (a Godot avisa INTEGER_DIVISION): use '/ 2.0' ou @warning_ignore(\"integer_division\")")
        # INCOMPATIBLE_TERNARY: ramos de tipos que não se encaixam (String x null, int x float) avisam na compilação.
        if "ternario-ok" not in bruta:
            if re.search(r"\belse\s+null\b|\bnull\s+if\b", cod):
                erro(p, n, "ternário com 'null' num dos ramos (a Godot avisa INCOMPATIBLE_TERNARY quando o outro ramo não é objeto): use if/else ou marque a linha com '# ternario-ok' se o outro ramo é um objeto")
            if re.search(r"\bint\([^()]*(?:\([^()]*\)[^()]*)*\)\s+if\b.*\belse\s+(?!int\(|-?\d+\b(?!\.))", cod):
                erro(p, n, "ternário que mistura int(...) com outro tipo (a Godot avisa INCOMPATIBLE_TERNARY): use if/else ou marque a linha com '# ternario-ok'")
        # := com Variant
        m = re.match(r"^\s*var\s+\w+\s*:=\s*(.+)$", cod)
        if m:
            rhs = m.group(1).strip()
            if rhs_eh_get_simples(rhs):
                erro(p, n, "':=' com .get(...) (Variant): declare o tipo explicitamente")
            elif rhs.endswith("]") and not rhs.startswith("[") and not rhs.startswith("PackedVector2Array") and not rhs.startswith("Packed") and not re.match(r'^""\s*%\s*\[', rhs):
                aviso(p, n, "':=' com indexação (pode ser Variant): %s" % rhs[:60])
            else:
                for vf in VARIANT_FUNCS:
                    if re.search(r"(^|[^\w])%s\(" % vf, rhs) and not re.search(r"(maxf|minf|maxi|mini|clampf|clampi|absf|absi|lerpf|signf|snappedf|floorf|roundf|ceilf|wrapf|wrapi)\(", rhs[:0]):
                        # funções tipadas equivalentes não casam porque exigimos limite de palavra
                        if re.match(r"^(int|float|str|bool)\(", rhs):
                            continue
                        erro(p, n, "':=' com %s(...) que retorna Variant: use a versão tipada ou declare o tipo" % vf)
                        break
                mm = re.match(r"^(?:await\s+)?(\w+)\.(\w+)\(", rhs)
                if mm and (mm.group(1) in autoloads or mm.group(1) in classes):
                    alvo_p = autoloads.get(mm.group(1)) or classes.get(mm.group(1))
                    f = membros_de(alvo_p)["funcs"].get(mm.group(2))
                    if f and (f["ret"] is None or f["ret"] == "Variant"):
                        erro(p, n, "':=' com %s.%s(...) sem tipo de retorno declarado (Variant)" % (mm.group(1), mm.group(2)))
                mm = re.match(r"^(?:await\s+)?(_?\w+)\(", rhs)
                if mm and mm.group(1) in tudo["funcs"]:
                    f = tudo["funcs"][mm.group(1)]
                    if f["ret"] is None or f["ret"] == "Variant":
                        erro(p, n, "':=' com %s(...) sem tipo de retorno declarado (Variant)" % mm.group(1))
        # chamadas a autoload / class_name
        for mm in re.finditer(r"\b([A-Z]\w+)\.(\w+)\s*(\()?", cod):
            nome, membro, abre = mm.group(1), mm.group(2), mm.group(3)
            alvo = autoloads.get(nome) or classes.get(nome)
            if alvo is None or alvo not in infos:
                continue
            if nome == i["class_name"] and alvo == p:
                pass
            h = membros_de(alvo)
            if membro in h["funcs"]:
                if abre:
                    na, fechou = contar_args(cod, mm.end() - 1)
                    f = h["funcs"][membro]
                    if fechou and not (f["min"] <= na <= f["max"]):
                        erro(p, n, "%s.%s espera %d..%d argumentos, recebeu %d" % (nome, membro, f["min"], f["max"], na))
            elif membro in h["sinais"] or membro in h["membros"]:
                pass
            elif membro == "new" or membro in alvo and False:
                pass
            elif infos[alvo]["inner"] and membro in infos[alvo]["inner"]:
                pass
            else:
                if membro not in ("new", "Modo") and not membro[0].isupper():
                    erro(p, n, "%s não possui o membro '%s'" % (nome, membro))
                elif membro[0].isupper():
                    # enum/const interno: precisa existir
                    if membro not in h["membros"] and membro not in infos[alvo]["inner"]:
                        aviso(p, n, "%s.%s não encontrado (const/enum?)" % (nome, membro))
        checar_conexoes(p, n, cod, tudo)
        # sinais conectados a métodos locais inexistentes
        for mm in re.finditer(r"\.(connect|disconnect|is_connected)\(\s*(_\w+)", cod):
            alvo_m = mm.group(2)
            if alvo_m not in tudo["funcs"] and alvo_m not in NOMES_VIRTUAIS:
                erro(p, n, "método '%s' usado em %s() não existe neste script" % (alvo_m, mm.group(1)))
        # chamadas a funções privadas locais inexistentes
        for mm in re.finditer(r"(?<![\w\.])(_[a-z]\w*)\s*\(", cod):
            f = mm.group(1)
            if f in tudo["funcs"] or f in NOMES_VIRTUAIS or f in BUILTINS_PRIVADOS:
                continue
            if re.match(r"^\s*func\s", cod):
                continue
            erro(p, n, "função privada '%s' não definida" % f)
        # preload/load
        for mm in re.finditer(r"\b(preload|load)\(\s*\"(res://[^\"]+)\"", bruta):
            alvo_r = os.path.join(RAIZ, mm.group(2)[6:])
            if mm.group(1) == "load" and ('exists("%s")' % mm.group(2)) in texto:
                continue
            if not os.path.exists(alvo_r):
                erro(p, n, "%s() de recurso inexistente: %s" % (mm.group(1), mm.group(2)))
        # constantes res:// literais usadas em ResourceLoader.exists(...) não precisam existir
        # emit de sinais do próprio script
        for mm in re.finditer(r"(?<![\w\.])(\w+)\.emit\(", cod):
            if mm.group(1) not in tudo["sinais"] and mm.group(1) not in tudo["membros"]:
                aviso(p, n, "sinal '%s' emitido mas não declarado neste script" % mm.group(1))
    # sinais declarados e nunca emitidos
    for s in i["sinais"]:
        if not re.search(r"\b%s\.emit\(" % s, texto) and not re.search(r"emit_signal\(\s*\"%s\"" % s, texto):
            aviso(p, i["linhas"][0][0], "sinal '%s' declarado mas nunca emitido neste script" % s)


for p, t in scripts.items():
    checar_script(p, t)

# ------------------------------------------------------------------ cenas
def checar_cena(p, texto):
    ids = {}
    for n, l in enumerate(texto.split("\n"), 1):
        m = re.match(r'\[ext_resource .*?path="([^"]+)".*?id="([^"]+)"', l)
        if m:
            ids[m.group(2)] = m.group(1)
            if m.group(1).startswith("res://") and not os.path.exists(os.path.join(RAIZ, m.group(1)[6:])):
                erro(p, n, "ext_resource inexistente: %s" % m.group(1))
        for ref in re.findall(r'ExtResource\("([^"]+)"\)', l):
            if ref not in ids:
                erro(p, n, "ExtResource(\"%s\") sem declaração" % ref)
    # script da raiz e nós referenciados por $/%
    nos = set()
    raiz = None
    for l in texto.split("\n"):
        m = re.match(r'\[node name="([^"]+)" type="[^"]+"( parent="([^"]*)")?', l)
        if m:
            if m.group(3) is None:
                raiz = m.group(1)
            else:
                nos.add(m.group(1) if m.group(3) == "." else m.group(3) + "/" + m.group(1))
    m = re.search(r'script = ExtResource\("([^"]+)"\)', texto)
    if m and m.group(1) in ids:
        alvo = os.path.join(RAIZ, ids[m.group(1)][6:])
        if alvo in scripts:
            for n, bruta, cod in infos[alvo]["linhas"]:
                for ref in re.findall(r"(?<![\w])\$([\w/]+)", cod):
                    if ref not in nos:
                        erro(alvo, n, "$%s não existe na cena %s" % (ref, os.path.relpath(p, RAIZ)))


for p, t in cenas.items():
    checar_cena(p, t)

# ------------------------------------------------------------------ %Nome (nós únicos) e type variations
def nos_da_cena(texto):
    """Lista [nome, único?] de todos os nós da cena (inclusive instâncias de outras cenas)."""
    res = []
    atual = None
    for l in texto.split("\n"):
        m = re.match(r'\[node name="([^"]+)"', l)
        if m:
            atual = [m.group(1), False]
            res.append(atual)
        elif atual is not None and l.strip() == "unique_name_in_owner = true":
            atual[1] = True
    return res


def script_da_raiz(texto):
    """ext_resource id do script do nó raiz (primeiro bloco [node ...] da cena)."""
    bloco, vistos = [], 0
    for l in texto.split("\n"):
        if l.startswith("[node "):
            vistos += 1
            if vistos > 1:
                break
        elif vistos == 1:
            bloco.append(l)
    m = re.search(r'script = ExtResource\("([^"]+)"\)', "\n".join(bloco))
    return m.group(1) if m else None


def variacoes_conhecidas():
    nomes = set()
    for rel in ("core/utilities/tema_nexus.gd", "core/utilities/tema_variacoes.gd"):
        caminho = os.path.join(RAIZ, rel)
        if os.path.exists(caminho):
            txt = ler(caminho)
            nomes |= set(re.findall(r'set_type_variation\("(\w+)"', txt))
            # variações criadas em laço ou por tabela: qualquer literal com prefixo de tipo de variação
            nomes |= set(re.findall(r'"((?:Painel|Barra|Botao|Rotulo|Campo|Texto|Richo)\w*)"', txt))
            for estilo, tam, mono in re.findall(r'\["(\w*)", (\d+), (true|false)\]', txt):
                nome = "Rotulo" + estilo + (tam if int(tam) > 0 else "")
                if mono == "true" and estilo != "Mono":
                    nome += "Mono"
                nomes.add(nome)
    return nomes


CONHECIDAS = variacoes_conhecidas()
for p, t in cenas.items():
    ids = dict((m.group(2), m.group(1)) for m in re.finditer(r'\[ext_resource .*?path="([^"]+)".*?id="([^"]+)"', t))
    unicos = set(n for n, u in nos_da_cena(t) if u)
    sid = script_da_raiz(t)
    if sid in ids:
        alvo = os.path.join(RAIZ, ids[sid][6:])
        if alvo in scripts:
            for n, bruta, cod in infos[alvo]["linhas"]:
                if "@onready" in cod or "get_node" in cod:
                    for ref in re.findall(r"%([A-Za-z_]\w*)", cod):
                        if ref not in unicos and ref[0].isupper():
                            erro(alvo, n, "%%%s não é um nó único (unique_name_in_owner) da cena %s" % (ref, os.path.relpath(p, RAIZ)))
    for n, l in enumerate(t.split("\n"), 1):
        m = re.match(r'theme_type_variation = &"(\w+)"', l)
        if m and m.group(1) not in CONHECIDAS:
            erro(p, n, "type variation '%s' não existe no Theme (TemaNexus/TemaVariacoes)" % m.group(1))
for p in scripts:
    for n, bruta, cod in infos[p]["linhas"]:
        if "theme_type_variation" in bruta and "=" in bruta:
            for nome in re.findall(r'&"(\w+)"', bruta):
                if nome not in CONHECIDAS:
                    erro(p, n, "type variation '%s' não existe no Theme (TemaNexus/TemaVariacoes)" % nome)

# ------------------------------------------------------------------ ordem dos autoloads na inicialização
def corpo_da_funcao(caminho, nome_func):
    """Linhas de código (n, cod) do corpo de uma função de nível superior do script."""
    saida, dentro = [], False
    for n, bruta, cod in infos[caminho]["linhas"]:
        if re.match(r"^(static\s+)?func\s+%s\b" % re.escape(nome_func), cod):
            dentro = True
            continue
        if not dentro or bruta.strip() == "" or cod.strip() == "":
            continue
        if not bruta.startswith(("\t", " ")):
            break
        saida.append((n, cod))
    return saida


def funcoes_da_inicializacao(caminho):
    """Funções do mesmo script alcançadas a partir de _init/_ready (até 3 níveis de chamada)."""
    funcs = infos[caminho]["funcs"]
    alcancadas = {nome: 0 for nome in ("_init", "_ready") if nome in funcs}
    fila = list(alcancadas)
    while fila:
        atual = fila.pop(0)
        if alcancadas[atual] >= 3:
            continue
        for n, cod in corpo_da_funcao(caminho, atual):
            for ch in re.findall(r"(?<![\w\.])(\w+)\s*\(", cod):
                if ch in funcs and ch not in alcancadas:
                    alcancadas[ch] = alcancadas[atual] + 1
                    fila.append(ch)
    return list(alcancadas)


ordem_autoloads = list(autoloads)
for nome_a, caminho_a in autoloads.items():
    if caminho_a not in infos:
        continue
    for nome_func in funcoes_da_inicializacao(caminho_a):
        for n, cod in corpo_da_funcao(caminho_a, nome_func):
            for ref in set(re.findall(r"\b([A-Z]\w+)\.\w+", cod)):
                if ref == nome_a or ref not in autoloads or autoloads[ref] not in infos:
                    continue
                depois = ordem_autoloads.index(ref) > ordem_autoloads.index(nome_a)
                if depois and "_ready" in infos[autoloads[ref]]["funcs"]:
                    erro(caminho_a, n, "autoload '%s' usa '%s' durante a inicialização (%s), mas '%s' é instanciado DEPOIS e ainda não rodou o próprio _ready: "
                         "reordene no project.godot ou adie o uso (call_deferred/sinal)" % (nome_a, ref, nome_func, ref))

# ------------------------------------------------------------------ uids .gd.uid
for p in scripts:
    if not os.path.exists(p + ".uid"):
        pass  # normal: o editor gera na primeira abertura

print("scripts: %d | cenas: %d | autoloads: %d | classes: %d" % (len(scripts), len(cenas), len(autoloads), len(classes)))
for a in avisos:
    print("AVISO", a)
for e in erros:
    print("ERRO ", e)
print("TOTAL: %d erros, %d avisos" % (len(erros), len(avisos)))
sys.exit(1 if erros else 0)
