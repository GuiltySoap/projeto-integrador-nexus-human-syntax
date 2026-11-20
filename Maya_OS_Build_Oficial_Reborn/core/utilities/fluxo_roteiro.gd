class_name FluxoRoteiro
extends RefCounted
## Dados e regras do ROTEIRO v2.0 da Maya: os nós numerados (T1.1, T4.F, TR.1, AV...), as condições e os efeitos.
## Funções ESTÁTICAS e sem estado próprio: o estado do jogo vive no GerenciadorEstado (Task, nó atual, flags, métricas, permissões) e a
## execução (apresentar o nó, esperar o jogador, avançar) fica no GerenciadorNarrativa. Os dados vêm de core/data/narrativa/roteiro_v2.json.
##
## TIPOS DE NÓ
##   fala        mostra `falas` (painel da Maya, ou conversa de `contato` no Mensageiro) e segue sozinho para `proximo`
##   escolha     mostra `falas` e as `opcoes` (botões); cada opção tem `efeitos`, `resposta` (falas) e `proximo`; `consome` esconde a opção usada
##   cartoes     fila de cartões de permissão (Permitir / Negar / Ver detalhes / Decidir depois, botões equivalentes)
##   acao        só aplica `efeitos` e segue
##   rota        escolhe o próximo nó por condições (`rotas`: [{se, ir}], `senao`)
##   espera      espera um evento do jogo (`saidas`: [{evento, ir}]) ou `evento`/`proximo`
##   janela      abre uma janela (`app`, `args`) e espera o evento `espera`
##   minigame    abre um minigame de lógica; `proximo_ok` ao resolver e `proximo_sair` ao sair
##   barra_envio a barra de 3 segundos da Task 6 (`proximo_completa`, `proximo_cancelada`)
##   fim         avalia o final (nó AV)
## CONDIÇÕES: ver GerenciadorEstado.avaliar_condicao. EFEITOS: ver `aplicar_efeito`.
## Divergências e decisões ficam em docs/18_roteiro_v2.md.

const ARQUIVO := "res://core/data/narrativa/roteiro_v2.json"
const ARQUIVO_FINAIS := "res://core/data/narrativa/finais_v2.json"
const ARQUIVO_RELATORIOS := "res://core/data/narrativa/relatorios_v2.json"
const TIPOS: PackedStringArray = ["fala", "escolha", "cartoes", "acao", "rota", "espera", "janela", "minigame", "barra_envio", "fim"]
const NO_INICIAL := "T1.1"
const MAX_HISTORICO := 80

static var _nos: Dictionary = {}
static var _roteiro_raiz: Dictionary = {}
static var _finais: Dictionary = {}
static var _relatorios: Dictionary = {}
static var _carregado: bool = false
static var erros: PackedStringArray = PackedStringArray()


# ------------------------------------------------------------------ dados
static func carregar(caminho: String = ARQUIVO) -> bool:
	_carregado = true
	erros = PackedStringArray()
	_nos = {}
	var raiz := _json(caminho)
	_roteiro_raiz = raiz
	if raiz.get("nos") is Dictionary:
		_nos = raiz["nos"]
	else:
		erros.append("roteiro sem o objeto \"nos\": %s" % caminho)
	_finais = _json(ARQUIVO_FINAIS)
	_relatorios = _json(ARQUIVO_RELATORIOS)
	erros.append_array(validar())
	return erros.is_empty()


