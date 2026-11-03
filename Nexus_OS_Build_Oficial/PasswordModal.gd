extends Control

signal password_submitted(entered_password: String)
signal cancelled

@onready var password_input: LineEdit = $ColorRect/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LineEditPassword
@onready var error_label: Label = $ColorRect/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ErrorLabel

func _ready() -> void:
	error_label.visible = false
	password_input.secret = true

func open_modal() -> void:
	password_input.clear()
	error_label.visible = false
	show()
	password_input.grab_focus()

func show_error(message: String = "Acesso Negado") -> void:
	error_label.text = message
	error_label.visible = true
	password_input.clear()
	password_input.grab_focus()

func _on_confirm_button_pressed() -> void:
	_submit_password()

func _on_line_edit_password_text_submitted(_new_text: String) -> void:
	_submit_password()

func _on_cancel_button_pressed() -> void:
	emit_signal("cancelled")
	hide()

func _submit_password() -> void:
	var password = password_input.text.strip_edges()
	if password != "":
		emit_signal("password_submitted", password)


func _on_btn_cancelar_pressed() -> void:
	emit_signal("cancelled")
	hide()


func _on_btn_confirmar_pressed() -> void:
	_submit_password()
