extends Node
## Barramento de eventos do jogo: desacopla os módulos (Mensageiro, Terminal, Arquivos, Permissões, Janelas, Story Nodes...).
## Quem produz o fato chama `emitir(id, dados)`; quem se interessa assina o sinal `evento_emitido` (ou `assinar(id, chamada)`).
## Nenhum aplicativo precisa conhecer detalhes internos de outro.
##
## Cada evento tem uma DEFINIÇÃO em core/data/eventos.json: ID, origem padrão, dados obrigatórios, condições, efeitos, destino,
## e a proteção contra duplicação (`unico`, `chave_dedup`, `janela_ms`). `emitir` devolve {aceito, id, origem, motivo, seq, dados}:
##   - evento desconhecido, dados faltando, condição não atendida, duplicado e recursão profunda são REJEITADOS (motivo no retorno
##     e no sinal `evento_rejeitado`), nunca causam erro;
##   - o que é aceito vai para o REGISTRO (últimos MAX_REGISTRO) e tem os efeitos aplicados ANTES de o sinal sair, para que os
##     ouvintes já enxerguem o estado (flags, métricas) que o evento produziu.
## Efeitos que só mexem no estado (métricas, flags, reação de NPC) são aplicados aqui mesmo; os demais (mensagem, notificação,
## glitch, falso boot, Story Nodes...) são entregues ao EXECUTOR registrado pela camada narrativa (`definir_executor`), o que mantém
## este autoload dependente só do GerenciadorEstado (sem ciclo com a narrativa).
## Os saves guardam só as chaves dos eventos únicos (GerenciadorEstado.eventos_unicos).

signal evento_emitido(id: String, dados: Dictionary, item: Dictionary)
signal evento_rejeitado(id: String, motivo: String)

const ARQUIVO := "res://core/data/eventos.json"
const MAX_REGISTRO := 200
const MAX_REJEITADOS := 50
const MAX_PROFUNDIDADE := 4
const DESTINOS: PackedStringArray = ["global", "registro"]

var definicoes: Dictionary = {}
var erros_de_carga: PackedStringArray = PackedStringArray()
## Desligado só nos testes que precisam de silêncio total.
var habilitado: bool = true

var _registro: Array = []
var _rejeitados: Array = []
var _contadores: Dictionary = {}
var _sequencia: int = 0
var _profundidade: int = 0
var _executor: Callable = Callable()
var _assinantes: Dictionary = {}
var _ultimo_ms: Dictionary = {}


func _ready() -> void:
	carregar_definicoes(ARQUIVO)
	GerenciadorEstado.permissao_alterada.connect(_ao_permissao_alterada)
	GerenciadorEstado.final_alcancado.connect(_ao_final_alcancado)


func _exit_tree() -> void:
	if GerenciadorEstado.permissao_alterada.is_connected(_ao_permissao_alterada):
		GerenciadorEstado.permissao_alterada.disconnect(_ao_permissao_alterada)
	if GerenciadorEstado.final_alcancado.is_connected(_ao_final_alcancado):
		GerenciadorEstado.final_alcancado.disconnect(_ao_final_alcancado)


# ------------------------------------------------------------------ definições
## Lê e valida o registro de eventos. Definições inválidas são recusadas (e listadas em `erros_de_carga`); as válidas seguem.
## Devolve true se o arquivo inteiro era válido.
func carregar_definicoes(caminho: String) -> bool:
	definicoes = {}
	erros_de_carga = PackedStringArray()
	if not FileAccess.file_exists(caminho):
		erros_de_carga.append("arquivo ausente: %s" % caminho)
		return false
	var analisador := JSON.new()
	if analisador.parse(FileAccess.get_file_as_string(caminho)) != OK:
		erros_de_carga.append("JSON inválido: %s" % caminho)
		return false
	var bruto: Variant = analisador.data
	if not (bruto is Dictionary) or not ((bruto as Dictionary).get("eventos") is Dictionary):
		erros_de_carga.append("o arquivo não tem o objeto \"eventos\"")
		return false
	var lista: Dictionary = (bruto as Dictionary)["eventos"]
	for id_evento in lista:
		var erro := validar_definicao(str(id_evento), lista[id_evento])
		if erro != "":
			erros_de_carga.append("%s: %s" % [str(id_evento), erro])
			continue
		definicoes[str(id_evento)] = lista[id_evento]
	return erros_de_carga.is_empty()


