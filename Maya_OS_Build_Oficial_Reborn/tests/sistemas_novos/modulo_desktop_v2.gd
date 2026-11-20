extends ModuloDeTeste
## Módulo 5 (roteiro v2.0): integração com a área de trabalho de verdade (area_de_trabalho.tscn). O roteiro roda pelo MESMO motor do jogo e a
## área de trabalho viva abre as janelas que ele pede: painel da Maya (T1), cartões de permissão (T2), montagem da rotina (T3.5), minigame (T4.4).
## Salvamento e preferências ficam isolados; nada é gravado no user://nexus_os do jogador.

const CENA_DESKTOP := "res://features/shell/area_de_trabalho/scenes/area_de_trabalho.tscn"

var _desktop: Node = null


func executar(banca_do_executor: BancaDeTestes) -> void:
	banca = banca_do_executor
	_isolar_configuracoes()
	await _testar_janelas_pedidas_pelo_roteiro()
	_restaurar_configuracoes()
	await get_tree().process_frame


func _abrir_desktop() -> void:
	GerenciadorJanelas.fechar_todas()
	_novo_jogo("Dani")
	_desktop = (load(CENA_DESKTOP) as PackedScene).instantiate()
	add_child(_desktop)
	await _quadros(8)
	GerenciadorNarrativa.pausado = true   # a barra de envio e as esperas não correm sozinhas durante o teste


func _fechar_desktop() -> void:
	GerenciadorJanelas.fechar_todas()
	if is_instance_valid(_desktop):
		_desktop.queue_free()
	await _quadros(4)
	_desktop = null


func _abertas(app_id: String) -> int:
	return GerenciadorJanelas.janelas_do_app(app_id).size()


func _testar_janelas_pedidas_pelo_roteiro() -> void:
	_secao("Área de trabalho de verdade: o roteiro pede, a janela abre")
	await _abrir_desktop()
	_ok(_desktop is AreaDeTrabalho, "a cena da área de trabalho instancia como AreaDeTrabalho")
	_igual(_no(), "T1.4", "o roteiro começou e parou na primeira escolha (T1.4)")
	_igual(_abertas("maya"), 1, "T1: o painel da Maya abre sozinho (janela pendente consumida)")
	_ok(GerenciadorNarrativa.janelas_pendentes.is_empty(), "a fila de janelas pendentes foi esvaziada")
	var maya := GerenciadorJanelas.janelas_do_app("maya")
	if not maya.is_empty():
		var app := (maya[0] as JanelaBase).conteudo as AppBase
		_ok(app != null and app.app_id == "maya", "a janela da Maya traz o app da Maya")

	# T1.4 → Task 2: o primeiro cartão pede a janela de privacidade
	var p := await _jogar_ate({"T1.4": "pode_organizar"}, "T2.2")
	_igual(_no(), "T2.2", "[Pode organizar] leva ao primeiro cartão de permissão (T2.2)")
	await _quadros(3)
	_igual(_abertas("privacidade_maya"), 1, "T2: a janela de cartões de permissão abre (uma só)")
	_ok(not p.passos.is_empty(), "o piloto registrou os nós percorridos")

	# decide os três cartões; o painel da Maya segue aberto, a janela de cartões deve poder ser fechada pelo roteiro (fechar: privacidade_maya)
	p = await _jogar_ate({"T1.4": "pode_organizar", "T3.3": "valeu", "T3.4": "eu_mesmo_faco"}, "T3.5")
	_igual(_no(), "T3.5", "decididos os cartões, a Task 3 segue até a montagem manual da rotina (T3.5)")
	await _quadros(4)
	_igual(_abertas("privacidade_maya"), 0, "ao fim dos cartões a janela de privacidade fecha")
	_igual(_abertas("rotina"), 1, "T3.5: a janela da rotina abre")

	# T4.4: o exercício de lógica abre como janela do minigame
	p = await _jogar_ate({"T1.4": "pode_organizar", "T3.3": "valeu", "T3.4": "eu_mesmo_faco", "T4.3": "eu_faco_sozinho"}, "T4.4", true)
	await _quadros(4)
	_igual(_no(), "T4.4", "[Eu faço sozinho] leva ao minigame (T4.4)")
	_igual(_abertas("minigame_logica"), 1, "T4.4: a janela do minigame de lógica abre")
	await _fechar_desktop()
	_ok(GerenciadorJanelas.janelas().is_empty(), "fechar o desktop fecha todas as janelas")


## Joga (do nó atual) até parar em `alvo`, com um plano; devolve o piloto. `rotina` conclui a montagem da rotina quando pedida.
func _jogar_ate(escolhas: Dictionary, alvo: String, rotina: bool = false) -> PilotoRoteiro:
	var p := PilotoRoteiro.jogar({"escolhas": escolhas, "parar_em": alvo, "rotina": rotina})
	await _quadros(2)
	return p
