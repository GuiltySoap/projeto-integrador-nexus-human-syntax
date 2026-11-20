class_name PainelOpcoes
extends Control
## Painel de Opções do Menu Principal e da Pausa. NÃO é um sistema novo de configurações: cada linha é uma instância dos mesmos
## componentes das Configurações do HumaxOS (LinhaSlider, LinhaCheck, LinhaOpcao) e grava no mesmo GerenciadorConfiguracoes, que
## aplica na hora e salva em user://nexus_os/configuracoes.cfg. Nada aqui mexe na campanha (progresso, flags, salvamentos).
## O que existe no jogo: volumes, tela cheia, tamanho do texto, alto contraste, modo conforto e as reduções de efeito
## (animações, glitch, tremor, flashes, ruído) e a velocidade do processo malicioso. Não existem seleção de idioma,
## resolução nem qualidade visual, então esses controles não foram inventados.
##
## Fica oculto até `abrir()`. Esc e "Voltar" fecham (e o foco volta para o botão que abriu). A estrutura inteira vive em
## painel_opcoes.tscn; este script só liga as linhas às configurações e mantém os controles em sincronia.

signal fechado

## Configurações que precisam ter uma linha na cena (conferido em `_ready`; sinaliza no log se alguém apagar ou renomear).
const CHAVES_ESPERADAS: Array = [
	"volume_master", "volume_bgm", "volume_sfx", "tamanho_texto", "alto_contraste", "modo_conforto", "reduzir_animacoes",
	"reduzir_glitch", "reduzir_tremor", "sem_flashes", "reduzir_ruido", "dificuldade_processo",
]
## Chave própria deste painel: o modo conforto não é uma configuração única, liga as cinco reduções de uma vez.
const CHAVE_CONFORTO := "modo_conforto"

var _linhas: Dictionary = {}  ## chave da configuração -> LinhaOpcao | LinhaCheck | LinhaSlider
var _aberto: bool = false
var _foco_anterior: Control = null
var _cx := Conexoes.new()

@onready var _rolagem: ScrollContainer = %Rolagem
@onready var _lista: Control = %Linhas
@onready var _botao_tela_cheia: Button = %BotaoTelaCheia
@onready var _botao_voltar: Button = %BotaoVoltar


func _ready() -> void:
	visible = false
	if not UiKit.refs_ok(self, {"Rolagem": _rolagem, "Linhas": _lista, "BotaoTelaCheia": _botao_tela_cheia, "BotaoVoltar": _botao_voltar}):
		return
	_registrar_linhas()
	for chave in CHAVES_ESPERADAS:
		if not _linhas.has(chave):
			push_error("PainelOpcoes: falta a linha da configuração '%s' na cena." % chave)
	_cx.ligar(GerenciadorConfiguracoes.configuracao_alterada, _ao_configuracao_alterada)
	_sincronizar()


func _exit_tree() -> void:
	_cx.desligar_tudo()


func esta_aberto() -> bool:
	return _aberto


## Mostra o painel, com todos os controles refletindo as configurações atuais, e leva o foco para a primeira opção.
func abrir() -> void:
	if _aberto or _lista == null:
		return
	_foco_anterior = get_viewport().gui_get_focus_owner()
	_sincronizar()
	_aberto = true
	visible = true
	_rolagem.scroll_vertical = 0
	var primeira: Control = _primeiro_foco()
	if primeira != null:
		primeira.call_deferred("grab_focus")


## Fecha o painel (garantindo que as preferências ficaram salvas) e devolve o foco a quem abriu.
func fechar() -> void:
	if not _aberto:
		return
	_aberto = false
	visible = false
	GerenciadorConfiguracoes.salvar()
	if _foco_anterior != null and is_instance_valid(_foco_anterior) and _foco_anterior.is_visible_in_tree() and _foco_anterior.focus_mode != Control.FOCUS_NONE:
		_foco_anterior.grab_focus()
	_foco_anterior = null
	fechado.emit()


func _input(evento: InputEvent) -> void:
	if _aberto and evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		fechar()


# ------------------------------------------------------------------ ligação das linhas
func _registrar_linhas() -> void:
	for no in _lista.find_children("*", "", true, false):
		if no is LinhaSlider:
			var slider: LinhaSlider = no
			_linhas[slider.chave] = slider
			slider.valor_alterado.connect(_ao_slider)
			slider.valor_confirmado.connect(_ao_slider_solto)
		elif no is LinhaCheck:
			var caixa: LinhaCheck = no
			_linhas[caixa.chave] = caixa
			caixa.alternada.connect(_ao_alternar)
		elif no is LinhaOpcao:
			var opcao: LinhaOpcao = no
			_linhas[opcao.chave] = opcao
			opcao.valor_escolhido.connect(_ao_opcao)


## Põe cada controle na posição da configuração atual, sem emitir sinal (não grava nada).
func _sincronizar() -> void:
	for chave in _linhas:
		var linha: Control = _linhas[chave]
		var valor: Variant = GerenciadorConfiguracoes.modo_conforto_ativo() if str(chave) == CHAVE_CONFORTO else GerenciadorConfiguracoes.obter(str(chave))
		if linha is LinhaCheck:
			(linha as LinhaCheck).definir_ativa(bool(valor))
		elif linha is LinhaSlider:
			(linha as LinhaSlider).definir_valor(float(valor))
		elif linha is LinhaOpcao:
			(linha as LinhaOpcao).definir_valor(valor)
	_botao_tela_cheia.text = "Tela cheia: %s  (F11 alterna)" % ("ligada" if _em_tela_cheia() else "desligada")


func _em_tela_cheia() -> bool:
	var modo: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	return modo == DisplayServer.WINDOW_MODE_FULLSCREEN or modo == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


## O primeiro controle que pode receber foco (o controle deslizante do volume geral).
func _primeiro_foco() -> Control:
	var linha: Control = _linhas.get("volume_master")
	if linha != null:
		var deslizante: Control = linha.find_child("Slider", true, false) as Control
		if deslizante != null:
			return deslizante
	return _botao_voltar


# ------------------------------------------------------------------ eventos (ligados na cena e por _registrar_linhas)
func _ao_opcao(chave: String, valor: Variant) -> void:
	GerenciadorConfiguracoes.definir(chave, valor)
	SistemaAudio.tocar_sfx("clique", -8.0)


func _ao_alternar(chave: String, ativa: bool) -> void:
	if chave == CHAVE_CONFORTO:
		if ativa:
			GerenciadorConfiguracoes.ativar_modo_conforto()
		else:
			GerenciadorConfiguracoes.desativar_modo_conforto()
	else:
		GerenciadorConfiguracoes.definir(chave, ativa)


func _ao_slider(chave: String, valor: float) -> void:
	GerenciadorConfiguracoes.definir(chave, valor, false)


func _ao_slider_solto(_chave: String) -> void:
	GerenciadorConfiguracoes.salvar()
	SistemaAudio.tocar_sfx("clique", -6.0)


func _ao_tela_cheia() -> void:
	GerenciadorConfiguracoes.alternar_tela_cheia()
	# A janela só muda de modo no quadro seguinte: o texto é atualizado depois disso.
	await get_tree().process_frame
	await get_tree().process_frame
	if is_inside_tree():
		_sincronizar()


func _ao_voltar() -> void:
	fechar()


func _ao_configuracao_alterada(_chave: String, _valor: Variant) -> void:
	_sincronizar()