## "" se a definição é válida; senão o motivo.
func validar_definicao(id_evento: String, def: Variant) -> String:
	if id_evento.strip_edges() == "" or id_evento != id_evento.to_lower() or id_evento.contains(" "):
		return "id inválido (use minúsculas e sublinhado)"
	if not (def is Dictionary):
		return "a definição precisa ser um objeto"
	var d: Dictionary = def
	if d.has("destino") and not DESTINOS.has(str(d["destino"])):
		return "destino desconhecido '%s'" % str(d["destino"])
	for campo in ["exige_dados", "condicoes", "efeitos"]:
		if d.has(campo) and not (d[campo] is Array):
			return "'%s' precisa ser uma lista" % campo
	for efeito in d.get("efeitos", []):
		if not (efeito is Dictionary) or str((efeito as Dictionary).get("tipo", "")) == "":
			return "todo efeito precisa ser um objeto com \"tipo\""
	if d.has("unico") and typeof(d["unico"]) != TYPE_BOOL:
		return "'unico' precisa ser verdadeiro ou falso"
	return ""


func existe(id_evento: String) -> bool:
	return definicoes.has(id_evento)


## Liga o executor dos efeitos que não são só de estado (a camada narrativa registra o dela em _ready).
func definir_executor(executor: Callable) -> void:
	_executor = executor


# ------------------------------------------------------------------ emissão
func emitir(id_evento: String, dados: Dictionary = {}, origem: String = "") -> Dictionary:
	var resultado := {"aceito": false, "id": id_evento, "origem": origem, "motivo": "", "seq": 0, "dados": dados}
	if not habilitado:
		return _rejeitar(resultado, "desabilitado")
	var def: Variant = definicoes.get(id_evento)
	if not (def is Dictionary):
		return _rejeitar(resultado, "evento_desconhecido")
	var d: Dictionary = def
	var origem_final := origem if origem != "" else str(d.get("origem_padrao", ""))
	resultado["origem"] = origem_final
	if _profundidade >= MAX_PROFUNDIDADE:
		return _rejeitar(resultado, "profundidade_excedida")
	for campo in d.get("exige_dados", []):
		if not dados.has(str(campo)):
			return _rejeitar(resultado, "dados_incompletos:%s" % str(campo))
	if not GerenciadorEstado.avaliar_condicao(d.get("condicoes", [])):
		return _rejeitar(resultado, "condicao_nao_atendida")
	var chave := _chave_dedup(id_evento, d, dados)
	if bool(d.get("unico", false)):
		if GerenciadorEstado.eventos_unicos.has(chave):
			return _rejeitar(resultado, "duplicado")
		GerenciadorEstado.eventos_unicos.append(chave)
	else:
		var janela := int(d.get("janela_ms", 0))
		var agora := Time.get_ticks_msec()
		if janela > 0:
			if _ultimo_ms.has(chave) and agora - int(_ultimo_ms[chave]) < janela:
				return _rejeitar(resultado, "duplicado")
			_ultimo_ms[chave] = agora
	_sequencia += 1
	var destino := str(d.get("destino", "global"))
	var item := {
		"seq": _sequencia, "id": id_evento, "origem": origem_final, "destino": destino,
		"t_ms": Time.get_ticks_msec(), "dados": dados.duplicate(true),
	}
	_registro.append(item)
	if _registro.size() > MAX_REGISTRO:
		_registro = _registro.slice(_registro.size() - MAX_REGISTRO)
	_contadores[id_evento] = int(_contadores.get(id_evento, 0)) + 1
	resultado["aceito"] = true
	resultado["seq"] = _sequencia
	_profundidade += 1
	for efeito in d.get("efeitos", []):
		if efeito is Dictionary:
			aplicar_efeito(efeito, dados, origem_final)
	if destino == "global":
		evento_emitido.emit(id_evento, dados, item)
		_notificar_assinantes(id_evento, dados, item)
	_profundidade -= 1
	return resultado


