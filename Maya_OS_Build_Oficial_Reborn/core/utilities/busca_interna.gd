class_name BuscaInterna
extends RefCounted
## Busca do Navegador SIMULADO (§20): normaliza o que o jogador digitou, valida, consulta o dicionário interno
## (core/data/narrativa/busca_web.json) e devolve a página interna a carregar. SEM autoloads e SEM rede: as funções são puras (a lista de páginas
## que já existem entra por parâmetro), então os testes chamam isto direto.
##
## REGRAS (nesta ordem):
##   1. Entrada que não é texto, ou vazia depois de normalizar -> "vazia" (nada acontece).
##   2. Entrada com caracteres de comando (`; | & ` $ < > \`) ou controle -> "invalida": mostra uma página de erro e NUNCA executa nada
##      (o projeto não tem como executar comandos externos; esta checagem torna isso explícito para o jogador e para os testes).
##   3. Entrada com `://` -> endereço: `humax://...` abre a página interna; qualquer outro esquema (http, https, file, nexus...) -> "externa" (bloqueada).
##   4. Palavras -> dicionário: 1º uma palavra-chave igual à consulta inteira; 2º uma palavra-chave cujas palavras aparecem todas na consulta
##      (a mais longa vence; empate = a primeira do arquivo). A entrada pode apontar para uma página que já existe (humax://status) ou ser uma
##      página própria (humax://busca/<id>, com título e conteúdo na própria entrada).
##   5. Sem correspondência: uma palavra só que seja uma página interna existente (comportamento antigo: "status" -> humax://status); senão
##      a página "sem resultado" (placeholder), que mostra a consulta (com BBCode escapado).
## Todas as páginas da busca ficam sob humax://busca/ e entram no histórico como qualquer outra.

const ARQUIVO := "res://core/data/narrativa/busca_web.json"
const ESQUEMA := "humax://"
const PREFIXO_BUSCA := "humax://busca/"
const ID_SEM_RESULTADO := "sem_resultado"
const ID_INVALIDA := "invalida"
const MAX_ENTRADA := 200
const PROIBIDOS := ";|&`$<>\\"
const PLACEHOLDER_TITULO_SEM_RESULTADO := "[TITULO_SEM_RESULTADO]"
const PLACEHOLDER_CONTEUDO_SEM_RESULTADO := "[CONTEUDO_SEM_RESULTADO]"

const _DE := "áàâãäéèêëíìîïóòôõöúùûüçñ"
const _PARA := "aaaaaeeeeiiiiooooouuuucn"

static var _entradas: Array = []
static var _sem_resultado: Dictionary = {}
static var _carregado: bool = false
## Motivo da última falha ao ler o arquivo ("" quando leu bem ou ainda não leu).
static var ultimo_erro: String = ""


# ------------------------------------------------------------------ dados
static func entradas() -> Array:
	if not _carregado:
		recarregar(ARQUIVO)
	return _entradas


## Lê `caminho`. Entradas inválidas (sem id, sem palavras-chave ou sem página) são ignoradas; arquivo ausente/ilegível deixa só o padrão
## (nenhuma entrada, página "sem resultado" em placeholder). Devolve false se o arquivo faltou ou era ilegível.
static func recarregar(caminho: String = ARQUIVO) -> bool:
	_carregado = true
	_entradas = []
	_sem_resultado = {"titulo": PLACEHOLDER_TITULO_SEM_RESULTADO, "conteudo": PLACEHOLDER_CONTEUDO_SEM_RESULTADO, "is_placeholder": true}
	ultimo_erro = ""
	if not FileAccess.file_exists(caminho):
		ultimo_erro = "arquivo ausente: %s" % caminho
		return false
	var analisador := JSON.new()
	if analisador.parse(FileAccess.get_file_as_string(caminho)) != OK or not (analisador.data is Dictionary):
		ultimo_erro = "JSON inválido: %s" % caminho
		return false
	var raiz: Dictionary = analisador.data
	var vistos: Dictionary = {}
	var lista: Variant = raiz.get("entradas")
	if lista is Array:
		for item in lista as Array:
			var entrada := _entrada_valida(item)
			if entrada.is_empty() or vistos.has(str(entrada["id"])):
				continue
			vistos[str(entrada["id"])] = true
			_entradas.append(entrada)
	var sem: Variant = raiz.get("sem_resultado")
	if sem is Dictionary:
		for chave in ["titulo", "conteudo"]:
			if (sem as Dictionary).get(chave) is String and str((sem as Dictionary)[chave]).strip_edges() != "":
				_sem_resultado[chave] = (sem as Dictionary)[chave]
		_sem_resultado["is_placeholder"] = bool((sem as Dictionary).get("is_placeholder", true))
	return true


