@tool
class_name LinhaCheck
extends VBoxContainer
## Opção liga/desliga das Configurações: caixa de seleção com título e uma descrição recuada logo abaixo.
## No Inspector: `chave` (nome da configuração ou da permissão), `titulo` e `descricao`.

## O jogador marcou ou desmarcou a caixa.
signal alternada(chave: String, ativa: bool)

@export var chave: String = ""
@export var titulo: String = "Título":
	set(valor):
		titulo = valor
		_aplicar()
@export_multiline var descricao: String = "":
	set(valor):
		descricao = valor
		_aplicar()

@onready var _caixa: CheckBox = %Caixa
@onready var _recuo: MarginContainer = %RecuoDescricao
@onready var _rotulo_descricao: Label = %RotuloDescricao


func _ready() -> void:
	_aplicar()


## Marca ou desmarca a caixa sem emitir sinal (para sincronizar com o estado do jogo).
func definir_ativa(ativa: bool) -> void:
	if _caixa != null:
		_caixa.set_pressed_no_signal(ativa)


func esta_ativa() -> bool:
	return _caixa != null and _caixa.button_pressed


func _aplicar() -> void:
	if not is_node_ready() or _caixa == null or _recuo == null or _rotulo_descricao == null:
		return
	_caixa.text = titulo
	_rotulo_descricao.text = descricao
	_recuo.visible = descricao != ""


func _ao_alternar(ativa: bool) -> void:
	alternada.emit(chave, ativa)
