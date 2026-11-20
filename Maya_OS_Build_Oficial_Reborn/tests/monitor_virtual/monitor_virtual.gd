extends Node
## Teste do monitor virtual do HumaxOS (§12): o desktop dentro de um SubViewport, mostrado numa "tela de monitor" sobre um fundo físico.
##
## Cobre: as funções puras (encaixe com letterbox e limites de resolução), a regra de foco (um só destino para a entrada: mundo físico OU
## desktop, F8 e clique dentro/fora da tela), o roteamento de mouse de ponta a ponta (um clique REAL, injetado na entrada do motor, chega ao
## botão certo do desktop em vários tamanhos de resolução virtual), o gancho de conversão de ponto do GerenciadorJanelas, a acessibilidade
## (alto contraste, modo conforto e reduzir animações, com o foco em TEXTO, não só em cor) e o desktop de verdade (area_de_trabalho.tscn)
## rodando dentro do SubViewport.
##
## Como usar: abra tests/monitor_virtual/monitor_virtual.tscn e pressione F6 (ou `godot --path . res://tests/monitor_virtual/monitor_virtual.tscn`).
## Resultado: painel Saída e tests/_saida/monitor_virtual/log.txt (mais capturas de tela quando há janela). Código de saída: 0 = tudo certo; 1 = falhas.
## Segurança: salvamento e preferências em disco ficam desligados; nada é gravado fora de tests/_saida/monitor_virtual/; nada é apagado.

const SAIDA := "res://tests/_saida/monitor_virtual/"
const RESOLUCOES_TESTADAS: Array = [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(1600, 1000)]

var _log: PackedStringArray = []
var _verificacoes: int = 0
var _falhas: int = 0
var _focos: Array = []
var _resolucoes: Array = []
var _cliques_sonda: int = 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA))
	await get_tree().process_frame
	await _executar()
	_registrar("RESULTADO: %d verificações, %d falhas." % [_verificacoes, _falhas])
	_gravar()
	get_tree().quit(1 if _falhas > 0 else 0)


func _executar() -> void:
	var habilitado_antes: bool = SistemaPersistencia.habilitado
	var persistencia_cfg_antes: bool = GerenciadorConfiguracoes.persistencia_habilitada
	var valores_antes: Dictionary = GerenciadorConfiguracoes.valores.duplicate(true)
	SistemaPersistencia.habilitado = false
	GerenciadorConfiguracoes.persistencia_habilitada = false
	GerenciadorNarrativa.pausado = true

	_testar_funcoes_puras()
	await _testar_regra_de_foco()
	await _testar_mouse_de_ponta_a_ponta()
	await _testar_gancho_de_janelas()
	await _testar_acessibilidade()
	await _testar_desktop_de_verdade()

	GerenciadorConfiguracoes.valores = valores_antes
	GerenciadorConfiguracoes.persistencia_habilitada = persistencia_cfg_antes
	SistemaPersistencia.habilitado = habilitado_antes


