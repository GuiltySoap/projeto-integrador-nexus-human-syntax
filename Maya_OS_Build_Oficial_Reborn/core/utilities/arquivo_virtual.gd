class_name ArquivoVirtual
extends RefCounted
## Modelo dos nós do VFS (§23): normaliza o que vem dos dados (vfs_inicial.json, salvamentos antigos, nós criados em tempo de execução) e
## descreve o ESTADO de cada arquivo/pasta. Funções puras e estáticas: nada aqui lê autoload, então os testes chamam direto.
## Quem decide com o estado do jogo (dia, flags, puzzles) é o SistemaArquivosVirtual, que passa essas respostas por parâmetro.
##
## CAMPOS de um arquivo (os antigos continuam valendo; os novos têm padrão, então dados e salvamentos antigos funcionam sem migração):
##   id                 identificador estável (não muda ao renomear/mover). Padrão: derivado do caminho de criação.
##   tipo               "pasta" | "arquivo" (como sempre). O formato do prompt (`"tipo": "arquivo_corrompido"`) também é aceito: vira
##                      tipo "arquivo" + tipo_arquivo "arquivo_corrompido" (divergência registrada em docs/14_*: `tipo` já era usado
##                      para pasta/arquivo em todo o projeto e nos salvamentos).
##   tipo_arquivo       "arquivo_normal" | "arquivo_criptografado" | "arquivo_corrompido" (derivado dos estados quando não vem nos dados).
##   conteudo | conteudo_por_dia | proc | referencia   o conteúdo (texto) ou a referência (imagem/áudio procedurais, arquivo externo).
##   somente_leitura    estado de escrita (true = não grava).
##   criptografado / decifrado   estado de criptografia (o puzzle de chave continua em chaves_sha256).
##   corrompido / reparado       estado de corrupção. Corrompido = leitura DEGRADADA (determinística) e escrita negada até reparar.
##   meta (alias metadados)      metadados mostrados nos aplicativos (descrição, autor, data...).
##   requisitos         condições (GerenciadorEstado.avaliar_condicao: "flag:x", "dia>=3", "!flag:y") para o arquivo estar DESBLOQUEADO
##                      NARRATIVAMENTE. Não atendidas: o arquivo aparece na lista, mas não pode ser lido (e a pasta pode ser aberta).
##   persistente        o que o jogador altera neste nó entra no salvamento (padrão true).
##   is_placeholder     o conteúdo ainda é um marcador técnico (nunca narrativa definitiva).
##   semente            semente da corrupção (padrão: hash do id), para o texto degradado ser sempre o mesmo.
## `desde_dia` em ARQUIVO vira o requisito "dia>=N" (o arquivo passa a aparecer bloqueado em vez de sumir); em PASTA é descartado quando a
## regra vfs.pastas_acessiveis_desde_o_inicio vale (padrão): a pasta fica acessível desde o início e o que precisa continuar protegido é
## protegido por `requer_flag` (puzzle) ou pelos estados do arquivo, nunca pela pasta estar escondida.

const TIPO_NORMAL := "arquivo_normal"
const TIPO_CRIPTOGRAFADO := "arquivo_criptografado"
const TIPO_CORROMPIDO := "arquivo_corrompido"
const TIPOS: PackedStringArray = [TIPO_NORMAL, TIPO_CRIPTOGRAFADO, TIPO_CORROMPIDO]

## Estados que o VFS informa (também usados como rótulo curto nos aplicativos).
const ESTADO_PASTA_ACESSIVEL := "pasta_acessivel"
const ESTADO_PASTA_BLOQUEADA := "pasta_bloqueada"
const ESTADO_LEGIVEL := "arquivo_legivel"
const ESTADO_CRIPTOGRAFADO := "arquivo_criptografado"
const ESTADO_CORROMPIDO := "arquivo_corrompido"
const ESTADO_BLOQUEADO_NARRATIVAMENTE := "arquivo_bloqueado_narrativamente"
const ESTADO_DESBLOQUEADO_NARRATIVAMENTE := "arquivo_desbloqueado_narrativamente"

const INTENSIDADE_CORRUPCAO := 0.35
const MAX_ID := 96


