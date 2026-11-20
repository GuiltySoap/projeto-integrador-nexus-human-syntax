extends Node
## Gerenciador dos Story Nodes (StoryNodeManager): a progressão do jogo por NÓS DE HISTÓRIA de nível de Task (roteiro v2.0: task_1..task_9,
## tr_1, av), sem calendário. Os dados vêm de core/data/narrativa/story_nodes.json; o ESTADO de cada nó vive no GerenciadorEstado (`nos`,
## `no_atual` = a Task atual) e vai para o salvamento. A lógica de progressão fica aqui, separada da interface. Os nós NUMERADOS (T4.3...) e os
## diálogos ficam no FluxoRoteiro, que ativa e conclui estes nós de Task conforme as condições de saída do roteiro.
##
## CICLO DE UM NÓ: bloqueado -> disponivel -> ativo -> concluido (e, se repetível, volta a disponivel até `max_ativacoes`).
##   - `disponivel`: os nós exigidos (requisitos.nos_concluidos) e ao menos UM antecessor (`proximos`) já concluíram: Task 8 é liberada
##     tanto pela Task 7 quanto pela transição TR.1;
##   - `ativo`: os GATILHOS (início, evento, flag, métrica, nó concluído) aconteceram E os REQUISITOS (nós, flags, arquivos abertos,
##     evidências, métricas) estão atendidos; os efeitos de ativação, os diálogos e os eventos do nó são aplicados;
##   - `concluido`: a CONCLUSÃO (flags, eventos ou imediata) aconteceu; os efeitos de conclusão rodam e os `proximos` são liberados.
## Um nó NÃO ativa duas vezes sem regra (`repetivel` + `max_ativacoes`); toda recusa vira o sinal `falha_de_requisito(id, motivo)`.
## `restaurar` confere o estado de um save; um save sem nós (modelo antigo, migrado) volta ao início da Task 1.
##
## DEPENDÊNCIAS: só GerenciadorEstado, SistemaEventos e SistemaArquivosVirtual (arquivos abertos). A narrativa registra um provedor
## de evidências (`registrar_provedor`) e o executor dos efeitos no SistemaEventos, então este autoload não conhece a narrativa.

signal no_ativado(id: String)
signal no_concluido(id: String)
signal progresso_atualizado(id: String)
signal falha_de_requisito(id: String, motivo: String)

const ARQUIVO := "res://core/data/narrativa/story_nodes.json"
const BLOQUEADO := "bloqueado"
const DISPONIVEL := "disponivel"
const ATIVO := "ativo"
const CONCLUIDO := "concluido"
const ESTADOS: PackedStringArray = ["bloqueado", "disponivel", "ativo", "concluido"]
const TIPOS_DE_GATILHO: PackedStringArray = ["inicio", "evento", "flag", "metrica", "no_concluido"]
const MAX_PASSADAS := 20
const MAX_ATIVACOES_PADRAO := 100

## Definições validadas, por id (somente leitura em jogo).
var nos: Dictionary = {}
var erros_de_carga: PackedStringArray = PackedStringArray()
## Os dados carregaram e há ao menos um nó válido: a progressão por nós está em uso.
var pronto: bool = false
## Provedores externos de verificação ("evidencia": Callable(id) -> bool), registrados pela narrativa.
var provedores: Dictionary = {}

var _ordem: Array = []
var _predecessores: Dictionary = {}
var _avaliando: bool = false
var _pendente: bool = false


func _ready() -> void:
	carregar(ARQUIVO)
	SistemaEventos.evento_emitido.connect(_ao_evento)
	GerenciadorEstado.flag_alterada.connect(_ao_flag)
	GerenciadorEstado.metrica_mudou.connect(_ao_metrica)


func _exit_tree() -> void:
	if SistemaEventos.evento_emitido.is_connected(_ao_evento):
		SistemaEventos.evento_emitido.disconnect(_ao_evento)
	if GerenciadorEstado.flag_alterada.is_connected(_ao_flag):
		GerenciadorEstado.flag_alterada.disconnect(_ao_flag)
	if GerenciadorEstado.metrica_mudou.is_connected(_ao_metrica):
		GerenciadorEstado.metrica_mudou.disconnect(_ao_metrica)