static func _entrada_valida(item: Variant) -> Dictionary:
	if not (item is Dictionary):
		return {}
	var d: Dictionary = item
	var id_entrada := str(d.get("id", "")).strip_edges()
	var pagina := str(d.get("pagina", "")).strip_edges()
	var brutas: Variant = d.get("palavras_chave")
	if id_entrada == "" or pagina == "" or not (brutas is Array):
		return {}
	var chaves: Array = []
	for bruta in brutas as Array:
		var chave := normalizar(bruta)
		if chave != "" and not chaves.has(chave):
			chaves.append(chave)
	if chaves.is_empty():
		return {}
	return {
		"id": id_entrada, "palavras_chave": chaves, "pagina": pagina, "titulo": str(d.get("titulo", "")), "conteudo": str(d.get("conteudo", "")),
		"is_placeholder": bool(d.get("is_placeholder", false)),
	}


# ------------------------------------------------------------------ normalização e validação
## Minúsculas, sem acentos, sem caracteres de controle, espaços colapsados, no máximo MAX_ENTRADA caracteres. Não-texto vira "".
static func normalizar(entrada: Variant) -> String:
	if typeof(entrada) != TYPE_STRING and typeof(entrada) != TYPE_STRING_NAME:
		return ""
	var minusculo := str(entrada).to_lower()
	var saida := ""
	var anterior_espaco := true   # corta espaços do começo
	for i in minusculo.length():
		var c: String = minusculo[i]
		var codigo := c.unicode_at(0)
		if codigo == 9 or codigo == 10 or codigo == 13 or c == " ":
			if not anterior_espaco:
				saida += " "
			anterior_espaco = true
			continue
		if codigo < 32 or codigo == 127:
			continue
		var pos := _DE.find(c)
		saida += _PARA[pos] if pos >= 0 else c
		anterior_espaco = false
	saida = saida.strip_edges()
	return saida.substr(0, MAX_ENTRADA).strip_edges()


## A entrada traz algum caractere de comando ou de controle (antes de normalizar)? Entradas assim viram "invalida".
static func tem_caractere_proibido(entrada: Variant) -> bool:
	if typeof(entrada) != TYPE_STRING and typeof(entrada) != TYPE_STRING_NAME:
		return false
	var bruta := str(entrada)
	for i in bruta.length():
		var c: String = bruta[i]
		var codigo := c.unicode_at(0)
		if PROIBIDOS.contains(c) or (codigo < 32 and codigo != 9 and codigo != 10 and codigo != 13) or codigo == 127:
			return true
	return false


