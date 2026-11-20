@tool
class_name CabecalhoPagina
extends VBoxContainer
## Cabeçalho de uma página das Configurações: título grande, subtítulo explicativo e uma linha separadora.
## Edite `titulo` e `subtitulo` no Inspector; o texto aparece também no editor (@tool).

@export var titulo: String = "Título da página":
	set(valor):
		titulo = valor
		_aplicar()
@export_multiline var subtitulo: String = "":
	set(valor):
		subtitulo = valor
		_aplicar()

@onready var _rotulo_titulo: Label = %RotuloTitulo
@onready var _rotulo_subtitulo: Label = %RotuloSubtitulo


func _ready() -> void:
	_aplicar()


func _aplicar() -> void:
	if not is_node_ready() or _rotulo_titulo == null or _rotulo_subtitulo == null:
		return
	_rotulo_titulo.text = titulo
	_rotulo_subtitulo.text = subtitulo
	_rotulo_subtitulo.visible = subtitulo != ""
