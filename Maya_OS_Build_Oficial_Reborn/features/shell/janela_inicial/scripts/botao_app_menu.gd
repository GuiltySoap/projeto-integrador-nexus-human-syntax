class_name BotaoAppMenu
extends Button
## Botão de um aplicativo na grade do Menu Iniciar. Item reutilizável (botao_app_menu.tscn): o menu instancia um por app.

var _info: Dictionary = {}
var _novo: bool = false

@onready var _icone: IconeApp = %Icone
@onready var _nome: Label = %Nome
@onready var _etiqueta: Label = %Etiqueta


func _ready() -> void:
	if not UiKit.refs_ok(self, {"Icone": _icone, "Nome": _nome, "Etiqueta": _etiqueta}):
		return
	_aplicar()


## info: item do catálogo de apps; novo: mostra a etiqueta "NOVO" (app liberado hoje).
## Pode ser chamada antes ou depois de a cena entrar na árvore.
func configurar(info: Dictionary, novo: bool = false) -> void:
	_info = info
	_novo = novo
	if is_node_ready():
		_aplicar()


func _aplicar() -> void:
	tooltip_text = "Abrir %s" % str(_info.get("nome", ""))
	_icone.configurar(_info)
	_nome.text = str(_info.get("nome", ""))
	_etiqueta.visible = _novo
