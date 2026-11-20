extends Node
## Controlador do ROTEIRO v2.0 da Maya. Não há dias, calendário nem rotina diária: o jogo progride por Tasks (T1 a T9), escolhas,
## permissões, variáveis numéricas (Dependência e Autonomia), flags, Story Nodes e condições de saída, até o nó AV e um de seis finais.
##
## Os DADOS vivem em core/data/narrativa/roteiro_v2.json (nós T1.1 a T9.6, TR.1, AV), relatorios_v2.json e finais_v2.json; as REGRAS de leitura
## e os efeitos estão em FluxoRoteiro; o ESTADO (nó atual, variáveis, flags) está no GerenciadorEstado e é persistido. Este autoload só
## executa: entra em um nó, aplica os efeitos, acrescenta as falas e, quando chega a um nó que precisa do jogador, PARA e espera.
##
## Tipos de nó (ver FluxoRoteiro.TIPOS):
##   fala        acrescenta falas e segue (encadeia sozinho até um nó que bloqueia)
##   rota        escolhe o destino por condições
##   escolha     mostra opções; `escolher_opcao(id)` aplica a resposta, os efeitos e segue
##   cartoes     cartões de permissão (Permitir / Negar / Ver detalhes / Decidir depois); `decidir_cartao`
##   espera      espera um evento (`notificar`) ou opções (`livre`)
##   janela      abre um app e espera o evento `espera`
##   minigame    abre um minigame de lógica; `concluir_minigame(id, "ok"|"sair")`
##   barra_envio a barra de 3 s (6 s com tempo estendido) da Task 6; `cancelar_envio()`
##   fim         AV: avalia o final por prioridade e termina o jogo
## Nada aqui sorteia: o mesmo estado produz sempre o mesmo caminho.

signal etapa_iniciada(etapa: int)
signal jogo_finalizado(id_final: String)
signal janela_solicitada(app_id: String, args: Dictionary)
signal apresentacao_mudou()
signal fala_adicionada(entrada: Dictionary)
signal barra_envio_mudou(ativa: bool, progresso: float)
signal evento_roteiro(id_evento: String, dados: Dictionary)
signal cartao_mudou()
## Emitido a cada nó em que o roteiro entra (inclusive os que encadeiam sozinhos); usado pelos testes e por diagnóstico.
signal no_entrou(id_no: String)
signal mensagem_revelada(contato: String, id_msg: String)

const PASTA_DADOS := "res://core/data/narrativa/"
const DURACAO_BARRA_S := 3.0
const DURACAO_BARRA_ESTENDIDA_S := 6.0
const LIMITE_CADEIA := 400
const INTERVALO_VERIFICACAO_S := 0.25

var jogo_ativo: bool = false
## O jogo começa pausado (menu, splash); a área de trabalho libera quando está pronta.
var pausado: bool = true
var contatos: Dictionary = {}
## Janelas pedidas antes de a área de trabalho existir (o início do jogo acontece no menu). A área de trabalho as consome ao ficar pronta.
var janelas_pendentes: Array = []

var _barra_t: float = 0.0
var _barra_ativa: bool = false
var _acum_verificacao: float = 0.0
var _etapa_anunciada: int = 0
var _em_cadeia: bool = false


func _ready() -> void:
	_carregar_dados()


# ------------------------------------------------------------------ ciclo de jogo
## Novo jogo: estado limpo, sistema de arquivos inicial e o nó T1.1 (sincronização e abertura da Task 1).
func iniciar_novo_jogo(nome: String, pronome: String = "") -> void:
	pausado = true
	_barra_ativa = false
	_etapa_anunciada = 0
	janelas_pendentes.clear()
	GerenciadorEstado.novo_jogo(nome, pronome)
	Permissoes.completar_estado()
	SistemaEventos.reiniciar_unicos()
	SistemaArquivosVirtual.carregar_inicial()
	FluxoRoteiro.garantir()
	if GerenciadorNos.pronto:
		GerenciadorNos.reiniciar()
	jogo_ativo = true
	_ir(FluxoRoteiro.NO_INICIAL)


## Reaplica o estado carregado: volta ao nó em que o save foi feito, sem repetir os efeitos de entrada daquele nó.
func retomar() -> void:
	pausado = true
	_barra_ativa = false
	Permissoes.completar_estado()
	FluxoRoteiro.garantir()
	if GerenciadorNos.pronto:
		GerenciadorNos.restaurar()
	jogo_ativo = GerenciadorEstado.final_id == ""
	_etapa_anunciada = GerenciadorEstado.etapa_atual
	var id_no := GerenciadorEstado.no_roteiro
	if id_no == "" or not FluxoRoteiro.existe(id_no):
		id_no = FluxoRoteiro.NO_INICIAL if GerenciadorEstado.historico_roteiro.is_empty() else "T4.F"
		if not FluxoRoteiro.existe(id_no):
			id_no = FluxoRoteiro.NO_INICIAL
		_ir(id_no)
		return
	if not jogo_ativo:
		apresentacao_mudou.emit()
		return
	_reapresentar(id_no)


