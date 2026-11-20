class_name PainelCreditos
extends Control
## Painel de Créditos do Menu Principal. Só mostra o que está confirmado no projeto: nome do jogo, tecnologias, origem das
## imagens e dos áudios e a licença do motor. As seções Equipe, Funções e Agradecimentos existem na cena, mas ficam OCULTAS
## enquanto o texto delas estiver vazio: para preencher, abra painel_creditos.tscn, escreva o texto do `RotuloCorpo` da seção
## e ela aparece sozinha. Nenhum nome, empresa ou licença foi inventado.
##
## Fecha com o botão "Voltar" ou com Esc; o foco volta ao botão que abriu. Rola com o mouse, com as setas, PageUp/PageDown,
## Home e End (o painel só tem o botão Voltar, então as setas são livres para rolar). Segue o tema, o alto contraste e o modo
## conforto, pois é só texto: sem animação nenhuma.

signal fechado

const PASSO_ROLAGEM := 72

var _aberto: bool = false
var _foco_anterior: Control = null

@onready var _rolagem: ScrollContainer = %Rolagem
@onready var _conteudo: Control = %Conteudo
@onready var _botao_voltar: Button = %BotaoVoltar
@onready var _texto_versao: Label = %TextoVersao
@onready var _texto_licenca_motor: Label = %TextoLicencaMotor


func _ready() -> void:
	visible = false
	if not UiKit.refs_ok(self, {"Rolagem": _rolagem, "Conteudo": _conteudo, "BotaoVoltar": _botao_voltar, "TextoVersao": _texto_versao, "TextoLicencaMotor": _texto_licenca_motor}):
		return
	# Seção sem texto no RotuloCorpo = seção escondida.
	for secao in _conteudo.get_children():
		var corpo: Label = secao.find_child("RotuloCorpo", false, false) as Label
		if corpo != null:
			(secao as Control).visible = corpo.text.strip_edges() != ""
	var motor: Dictionary = Engine.get_version_info()
	_texto_versao.text = "HumaxOS 1.0 — simulação\nMotor: Godot %s" % str(motor.get("string", "4.x"))
	_texto_licenca_motor.text = Engine.get_license_text().strip_edges()


func esta_aberto() -> bool:
	return _aberto


func abrir() -> void:
	if _aberto or _rolagem == null:
		return
	_foco_anterior = get_viewport().gui_get_focus_owner()
	_aberto = true
	visible = true
	_rolagem.scroll_vertical = 0
	_botao_voltar.call_deferred("grab_focus")


func fechar() -> void:
	if not _aberto:
		return
	_aberto = false
	visible = false
	if _foco_anterior != null and is_instance_valid(_foco_anterior) and _foco_anterior.is_visible_in_tree() and _foco_anterior.focus_mode != Control.FOCUS_NONE:
		_foco_anterior.grab_focus()
	_foco_anterior = null
	fechado.emit()


func _input(evento: InputEvent) -> void:
	if not _aberto:
		return
	if evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		fechar()
	elif evento.is_action_pressed("ui_down", true):
		get_viewport().set_input_as_handled()
		_rolar(PASSO_ROLAGEM)
	elif evento.is_action_pressed("ui_up", true):
		get_viewport().set_input_as_handled()
		_rolar(-PASSO_ROLAGEM)
	elif evento.is_action_pressed("ui_page_down", true):
		get_viewport().set_input_as_handled()
		_rolar(int(_rolagem.size.y * 0.9))
	elif evento.is_action_pressed("ui_page_up", true):
		get_viewport().set_input_as_handled()
		_rolar(-int(_rolagem.size.y * 0.9))
	elif evento.is_action_pressed("ui_home"):
		get_viewport().set_input_as_handled()
		_rolagem.scroll_vertical = 0
	elif evento.is_action_pressed("ui_end"):
		get_viewport().set_input_as_handled()
		_rolagem.scroll_vertical = int(_conteudo.size.y)


func _rolar(pixels: int) -> void:
	_rolagem.scroll_vertical = maxi(0, _rolagem.scroll_vertical + pixels)


func _ao_voltar() -> void:
	fechar()