# ------------------------------------------------------------------ carga e validação
## Lê o arquivo e valida os nós. Nós inválidos são REJEITADOS (listados em `erros_de_carga`); os válidos seguem.
func carregar(caminho: String) -> bool:
	if not FileAccess.file_exists(caminho):
		_zerar()
		erros_de_carga.append("arquivo ausente: %s" % caminho)
		return false
	var analisador := JSON.new()
	if analisador.parse(FileAccess.get_file_as_string(caminho)) != OK or not (analisador.data is Dictionary):
		_zerar()
		erros_de_carga.append("JSON inválido: %s" % caminho)
		return false
	return carregar_dados(analisador.data as Dictionary)


## Igual a `carregar`, mas a partir de um dicionário já lido (os testes usam isto para provar a rejeição de dados inválidos).
func carregar_dados(raiz: Dictionary) -> bool:
	_zerar()
	if not (raiz.get("nos") is Dictionary):
		erros_de_carga.append("o arquivo não tem o objeto \"nos\"")
		return false
	var brutos: Dictionary = raiz["nos"]
	var aceitos: Dictionary = {}
	for id_no in brutos:
		var problemas := validar_no(str(id_no), brutos[id_no])
		if problemas.is_empty():
			aceitos[str(id_no)] = brutos[id_no]
		else:
			for p in problemas:
				erros_de_carga.append("%s: %s" % [str(id_no), p])
	# Referências entre nós: um nó que aponta para um id inexistente (ou rejeitado) também é rejeitado; repete até estabilizar.
	var mudou := true
	while mudou:
		mudou = false
		for id_no in aceitos.keys():
			var def: Dictionary = aceitos[id_no]
			for alvo in _referencias(def):
				if not aceitos.has(alvo):
					erros_de_carga.append("%s: referência para o nó inexistente '%s'" % [id_no, alvo])
					aceitos.erase(id_no)
					mudou = true
					break
	# Ciclos entre nós não repetíveis nunca terminariam: os nós do ciclo são rejeitados.
	for id_no in _nos_em_ciclo(aceitos):
		erros_de_carga.append("%s: ciclo de nós não repetíveis" % id_no)
		aceitos.erase(id_no)
	nos = aceitos
	for id_no in brutos:   # mantém a ordem do arquivo
		if nos.has(str(id_no)):
			_ordem.append(str(id_no))
	for id_no in _ordem:
		var def_ok: Dictionary = nos[id_no]
		for alvo in def_ok.get("proximos", []):
			if not _predecessores.has(str(alvo)):
				_predecessores[str(alvo)] = []
			(_predecessores[str(alvo)] as Array).append(id_no)
	pronto = not nos.is_empty()
	return erros_de_carga.is_empty()


func _zerar() -> void:
	nos = {}
	_ordem = []
	_predecessores = {}
	erros_de_carga = PackedStringArray()
	pronto = false


## Lista de problemas de UMA definição (vazia = válida). Não olha referências entre nós (isso é feito ao carregar tudo).
func validar_no(id_no: String, def: Variant) -> PackedStringArray:
	var p := PackedStringArray()
	if id_no == "" or id_no.length() > 64 or id_no != id_no.to_lower() or id_no.contains(" "):
		p.append("id inválido (minúsculas, sem espaços, até 64 caracteres)")
	if not (def is Dictionary):
		p.append("a definição precisa ser um objeto")
		return p
	var d: Dictionary = def
	if typeof(d.get("titulo", null)) != TYPE_STRING or str(d["titulo"]) == "":
		p.append("falta o título")
	for campo in ["requisitos", "conclusao"]:
		if d.has(campo) and not (d[campo] is Dictionary):
			p.append("'%s' precisa ser um objeto" % campo)
	for campo in ["gatilhos", "efeitos_ao_ativar", "efeitos_ao_concluir", "dialogos", "escolhas", "eventos", "proximos"]:
		if d.has(campo) and not (d[campo] is Array):
			p.append("'%s' precisa ser uma lista" % campo)
	for campo in ["dialogos", "escolhas", "proximos"]:
		if d.get(campo) is Array:
			for item in d[campo]:
				if typeof(item) != TYPE_STRING or str(item) == "":
					p.append("'%s' só aceita textos não vazios" % campo)
					break
	for campo in ["repetivel", "principal", "is_placeholder"]:
		if d.has(campo) and typeof(d[campo]) != TYPE_BOOL:
			p.append("'%s' precisa ser verdadeiro ou falso" % campo)
	if d.has("max_ativacoes") and (not _eh_numero(d["max_ativacoes"]) or int(d["max_ativacoes"]) < 1):
		p.append("'max_ativacoes' precisa ser um número maior que zero")
	if d.get("requisitos") is Dictionary:
		_validar_requisitos(d["requisitos"], p)
	if d.get("gatilhos") is Array:
		for g in d["gatilhos"]:
			_validar_gatilho(g, p)
	if d.get("conclusao") is Dictionary:
		_validar_conclusao(d["conclusao"], p)
	for campo in ["efeitos_ao_ativar", "efeitos_ao_concluir"]:
		if d.get(campo) is Array:
			for efeito in d[campo]:
				if not (efeito is Dictionary) or str((efeito as Dictionary).get("tipo", "")) == "":
					p.append("todo efeito em '%s' precisa ser um objeto com \"tipo\"" % campo)
					break
	if d.get("eventos") is Array:
		for ev in d["eventos"]:
			if not (ev is Dictionary) or str((ev as Dictionary).get("id", "")) == "":
				p.append("todo item de 'eventos' precisa ser um objeto com \"id\"")
				break
	return p