func finalizar(id_final: String) -> void:
	if FluxoRoteiro.final_def(id_final).is_empty() or GerenciadorEstado.final_id != "":
		return
	jogo_ativo = false
	_barra_ativa = false
	GerenciadorEstado.set_flag("final_escolhido", true)
	GerenciadorEstado.set_flag("final:" + id_final, true)
	GerenciadorEstado.perfil_final = id_final
	GerenciadorEstado.registrar_final(id_final)
	SistemaAudio.parar_bgm()
	jogo_finalizado.emit(id_final)


## Vai direto a um nó (painel de testes e testes automáticos). Não refaz os efeitos dos nós anteriores: quem chama prepara o estado.
func ir_para_no(id_no: String) -> void:
	if not FluxoRoteiro.existe(id_no):
		return
	jogo_ativo = GerenciadorEstado.final_id == ""
	_barra_ativa = false
	_ir(id_no)


func sair_do_jogo() -> void:
	jogo_ativo = false
	pausado = true
	_barra_ativa = false


# ------------------------------------------------------------------ consultas para a interface
func no_atual() -> Dictionary:
	return FluxoRoteiro.no(GerenciadorEstado.no_roteiro)


func tipo_do_no() -> String:
	return str(no_atual().get("tipo", ""))


## Estado de apresentação do nó atual para o painel da Maya e o Mensageiro.
func apresentacao() -> Dictionary:
	var def := no_atual()
	var saida := {"no": GerenciadorEstado.no_roteiro, "tipo": str(def.get("tipo", "")), "contexto": str(def.get("contexto", "")),
		"contato": str(def.get("contato", "")), "opcoes": [], "espera": "", "livre": bool(def.get("livre", false))}
	match str(def.get("tipo", "")):
		"escolha", "espera":
			saida["opcoes"] = _opcoes_para_interface(def)
			if str(def.get("tipo", "")) == "espera":
				saida["espera"] = str(def.get("evento", ""))
		"janela":
			saida["espera"] = str(def.get("espera", ""))
			saida["app"] = str(def.get("app", ""))
		"minigame":
			saida["app"] = "minigame_logica"
			saida["args"] = {"minigame": str(def.get("minigame", ""))}
		"cartoes":
			saida["cartao"] = cartao_atual()
			saida["app"] = "privacidade_maya"
			saida["args"] = {"no": GerenciadorEstado.no_roteiro}
		"barra_envio":
			saida["barra"] = estado_da_barra()
	return saida


func _opcoes_para_interface(def: Dictionary) -> Array:
	var saida: Array = []
	for o in FluxoRoteiro.opcoes_visiveis(def, _consumidas()):
		var od: Dictionary = o
		if od.has("removida_se") and GerenciadorEstado.avaliar_condicao(od["removida_se"]):
			continue
		saida.append({"id": str(od["id"]), "texto": str(od["texto"])})
	return saida


## Opções que a Maya removeu agora (T9.6): a interface mostra o aviso em vez do botão.
func opcoes_removidas() -> Array:
	var saida: Array = []
	var def := no_atual()
	if def.get("opcoes") is Array:
		for o in def["opcoes"]:
			if o is Dictionary and (o as Dictionary).has("removida_se") and GerenciadorEstado.avaliar_condicao((o as Dictionary)["removida_se"]):
				saida.append(str((o as Dictionary).get("rotulo_removida", "Opção removida pela Maya")))
	return saida


## Histórico do painel da Maya (as últimas MAX_HISTORICO falas).
func historico_da_maya() -> Array:
	return GerenciadorEstado.historico_roteiro


## Mensagens de uma conversa do Mensageiro: o histórico sincronizado (somente leitura) seguido do que o jogo acrescentou.
func mensagens_da_conversa(id_contato: String) -> Array:
	var saida: Array = []
	for c in FluxoRoteiro.conversas_sincronizadas():
		if str((c as Dictionary).get("id", "")) == id_contato:
			for m in (c as Dictionary).get("mensagens", []):
				saida.append({"id": "sync_%s_%d" % [id_contato, saida.size()], "autor": str(m[0]), "texto": str(m[1]), "tipo": "normal", "lida": true, "sincronizada": true})
			if str((c as Dictionary).get("nota", "")) != "":
				saida.append({"id": "sync_%s_nota" % id_contato, "autor": "sistema", "texto": str((c as Dictionary)["nota"]), "tipo": "sistema", "lida": true, "sincronizada": true})
	for e in GerenciadorEstado.historico(id_contato):
		saida.append(e)
	return saida


