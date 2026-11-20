extends Node
## Sistema de arquivos virtual (VFS). Existe somente em memória: nenhum caminho daqui toca o disco real.
## Toda entrada de caminho passa por normalizar(); caminhos fora da árvore simplesmente "não existem".
## O estado do jogador é salvo como um log de operações (criar/texto/mover/decifrar/revelar), reaplicado
## sobre vfs_inicial.json no carregamento. Assim atualizações dos dados iniciais não quebram saves antigos.
##
## ESTADOS DO NÓ (§23, modelo em ArquivoVirtual): pasta acessível/bloqueada (puzzle `requer_flag`), arquivo legível, criptografado, corrompido
## (leitura degradada e determinística, sem escrita), bloqueado/desbloqueado narrativamente (`requisitos`). `estado_do_no`/`descrever`
## respondem isso a quem chamar (Explorador, Terminal, Leitor, Galeria...), e `ler_texto` nunca expõe conteúdo de arquivo bloqueado ou cifrado.
## As pastas ficam acessíveis desde o início (regra vfs.pastas_acessiveis_desde_o_inicio): o conteúdo continua protegido pelos estados do
## ARQUIVO, nunca por esconder a pasta. (Roteiro v2.0: `visivel_se` esconde itens até a história chegar neles, como a pasta Rafael.)

signal arvore_alterada(pasta: String)
signal arquivo_alterado(caminho: String)
signal chave_incorreta(id_puzzle: String)

const ARQUIVO_INICIAL := "res://core/data/vfs_inicial.json"
const RAIZ := "/"
const PASTA_LIXEIRA := "/lixeira"
const PASTA_USUARIO := "/home/usuario"
const PASTA_APLICATIVOS := "/sistema/aplicativos"
const TAMANHO_MAX_NOME := 64
const TAMANHO_MAX_TEXTO := 200000
const MAX_CRIADOS := 300
const PROIBIDOS := "\\/:*?\"<>|"
## Caminhos de arquivos do sistema que mudaram no rebranding (NEXUS -> Maya / HumaxOS). Os salvamentos antigos citam os nomes
## antigos no log de operações; _caminho_atual() os traduz ao reaplicar o log. Chave: o caminho antigo em minúsculas.
const CAMINHOS_ANTIGOS: Dictionary = {
	"/sistema/system_logs/nexus_audit.log": "/sistema/System_Logs/maya_audit.log",   # marca-legada
	"/sistema/nexus": "/sistema/maya",   # marca-legada
	"/sistema/nexus/core.nexus": "/sistema/maya/core.maya",   # marca-legada
	"/sistema/nexus/diretrizes.nexus": "/sistema/maya/diretrizes.maya",   # marca-legada
	"/home/usuario/downloads/nexuscore.exe": "/home/usuario/Downloads/MayaCore.exe",   # marca-legada
	"/home/usuario/downloads/memorias_backup/kill_switch.nexus": "/home/usuario/Downloads/memorias_backup/kill_switch.maya",   # marca-legada
}

var _nos: Dictionary = {}      # caminho canônico -> nó
var _indice: Dictionary = {}   # caminho em minúsculas -> caminho canônico
var _filhos: Dictionary = {}   # pasta canônica -> Array de caminhos canônicos
var _ids: Dictionary = {}      # id estável do nó -> caminho canônico
var _operacoes: Array = []
var _criados: int = 0


func _ready() -> void:
	carregar_inicial()


# ------------------------------------------------------------------ carga
func carregar_inicial() -> void:
	_nos.clear()
	_indice.clear()
	_filhos.clear()
	_ids.clear()
	_operacoes.clear()
	_criados = 0
	_registrar({"caminho": RAIZ, "tipo": "pasta", "somente_leitura": true}, true)
	var lista: Array = []
	if FileAccess.file_exists(ARQUIVO_INICIAL):
		var json: Variant = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO_INICIAL))
		if json is Dictionary and json.get("nos") is Array:
			lista = json["nos"]
	for item in lista:
		if item is Dictionary:
			var no: Dictionary = item.duplicate(true)
			no["caminho"] = normalizar(str(no.get("caminho", "")))
			if not _registrar(no, false):
				push_warning("VFS: nó inválido ignorado: %s" % str(item.get("caminho", "?")))
	if _nos.size() <= 1:
		push_warning("VFS: dados iniciais ausentes; criando árvore mínima.")
		for caminho in ["/home", "/home/usuario", "/home/usuario/Documentos", "/lixeira"]:
			_registrar({"caminho": caminho, "tipo": "pasta", "somente_leitura": caminho == "/home" or caminho == "/lixeira"}, false)
	arvore_alterada.emit(RAIZ)


