#!/usr/bin/env python3
"""Contrato entre o backend em C e o jogo (§25 a §27), sem precisar da Godot.

O backend (backend/, compilado por `make backend`) é uma FERRAMENTA AUXILIAR de linha de comando que o jogo não executa; o que liga os dois
lados é o arquivo estado_jogo.json e o catálogo de escolhas. Este teste confere, rodando o binário de verdade (sempre com a lista de
argumentos, nunca por um shell):

  1. --choice <id>: formato do id, tamanho, caracteres, valor ausente, id duplicado, argumento desconhecido ou posicional, injeção de shell,
     id desconhecido e os códigos de saída de cada caso (backend/bk_common.h);
  2. estado_jogo.json: esquema versionado, UTF-8, escrita atômica (sem .tmp sobrando, arquivo anterior intacto quando a gravação falha),
     acúmulo entre execuções, --reset, limites 0..100 e recuperação de um arquivo corrompido;
  3. catálogo (backend/choices.json) x core/data/narrativa/conversas.json: os deltas de AUT/CON/DEP e o campo is_placeholder de cada escolha
     têm de bater nos dois lados (o jogo aplica o que está em conversas.json; o backend, o que está em choices.json);
  4. o código C não chama o shell nem usa funções sem limite, e os scripts do Godot não executam processos.

Modo `--integracao <pasta>`: confere o resultado do ciclo C -> Godot -> C (veja `make integracao` e tests/integracao_c/): o backend grava, o
Godot lê, valida, aplica e grava o MESMO formato, e o backend aceita o arquivo do Godot como ponto de partida.

Uso:  python3 -I tools/testar_backend.py [--binario caminho] [--integracao pasta]
Saída: "RESULTADO PY: N verificacoes, M falhas" e código de saída 0 só sem falhas.
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
EXE = ".exe" if os.name == "nt" else ""
BINARIO_PADRAO = RAIZ / "backend" / "output" / ("maya_backend" + EXE)
CATALOGO = RAIZ / "backend" / "choices.json"
CONVERSAS = RAIZ / "core" / "data" / "narrativa" / "conversas.json"

# Códigos de saída (backend/bk_common.h)
OK, ERR_ARG, ERR_ID_FORMATO, ERR_ID_DESCONHECIDO, ERR_IO, ERR_JSON, ERR_MEM, ERR_ESQUEMA, ERR_LIMITE = 0, 2, 3, 4, 5, 6, 7, 8, 9

METRICAS = ("autonomia", "conformidade", "dependencia")
INICIAIS = {"autonomia": 50, "conformidade": 50, "dependencia": 0}
CHAVES = ("schema_version", "choice_id", "status", "metrics", "timestamp", "is_placeholder")
RE_ID = re.compile(r"^[a-z][a-z0-9_]{0,47}$")
RE_STATUS = re.compile(r"^[a-z_]{1,32}$")
RE_TS = re.compile(r"^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])T([01]\d|2[0-3]):[0-5]\d:([0-5]\d|60)Z$")

_total = 0
_falhas = 0


def ok(condicao, descricao):
    global _total, _falhas
    _total += 1
    if not condicao:
        _falhas += 1
        print("FALHA", descricao)
    return bool(condicao)


def secao(titulo):
    print("==", titulo)


class Backend:
    def __init__(self, binario):
        self.binario = str(binario)

    def rodar(self, *args, cwd=None, timeout=30):
        """Executa o binário com a lista de argumentos (sem shell). Devolve (código, stdout, stderr)."""
        r = subprocess.run([self.binario, *map(str, args)], cwd=cwd, capture_output=True, timeout=timeout,
                           stdin=subprocess.DEVNULL, shell=False)
        return r.returncode, r.stdout.decode("utf-8", "replace"), r.stderr.decode("utf-8", "replace")


def validar_estado(dados):
    """Validador INDEPENDENTE do formato de estado_jogo.json (as mesmas regras de backend/bk_estado.h e de EstadoJogoBackend.validar)."""
    erros = []
    if not isinstance(dados, dict):
        return ["raiz não é objeto"]
    if dados.get("schema_version") != 1 or isinstance(dados.get("schema_version"), bool):
        erros.append("schema_version")
    escolha = dados.get("choice_id")
    if not isinstance(escolha, str) or (escolha != "" and not RE_ID.match(escolha)):
        erros.append("choice_id")
    if not isinstance(dados.get("status"), str) or not RE_STATUS.match(dados["status"]):
        erros.append("status")
    metricas = dados.get("metrics")
    if not isinstance(metricas, dict):
        erros.append("metrics")
    else:
        for nome in METRICAS:
            v = metricas.get(nome)
            if isinstance(v, bool) or not isinstance(v, (int, float)) or not (0 <= v <= 100):
                erros.append("metrics." + nome)
    carimbo = dados.get("timestamp")
    if not isinstance(carimbo, str) or (carimbo != "" and not RE_TS.match(carimbo)):
        erros.append("timestamp")
    if not isinstance(dados.get("is_placeholder"), bool):
        erros.append("is_placeholder")
    return erros


def ler_estado(caminho):
    bruto = Path(caminho).read_bytes()
    texto = bruto.decode("utf-8")  # UTF-8 estrito: lança erro se o arquivo não for UTF-8
    return json.loads(texto), texto, bruto


# ------------------------------------------------------------------ 1. argumentos
def testar_argumentos(b, tmp):
    secao("argumentos (--choice <id>)")
    cat = str(CATALOGO)
    codigo, saida, _ = b.rodar("--help")
    ok(codigo == OK and "--choice" in saida, "--help mostra a opção --choice e sai com 0")
    codigo, saida, _ = b.rodar("--version")
    ok(codigo == OK and saida.strip().startswith("maya_backend "), "--version sai com 0")
    codigo, saida, _ = b.rodar()
    ok(codigo == OK and "Iniciar Novo Jogo" in saida, "sem argumentos abre o modo interativo e, com a entrada encerrada, sai com 0")

    estado = tmp / "estado.json"
    base = ["--catalog", cat, "--out", estado]

    def invalido(args, esperado, rotulo):
        if estado.exists():
            estado.unlink()
        codigo, _, erro = b.rodar(*args, cwd=tmp)
        ok(codigo == esperado, "%s: saída %d (veio %d)" % (rotulo, esperado, codigo))
        ok(not estado.exists() and not (tmp / "estado.json.tmp").exists(), "%s: nenhum arquivo de estado criado" % rotulo)
        ok("[ERRO]" in erro, "%s: a mensagem de erro vai para o stderr" % rotulo)

    invalido(["--choice", *base], ERR_ARG, "--choice seguido de outra opção (falta o valor: '--catalog' não é um id)")
    invalido(["--choice"], ERR_ARG, "--choice sem valor")
    invalido(["--choice", "ok", "--choice", "sozinho", *base], ERR_ARG, "--choice duplicado")
    invalido(["--nope", *base], ERR_ARG, "argumento desconhecido")
    invalido(["ok", *base], ERR_ARG, "argumento posicional")
    invalido(["--choice", "", *base], ERR_ID_FORMATO, "id vazio")
    invalido(["--choice", "OK", *base], ERR_ID_FORMATO, "id com maiúsculas")
    invalido(["--choice", "1ok", *base], ERR_ID_FORMATO, "id que começa com dígito")
    invalido(["--choice", "_ok", *base], ERR_ID_FORMATO, "id que começa com sublinhado")
    invalido(["--choice", "o k", *base], ERR_ID_FORMATO, "id com espaço")
    invalido(["--choice", "ação", *base], ERR_ID_FORMATO, "id com acento")
    invalido(["--choice", "a" * 49, *base], ERR_ID_FORMATO, "id com 49 caracteres (limite 48)")
    invalido(["--choice", "ok\n", *base], ERR_ID_FORMATO, "id com quebra de linha")
    invalido(["--choice", "nao_existe", *base], ERR_ID_DESCONHECIDO, "id válido mas fora do catálogo")
    invalido(["--choice", "a" * 48, *base], ERR_ID_DESCONHECIDO, "id com 48 caracteres: formato aceito, mas desconhecido")

    secao("injeção de shell: o id do jogador nunca vira comando")
    marcador = tmp / "invadido"
    for carga in ["ok;touch invadido", "ok && touch invadido", "ok | touch invadido", "$(touch invadido)", "`touch invadido`",
                  "ok\ntouch invadido", "../../etc/passwd", "ok>invadido", "ok'; touch invadido; '", "%PATH%", "ok\"&touch invadido&\""]:
        codigo, _, _ = b.rodar("--choice", carga, *base, cwd=tmp)
        ok(codigo == ERR_ID_FORMATO and not marcador.exists() and not estado.exists(), "carga recusada sem efeito colateral: %r" % carga)
    # o caminho de saída e o do catálogo também não passam por um shell: nomes com metacaracteres são só nomes de arquivo
    estranho = tmp / "a b;touch invadido.json"
    codigo, _, _ = b.rodar("--choice", "ok", "--reset", "--catalog", cat, "--out", estranho, cwd=tmp)
    ok(codigo == OK and estranho.exists() and not marcador.exists(), "--out com espaço e ';' é só um nome de arquivo")
    codigo, _, _ = b.rodar("--choice", "ok", "--reset", "--catalog", cat, "--out", tmp / "con\x07trole.json", cwd=tmp)
    ok(codigo == ERR_ARG, "--out com caractere de controle é recusado (argumento inválido)")
    codigo, _, _ = b.rodar("--choice", "ok", "--timestamp", "ontem", *base, cwd=tmp)
    ok(codigo == ERR_ARG and not estado.exists(), "--timestamp fora do formato é recusado")
    codigo, _, _ = b.rodar("--choice", "ok", "--timestamp", "2026-13-40T25:61:61Z", *base, cwd=tmp)
    ok(codigo == ERR_ARG and not estado.exists(), "--timestamp com campos impossíveis é recusado")
    codigo, _, _ = b.rodar("--choice", "ok", "--reset", "--reset", *base, cwd=tmp)
    ok(codigo == ERR_ARG, "--reset duplicado é recusado")


# ------------------------------------------------------------------ 2. estado_jogo.json
def aplicar(b, escolha, saida, carimbo, reset=False, catalogo=None):
    args = ["--choice", escolha, "--catalog", catalogo or str(CATALOGO), "--timestamp", carimbo, "--out", saida]
    if reset:
        args.append("--reset")
    return b.rodar(*args)


def testar_estado(b, tmp):
    secao("estado_jogo.json: formato, acúmulo, limites e escrita atômica")
    saida = tmp / "estado_jogo.json"
    codigo, texto, _ = aplicar(b, "ok", saida, "2026-11-17T21:00:00Z", reset=True)
    ok(codigo == OK and "ok" in texto, "--choice ok --reset grava o estado e sai com 0")
    dados, texto, bruto = ler_estado(saida)
    ok(validar_estado(dados) == [], "o arquivo gravado cumpre o esquema (%s)" % validar_estado(dados))
    ok(list(dados.keys()) == list(CHAVES), "os campos estão na ordem do contrato")
    ok(dados["choice_id"] == "ok" and dados["status"] == "ok" and dados["is_placeholder"] is False, "choice_id, status e is_placeholder da escolha 'ok'")
    ok(dados["metrics"] == {"autonomia": 47, "conformidade": 52, "dependencia": 4}, "métricas = iniciais 50/50/0 + deltas -3/+2/+4 do catálogo")
    ok(dados["timestamp"] == "2026-11-17T21:00:00Z", "o --timestamp fixo é gravado como veio")
    ok(texto.endswith("\n") and not bruto.startswith(b"\xef\xbb\xbf"), "termina com quebra de linha e sem BOM")
    ok(not (tmp / "estado_jogo.json.tmp").exists(), "nenhum .tmp sobra depois da gravação atômica")

    codigo, _, _ = aplicar(b, "ficar", saida, "2026-11-17T21:05:00Z")
    dados, _, _ = ler_estado(saida)
    ok(codigo == OK and dados["metrics"] == {"autonomia": 37, "conformidade": 58, "dependencia": 14} and dados["choice_id"] == "ficar", "a segunda execução acumula sobre o estado gravado")
    ok(dados["timestamp"] == "2026-11-17T21:05:00Z", "o timestamp é o da última gravação")
    codigo, _, _ = aplicar(b, "recusar", saida, "2026-11-17T21:06:00Z", reset=True)
    dados, _, _ = ler_estado(saida)
    ok(codigo == OK and dados["metrics"] == {"autonomia": 60, "conformidade": 44, "dependencia": 0}, "--reset ignora o estado gravado (50/50/0 + 10/-6/-5, com DEP travada em 0)")

    codigo, _, _ = aplicar(b, "choice_fixed_01", saida, "2026-11-17T21:07:00Z", reset=True)
    dados, _, _ = ler_estado(saida)
    ok(codigo == OK and dados["is_placeholder"] is True and dados["metrics"] == INICIAIS, "escolha placeholder: is_placeholder true e métricas intactas")

    codigo, _, _ = aplicar(b, "ficar", saida, "2026-11-17T21:08:00Z", reset=True)
    for _ in range(12):
        aplicar(b, "ficar", saida, "2026-11-17T21:09:00Z")
    dados, _, _ = ler_estado(saida)
    ok(dados["metrics"]["autonomia"] == 0 and dados["metrics"]["dependencia"] == 100 and 0 <= dados["metrics"]["conformidade"] <= 100,
       "limites: AUT não desce de 0 e DEP não passa de 100 (%s)" % dados["metrics"])
    ok(validar_estado(dados) == [], "no limite o arquivo continua válido")

    # sem --timestamp o backend usa a hora atual em UTC, no formato do contrato
    codigo, _, _ = b.rodar("--choice", "ok", "--reset", "--catalog", CATALOGO, "--out", saida)
    dados, _, _ = ler_estado(saida)
    ok(codigo == OK and RE_TS.match(dados["timestamp"]) is not None, "sem --timestamp: hora atual UTC válida (%s)" % dados["timestamp"])
    codigo, _, _ = b.rodar("--choice=sozinho", "--catalog=" + str(CATALOGO), "--out=" + str(saida), "--timestamp=2026-11-17T22:00:00Z")
    dados, _, _ = ler_estado(saida)
    ok(codigo == OK and dados["choice_id"] == "sozinho", "a forma --opcao=valor também é aceita")

    secao("falhas: o arquivo anterior fica intacto e nada sobra")
    aplicar(b, "ok", saida, "2026-11-17T21:00:00Z", reset=True)
    antes = saida.read_bytes()
    codigo, _, _ = aplicar(b, "nao_existe", saida, "2026-11-17T21:10:00Z")
    ok(codigo == ERR_ID_DESCONHECIDO and saida.read_bytes() == antes, "id desconhecido não altera o estado gravado")
    codigo, _, _ = b.rodar("--choice", "ok", "--catalog", CATALOGO, "--out", tmp / "pasta_que_nao_existe" / "estado.json")
    ok(codigo == ERR_IO and not (tmp / "pasta_que_nao_existe").exists(), "pasta de destino inexistente: erro de E/S e nada criado")
    pasta = tmp / "uma_pasta"
    pasta.mkdir()
    codigo, _, _ = b.rodar("--choice", "ok", "--reset", "--catalog", CATALOGO, "--out", pasta)
    ok(codigo == ERR_IO and pasta.is_dir() and not (tmp / "uma_pasta.tmp").exists(), "--out apontando para uma pasta: erro de E/S e nenhum .tmp sobra")

    secao("arquivos de entrada corrompidos")
    ruim = tmp / "ruim.json"
    ruim.write_text("{ isto nao e json", encoding="utf-8")
    codigo, _, _ = aplicar(b, "ok", ruim, "2026-11-17T21:00:00Z")
    ok(codigo == ERR_JSON and ruim.read_text(encoding="utf-8") == "{ isto nao e json", "estado corrompido sem --reset: erro de JSON e o arquivo NÃO é sobrescrito")
    codigo, _, _ = aplicar(b, "ok", ruim, "2026-11-17T21:00:00Z", reset=True)
    ok(codigo == OK and validar_estado(ler_estado(ruim)[0]) == [], "--reset é o caminho de recuperação: grava um estado novo e válido")
    fora = tmp / "fora_do_esquema.json"
    for nome, conteudo in [("versão 2", {"schema_version": 2, "choice_id": "ok", "status": "ok", "metrics": INICIAIS, "timestamp": "", "is_placeholder": False}),
                           ("métrica 101", {"schema_version": 1, "choice_id": "ok", "status": "ok", "metrics": {"autonomia": 101, "conformidade": 0, "dependencia": 0}, "timestamp": "", "is_placeholder": False}),
                           ("status inválido", {"schema_version": 1, "choice_id": "ok", "status": "OK!", "metrics": INICIAIS, "timestamp": "", "is_placeholder": False}),
                           ("sem is_placeholder", {"schema_version": 1, "choice_id": "ok", "status": "ok", "metrics": INICIAIS, "timestamp": ""}),
                           ("choice_id com maiúscula", {"schema_version": 1, "choice_id": "Ok", "status": "ok", "metrics": INICIAIS, "timestamp": "", "is_placeholder": False})]:
        fora.write_text(json.dumps(conteudo), encoding="utf-8")
        codigo, _, _ = aplicar(b, "ok", fora, "2026-11-17T21:00:00Z")
        ok(codigo == ERR_ESQUEMA, "estado fora do esquema (%s): erro de esquema (saída %d)" % (nome, codigo))
    fora.write_bytes(b"\xef\xbb\xbf" + json.dumps({"schema_version": 1, "choice_id": "", "status": "inicial", "metrics": INICIAIS, "timestamp": "", "is_placeholder": False, "campo_futuro": [1, 2]}).encode("utf-8"))
    codigo, _, _ = aplicar(b, "ok", fora, "2026-11-17T21:00:00Z")
    ok(codigo == OK, "BOM UTF-8 e campos desconhecidos são aceitos na leitura (compatibilidade futura)")
    grande = tmp / "grande.json"
    grande.write_bytes(b" " * (1024 * 1024 + 10))
    codigo, _, _ = aplicar(b, "ok", grande, "2026-11-17T21:00:00Z")
    ok(codigo == ERR_LIMITE, "arquivo acima de 1 MiB: limite excedido (saída %d)" % codigo)

    secao("catálogo inválido")
    cat = tmp / "catalogo.json"
    casos = [
        ("JSON malformado", "{ nao e json", ERR_JSON),
        ("sem 'choices'", '{"schema_version": 1}', ERR_ESQUEMA),
        ("'choices' não é lista", '{"schema_version": 1, "choices": {"a": 1}}', ERR_ESQUEMA),
        ("delta fora de -100..100", '{"schema_version": 1, "choices": [{"id": "ok", "autonomia": 500}]}', ERR_ESQUEMA),
        ("id repetido", '{"schema_version": 1, "choices": [{"id": "ok"}, {"id": "ok"}]}', ERR_ESQUEMA),
        ("id fora do formato", '{"schema_version": 1, "choices": [{"id": "Ok!"}]}', ERR_ESQUEMA),
    ]
    for rotulo, texto, esperado in casos:
        cat.write_text(texto, encoding="utf-8")
        codigo, _, _ = aplicar(b, "ok", tmp / "z.json", "2026-11-17T21:00:00Z", reset=True, catalogo=str(cat))
        ok(codigo == esperado and not (tmp / "z.json").exists(), "catálogo %s: saída %d e nenhum estado criado (veio %d)" % (rotulo, esperado, codigo))
    codigo, _, _ = aplicar(b, "ok", tmp / "z.json", "2026-11-17T21:00:00Z", reset=True, catalogo=str(tmp / "nao_existe.json"))
    ok(codigo == ERR_IO, "catálogo inexistente: erro de E/S")
    itens = ",".join('{"id": "c%d"}' % i for i in range(129))
    cat.write_text('{"schema_version": 1, "choices": [%s]}' % itens, encoding="utf-8")
    codigo, _, _ = aplicar(b, "c1", tmp / "z.json", "2026-11-17T21:00:00Z", reset=True, catalogo=str(cat))
    ok(codigo in (ERR_LIMITE, ERR_ESQUEMA) and not (tmp / "z.json").exists(), "catálogo com mais de 128 escolhas é recusado (saída %d)" % codigo)


# ------------------------------------------------------------------ 3. catálogo x conversas.json
def escolhas_do_jogo():
    dados = json.loads(CONVERSAS.read_text(encoding="utf-8"))
    achadas = {}
    for id_msg, msg in dados["mensagens"].items():
        for esc in msg.get("escolhas") or []:
            metricas = esc.get("metricas") or {}
            registro = {"metricas": tuple(float(metricas.get(n, 0)) for n in METRICAS), "placeholder": bool(msg.get("is_placeholder", False) or esc.get("is_placeholder", False)), "mensagem": id_msg}
            achadas.setdefault(esc["id"], []).append(registro)
    return achadas


def testar_catalogo():
    secao("catálogo do backend x escolhas do jogo (conversas.json)")
    catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))
    ok(catalogo.get("schema_version") == 1 and isinstance(catalogo.get("choices"), list), "choices.json tem schema_version 1 e a lista 'choices'")
    do_backend = {c["id"]: c for c in catalogo["choices"]}
    ok(len(do_backend) == len(catalogo["choices"]), "ids do catálogo sem repetição")
    ok(all(RE_ID.match(i) for i in do_backend), "todo id do catálogo cumpre o formato aceito pelo --choice")
    do_jogo = escolhas_do_jogo()
    for id_escolha, usos in sorted(do_jogo.items()):
        primeiro = usos[0]
        ok(all(u["metricas"] == primeiro["metricas"] and u["placeholder"] == primeiro["placeholder"] for u in usos),
           "a escolha '%s' tem os mesmos deltas em todas as mensagens em que aparece" % id_escolha)
        if not ok(id_escolha in do_backend, "a escolha '%s' do jogo existe no catálogo do backend" % id_escolha):
            continue
        c = do_backend[id_escolha]
        deltas = (float(c.get("autonomia", 0)), float(c.get("conformidade", 0)), float(c.get("dependencia", 0)))
        ok(deltas == primeiro["metricas"], "deltas de '%s': backend %s x jogo %s" % (id_escolha, deltas, primeiro["metricas"]))
        ok(bool(c.get("is_placeholder", False)) == primeiro["placeholder"], "is_placeholder de '%s' bate com a mensagem do jogo" % id_escolha)
    ok(not [i for i in do_backend if i not in do_jogo], "nenhuma escolha do backend sem correspondente no jogo (%s)" % [i for i in do_backend if i not in do_jogo])
    ok(all(c.get("status", "ok") and RE_STATUS.match(c.get("status", "ok")) for c in catalogo["choices"]), "status de cada escolha cumpre [a-z_]{1,32}")


# ------------------------------------------------------------------ 4. código-fonte
def testar_fontes():
    secao("fontes: sem shell, sem funções sem limite")
    c_proprios = [p for p in sorted((RAIZ / "backend").glob("*.c")) + sorted((RAIZ / "backend" / "tests").glob("*.c")) if p.name != "cJSON.c"]
    shell = re.compile(r"\b(system|popen|execl|execlp|execv|execvp|execve|WinExec|ShellExecute[AW]?|CreateProcess[AW]?|_wsystem)\s*\(")
    sem_limite = re.compile(r"\b(strcpy|strcat|sprintf|vsprintf|gets|scanf|sscanf)\s*\(")
    achados_shell, achados_limite = [], []
    for caminho in c_proprios:
        for n, linha in enumerate(caminho.read_text(encoding="utf-8").splitlines(), 1):
            codigo = linha.split("//")[0]
            if shell.search(codigo):
                achados_shell.append("%s:%d" % (caminho.name, n))
            if sem_limite.search(codigo):
                achados_limite.append("%s:%d" % (caminho.name, n))
    ok(not achados_shell, "o backend em C não chama o shell (%s)" % achados_shell)
    ok(not achados_limite, "o backend em C não usa funções sem limite (%s)" % achados_limite)
    proibido = re.compile(r"\bOS\.(execute|create_process|shell_open|kill)\b")
    achados_godot = []
    for pasta in ("core", "features", "shared", "tests"):
        for caminho in (RAIZ / pasta).rglob("*.gd"):
            for n, linha in enumerate(caminho.read_text(encoding="utf-8").splitlines(), 1):
                if proibido.search(linha.split("#")[0]):
                    achados_godot.append("%s:%d" % (caminho.relative_to(RAIZ), n))
    ok(not achados_godot, "os scripts do Godot não executam processos (%s)" % achados_godot)
    ok((RAIZ / "core" / "utilities" / "estado_jogo_backend.gd").exists(), "o leitor/gravador do estado no lado do Godot existe (core/utilities/estado_jogo_backend.gd)")


# ------------------------------------------------------------------ ciclo C -> Godot -> C
def testar_integracao(b, pasta):
    secao("integração C -> Godot -> C (%s)" % pasta)
    de_c = pasta / "estado_jogo.json"
    do_godot = pasta / "estado_jogo_godot.json"
    relatorio = pasta / "resultado_godot.json"
    if not ok(de_c.exists(), "o backend gravou estado_jogo.json antes do teste do Godot"):
        return
    if not ok(do_godot.exists() and relatorio.exists(), "o teste do Godot rodou e gravou estado_jogo_godot.json e resultado_godot.json"):
        return
    resultado = json.loads(relatorio.read_text(encoding="utf-8"))
    ok(resultado.get("falhas") == 0 and resultado.get("verificacoes", 0) > 0, "o teste do Godot terminou sem falhas (%s verificações)" % resultado.get("verificacoes"))
    dados, texto, bruto = ler_estado(do_godot)
    ok(validar_estado(dados) == [], "o arquivo gravado PELO GODOT cumpre o esquema (%s)" % validar_estado(dados))
    ok(list(dados.keys()) == list(CHAVES) and texto.endswith("\n") and not bruto.startswith(b"\xef\xbb\xbf"), "o arquivo do Godot segue a mesma ordem, UTF-8 sem BOM e quebra de linha final")
    ok(not (pasta / "estado_jogo_godot.json.tmp").exists(), "o Godot não deixou .tmp depois de gravar")
    antes = dados["metrics"]
    codigo, _, erro = b.rodar("--choice", "sozinho", "--catalog", CATALOGO, "--timestamp", "2026-11-17T21:30:00Z", "--out", do_godot)
    ok(codigo == OK, "o backend aceita o arquivo do Godot como ponto de partida (saída %d, %s)" % (codigo, erro.strip()))
    depois, _, _ = ler_estado(do_godot)
    esperado = {"autonomia": min(100, antes["autonomia"] + 5), "conformidade": max(0, antes["conformidade"] - 2), "dependencia": antes["dependencia"]}
    ok(depois["metrics"] == esperado and depois["choice_id"] == "sozinho", "o backend continuou do estado do Godot: %s -> %s" % (antes, depois["metrics"]))


def main():
    global _total
    analisador = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    analisador.add_argument("--binario", default=str(BINARIO_PADRAO), help="caminho do maya_backend compilado")
    analisador.add_argument("--integracao", default="", help="pasta do ciclo C -> Godot -> C (confere o resultado, não roda o Godot)")
    opcoes = analisador.parse_args()
    binario = Path(opcoes.binario)
    if not binario.exists():
        print("ERRO: binário não encontrado: %s (rode `make backend`)" % binario)
        return 2
    b = Backend(binario)
    with tempfile.TemporaryDirectory(prefix="maya_backend_") as pasta_temp:
        tmp = Path(pasta_temp)
        if opcoes.integracao:
            testar_integracao(b, Path(opcoes.integracao).resolve())
        else:
            (tmp / "args").mkdir()
            (tmp / "estado").mkdir()
            testar_argumentos(b, tmp / "args")
            testar_estado(b, tmp / "estado")
            testar_catalogo()
            testar_fontes()
    print("RESULTADO PY: %d verificacoes, %d falhas." % (_total, _falhas))
    return 0 if _falhas == 0 and _total > 0 else 1


if __name__ == "__main__":
    sys.exit(main())
