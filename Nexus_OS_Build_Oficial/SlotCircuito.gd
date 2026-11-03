extends PanelContainer

signal porta_alterada(slot_id: String, tipo_porta: String)

@export var slot_id: String = "slot_1"
@onready var label_slot: Label = $Label

var porta_instalada: String = ""

# Valida se o objeto arrastado pode ser solto neste nó
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("type") == "gate_item"

# Executado quando o jogador solta o objeto sobre o slot
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	porta_instalada = data.get("gate_type", "")
	
	if label_slot:
		label_slot.text = "[" + porta_instalada + "]"
		
	emit_signal("porta_alterada", slot_id, porta_instalada)
