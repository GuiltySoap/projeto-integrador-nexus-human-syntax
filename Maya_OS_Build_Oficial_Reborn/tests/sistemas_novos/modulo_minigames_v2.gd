extends ModuloDeTeste
## Módulo 3 (roteiro v2.0): minigames de lógica. Regras puras (LogicaOrdem, LogicaContradicao), dados do JSON e a janela real (AppMinigameLogica):
## sem tempo, tentativas ilimitadas, [Verificar] trava as peças certas e devolve as erradas, dica automática depois de duas verificações sem acerto
## novo, [Sair] salva o progresso, [Como jogar] sempre disponível, tutorial pulado com `conhecimento_logico_adquirido`, deterministas.

const CENA := "res://features/minigames/logica/scenes/app_minigame_logica.tscn"


func executar(banca_do_executor: BancaDeTestes) -> void:
	banca = banca_do_executor
	_isolar_configuracoes()
	_testar_dados()
	_testar_ordem_lista3()
	_testar_ordem_historico()
	_testar_ordem_carregar_saneando()
	_testar_contradicao()
	await _testar_janela_ordem()
	await _testar_janela_trava()
	await _testar_janela_sem_definicao()
	await _testar_rotina()
	_restaurar_configuracoes()
	await get_tree().process_frame


func _def(id: String) -> Dictionary:
	return AppMinigameLogica.definicao(id)


func _testar_dados() -> void:
	_secao("Definições dos minigames (JSON)")
	for id in ["ordenar_lista3", "historico_fragmentado", "trava_rafael"]:
		_ok(not _def(id).is_empty(), "%s está definido" % id)
	_ok(AppMinigameLogica.texto_como_jogar().contains("Sem tempo") and AppMinigameLogica.texto_como_jogar().contains("Sair"), "o texto de [Como jogar] explica as regras comuns")
	_igual((_def("ordenar_lista3")["solucao"] as Array).size(), 4, "lista 3: quatro passos")
	_igual((_def("historico_fragmentado")["solucao"] as Array).size(), 6, "histórico: seis fragmentos")
	_igual(_def("historico_fragmentado")["inicio"], ["f4", "f1", "f6", "f3", "f5", "f2"], "o histórico começa embaralhado na ordem 4, 1, 6, 3, 5, 2")
	_igual(_def("trava_rafael")["evidencias"].size(), 3, "a trava mostra três evidências (E1, E2, E3)")
	_igual(_def("trava_rafael")["afirmacoes"].size(), 3, "...e três afirmações (A, B, C)")
	var corretas := 0
	for a in _def("trava_rafael")["afirmacoes"]:
		if bool((a as Dictionary)["correta"]):
			corretas += 1
	_igual(corretas, 1, "exatamente uma afirmação é a correta (a mentira que a Maya diria ser verdade)")
	_igual(_def("trava_rafael")["afirmacoes"][0]["id"], "A", "a correta é a A")


func _testar_ordem_lista3() -> void:
	_secao("Exercício da lista 3 (Ordenar)")
	var def := _def("ordenar_lista3")
	var e := LogicaOrdem.estado_inicial(def)
	_igual((e["slots"] as Array).size(), 4, "quatro espaços vazios")
	_igual(LogicaOrdem.bandeja(def, e).size(), 4, "quatro peças na bandeja")
	e = LogicaOrdem.colocar(e, "p1", 0)
	e = LogicaOrdem.colocar(e, "p2", 1)
	e = LogicaOrdem.colocar(e, "p4", 2)   # errada de propósito
	e = LogicaOrdem.colocar(e, "p3", 3)   # errada
	var r := LogicaOrdem.verificar(def, e)
	_igual(r["novos"], 2, "[Verificar]: duas peças certas travadas")
	e = r["estado"]
	_igual(e["slots"], ["p1", "p2", "", ""], "as erradas voltaram para a bandeja (espaços vazios)")
	_igual(e["travados"], [true, true, false, false], "as certas ficaram travadas")
	_igual(LogicaOrdem.bandeja(def, e), ["p3", "p4"], "a bandeja tem de novo p3 e p4 (na ordem inicial)")
	var e2 := LogicaOrdem.colocar(e, "p3", 0)
	_igual(e2["slots"], e["slots"], "peça travada não é substituída")
	e = LogicaOrdem.colocar(e, "p3", 2)
	e = LogicaOrdem.colocar(e, "p4", 3)
	r = LogicaOrdem.verificar(def, e)
	_ok(LogicaOrdem.completo(def, r["estado"]), "a sequência certa completa o exercício")
	_ok(LogicaOrdem.verificar(def, LogicaOrdem.estado_inicial(def))["novos"] == 0, "verificar sem nenhuma peça não acerta nem quebra")


