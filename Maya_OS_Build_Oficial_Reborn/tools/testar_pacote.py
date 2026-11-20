#!/usr/bin/env python3
"""Testa o conferidor de pacotes (tools/conferir_pacote.py) com PCKs SINTÉTICOS, sem a Godot nem templates de exportação.

Monta, em memória, pacotes no formato 4 do Godot (o de 4.7) com o conteúdo que a exportação do projeto atual deveria ter, e confere que o
conferidor aceita o pacote certo e recusa os errados: arquivos de desenvolvimento, JSON do jogo faltando, cena principal ou autoload ausente,
recurso importado faltando. Também confere a leitura do PCK embutido (rodapé e seção `pck` de um PE do Windows) e que arquivos quebrados
dão erro claro em vez de exceção.

Se a variável de ambiente MAYA_PCK_REAL apontar para um .pck exportado de verdade (por exemplo o da pasta do projeto no Windows), ele
também confere que o leitor entende o arquivo e que nenhum caminho vem vazio.

Uso:  python3 -I tools/testar_pacote.py          Saída: "RESULTADO PACOTE (testes): N verificacoes, M falhas."
"""
import importlib.util
import os
import struct
import sys
import tempfile
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
_spec = importlib.util.spec_from_file_location("conferir_pacote", RAIZ / "tools" / "conferir_pacote.py")
cp = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(cp)

_total = 0
_falhas = 0


def ok(condicao, descricao):
    global _total, _falhas
    _total += 1
    if not condicao:
        _falhas += 1
        print("FALHA", descricao)
    return bool(condicao)


def montar_pck(caminhos, formato=4, flags=2):
    """Bytes de um PCK mínimo e válido (formato 3 ou 4: com o deslocamento do diretório) com os caminhos dados e 4 bytes de conteúdo cada."""
    cabecalho = 24 + 8 + (8 if formato >= 3 else 0) + 64
    base = cabecalho + 8
    corpo = b"".join(b"dado" for _ in caminhos)
    inicio_do_diretorio = base + len(corpo)
    saida = struct.pack("<6I", cp.MAGIA_PCK, formato, 4, 7, 2, flags) + struct.pack("<Q", base)
    if formato >= 3:
        saida += struct.pack("<Q", inicio_do_diretorio)
    saida += b"\0" * 64 + b"\0" * 8 + corpo
    diretorio = struct.pack("<I", len(caminhos))
    for i, c in enumerate(caminhos):
        bruto = c.encode("utf-8")
        preenchido = bruto + b"\0" * ((4 - len(bruto) % 4) % 4)
        diretorio += struct.pack("<I", len(preenchido)) + preenchido + struct.pack("<QQ", base + 4 * i, 4) + b"\0" * 16 + struct.pack("<I", 0)
    return saida + diretorio


def pacote_correto():
    """Os caminhos que uma exportação certa do projeto atual leva (compilados como a Godot faz: .gd.remap + .gdc, .tscn.remap, .ctex...)."""
    esperado = cp.esperados_do_projeto(RAIZ)
    caminhos = ["project.binary", ".godot/global_script_class_cache.cfg", ".godot/uid_cache.bin"]
    caminhos += sorted(esperado["dados"])
    for gd in sorted(esperado["scripts"]):
        caminhos += [gd + ".remap", gd + "c"]
    for tscn in sorted(esperado["cenas"]):
        caminhos += [tscn + ".remap", ".godot/exported/133200997/export-%016x-%s.scn" % (abs(hash(tscn)) % (1 << 60), Path(tscn).stem)]
    caminhos += sorted(esperado["importados"])
    return caminhos


def conferir_lista(caminhos):
    dados = montar_pck(caminhos)
    with tempfile.TemporaryDirectory(prefix="maya_pck_") as pasta:
        arquivo = Path(pasta) / "teste.pck"
        arquivo.write_bytes(dados)
        pacote = cp.ler_pacote(arquivo)
    return cp.conferir(pacote, RAIZ), pacote