func serializar() -> Dictionary:
	return {"versao": 1, "operacoes": _operacoes.duplicate(true)}


func desserializar(dados: Dictionary) -> void:
	carregar_inicial()
	var ops: Variant = dados.get("operacoes", [])
	if not (ops is Array):
		return
	for op in ops:
		if op is Dictionary:
			_aplicar(_operacao_atual(op), true)
	arvore_alterada.emit(RAIZ)


## Cópia da operação com os caminhos de antes do rebranding trocados pelos atuais. Operações novas passam intactas.
func _operacao_atual(op: Dictionary) -> Dictionary:
	var nova: Dictionary = op.duplicate(true)
	for campo in ["c", "de", "para", "origem_lixeira"]:
		if nova.has(campo):
			nova[campo] = _caminho_atual(str(nova[campo]))
	var no: Variant = nova.get("no")
	if no is Dictionary:
		var no_dic: Dictionary = no
		no_dic["caminho"] = _caminho_atual(str(no_dic.get("caminho", "")))
	return nova


## O caminho atual de um caminho citado por um salvamento anterior ao rebranding (ou o próprio caminho, se não mudou).
func _caminho_atual(caminho: String) -> String:
	var n := normalizar(caminho)
	return str(CAMINHOS_ANTIGOS.get(n.to_lower(), caminho))


# ------------------------------------------------------------------ caminhos
## Retorna o caminho absoluto limpo (sem "." e ".." e sem barra final) ou "" se for inválido.
func normalizar(caminho: String) -> String:
	var c := caminho.strip_edges()
	if c == "" or not c.begins_with("/"):
		return ""
	var pilha: Array = []
	for parte in c.split("/", false):
		if parte == ".":
			continue
		if parte == "..":
			if not pilha.is_empty():
				pilha.pop_back()
			continue
		if not _parte_valida(parte):
			return ""
		pilha.append(parte)
	if pilha.is_empty():
		return RAIZ
	return "/" + "/".join(pilha)


## Resolve uma entrada digitada (relativa ao diretório atual, "~" ou absoluta). Retorna "" se inválida.
func resolver_relativo(base: String, entrada: String) -> String:
	var e := entrada.strip_edges()
	if e == "":
		return normalizar(base)
	if e == "~":
		return PASTA_USUARIO
	if e.begins_with("~/"):
		return normalizar(PASTA_USUARIO + e.substr(1))
	if e.begins_with("/"):
		return normalizar(e)
	var b := normalizar(base)
	if b == "":
		return ""
	return normalizar(b + "/" + e)


## Caminho canônico existente (com a caixa original) ou "".
func resolver(caminho: String) -> String:
	var n := normalizar(caminho)
	if n == "":
		return ""
	return str(_indice.get(n.to_lower(), ""))


## Chave estável em minúsculas para flags (ex.: "pasta_visitada:/home/usuario/documentos").
func chave(caminho: String) -> String:
	return resolver(caminho).to_lower()


func caminho_pai(caminho: String) -> String:
	var n := normalizar(caminho)
	if n == "" or n == RAIZ:
		return RAIZ
	var i := n.rfind("/")
	if i <= 0:
		return RAIZ
	return n.substr(0, i)


func nome_do_caminho(caminho: String) -> String:
	var n := normalizar(caminho)
	if n == "" or n == RAIZ:
		return "/"
	return n.substr(n.rfind("/") + 1)


func juntar(pasta: String, nome: String) -> String:
	if pasta == RAIZ:
		return "/" + nome
	return pasta + "/" + nome


func validar_nome(nome: String) -> bool:
	var n := nome.strip_edges()
	if n != nome or n.length() == 0 or n.length() > TAMANHO_MAX_NOME:
		return false
	if n == "." or n == "..":
		return false
	return _parte_valida(n)