## Aplica UM efeito (de um evento, de um Story Node...). `contexto` são os dados do evento (para `$campo`).
## Devolve true se o efeito foi tratado. Tipo desconhecido sem executor vira aviso no log, nunca erro.
func aplicar_efeito(efeito: Dictionary, contexto: Dictionary = {}, origem: String = "") -> bool:
	var resolvido: Dictionary = _substituir(efeito, contexto)
	# `quando_dados`: o efeito só vale se cada campo citado dos dados do evento tiver o valor indicado (ex.: {"ativa": false}).
	var condicao_dados: Variant = resolvido.get("quando_dados")
	if condicao_dados is Dictionary:
		for campo in condicao_dados:
			if not contexto.has(str(campo)) or contexto[str(campo)] != (condicao_dados as Dictionary)[campo]:
				return true
	if resolvido.has("valor_regra"):
		resolvido["valor"] = Regras.numero(str(resolvido["valor_regra"]), 0.0)
	var tipo := str(resolvido.get("tipo", ""))
	match tipo:
		"metrica_delta":
			GerenciadorEstado.alterar_metrica(str(resolvido.get("nome", "")), resolvido.get("valor", 0), origem)
			return true
		"metrica_definir":
			GerenciadorEstado.definir_metrica(str(resolvido.get("nome", "")), resolvido.get("valor", 0), origem)
			return true
		"metricas_dados":
			var mapa: Variant = contexto.get(str(resolvido.get("campo", "")), {})
			if mapa is Dictionary:
				for nome_metrica in mapa:
					GerenciadorEstado.alterar_metrica(str(nome_metrica), (mapa as Dictionary)[nome_metrica], origem)
			return true
		"flag":
			GerenciadorEstado.set_flag(str(resolvido.get("nome", "")), resolvido.get("valor", true))
			return true
		"flag_incrementar":
			GerenciadorEstado.incrementar_flag(str(resolvido.get("nome", "")), int(resolvido.get("valor", 1)))
			return true
	# (o roteiro v2.0 tem a sua própria DSL de efeitos em FluxoRoteiro; aqui ficam só os efeitos genéricos do barramento)
	if _executor.is_valid():
		var retorno: Variant = _executor.call(resolvido, contexto)
		return retorno == null or bool(retorno)
	push_warning("SistemaEventos: efeito '%s' sem executor registrado." % tipo)
	return false


## Acrescenta uma linha ao registro (log) que não é um evento do catálogo: efeitos aplicados ou suprimidos, falhas tratadas...
func registrar_log(id_log: String, dados: Dictionary, origem: String = "") -> void:
	_sequencia += 1
	_registro.append({"seq": _sequencia, "id": id_log, "origem": origem, "destino": "log", "t_ms": Time.get_ticks_msec(), "dados": dados.duplicate(true)})
	if _registro.size() > MAX_REGISTRO:
		_registro = _registro.slice(_registro.size() - MAX_REGISTRO)


# ------------------------------------------------------------------ assinaturas, registro e consultas
## Chama `chamada(dados: Dictionary, registro: Dictionary)` sempre que `id_evento` for aceito.
func assinar(id_evento: String, chamada: Callable) -> void:
	if not _assinantes.has(id_evento):
		_assinantes[id_evento] = []
	if not (_assinantes[id_evento] as Array).has(chamada):
		(_assinantes[id_evento] as Array).append(chamada)


func desassinar(id_evento: String, chamada: Callable) -> void:
	if _assinantes.has(id_evento):
		(_assinantes[id_evento] as Array).erase(chamada)