## Cópia do nó pronta para o VFS: campos novos com padrão, formato do prompt traduzido, `desde_dia` traduzido. Nunca altera o original.
## `pastas_acessiveis`: ignora `desde_dia` nas pastas (a regra vfs.pastas_acessiveis_desde_o_inicio).
static func normalizar_no(bruto: Dictionary, pastas_acessiveis: bool = true) -> Dictionary:
	var no: Dictionary = bruto.duplicate(true)
	var caminho := str(no.get("caminho", ""))
	var tipo := str(no.get("tipo", ""))
	if tipo.begins_with("arquivo_"):
		no["tipo_arquivo"] = tipo
		tipo = "arquivo"
		no["tipo"] = "arquivo"
	if tipo == "pasta":
		if pastas_acessiveis:
			no.erase("desde_dia")
		if not no.has("id") or str(no["id"]).strip_edges() == "":
			no["id"] = id_do_caminho(caminho)
		if not no.has("is_placeholder"):
			no["is_placeholder"] = false
		return no
	if tipo != "arquivo":
		return no
	# --- arquivo
	if no.has("metadados") and no["metadados"] is Dictionary:
		var meta: Dictionary = no["meta"] if no.get("meta") is Dictionary else {}
		for chave in no["metadados"]:
			meta[chave] = no["metadados"][chave]
		no["meta"] = meta
		no.erase("metadados")
	var declarado := str(no.get("tipo_arquivo", ""))
	if declarado == TIPO_CRIPTOGRAFADO:
		no["criptografado"] = true
	elif declarado == TIPO_CORROMPIDO:
		no["corrompido"] = true
	elif declarado == TIPO_NORMAL:
		no["criptografado"] = bool(no.get("criptografado", false))
		no["corrompido"] = bool(no.get("corrompido", false))
	no["criptografado"] = bool(no.get("criptografado", false))
	no["corrompido"] = bool(no.get("corrompido", false))
	no["tipo_arquivo"] = tipo_declarado(no)
	if not no.has("id") or str(no["id"]).strip_edges() == "":
		no["id"] = id_do_caminho(caminho)
	var requisitos := _requisitos_validos(no.get("requisitos"))
	if no.has("desde_dia"):
		var dia := int(no["desde_dia"])
		if dia > 1:
			requisitos.append("dia>=%d" % dia)
		no.erase("desde_dia")
	no["requisitos"] = requisitos
	if not no.has("persistente"):
		no["persistente"] = true
	if not no.has("is_placeholder"):
		no["is_placeholder"] = false
	if not no.has("semente"):
		no["semente"] = semente_do_id(str(no["id"]))
	return no


## O tipo do arquivo pelos estados de criptografia e corrupção: criptografado vence (não se vê o que há dentro de um arquivo cifrado).
static func tipo_declarado(no: Dictionary) -> String:
	if bool(no.get("criptografado", false)):
		return TIPO_CRIPTOGRAFADO
	if bool(no.get("corrompido", false)):
		return TIPO_CORROMPIDO
	return TIPO_NORMAL


## Id estável derivado do caminho: minúsculas, só [a-z0-9_] ("/home/usuario/Rafael/a.txt" -> "home_usuario_rafael_a_txt").
static func id_do_caminho(caminho: String) -> String:
	var minusculo := caminho.to_lower()
	var saida := ""
	var anterior_sep := true
	for i in minusculo.length():
		var c: String = minusculo[i]
		var ok := (c >= "a" and c <= "z") or (c >= "0" and c <= "9")
		if ok:
			saida += c
			anterior_sep = false
		elif not anterior_sep:
			saida += "_"
			anterior_sep = true
	saida = saida.trim_suffix("_")
	if saida == "":
		saida = "raiz"
	return saida.substr(0, MAX_ID)


## Semente determinística (inteiro positivo) a partir de um texto. Mesmo texto, mesma semente, em qualquer máquina.
static func semente_do_id(texto: String) -> int:
	var h: int = 2166136261
	for i in texto.length():
		h = ((h ^ texto.unicode_at(i)) * 16777619) & 0x7FFFFFFF
	return h & 0x7FFFFFFF   # também para o texto vazio (que devolveria o valor inicial, maior que 31 bits)


static func _requisitos_validos(bruto: Variant) -> Array:
	var saida: Array = []
	if bruto is Array:
		for item in bruto as Array:
			var texto := str(item).strip_edges()
			if texto != "":
				saida.append(texto)
	elif bruto is String and str(bruto).strip_edges() != "":
		saida.append(str(bruto).strip_edges())
	return saida