func nome_unico(pasta: String, base: String) -> String:
	var p := resolver(pasta)
	if p == "":
		return base
	var candidato := base
	var i := 2
	while _indice.has(juntar(p, candidato).to_lower()):
		candidato = "%s (%d)" % [base, i]
		i += 1
	return candidato


# ------------------------------------------------------------------ consulta
func existe(caminho: String) -> bool:
	return resolver(caminho) != ""


func eh_pasta(caminho: String) -> bool:
	var c := resolver(caminho)
	return c != "" and str(_nos[c].get("tipo", "")) == "pasta"


func eh_arquivo(caminho: String) -> bool:
	var c := resolver(caminho)
	return c != "" and str(_nos[c].get("tipo", "")) == "arquivo"


## Nó (somente leitura para quem chama). Dicionário vazio quando não existe.
func obter_no(caminho: String) -> Dictionary:
	var c := resolver(caminho)
	if c == "":
		return {}
	return _nos[c]


## O jogador pode renomear/excluir este item? (nada de sistema, somente leitura ou essencial para a história)
func pode_alterar(caminho: String) -> bool:
	var c := resolver(caminho)
	return c != "" and _pode_alterar(c)


func somente_leitura(caminho: String) -> bool:
	var c := resolver(caminho)
	if c == "":
		return true
	return bool(_nos[c].get("somente_leitura", false))


## Visível agora? `visivel_se` (condições do roteiro: "flag:x", "!flag:y", "perm:z"...) decide se o nó existe para o jogador neste ponto da história.
## Arquivo oculto só aparece com "Mostrar arquivos ocultos" (sempre disponível; não depende de nenhum desbloqueio).
func visivel(no: Dictionary, mostrar_ocultos: bool = false) -> bool:
	if no.has("visivel_se") and not GerenciadorEstado.avaliar_condicao(no["visivel_se"]):
		return false
	if bool(no.get("oculto", false)) and not bool(no.get("revelado", false)):
		return mostrar_ocultos
	return true


## Pastas com "requer_flag" aparecem na listagem, mas só abrem depois do puzzle.
func bloqueada(no: Dictionary) -> bool:
	var flag := str(no.get("requer_flag", ""))
	return flag != "" and not GerenciadorEstado.tem_flag(flag)


## Todos os ancestrais visíveis e destrancados? Usado pelo terminal e pela busca.
func acessivel(caminho: String, mostrar_ocultos: bool = false) -> bool:
	var c := resolver(caminho)
	if c == "":
		return false
	var atual := c
	while atual != RAIZ:
		var no: Dictionary = _nos[atual]
		if not visivel(no, mostrar_ocultos):
			return false
		if atual != c and bloqueada(no):
			return false
		atual = caminho_pai(atual)
	return true


func listar(pasta: String, mostrar_ocultos: bool = false) -> Array:
	var saida: Array = []
	var p := resolver(pasta)
	if p == "" or not _filhos.has(p):
		return saida
	for c in _filhos[p]:
		var no: Dictionary = _nos[c]
		if visivel(no, mostrar_ocultos):
			saida.append(no)
	saida.sort_custom(_ordenar_nos)
	return saida


func buscar(texto: String, limite: int = 20) -> Array:
	var termo := texto.strip_edges().to_lower()
	var saida: Array = []
	if termo.length() < 2:
		return saida
	for c in _nos:
		if c == RAIZ:
			continue
		var no: Dictionary = _nos[c]
		if nome_do_caminho(c).to_lower().contains(termo) and visivel(no, false) and acessivel(c, false):
			saida.append(no)
	saida.sort_custom(_ordenar_nos)
	if saida.size() > limite:
		saida.resize(limite)
	return saida


## Texto do arquivo conforme o dia atual (ou o texto editado pelo jogador). Criptografado ou bloqueado narrativamente => "" (nada é exposto);
## corrompido => o conteúdo DEGRADADO, sempre o mesmo (ArquivoVirtual.texto_visivel).
func ler_texto(caminho: String) -> String:
	var c := resolver(caminho)
	if c == "":
		return ""
	var no: Dictionary = _nos[c]
	if str(no.get("tipo", "")) != "arquivo":
		return ""
	return ArquivoVirtual.texto_visivel(no, conteudo_do_no(no), estado_do_no(no))


