@tool
class_name LinhaOpcao
extends HBoxContainer
## Linha das Configurações: título à esquerda e lista suspensa (OptionButton) à direita.
## No Inspector: `chave` (nome da configuração), `titulo`, `rotulos` (texto de cada opção) e `valores` (o que cada opção
## grava, na mesma ordem dos rótulos: texto ou número). O app só ouve `valor_escolhido` e grava a configuração.

## O jogador escolheu uma opção da lista.
signal valor_escolhido(chave: String, valor: Variant)

@export var chave: String = ""
@export var titulo: String = "Título":
	set(valor):
		titulo = valor
		_aplicar()
@export var rotulos: PackedStringArray = PackedStringArray():
	set(valor):
		rotulos = valor
		_aplicar()
@export var valores: Array = []

@onready var _rotulo: Label = %RotuloTitulo
@onready var _seletor: OptionButton = %Seletor


func _ready() -> void:
	_aplicar()


## Seleciona a opção que representa `valor`, sem emitir sinal. Para números escolhe a mais próxima.
func definir_valor(valor: Variant) -> void:
	if _seletor == null or _seletor.item_count == 0:
		return
	_seletor.select(_indice_do_valor(valor))


func _aplicar() -> void:
	if not is_node_ready() or _rotulo == null or _seletor == null:
		return
	_rotulo.text = titulo
	var anterior: int = _seletor.selected
	_seletor.clear()
	for rotulo in rotulos:
		_seletor.add_item(rotulo)
	if _seletor.item_count > 0:
		_seletor.select(clampi(anterior, 0, _seletor.item_count - 1))


func _indice_do_valor(valor: Variant) -> int:
	var melhor: int = 0
	var menor_dif: float = INF
	for i in valores.size():
		var v: Variant = valores[i]
		if typeof(v) == TYPE_STRING:
			if str(v) == str(valor):
				return i
		else:
			var dif: float = absf(float(v) - float(valor))
			if dif < menor_dif:
				menor_dif = dif
				melhor = i
	return melhor


func _ao_item_selecionado(indice: int) -> void:
	if indice < 0 or indice >= valores.size():
		return
	valor_escolhido.emit(chave, valores[indice])