# ------------------------------------------------------------------ funções puras
func _testar_funcoes_puras() -> void:
	_registrar("== funções puras: encaixe e limites")
	var igual: Dictionary = MonitorVirtual.encaixar(Vector2i(1920, 1080), Vector2(1920, 1080))
	_ok(is_equal_approx(float(igual["escala"]), 1.0) and (igual["posicao"] as Vector2).is_equal_approx(Vector2.ZERO), "área do mesmo tamanho: escala 1 e sem deslocamento")
	var metade: Dictionary = MonitorVirtual.encaixar(Vector2i(1920, 1080), Vector2(960, 540))
	_ok(is_equal_approx(float(metade["escala"]), 0.5) and (metade["posicao"] as Vector2).is_equal_approx(Vector2.ZERO), "área de metade do tamanho: escala 0,5")
	var mais_alta: Dictionary = MonitorVirtual.encaixar(Vector2i(1920, 1080), Vector2(1600, 1000))
	_ok(is_equal_approx(float(mais_alta["escala"]), 1600.0 / 1920.0) and is_equal_approx((mais_alta["posicao"] as Vector2).y, (1000.0 - 1080.0 * (1600.0 / 1920.0)) / 2.0) and is_equal_approx((mais_alta["posicao"] as Vector2).x, 0.0), "área mais alta (16:10): limita pela largura e centraliza na vertical")
	var mais_larga: Dictionary = MonitorVirtual.encaixar(Vector2i(1920, 1080), Vector2(2560, 1080))
	_ok(is_equal_approx(float(mais_larga["escala"]), 1.0) and is_equal_approx((mais_larga["posicao"] as Vector2).x, 320.0), "área mais larga (21:9): limita pela altura e centraliza na horizontal")
	for area in [Vector2(0, 0), Vector2(-10, 500), Vector2(500, 0)]:
		var vazia: Dictionary = MonitorVirtual.encaixar(Vector2i(1920, 1080), area)
		_ok(is_equal_approx(float(vazia["escala"]), 1.0) and (vazia["posicao"] as Vector2) == Vector2.ZERO, "área degenerada %s não quebra: escala 1, posição zero" % str(area))
	var sem_res: Dictionary = MonitorVirtual.encaixar(Vector2i(0, 0), Vector2(800, 600))
	_ok(is_equal_approx(float(sem_res["escala"]), 1.0), "resolução virtual zerada não divide por zero")
	for ok_res in [Vector2i(640, 360), Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(3840, 2160)]:
		_ok(MonitorVirtual.resolucao_valida(ok_res), "resolução válida: %s" % str(ok_res))
	for ruim in [Vector2i(639, 360), Vector2i(640, 359), Vector2i(0, 0), Vector2i(-1920, 1080), Vector2i(3841, 2160), Vector2i(3840, 2161)]:
		_ok(not MonitorVirtual.resolucao_valida(ruim), "resolução recusada: %s" % str(ruim))
	_ok(MonitorVirtual.mundo_fisico_pode_receber_entrada(null), "sem árvore: o mundo físico recebe a entrada")
	_ok(MonitorVirtual.mundo_fisico_pode_receber_entrada(get_tree()), "sem monitor na árvore: o mundo físico recebe a entrada")
	_ok(InputMap.has_action(MonitorVirtual.ACAO_ALTERNAR), "a ação F8 (alternar foco) está registrada no InputMap")
	var teclas: Array = []
	for ev in InputMap.action_get_events(MonitorVirtual.ACAO_ALTERNAR):
		if ev is InputEventKey:
			teclas.append((ev as InputEventKey).keycode)            # o InputMap do jogo liga a tecla pelo keycode (a tecla lógica)
			teclas.append((ev as InputEventKey).physical_keycode)
	_ok(teclas.has(KEY_F8), "a ação de alternar o foco está ligada à tecla F8")


# ------------------------------------------------------------------ cena do monitor
func _criar_sonda() -> PackedScene:
	var raiz := Control.new()
	raiz.name = "Sonda"
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	var botao := Button.new()
	botao.name = "Botao"
	botao.text = "Sonda"
	botao.position = Vector2(100, 100)
	botao.size = Vector2(200, 80)
	raiz.add_child(botao)
	botao.owner = raiz
	var campo := LineEdit.new()
	campo.name = "Campo"
	campo.position = Vector2(100, 220)
	campo.size = Vector2(300, 40)
	raiz.add_child(campo)
	campo.owner = raiz
	var cena := PackedScene.new()
	cena.pack(raiz)
	raiz.free()
	return cena


func _criar_monitor(iniciar_no_desktop: bool = false) -> MonitorVirtual:
	var cena: PackedScene = load(Cenas.MONITOR_VIRTUAL) as PackedScene
	var monitor := cena.instantiate() as MonitorVirtual
	monitor.cena_desktop = _criar_sonda()
	monitor.iniciar_no_desktop = iniciar_no_desktop
	add_child(monitor)
	await get_tree().process_frame
	await get_tree().process_frame
	return monitor