## Conversas que o Mensageiro mostra. Antes da indexação (Task 6) nenhuma: o app mostra "aguardando indexação".
func contatos_disponiveis() -> Array:
	var saida: Array = []
	if not GerenciadorEstado.tem_flag("mensageiro_indexado"):
		return saida
	var ids: Array = []
	for c in FluxoRoteiro.conversas_sincronizadas():
		ids.append(str((c as Dictionary).get("id", "")))
	for id_contato in GerenciadorEstado.chat:
		if not ids.has(str(id_contato)) and contatos.has(str(id_contato)) and str((contatos[str(id_contato)] as Dictionary).get("grupo", "")) != "sistema":
			ids.append(str(id_contato))
	for id_contato in ids:
		var info := info_contato(id_contato)
		if str(info.get("grupo", "")) == "sistema":
			continue
		if GerenciadorEstado.tem_flag("contatos_reordenados"):
			info["secao"] = "Importantes" if str(info.get("grupo", "")) == "importantes" else "Outros"
		saida.append(info)
	if GerenciadorEstado.tem_flag("contatos_reordenados"):
		saida.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("secao", "")) == "Importantes" and str(b.get("secao", "")) != "Importantes")
	return saida


func info_contato(id_contato: String) -> Dictionary:
	var c: Variant = contatos.get(id_contato)
	if c is Dictionary:
		var copia: Dictionary = (c as Dictionary).duplicate()
		copia["id"] = id_contato
		return copia
	return {"id": id_contato, "nome": id_contato, "icone": "?", "cor": "#94a3b8", "grupo": "outros"}


func titulo_da_etapa(etapa: int) -> String:
	var id_task := "task_%d" % clampi(etapa, 1, 9)
	if GerenciadorNos.pronto and GerenciadorNos.existe(id_task):
		return str(GerenciadorNos.dados_do_no(id_task).get("titulo", ""))
	return ""


# ------------------------------------------------------------------ escolhas
func _consumidas() -> Array:
	var v: Variant = GerenciadorEstado.roteiro_aux.get("consumidas", [])
	return v if v is Array else []


## O jogador escolheu uma opção do nó atual (escolha, ou opções de um nó `espera` livre). Devolve false se a opção não vale agora.
func escolher_opcao(id_opcao: String) -> bool:
	if not jogo_ativo:
		return false
	var def := no_atual()
	var tipo := str(def.get("tipo", ""))
	if tipo != "escolha" and not (tipo == "espera" and def.get("opcoes") is Array):
		return false
	var escolhida: Dictionary = {}
	for o in FluxoRoteiro.opcoes_visiveis(def, _consumidas()):
		if str((o as Dictionary)["id"]) == id_opcao:
			escolhida = o
	if escolhida.is_empty():
		return false
	if escolhida.has("removida_se") and GerenciadorEstado.avaliar_condicao(escolhida["removida_se"]):
		return false
	var id_no := GerenciadorEstado.no_roteiro
	GerenciadorEstado.escolhas_realizadas[id_no] = id_opcao
	if bool(escolhida.get("consome", false)):
		var lista := _consumidas().duplicate()
		lista.append(id_opcao)
		GerenciadorEstado.roteiro_aux["consumidas"] = lista
	var no_chat := str(def.get("contexto", "")) == "chat"
	if not no_chat:
		_adicionar_fala({"quem": "jogador", "texto": str(escolhida["texto"])})
	_adicionar_falas(FluxoRoteiro.falas_validas(escolhida.get("resposta")), def, escolhida.get("resposta"))
	FluxoRoteiro.aplicar_efeitos(escolhida.get("efeitos"), "escolha:" + id_opcao)
	var destino := ""
	if escolhida.get("rotas") is Array:
		for r in escolhida["rotas"]:
			if r is Dictionary and GerenciadorEstado.avaliar_condicao((r as Dictionary).get("se")):
				destino = str((r as Dictionary).get("ir", ""))
				break
	if destino == "":
		destino = str(escolhida.get("proximo", ""))
	_ir(destino)
	return true


# ------------------------------------------------------------------ cartões de permissão (T2, T4.2, T6.1, T9.1)
func _cartoes() -> Dictionary:
	var v: Variant = GerenciadorEstado.roteiro_aux.get("cartoes", {})
	return v if v is Dictionary else {}


func _salvar_cartoes(c: Dictionary) -> void:
	GerenciadorEstado.roteiro_aux["cartoes"] = c


