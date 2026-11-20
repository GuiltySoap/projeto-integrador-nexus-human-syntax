#!/usr/bin/env python3
"""Confere o conteúdo de uma exportação do Godot (.pck, ou .exe com o .pck embutido) contra o que a documentação manda (§27).

O que ele lê é o próprio arquivo exportado (o diretório do PCK, formato 2 a 4, sem precisar da Godot). Falha (código 1) se o pacote:
  - levar arquivos de desenvolvimento: tests/, tools/, docs/, backend/ ou addons/ (docs/07_integracao.md, seção 11);
  - não levar os dados do jogo: todo .json de core/data/ (são lidos com FileAccess, não são recursos: sem o filtro `*.json` do preset ficam de
    fora), o vídeo da Splash (.ogv, também fora do sistema de recursos) e os scripts, cenas e recursos importados que o projeto declara;
  - não trouxer a cena principal, os scripts dos autoloads e o project.binary.
Avisa (sem falhar) sobre o que só vale conferir de olho: tamanho do pacote e contagem de arquivos.

Uso:  python3 -I tools/conferir_pacote.py <pasta-ou-arquivo> [--projeto <raiz-do-projeto>] [--listar]
  <pasta>   procura nela o .pck e, se não houver, o .exe do jogo (o que não termina em .console.exe)
Saída: lista de falhas e "RESULTADO PACOTE: N verificacoes, M falhas".
"""
import argparse
import re
import struct
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
MAGIA_PCK = 0x43504447  # "GDPC"
PROIBIDOS = ("tests/", "tools/", "docs/", "backend/", "addons/")
EXTENSOES_DADOS = (".json", ".ogv")


class ErroPacote(Exception):
    pass


# ------------------------------------------------------------------ leitura do PCK
def _ler_diretorio(dados, inicio):
    """Lê o diretório de um PCK que começa em `inicio`. Devolve (formato, versão da engine, [caminho, ...])."""
    if inicio < 0 or inicio + 32 > len(dados):
        raise ErroPacote("PCK fora do arquivo")
    magia, formato, maior, menor, patch, flags = struct.unpack_from("<6I", dados, inicio)
    if magia != MAGIA_PCK:
        raise ErroPacote("assinatura GDPC ausente")
    if formato < 2 or formato > 4:
        raise ErroPacote("formato de PCK %d não suportado por este conferidor (2 a 4)" % formato)
    if flags & 1:
        raise ErroPacote("o diretório do PCK está criptografado")
    deslocamento = inicio + 24
    base_dos_arquivos = struct.unpack_from("<Q", dados, deslocamento)[0]
    deslocamento += 8
    inicio_do_diretorio = None
    if formato >= 3:
        inicio_do_diretorio = struct.unpack_from("<Q", dados, deslocamento)[0]
        deslocamento += 8
    deslocamento += 16 * 4  # 16 inteiros reservados
    if inicio_do_diretorio:
        deslocamento = inicio + inicio_do_diretorio  # relativo ao começo do PCK (num .pck solto, `inicio` é 0)
    quantidade = struct.unpack_from("<I", dados, deslocamento)[0]
    deslocamento += 4
    if quantidade > 2_000_000:
        raise ErroPacote("quantidade de arquivos absurda (%d)" % quantidade)
    caminhos = []
    for _ in range(quantidade):
        tamanho = struct.unpack_from("<I", dados, deslocamento)[0]
        deslocamento += 4
        caminho = dados[deslocamento:deslocamento + tamanho].rstrip(b"\0").decode("utf-8", "replace")
        deslocamento += tamanho
        deslocamento += 8 + 8 + 16  # deslocamento, tamanho e MD5
        deslocamento += 4  # flags
        caminhos.append(caminho[6:] if caminho.startswith("res://") else caminho)
    del base_dos_arquivos
    return formato, "%d.%d.%d" % (maior, menor, patch), caminhos


