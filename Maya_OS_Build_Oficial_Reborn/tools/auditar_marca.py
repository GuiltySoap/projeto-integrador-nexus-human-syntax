#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Auditoria de marca do rebranding "Maya Human Syntax" (jogo: Maya Human Syntax, IA: Maya, sistema: HumaxOS).

Procura "nexus", "NEXUS", "Nexus", "NEXUS OS" e o apelido "Nex" em todo o projeto, classifica cada ocorrência e
termina com código 1 quando sobra texto visível ao jogador com a identidade antiga ou uma ocorrência não classificada.
Também confere o uso correto das marcas novas nos textos visíveis (grafia "HumaxOS", gênero dos artigos).

Categorias (cada ocorrência cai em exatamente uma):
  Visível        texto que chega ao jogador (rótulo, tooltip, mensagem, e-mail, página, nome de arquivo, comando, URL...)
  Interno        classe, nó, variável, caminho de recurso (res://...) e outros identificadores do código
  InputMap       ação de entrada (nexus_menu_iniciar, ...), preservada por compatibilidade
  Persistência   pasta de salvamento (user://nexus_os...), preservada para os saves antigos
  ID             identificador de dados (id do contato "nexus", d1_nexus_01, flag conversa_lida:nexus, ...)
  Compatibilidade  uso intencional do nome antigo para aceitar saves/entradas antigos (linha marcada com "marca-legada")
  Comentário     comentário ou docstring de código
  Teste / Ferramenta / Documentação / Legado   ocorrência fora do jogo (só informativa, exceto texto de teste desatualizado)

Uso (a partir da pasta do projeto):
  python3 -I tools/auditar_marca.py                       resumo; código de saída 1 se houver pendência
  python3 -I tools/auditar_marca.py --tabela              imprime a tabela completa em Markdown
  python3 -I tools/auditar_marca.py --base PASTA          audita outra pasta (por exemplo, a cópia anterior ao rebranding)
  python3 -I tools/auditar_marca.py --escrever docs/13_auditoria_de_marca.md --base PASTA_ANTES
"""
import argparse
import difflib
import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PADRAO = re.compile(r"nexus|\bnex\b", re.IGNORECASE)
MARCADOR_LEGADO = "marca-legada"

ACOES_INPUTMAP = {
    "nexus_menu_iniciar", "nexus_tela_cheia", "nexus_painel_debug", "nexus_proxima_janela",
    "nexus_fechar_janela", "nexus_minimizar_janela", "nexus_abrir_terminal", "nexus_forcar_desativar",
}
ARQUIVOS_NARRATIVOS = ("conversas.json", "dias.json", "emails.json", "finais.json", "calendario.json", "paginas_web.json", "vfs_inicial.json", "processos.json", "catalogo_apps.json")
PASTAS_IGNORADAS = {".godot", ".git", "__pycache__", "_saida"}
# O relatório do rebranding, a auditoria gerada e esta própria ferramenta falam do nome antigo por definição: ficam fora da varredura
# (senão cada nova geração da tabela se contaria a si mesma).
ARQUIVOS_DESTA_AUDITORIA = {"docs/12_rebranding_maya_human_syntax.md", "docs/13_auditoria_de_marca.md", "tools/auditar_marca.py"}
EXT_TEXTO = {".gd", ".tscn", ".tres", ".json", ".cfg", ".svg", ".import", ".godot", ".py", ".md", ".c", ".h"}

RE_ID = re.compile(r"[a-z0-9_:]*nexus[a-z0-9_:]*")
RE_INTERATIVO = re.compile(r"scan_nexus|destroy_nexus|nexus://|/sistema/nexus|\.nexus\b|nexus_audit\.log|NEXUSCore\.exe|nexus_\w+\.exe|@nexus|nexus\.os", re.IGNORECASE)

# Verificações de uso das marcas novas (só em texto visível)
LINT = [
    (re.compile(r"\bHumax[ \-]OS\b|\bHumaxos\b|\bHUMAX OS\b|\bHumax\-os\b|\bhumax os\b"), "grafia: use exatamente HumaxOS"),
    (re.compile(r"\b(a|A|da|Da|pela|Pela|à|à|na|Na|uma|Uma) HumaxOS\b"), "HumaxOS é masculino (o/do/no/ao/um)"),
    (re.compile(r"\b(o|O|do|Do|no|No|ao|Ao|pelo|Pelo|um|Um) (Maya|MAYA)\b"), "Maya é feminina (a/da/na/à/uma)"),
    (re.compile(r"\b(a|A|da|Da|pela|Pela|à|na|Na) MAYA\b"), "em prosa use 'Maya' (MAYA só em etiquetas e títulos)"),
]


class Ocorrencia:
    def __init__(self, arquivo, linha, trecho, categoria, tipo, papel):
        self.arquivo = arquivo
        self.linha = linha
        self.trecho = trecho
        self.categoria = categoria
        self.tipo = tipo
        self.papel = papel

    @property
    def pendente(self):
        return self.categoria in ("Visível", "Não classificada")


def papel_do_arquivo(rel):
    partes = rel.split("/")
    if any(p in PASTAS_IGNORADAS for p in partes):
        return None
    if rel in ARQUIVOS_DESTA_AUDITORIA:
        return None
    if rel.startswith("backend/"):
        return "legado"
    if rel.startswith("tests/"):
        return "teste"
    if rel.startswith("tools/"):
        return "ferramenta"
    if rel == "README.md" or rel.startswith("docs/"):
        return "documentacao"
    if rel == "project.godot" or rel.startswith(("core/", "features/", "shared/", "addons/")):
        return "jogo"
    return None


def listar(raiz):
    for dp, dn, fn in os.walk(raiz):
        dn[:] = sorted(d for d in dn if d not in PASTAS_IGNORADAS)
        for f in sorted(fn):
            caminho = os.path.join(dp, f)
            rel = os.path.relpath(caminho, raiz).replace(os.sep, "/")
            ext = os.path.splitext(f)[1].lower()
            if rel == "project.godot" or ext in EXT_TEXTO:
                if papel_do_arquivo(rel):
                    yield rel, caminho


def ler(caminho):
    try:
        with open(caminho, encoding="utf-8", newline="") as f:
            return f.read().splitlines()
    except (UnicodeDecodeError, OSError):
        return []


# ------------------------------------------------------------------ classificação por token
DELIMITADORES = " \t[](){}<>\"',;"
RE_IDENT_CAMEL = re.compile(r"[A-Za-z0-9_]+Nexus|Nexus[A-Za-z0-9_]+")


def token_em(texto, pos):
    """A "palavra" (sem espaços nem delimitadores) que contém a posição `pos` de `texto`."""
    ini = pos
    while ini > 0 and texto[ini - 1] not in DELIMITADORES:
        ini -= 1
    fim = pos
    while fim < len(texto) and texto[fim] not in DELIMITADORES:
        fim += 1
    return texto[ini:fim].strip(".,:;!?…`*")


def classificar_token(t):
    """Categoria de um token (palavra) que contém a marca antiga, dentro de uma string ou de um valor de dados."""
    if t.startswith(("res://", "uid://")):
        return "Interno"
    if t.startswith("user://nexus_os"):
        return "Persistência"
    if t in ACOES_INPUTMAP:
        return "InputMap"
    if RE_INTERATIVO.search(t):
        return "Visível"            # comando, URL, nome de arquivo ou de processo: o jogador vê e digita (tipo Interativa)
    if t.endswith((".tscn", ".gd", ".tres", ".uid", ".import", ".svg")):
        return "Interno"            # nome de arquivo do projeto citado em mensagem de desenvolvimento
    if RE_IDENT_CAMEL.search(t):
        return "Interno"            # classe ou nó (TemaNexus, WidgetNexus, ...)
    if RE_ID.fullmatch(t):
        return "ID"
    return "Visível"


def tipo_da_pendencia(rel, trecho):
    """Tipo usado na tabela: Narrativa, Interativa ou Visível."""
    if RE_INTERATIVO.search(trecho):
        return "Interativa"
    if os.path.basename(rel) in ARQUIVOS_NARRATIVOS:
        return "Narrativa"
    return "Visível"


def varrer_linha_gd(linha):
    """Retorna (literais, inicio_do_comentario) de uma linha de GDScript: literais = [(ini, fim, conteudo)]."""
    literais = []
    comentario = None
    i = 0
    n = len(linha)
    while i < n:
        c = linha[i]
        if c == "#":
            comentario = i
            break
        if c in "\"'":
            ini = i
            aspa = c
            i += 1
            while i < n:
                if linha[i] == "\\":
                    i += 2
                    continue
                if linha[i] == aspa:
                    break
                i += 1
            literais.append((ini, min(i, n - 1), linha[ini + 1:i]))
        i += 1
    return literais, comentario


def ocorrencias_gd(rel, linhas, papel):
    saida = []
    for n, linha in enumerate(linhas, 1):
        if not PADRAO.search(linha):
            continue
        literais, comentario = varrer_linha_gd(linha)
        legado = comentario is not None and MARCADOR_LEGADO in linha[comentario:]
        for m in PADRAO.finditer(linha):
            pos = m.start()
            lit = next((l for l in literais if l[0] < pos <= l[1]), None)
            if comentario is not None and pos >= comentario:
                cat, trecho = ("Compatibilidade" if legado else "Comentário"), linha[comentario:].strip()[:90]
            elif lit is not None:
                cat = "Compatibilidade" if legado else classificar_token(token_em(lit[2], pos - lit[0] - 1))
                trecho = lit[2]
            else:
                cat, trecho = ("Compatibilidade" if legado else "Interno"), linha.strip()[:90]
            saida.append(Ocorrencia(rel, n, trecho, cat, tipo_da_pendencia(rel, trecho) if cat == "Visível" else cat, papel))
    return saida


def ocorrencias_tscn(rel, linhas, papel):
    saida = []
    for n, linha in enumerate(linhas, 1):
        if not PADRAO.search(linha):
            continue
        if linha.startswith(("[ext_resource", "[node", "[sub_resource", "[gd_scene", "[connection")) or "ExtResource(" in linha or "instance=" in linha:
            saida.append(Ocorrencia(rel, n, linha.strip()[:90], "Interno", "Interno", papel))
            continue
        m = re.match(r'^[\w/\.:]+\s*=\s*"(.*)"\s*$', linha)
        if m:
            for achado in PADRAO.finditer(m.group(1)):
                cat = classificar_token(token_em(m.group(1), achado.start()))
                saida.append(Ocorrencia(rel, n, m.group(1), cat, tipo_da_pendencia(rel, m.group(1)) if cat == "Visível" else cat, papel))
        else:
            saida.append(Ocorrencia(rel, n, linha.strip()[:90], "Interno", "Interno", papel))
    return saida


RE_JSON_CHAVE = re.compile(r'^\s*"((?:[^"\\]|\\.)*)"\s*:\s*(.*)$')


def ocorrencias_json(rel, linhas, papel):
    saida = []
    for n, linha in enumerate(linhas, 1):
        if not PADRAO.search(linha):
            continue
        m = RE_JSON_CHAVE.match(linha)
        ini_valor = linha.index(m.group(2), linha.index(m.group(1)) + len(m.group(1))) if m and m.group(2) else len(linha)
        for achado in PADRAO.finditer(linha):
            cat = classificar_token(token_em(linha, achado.start()))
            na_chave = m is not None and achado.start() < ini_valor
            trecho = m.group(1) if na_chave else (linha.strip().rstrip(",").split(":", 1)[-1].strip().strip('"') if m else linha.strip().rstrip(",").strip('"'))
            saida.append(Ocorrencia(rel, n, trecho, cat, tipo_da_pendencia(rel, trecho) if cat == "Visível" else cat, papel))
    return saida


def ocorrencias_outro(rel, linhas, papel):
    saida = []
    rotulo = {"teste": "Teste", "ferramenta": "Ferramenta", "documentacao": "Documentação", "legado": "Legado", "jogo": "Interno"}[papel]
    for n, linha in enumerate(linhas, 1):
        for _ in PADRAO.finditer(linha):
            saida.append(Ocorrencia(rel, n, linha.strip()[:90], rotulo, rotulo, papel))
    return saida


def auditar(raiz):
    """Todas as ocorrências da marca antiga em `raiz`."""
    todas = []
    for rel, caminho in listar(raiz):
        papel = papel_do_arquivo(rel)
        linhas = ler(caminho)
        ext = os.path.splitext(rel)[1].lower()
        if papel in ("jogo", "teste") and ext == ".gd":
            todas += ocorrencias_gd(rel, linhas, papel)
        elif papel in ("jogo", "teste") and ext == ".tscn":
            todas += ocorrencias_tscn(rel, linhas, papel)
        elif papel in ("jogo", "teste") and ext == ".json":
            todas += ocorrencias_json(rel, linhas, papel)
        elif rel == "project.godot":
            for n, linha in enumerate(linhas, 1):
                for m in PADRAO.finditer(linha):
                    lit = re.search(r'="(.*)"', linha)
                    interno = "tema_nexus_base.tres" in linha
                    if linha.startswith("config/name="):
                        cat = "Visível"     # o nome do projeto aparece na janela, no editor e no executável exportado
                    elif linha.startswith("config/custom_user_dir_name"):
                        cat = "Compatibilidade"   # fixa a pasta dos saves antigos (o editor reescreve o arquivo e descarta comentários)
                    elif interno:
                        cat = "Interno"
                    else:
                        cat = classificar_token(token_em(lit.group(1), 0) if lit else linha)
                    todas.append(Ocorrencia(rel, n, linha.strip()[:90], cat, "Interno" if interno else cat, papel))
        else:
            todas += ocorrencias_outro(rel, linhas, papel)
    vistas = set()
    unicas = []
    for o in todas:   # uma linha por literal: "/sistema/nexus/core.nexus" tem duas ocorrências na mesma string
        chave = (o.arquivo, o.linha, o.trecho, o.categoria)
        if chave not in vistas:
            vistas.add(chave)
            unicas.append(o)
    return unicas


# ------------------------------------------------------------------ verificação das marcas novas
def textos_visiveis(raiz):
    """(arquivo, linha, texto) dos literais de jogo (.gd, .tscn, .json) para conferir o uso de HumaxOS e Maya."""
    for rel, caminho in listar(raiz):
        if papel_do_arquivo(rel) != "jogo":
            continue
        ext = os.path.splitext(rel)[1].lower()
        for n, linha in enumerate(ler(caminho), 1):
            if ext == ".gd":
                literais, _ = varrer_linha_gd(linha)
                for _, _, conteudo in literais:
                    yield rel, n, conteudo
            elif ext in (".tscn", ".json"):
                yield rel, n, linha


def lint_marcas(raiz):
    achados = []
    for rel, n, texto in textos_visiveis(raiz):
        for padrao, mensagem in LINT:
            m = padrao.search(texto)
            if m:
                achados.append((rel, n, m.group(0), mensagem))
    return achados


# ------------------------------------------------------------------ alterações linha a linha (antes -> depois)
RE_TOKEN = re.compile(r"\s+|\w+|[^\w\s]", re.UNICODE)
LIMITE_CELULA = 230


def trechos_alterados(a, b, contexto=6):
    """Mostra só o que mudou entre duas linhas: [(trecho_antes, trecho_depois)], com `contexto` tokens ao redor de cada mudança."""
    ta, tb = RE_TOKEN.findall(a), RE_TOKEN.findall(b)
    ops = [op for op in difflib.SequenceMatcher(None, ta, tb, autojunk=False).get_opcodes() if op[0] != "equal"]
    grupos = []
    for op in ops:
        if grupos and op[1] - grupos[-1][-1][2] <= 2 * contexto:
            grupos[-1].append(op)
        else:
            grupos.append([op])
    ant, dep = [], []
    for g in grupos:
        i1, i2, j1, j2 = g[0][1], g[-1][2], g[0][3], g[-1][4]
        ia, ja = max(0, i1 - contexto), max(0, j1 - contexto)
        fa, fb = min(len(ta), i2 + contexto), min(len(tb), j2 + contexto)
        ant.append(("…" if ia > 0 else "") + "".join(ta[ia:fa]).strip() + ("…" if fa < len(ta) else ""))
        dep.append(("…" if ja > 0 else "") + "".join(tb[ja:fb]).strip() + ("…" if fb < len(tb) else ""))
    return " ".join(ant), " ".join(dep)


def cortar(txt):
    return txt if len(txt) <= LIMITE_CELULA else txt[:LIMITE_CELULA - 1] + "…"


def pares_do_bloco(antigas, novas):
    """Liga cada linha antiga de um bloco substituído à linha nova mais parecida (ou a nenhuma). Blocos do mesmo tamanho: em ordem."""
    if len(antigas) == len(novas):
        return [(i, j) for (i, _), (j, _) in zip(antigas, novas)]
    usadas, pares = set(), []
    for i, a in antigas:
        melhor, nota = None, 0.0
        for j, b in novas:
            if j in usadas:
                continue
            r = difflib.SequenceMatcher(None, a, b, autojunk=False).ratio()
            if r > nota:
                melhor, nota = j, r
        if melhor is not None and nota >= 0.5:
            usadas.add(melhor)
        else:
            melhor = None
        pares.append((i, melhor))
    return pares


def comparar_arquivo(antigas, novas):
    """(trocas, removidas, novas_linhas): trocas = [(n_antigo, n_novo)], removidas = [n_antigo] só das linhas que citavam a marca."""
    trocas, removidas, qtd_novas = [], [], 0
    for tag, i1, i2, j1, j2 in difflib.SequenceMatcher(None, antigas, novas, autojunk=False).get_opcodes():
        if tag == "equal":
            continue
        velhas = [(i, antigas[i]) for i in range(i1, i2)]
        novas_b = [(j, novas[j]) for j in range(j1, j2)]
        if tag == "insert":
            qtd_novas += len(novas_b)
            continue
        if tag == "delete":
            removidas += [i + 1 for i, a in velhas if PADRAO.search(a)]
            continue
        usadas = set()
        for i, j in pares_do_bloco(velhas, novas_b):
            if not PADRAO.search(antigas[i]):
                if j is not None:
                    usadas.add(j)
                continue
            if j is None:
                removidas.append(i + 1)
            else:
                usadas.add(j)
                trocas.append((i + 1, j + 1))
        qtd_novas += len([j for j, _ in novas_b if j not in usadas])
    return trocas, removidas, qtd_novas


def alteracoes(base, raiz, ocs_antes):
    """Compara a cópia anterior (`base`) com o projeto atual (`raiz`).
    Devolve (linhas, resumo): linhas = [(arquivo, antigo, novo, antes, depois, categoria, acao, papel)];
    resumo = [(arquivo, papel, linhas_trocadas, linhas_removidas, linhas_novas, estado)]."""
    cat_antes = {}
    for o in ocs_antes:
        chave = o.tipo if o.categoria == "Visível" else o.categoria
        lista = cat_antes.setdefault((o.arquivo, o.linha), [])
        if chave not in lista:
            lista.append(chave)
    arquivos = {}
    for rel, caminho in listar(raiz):
        arquivos[rel] = [caminho, None]
    for rel, caminho in listar(base):
        arquivos.setdefault(rel, [None, None])[1] = caminho
    linhas, resumo = [], []
    for rel in sorted(arquivos):
        novo, antigo = arquivos[rel]
        papel = papel_do_arquivo(rel)
        if antigo is None:
            resumo.append((rel, papel, 0, 0, len(ler(novo)), "novo"))
            continue
        if novo is None:
            resumo.append((rel, papel, 0, 0, 0, "removido"))
            continue
        antigas, novas = ler(antigo), ler(novo)
        if antigas == novas:
            continue
        trocas, removidas, qtd_novas = comparar_arquivo(antigas, novas)
        resumo.append((rel, papel, len(trocas), len(removidas), qtd_novas, "alterado"))
        if papel in ("jogo", "teste", "ferramenta"):
            for n_antigo, n_novo in trocas:
                a, b = trechos_alterados(antigas[n_antigo - 1], novas[n_novo - 1])
                acao = "Alterado" + ("; identificador preservado na mesma linha" if PADRAO.search(novas[n_novo - 1]) else "")
                linhas.append((rel, n_antigo, n_novo, a, b, " + ".join(cat_antes.get((rel, n_antigo), ["—"])), acao, papel))
            for n_antigo in removidas:
                linhas.append((rel, n_antigo, None, cortar(antigas[n_antigo - 1].strip()), "(linha reescrita ou removida)", " + ".join(cat_antes.get((rel, n_antigo), ["—"])), "Reescrito", papel))
    return linhas, resumo


def tabela_alteracoes(linhas):
    saida = ["| Arquivo | Linha (antes → depois) | Antes | Depois | Categoria antes | Ação |", "|---|---|---|---|---|---|"]
    for rel, n_antigo, n_novo, a, b, cat, acao, _ in linhas:
        pos = "%d → %d" % (n_antigo, n_novo) if n_novo and n_novo != n_antigo else str(n_antigo)
        saida.append("| `%s` | %s | %s | %s | %s | %s |" % (rel, pos, esc(cortar(a)), esc(cortar(b)), cat, acao))
    return "\n".join(saida)


def tabela_resumo_arquivos(resumo):
    saida = ["| Arquivo | Papel | Linhas com a marca trocadas | Linhas reescritas | Linhas novas | Estado |", "|---|---|---|---|---|---|"]
    for rel, papel, trocadas, removidas, novas, estado in resumo:
        saida.append("| `%s` | %s | %d | %d | %d | %s |" % (rel, papel or "—", trocadas, removidas, novas, estado))
    return "\n".join(saida)


# ------------------------------------------------------------------ saída
ACAO_ANTES = {"Visível": "Substituir", "Narrativa": "Substituir", "Interativa": "Atualizar com os consumidores", "Interno": "Preservar",
              "InputMap": "Preservar", "Persistência": "Preservar", "ID": "Preservar", "Compatibilidade": "Manter (compat.)",
              "Comentário": "Atualizar a prosa", "Teste": "Atualizar a expectativa", "Ferramenta": "Atualizar a prosa",
              "Documentação": "Atualizar a prosa", "Legado": "Fora do escopo"}
ACAO_DEPOIS = {"Visível": "PENDENTE", "Narrativa": "PENDENTE", "Interativa": "PENDENTE", "Interno": "Preservado", "InputMap": "Preservado",
               "Persistência": "Preservado", "ID": "Preservado", "Compatibilidade": "Mantido (compat.)", "Comentário": "Comentário (identificador citado)",
               "Teste": "Teste (identificador citado)", "Ferramenta": "Ferramenta (identificador citado)",
               "Documentação": "Documento (identificador citado)", "Legado": "Fora do escopo", "Não classificada": "PENDENTE"}
VISIVEL = {"Visível": "Sim", "Narrativa": "Sim", "Interativa": "Sim"}
PODE_ALTERAR = {"Visível": "Sim", "Narrativa": "Sim", "Interativa": "Sim, junto com os consumidores", "Interno": "Não (preservar)",
                "InputMap": "Não (preservar)", "Persistência": "Não (preservar)", "ID": "Não (preservar)", "Compatibilidade": "Mantida",
                "Comentário": "Sim (prosa)", "Teste": "Sim (expectativa)", "Ferramenta": "Sim (prosa)", "Documentação": "Sim (prosa)", "Legado": "Fora do escopo"}
RISCO = {"Visível": "Baixo", "Narrativa": "Baixo", "Interativa": "Alto", "Interno": "Alto se mudar", "InputMap": "Alto se mudar",
         "Persistência": "Crítico se mudar", "ID": "Alto se mudar", "Compatibilidade": "Baixo", "Comentário": "Nenhum", "Teste": "Baixo",
         "Ferramenta": "Nenhum", "Documentação": "Nenhum", "Legado": "Nenhum"}


def esc(txt):
    return txt.replace("|", "\\|").replace("`", "'")


def tabela_antes(ocs):
    linhas = ["| Ocorrência | Arquivo:linha | Tipo | Visível? | Pode ser alterada? | Risco |", "|---|---|---|---|---|---|"]
    for o in ocs:
        linhas.append("| %s | `%s:%d` | %s | %s | %s | %s |" % (esc(o.trecho[:80]), o.arquivo, o.linha, o.tipo, VISIVEL.get(o.tipo, "Não"),
                                                                    PODE_ALTERAR.get(o.categoria if o.categoria != "Visível" else o.tipo, "—"), RISCO.get(o.tipo, "—")))
    return "\n".join(linhas)


def tabela_depois(ocs):
    linhas = ["| Arquivo | Linha | Ocorrência | Categoria | Ação |", "|---|---|---|---|---|"]
    for o in ocs:
        linhas.append("| `%s` | %d | %s | %s | %s |" % (o.arquivo, o.linha, esc(o.trecho[:80]), o.categoria, ACAO_DEPOIS.get(o.categoria, "—")))
    return "\n".join(linhas)


def resumo(ocs):
    contagem = {}
    for o in ocs:
        chave = o.categoria if o.categoria != "Visível" else o.tipo
        contagem.setdefault(chave, {"jogo": 0, "teste": 0, "ferramenta": 0, "documentacao": 0, "legado": 0})
        contagem[chave][o.papel] += 1
    return contagem


def tabela_resumo(ocs):
    c = resumo(ocs)
    linhas = ["| Categoria | Jogo | Testes | Ferramentas | Documentos | Protótipo C | Total |", "|---|---|---|---|---|---|---|"]
    for chave in sorted(c, key=lambda k: -sum(c[k].values())):
        v = c[chave]
        linhas.append("| %s | %d | %d | %d | %d | %d | %d |" % (chave, v["jogo"], v["teste"], v["ferramenta"], v["documentacao"], v["legado"], sum(v.values())))
    total = [sum(c[k][p] for k in c) for p in ("jogo", "teste", "ferramenta", "documentacao", "legado")]
    linhas.append("| **Total** | **%d** | **%d** | **%d** | **%d** | **%d** | **%d** |" % (*total, sum(total)))
    return "\n".join(linhas)


CLASSES_DO_PEDIDO = ["Texto visível", "Não resolvida", "Interna", "Compatibilidade", "Persistência", "Teste",
                     "Ferramenta (fora do jogo)", "Documentação (fora do jogo)", "Protótipo C (fora do jogo)"]


def classe_do_pedido(o):
    """As classes que o pedido de rebranding usa para a tabela de ocorrências restantes.
    Teste = ocorrência em tests/ que cita identificador preservado ou serve de fixture de um salvamento antigo."""
    if o.categoria in ("Visível", "Não classificada"):
        return "Texto visível" if o.categoria == "Visível" else "Não resolvida"
    if o.papel == "teste":
        return "Teste"
    if o.papel == "jogo":
        if o.categoria == "Compatibilidade":
            return "Compatibilidade"
        if o.categoria == "Persistência":
            return "Persistência"
        return "Interna"            # Interno, ID, InputMap e comentários que citam identificadores
    return {"ferramenta": "Ferramenta (fora do jogo)", "documentacao": "Documentação (fora do jogo)", "legado": "Protótipo C (fora do jogo)"}[o.papel]


def tabela_classes(antes, depois):
    """Quantas ocorrências há em cada classe do pedido, antes (se houver cópia anterior) e depois."""
    def contar(ocs):
        c = {k: 0 for k in CLASSES_DO_PEDIDO}
        for o in ocs or []:
            c[classe_do_pedido(o)] += 1
        return c
    a, d = contar(antes), contar(depois)
    cab = "| Classe | Antes | Depois |\n|---|---|---|\n" if antes is not None else "| Classe | Depois |\n|---|---|\n"
    linhas = []
    for k in CLASSES_DO_PEDIDO:
        linhas.append("| %s | %d | %d |" % (k, a[k], d[k]) if antes is not None else "| %s | %d |" % (k, d[k]))
    total = "| **Total** | **%d** | **%d** |" % (sum(a.values()), sum(d.values())) if antes is not None else "| **Total** | **%d** |" % sum(d.values())
    return cab + "\n".join(linhas + [total])


def montar_documento(raiz, base):
    depois = auditar(raiz)
    lint = lint_marcas(raiz)
    texto = ["# 20. Auditoria de marca (rebranding Maya Human Syntax)", "",
             "> Documento gerado por `tools/auditar_marca.py` (não edite à mão). A tabela **Antes** vem da cópia do projeto anterior ao rebranding e a tabela **Depois** do projeto atual. "
             "Cada linha é uma ocorrência de `nexus`, `NEXUS`, `Nexus`, `NEXUS OS` ou do apelido `Nex`. Para reproduzir: `python3 -I tools/auditar_marca.py --escrever docs/13_auditoria_de_marca.md --base <pasta anterior>`.", ""]
    antes_todas = auditar(base) if base else None
    texto += ["## Resumo pelas classes do pedido", "",
              "Cada ocorrência cai numa classe só. **Texto visível** e **Não resolvida** são as pendências: devem ser **0** depois das mudanças. "
              "**Interna** reúne classes, nós, caminhos de recurso, IDs, flags, ações do InputMap e comentários que citam esses identificadores; "
              "**Teste** são ocorrências em `tests/` (fixtures de salvamentos antigos e identificadores preservados). Detalhes por categoria nas tabelas abaixo.", "",
              tabela_classes(antes_todas, depois), ""]
    if base:
        antes = antes_todas
        jogo_antes = [o for o in antes if o.papel in ("jogo",)]
        suporte_antes = [o for o in antes if o.papel in ("teste", "ferramenta")]
        texto += ["## Antes das mudanças", "", "### Resumo (todas as pastas)", "", tabela_resumo(antes), "",
                  "### Tabela do jogo (project.godot, core/, features/, shared/)", "", tabela_antes(jogo_antes), "",
                  "### Tabela dos testes e das ferramentas (tests/, tools/)", "", tabela_antes(suporte_antes), ""]
        linhas, resumo_arq = alteracoes(base, raiz, antes)
        texto += ["## Alterações aplicadas (linha a linha)", "",
                  "Cada linha abaixo citava a marca antiga e foi trocada. A coluna **Antes**/**Depois** mostra só o trecho que mudou (com um pouco de contexto); "
                  "as demais ocorrências, que foram preservadas de propósito, estão em **Depois das mudanças**. "
                  "Os números de linha são os do arquivo antes e depois da mudança.", "",
                  "### Resumo por arquivo (todos os arquivos que mudaram)", "", tabela_resumo_arquivos(resumo_arq), "",
                  "### Jogo (project.godot, core/, features/, shared/)", "", tabela_alteracoes([l for l in linhas if l[7] == "jogo"]), "",
                  "### Testes e ferramentas (tests/, tools/)", "", tabela_alteracoes([l for l in linhas if l[7] in ("teste", "ferramenta")]), ""]
    jogo_depois = [o for o in depois if o.papel == "jogo"]
    suporte_depois = [o for o in depois if o.papel in ("teste", "ferramenta")]
    outros = [o for o in depois if o.papel in ("documentacao", "legado")]
    texto += ["## Depois das mudanças", "", "### Resumo (todas as pastas)", "", tabela_resumo(depois), "",
              "### Tabela do jogo (project.godot, core/, features/, shared/)", "", tabela_depois(jogo_depois), "",
              "### Tabela dos testes e das ferramentas (tests/, tools/)", "",
              "As linhas de categoria **Compatibilidade** são os testes que fornecem um salvamento da marca antiga (ou confirmam que a marca antiga não aparece) e precisam citar o nome antigo.", "",
              tabela_depois(suporte_depois), "",
              "### Documentos e protótipo C", "",
              "Só as ocorrências que citam identificadores preservados, histórico de relatórios anteriores e o protótipo `backend/` (não faz parte do jogo). "
              "`docs/12_rebranding_maya_human_syntax.md`, este documento e `tools/auditar_marca.py` ficam fora da varredura (falam do nome antigo por definição). Por arquivo:", "", "| Arquivo | Ocorrências | Categoria |", "|---|---|---|"]
    por_arquivo = {}
    for o in outros:
        por_arquivo.setdefault((o.arquivo, o.categoria), 0)
        por_arquivo[(o.arquivo, o.categoria)] += 1
    for (arq, cat), qtd in sorted(por_arquivo.items()):
        texto.append("| `%s` | %d | %s |" % (arq, qtd, cat))
    texto += ["", "### Uso das marcas novas", "", "Verificação automática de HumaxOS (grafia e gênero) e Maya/MAYA nos textos visíveis: **%s**." % ("nenhum problema" if not lint else "%d problema(s)" % len(lint))]
    for rel, n, achado, msg in lint:
        texto.append("- `%s:%d`: «%s» — %s" % (rel, n, achado, msg))
    pend = [o for o in depois if o.pendente]
    texto += ["", "### Pendências do jogo", "", "Ocorrências visíveis ou não classificadas no jogo e nos testes: **%d**." % len(pend)]
    for o in pend:
        texto.append("- `%s:%d`: %s" % (o.arquivo, o.linha, o.trecho))
    return "\n".join(texto) + "\n"


def main():
    ap = argparse.ArgumentParser(description="Auditoria de marca (rebranding Maya Human Syntax).")
    ap.add_argument("--base", help="pasta a auditar no lugar do projeto (ex.: cópia anterior ao rebranding)")
    ap.add_argument("--tabela", action="store_true", help="imprime a tabela completa")
    ap.add_argument("--escrever", help="grava o documento de auditoria (Markdown) neste caminho")
    args = ap.parse_args()

    if args.escrever:
        caminho = args.escrever if os.path.isabs(args.escrever) else os.path.join(RAIZ, args.escrever)
        with open(caminho, "w", encoding="utf-8", newline="\n") as f:
            f.write(montar_documento(RAIZ, args.base))
        print("escrito", os.path.relpath(caminho, RAIZ))
        return 0

    raiz = os.path.abspath(args.base) if args.base else RAIZ
    ocs = auditar(raiz)
    lint = lint_marcas(raiz)
    if args.tabela:
        print(tabela_depois(ocs))
        print()
    print(tabela_resumo(ocs))
    print()
    print(tabela_classes(None, ocs))
    pend = [o for o in ocs if o.pendente]
    print()
    for o in pend:
        print("PENDENTE %s:%d  [%s]  %s" % (o.arquivo, o.linha, o.tipo, o.trecho))
    for rel, n, achado, msg in lint:
        print("MARCA    %s:%d  «%s» %s" % (rel, n, achado, msg))
    print("TOTAL: %d ocorrência(s) pendente(s), %d problema(s) no uso das marcas novas" % (len(pend), len(lint)))
    return 1 if (pend or lint) else 0


if __name__ == "__main__":
    sys.exit(main())
