class_name BotaoTarefaApp
extends Button
## Botão da barra de tarefas: ícone do app e, nas janelas abertas, o título. Item reutilizável (botao_tarefa.tscn):
## a barra instancia um por app fixado e um por janela aberta.

var _info: Dictionary = {}
var _texto: String = ""

@onready var _icone: IconeApp = %Icone
@onready var _rotulo: Label = %Rotulo


func _ready() -> void:
	if not UiKit.refs_ok(self, {"Icone": _icone, "Rotulo": _rotulo}):
		return
	_aplicar()


## info: item do catálogo de apps; texto: título (vazio = só o ícone); largura_minima: largura mínima do botão.
## Pode ser chamada antes ou depois de a cena entrar na árvore.
func configurar(info: Dictionary, texto: String = "", largura_minima: float = 44.0) -> void:
	_info = info
	_texto = texto
	custom_minimum_size = Vector2(largura_minima, custom_minimum_size.y)
	if is_node_ready():
		_aplicar()


## Destaca o botão da janela que está em primeiro plano.
func definir_destaque(ativo: bool) -> void:
	theme_type_variation = &"BotaoTarefaAtivo" if ativo else &"BotaoTarefa"


func _aplicar() -> void:
	_icone.configurar(_info)
	_rotulo.text = _texto
	_rotulo.visible = _texto != ""