func _validar_requisitos(req: Dictionary, p: PackedStringArray) -> void:
	for campo in ["nos_concluidos", "flags", "arquivos", "evidencias"]:
		if req.has(campo) and not (req[campo] is Array):
			p.append("requisitos.%s precisa ser uma lista" % campo)
	if req.get("metricas") != null and not (req.get("metricas") is Dictionary):
		p.append("requisitos.metricas precisa ser um objeto")
	elif req.get("metricas") is Dictionary:
		for nome in req["metricas"]:
			var lim: Variant = req["metricas"][nome]
			if Metricas.normalizar_nome(str(nome)) == "":
				p.append("requisitos.metricas: métrica desconhecida '%s'" % str(nome))
			elif not (lim is Dictionary) or ((lim as Dictionary).has("min") and not _eh_numero((lim as Dictionary)["min"])) or ((lim as Dictionary).has("max") and not _eh_numero((lim as Dictionary)["max"])):
				p.append("requisitos.metricas.%s precisa de min/max numéricos" % str(nome))


func _validar_gatilho(g: Variant, p: PackedStringArray) -> void:
	if not (g is Dictionary):
		p.append("todo gatilho precisa ser um objeto")
		return
	var gd: Dictionary = g
	var tipo := str(gd.get("tipo", ""))
	if not TIPOS_DE_GATILHO.has(tipo):
		p.append("tipo de gatilho desconhecido '%s'" % tipo)
		return
	match tipo:
		"evento":
			if str(gd.get("evento", "")) == "":
				p.append("o gatilho 'evento' precisa do campo \"evento\"")
		"flag":
			if str(gd.get("condicao", "")) == "":
				p.append("o gatilho 'flag' precisa do campo \"condicao\"")
		"metrica":
			if Metricas.normalizar_nome(str(gd.get("nome", ""))) == "":
				p.append("o gatilho 'metrica' precisa de uma métrica válida em \"nome\"")
			if not gd.has("min") and not gd.has("max"):
				p.append("o gatilho 'metrica' precisa de \"min\" ou \"max\"")
		"no_concluido":
			if str(gd.get("id", "")) == "":
				p.append("o gatilho 'no_concluido' precisa do campo \"id\"")


func _validar_conclusao(c: Dictionary, p: PackedStringArray) -> void:
	if c.has("flags") and not (c["flags"] is Array):
		p.append("conclusao.flags precisa ser uma lista")
	if c.has("imediata") and typeof(c["imediata"]) != TYPE_BOOL:
		p.append("conclusao.imediata precisa ser verdadeiro ou falso")
	if c.has("eventos"):
		if not (c["eventos"] is Array):
			p.append("conclusao.eventos precisa ser uma lista")
		else:
			for ev in c["eventos"]:
				if not (ev is Dictionary) or str((ev as Dictionary).get("evento", "")) == "":
					p.append("todo item de conclusao.eventos precisa do campo \"evento\"")
					break


