#!/usr/bin/env python3
"""Compara duas rodadas da ferramenta tests/ui_dump (ex.: "antes" x "depois" de uma migração).

Para cada captura (.png) calcula a fração de pixels que mudou; para cada árvore de nós
(.txt em arvores/) compara os textos visíveis e as posições dos controles com texto.
Não precisa do Godot: só lê o que o ui_dump gravou em tests/_saida/<rodada>/.

Uso:
    python3 tools/comparar_rodadas.py [antes] [depois] [--saida tests/_saida]
                                      [--tol 8] [--limite 0.60] [--px 3] [--sem-diff]

Saída: tabela no terminal + <saida>/comparacao_<antes>_<depois>.md
       + imagens <saida>/diff_<antes>_<depois>/<nome>.png (vermelho = pixel que mudou).
Código de saída: 0 se nada passou do limite, 1 se alguma captura/árvore passou, 2 se faltou arquivo.

Observações de leitura:
  * relógios, barras animadas e o brilho da Maya mudam sozinhos entre duas rodadas: um
    pequeno percentual de pixels diferentes (< 0,2 %) numa captura é ruído esperado;
  * horas "12:04" são normalizadas ("HH:MM") antes de comparar os textos das árvores;
  * a árvore PODE ter outras classes depois da migração (esse é o objetivo): o que se compara
    é o que o jogador vê (textos) e onde está (retângulos).
"""
import argparse
import os
import re
import sys

try:
    from PIL import Image, ImageChops, ImageFilter
except ImportError:  # pragma: no cover
    sys.exit("Falta o Pillow (pip install pillow) para comparar as imagens.")

RE_LINHA = re.compile(r"^(?P<ind> *)(?P<classe>\w+)(?: <(?P<global>\w+)>)?(?P<resto>.*)$")
RE_RECT = re.compile(r"\br=(-?\d+),(-?\d+),(-?\d+),(-?\d+)")
RE_TEXTO = re.compile(r'\btext="((?:[^"\\]|\\.)*)"')
RE_DICA = re.compile(r'\btooltip_text="((?:[^"\\]|\\.)*)"')
RE_PLACEHOLDER = re.compile(r'\bplaceholder_text="((?:[^"\\]|\\.)*)"')
RE_HORA = re.compile(r"\b\d{1,2}:\d{2}(?::\d{2})?\b")
RE_DATA = re.compile(r"\b\d{1,2}/\d{1,2}/\d{4}\b")


def normalizar_texto(t):
    t = RE_HORA.sub("HH:MM", t)
    t = RE_DATA.sub("DD/MM/AAAA", t)
    return t.strip()


def ler_arvore(origem):
    """origem: caminho de um .txt de árvore ou uma lista de linhas já lidas."""
    nos = []
    if isinstance(origem, str):
        with open(origem, "r", encoding="utf-8") as f:
            linhas_origem = f.read().split("\n")
    else:
        linhas_origem = origem
    if True:
        oculto_ate = None   # profundidade do nó oculto que ainda "cobre" os filhos (filho de nó oculto também não aparece)
        for linha in linhas_origem:
            linha = linha.rstrip("\n")
            if not linha.strip():
                continue
            m = RE_LINHA.match(linha)
            if not m:
                continue
            resto = m.group("resto")
            r = RE_RECT.search(resto)
            t = RE_TEXTO.search(resto)
            # dicas e placeholders entram na comparação como textos com prefixo
            extra = []
            for prefixo, rx in (("[dica] ", RE_DICA), ("[placeholder] ", RE_PLACEHOLDER)):
                e = rx.search(resto)
                if e:
                    extra.append(prefixo + normalizar_texto(e.group(1)))
            prof = len(m.group("ind")) // 2
            if oculto_ate is not None and prof <= oculto_ate:
                oculto_ate = None
            proprio = " oculto" in resto or "hidden" in resto
            if proprio and oculto_ate is None:
                oculto_ate = prof
            nos.append({
                "profundidade": prof,
                "classe": m.group("classe"),
                "global": m.group("global") or "",
                "rect": tuple(int(x) for x in r.groups()) if r else None,
                "texto": normalizar_texto(t.group(1)) if t else None,
                "extras": extra,
                "oculto": proprio or oculto_ate is not None,
            })
    return nos


def ler_arvores_todas(caminho):
    """Lê o arquivo consolidado do ui_dump (blocos '### nome' seguidos das linhas da árvore)."""
    blocos, atual = {}, None
    with open(caminho, "r", encoding="utf-8") as f:
        for linha in f.read().split("\n"):
            if linha.startswith("### "):
                atual = linha[4:].strip()
                blocos[atual] = []
            elif atual is not None:
                blocos[atual].append(linha)
    return blocos