func conteudo_do_no(no: Dictionary) -> String:
	if no.has("conteudo_usuario"):
		return str(no["conteudo_usuario"])
	var condicional: Variant = no.get("conteudo_se")
	if condicional is Array:
		for alt in condicional:
			if alt is Dictionary and GerenciadorEstado.avaliar_condicao((alt as Dictionary).get("se")):
				return str((alt as Dictionary).get("conteudo", ""))
	return str(no.get("conteudo", ""))


func esta_criptografado(no: Dictionary) -> bool:
	return bool(no.get("criptografado", false)) and not bool(no.get("decifrado", false))


func eh_executavel(no: Dictionary) -> bool:
	return bool(no.get("executavel", false))


func tamanho_legivel(no: Dictionary) -> String:
	if str(no.get("tipo", "")) == "pasta":
		return "—"
	var proc: Variant = no.get("proc")
	if proc is Dictionary:
		return "1,4 MB" if str(proc.get("tipo", "")) == "imagem" else "262 KB"
	var bytes := conteudo_do_no(no).to_utf8_buffer().size()
	if bool(no.get("criptografado", false)) and bytes == 0:
		bytes = 2048
	if bytes < 1024:
		return "%d B" % bytes
	return ("%.1f KB" % (float(bytes) / 1024.0)).replace(".", ",")


# ------------------------------------------------------------------ estados do nó (§23)
## Os requisitos narrativos do arquivo estão atendidos agora? (Sem requisitos: sempre.)
func requisitos_atendidos(no: Dictionary) -> bool:
	var requisitos: Variant = no.get("requisitos", [])
	if not (requisitos is Array) or (requisitos as Array).is_empty():
		return true
	return GerenciadorEstado.avaliar_condicao(requisitos)


## Arquivo com requisitos ainda não atendidos: aparece na lista, mas não pode ser aberto, lido nem decifrado.
func bloqueado_narrativamente(no: Dictionary) -> bool:
	return str(no.get("tipo", "")) == "arquivo" and not requisitos_atendidos(no)


func esta_corrompido(no: Dictionary) -> bool:
	return ArquivoVirtual.esta_corrompido(no)


## Estado do nó agora (ArquivoVirtual.ESTADO_*). Dicionário vazio => "".
func estado_do_no(no: Dictionary) -> String:
	if no.is_empty():
		return ""
	return ArquivoVirtual.estado(no, requisitos_atendidos(no), bloqueada(no))


func pode_ler(no: Dictionary) -> bool:
	return ArquivoVirtual.pode_ler(estado_do_no(no))


func pode_escrever(no: Dictionary) -> bool:
	return ArquivoVirtual.pode_escrever(no, estado_do_no(no))


## Nó pelo id estável (o id não muda ao renomear ou mover). Vazio se não existir.
func obter_por_id(id_no: String) -> Dictionary:
	var c := str(_ids.get(id_no, ""))
	if c == "" or not _nos.has(c):
		return {}
	return _nos[c]


## Ficha do nó (somente leitura) para `stat`, dicas e testes.
func descrever(caminho: String) -> Dictionary:
	var c := resolver(caminho)
	if c == "":
		return {}
	var no: Dictionary = _nos[c]
	var estado := estado_do_no(no)
	var arquivo := str(no.get("tipo", "")) == "arquivo"
	var leitura := "negada"
	if arquivo:
		if estado == ArquivoVirtual.ESTADO_CORROMPIDO:
			leitura = "degradada"
		elif ArquivoVirtual.pode_ler(estado):
			leitura = "permitida"
	var meta: Dictionary = {}
	if no.get("meta") is Dictionary:
		meta = (no["meta"] as Dictionary).duplicate(true)
	var requisitos: Array = []
	if no.get("requisitos") is Array:
		requisitos = (no["requisitos"] as Array).duplicate()
	return {
		"id": str(no.get("id", "")), "nome": nome_do_caminho(c), "caminho": c, "tipo": str(no.get("tipo", "")),
		"tipo_arquivo": str(no.get("tipo_arquivo", "")), "estado": estado, "rotulo": ArquivoVirtual.rotulo(estado),
		"leitura": leitura, "escrita": "permitida" if (arquivo and pode_escrever(no)) else "negada",
		"criptografado": bool(no.get("criptografado", false)), "decifrado": bool(no.get("decifrado", false)),
		"corrompido": bool(no.get("corrompido", false)), "reparado": bool(no.get("reparado", false)),
		"requisitos": requisitos, "requisitos_atendidos": requisitos_atendidos(no),
		"persistente": bool(no.get("persistente", true)), "is_placeholder": bool(no.get("is_placeholder", false)),
		"meta": meta, "tamanho": tamanho_legivel(no),
	}