## Ids de outros nós que a definição cita (proximos, nos_concluidos e gatilhos no_concluido).
func _referencias(def: Dictionary) -> PackedStringArray:
	var saida := PackedStringArray()
	for alvo in def.get("proximos", []):
		saida.append(str(alvo))
	var req: Variant = def.get("requisitos", {})
	if req is Dictionary:
		for alvo in (req as Dictionary).get("nos_concluidos", []):
			saida.append(str(alvo))
	for g in def.get("gatilhos", []):
		if g is Dictionary and str((g as Dictionary).get("tipo", "")) == "no_concluido":
			saida.append(str((g as Dictionary).get("id", "")))
	return saida


## Nós que participam de um ciclo formado só por nós NÃO repetíveis, seguindo `proximos`.
func _nos_em_ciclo(aceitos: Dictionary) -> PackedStringArray:
	var em_ciclo := PackedStringArray()
	for inicio in aceitos:
		var visitados: Dictionary = {}
		var pilha: Array = [[str(inicio), 0]]
		var achou := false
		while not pilha.is_empty() and not achou:
			var atual: Array = pilha.pop_back()
			var id_atual: String = atual[0]
			var def: Dictionary = aceitos.get(id_atual, {})
			if bool(def.get("repetivel", false)) and id_atual != str(inicio):
				continue
			for alvo in def.get("proximos", []):
				var a := str(alvo)
				if a == str(inicio) and not bool((aceitos[inicio] as Dictionary).get("repetivel", false)):
					achou = true
					break
				if not visitados.has(a) and aceitos.has(a):
					visitados[a] = true
					pilha.append([a, 0])
		if achou:
			em_ciclo.append(str(inicio))
	return em_ciclo


# ------------------------------------------------------------------ consultas
func ids() -> PackedStringArray:
	var saida := PackedStringArray()
	for id_no in _ordem:
		saida.append(str(id_no))
	return saida


func existe(id_no: String) -> bool:
	return nos.has(id_no)


## Cópia da definição de um nó ({} se não existe).
func dados_do_no(id_no: String) -> Dictionary:
	var d: Variant = nos.get(id_no)
	return (d as Dictionary).duplicate(true) if d is Dictionary else {}


## "bloqueado" | "disponivel" | "ativo" | "concluido" | "inexistente".
func estado_do_no(id_no: String) -> String:
	if not nos.has(id_no):
		return "inexistente"
	var st: Variant = GerenciadorEstado.nos.get(id_no)
	if st is Dictionary:
		var estado := str((st as Dictionary).get("estado", BLOQUEADO))
		return estado if ESTADOS.has(estado) else BLOQUEADO
	return BLOQUEADO


func ativacoes(id_no: String) -> int:
	var st: Variant = GerenciadorEstado.nos.get(id_no)
	return int((st as Dictionary).get("ativacoes", 0)) if st is Dictionary else 0


## Nó principal (da linha do tempo) em andamento, ou "".
func no_atual() -> String:
	return GerenciadorEstado.no_atual


func titulo_do_no_atual() -> String:
	return str(dados_do_no(GerenciadorEstado.no_atual).get("titulo", ""))


func nos_com_estado(estado: String) -> PackedStringArray:
	var saida := PackedStringArray()
	for id_no in _ordem:
		if estado_do_no(str(id_no)) == estado:
			saida.append(str(id_no))
	return saida


func resumo() -> Dictionary:
	return {
		"total": _ordem.size(), "bloqueados": nos_com_estado(BLOQUEADO).size(), "disponiveis": nos_com_estado(DISPONIVEL).size(),
		"ativos": nos_com_estado(ATIVO).size(), "concluidos": nos_com_estado(CONCLUIDO).size(), "atual": GerenciadorEstado.no_atual,
	}


func registrar_provedor(nome: String, chamada: Callable) -> void:
	provedores[nome] = chamada