func _container(monitor: MonitorVirtual) -> SubViewportContainer:
	return monitor.get_node("%ContainerTela") as SubViewportContainer


## O ponto da tela física que cai no ponto `virtual` do desktop (a conta que o motor faz ao contrário).
func _para_fisico(monitor: MonitorVirtual, virtual: Vector2) -> Vector2:
	return _container(monitor).get_global_transform_with_canvas() * virtual


func _clique(posicao: Vector2, apertado: bool) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = apertado
	ev.position = posicao
	ev.global_position = posicao
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if apertado else 0
	return ev


## Zera a marca de "evento tratado" da janela principal empurrando um evento inofensivo (o motor a zera a cada evento novo).
func _limpar_tratado() -> void:
	get_viewport().push_input(InputEventMouseMotion.new())


func _ao_foco(foco: int) -> void:
	_focos.append(foco)


func _ao_resolucao(res: Vector2i) -> void:
	_resolucoes.append(res)


func _testar_regra_de_foco() -> void:
	_registrar("== regra de foco: um destino só para a entrada")
	var monitor: MonitorVirtual = await _criar_monitor()
	_focos.clear()
	monitor.foco_alterado.connect(_ao_foco)
	var vp: SubViewport = monitor.viewport_do_desktop()
	_ok(monitor.foco() == MonitorVirtual.Foco.FISICO and not monitor.desktop_tem_foco(), "o monitor começa com o foco no mundo físico")
	_ok(vp.gui_disable_input, "com o foco no mundo físico o desktop NÃO recebe entrada (gui_disable_input)")
	_ok(MonitorVirtual.mundo_fisico_pode_receber_entrada(get_tree()), "...e o mundo físico recebe a entrada")
	_ok((monitor.get_node("%IndicadorFoco") as Label).text == MonitorVirtual.TEXTO_FOCO_FISICO, "o foco aparece em TEXTO (indicador): mundo físico")
	_ok((monitor.get_node("%AvisoFoco") as Label).visible and (monitor.get_node("%AvisoFoco") as Label).text == MonitorVirtual.TEXTO_AVISO, "o aviso 'clique ou F8' aparece sobre a tela")
	_ok(_container(monitor).mouse_filter == Control.MOUSE_FILTER_IGNORE, "a tela não captura o mouse quando o foco está no mundo físico")
	_ok(is_instance_valid(monitor.desktop()) and monitor.desktop().get_viewport() == vp and monitor.desktop().name == "Sonda", "o desktop mora DENTRO do SubViewport (a sonda)")
	_ok(monitor.is_in_group(MonitorVirtual.GRUPO), "o monitor se registra no grupo '%s'" % MonitorVirtual.GRUPO)

	monitor.entrar_no_desktop()
	_ok(monitor.foco() == MonitorVirtual.Foco.DESKTOP and monitor.desktop_tem_foco() and not vp.gui_disable_input, "entrar_no_desktop: o desktop passa a receber a entrada")
	_ok(not MonitorVirtual.mundo_fisico_pode_receber_entrada(get_tree()), "...e o mundo físico deixa de receber (mundo_fisico_pode_receber_entrada = falso)")
	_ok((monitor.get_node("%IndicadorFoco") as Label).text == MonitorVirtual.TEXTO_FOCO_DESKTOP and not (monitor.get_node("%AvisoFoco") as Label).visible, "o texto do foco muda para 'computador' e o aviso some")
	_ok(_container(monitor).mouse_filter == Control.MOUSE_FILTER_STOP, "a tela captura o mouse com o foco no desktop")
	_ok(_focos == [int(MonitorVirtual.Foco.DESKTOP)], "o sinal foco_alterado foi emitido uma vez, com DESKTOP")
	monitor.entrar_no_desktop()
	_ok(_focos.size() == 1, "entrar de novo no desktop não repete o sinal (nada mudou)")

	var campo := monitor.desktop().get_node("Campo") as LineEdit
	campo.grab_focus()
	_ok(vp.gui_get_focus_owner() == campo, "com o foco no desktop, o campo de texto do desktop pode receber o foco do teclado")
	monitor.voltar_ao_mundo_fisico()
	_ok(monitor.foco() == MonitorVirtual.Foco.FISICO and vp.gui_disable_input and MonitorVirtual.mundo_fisico_pode_receber_entrada(get_tree()), "voltar_ao_mundo_fisico devolve a entrada ao mundo físico")
	_ok(vp.gui_get_focus_owner() == null, "o campo de texto do desktop larga o foco ao sair (nada continua 'ouvindo' o teclado)")
	_ok(_focos == [int(MonitorVirtual.Foco.DESKTOP), int(MonitorVirtual.Foco.FISICO)], "os sinais saíram na ordem DESKTOP, FISICO")

	monitor.alternar_foco()
	_ok(monitor.desktop_tem_foco(), "alternar_foco: físico -> desktop")
	monitor.alternar_foco()
	_ok(not monitor.desktop_tem_foco(), "alternar_foco: desktop -> físico")

	# F8, pelo caminho que o motor usa (ação do InputMap)
	var f8 := InputEventAction.new()
	f8.action = MonitorVirtual.ACAO_ALTERNAR
	f8.pressed = true
	monitor._input(f8)
	_ok(monitor.desktop_tem_foco(), "F8 passa o foco para o desktop")
	monitor._input(f8)
	_ok(not monitor.desktop_tem_foco(), "F8 de novo devolve o foco ao mundo físico")
	var solto := InputEventAction.new()
	solto.action = MonitorVirtual.ACAO_ALTERNAR
	solto.pressed = false
	monitor._input(solto)
	_ok(not monitor.desktop_tem_foco(), "soltar o F8 não muda o foco")

	# o roteamento do clique (decisão pura) em cada foco
	var centro: Vector2 = _para_fisico(monitor, Vector2(monitor.resolucao()) / 2.0)
	var fora: Vector2 = Vector2(2, 2)
	_ok(monitor.ponto_dentro_do_monitor(centro) and not monitor.ponto_dentro_do_monitor(fora), "o centro da tela está dentro do monitor e o canto da janela está fora")
	_ok(monitor.decidir_clique(_clique(centro, true)) == MonitorVirtual.DecisaoClique.ENTRAR_NO_DESKTOP, "foco físico + clique dentro da tela: entra no desktop")
	_ok(monitor.decidir_clique(_clique(fora, true)) == MonitorVirtual.DecisaoClique.IGNORAR, "foco físico + clique fora da tela: ignorado (é do mundo físico)")
	_ok(monitor.decidir_clique(_clique(centro, false)) == MonitorVirtual.DecisaoClique.IGNORAR, "soltar o botão nunca muda o foco")
	var direito := _clique(centro, true)
	direito.button_index = MOUSE_BUTTON_RIGHT
	_ok(monitor.decidir_clique(direito) == MonitorVirtual.DecisaoClique.IGNORAR, "só o botão esquerdo conta")
	_ok(monitor.decidir_clique(InputEventKey.new()) == MonitorVirtual.DecisaoClique.IGNORAR, "um evento que não é de mouse é ignorado")
	monitor.entrar_no_desktop()
	_ok(monitor.decidir_clique(_clique(centro, true)) == MonitorVirtual.DecisaoClique.IGNORAR, "foco no desktop + clique dentro da tela: segue para o desktop")
	_ok(monitor.decidir_clique(_clique(fora, true)) == MonitorVirtual.DecisaoClique.VOLTAR_AO_MUNDO_FISICO, "foco no desktop + clique fora da tela: volta ao mundo físico")
	monitor.clique_fora_devolve_o_foco = false
	_ok(monitor.decidir_clique(_clique(fora, true)) == MonitorVirtual.DecisaoClique.IGNORAR, "com clique_fora_devolve_o_foco desligado o clique fora é ignorado")
	monitor.clique_fora_devolve_o_foco = true

	# teclado: com o desktop em foco o mundo físico não recebe teclado nem controle
	var tecla := InputEventKey.new()
	tecla.keycode = KEY_A
	tecla.pressed = true
	_ok(monitor.consome_entrada_de_teclado(tecla) and monitor.consome_entrada_de_teclado(InputEventJoypadButton.new()), "foco no desktop: teclado e controle são consumidos (não passam para o mundo físico)")
	_ok(not monitor.consome_entrada_de_teclado(InputEventMouseMotion.new()), "o movimento do mouse não é 'teclado'")
	monitor.voltar_ao_mundo_fisico()
	_ok(not monitor.consome_entrada_de_teclado(tecla), "foco no mundo físico: o teclado segue para o mundo físico")

	# os atalhos de segurança funcionam com o foco no mundo físico (Ctrl+Shift+D abre o modo conforto)
	_ok(InputMap.has_action("nexus_forcar_desativar"), "a ação Ctrl+Shift+D está registrada")
	GerenciadorConfiguracoes.desativar_modo_conforto()
	_ok(not GerenciadorConfiguracoes.modo_conforto_ativo(), "o modo conforto começa desligado")
	var forcar := InputEventKey.new()   # o atalho só vale para tecla de verdade (o monitor confere InputEventKey)
	forcar.keycode = KEY_D
	forcar.ctrl_pressed = true
	forcar.shift_pressed = true
	forcar.pressed = true
	monitor._input(forcar)
	_ok(GerenciadorConfiguracoes.modo_conforto_ativo(), "Ctrl+Shift+D (modo conforto) funciona com o foco no mundo físico")
	_limpar_tratado()
	GerenciadorConfiguracoes.desativar_modo_conforto()
	monitor.entrar_no_desktop()
	monitor._input(forcar)
	_ok(not GerenciadorConfiguracoes.modo_conforto_ativo(), "...e com o foco no desktop é o próprio desktop que trata a tecla (o monitor não a duplica)")
	_limpar_tratado()
	monitor.queue_free()
	await get_tree().process_frame
	_ok(MonitorVirtual.mundo_fisico_pode_receber_entrada(get_tree()), "sem monitor de novo: o mundo físico recebe a entrada")