static func _json(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		return {}
	var lido: Variant = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	return lido if lido is Dictionary else {}


static func garantir() -> void:
	if not _carregado:
		carregar()


static func no(id_no: String) -> Dictionary:
	garantir()
	var d: Variant = _nos.get(id_no)
	return d if d is Dictionary else {}


static func existe(id_no: String) -> bool:
	garantir()
	return _nos.has(id_no)


static func ids() -> PackedStringArray:
	garantir()
	var saida := PackedStringArray()
	for k in _nos:
		saida.append(str(k))
	return saida


## Dados de um final ("tudo_em_ordem", "modo_manual"...). {} se não existir.
static func final_def(id_final: String) -> Dictionary:
	garantir()
	return _sub(_finais, "finais", id_final)


static func ids_dos_finais() -> PackedStringArray:
	garantir()
	var saida := PackedStringArray()
	if _finais.get("finais") is Dictionary:
		for k in _finais["finais"]:
			saida.append(str(k))
	return saida


static func cartao_de_encerramento() -> Array:
	garantir()
	return (_finais.get("cartao_de_encerramento", []) as Array).duplicate(true) if _finais.get("cartao_de_encerramento") is Array else []


static func relatorio(id_relatorio: String) -> Dictionary:
	garantir()
	return _sub(_relatorios, "relatorios", id_relatorio)


static func conversas_sincronizadas() -> Array:
	garantir()
	return (_relatorios.get("conversas", []) as Array).duplicate(true) if _relatorios.get("conversas") is Array else []


## Todos os problemas dos dados: tipo desconhecido, destino inexistente, opção sem destino. Vazio = consistente.
static func validar() -> PackedStringArray:
	var p := PackedStringArray()
	for id_no in _nos:
		var d: Variant = _nos[id_no]
		if not (d is Dictionary):
			p.append("%s: definição inválida" % id_no)
			continue
		var def: Dictionary = d
		var tipo := str(def.get("tipo", ""))
		if not TIPOS.has(tipo):
			p.append("%s: tipo desconhecido '%s'" % [id_no, tipo])
			continue
		for alvo in alvos_de(def):
			if not _nos.has(alvo):
				p.append("%s: destino inexistente '%s'" % [id_no, alvo])
		if tipo == "escolha":
			if not (def.get("opcoes") is Array) or (def["opcoes"] as Array).is_empty():
				p.append("%s: escolha sem opções" % id_no)
			else:
				for o in def["opcoes"]:
					if not (o is Dictionary) or str((o as Dictionary).get("id", "")) == "" or str((o as Dictionary).get("texto", "")) == "":
						p.append("%s: opção sem id ou texto" % id_no)
		if tipo == "rota" and str(def.get("senao", "")) == "":
			p.append("%s: rota sem 'senao' (todo estado precisa ter destino)" % id_no)
	if not _nos.has(NO_INICIAL):
		p.append("falta o nó inicial %s" % NO_INICIAL)
	return p


## Todos os destinos referenciados por um nó.
static func alvos_de(def: Dictionary) -> PackedStringArray:
	var saida := PackedStringArray()
	for campo in ["proximo", "senao", "proximo_ok", "proximo_sair", "proximo_completa", "proximo_cancelada"]:
		if str(def.get(campo, "")) != "":
			saida.append(str(def[campo]))
	for lista_nome in ["opcoes", "rotas", "saidas"]:
		if def.get(lista_nome) is Array:
			for item in def[lista_nome]:
				if item is Dictionary:
					for campo in ["proximo", "ir"]:
						if str((item as Dictionary).get(campo, "")) != "":
							saida.append(str((item as Dictionary)[campo]))
	return saida


# ------------------------------------------------------------------ textos e condições
static func texto(t: String) -> String:
	return GerenciadorEstado.formatar(t)


## Falas cujas condições valem agora, com o texto formatado e o autor resolvido. Cada fala: {quem, texto}.
static func falas_validas(falas: Variant) -> Array:
	var saida: Array = []
	if not (falas is Array):
		return saida
	for f in falas:
		if f is Dictionary:
			var fd: Dictionary = f
			if GerenciadorEstado.avaliar_condicao(fd.get("se")):
				var item := {"quem": str(fd.get("quem", "maya")), "texto": texto(str(fd.get("texto", "")))}
				if fd.has("oculta_se") and GerenciadorEstado.avaliar_condicao(fd["oculta_se"]):
					item["oculta"] = true
				if fd.has("id"):
					item["id"] = str(fd["id"])
				for chave in ["canal", "contato", "assinada_por", "texto_original"]:
					if fd.has(chave):
						item[chave] = str(fd[chave])
				if bool(fd.get("pendente", false)) or (fd.has("pendente_se") and GerenciadorEstado.avaliar_condicao(fd["pendente_se"])):
					item["pendente"] = true
				saida.append(item)
	return saida


## Opções de uma escolha visíveis agora (condição verdadeira e não consumida). Cada uma: {id, texto, ...def}.
static func opcoes_visiveis(def: Dictionary, consumidas: Array = []) -> Array:
	var saida: Array = []
	var lista: Variant = def.get("opcoes", [])
	if lista is Array:
		for o in lista:
			if not (o is Dictionary):
				continue
			var od: Dictionary = o
			if consumidas.has(str(od.get("id", ""))) and bool(od.get("consome", false)):
				continue
			if not GerenciadorEstado.avaliar_condicao(od.get("se")):
				continue
			var item: Dictionary = od.duplicate(true)
			item["texto"] = texto(str(od.get("texto", "")))
			saida.append(item)
	return saida


## Primeira rota cuja condição vale; senão o `senao`.
static func resolver_rota(def: Dictionary) -> String:
	if def.get("rotas") is Array:
		for r in def["rotas"]:
			if r is Dictionary and GerenciadorEstado.avaliar_condicao((r as Dictionary).get("se")):
				return str((r as Dictionary).get("ir", ""))
	return str(def.get("senao", ""))


# ------------------------------------------------------------------ efeitos
## Aplica uma lista de efeitos. Cada efeito é um objeto; o campo "se" (condições) torna o efeito condicional. Efeitos:
##   {"dep": N}                      altera a Dependência (travada em 0..100)
##   {"aut": "id_do_ato"}            ato explícito de resistência: A +1, uma única vez por id
##   {"flag": "nome", "valor": v}    flag (padrão true); flags de descoberta nunca voltam a false
##   {"perm": "id", "valor": bool}   muda a permissão (decisão explícita já tomada)
##   {"task": "task_N"}              conclui a Task atual e ativa a próxima (Story Nodes)
##   {"task_opcional": "task_5", "acao": "ativar"|"concluir"}
##   {"vfs": "mover", "de": "...", "para": "..."}   |  {"vfs": "criar_pasta"...}
##   {"notificar": {"titulo", "texto", "icone"}}
##   {"mensagem": {"contato", "autor", "texto", "id", "oculta_se", "assinada_por"}}
##   {"abrir": "app_id", "args": {}} {"fechar": "app_id"}
##   {"app": "id", "visivel": bool}  mostra/oculta o app na área de trabalho (regra central do GerenciadorJanelas)
##   {"maya_diz": "texto"}           fala avulsa da Maya no painel (comentários ao abrir arquivos)
##   {"evento": "id", "dados": {}}   emite um evento do roteiro (GerenciadorNarrativa.evento_roteiro)
##   {"aux": "chave", "valor": v}    estado auxiliar do roteiro (persistido)
static func aplicar_efeitos(efeitos: Variant, origem: String) -> void:
	if not (efeitos is Array):
		return
	for e in efeitos:
		if e is Dictionary:
			aplicar_efeito(e, origem)


static func aplicar_efeito(e: Dictionary, origem: String) -> void:
	if e.has("se") and not GerenciadorEstado.avaliar_condicao(e["se"]):
		return
	if e.has("dep"):
		GerenciadorEstado.alterar_dependencia_maya(int(e["dep"]), StringName(origem))
	if e.has("aut"):
		GerenciadorEstado.registrar_resistencia(StringName(str(e["aut"])))
	if e.has("flag"):
		GerenciadorEstado.definir_flag_roteiro(str(e["flag"]), e.get("valor", true))
	if e.has("perm"):
		Permissoes.definir(str(e["perm"]), bool(e.get("valor", true)))
	if e.has("task"):
		mudar_task(str(e["task"]))
	if e.has("task_opcional"):
		_task_opcional(str(e["task_opcional"]), str(e.get("acao", "ativar")))
	if e.has("vfs"):
		_efeito_vfs(e)
	if e.has("notificar") and e["notificar"] is Dictionary:
		var n: Dictionary = e["notificar"]
		SistemaNotificacoes.notificar(texto(str(n.get("titulo", "Maya"))), texto(str(n.get("texto", ""))), str(n.get("icone", "ia")), float(n.get("duracao", 7.0)), str(n.get("app", "")))
	if e.has("mensagem") and e["mensagem"] is Dictionary:
		adicionar_mensagem(e["mensagem"] as Dictionary)
	if e.has("abrir"):
		GerenciadorNarrativa.solicitar_janela(str(e["abrir"]), e.get("args", {}) if e.get("args") is Dictionary else {})
	if e.has("fechar"):
		for j in GerenciadorJanelas.janelas_do_app(str(e["fechar"])):
			GerenciadorJanelas.fechar_janela(j, true)
	if e.has("app"):
		GerenciadorEstado.definir_flag_roteiro("app_oculto:" + str(e["app"]), not bool(e.get("visivel", true)))
		GerenciadorJanelas.catalogo_alterado.emit()
	if e.has("maya_diz"):
		GerenciadorNarrativa.maya_diz(texto(str(e["maya_diz"])))
	if e.has("evento"):
		GerenciadorNarrativa.evento_roteiro.emit(str(e["evento"]), (e.get("dados", {}) as Dictionary).duplicate(true) if e.get("dados") is Dictionary else {})
	if e.has("aux"):
		GerenciadorEstado.roteiro_aux[str(e["aux"])] = e.get("valor")


## Conclui a Task atual (se estiver ativa) e ativa `id_task`. Se os dados dos nós de Task falharem, só troca a Task no estado.
static func mudar_task(id_task: String) -> void:
	if GerenciadorEstado.task_atual == id_task:
		return
	if GerenciadorNos.pronto and GerenciadorNos.existe(id_task):
		var atual := GerenciadorEstado.task_atual
		if atual != "" and GerenciadorNos.estado_do_no(atual) == GerenciadorNos.ATIVO:
			GerenciadorNos.concluir(atual, "roteiro")
		var r: Dictionary = GerenciadorNos.ativar(id_task, "roteiro")
		if bool(r["ok"]):
			return
		push_warning("FluxoRoteiro: não foi possível ativar '%s' (%s); a Task foi trocada direto." % [id_task, str(r["motivo"])])
	GerenciadorEstado.definir_task(id_task)


static func _task_opcional(id_task: String, acao: String) -> void:
	if not (GerenciadorNos.pronto and GerenciadorNos.existe(id_task)):
		return
	if acao == "ativar" and GerenciadorNos.estado_do_no(id_task) in [GerenciadorNos.DISPONIVEL, GerenciadorNos.BLOQUEADO]:
		GerenciadorNos.ativar(id_task, "roteiro")
	elif acao == "concluir" and GerenciadorNos.estado_do_no(id_task) == GerenciadorNos.ATIVO:
		GerenciadorNos.concluir(id_task, "roteiro")


static func _efeito_vfs(e: Dictionary) -> void:
	match str(e["vfs"]):
		"mover":
			SistemaArquivosVirtual.mover(str(e.get("de", "")), str(e.get("para", "")))
		"mover_todos":
			# {"vfs":"mover_todos","itens":[{"de","para"}...]}
			for item in e.get("itens", []):
				if item is Dictionary:
					SistemaArquivosVirtual.mover(str((item as Dictionary).get("de", "")), str((item as Dictionary).get("para", "")))


## Acrescenta uma mensagem à conversa de `contato` (Mensageiro). Campos: contato, autor, texto, id, `oculta` (ou `oculta_se`: a Maya a esconde),
## `pendente` (mensagem do jogador que a Maya pode trocar: a barra de envio), `assinada_por`, `texto_original`, `silenciosa` (sem notificação).
## Sem `forcar`, mensagens repetidas (mesmo id) são ignoradas.
static func adicionar_mensagem(m: Dictionary, _forcar: bool = false) -> void:
	var contato := str(m.get("contato", ""))
	if contato == "":
		return
	var id_msg := str(m.get("id", "%s_%d" % [contato, GerenciadorEstado.historico(contato).size() + 1]))
	if GerenciadorEstado.tem_mensagem(contato, id_msg):
		return
	var autor := str(m.get("autor", contato))
	var msg := {
		"id": id_msg, "autor": autor, "texto": texto(str(m.get("texto", ""))), "tipo": "normal",
		"hora": RelogioGlobal.hora_texto(), "lida": autor == "jogador" or autor == "sistema",
	}
	for chave in ["assinada_por", "texto_original"]:
		if m.has(chave):
			msg[chave] = str(m[chave])
	if bool(m.get("pendente", false)):
		msg["status"] = "enviando"
		msg["texto_digitado"] = msg["texto"]
	var oculta := bool(m.get("oculta", false)) or (m.has("oculta_se") and GerenciadorEstado.avaliar_condicao(m["oculta_se"]))
	if oculta:
		msg["oculta"] = true
		msg["texto_oculto"] = msg["texto"]
		msg["texto"] = "Mensagem ocultada pela Maya: pode te deixar ansioso."
	GerenciadorEstado.adicionar_mensagem(contato, msg)
	if autor != "jogador" and autor != "sistema" and not bool(m.get("silenciosa", false)):
		var nome := str(GerenciadorNarrativa.info_contato(contato).get("nome", contato))
		SistemaNotificacoes.notificar(nome, UtilTexto.truncar(str(msg["texto"]), 90), "info", 6.0, "messenger")
		SistemaAudio.tocar_sfx("mensagem")


## Entrada do histórico de `contato` com o id dado (referência: alterá-la altera o estado). Vazio se não existe.
static func entrada_de(contato: String, id_msg: String) -> Dictionary:
	for e in GerenciadorEstado.historico(contato):
		if e is Dictionary and str((e as Dictionary).get("id", "")) == id_msg:
			return e
	return {}


static func contatos() -> Dictionary:
	garantir()
	return (_relatorios.get("contatos", {}) as Dictionary).duplicate(true) if _relatorios.get("contatos") is Dictionary else {}


## Efeitos e falas de revogação de uma permissão (dados em roteiro_v2.json > revogacoes).
static func revogacao(id_perm: String) -> Dictionary:
	garantir()
	return _sub(_roteiro_raiz, "revogacoes", id_perm)


## raiz[grupo][chave] como Dictionary ({} se faltar algo no caminho).
static func _sub(raiz: Dictionary, grupo: String, chave: String) -> Dictionary:
	var g: Variant = raiz.get(grupo)
	if g is Dictionary:
		var v: Variant = (g as Dictionary).get(chave)
		if v is Dictionary:
			return v
	return {}