## Verifica os REQUISITOS de entrada de um nó. Devolve {ok, faltas: ["no:x", "flag:y", "arquivo:z", "evidencia:w", "metrica:n"]}.
func verificar_requisitos(id_no: String) -> Dictionary:
	if not nos.has(id_no):
		return {"ok": false, "faltas": ["no_desconhecido"]}
	var req: Variant = (nos[id_no] as Dictionary).get("requisitos", {})
	var faltas: Array = []
	if not (req is Dictionary):
		return {"ok": true, "faltas": faltas}
	var r: Dictionary = req
	for exigido in r.get("nos_concluidos", []):
		if estado_do_no(str(exigido)) != CONCLUIDO:
			faltas.append("no:%s" % str(exigido))
	for cond in r.get("flags", []):
		if not GerenciadorEstado.avaliar_condicao(cond):
			faltas.append("flag:%s" % str(cond))
	for caminho in r.get("arquivos", []):
		var chave := SistemaArquivosVirtual.chave(str(caminho))
		if chave == "":
			faltas.append("arquivo_inexistente:%s" % str(caminho))
		elif not GerenciadorEstado.tem_flag("arquivo_aberto:" + chave):
			faltas.append("arquivo:%s" % str(caminho))
	for id_evidencia in r.get("evidencias", []):
		if not _evidencia_ok(str(id_evidencia)):
			faltas.append("evidencia:%s" % str(id_evidencia))
	var metricas: Variant = r.get("metricas", {})
	if metricas is Dictionary:
		for nome in metricas:
			var lim: Variant = (metricas as Dictionary)[nome]
			if not (lim is Dictionary):
				continue
			var valor := GerenciadorEstado.obter_metrica(str(nome))
			if (lim as Dictionary).has("min") and valor < float((lim as Dictionary)["min"]):
				faltas.append("metrica:%s<%s" % [str(nome), str((lim as Dictionary)["min"])])
			if (lim as Dictionary).has("max") and valor > float((lim as Dictionary)["max"]):
				faltas.append("metrica:%s>%s" % [str(nome), str((lim as Dictionary)["max"])])
	return {"ok": faltas.is_empty(), "faltas": faltas}


# ------------------------------------------------------------------ ciclo de vida do jogo
## Novo jogo: todos os nós voltam a bloqueados, os iniciais ficam disponíveis e os gatilhos de início já disparam (o nó da Task 1
## ativa aqui).
func reiniciar() -> void:
	if not pronto:
		return
	GerenciadorEstado.nos = {}
	GerenciadorEstado.no_atual = ""
	_inicializar_estados()
	_recalcular_disponibilidade()
	_avaliar_gatilhos()


## Depois de carregar um save: confere os estados salvos. Um save SEM nós (modelo antigo, migrado) é tratado como início da Task 1
## sem reexecutar efeitos de ativação. NÃO reexecuta efeitos de ativação de um save válido (a Task já está em andamento).
func restaurar() -> void:
	if not pronto:
		return
	if GerenciadorEstado.nos.is_empty():
		_inicializar_estados()
		var inicial := GerenciadorEstado.TASK_INICIAL
		if nos.has(inicial):
			_marcar(inicial, ATIVO)
			GerenciadorEstado.no_atual = inicial
	else:
		_sanear_estado()
	_recalcular_disponibilidade()
	_avaliar_gatilhos()


# ------------------------------------------------------------------ ativar e concluir
## Tenta ativar o nó. Devolve {ok, motivo}. Qualquer recusa também sai pelo sinal `falha_de_requisito`.
func ativar(id_no: String, origem: String = "manual") -> Dictionary:
	if not nos.has(id_no):
		return _falha(id_no, "no_desconhecido")
	var def: Dictionary = nos[id_no]
	var estado := estado_do_no(id_no)
	var feitas := ativacoes(id_no)
	if estado == ATIVO:
		return _falha(id_no, "ja_ativo")
	var repetivel := bool(def.get("repetivel", false))
	if feitas >= 1 and not repetivel:
		return _falha(id_no, "ja_ativado")
	if repetivel and feitas >= int(def.get("max_ativacoes", MAX_ATIVACOES_PADRAO)):
		return _falha(id_no, "limite_de_ativacoes")
	if estado == BLOQUEADO:
		return _falha(id_no, "bloqueado")
	var verificacao := verificar_requisitos(id_no)
	if not bool(verificacao["ok"]):
		return _falha(id_no, ",".join(PackedStringArray(verificacao["faltas"])))
	var st := _entrada(id_no)
	st["estado"] = ATIVO
	st["ativacoes"] = feitas + 1
	st["t_ativado"] = int(Time.get_unix_time_from_system())
	GerenciadorEstado.nos[id_no] = st
	if bool(def.get("principal", false)):
		GerenciadorEstado.definir_task(id_no)
	_aplicar_efeitos(def.get("efeitos_ao_ativar", []), id_no)
	for id_mensagem in def.get("dialogos", []):
		SistemaEventos.aplicar_efeito({"tipo": "mensagem", "id": str(id_mensagem)}, {"no": id_no}, "no:" + id_no)
	for id_mensagem in def.get("escolhas", []):
		SistemaEventos.aplicar_efeito({"tipo": "mensagem", "id": str(id_mensagem)}, {"no": id_no}, "no:" + id_no)
	for ev in def.get("eventos", []):
		if ev is Dictionary:
			var dados_ev: Variant = (ev as Dictionary).get("dados", {})
			SistemaEventos.emitir(str((ev as Dictionary).get("id", "")), (dados_ev as Dictionary).duplicate(true) if dados_ev is Dictionary else {}, "no:" + id_no)
	SistemaEventos.emitir("no_ativado", {"id": id_no, "origem": origem}, "nos")
	no_ativado.emit(id_no)
	progresso_atualizado.emit(id_no)
	var conclusao: Variant = def.get("conclusao", {})
	if conclusao is Dictionary and bool((conclusao as Dictionary).get("imediata", false)):
		concluir(id_no, "imediata")
	else:
		_avaliar_gatilhos()
	return {"ok": true, "motivo": ""}


