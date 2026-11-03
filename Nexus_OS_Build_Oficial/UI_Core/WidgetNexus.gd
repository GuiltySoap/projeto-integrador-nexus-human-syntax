extends Control

@onready var animacao: AnimationPlayer = $AnimationPlayer
@onready var orbe_visual: Panel = $OrbeVisual

func _ready() -> void:
	# O orbe começa a "respirar" assim que o jogo abre
	animacao.play("pulso_calmo")
	
	# Verifica em que fase estamos para mudar a cor
	atualizar_personalidade()

func atualizar_personalidade() -> void:
	var fase = GerenciadorEstado.dados.get("fase_os", 1)
	
	if fase >= 3:
		# Muda a cor para Azul Frio/Cinza (Dia 3)
		var estilo = orbe_visual.get_theme_stylebox("panel") as StyleBoxFlat
		estilo.bg_color = Color("3b6b7a") # Um tom de azul petróleo
		
		# A animação fica mais acelerada e tensa
		animacao.speed_scale = 1.5
