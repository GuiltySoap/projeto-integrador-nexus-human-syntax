extends Control

signal puzzle_solved
signal cancelled

@onready var switch_a: Button = %BtnA
@onready var switch_b: Button = %BtnB
@onready var status_led: ColorRect = %StatusLed
@onready var status_label: Label = %StatusLabel
@onready var btn_cancelar: Button = %BtnCancelar
@onready var btn_testar: Button = %BtnTestar
@onready var slot_1: PanelContainer = %Slot1

var estado_a: bool = false
var estado_b: bool = false
var porta_no_slot: String = ""

func _ready() -> void:
	hide() # Mantém escondido por padrão ao iniciar o OS
	btn_cancelar.pressed.connect(_on_btn_cancelar_pressed)
	btn_testar.pressed.connect(_on_btn_testar_pressed)
	switch_a.pressed.connect(_on_switch_a_pressed)
	switch_b.pressed.connect(_on_switch_b_pressed)
	
	if slot_1 and slot_1.has_signal("porta_alterada"):
		slot_1.porta_alterada.connect(_on_porta_slot_alterada)
		
	_atualizar_ui()

func open_modal() -> void:
	estado_a = false
	estado_b = false
	porta_no_slot = ""
	
	if slot_1 and slot_1.has_node("Label"):
		slot_1.get_node("Label").text = "[ Vazio ]"
		
	status_led.color = Color.RED
	status_label.text = "BLOQUEADO"
	_atualizar_ui()
	show()

func _on_porta_slot_alterada(_slot_id: String, tipo_porta: String) -> void:
	porta_no_slot = tipo_porta

func _on_switch_a_pressed() -> void:
	estado_a = !estado_a
	_atualizar_ui()

func _on_switch_b_pressed() -> void:
	estado_b = !estado_b
	_atualizar_ui()

func _atualizar_ui() -> void:
	switch_a.text = "Entrada A: " + ("1" if estado_a else "0")
	switch_b.text = "Entrada B: " + ("1" if estado_b else "0")

func _on_btn_testar_pressed() -> void:
	if porta_no_slot == "":
		status_label.text = "ENCAIXE UMA PORTA"
		return
		
	var resultado: bool = false
	
	match porta_no_slot:
		"AND":
			resultado = estado_a and estado_b
		"OR":
			resultado = estado_a or estado_b
		"XOR":
			resultado = estado_a != estado_b
			
	if resultado:
		status_led.color = Color.GREEN
		status_label.text = "DESBLOQUEADO"
		emit_signal("puzzle_solved")
		await get_tree().create_timer(0.8).timeout
		hide()
	else:
		status_led.color = Color.RED
		status_label.text = "ACESSO NEGADO"

func _on_btn_cancelar_pressed() -> void:
	emit_signal("cancelled")
	hide()