func _decisoes() -> Dictionary:
	var v: Variant = GerenciadorEstado.roteiro_aux.get("decisoes", {})
	return v if v is Dictionary else {}


func decisao_da_permissao(id_perm: String) -> String:
	return str(_decisoes().get(id_perm, ""))


func _montar_fila(def: Dictionary) -> Array:
	var fila: Array = []
	if bool(def.get("popups", false)):
		var acoes: Dictionary = def.get("acoes_maya", {})
		for id_perm in acoes:
			if not Permissoes.valor(str(id_perm)):
				fila.append(str(id_perm))
		return fila
	if bool(def.get("pendentes", false)):
		for id_perm in Permissoes.ids():
			if decisao_da_permissao(str(id_perm)) == "adiada":
				fila.append(str(id_perm))
		return fila
	for id_perm in def.get("permissoes", []):
		fila.append(str(id_perm))
	return fila


## Cartão exibido agora (vazio se não há). Botões: permitir, negar, detalhes, depois (quatro, do mesmo tamanho, sem pré-seleção).
func cartao_atual() -> Dictionary:
	var def := no_atual()
	if str(def.get("tipo", "")) != "cartoes":
		return {}
	var c := _cartoes()
	var fila: Array = c.get("fila", [])
	var i := int(c.get("indice", 0))
	if i >= fila.size():
		return {}
	var id_perm := str(fila[i])
	var info := Permissoes.info(id_perm)
	var popups := bool(def.get("popups", false))
	var texto_pedido := str(info.get("pedido", ""))
	var botoes: Array = [{"id": "permitir", "texto": "Permitir"}, {"id": "negar", "texto": str(def.get("rotulo_negar", "Negar"))}]
	var cartao := {"permissao": id_perm, "nome": str(info.get("nome", id_perm)), "pedido": texto_pedido, "ficha": info.get("ficha", []),
		"detalhes": str(info.get("detalhes", "")), "descricao": str(info.get("descricao", "")), "popup": popups, "indice": i, "total": fila.size()}
	if popups:
		var acoes: Dictionary = def.get("acoes_maya", {})
		var pedido := str((acoes.get(id_perm, {}) as Dictionary).get("pedido", texto_pedido))
		cartao["pedido"] = ("Só pra confirmar: %s" % pedido) if bool((c.get("negadas_uma_vez", {}) as Dictionary).get(id_perm, false)) else pedido
		cartao["botoes"] = botoes
		return cartao
	botoes.append({"id": "detalhes", "texto": "Ver detalhes"})
	if bool(def.get("decidir_depois", false)):
		botoes.append({"id": "depois", "texto": "Decidir depois"})
	cartao["botoes"] = botoes
	return cartao


## Decisão do jogador no cartão atual. `decisao`: "permitir", "negar" ou "depois". Na primeira recusa de um nó com `confirma_recusa`
## devolve {requer_confirmacao: true} e nada muda: a interface mostra [Manter recusa]/[Permitir] e chama de novo com `confirmou` = true.
func decidir_cartao(id_perm: String, decisao: String, confirmou: bool = false) -> Dictionary:
	var def := no_atual()
	var atual := cartao_atual()
	if atual.is_empty() or str(atual["permissao"]) != id_perm:
		return {"ok": false, "motivo": "cartao_nao_atual"}
	var popups := bool(def.get("popups", false))
	var c := _cartoes()
	var decisoes := _decisoes().duplicate()
	match decisao:
		"permitir":
			Permissoes.permitir(id_perm, int(def.get("delta_permitir", 9999)))
			decisoes[id_perm] = "permitida"
			GerenciadorEstado.roteiro_aux["decisoes"] = decisoes
			if popups:
				_maya_age(def, id_perm)
			else:
				_adicionar_falas_texto(def.get("respostas", {}), "permitir")
				FluxoRoteiro.aplicar_efeitos(def.get("efeitos_permitir"), "cartao:" + id_perm)
		"negar":
			if popups:
				var negadas: Dictionary = c.get("negadas_uma_vez", {})
				if not bool(negadas.get(id_perm, false)):
					negadas[id_perm] = true
					c["negadas_uma_vez"] = negadas
					_salvar_cartoes(c)
					cartao_mudou.emit()
					return {"ok": true, "repete": true, "concluido": false}
				var definitivas: Array = c.get("negadas_definitivas", [])
				if not definitivas.has(id_perm):
					definitivas.append(id_perm)
				c["negadas_definitivas"] = definitivas
				decisoes[id_perm] = "negada"
				GerenciadorEstado.roteiro_aux["decisoes"] = decisoes
			else:
				var ja_confirmada := bool(GerenciadorEstado.roteiro_aux.get("recusa_confirmada", false))
				if bool(def.get("confirma_recusa", false)) and not ja_confirmada and not confirmou:
					return {"ok": false, "requer_confirmacao": true}
				if bool(def.get("confirma_recusa", false)):
					GerenciadorEstado.roteiro_aux["recusa_confirmada"] = true
				Permissoes.negar(id_perm, int(def.get("delta_negar", 9999)))
				decisoes[id_perm] = "negada"
				GerenciadorEstado.roteiro_aux["decisoes"] = decisoes
				_adicionar_falas_texto(def.get("respostas", {}), "negar")
				FluxoRoteiro.aplicar_efeitos(def.get("efeitos_negar"), "cartao:" + id_perm)
		"depois":
			if not bool(def.get("decidir_depois", false)) or popups:
				return {"ok": false, "motivo": "indisponivel"}
			decisoes[id_perm] = "adiada"
			GerenciadorEstado.roteiro_aux["decisoes"] = decisoes
		_:
			return {"ok": false, "motivo": "decisao_desconhecida"}
	c = _cartoes()
	c["indice"] = int(c.get("indice", 0)) + 1
	_salvar_cartoes(c)
	var concluido := int(c["indice"]) >= (c.get("fila", []) as Array).size()
	cartao_mudou.emit()
	if concluido:
		_fechar_cartoes(def)
	return {"ok": true, "concluido": concluido}