## Repara um arquivo corrompido (efeito da narrativa): passa a ler o conteúdo inteiro. Devolve true se o estado mudou.
func reparar(caminho: String) -> bool:
	var c := resolver(caminho)
	if c == "" or str(_nos[c].get("tipo", "")) != "arquivo":
		return false
	var no: Dictionary = _nos[c]
	if not bool(no.get("corrompido", false)) or bool(no.get("reparado", false)):
		return false
	no["reparado"] = true
	_registrar_operacao_do_no(no, {"op": "reparar", "c": c})
	arquivo_alterado.emit(c)
	arvore_alterada.emit(caminho_pai(c))
	return true


# ------------------------------------------------------------------ escrita (somente dentro do VFS)
func escrever_texto(caminho: String, texto: String) -> bool:
	var c := resolver(caminho)
	if c == "" or texto.length() > TAMANHO_MAX_TEXTO:
		return false
	var no: Dictionary = _nos[c]
	if str(no.get("tipo", "")) != "arquivo" or not pode_escrever(no):
		return false
	_definir_texto(c, texto)
	_registrar_operacao_do_no(no, {"op": "texto", "c": c, "t": texto})
	arquivo_alterado.emit(c)
	return true


func criar_arquivo(pasta: String, nome: String, conteudo: String = "") -> String:
	return _criar(pasta, nome, "arquivo", conteudo)


func criar_pasta(pasta: String, nome: String) -> String:
	return _criar(pasta, nome, "pasta", "")


func renomear(caminho: String, novo_nome: String) -> String:
	var c := resolver(caminho)
	if c == "" or not validar_nome(novo_nome) or not _pode_alterar(c):
		return ""
	var destino := juntar(caminho_pai(c), novo_nome)
	if _indice.has(destino.to_lower()) and destino.to_lower() != c.to_lower():
		return ""
	_mover_no(c, destino)
	_registrar_operacao({"op": "mover", "de": c, "para": destino})
	arvore_alterada.emit(caminho_pai(destino))
	return destino


## "Excluir" nunca apaga de verdade: move para /lixeira (reversível). Arquivos essenciais e do sistema não saem do lugar.
func mover_para_lixeira(caminho: String) -> bool:
	var c := resolver(caminho)
	if c == "" or not _pode_alterar(c) or c.to_lower().begins_with(PASTA_LIXEIRA):
		return false
	var nome := nome_unico(PASTA_LIXEIRA, nome_do_caminho(c))
	var destino := juntar(PASTA_LIXEIRA, nome)
	var origem := caminho_pai(c)
	_mover_no(c, destino)
	_nos[destino]["origem_lixeira"] = origem
	_registrar_operacao({"op": "mover", "de": c, "para": destino, "origem_lixeira": origem})
	arvore_alterada.emit(origem)
	arvore_alterada.emit(PASTA_LIXEIRA)
	return true


func restaurar_da_lixeira(caminho: String) -> bool:
	var c := resolver(caminho)
	if c == "" or not caminho_pai(c).to_lower() == PASTA_LIXEIRA:
		return false
	var no: Dictionary = _nos[c]
	if bool(no.get("somente_leitura", false)):
		return false
	var pasta := str(no.get("origem_lixeira", PASTA_USUARIO))
	if not eh_pasta(pasta):
		pasta = PASTA_USUARIO
	var nome := nome_unico(pasta, nome_do_caminho(c))
	var destino := juntar(resolver(pasta), nome)
	_mover_no(c, destino)
	_registrar_operacao({"op": "mover", "de": c, "para": destino})
	arvore_alterada.emit(PASTA_LIXEIRA)
	arvore_alterada.emit(caminho_pai(destino))
	return true