def comparar_arvores(a_path, b_path, px):
    a, b = ler_arvore(a_path), ler_arvore(b_path)
    # Só o que o jogador pode ver: a migração para cenas cria nós que ficam ocultos até serem necessários.
    a, b = [n for n in a if not n["oculto"]], [n for n in b if not n["oculto"]]
    textos_a, textos_b = {}, {}
    for n in a:
        for t in ([n["texto"]] if n["texto"] else []) + n["extras"]:
            textos_a.setdefault(t, []).append(n)
    for n in b:
        for t in ([n["texto"]] if n["texto"] else []) + n["extras"]:
            textos_b.setdefault(t, []).append(n)
    so_antes = sorted(set(textos_a) - set(textos_b))
    so_depois = sorted(set(textos_b) - set(textos_a))
    movidos = []
    for t in sorted(set(textos_a) & set(textos_b)):
        ra = [n["rect"] for n in textos_a[t] if n["rect"]]
        rb = [n["rect"] for n in textos_b[t] if n["rect"]]
        if len(ra) != len(rb):
            movidos.append((t, "quantidade %d -> %d" % (len(ra), len(rb))))
            continue
        for x, y in zip(sorted(ra), sorted(rb)):
            # x,y são (x,y,w,h); compara posição do canto e do tamanho
            dx = max(abs(x[i] - y[i]) for i in range(4))
            if dx > px:
                movidos.append((t, "%s -> %s" % (x, y)))
                break
    globais_a = sorted({n["global"] for n in a if n["global"]})
    globais_b = sorted({n["global"] for n in b if n["global"]})
    return {
        "nos_antes": len(a), "nos_depois": len(b),
        "textos_so_antes": so_antes, "textos_so_depois": so_depois,
        "textos_movidos": movidos,
        "classes_globais_so_antes": sorted(set(globais_a) - set(globais_b)),
        "classes_globais_so_depois": sorted(set(globais_b) - set(globais_a)),
    }