func _fechar_cartoes(def: Dictionary) -> void:
	if bool(def.get("popups", false)):
		var c := _cartoes()
		var fila: Array = c.get("fila", [])
		var definitivas: Array = c.get("negadas_definitivas", [])
		if not fila.is_empty() and definitivas.size() == fila.size():
			var tn: Dictionary = def.get("todas_negadas", {})
			if tn.has("aut"):
				GerenciadorEstado.registrar_resistencia(StringName(str(tn["aut"])))
			_adicionar_falas(FluxoRoteiro.falas_validas(tn.get("falas")), def, tn.get("falas"))
	_ir(str(def.get("proximo", "")))


## A Maya age em `id_perm` só se a permissão está ativa (a checagem é central: Permissoes.agir_como_maya).
func _maya_age(def: Dictionary, id_perm: String) -> void:
	var acao: Dictionary = (def.get("acoes_maya", {}) as Dictionary).get(id_perm, {})
	Permissoes.agir_como_maya(id_perm, func() -> void:
		FluxoRoteiro.aplicar_efeitos(acao.get("efeitos"), "maya:" + id_perm)
		_adicionar_falas(FluxoRoteiro.falas_validas(acao.get("falas")), def, acao.get("falas")))


func _preparar_cartoes(def: Dictionary) -> void:
	var fila := _montar_fila(def)
	var c: Dictionary = {"fila": fila, "indice": 0, "negadas_uma_vez": {}, "negadas_definitivas": []}
	_salvar_cartoes(c)
	if bool(def.get("popups", false)):
		var acoes: Dictionary = def.get("acoes_maya", {})
		for id_perm in acoes:
			if Permissoes.valor(str(id_perm)):
				_maya_age(def, str(id_perm))


# ------------------------------------------------------------------ espera, janelas e minigames
## Fatos do jogo que podem liberar um nó que espera: "app_aberto:<app>", "janela_fechada:<app>", "retorno_desktop", "rotina_concluida"...
func notificar(evento: String, dados: Dictionary = {}) -> void:
	evento_roteiro.emit(evento, dados)
	if not jogo_ativo:
		return
	var def := no_atual()
	match str(def.get("tipo", "")):
		"espera":
			if str(def.get("evento", "")) == evento or (str(def.get("evento", "")) == "retorno_desktop" and evento.begins_with("janela_fechada:") and _retorno_desktop()):
				_sair_da_espera(def)
			elif def.get("saidas") is Array:
				for s in def["saidas"]:
					if s is Dictionary and str((s as Dictionary).get("evento", "")) == evento:
						_ir(str((s as Dictionary).get("ir", "")))
						return
		"janela":
			if str(def.get("espera", "")) == evento:
				_ir(str(def.get("proximo", "")))


func _sair_da_espera(def: Dictionary) -> void:
	FluxoRoteiro.aplicar_efeitos(def.get("efeitos_ao_sair"), "espera")
	_ir(str(def.get("proximo", "")))


func _retorno_desktop() -> bool:
	for j in GerenciadorJanelas.janelas():
		if (j as JanelaBase).app_id != "maya":
			return false
	return true