func _testar_ordem_historico() -> void:
	_secao("Minigame #1: Histórico fragmentado (dica automática)")
	var def := _def("historico_fragmentado")
	var e := LogicaOrdem.estado_inicial(def)
	_igual(LogicaOrdem.bandeja(def, e), ["f4", "f1", "f6", "f3", "f5", "f2"], "a bandeja começa na ordem 4, 1, 6, 3, 5, 2")
	# duas verificações seguidas sem nenhum acerto
	e = LogicaOrdem.colocar(e, "f6", 0)
	var r := LogicaOrdem.verificar(def, e)
	_igual(r["novos"], 0, "1ª verificação sem acerto")
	e = r["estado"]
	_ok(not LogicaOrdem.dica_ativa(e), "uma verificação sem acerto ainda não dá dica")
	e = LogicaOrdem.colocar(e, "f5", 1)
	r = LogicaOrdem.verificar(def, e)
	e = r["estado"]
	_ok(LogicaOrdem.dica_ativa(e), "depois de duas verificações sem acerto novo, a dica aparece")
	var dica := LogicaOrdem.texto_da_dica(def, e)
	_ok(dica != "", "a dica tem texto (%s)" % dica)
	# acerta a primeira → a dica da próxima posição cita a mensagem anterior
	e = LogicaOrdem.colocar(e, "f1", 0)
	r = LogicaOrdem.verificar(def, e)
	e = r["estado"]
	_igual(r["novos"], 1, "acerto novo trava a primeira mensagem")
	_ok(not LogicaOrdem.dica_ativa(e), "um acerto novo zera o contador da dica")
	_igual(LogicaOrdem.primeira_nao_travada(e), 1, "a primeira posição não travada agora é a 2")
	e["sem_acerto"] = 2
	_ok(LogicaOrdem.texto_da_dica(def, e).begins_with("Esta mensagem responde a: \"rafael.m: maya, o marcos mandou mensagem?\""), "a dica mostra 'Esta mensagem responde a: [trecho da anterior]'")
	# solução completa em qualquer ordem de tentativas
	var solucao: Array = def["solucao"]
	var fim := LogicaOrdem.estado_inicial(def)
	for i in solucao.size():
		fim = LogicaOrdem.colocar(fim, str(solucao[i]), i)
	_ok(LogicaOrdem.completo(def, LogicaOrdem.verificar(def, fim)["estado"]), "a sequência 1–6 completa o minigame")
	_ok(LogicaOrdem.completo(def, fim), "...e `completo` confere sem precisar verificar")
	# determinismo
	var a := LogicaOrdem.verificar(def, LogicaOrdem.colocar(LogicaOrdem.estado_inicial(def), "f2", 1))
	var b := LogicaOrdem.verificar(def, LogicaOrdem.colocar(LogicaOrdem.estado_inicial(def), "f2", 1))
	_igual(a, b, "determinístico: a mesma jogada dá o mesmo resultado")


func _testar_ordem_carregar_saneando() -> void:
	_secao("Progresso salvo dos minigames é saneado")
	var def := _def("historico_fragmentado")
	var base := LogicaOrdem.estado_inicial(def)
	_igual(LogicaOrdem.carregar(def, null), base, "sem progresso: estado inicial")
	_igual(LogicaOrdem.carregar(def, {"slots": ["x"], "travados": []}), base, "tamanho errado: estado inicial")
	_igual(LogicaOrdem.carregar(def, {"slots": ["f1", "f1", "", "", "", ""], "travados": [true, false, false, false, false, false]}), base, "peça repetida: estado inicial")
	_igual(LogicaOrdem.carregar(def, {"slots": ["zzz", "", "", "", "", ""], "travados": [false, false, false, false, false, false]}), base, "peça desconhecida: estado inicial")
	var bom := LogicaOrdem.carregar(def, {"slots": ["f1", "", "", "", "", ""], "travados": [true, true, false, false, false, false], "sem_acerto": 1})
	_igual(bom["slots"][0], "f1", "progresso válido é mantido")
	_igual(bom["travados"][1], false, "espaço vazio nunca fica travado")
	_igual(bom["sem_acerto"], 1, "o contador da dica é mantido")


