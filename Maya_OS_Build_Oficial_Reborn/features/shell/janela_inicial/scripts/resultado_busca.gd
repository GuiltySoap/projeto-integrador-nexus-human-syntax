class_name ResultadoBusca
extends Button
## Um resultado da busca do Menu Iniciar (aplicativo ou arquivo). Item reutilizável (resultado_busca.tscn).

var _info: Dictionary = {}
var _emoji: String = ""
var _texto_titulo: String = ""
var _texto_detalhe: String = ""

@onready var _icone: IconeApp = %Icone
@onready var _rot_emoji: Label = %Emoji
@onready var _titulo: Label = %Titulo
@onready var _detalhe: Label = %Detalhe


func _ready() -> void:
	if not UiKit.refs_ok(self, {"Icone": _icone, "Emoji": _rot_emoji, "Titulo": _titulo, "Detalhe": _detalhe}):
		return
	_aplicar()


## Resultado do tipo aplicativo: mostra o ícone do app.
func configurar_app(info: Dictionary, titulo: String, detalhe: String) -> void:
	_info = info
	_emoji = ""
	_definir_textos(titulo, detalhe)


## Resultado do tipo arquivo: mostra o emoji do tipo de arquivo.
func configurar_arquivo(emoji: String, titulo: String, detalhe: String) -> void:
	_info = {}
	_emoji = emoji
	_definir_textos(titulo, detalhe)


func _definir_textos(titulo: String, detalhe: String) -> void:
	_texto_titulo = titulo
	_texto_detalhe = detalhe
	if is_node_ready():
		_aplicar()


func _aplicar() -> void:
	var e_app: bool = not _info.is_empty()
	_icone.visible = e_app
	_rot_emoji.visible = not e_app
	if e_app:
		_icone.configurar(_info)
	else:
		_rot_emoji.text = _emoji
	_titulo.text = _texto_titulo
	_detalhe.text = _texto_detalhe