## Conclui um nó ATIVO: efeitos de conclusão, evento/sinal, liberação dos `proximos`. Devolve {ok, motivo}.
func concluir(id_no: String, origem: String = "manual") -> Dictionary:
	if not nos.has(id_no):
		return _falha(id_no, "no_desconhecido")
	if estado_do_no(id_no) != ATIVO:
		return _falha(id_no, "nao_ativo")
	var def: Dictionary = nos[id_no]
	var st := _entrada(id_no)
	st["estado"] = CONCLUIDO
	st["t_concluido"] = int(Time.get_unix_time_from_system())
	GerenciadorEstado.nos[id_no] = st
	_aplicar_efeitos(def.get("efeitos_ao_concluir", []), id_no)
	SistemaEventos.emitir("no_concluido", {"id": id_no, "origem": origem}, "nos")
	no_concluido.emit(id_no)
	progresso_atualizado.emit(id_no)
	if bool(def.get("repetivel", false)) and int(st["ativacoes"]) < int(def.get("max_ativacoes", MAX_ATIVACOES_PADRAO)):
		st["estado"] = DISPONIVEL
		GerenciadorEstado.nos[id_no] = st
	_recalcular_disponibilidade()
	_avaliar_gatilhos()
	return {"ok": true, "motivo": ""}


## "Pedir ajuda à Maya": marca o nó principal em andamento como assistido (a narrativa libera a dica e o modo assistido do objetivo).
## Devolve {ok, id, assistido}. Sem nó em andamento, devolve ok falso.
func destravar_no_atual() -> Dictionary:
	var id_no := GerenciadorEstado.no_atual
	if id_no == "" or not nos.has(id_no) or estado_do_no(id_no) != ATIVO:
		return {"ok": false, "id": id_no, "assistido": false}
	var st := _entrada(id_no)
	st["assistido"] = true
	GerenciadorEstado.nos[id_no] = st
	GerenciadorEstado.set_flag("no_assistido:" + id_no, true)
	progresso_atualizado.emit(id_no)
	return {"ok": true, "id": id_no, "assistido": true}


func assistido(id_no: String) -> bool:
	var st: Variant = GerenciadorEstado.nos.get(id_no)
	return st is Dictionary and bool((st as Dictionary).get("assistido", false))


# ------------------------------------------------------------------ gatilhos (internos)
func _ao_evento(id_evento: String, dados: Dictionary, _item: Dictionary) -> void:
	if not pronto:
		return
	for id_no in _ordem:
		var def: Dictionary = nos[id_no]
		var estado := estado_do_no(str(id_no))
		if estado == DISPONIVEL:
			for g in def.get("gatilhos", []):
				if _gatilho_de_evento_coincide(g as Dictionary, id_evento, dados):
					ativar(str(id_no), "gatilho:" + id_evento)
					break
		elif estado == ATIVO:
			var conclusao: Variant = def.get("conclusao", {})
			if conclusao is Dictionary:
				for ev in (conclusao as Dictionary).get("eventos", []):
					if str((ev as Dictionary).get("evento", "")) == id_evento and _coincide((ev as Dictionary).get("onde"), dados):
						concluir(str(id_no), "evento:" + id_evento)
						break
	_avaliar_gatilhos()