def testar_leitura():
    print("== leitura do PCK")
    caminhos = ["project.binary", "core/data/a.json", "res://com_prefixo/b.json", "acentuação/ção.txt", "x"]
    for formato in (3, 4):
        with tempfile.TemporaryDirectory(prefix="maya_pck_") as pasta:
            arquivo = Path(pasta) / "teste.pck"
            arquivo.write_bytes(montar_pck(caminhos, formato=formato))
            pacote = cp.ler_pacote(arquivo)
        ok(pacote["formato"] == formato and pacote["engine"] == "4.7.2", "formato %d: versão lida (%s)" % (formato, pacote["engine"]))
        ok(pacote["arquivos"] == ["project.binary", "core/data/a.json", "com_prefixo/b.json", "acentuação/ção.txt", "x"], "formato %d: caminhos lidos na ordem, com o prefixo res:// removido e acentos preservados" % formato)

    print("== PCK embutido")
    pck = montar_pck(caminhos)
    # rodapé: [PCK][tamanho u64][GDPC]
    exe_rodape = b"MZ" + b"\0" * 5000 + pck + struct.pack("<Q", len(pck)) + struct.pack("<I", cp.MAGIA_PCK)
    # seção `pck` de um PE: DOS + 'PE\0\0' + COFF + (sem cabeçalho opcional) + 1 seção + dados brutos
    pe = bytearray(b"MZ" + b"\0" * 0x3A)
    pe += struct.pack("<I", 0x40)
    pe += b"PE\0\0" + struct.pack("<HHIIIHH", 0x8664, 1, 0, 0, 0, 0, 0)
    pe += b"pck\0\0\0\0\0" + struct.pack("<IIII", len(pck), 0x1000, len(pck), 0x200) + b"\0" * 16
    pe += b"\0" * (0x200 - len(pe)) + pck
    with tempfile.TemporaryDirectory(prefix="maya_pck_") as pasta:
        for nome, dados in (("rodape.exe", exe_rodape), ("secao.exe", bytes(pe))):
            arquivo = Path(pasta) / nome
            arquivo.write_bytes(dados)
            achado = cp.ler_pacote(arquivo)
            ok(achado["arquivos"] == ["project.binary", "core/data/a.json", "com_prefixo/b.json", "acentuação/ção.txt", "x"], "%s: o PCK embutido é achado e lido" % nome)
        (Path(pasta) / "exportacao").mkdir()
        (Path(pasta) / "exportacao" / "Jogo.console.exe").write_bytes(exe_rodape)
        (Path(pasta) / "exportacao" / "Jogo.exe").write_bytes(bytes(pe))
        ok(cp.localizar_pacote(Path(pasta) / "exportacao").name == "Jogo.exe", "numa pasta de exportação o .exe do jogo vence o .console.exe")
        (Path(pasta) / "exportacao" / "Jogo.pck").write_bytes(pck)
        ok(cp.localizar_pacote(Path(pasta) / "exportacao").name == "Jogo.pck", "e o .pck solto vence o .exe")

    print("== arquivos quebrados dão erro claro")
    with tempfile.TemporaryDirectory(prefix="maya_pck_") as pasta:
        for nome, dados in (("vazio.pck", b""), ("lixo.pck", os.urandom(300)), ("truncado.pck", pck[:60]), ("sem_pck.exe", b"MZ" + b"\0" * 400),
                            ("formato9.pck", montar_pck(caminhos, formato=4)[:4] + struct.pack("<I", 9) + montar_pck(caminhos)[8:]),
                            ("criptografado.pck", montar_pck(caminhos, flags=1))):
            arquivo = Path(pasta) / nome
            arquivo.write_bytes(dados)
            try:
                cp.ler_pacote(arquivo)
                ok(False, "%s deveria dar ErroPacote" % nome)
            except cp.ErroPacote:
                ok(True, nome)
            except Exception as erro:  # noqa: BLE001 - qualquer outra exceção é falha do conferidor
                ok(False, "%s: exceção inesperada %r em vez de ErroPacote" % (nome, erro))
        try:
            cp.localizar_pacote(Path(pasta) / "nao_existe")
            ok(False, "pasta inexistente deveria dar ErroPacote")
        except cp.ErroPacote:
            ok(True, "pasta inexistente")