## Últimos eventos aceitos (mais antigo primeiro). `id_evento` filtra; `limite` 0 devolve todos os guardados.
func registro(id_evento: String = "", limite: int = 0) -> Array:
	var saida: Array = []
	for item in _registro:
		if id_evento == "" or str((item as Dictionary).get("id", "")) == id_evento:
			saida.append(item)
	if limite > 0 and saida.size() > limite:
		saida = saida.slice(saida.size() - limite)
	return saida


func rejeicoes(limite: int = 0) -> Array:
	if limite > 0 and _rejeitados.size() > limite:
		return _rejeitados.slice(_rejeitados.size() - limite)
	return _rejeitados.duplicate()


## Quantas vezes o evento foi ACEITO desde o início da sessão do jogo (não persiste).
func contagem(id_evento: String) -> int:
	return int(_contadores.get(id_evento, 0))


func limpar_registro() -> void:
	_registro.clear()
	_rejeitados.clear()
	_contadores.clear()
	_ultimo_ms.clear()


## Esquece as chaves dos eventos únicos (novo jogo). O GerenciadorEstado.novo_jogo também zera a lista salva.
func reiniciar_unicos() -> void:
	GerenciadorEstado.eventos_unicos = []
	_ultimo_ms.clear()


# ------------------------------------------------------------------ internos
func _rejeitar(resultado: Dictionary, motivo: String) -> Dictionary:
	resultado["aceito"] = false
	resultado["motivo"] = motivo
	_rejeitados.append({"id": str(resultado["id"]), "motivo": motivo, "t_ms": Time.get_ticks_msec()})
	if _rejeitados.size() > MAX_REJEITADOS:
		_rejeitados = _rejeitados.slice(_rejeitados.size() - MAX_REJEITADOS)
	evento_rejeitado.emit(str(resultado["id"]), motivo)
	return resultado


## Chave de duplicação: "id" ou "id:valor" quando a definição aponta um campo dos dados (`chave_dedup`) ou os dados trazem "chave_dedup".
func _chave_dedup(id_evento: String, d: Dictionary, dados: Dictionary) -> String:
	var campo := str(d.get("chave_dedup", ""))
	if campo != "" and dados.has(campo):
		return "%s:%s" % [id_evento, str(dados[campo])]
	if dados.has("chave_dedup"):
		return "%s:%s" % [id_evento, str(dados["chave_dedup"])]
	return id_evento


func _notificar_assinantes(id_evento: String, dados: Dictionary, registro_do_evento: Dictionary) -> void:
	if not _assinantes.has(id_evento):
		return
	for chamada in (_assinantes[id_evento] as Array).duplicate():
		if (chamada as Callable).is_valid():
			(chamada as Callable).call(dados, registro_do_evento)
		else:
			(_assinantes[id_evento] as Array).erase(chamada)


## Troca `$campo` pelo valor do campo nos dados (texto inteiro "$campo" mantém o tipo original; "a:$campo" vira texto).
func _substituir(valor: Variant, dados: Dictionary) -> Variant:
	if valor is String:
		var texto: String = valor
		if texto.begins_with("$") and dados.has(texto.substr(1)):
			return dados[texto.substr(1)]
		if texto.contains("$"):
			for chave in dados:
				var v: Variant = dados[chave]
				if typeof(v) == TYPE_STRING or typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_BOOL or typeof(v) == TYPE_STRING_NAME:
					texto = texto.replace("$" + str(chave), str(v))
		return texto
	if valor is Array:
		var lista: Array = []
		for item in valor:
			lista.append(_substituir(item, dados))
		return lista
	if valor is Dictionary:
		var copia: Dictionary = {}
		for chave in valor:
			copia[chave] = _substituir(valor[chave], dados)
		return copia
	return valor


# ------------------------------------------------------------------ ponte: sinais do estado -> eventos
func _ao_permissao_alterada(nome: String, ativa: bool) -> void:
	emitir("permissao_alterada", {"id": nome, "ativa": ativa})


func _ao_final_alcancado(id_final: String) -> void:
	emitir("final_alcancado", {"final": id_final}, "narrativa")