func _testar_contradicao() -> void:
	_secao("Minigame #2: A trava do Rafael")
	var def := _def("trava_rafael")
	var e := LogicaContradicao.estado_inicial()
	var r := LogicaContradicao.confirmar(def, e, "B")
	_ok(not bool(r["ok"]) and str(r["mensagem"]).contains("E2") and str(r["mensagem"]).contains("E3") and str(r["mensagem"]).begins_with("Essa frase é confirmada por"), "B é confirmada por E2 e E3: %s" % str(r["mensagem"]))
	e = r["estado"]
	_igual(e["erros"], 1, "o erro é contado")
	_ok(not LogicaContradicao.dica_ativa(e), "um erro ainda não dá dica")
	r = LogicaContradicao.confirmar(def, e, "C")
	_ok(not bool(r["ok"]) and str(r["mensagem"]).contains("E1"), "C é confirmada por E1: %s" % str(r["mensagem"]))
	e = r["estado"]
	_ok(LogicaContradicao.dica_ativa(e), "dica depois de dois erros (a linha de E1 fica destacada)")
	r = LogicaContradicao.confirmar(def, e, "inexistente")
	_igual(r["estado"]["erros"], 2, "escolha inexistente não conta como erro")
	r = LogicaContradicao.confirmar(def, e, "A")
	_ok(bool(r["ok"]) and bool(r["estado"]["resolvido"]), "A resolve (as evidências desmentem)")
	_igual(LogicaContradicao.carregar({"erros": -5, "resolvido": 1})["erros"], 0, "progresso salvo inválido é saneado")


# ------------------------------------------------------------------ janela
func _abrir(id: String, origem: String = "") -> AppMinigameLogica:
	var fundo := Control.new()
	fundo.size = Vector2(760, 600)
	add_child(fundo)
	var app := (load(CENA) as PackedScene).instantiate() as AppMinigameLogica
	fundo.add_child(app)
	app.iniciar({"minigame": id, "origem": origem})
	return app


func _fechar(app: AppMinigameLogica) -> void:
	var fundo := app.get_parent()
	fundo.remove_child(app)
	app.queue_free()
	remove_child(fundo)
	fundo.queue_free()


func _tem_filho_do_tipo(no: Node, tipo: String) -> bool:
	if no.get_class() == tipo:
		return true
	for f in no.get_children():
		if _tem_filho_do_tipo(f, tipo):
			return true
	return false


func _botao_com_texto(no: Node, texto: String) -> Button:
	if no is Button and (no as Button).text == texto:
		return no as Button
	for f in no.get_children():
		var b := _botao_com_texto(f, texto)
		if b != null:
			return b
	return null


