extends Panel

var arrastando: bool = false
var posicao_mouse_inicial: Vector2

func _gui_input(event: InputEvent) -> void:
	# Se o jogador clicar em qualquer parte da janela (fundo, barra superior)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		trazer_para_frente()
	
func trazer_para_frente() -> void:
	# move_to_front() empurra este nó para o final da lista de filhos do parent
	var pai = get_parent()
	if pai:
		pai.move_child(self, -1)
# Função que será ativada quando o mouse interagir com a Barra Superior
func _on_barra_superior_gui_input(event: InputEvent) -> void:
	# 1. Detecta se o jogador apertou ou soltou o clique esquerdo
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			arrastando = true
			posicao_mouse_inicial = event.position
		else:
			arrastando = false
			
	# 2. Se estiver segurando o clique e movendo o mouse, arrasta a janela
	if event is InputEventMouseMotion and arrastando:
		position += event.position - posicao_mouse_inicial

# Função que será ativada quando clicar no "X"
func _on_btn_fechar_pressed() -> void:
	if GerenciadorEstado.dados.has("nexus_bloqueia_fechamento") and GerenciadorEstado.dados["nexus_bloqueia_fechamento"] == true:
		
		# A Tensão Física: A janela treme para os lados
		var pos_original = position
		var tween = create_tween()
		
		# Joga 10 pixels pra direita, depois 10 pra esquerda, depois volta pro centro
		tween.tween_property(self, "position", pos_original + Vector2(10, 0), 0.05)
		tween.tween_property(self, "position", pos_original - Vector2(10, 0), 0.05)
		tween.tween_property(self, "position", pos_original, 0.05)
		
	else:
		queue_free()