def testar_conferencia():
    print("== conferência do conteúdo")
    base = pacote_correto()
    (falhas, avisos, total), _ = conferir_lista(base)
    ok(falhas == [] and total >= 8, "o pacote correto passa sem falhas (%s)" % falhas)

    casos = [
        ("arquivo de teste dentro do pacote", base + ["tests/smoke_test.gd.remap"], "desenvolvimento"),
        ("ferramentas dentro do pacote", base + ["tools/validar_projeto.py"], "desenvolvimento"),
        ("documentação dentro do pacote", base + ["docs/07_integracao.md"], "desenvolvimento"),
        ("backend dentro do pacote", base + ["backend/dialogues.json"], "desenvolvimento"),
        ("addons dentro do pacote", base + ["addons/x/plugin.cfg"], "desenvolvimento"),
        ("JSON do jogo faltando", [c for c in base if c != "core/data/catalogo_apps.json"], "dados do jogo"),
        ("vídeo da Splash faltando", [c for c in base if not c.endswith(".ogv")], "dados do jogo"),
        ("script faltando", [c for c in base if not c.startswith("core/utilities/estado_jogo_backend.gd")], "scripts ausentes"),
        ("cena faltando", [c for c in base if not c.startswith("features/shell/monitor_virtual/scenes/monitor_virtual.tscn")], "cenas ausentes"),
        ("cena principal faltando", [c for c in base if not c.startswith("features/splash_screen/scenes/splash_screen.tscn")], "cena principal"),
        ("autoload faltando", [c for c in base if not c.startswith("core/autoload/sistema_eventos.gd")], "autoloads"),
        ("recurso importado faltando", [c for c in base if not c.startswith(".godot/imported/") or c != next(x for x in base if x.startswith(".godot/imported/"))], "importados"),
        ("project.binary faltando", [c for c in base if c != "project.binary"], "project.binary"),
        ("estado do jogador dentro do pacote", base + ["estado_jogo.json"], "não deveriam"),
        ("salvamento dentro do pacote", base + ["salvamento.json"], "não deveriam"),
        ("executável dentro do pacote", base + ["outro.exe"], "não deveriam"),
    ]
    for rotulo, caminhos, trecho in casos:
        (falhas, _, _), _ = conferir_lista(caminhos)
        ok(any(trecho in f for f in falhas), "recusa: %s (%s)" % (rotulo, falhas[:1]))
    (falhas, _, _), _ = conferir_lista([])
    ok(len(falhas) == 1 and "vazio" in falhas[0], "pacote vazio é recusado")
    # o nome de um arquivo que só CONTÉM "tests" ou "estado_jogo" não é desenvolvimento nem dado do jogador
    (falhas, _, _), _ = conferir_lista(base + ["core/utilities/contests/x.gd.remap", "shared/estado_jogo_backend_ajuda.txt"])
    ok(falhas == [], "nomes parecidos (contests/, estado_jogo_backend_ajuda.txt) não são confundidos com os proibidos (%s)" % falhas)


def testar_pacote_real():
    real = os.environ.get("MAYA_PCK_REAL", "")
    if not real:
        print("== PCK real: MAYA_PCK_REAL não definida; etapa ignorada")
        return
    print("== PCK real (%s)" % real)
    pacote = cp.ler_pacote(real)
    ok(pacote["formato"] in (3, 4) and len(pacote["arquivos"]) > 50, "o leitor entende o PCK exportado pelo Godot %s (%d arquivos)" % (pacote["engine"], len(pacote["arquivos"])))
    ok(all(a and not a.startswith("/") for a in pacote["arquivos"]), "nenhum caminho vazio ou absoluto")
    ok("project.binary" in pacote["arquivos"], "o PCK real traz project.binary")


def main():
    testar_leitura()
    testar_conferencia()
    testar_pacote_real()
    print("RESULTADO PACOTE (testes): %d verificacoes, %d falhas." % (_total, _falhas))
    return 0 if _falhas == 0 and _total > 0 else 1


if __name__ == "__main__":
    sys.exit(main())