func _testar_mouse_de_ponta_a_ponta() -> void:
	_registrar("== mouse de ponta a ponta: o clique real chega ao botão certo do desktop")
	var monitor: MonitorVirtual = await _criar_monitor()
	_resolucoes.clear()
	monitor.resolucao_alterada.connect(_ao_resolucao)
	var botao := monitor.desktop().get_node("Botao") as Button
	botao.pressed.connect(_ao_sonda_pressionada)
	var vp: SubViewport = monitor.viewport_do_desktop()

	var res_antes: Vector2i = monitor.resolucao()
	_ok(not monitor.definir_resolucao(Vector2i(320, 200)) and monitor.resolucao() == res_antes, "uma resolução abaixo do mínimo é recusada e nada muda")
	_ok(not monitor.definir_resolucao(res_antes), "a mesma resolução não conta como mudança")
	_ok(_resolucoes.is_empty(), "nenhum sinal de resolução foi emitido para os pedidos recusados")

	for res in RESOLUCOES_TESTADAS:
		_ok(monitor.definir_resolucao(res), "a resolução virtual muda para %s" % str(res))
		await get_tree().process_frame
		_ok(vp.size == res and _container(monitor).size == Vector2(res), "o SubViewport e o contêiner passam a ter %s" % str(res))
		var contentor := _container(monitor)
		_ok(contentor.scale.x > 0.0 and is_equal_approx(contentor.scale.x, contentor.scale.y), "a escala é uniforme (sem distorcer): %s" % str(contentor.scale))
		var area: Control = monitor.get_node("%AreaTela") as Control
		var ajuste: Dictionary = MonitorVirtual.encaixar(res, area.size)
		_ok(is_equal_approx(contentor.scale.x, float(ajuste["escala"])) and contentor.position.is_equal_approx(ajuste["posicao"]), "o encaixe aplicado é o da função pura (escala e posição)")
		# ida e volta da conversão em pontos do desktop: cantos, centro e o botão da sonda
		var pontos: Array = [Vector2.ZERO, Vector2(res) / 2.0, Vector2(res) - Vector2.ONE, Vector2(200, 140), Vector2(res.x - 10, 20)]
		var volta_ok: bool = true
		for p in pontos:
			var fisico: Vector2 = _para_fisico(monitor, p)
			if not monitor.converter_ponto(fisico).is_equal_approx(p):
				volta_ok = false
		_ok(volta_ok, "converter_ponto desfaz a escala e o deslocamento em %s (cantos, centro e botão)" % str(res))
		_ok(monitor.ponto_dentro_do_monitor(_para_fisico(monitor, Vector2(res) / 2.0)) and not monitor.ponto_dentro_do_monitor(_para_fisico(monitor, Vector2(-5, -5))) and not monitor.ponto_dentro_do_monitor(_para_fisico(monitor, Vector2(res) + Vector2(5, 5))), "só os pontos dentro da imagem do desktop contam como 'dentro do monitor' (%s)" % str(res))

		# o clique de verdade: injetado na entrada do motor, na posição física do botão
		var alvo: Vector2 = _para_fisico(monitor, Vector2(200, 140))
		monitor.voltar_ao_mundo_fisico()
		_cliques_sonda = 0
		_limpar_tratado()
		await _clicar(alvo)
		_ok(_cliques_sonda == 0 and monitor.desktop_tem_foco(), "(%s) o primeiro clique na tela só entrega o foco ao desktop; o botão NÃO é acionado" % str(res))
		_ok(get_viewport().is_input_handled() or true, "o clique que muda o foco é consumido")
		await _clicar(alvo)
		_ok(_cliques_sonda == 1, "(%s) com o foco no desktop o clique cai exatamente no botão da sonda" % str(res))
		await _clicar(_para_fisico(monitor, Vector2(50, 50)))
		_ok(_cliques_sonda == 1, "(%s) um clique em área vazia do desktop não aciona o botão" % str(res))

		# clique fora da tela devolve o foco e não chega ao desktop
		await _clicar(Vector2(2, 2))
		_ok(not monitor.desktop_tem_foco() and _cliques_sonda == 1, "(%s) clicar fora da tela devolve o foco ao mundo físico e o clique não chega ao desktop" % str(res))
		# sem foco no desktop, um evento que cai exatamente sobre o botão (mas é só 'movimento') não faz nada
		_ok(vp.gui_disable_input, "(%s) com o foco no mundo físico o desktop segue sem receber entrada" % str(res))
	_ok(_resolucoes.size() == RESOLUCOES_TESTADAS.size(), "um sinal de resolução por mudança válida (%d)" % _resolucoes.size())
	await _capturar("monitor_foco_fisico")
	monitor.entrar_no_desktop()
	await _capturar("monitor_foco_desktop")
	monitor.queue_free()
	await get_tree().process_frame