## Resultado de um minigame: "ok" (resolvido) ou "sair" (o jogador saiu; o progresso fica salvo).
func concluir_minigame(id_minigame: String, resultado: String) -> void:
	var def := no_atual()
	if str(def.get("tipo", "")) != "minigame" or str(def.get("minigame", "")) != id_minigame:
		return
	if resultado == "ok":
		GerenciadorEstado.puzzles_resolvidos[id_minigame] = true
		FluxoRoteiro.aplicar_efeitos(def.get("efeitos_ok"), "minigame:" + id_minigame)
		_ir(str(def.get("proximo_ok", "")))
	else:
		FluxoRoteiro.aplicar_efeitos(def.get("efeitos_sair"), "minigame:" + id_minigame)
		_ir(str(def.get("proximo_sair", "")))


func solicitar_janela(app_id: String, args: Dictionary = {}) -> void:
	if get_signal_connection_list("janela_solicitada").is_empty():
		janelas_pendentes.append({"app": app_id, "args": args})
	else:
		janela_solicitada.emit(app_id, args)


# ------------------------------------------------------------------ barra de envio (Task 6)
func duracao_da_barra() -> float:
	return DURACAO_BARRA_ESTENDIDA_S if bool(GerenciadorConfiguracoes.obter("tempo_estendido")) else DURACAO_BARRA_S


func estado_da_barra() -> Dictionary:
	var def := no_atual()
	if str(def.get("tipo", "")) != "barra_envio":
		return {"ativa": false}
	var dur := duracao_da_barra()
	return {"ativa": _barra_ativa, "progresso": clampf(_barra_t / dur, 0.0, 1.0), "duracao": dur,
		"rotulo": str(def.get("rotulo", "Maya está enviando por você")), "texto": FluxoRoteiro.texto(str(def.get("texto_maya", ""))), "contato": str(def.get("contato", ""))}


func _iniciar_barra() -> void:
	_barra_t = 0.0
	_barra_ativa = true
	barra_envio_mudou.emit(true, 0.0)


## O jogador cancelou o envio da Maya: a mensagem sai como ele escreveu.
func cancelar_envio() -> bool:
	if not _barra_ativa:
		return false
	_barra_ativa = false
	var def := no_atual()
	_resolver_mensagem_pendente(def, false)
	FluxoRoteiro.aplicar_efeitos(def.get("efeitos_cancelada"), "barra:cancelada")
	barra_envio_mudou.emit(false, _barra_t / duracao_da_barra())
	_ir(str(def.get("proximo_cancelada", "")))
	return true


func _completar_barra() -> void:
	_barra_ativa = false
	var def := no_atual()
	_resolver_mensagem_pendente(def, true)
	FluxoRoteiro.aplicar_efeitos(def.get("efeitos_completa"), "barra:completa")
	barra_envio_mudou.emit(false, 1.0)
	_ir(str(def.get("proximo_completa", "")))


## A mensagem do jogador estava pendente: se a Maya completou, ela troca o texto (guarda o original, assina por ela); senão sai como digitada.
func _resolver_mensagem_pendente(def: Dictionary, pela_maya: bool) -> void:
	var contato := str(def.get("contato", ""))
	var id_msg := str(def.get("id_mensagem", ""))
	var entrada: Dictionary = FluxoRoteiro.entrada_de(contato, id_msg)
	if entrada.is_empty():
		return
	entrada["status"] = "enviada"
	if pela_maya:
		entrada["texto_digitado"] = str(entrada.get("texto", ""))
		entrada["texto"] = FluxoRoteiro.texto(str(def.get("texto_maya", "")))
		entrada["assinada_por"] = "maya"
	GerenciadorEstado.notificar_mensagem_atualizada(contato, id_msg)


## Mensagem ocultada pela Maya: o jogador pede para ver mesmo assim (A +1, uma vez por mensagem).
func mostrar_mensagem_oculta(contato: String, id_msg: String) -> bool:
	var entrada: Dictionary = FluxoRoteiro.entrada_de(contato, id_msg)
	if entrada.is_empty() or not bool(entrada.get("oculta", false)):
		return false
	entrada["oculta"] = false
	entrada["texto"] = str(entrada.get("texto_oculto", entrada.get("texto", "")))
	GerenciadorEstado.registrar_resistencia(StringName("mostrar_mensagem:" + id_msg))
	GerenciadorEstado.notificar_mensagem_atualizada(contato, id_msg)
	mensagem_revelada.emit(contato, id_msg)
	return true


## Revogar o Mensageiro devolve as respostas ao jogador: as mensagens ocultas são reveladas sem custo de Autonomia.
func revelar_todas_ocultas() -> int:
	var n := 0
	for contato in GerenciadorEstado.chat:
		for e in GerenciadorEstado.historico(str(contato)):
			if e is Dictionary and bool((e as Dictionary).get("oculta", false)):
				(e as Dictionary)["oculta"] = false
				(e as Dictionary)["texto"] = str((e as Dictionary).get("texto_oculto", (e as Dictionary).get("texto", "")))
				GerenciadorEstado.notificar_mensagem_atualizada(str(contato), str((e as Dictionary).get("id", "")))
				n += 1
	return n