# ------------------------------------------------------------------ estado (as respostas do jogo entram por parâmetro)
## O estado do nó. `requisitos_ok`: os requisitos estão atendidos agora? `pasta_bloqueada`: a trava de puzzle da pasta ainda vale?
static func estado(no: Dictionary, requisitos_ok: bool = true, pasta_bloqueada: bool = false) -> String:
	if str(no.get("tipo", "")) == "pasta":
		return ESTADO_PASTA_BLOQUEADA if pasta_bloqueada else ESTADO_PASTA_ACESSIVEL
	if not requisitos_ok:
		return ESTADO_BLOQUEADO_NARRATIVAMENTE   # vence a criptografia: antes da hora nem se tenta a chave
	if bool(no.get("criptografado", false)) and not bool(no.get("decifrado", false)):
		return ESTADO_CRIPTOGRAFADO
	if esta_corrompido(no):
		return ESTADO_CORROMPIDO
	if not (no.get("requisitos", []) as Array).is_empty():
		return ESTADO_DESBLOQUEADO_NARRATIVAMENTE
	return ESTADO_LEGIVEL


static func esta_corrompido(no: Dictionary) -> bool:
	return bool(no.get("corrompido", false)) and not bool(no.get("reparado", false))


## Rótulo curto (português) do estado, para listas, tooltips e o comando `stat`.
static func rotulo(estado_do_no: String) -> String:
	match estado_do_no:
		ESTADO_PASTA_ACESSIVEL:
			return "pasta acessível"
		ESTADO_PASTA_BLOQUEADA:
			return "pasta bloqueada"
		ESTADO_LEGIVEL:
			return "legível"
		ESTADO_CRIPTOGRAFADO:
			return "criptografado"
		ESTADO_CORROMPIDO:
			return "corrompido"
		ESTADO_BLOQUEADO_NARRATIVAMENTE:
			return "bloqueado"
		ESTADO_DESBLOQUEADO_NARRATIVAMENTE:
			return "desbloqueado"
	return estado_do_no


## O texto pode ser LIDO neste estado? (Corrompido lê, mas degradado: ver `texto_visivel`.)
static func pode_ler(estado_do_no: String) -> bool:
	return estado_do_no == ESTADO_LEGIVEL or estado_do_no == ESTADO_DESBLOQUEADO_NARRATIVAMENTE or estado_do_no == ESTADO_CORROMPIDO


## O arquivo aceita escrita neste estado? Só o arquivo legível/desbloqueado e não marcado como somente leitura.
static func pode_escrever(no: Dictionary, estado_do_no: String) -> bool:
	if bool(no.get("somente_leitura", false)):
		return false
	return estado_do_no == ESTADO_LEGIVEL or estado_do_no == ESTADO_DESBLOQUEADO_NARRATIVAMENTE


## O texto que o jogador enxerga: no estado "corrompido" é o conteúdo DEGRADADO (sempre o mesmo para o mesmo arquivo); nos outros,
## o próprio conteúdo. Bloqueado e criptografado nunca expõem nada (texto vazio).
static func texto_visivel(no: Dictionary, conteudo: String, estado_do_no: String) -> String:
	if estado_do_no == ESTADO_CORROMPIDO:
		return UtilTexto.corromper(conteudo, INTENSIDADE_CORRUPCAO, int(no.get("semente", 0)) % 9973)
	if pode_ler(estado_do_no):
		return conteudo
	return ""


## Confere o formato de um nó dos dados (para o validador e os testes). Devolve as mensagens de erro (vazio = ok).
static func validar(no: Dictionary) -> PackedStringArray:
	var erros := PackedStringArray()
	var caminho := str(no.get("caminho", ""))
	if caminho == "" or not caminho.begins_with("/"):
		erros.append("caminho ausente ou relativo")
	var tipo := str(no.get("tipo", ""))
	if tipo != "pasta" and tipo != "arquivo":
		erros.append("tipo inválido: '%s'" % tipo)
		return erros
	if tipo == "arquivo":
		var tipo_arquivo := str(no.get("tipo_arquivo", ""))
		if not TIPOS.has(tipo_arquivo):
			erros.append("tipo_arquivo inválido: '%s'" % tipo_arquivo)
		elif tipo_arquivo != tipo_declarado(no):
			erros.append("tipo_arquivo '%s' não combina com os estados (criptografado=%s, corrompido=%s)" % [tipo_arquivo, str(no.get("criptografado")), str(no.get("corrompido"))])
		if str(no.get("id", "")).strip_edges() == "":
			erros.append("id ausente")
		if not (no.get("requisitos", []) is Array):
			erros.append("requisitos precisa ser uma lista")
	return erros