func _testar_janela_ordem() -> void:
	_secao("Janela: exercício da lista 3 e histórico fragmentado")
	_novo_jogo()
	GerenciadorEstado.limpar_flag("conhecimento_logico_adquirido")
	var app := _abrir("ordenar_lista3")
	await _quadros(2)
	_ok(app._painel_tutorial.visible, "sem conhecimento_logico_adquirido, o tutorial de abertura aparece")
	_ok(_botao_com_texto(app, "Como jogar") != null and _botao_com_texto(app, "Sair") != null and _botao_com_texto(app, "Verificar") != null, "os botões [Como jogar], [Sair] e [Verificar] existem")
	_ok(not _tem_filho_do_tipo(app, "Timer"), "não há temporizador na janela")
	app._fechar_tutorial()
	_ok(not app._painel_tutorial.visible, "[Entendi] fecha o tutorial")
	_botao_com_texto(app, "Como jogar").pressed.emit()
	_ok(app._painel_tutorial.visible, "[Como jogar] reabre o tutorial a qualquer momento")
	app._fechar_tutorial()
	# jogada parcial e saída
	app._ao_peca_da_bandeja("p1")
	app._ao_slot(0)
	app._ao_peca_da_bandeja("p3")
	app._ao_slot(1)   # errada
	app._ao_verificar()
	_igual(app._estado["slots"], ["p1", "", "", ""], "a janela trava a certa e devolve a errada")
	_ok(bool((GerenciadorEstado.progresso_puzzles.get("ordenar_lista3", {}) as Dictionary).get("travados", [false])[0]), "o progresso foi salvo")
	app._ao_sair()
	_ok(app._encerrado, "[Sair] encerra a janela")
	await _quadros(2)
	_fechar(app)
	# reabrir: a peça travada continua
	var app2 := _abrir("ordenar_lista3")
	_igual(app2._estado["slots"][0], "p1", "ao reabrir, o progresso volta (a peça travada continua no lugar)")
	_ok(not GerenciadorEstado.puzzles_resolvidos.has("ordenar_lista3"), "sair não conta como resolvido")
	# resolve
	for i in [1, 2, 3]:
		app2._ao_peca_da_bandeja("p%d" % (i + 1))
		app2._ao_slot(i)
	app2._ao_verificar()
	_ok(bool(GerenciadorEstado.puzzles_resolvidos.get("ordenar_lista3", false)), "resolver registra o minigame como resolvido")
	await _quadros(2)
	_fechar(app2)
	# conhecimento lógico adquirido: tutorial pulado, mas [Como jogar] continua
	GerenciadorEstado.set_flag("conhecimento_logico_adquirido", true)
	var app3 := _abrir("historico_fragmentado")
	await _quadros(2)
	_ok(not app3._painel_tutorial.visible, "com conhecimento_logico_adquirido o tutorial de abertura é pulado")
	_ok(_botao_com_texto(app3, "Como jogar") != null, "...e [Como jogar] continua disponível")
	_igual(LogicaOrdem.bandeja(app3._def, app3._estado), ["f4", "f1", "f6", "f3", "f5", "f2"], "o histórico abre embaralhado na ordem 4, 1, 6, 3, 5, 2")
	# duas verificações sem acerto → dica visível
	app3._ao_peca_da_bandeja("f6")
	app3._ao_slot(0)
	app3._ao_verificar()
	app3._ao_peca_da_bandeja("f6")
	app3._ao_slot(0)
	app3._ao_verificar()
	_ok(app3._rot_dica.visible and app3._rot_dica.text.begins_with("Dica:"), "depois de duas verificações sem acerto novo, a dica aparece na janela")
	# fechar a janela salva o progresso (equivale a [Sair])
	app3.ao_fechar()
	_ok(GerenciadorEstado.progresso_puzzles.has("historico_fragmentado"), "fechar a janela salva o progresso")
	_fechar(app3)


func _testar_janela_trava() -> void:
	_secao("Janela: A trava do Rafael")
	_novo_jogo()
	var app := _abrir("trava_rafael")
	await _quadros(2)
	var texto_ev := ""
	for no in app._itens:
		if no is PanelContainer:
			for f in (no as Node).get_children():
				if f is RichTextLabel:
					texto_ev += (f as RichTextLabel).text + "\n"
	_ok(texto_ev.contains("E1") and texto_ev.contains("E2") and texto_ev.contains("E3"), "as três evidências estão sempre visíveis, sem leitura prévia")
	_ok(texto_ev.contains("24 de 24") and texto_ev.contains("saí. ela não sabe."), "E1 mostra os metadados da foto")
	_ok(not texto_ev.contains("ffd166"), "no começo nenhuma linha está destacada")
	_ok(app._rot_instrucao.text.contains("Rafael trancou este arquivo com uma pergunta.") and app._rot_instrucao.text.contains("Qual destas frases"), "a pergunta do Rafael aparece")
	_ok(app._btn_verificar.disabled, "[Confirmar] fica desativado sem escolha")
	app._ao_afirmacao("B")
	app._ao_verificar()
	_ok(app._rot_msg.text.contains("E2") and app._rot_msg.text.contains("E3"), "erro: a mensagem cita as evidências que confirmam a frase (%s)" % app._rot_msg.text)
	_ok(not GerenciadorEstado.tem_flag("minigame_rafael_resolvido"), "errar não abre o bloco")
	app._ao_afirmacao("C")
	app._ao_verificar()
	var destaque := false
	for no in app._itens:
		if no is PanelContainer:
			for f in (no as Node).get_children():
				if f is RichTextLabel and (f as RichTextLabel).text.contains("ffd166"):
					destaque = true
	_ok(destaque, "depois de dois erros, a linha 'saí. ela não sabe.' fica destacada em E1")
	_igual(int(GerenciadorEstado.progresso_puzzles["trava_rafael"]["erros"]), 2, "os erros ficam salvos à parte")
	app._ao_afirmacao("A")
	app._ao_verificar()
	_ok(GerenciadorEstado.tem_flag("minigame_rafael_resolvido"), "acertar a A: minigame_rafael_resolvido = true")
	_ok(bool(GerenciadorEstado.puzzles_resolvidos.get("trava_rafael", false)), "...e o minigame consta como resolvido")
	await _quadros(2)
	_fechar(app)
	# a flag é de descoberta e nunca volta
	GerenciadorEstado.definir_flag_roteiro("minigame_rafael_resolvido", false)
	_ok(GerenciadorEstado.tem_flag("minigame_rafael_resolvido"), "a flag não volta a false")