def comparar_imagem(a_path, b_path, tol, destino_diff):
    a = Image.open(a_path).convert("RGB")
    b = Image.open(b_path).convert("RGB")
    if a.size != b.size:
        return {"erro": "tamanhos diferentes %s x %s" % (a.size, b.size)}
    r, g, bl = ImageChops.difference(a, b).split()
    m = ImageChops.lighter(ImageChops.lighter(r, g), bl)
    mascara = m.point(lambda p: 255 if p > tol else 0)
    mudou = mascara.histogram()[255]
    total = a.size[0] * a.size[1]
    caixa = mascara.getbbox()
    if destino_diff and mudou:
        base = Image.blend(b, Image.new("RGB", b.size, (0, 0, 0)), 0.55)
        realce = mascara.filter(ImageFilter.MaxFilter(5))
        base.paste(Image.new("RGB", b.size, (255, 40, 90)), mask=realce)
        os.makedirs(os.path.dirname(destino_diff), exist_ok=True)
        base.save(destino_diff)
    return {"pct": 100.0 * mudou / total, "pixels": mudou, "caixa": caixa}


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("antes", nargs="?", default="antes")
    ap.add_argument("depois", nargs="?", default="depois")
    ap.add_argument("--saida", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "tests", "_saida"))
    ap.add_argument("--tol", type=int, default=8, help="diferença mínima por canal (0-255) para contar o pixel como mudado")
    ap.add_argument("--limite", type=float, default=0.60, help="%% de pixels mudados acima da qual a captura é sinalizada")
    ap.add_argument("--px", type=int, default=3, help="tolerância (px) para posição/tamanho de controles com texto")
    ap.add_argument("--sem-diff", action="store_true", help="não gravar as imagens de diferença")
    args = ap.parse_args()

    saida = os.path.abspath(args.saida)
    pa, pb = os.path.join(saida, args.antes), os.path.join(saida, args.depois)
    for p in (pa, pb):
        if not os.path.isdir(p):
            print("não existe:", p)
            return 2
    destino = os.path.join(saida, "diff_%s_%s" % (args.antes, args.depois))
    linhas_md = ["# Comparação `%s` × `%s`" % (args.antes, args.depois), ""]
    sinalizado = False
    faltam = False

    pngs = sorted(f for f in os.listdir(pa) if f.endswith(".png"))
    pngs += sorted(f for f in os.listdir(pb) if f.endswith(".png") and f not in pngs)
    print("== capturas (limite %.2f %% dos pixels, tol %d) ==" % (args.limite, args.tol))
    linhas_md += ["## Capturas", "", "| captura | pixels mudados | região | veredito |", "|---|---:|---|---|"]
    for nome in pngs:
        fa, fb = os.path.join(pa, nome), os.path.join(pb, nome)
        if not (os.path.exists(fa) and os.path.exists(fb)):
            lado = "só em %s" % (args.antes if os.path.exists(fa) else args.depois)
            print("  %-42s %s" % (nome, lado))
            linhas_md.append("| %s | — | — | **falta** (%s) |" % (nome, lado))
            faltam = True
            continue
        r = comparar_imagem(fa, fb, args.tol, None if args.sem_diff else os.path.join(destino, nome))
        if "erro" in r:
            print("  %-42s %s" % (nome, r["erro"]))
            linhas_md.append("| %s | — | — | **%s** |" % (nome, r["erro"]))
            sinalizado = True
            continue
        ver = "ok" if r["pct"] <= args.limite else "REVER"
        sinalizado = sinalizado or ver != "ok"
        print("  %-42s %7.3f %%  %s  %s" % (nome, r["pct"], r["caixa"] or "", ver))
        linhas_md.append("| %s | %.3f %% | %s | %s |" % (nome, r["pct"], r["caixa"] or "—", ver))

    arv_a, arv_b = os.path.join(pa, "arvores"), os.path.join(pb, "arvores")
    todas_a, todas_b = os.path.join(pa, "arvores_todas.txt"), os.path.join(pb, "arvores_todas.txt")
    mem_a = mem_b = None
    if not (os.path.isdir(arv_a) and os.path.isdir(arv_b)) and os.path.exists(todas_a) and os.path.exists(todas_b):
        mem_a, mem_b = ler_arvores_todas(todas_a), ler_arvores_todas(todas_b)
    if mem_a is not None or (os.path.isdir(arv_a) and os.path.isdir(arv_b)):
        if mem_a is not None:
            txts = sorted(n + ".txt" for n in mem_a) + sorted(n + ".txt" for n in mem_b if n not in mem_a)
        else:
            txts = sorted(f for f in os.listdir(arv_a) if f.endswith(".txt"))
            txts += sorted(f for f in os.listdir(arv_b) if f.endswith(".txt") and f not in txts)
        print("\n== árvores de nós (posição ±%d px) ==" % args.px)
        linhas_md += ["", "## Árvores de nós", "",
                      "| árvore | nós antes → depois | textos só antes | textos só depois | movidos | veredito |",
                      "|---|---:|---:|---:|---:|---|"]
        detalhes = []
        for nome in txts:
            if mem_a is not None:
                fa, fb = mem_a.get(nome[:-4]), mem_b.get(nome[:-4])
                existe = fa is not None and fb is not None
                lado_a = fa is not None
            else:
                fa, fb = os.path.join(arv_a, nome), os.path.join(arv_b, nome)
                existe = os.path.exists(fa) and os.path.exists(fb)
                lado_a = os.path.exists(fa)
            if not existe:
                print("  %-42s só em %s" % (nome, args.antes if lado_a else args.depois))
                faltam = True
                continue
            r = comparar_arvores(fa, fb, args.px)
            limpo = not (r["textos_so_antes"] or r["textos_so_depois"] or r["textos_movidos"])
            sinalizado = sinalizado or not limpo
            print("  %-42s nós %4d -> %4d  só_antes=%d só_depois=%d movidos=%d  %s" % (
                nome, r["nos_antes"], r["nos_depois"], len(r["textos_so_antes"]), len(r["textos_so_depois"]),
                len(r["textos_movidos"]), "ok" if limpo else "REVER"))
            linhas_md.append("| %s | %d → %d | %d | %d | %d | %s |" % (
                nome, r["nos_antes"], r["nos_depois"], len(r["textos_so_antes"]), len(r["textos_so_depois"]),
                len(r["textos_movidos"]), "ok" if limpo else "REVER"))
            if not limpo:
                detalhes.append("### %s" % nome)
                for t in r["textos_so_antes"][:25]:
                    detalhes.append("- só antes: `%s`" % t)
                for t in r["textos_so_depois"][:25]:
                    detalhes.append("- só depois: `%s`" % t)
                for t, d in r["textos_movidos"][:25]:
                    detalhes.append("- movido: `%s` %s" % (t, d))
                detalhes.append("")
            if r["classes_globais_so_antes"] or r["classes_globais_so_depois"]:
                detalhes.append("### %s (classes globais)" % nome)
                for c in r["classes_globais_so_antes"]:
                    detalhes.append("- some: `%s`" % c)
                for c in r["classes_globais_so_depois"]:
                    detalhes.append("- aparece: `%s`" % c)
                detalhes.append("")
        if detalhes:
            linhas_md += [""] + detalhes

    md = os.path.join(saida, "comparacao_%s_%s.md" % (args.antes, args.depois))
    with open(md, "w", encoding="utf-8") as f:
        f.write("\n".join(linhas_md) + "\n")
    print("\nrelatório:", md)
    if not args.sem_diff:
        print("diferenças visuais:", destino)
    if faltam:
        return 2
    return 1 if sinalizado else 0


if __name__ == "__main__":
    sys.exit(main())
