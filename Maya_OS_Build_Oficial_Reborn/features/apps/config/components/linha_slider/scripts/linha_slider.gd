@tool
class_name LinhaSlider
extends VBoxContainer
## Controle deslizante (0 a 100%) das Configurações, com título e o valor em porcentagem ao lado.
## No Inspector: `chave` (nome da configuração) e `titulo`.

## O valor mudou (a cada passo do arraste).
signal valor_alterado(chave: String, valor: float)
## O jogador soltou o controle (hora de salvar).
signal valor_confirmado(chave: String)

@export var chave: String = ""
@export var titulo: String = "Título":
	set(valor):
		titulo = valor
		_aplicar()

@onready var _rotulo_titulo: Label = %RotuloTitulo
@onready var _rotulo_valor: Label = %RotuloValor
@onready var _slider: HSlider = %Slider


func _ready() -> void:
	_aplicar()
	_atualizar_rotulo(_slider.value if _slider != null else 0.0)


## Posiciona o controle sem emitir sinal (para sincronizar com a configuração salva).
func definir_valor(valor: float) -> void:
	if _slider == null:
		return
	_slider.set_value_no_signal(valor)
	_atualizar_rotulo(valor)


func _aplicar() -> void:
	if not is_node_ready() or _rotulo_titulo == null:
		return
	_rotulo_titulo.text = titulo


func _atualizar_rotulo(valor: float) -> void:
	if _rotulo_valor != null:
		_rotulo_valor.text = "%d%%" % int(round(valor * 100.0))


func _ao_valor_alterado(valor: float) -> void:
	_atualizar_rotulo(valor)
	valor_alterado.emit(chave, valor)


func _ao_arraste_terminado(_alterado: bool) -> void:
	valor_confirmado.emit(chave)