def _inicio_do_pck_embutido(dados):
    """Onde começa um PCK embutido num executável: pelo rodapé (tamanho + assinatura) ou pela seção `pck` do PE (Windows)."""
    if len(dados) > 12 and struct.unpack_from("<I", dados, len(dados) - 4)[0] == MAGIA_PCK:
        tamanho = struct.unpack_from("<Q", dados, len(dados) - 12)[0]
        inicio = len(dados) - 12 - tamanho
        if 0 <= inicio < len(dados) and struct.unpack_from("<I", dados, inicio)[0] == MAGIA_PCK:
            return inicio
    if dados[:2] == b"MZ" and len(dados) > 0x40:
        pe = struct.unpack_from("<I", dados, 0x3C)[0]
        if dados[pe:pe + 4] == b"PE\0\0":
            secoes, = struct.unpack_from("<H", dados, pe + 6)
            tamanho_opcional, = struct.unpack_from("<H", dados, pe + 20)
            tabela = pe + 24 + tamanho_opcional
            for i in range(secoes):
                nome = dados[tabela + i * 40:tabela + i * 40 + 8].rstrip(b"\0")
                tamanho_bruto, ponteiro_bruto = struct.unpack_from("<II", dados, tabela + i * 40 + 16)
                if nome in (b"pck", b".pck") and ponteiro_bruto and tamanho_bruto and struct.unpack_from("<I", dados, ponteiro_bruto)[0] == MAGIA_PCK:
                    return ponteiro_bruto
    return -1


def ler_pacote(caminho):
    """Lê um .pck ou um .exe com PCK embutido. Devolve {"formato", "engine", "arquivos": [...], "tamanho"}."""
    dados = Path(caminho).read_bytes()
    try:
        if len(dados) >= 4 and struct.unpack_from("<I", dados, 0)[0] == MAGIA_PCK:
            inicio = 0
        else:
            inicio = _inicio_do_pck_embutido(dados)
            if inicio < 0:
                raise ErroPacote("não achei um PCK em %s (nem arquivo .pck, nem rodapé, nem seção 'pck'): exporte com embed_pck=false para conferir o .pck ao lado" % caminho)
        formato, engine, arquivos = _ler_diretorio(dados, inicio)
    except (struct.error, IndexError, OverflowError) as erro:
        raise ErroPacote("pacote truncado ou corrompido (%s)" % erro) from erro
    return {"formato": formato, "engine": engine, "arquivos": arquivos, "tamanho": len(dados)}


def localizar_pacote(alvo):
    alvo = Path(alvo)
    if alvo.is_file():
        return alvo
    if not alvo.is_dir():
        raise ErroPacote("não existe: %s" % alvo)
    pcks = sorted(alvo.glob("*.pck"))
    if pcks:
        return pcks[0]
    exes = [e for e in sorted(alvo.glob("*.exe")) if not e.name.lower().endswith(".console.exe")]
    if exes:
        return exes[0]
    raise ErroPacote("nem .pck nem .exe em %s (rode `make export-windows`)" % alvo)


# ------------------------------------------------------------------ o que o projeto declara
def _logico(caminho):
    """Caminho do recurso de origem de uma entrada do pacote: `x.gd.remap`/`x.gdc` -> `x.gd`, `x.tscn.remap` -> `x.tscn`."""
    if caminho.endswith(".remap"):
        return caminho[:-6]
    if caminho.endswith(".gdc"):
        return caminho[:-1]
    return caminho


def esperados_do_projeto(raiz):
    """Conjuntos que o projeto exige no pacote, lidos do disco: dados (.json/.ogv fora das pastas excluídas), scripts, cenas e importados."""
    def excluido(rel):
        return rel.startswith(PROIBIDOS)

    dados, scripts, cenas, importados = set(), set(), set(), set()
    for arquivo in raiz.rglob("*"):
        if not arquivo.is_file() or ".godot" in arquivo.parts or ".git" in arquivo.parts or "build" in arquivo.relative_to(raiz).parts[:1]:
            continue
        rel = arquivo.relative_to(raiz).as_posix()
        if excluido(rel):
            continue
        if rel.endswith(EXTENSOES_DADOS):
            dados.add(rel)
        elif rel.endswith(".gd"):
            scripts.add(rel)
        elif rel.endswith(".tscn"):
            cenas.add(rel)
        elif rel.endswith(".import"):
            texto = arquivo.read_text(encoding="utf-8", errors="replace")
            for destino in re.findall(r'^dest_files=\[(.*)\]$', texto, flags=re.M):
                for item in re.findall(r'"res://([^"]+)"', destino):
                    importados.add(item)
    return {"dados": dados, "scripts": scripts, "cenas": cenas, "importados": importados}


def cena_principal(raiz):
    texto = (raiz / "project.godot").read_text(encoding="utf-8")
    m = re.search(r'^run/main_scene="res://([^"]+)"', texto, flags=re.M)
    return m.group(1) if m else ""