## Move um nó (e o que há dentro dele) por decisão do ROTEIRO (a Maya organizando, por exemplo). Entra no log de operações do salvamento.
## Devolve true se o item está no destino depois da chamada; false se a origem não existe ou o destino é inválido/ocupado.
func mover(de: String, para: String) -> bool:
	var origem := resolver(de)
	var destino := normalizar(para)
	if origem == "" or destino == "" or origem == RAIZ:
		return false
	if _indice.has(destino.to_lower()):
		return str(_indice[destino.to_lower()]) == origem
	var pasta_origem := caminho_pai(origem)
	_aplicar({"op": "mover", "de": origem, "para": destino}, false)
	var moveu := _indice.has(destino.to_lower())
	if moveu:
		arvore_alterada.emit(pasta_origem)
		arvore_alterada.emit(caminho_pai(destino))
	return moveu


## O jogador abriu `caminho` (Leitor, Galeria ou Explorador): aplica UMA vez os efeitos do roteiro do nó (`ao_abrir`: flags de descoberta e a
## fala da Maya) e devolve o que a interface deve fazer ({"minigame": id} para a trava do Rafael).
func ao_abrir(caminho: String) -> Dictionary:
	var c := resolver(caminho)
	if c == "":
		return {}
	var no: Dictionary = _nos[c]
	var saida: Dictionary = {}
	if str(no.get("abre_minigame", "")) != "" and not GerenciadorEstado.tem_flag(str(no.get("flag_minigame_resolvido", ""))):
		saida["minigame"] = str(no["abre_minigame"])
	var chave_unica := "aberto:" + str(no.get("id", c))
	if no.get("ao_abrir") is Array and not GerenciadorEstado.tem_flag(chave_unica):
		GerenciadorEstado.set_flag(chave_unica, true)
		FluxoRoteiro.aplicar_efeitos(no["ao_abrir"], "arquivo:" + str(no.get("id", c)))
	return saida


## Ao ligar "Mostrar arquivos ocultos" dentro de `pasta`: se há um segredo oculto no caminho (o bloco da pasta do Rafael), ele foi encontrado.
func ao_mostrar_ocultos(pasta: String) -> bool:
	var p := resolver(pasta)
	if p == "":
		return false
	var achou := false
	for c in _filhos.get(p, []):
		var no: Dictionary = _nos[c]
		if bool(no.get("oculto", false)) and not bool(no.get("revelado", false)) and visivel(no, true):
			if no.get("ao_encontrar") is Array:
				FluxoRoteiro.aplicar_efeitos(no["ao_encontrar"], "oculto:" + str(no.get("id", c)))
				achou = true
	return achou


## Marca como visível um item oculto (usado pelos eventos da narrativa).
func revelar(caminho: String) -> bool:
	var c := resolver(caminho)
	if c == "":
		return false
	_nos[c]["revelado"] = true
	_registrar_operacao({"op": "revelar", "c": c})
	arvore_alterada.emit(caminho_pai(c))
	return true


# ------------------------------------------------------------------ puzzle de arquivos criptografados
func tentar_decifrar(caminho: String, tentativa: String) -> bool:
	var c := resolver(caminho)
	if c == "":
		return false
	var no: Dictionary = _nos[c]
	if not bool(no.get("criptografado", false)) or bool(no.get("decifrado", false)):
		return true
	if not requisitos_atendidos(no):
		return false   # ainda bloqueado narrativamente: nem tentar a chave vale (e a tentativa não conta como falha)
	var aceitas: Variant = no.get("chaves_sha256", [])
	if aceitas is Array and aceitas.has(UtilTexto.hash_chave(tentativa)):
		_decifrar(c)
		_registrar_operacao_do_no(no, {"op": "decifrar", "c": c})
		return true
	var id_puzzle := str(no.get("id_puzzle", "arquivo"))
	GerenciadorEstado.incrementar_flag("falhas_chave_" + id_puzzle)
	chave_incorreta.emit(id_puzzle)
	return false


# ------------------------------------------------------------------ internos
func _parte_valida(parte: String) -> bool:
	if parte.length() == 0 or parte.length() > TAMANHO_MAX_NOME:
		return false
	for i in parte.length():
		var codigo := parte.unicode_at(i)
		if codigo < 32 or codigo == 127:
			return false
		if PROIBIDOS.contains(parte[i]):
			return false
	return true


func _ordenar_nos(a: Dictionary, b: Dictionary) -> bool:
	var pasta_a := str(a.get("tipo", "")) == "pasta"
	var pasta_b := str(b.get("tipo", "")) == "pasta"
	if pasta_a != pasta_b:
		return pasta_a
	return nome_do_caminho(str(a.get("caminho", ""))).to_lower() < nome_do_caminho(str(b.get("caminho", ""))).to_lower()