func _ao_flag(_nome: String, _valor: Variant) -> void:
	_avaliar_gatilhos()


func _ao_metrica(_nome: String, _valor: float, _delta: float) -> void:
	_avaliar_gatilhos()


## Avalia os gatilhos PASSIVOS (início, flag, métrica, nó concluído) dos nós disponíveis e as conclusões por flag dos nós ativos,
## repetindo até estabilizar (ativar um nó pode liberar outros). Protegida contra reentrada.
func _avaliar_gatilhos() -> void:
	if not pronto:
		return
	if _avaliando:
		_pendente = true
		return
	_avaliando = true
	var passadas := 0
	while true:
		_pendente = false
		passadas += 1
		for id_no in _ordem:
			var estado := estado_do_no(str(id_no))
			if estado == DISPONIVEL and _gatilho_passivo_atendido(str(id_no)):
				if bool(verificar_requisitos(str(id_no))["ok"]):
					ativar(str(id_no), "gatilho")
			elif estado == ATIVO and _conclusao_por_flags(str(id_no)):
				concluir(str(id_no), "flags")
		if not _pendente or passadas >= MAX_PASSADAS:
			break
	_avaliando = false


func _gatilho_passivo_atendido(id_no: String) -> bool:
	var gatilhos: Array = (nos[id_no] as Dictionary).get("gatilhos", [])
	if gatilhos.is_empty():
		return true
	for g in gatilhos:
		var gd: Dictionary = g
		match str(gd.get("tipo", "")):
			"inicio":
				return true
			"flag":
				if GerenciadorEstado.avaliar_condicao(gd.get("condicao")):
					return true
			"metrica":
				var valor := GerenciadorEstado.obter_metrica(str(gd.get("nome", "")))
				var ok_min := not gd.has("min") or valor >= float(gd["min"])
				var ok_max := not gd.has("max") or valor <= float(gd["max"])
				if ok_min and ok_max:
					return true
			"no_concluido":
				if estado_do_no(str(gd.get("id", ""))) == CONCLUIDO:
					return true
	return false


func _gatilho_de_evento_coincide(g: Dictionary, id_evento: String, dados: Dictionary) -> bool:
	var tipo := str(g.get("tipo", ""))
	if tipo == "evento":
		return str(g.get("evento", "")) == id_evento and _coincide(g.get("onde"), dados)
	return false


func _conclusao_por_flags(id_no: String) -> bool:
	var conclusao: Variant = (nos[id_no] as Dictionary).get("conclusao", {})
	if not (conclusao is Dictionary) or not (conclusao as Dictionary).has("flags"):
		return false
	var flags: Array = (conclusao as Dictionary)["flags"]
	return not flags.is_empty() and GerenciadorEstado.avaliar_condicao(flags)


## `onde`: {campo: valor} ou {campo: {prefixo|contem|igual|min|max: valor}}; todos os campos precisam coincidir.
func _coincide(onde: Variant, dados: Dictionary) -> bool:
	if not (onde is Dictionary):
		return true
	for campo in onde:
		if not dados.has(campo):
			return false
		var esperado: Variant = (onde as Dictionary)[campo]
		var atual: Variant = dados[campo]
		if esperado is Dictionary:
			var op: Dictionary = esperado
			if op.has("prefixo") and not str(atual).to_lower().begins_with(str(op["prefixo"]).to_lower()):
				return false
			if op.has("contem") and not str(atual).to_lower().contains(str(op["contem"]).to_lower()):
				return false
			if op.has("igual") and not _igual(atual, op["igual"]):
				return false
			if op.has("min") and not (_eh_numero(atual) and float(atual) >= float(op["min"])):
				return false
			if op.has("max") and not (_eh_numero(atual) and float(atual) <= float(op["max"])):
				return false
		elif not _igual(atual, esperado):
			return false
	return true


func _igual(a: Variant, b: Variant) -> bool:
	if _eh_numero(a) and _eh_numero(b):
		return is_equal_approx(float(a), float(b))
	return str(a) == str(b)


func _eh_numero(v: Variant) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT


# ------------------------------------------------------------------ estado (interno)
func _inicializar_estados() -> void:
	for id_no in _ordem:
		GerenciadorEstado.nos[str(id_no)] = {"estado": BLOQUEADO, "ativacoes": 0, "t_ativado": 0, "t_concluido": 0}