# ------------------------------------------------------------------ revogação (Permissoes.revogar chama aqui)
## Efeitos e falas da revogação. A fala de resistência da Maya (`falas_task_9`) só vale quando ela contestou (Task 9).
func ao_revogacao(id_perm: String, resultado: String, origem: String, contestada: bool) -> void:
	var rev: Dictionary = FluxoRoteiro.revogacao(id_perm)
	if resultado == "revogada":
		FluxoRoteiro.aplicar_efeitos(rev.get("efeitos"), "revogacao:" + id_perm)
		if id_perm == "permissao_gerenciamento_mensageiro":
			revelar_todas_ocultas()
		if contestada:
			_adicionar_falas(FluxoRoteiro.falas_validas(rev.get("falas_task_9")), {}, rev.get("falas_task_9"))
	elif resultado == "adiada" and origem != "terminal":
		_adicionar_fala({"quem": "maya", "texto": "Acho que você clicou sem querer."})


## Fala avulsa da Maya no painel (usada pelas interfaces: Configurações, Terminal...).
func maya_diz(texto: String) -> void:
	_adicionar_fala({"quem": "maya", "texto": texto})


# ------------------------------------------------------------------ AV: os seis finais
## Avalia o final pela prioridade do roteiro: Rafael 2 → Rafael 1 → Aceitação total → Recusa total → Meio-termo 1 → Meio-termo 2.
## Função pura sobre o estado: o mesmo estado dá sempre o mesmo final.
func avaliar_final() -> String:
	var profunda := GerenciadorEstado.investigacao_profunda_concluida()
	var d := GerenciadorEstado.dependencia_maya()
	var a := GerenciadorEstado.autonomia_jogador()
	if profunda and GerenciadorEstado.tem_flag("rafael_confronto") and GerenciadorEstado.tem_flag("rafael_evidencia_enviada"):
		return "rafael_2"
	if profunda:
		return "rafael_1"
	if d >= 65 and a <= 2 and Permissoes.valor("permissao_gerenciamento_apps") and Permissoes.valor("permissao_gerenciamento_mensageiro"):
		return "aceitacao_total"
	if d <= 35 and a >= 3 and GerenciadorEstado.permissoes_ativas() == 0:
		return "recusa_total"
	if not Permissoes.valor("permissao_gerenciamento_mensageiro"):
		return "meio_termo_1"
	return "meio_termo_2"


# ------------------------------------------------------------------ execução dos nós
func _ir(id_no: String) -> void:
	if _em_cadeia:
		# Efeito que pede outro nó durante a cadeia: o laço atual assume o destino.
		_proximo_da_cadeia = id_no
		return
	_em_cadeia = true
	var atual := id_no
	var guarda := 0
	while atual != "" and guarda < LIMITE_CADEIA:
		guarda += 1
		_proximo_da_cadeia = ""
		var def := FluxoRoteiro.no(atual)
		if def.is_empty():
			push_error("Narrativa: nó '%s' não existe no roteiro." % atual)
			break
		GerenciadorEstado.definir_no_roteiro(atual)
		no_entrou.emit(atual)
		var seguinte := _executar_no(atual, def)
		if _proximo_da_cadeia != "":
			seguinte = _proximo_da_cadeia
		atual = seguinte
	_em_cadeia = false
	_ao_parar()


var _proximo_da_cadeia: String = ""


func _executar_no(id_no: String, def: Dictionary) -> String:
	FluxoRoteiro.aplicar_efeitos(def.get("efeitos"), "no:" + id_no)
	var tipo := str(def.get("tipo", ""))
	match tipo:
		"fala":
			_adicionar_falas(FluxoRoteiro.falas_validas(def.get("falas")), def, def.get("falas"))
			return str(def.get("proximo", ""))
		"rota":
			return FluxoRoteiro.resolver_rota(def)
		"escolha":
			_adicionar_falas(FluxoRoteiro.falas_validas(def.get("falas")), def, def.get("falas"))
			return ""
		"cartoes":
			_preparar_cartoes(def)
			if (_cartoes().get("fila", []) as Array).is_empty():
				return _concluir_cartoes_vazios(def)
			solicitar_janela("privacidade_maya", {"no": id_no})
			return ""
		"espera":
			if str(def.get("evento", "")) == "retorno_desktop" and _retorno_desktop():
				FluxoRoteiro.aplicar_efeitos(def.get("efeitos_ao_sair"), "espera")
				return str(def.get("proximo", ""))
			return ""
		"janela":
			solicitar_janela(str(def.get("app", "")), {"no": id_no})
			return ""
		"minigame":
			solicitar_janela("minigame_logica", {"minigame": str(def.get("minigame", ""))})
			return ""
		"barra_envio":
			_iniciar_barra()
			return ""
		"fim":
			var id_final := avaliar_final()
			_proximo_da_cadeia = ""
			finalizar(id_final)
			return ""
	return ""