func _testar_janela_sem_definicao() -> void:
	_secao("Janela: minigame desconhecido não derruba o jogo")
	var app := _abrir("nao_existe")
	await _quadros(2)
	_ok(app._def.is_empty() and not app._btn_verificar.visible, "mostra o aviso e esconde os botões")
	app.ao_fechar()   # sem definição, fechar não faz nada
	_fechar(app)


func _testar_rotina() -> void:
	_secao("Montagem da rotina (T3.5): interface de escolha, sem falha")
	var bl := RotinaLogica.BLOCOS
	_igual(bl, ["Estudo", "Descanso", "Lazer", "Sair com amigos"], "os quatro blocos")
	var s := RotinaLogica.vazia()
	s = RotinaLogica.colocar(s, "Estudo", 0)
	s = RotinaLogica.colocar(s, "Descanso", 1)
	_ok(RotinaLogica.jogada_da_maya(s).is_empty(), "com dois blocos a Maya ainda não joga")
	s = RotinaLogica.colocar(s, "Sair com amigos", 2)
	var jogada := RotinaLogica.jogada_da_maya(s)
	_igual(jogada, {"indice": 3, "bloco": "Lazer"}, "ao encaixar o terceiro bloco, a Maya preenche o quarto sozinha")
	s = RotinaLogica.colocar(s, "Lazer", 3)
	_ok(RotinaLogica.completa(s) and not RotinaLogica.conflito(s), "rotina completa sem conflito (Estudo antes de Sair com amigos)")
	var s2 := RotinaLogica.colocar(s, "Sair com amigos", 0)
	_igual(s2[0], "Sair com amigos", "mover um bloco para um espaço ocupado troca os dois")
	_igual(s2[2], "Estudo", "...o outro vai para onde o primeiro estava")
	_ok(RotinaLogica.conflito(s2), "'Sair com amigos' antes de 'Estudo' é conflito de produtividade")
	_igual(RotinaLogica.resolver_trocando(s2), s, "[Trocar]: a Maya troca os dois blocos")
	# janela completa
	_novo_jogo()
	var fundo := Control.new()
	fundo.size = Vector2(760, 600)
	add_child(fundo)
	var app := (load("res://features/apps/rotina/scenes/app_rotina.tscn") as PackedScene).instantiate() as AppRotina
	fundo.add_child(app)
	app.iniciar({})
	await _quadros(2)
	_ok(not _tem_filho_do_tipo(app, "Timer"), "a rotina não tem temporizador")
	app.colocar_bloco("Sair com amigos", 0)
	app.colocar_bloco("Descanso", 1)
	app.colocar_bloco("Estudo", 2)
	_ok(RotinaLogica.completa(app._slots), "ao encaixar o 3º bloco a Maya completa o 4º (%s)" % str(app._slots))
	var falas := GerenciadorEstado.historico("maya")
	_ok(JSON.stringify(GerenciadorNarrativa.historico_da_maya()).contains("Bati com o que eu tinha calculado"), "a Maya diz 'Isso! Bati com o que eu tinha calculado.'")
	app._ao_concluir()
	_ok(app._caixa_conflito.visible and not app._concluida, "com conflito a Maya pergunta antes de concluir")
	app._ao_conflito("certeza")
	_ok(app._concluida, "[Tenho certeza] conclui")
	_igual(GerenciadorEstado.roteiro_aux.get("rotina_resultado", ""), "anotado", "o resultado é guardado")
	_ok(falas != null, "(histórico acessível)")
	fundo.remove_child(app)
	app.queue_free()
	remove_child(fundo)
	fundo.queue_free()