## Entrada de estado do nó (cópia editável); cria uma nova se faltar.
func _entrada(id_no: String) -> Dictionary:
	var st: Variant = GerenciadorEstado.nos.get(id_no)
	if st is Dictionary:
		return (st as Dictionary).duplicate()
	return {"estado": BLOQUEADO, "ativacoes": 0, "t_ativado": 0, "t_concluido": 0}


## Marca o estado de um nó SEM efeitos (migração e sincronização).
func _marcar(id_no: String, estado: String) -> void:
	var st := _entrada(id_no)
	st["estado"] = estado
	var agora := int(Time.get_unix_time_from_system())
	if estado == BLOQUEADO:
		st["ativacoes"] = 0
		st["t_ativado"] = 0
		st["t_concluido"] = 0
		st.erase("assistido")
	else:
		st["ativacoes"] = maxi(int(st.get("ativacoes", 0)), 1)
		if int(st.get("t_ativado", 0)) == 0:
			st["t_ativado"] = agora
		if estado == CONCLUIDO:
			st["t_concluido"] = agora
	GerenciadorEstado.nos[id_no] = st


## Confere um estado salvo: tira ids que não existem mais, corrige tipos e inclui os nós novos como bloqueados.
func _sanear_estado() -> void:
	var limpo: Dictionary = {}
	for id_no in _ordem:
		var st: Variant = GerenciadorEstado.nos.get(str(id_no))
		var novo: Dictionary = {"estado": BLOQUEADO, "ativacoes": 0, "t_ativado": 0, "t_concluido": 0}
		if st is Dictionary:
			var estado := str((st as Dictionary).get("estado", BLOQUEADO))
			novo["estado"] = estado if ESTADOS.has(estado) else BLOQUEADO
			novo["ativacoes"] = maxi(int((st as Dictionary).get("ativacoes", 0)), 0)
			novo["t_ativado"] = int((st as Dictionary).get("t_ativado", 0))
			novo["t_concluido"] = int((st as Dictionary).get("t_concluido", 0))
			if bool((st as Dictionary).get("assistido", false)):
				novo["assistido"] = true
		limpo[str(id_no)] = novo
	GerenciadorEstado.nos = limpo
	if not nos.has(GerenciadorEstado.no_atual) or estado_do_no(GerenciadorEstado.no_atual) != ATIVO:
		GerenciadorEstado.no_atual = ""
		for id_no in _ordem:
			if bool((nos[id_no] as Dictionary).get("principal", false)) and estado_do_no(str(id_no)) == ATIVO:
				GerenciadorEstado.no_atual = str(id_no)


## Nós bloqueados cujos requisitos de nós e antecessores já estão concluídos passam a disponíveis.
func _recalcular_disponibilidade() -> void:
	for id_no in _ordem:
		if estado_do_no(str(id_no)) != BLOQUEADO or ativacoes(str(id_no)) >= 1 and not bool((nos[id_no] as Dictionary).get("repetivel", false)):
			continue
		if _liberado(str(id_no)):
			var st := _entrada(str(id_no))
			st["estado"] = DISPONIVEL
			GerenciadorEstado.nos[str(id_no)] = st


func _liberado(id_no: String) -> bool:
	var req: Variant = (nos[id_no] as Dictionary).get("requisitos", {})
	if req is Dictionary:
		for exigido in (req as Dictionary).get("nos_concluidos", []):
			if estado_do_no(str(exigido)) != CONCLUIDO:
				return false
	var antecessores: Array = _predecessores.get(id_no, [])
	if antecessores.is_empty():
		return true
	for a in antecessores:
		if estado_do_no(str(a)) == CONCLUIDO:
			return true
	return false


func _aplicar_efeitos(efeitos: Variant, id_no: String) -> void:
	if not (efeitos is Array):
		return
	for efeito in efeitos:
		if efeito is Dictionary:
			SistemaEventos.aplicar_efeito(efeito as Dictionary, {"no": id_no}, "no:" + id_no)


func _evidencia_ok(id_evidencia: String) -> bool:
	var chamada: Variant = provedores.get("evidencia")
	if chamada is Callable and (chamada as Callable).is_valid():
		return bool((chamada as Callable).call(id_evidencia))
	return false


func _falha(id_no: String, motivo: String) -> Dictionary:
	falha_de_requisito.emit(id_no, motivo)
	return {"ok": false, "motivo": motivo}