def autoloads(raiz):
    texto = (raiz / "project.godot").read_text(encoding="utf-8")
    return re.findall(r'^\w+="\*res://([^"]+)"', texto, flags=re.M)


# ------------------------------------------------------------------ conferência
def conferir(pacote, raiz):
    """Devolve (falhas, avisos, total_de_verificacoes)."""
    falhas, avisos = [], []
    total = 0
    arquivos = pacote["arquivos"]
    todos = set(arquivos)
    logicos = {_logico(a) for a in arquivos}

    total += 1
    if not arquivos:
        falhas.append("o pacote está vazio")
        return falhas, avisos, total

    total += 1
    achados = sorted(a for a in arquivos if a.startswith(PROIBIDOS))
    if achados:
        falhas.append("arquivos de desenvolvimento no pacote (%d): %s%s" % (len(achados), ", ".join(achados[:6]), " ..." if len(achados) > 6 else ""))

    esperados = esperados_do_projeto(raiz)
    for rotulo, conjunto in (("dados do jogo (.json/.ogv)", esperados["dados"]), ("scripts", esperados["scripts"]), ("cenas", esperados["cenas"])):
        total += 1
        faltando = sorted(c for c in conjunto if c not in logicos and c not in todos)
        if rotulo.startswith("cenas"):
            # numa exportação a cena vira `x.tscn.remap` + `.godot/exported/.../x.scn`; o remap basta como prova
            faltando = [c for c in faltando if (c + ".remap") not in todos]
        if faltando:
            falhas.append("%s ausentes do pacote (%d): %s%s" % (rotulo, len(faltando), ", ".join(faltando[:6]), " ..." if len(faltando) > 6 else ""))
    total += 1
    faltando = sorted(d for d in esperados["importados"] if d not in todos)
    if faltando:
        falhas.append("recursos importados ausentes (%d): %s%s" % (len(faltando), ", ".join(faltando[:4]), " ..." if len(faltando) > 4 else ""))

    total += 1
    principal = cena_principal(raiz)
    if not principal or principal not in logicos:
        falhas.append("cena principal ausente do pacote: %s" % (principal or "(não declarada)"))
    total += 1
    ausentes = [a for a in autoloads(raiz) if a not in logicos]
    if ausentes:
        falhas.append("scripts dos autoloads ausentes: %s" % ", ".join(ausentes))
    total += 1
    if "project.binary" not in todos and "project.godot" not in todos:
        falhas.append("project.binary ausente (o jogo não abre sem as configurações do projeto)")
    total += 1
    sujos = sorted(a for a in arquivos if a.endswith((".tmp", ".corrompido", ".exe", ".dll", "estado_jogo.json", "salvamento.json")) or a.startswith(("export_presets", ".git"))
                   or re.search(r"checkpoint_dia_\d\.json$", a))
    if sujos:
        falhas.append("arquivos que não deveriam ir no pacote: %s" % ", ".join(sujos[:6]))
    if pacote["tamanho"] > 400 * 1024 * 1024:
        avisos.append("pacote muito grande (%.0f MB): confira o que entrou" % (pacote["tamanho"] / 1048576))
    return falhas, avisos, total


def main(argv=None):
    analisador = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    analisador.add_argument("alvo", help="pasta da exportação, ou o .pck / .exe")
    analisador.add_argument("--projeto", default=str(RAIZ), help="raiz do projeto (padrão: a deste script)")
    analisador.add_argument("--listar", action="store_true", help="imprime todos os caminhos do pacote")
    opcoes = analisador.parse_args(argv)
    try:
        arquivo = localizar_pacote(opcoes.alvo)
        pacote = ler_pacote(arquivo)
    except ErroPacote as erro:
        print("ERRO:", erro)
        return 2
    print("pacote: %s (%.1f MB, PCK formato %d, Godot %s, %d arquivos)" % (arquivo, pacote["tamanho"] / 1048576, pacote["formato"], pacote["engine"], len(pacote["arquivos"])))
    if opcoes.listar:
        print("\n".join(sorted(pacote["arquivos"])))
    falhas, avisos, total = conferir(pacote, Path(opcoes.projeto))
    for aviso in avisos:
        print("AVISO", aviso)
    for falha in falhas:
        print("FALHA", falha)
    print("RESULTADO PACOTE: %d verificacoes, %d falhas." % (total, len(falhas)))
    return 1 if falhas else 0


if __name__ == "__main__":
    sys.exit(main())