func _pode_alterar(caminho: String) -> bool:
	var no: Dictionary = _nos[caminho]
	if bool(no.get("somente_leitura", false)) or bool(no.get("essencial", false)):
		return false
	var pai := caminho_pai(caminho)
	if pai != RAIZ and _nos.has(pai) and bool(_nos[pai].get("somente_leitura", false)):
		return false
	return caminho != RAIZ


func _criar(pasta: String, nome: String, tipo: String, conteudo: String) -> String:
	var p := resolver(pasta)
	if p == "" or str(_nos[p].get("tipo", "")) != "pasta" or bool(_nos[p].get("somente_leitura", false)):
		return ""
	if not validar_nome(nome) or _criados >= MAX_CRIADOS or conteudo.length() > TAMANHO_MAX_TEXTO:
		return ""
	var destino := juntar(p, nome)
	if _indice.has(destino.to_lower()):
		return ""
	var no := {"caminho": destino, "tipo": tipo, "somente_leitura": false, "conteudo": conteudo, "usuario": true}
	if not _registrar(no, false):
		return ""
	_criados += 1
	_registrar_operacao({"op": "criar", "no": no.duplicate(true)})
	arvore_alterada.emit(p)
	return destino


## Cadastra o nó (uma CÓPIA normalizada: campos novos com padrão, formato do prompt e `desde_dia` traduzidos; ver ArquivoVirtual).
func _registrar(no_bruto: Dictionary, raiz: bool) -> bool:
	var no := ArquivoVirtual.normalizar_no(no_bruto, Regras.booleano("vfs.pastas_acessiveis_desde_o_inicio", true))
	var caminho := str(no.get("caminho", ""))
	if caminho == "" or (caminho == RAIZ and not raiz):
		return false
	var tipo := str(no.get("tipo", ""))
	if tipo != "pasta" and tipo != "arquivo":
		return false
	if _indice.has(caminho.to_lower()):
		return false
	if not raiz:
		var pai := caminho_pai(caminho)
		if not _nos.has(pai) or str(_nos[pai].get("tipo", "")) != "pasta":
			return false
		_filhos[pai].append(caminho)
	var id_no := _id_unico(str(no.get("id", "")), caminho)
	no["id"] = id_no
	_nos[caminho] = no
	_indice[caminho.to_lower()] = caminho
	_ids[id_no] = caminho
	if tipo == "pasta":
		_filhos[caminho] = []
	return true


## `id_base` se estiver livre; senão com sufixo _2, _3... (ids iguais nos dados não derrubam o carregamento).
func _id_unico(id_base: String, caminho: String) -> String:
	var base := id_base if id_base != "" else ArquivoVirtual.id_do_caminho(caminho)
	var candidato := base
	var i := 2
	while _ids.has(candidato) and str(_ids[candidato]) != caminho:
		candidato = "%s_%d" % [base, i]
		i += 1
	return candidato


func _remover_entrada(caminho: String) -> void:
	var pai := caminho_pai(caminho)
	if _filhos.has(pai):
		_filhos[pai].erase(caminho)
	if _nos.has(caminho):
		var id_no := str(_nos[caminho].get("id", ""))
		if str(_ids.get(id_no, "")) == caminho:
			_ids.erase(id_no)
	_nos.erase(caminho)
	_indice.erase(caminho.to_lower())
	_filhos.erase(caminho)


## Move um nó e todos os seus descendentes (renomear e lixeira usam o mesmo caminho de código).
func _mover_no(de: String, para: String) -> void:
	var prefixo := de + "/"
	var afetados: Array = []
	for c in _nos:
		if c == de or str(c).begins_with(prefixo):
			afetados.append(c)
	afetados.sort_custom(func(x: String, y: String) -> bool: return x.length() < y.length())
	var antigos: Array = []
	for c in afetados:
		antigos.append(_nos[c])
	for c in afetados:
		_remover_entrada(c)
	for i in afetados.size():
		var no: Dictionary = antigos[i]
		var novo_caminho: String = para + str(afetados[i]).substr(de.length())
		no["caminho"] = novo_caminho
		_registrar(no, false)


