extends Control

signal modal_closed

@onready var imagem_expandida: TextureRect = $ContainerMidia/ImagemExpandida
@onready var botao_fechar: Button = $BtnFechar

func _ready() -> void:
	hide()
	botao_fechar.pressed.connect(_ao_fechar_clicado)

func exibir_midia(caminho_midia: String) -> void:
	if ResourceLoader.exists(caminho_midia):
		imagem_expandida.texture = load(caminho_midia)
		show()
	else:
		push_error("MediaViewerModal: Caminho de mídia não encontrado -> " + caminho_midia)

func _ao_fechar_clicado() -> void:
	hide()
	modal_closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"): # Permite fechar com a tecla ESC
		_ao_fechar_clicado()
		get_viewport().set_input_as_handled()