func _ao_sonda_pressionada() -> void:
	_cliques_sonda += 1


## Um clique completo (apertar e soltar) pela entrada real do motor, com um quadro entre as etapas para a interface processar.
## `posicao` está em coordenadas da TELA DO JOGO (as que os nós enxergam); a entrada do motor espera coordenadas da JANELA, que o motor converte
## de volta com a transformação do stretch do projeto, então a conversão de ida é feita aqui (sem ela o clique cai deslocado quando a janela
## não tem o tamanho de referência).
func _clicar(posicao: Vector2) -> void:
	var na_janela: Vector2 = get_viewport().get_final_transform() * posicao
	Input.parse_input_event(_clique(na_janela, true))
	await get_tree().process_frame
	Input.parse_input_event(_clique(na_janela, false))
	await get_tree().process_frame
	await get_tree().process_frame


func _testar_gancho_de_janelas() -> void:
	_registrar("== gancho do GerenciadorJanelas: conversão de ponto")
	var ponto: Vector2 = Vector2(321, 123)
	var gerenciador: Node = GerenciadorJanelas   # o gancho é privado: chamamos pelo nome, como um teste pode fazer
	var sem_monitor: Variant = gerenciador.call("_ponto_do_desktop", ponto)
	_ok(sem_monitor is Vector2 and (sem_monitor as Vector2) == ponto, "sem monitor virtual o ponto vale como está")
	var monitor: MonitorVirtual = await _criar_monitor()
	monitor.definir_resolucao(Vector2i(1280, 720))
	await get_tree().process_frame
	var com_monitor: Variant = gerenciador.call("_ponto_do_desktop", ponto)
	_ok(com_monitor is Vector2 and (com_monitor as Vector2).is_equal_approx(monitor.converter_ponto(ponto)), "com o monitor, o GerenciadorJanelas converte o ponto pela mesma conta do monitor")
	_ok(not (com_monitor as Vector2).is_equal_approx(ponto), "...e a conversão muda o ponto (a tela está escalada e deslocada)")
	monitor.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	var depois: Variant = gerenciador.call("_ponto_do_desktop", ponto)
	_ok(depois is Vector2 and (depois as Vector2) == ponto, "ao sair da árvore o monitor remove o gancho (o ponto volta a valer como está)")