func _definir_texto(caminho: String, texto: String) -> void:
	_nos[caminho]["conteudo_usuario"] = texto
	_nos[caminho]["modificado"] = true


func _decifrar(caminho: String) -> void:
	var no: Dictionary = _nos[caminho]
	no["decifrado"] = true
	var flag := str(no.get("flag_ao_decifrar", ""))
	if flag != "":
		GerenciadorEstado.set_flag(flag, true)
	var conteudo: Variant = no.get("zip_conteudo")
	var destino := normalizar(str(no.get("pasta_destino", "")))
	if conteudo is Array and destino != "":
		_extrair_zip(destino, conteudo)
	arquivo_alterado.emit(caminho)
	arvore_alterada.emit(caminho_pai(caminho))


func _extrair_zip(destino: String, itens: Array) -> void:
	if not _indice.has(destino.to_lower()):
		_registrar({"caminho": destino, "tipo": "pasta", "somente_leitura": true, "gerado": true}, false)
	var pasta := str(_indice.get(destino.to_lower(), destino))
	for item in itens:
		if not (item is Dictionary):
			continue
		var nome := str(item.get("nome", ""))
		if not validar_nome(nome):
			continue
		var caminho := juntar(pasta, nome)
		if _indice.has(caminho.to_lower()):
			continue
		_registrar({"caminho": caminho, "tipo": "arquivo", "somente_leitura": true, "conteudo": str(item.get("conteudo", "")), "gerado": true}, false)


## Registra a operação no log do salvamento, a menos que o nó seja marcado `persistente: false` (a alteração então vale só na sessão).
func _registrar_operacao_do_no(no: Dictionary, op: Dictionary) -> void:
	if bool(no.get("persistente", true)):
		_registrar_operacao(op)


func _registrar_operacao(op: Dictionary) -> void:
	if str(op.get("op", "")) == "texto" and not _operacoes.is_empty():
		var ultima: Dictionary = _operacoes[_operacoes.size() - 1]
		if str(ultima.get("op", "")) == "texto" and str(ultima.get("c", "")) == str(op.get("c", "")):
			_operacoes[_operacoes.size() - 1] = op
			return
	_operacoes.append(op)


func _aplicar(op: Dictionary, restaurando: bool) -> void:
	match str(op.get("op", "")):
		"criar":
			var no: Variant = op.get("no")
			if no is Dictionary:
				var copia: Dictionary = no.duplicate(true)
				copia["caminho"] = normalizar(str(copia.get("caminho", "")))
				copia["usuario"] = true
				if _registrar(copia, false):
					_criados += 1
					if restaurando:
						_operacoes.append({"op": "criar", "no": copia.duplicate(true)})
		"texto":
			var c := resolver(str(op.get("c", "")))
			var texto := str(op.get("t", ""))
			if c != "" and texto.length() <= TAMANHO_MAX_TEXTO:
				_definir_texto(c, texto)
				_registrar_operacao({"op": "texto", "c": c, "t": texto})
		"mover":
			var de := resolver(str(op.get("de", "")))
			var para := normalizar(str(op.get("para", "")))
			var dentro_de_si := para.to_lower().begins_with(de.to_lower() + "/")
			if de != "" and para != "" and de != RAIZ and not dentro_de_si and not _indice.has(para.to_lower()) and _filhos.has(caminho_pai(para)):
				_mover_no(de, para)
				if op.has("origem_lixeira") and _nos.has(para):
					_nos[para]["origem_lixeira"] = str(op["origem_lixeira"])
				_registrar_operacao(op.duplicate(true))
		"decifrar":
			var c2 := resolver(str(op.get("c", "")))
			if c2 != "" and bool(_nos[c2].get("criptografado", false)):
				_decifrar(c2)
				_registrar_operacao({"op": "decifrar", "c": c2})
		"revelar":
			var c3 := resolver(str(op.get("c", "")))
			if c3 != "":
				_nos[c3]["revelado"] = true
				_registrar_operacao({"op": "revelar", "c": c3})
		"reparar":
			var c4 := resolver(str(op.get("c", "")))
			if c4 != "" and bool(_nos[c4].get("corrompido", false)):
				_nos[c4]["reparado"] = true
				_registrar_operacao({"op": "reparar", "c": c4})
		_:
			push_warning("VFS: operação desconhecida ignorada.")
