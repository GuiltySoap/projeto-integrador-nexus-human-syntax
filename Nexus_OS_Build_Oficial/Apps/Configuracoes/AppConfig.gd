extends "res://JanelaBase.gd" # Mantém a habilidade de arrastar e fechar!

# Atualizamos o caminho, pois agora eles são filhos diretos da AreaConteudo!
@onready var btn_permitir: Button = $AreaConteudo/BtnPermitir
@onready var btn_negar: Button = $AreaConteudo/BtnNegar

func _ready() -> void:
	# Conecta os sinais dos botões
	btn_permitir.pressed.connect(_on_permitir_pressed)
	btn_negar.mouse_entered.connect(_on_negar_mouse_entered)
	btn_negar.pressed.connect(_on_negar_pressed)

# O Dark Pattern: O botão "Negar" foge quando o cursor se aproxima!
func _on_negar_mouse_entered() -> void:
	# Gera uma posição aleatória curta dentro da janela
	var deslocamento_x = randf_range(-80, 80)
	var deslocamento_y = randf_range(-40, 40)
	
	var tween = create_tween()
	tween.tween_property(btn_negar, "position", btn_negar.position + Vector2(deslocamento_x, deslocamento_y), 0.1)

# Se o jogador milagrosamente conseguir clicar em Negar
func _on_negar_pressed() -> void:
	# Pisca a janela de vermelho para mostrar a coerção do sistema
	modulate = Color(0.9, 0.1, 0.1)
	btn_negar.text = "PERMITIR?" # A NEXUS reescreve a opção
	
	await get_tree().create_timer(0.3).timeout
	modulate = Color(1, 1, 1)
	
	_on_permitir_pressed()

# Clique no botão verde de Aceitar
func _on_permitir_pressed() -> void:
	print("NEXUS: Obrigado por colaborar. Permissões concedidas!")
	
	# Atualiza o estado simulado no Mock JSON
	GerenciadorEstado.dados["fase_os"] = 2
	
	queue_free() # Fecha a janela após aceitar
