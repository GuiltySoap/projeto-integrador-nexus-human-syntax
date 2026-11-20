class_name IconeAreaDeTrabalho
extends Button
## Atalho de aplicativo na área de trabalho. Mouse: duplo clique. Teclado: Enter/Espaço com o ícone focado.
## A estrutura (ícone + legenda) está em icone_area_de_trabalho.tscn; aqui entram só os dados do app e a entrada.

signal abrir_pedido(app_id: String)

var app_id: String = ""
var _info: Dictionary = {}
var _veio_do_mouse: bool = false

@onready var _icone: IconeApp = %Icone
@onready var _rotulo: Label = %Rotulo


func _ready() -> void:
	if not UiKit.refs_ok(self, {"Icone": _icone, "Rotulo": _rotulo}):
		return
	_aplicar()


## Pode ser chamada antes ou depois de a cena entrar na árvore.
func configurar(info: Dictionary) -> void:
	_info = info
	app_id = str(info.get("id", ""))
	if is_node_ready():
		_aplicar()


func _aplicar() -> void:
	if _info.is_empty():
		return
	var nome: String = str(_info.get("nome", app_id))
	tooltip_text = "%s (duplo clique ou Enter para abrir)" % nome
	_icone.configurar(_info)
	_rotulo.text = nome


# Conectado na cena: gui_input
func _ao_entrada(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT and evento.pressed:
		_veio_do_mouse = true
		if evento.double_click:
			abrir_pedido.emit(app_id)


# Conectado na cena: pressed
func _ao_pressionado() -> void:
	if _veio_do_mouse:
		_veio_do_mouse = false
		return
	abrir_pedido.emit(app_id)
