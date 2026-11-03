extends Node

var dados: Dictionary = {}

func _ready() -> void:
	carregar_json()

func carregar_json() -> void:
	# Abre o arquivo no modo leitura
	var arquivo = FileAccess.open("user://estado_jogo.json", FileAccess.READ)
	
	if arquivo:
		var texto = arquivo.get_as_text()
		var json = JSON.new()
		var erro = json.parse(texto) # Traduz o texto para dados do Godot
		
		if erro == OK:
			dados = json.data
			print("JSON carregado com sucesso! Fase atual: ", dados["fase_os"])
		else:
			print("Erro ao ler o JSON.")