## Nada a decidir (todas as permissões do nó já foram decididas): segue direto.
func _concluir_cartoes_vazios(def: Dictionary) -> String:
	return str(def.get("proximo", ""))


## Chamado quando a cadeia para em um nó que espera o jogador: marca o ponto de salvamento da Task e avisa a interface.
func _ao_parar() -> void:
	var etapa := GerenciadorEstado.etapa_atual
	if etapa != _etapa_anunciada:
		_etapa_anunciada = etapa
		etapa_iniciada.emit(etapa)
	apresentacao_mudou.emit()


## Volta a um nó salvo SEM repetir os efeitos de entrada (já estão no estado salvo); só refaz o que é de tempo de execução.
func _reapresentar(id_no: String) -> void:
	var def := FluxoRoteiro.no(id_no)
	match str(def.get("tipo", "")):
		"barra_envio":
			_iniciar_barra()
		"minigame":
			solicitar_janela("minigame_logica", {"minigame": str(def.get("minigame", ""))})
		"cartoes":
			if (_cartoes().get("fila", []) as Array).is_empty():
				_preparar_cartoes(def)
			solicitar_janela("privacidade_maya", {"no": id_no})
		"janela":
			solicitar_janela(str(def.get("app", "")), {"no": id_no})
		"fim":
			_ir(id_no)
			return
		"fala", "rota":
			_ir(id_no)
			return
	apresentacao_mudou.emit()


# ------------------------------------------------------------------ falas
## Fala com `canal: "chat"` vai para a conversa do contato no Mensageiro; as demais vão para o histórico do painel da Maya.
func _adicionar_falas(falas: Array, _def: Dictionary, _bruto: Variant = null) -> void:
	for f in falas:
		var fd: Dictionary = f
		if str(fd.get("canal", "")) == "chat":
			_adicionar_no_chat(fd)
		else:
			_adicionar_fala(fd)


func _adicionar_no_chat(fd: Dictionary) -> void:
	var m := {"contato": str(fd.get("contato", "")), "autor": str(fd.get("quem", "")), "texto": str(fd.get("texto", "")), "silenciosa": true}
	for chave in ["id", "assinada_por", "texto_original"]:
		if fd.has(chave):
			m[chave] = str(fd[chave])
	if fd.has("oculta"):
		m["oculta"] = true
	if bool(fd.get("pendente", false)):
		m["pendente"] = true
	FluxoRoteiro.adicionar_mensagem(m, true)


func _adicionar_falas_texto(mapa: Variant, chave: String) -> void:
	if mapa is Dictionary and (mapa as Dictionary).has(chave):
		_adicionar_fala({"quem": "maya", "texto": FluxoRoteiro.texto(str(mapa[chave]))})


func _adicionar_fala(f: Dictionary) -> void:
	var entrada := {"quem": str(f.get("quem", "maya")), "texto": str(f.get("texto", "")), "no": GerenciadorEstado.no_roteiro, "hora": RelogioGlobal.hora_texto()}
	GerenciadorEstado.historico_roteiro.append(entrada)
	while GerenciadorEstado.historico_roteiro.size() > FluxoRoteiro.MAX_HISTORICO:
		GerenciadorEstado.historico_roteiro.pop_front()
	fala_adicionada.emit(entrada)


# ------------------------------------------------------------------ tempo de execução
func _process(delta: float) -> void:
	if not jogo_ativo or pausado:
		return
	if _barra_ativa:
		_barra_t += delta
		barra_envio_mudou.emit(true, clampf(_barra_t / duracao_da_barra(), 0.0, 1.0))
		if _barra_t >= duracao_da_barra():
			_completar_barra()
		return
	_acum_verificacao += delta
	if _acum_verificacao >= INTERVALO_VERIFICACAO_S:
		_acum_verificacao = 0.0
		var def := no_atual()
		if str(def.get("tipo", "")) == "espera" and str(def.get("evento", "")) == "retorno_desktop" and _retorno_desktop():
			notificar("retorno_desktop")


# ------------------------------------------------------------------ dados
func _carregar_dados() -> void:
	FluxoRoteiro.garantir()
	contatos = FluxoRoteiro.contatos()
	if not FluxoRoteiro.erros.is_empty():
		for e in FluxoRoteiro.erros:
			push_error("Narrativa: " + e)
