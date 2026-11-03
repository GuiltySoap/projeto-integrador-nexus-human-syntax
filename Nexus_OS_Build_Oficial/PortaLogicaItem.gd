extends PanelContainer

@export var tipo_porta: String = "AND"
@onready var label_porta: Label = $Label

func _ready() -> void:
	if label_porta:
		label_porta.text = tipo_porta

func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview = PanelContainer.new()
	var preview_label = Label.new()
	preview_label.text = tipo_porta
	preview.add_child(preview_label)
	
	set_drag_preview(preview)

	return {
		"type": "gate_item",
		"gate_type": tipo_porta
	}