# ------------------------------------------------------------------ busca
## Decide o que carregar. Devolve {tipo, url, consulta, entrada_id}:
##   tipo: "vazia" | "invalida" | "externa" | "interna" (humax://... digitado) | "pagina" (achou no dicionário ou página existente) | "sem_resultado".
## `url` é sempre uma URL carregável pelo navegador (vazia só em "vazia"). `paginas_conhecidas`: as páginas internas que existem (chave = url).
static func buscar(entrada: Variant, paginas_conhecidas: Dictionary = {}) -> Dictionary:
	var r := {"tipo": "vazia", "url": "", "consulta": "", "entrada_id": ""}
	var consulta := normalizar(entrada)
	r["consulta"] = consulta
	if consulta == "":
		return r
	if tem_caractere_proibido(entrada):
		r["tipo"] = "invalida"
		r["url"] = PREFIXO_BUSCA + ID_INVALIDA
		return r
	if consulta.contains("://"):
		r["tipo"] = "interna" if consulta.begins_with(ESQUEMA) else "externa"
		r["url"] = consulta
		return r
	var achada := _procurar(consulta)
	if not achada.is_empty():
		r["tipo"] = "pagina"
		r["entrada_id"] = str(achada["id"])
		var pagina := str(achada["pagina"])
		r["url"] = pagina if pagina.begins_with(ESQUEMA) else PREFIXO_BUSCA + pagina
		return r
	var direto := ESQUEMA + consulta
	if not consulta.contains(" ") and paginas_conhecidas.has(direto):
		r["tipo"] = "pagina"
		r["url"] = direto
		return r
	r["tipo"] = "sem_resultado"
	r["url"] = "%s%s?q=%s" % [PREFIXO_BUSCA, ID_SEM_RESULTADO, consulta.uri_encode()]
	return r


static func _procurar(consulta: String) -> Dictionary:
	var palavras := consulta.split(" ", false)
	var melhor: Dictionary = {}
	var melhor_tamanho := 0
	# 1º: palavra-chave IGUAL à consulta inteira (vence qualquer outra).
	for entrada in entradas():
		if (entrada as Dictionary)["palavras_chave"].has(consulta):
			return entrada
	# 2º: palavra-chave cujas palavras estão todas na consulta; a de mais palavras vence, depois a primeira do arquivo.
	for entrada in entradas():
		for chave in (entrada as Dictionary)["palavras_chave"]:
			var partes: PackedStringArray = str(chave).split(" ", false)
			var todas := not partes.is_empty()
			for parte in partes:
				if not palavras.has(parte):
					todas = false
					break
			if todas and partes.size() > melhor_tamanho:
				melhor = entrada
				melhor_tamanho = partes.size()
	return melhor


## Conteúdo de uma página sob humax://busca/: {ok, titulo, texto} (BBCode). Nunca falha: id desconhecido cai na página "sem resultado".
static func pagina_da_busca(url: String) -> Dictionary:
	if not url.begins_with(PREFIXO_BUSCA):
		return {"ok": false, "titulo": "Página não encontrada", "texto": "[b]404[/b]\nNão existe nada em [code]%s[/code]." % UtilTexto.escapar_bbcode(url)}
	var resto := url.substr(PREFIXO_BUSCA.length())
	var id_pagina := resto.get_slice("?", 0)
	if id_pagina == ID_INVALIDA:
		return {
			"ok": false, "titulo": "Entrada inválida",
			"texto": "[b]Entrada inválida[/b]\nO que você digitou tem caracteres que o navegador não aceita. Este navegador só abre páginas internas e [b]nunca executa comandos[/b].\nUse apenas palavras ou um endereço [code]humax://[/code].",
		}
	if id_pagina != ID_SEM_RESULTADO:
		for entrada in entradas():
			if str((entrada as Dictionary)["id"]) == id_pagina or str((entrada as Dictionary)["pagina"]) == id_pagina:
				return {"ok": true, "titulo": _ou(str((entrada as Dictionary)["titulo"]), id_pagina), "texto": _ou(str((entrada as Dictionary)["conteudo"]), "")}
	var consulta := ""
	if resto.contains("?q="):
		consulta = resto.get_slice("?q=", 1).uri_decode()
	var corpo := str(_sem_resultado.get("conteudo", PLACEHOLDER_CONTEUDO_SEM_RESULTADO))
	if consulta != "":
		corpo += "\n\nPesquisa: [code]%s[/code]" % UtilTexto.escapar_bbcode(consulta.substr(0, MAX_ENTRADA))
	return {"ok": false, "titulo": str(_sem_resultado.get("titulo", PLACEHOLDER_TITULO_SEM_RESULTADO)), "texto": corpo}


static func _ou(texto: String, padrao: String) -> String:
	return texto if texto.strip_edges() != "" else padrao