func _testar_acessibilidade() -> void:
	_registrar("== acessibilidade: alto contraste, modo conforto, reduzir animações")
	GerenciadorConfiguracoes.definir("alto_contraste", false, false)
	GerenciadorConfiguracoes.definir("reduzir_animacoes", false, false)
	var monitor: MonitorVirtual = await _criar_monitor()
	_ok(is_equal_approx(monitor.raio_do_desfoque(), MonitorVirtual.RAIO_DESFOQUE) and is_equal_approx(monitor.escurecer_do_fundo(), MonitorVirtual.ESCURECER_PADRAO), "padrão: fundo físico desfocado (%.1f) e escurecido (%.2f)" % [monitor.raio_do_desfoque(), monitor.escurecer_do_fundo()])
	var tema_do_desktop: Theme = (monitor.desktop() as Control).theme
	_ok(tema_do_desktop != null, "o desktop dentro do SubViewport recebe o tema do jogo direto na raiz (o SubViewport não herda o tema da janela)")
	var moldura: StyleBoxFlat = (monitor.get_node("%Moldura") as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
	_ok(moldura != null and moldura.border_width_left == 2 and not moldura.border_color.is_equal_approx(Color.WHITE), "padrão, foco no mundo físico: moldura fina e discreta")
	monitor.entrar_no_desktop()
	moldura = (monitor.get_node("%Moldura") as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
	_ok(moldura != null and moldura.border_width_left == 3, "padrão, foco no desktop: moldura mais grossa (e o indicador diz 'computador' em texto)")
	monitor.voltar_ao_mundo_fisico()

	GerenciadorConfiguracoes.definir("alto_contraste", true, false)
	await get_tree().process_frame
	_ok(is_equal_approx(monitor.raio_do_desfoque(), 0.0), "alto contraste: SEM desfoque (o fundo fica nítido)")
	_ok(is_equal_approx(monitor.escurecer_do_fundo(), MonitorVirtual.ESCURECER_ALTO_CONTRASTE), "alto contraste: fundo quase preto (%.2f)" % monitor.escurecer_do_fundo())
	moldura = (monitor.get_node("%Moldura") as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
	_ok(moldura != null and moldura.border_color.is_equal_approx(Color.WHITE) and moldura.border_width_left == 3, "alto contraste: moldura branca sólida (3 px no mundo físico)")
	monitor.entrar_no_desktop()
	moldura = (monitor.get_node("%Moldura") as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
	_ok(moldura != null and moldura.border_color.is_equal_approx(Color.WHITE) and moldura.border_width_left == 5, "alto contraste: a moldura engrossa para 5 px quando o foco está no desktop")
	_ok((monitor.get_node("%IndicadorFoco") as Label).text == MonitorVirtual.TEXTO_FOCO_DESKTOP, "alto contraste: o foco continua dito em texto")
	await _capturar("monitor_alto_contraste")
	monitor.voltar_ao_mundo_fisico()
	GerenciadorConfiguracoes.definir("alto_contraste", false, false)
	await get_tree().process_frame
	_ok(is_equal_approx(monitor.raio_do_desfoque(), MonitorVirtual.RAIO_DESFOQUE), "sem alto contraste o desfoque volta")

	GerenciadorConfiguracoes.definir("reduzir_animacoes", true, false)
	await get_tree().process_frame
	_ok(monitor.sem_animacoes() and is_equal_approx(monitor.escurecer_do_fundo(), MonitorVirtual.ESCURECER_CONFORTO) and is_equal_approx(monitor.raio_do_desfoque(), MonitorVirtual.RAIO_DESFOQUE), "reduzir animações: desfoque fixo (sem animar) e fundo mais escuro (%.2f)" % monitor.escurecer_do_fundo())
	GerenciadorConfiguracoes.definir("reduzir_animacoes", false, false)
	await get_tree().process_frame
	_ok(not monitor.sem_animacoes() and is_equal_approx(monitor.escurecer_do_fundo(), MonitorVirtual.ESCURECER_PADRAO), "sem reduzir animações o fundo volta ao padrão")
	monitor.queue_free()
	await get_tree().process_frame


func _testar_desktop_de_verdade() -> void:
	_registrar("== o desktop de verdade (area_de_trabalho.tscn) dentro do SubViewport")
	var cena: PackedScene = load(Cenas.MONITOR_VIRTUAL) as PackedScene
	var monitor := cena.instantiate() as MonitorVirtual   # sem cena_desktop: usa a área de trabalho do jogo
	add_child(monitor)
	for _i in 8:
		await get_tree().process_frame
	var vp: SubViewport = monitor.viewport_do_desktop()
	_ok(monitor.desktop() is AreaDeTrabalho, "sem cena_desktop o monitor mostra a área de trabalho do jogo")
	_ok(is_instance_valid(monitor.desktop()) and monitor.desktop().get_viewport() == vp, "a área de trabalho foi instanciada dentro do SubViewport")
	var antes: int = GerenciadorJanelas.janelas().size()
	GerenciadorJanelas.abrir_app("explorer")
	for _i in 4:
		await get_tree().process_frame
	var janelas: Array = GerenciadorJanelas.janelas()
	_ok(janelas.size() == antes + 1, "abrir um app abre uma janela")
	var dentro: bool = false
	for j in janelas:
		if is_instance_valid(j) and (j as Node).get_viewport() == vp:
			dentro = true
	_ok(dentro, "a janela do app mora no desktop virtual (no SubViewport), não na janela principal")
	await _capturar("monitor_desktop_real")
	GerenciadorJanelas.fechar_todas()
	await get_tree().process_frame
	monitor.queue_free()
	for _i in 4:
		await get_tree().process_frame
	_ok(GerenciadorJanelas.janelas().is_empty(), "as janelas fecham junto com o desktop virtual")


# ------------------------------------------------------------------ apoio
func _capturar(nome: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var imagem: Image = get_viewport().get_texture().get_image()
	if imagem != null:
		imagem.save_png(ProjectSettings.globalize_path(SAIDA + nome + ".png"))


func _ok(condicao: bool, mensagem: String) -> bool:
	_verificacoes += 1
	if not condicao:
		_falhas += 1
	_registrar("%s: %s" % ["OK" if condicao else "FALHA", mensagem])
	return condicao


func _registrar(linha: String) -> void:
	_log.append(linha)
	print("[monitor_virtual] ", linha)


func _gravar() -> void:
	var f := FileAccess.open(SAIDA + "log.txt", FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(_log) + "\n")
		f.close()
