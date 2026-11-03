extends PanelContainer # ou Control, dependendo do nó raiz

@onready var lbl_titulo: Label = $VBoxContainer/Titulo
@onready var lbl_mensagem: Label = $VBoxContainer/Mensagem
@onready var btn_ok: Button = $VBoxContainer/BtnOk

func _ready() -> void:
	# Eleva o pop-up para a camada 100, garantindo que ele cubra QUALQUER coisa na tela
	z_index = 100
	# A única função do _ready agora é conectar o botão
	btn_ok.pressed.connect(queue_free)

func configurar_mensagem(titulo: String, texto: String) -> void:
	lbl_titulo.text = titulo
	lbl_mensagem.text = texto
	
	# Truque de Mestre: Esperamos 1 frame para o Godot recalcular
	# a altura do balão após o texto gigante quebrar a linha.
	await get_tree().process_frame
	
	# Pegamos o tamanho da tela e o tamanho REAL do balão atualizado
	var tamanho_tela = get_viewport_rect().size
	var altura_balao = size.y
	var largura_balao = size.x
	
	var margem_direita = 20
	var margem_inferior = 80 # Margem para ficar acima da barra de tarefas
	
	# Calcula a posição exata no canto inferior direito
	var pos_final_x = tamanho_tela.x - largura_balao - margem_direita
	var pos_final_y = tamanho_tela.y - altura_balao - margem_inferior
	
	# Define a posição inicial 50 pixels mais abaixo (invisível) para a animação
	position = Vector2(pos_final_x, pos_final_y + 50)
	modulate.a = 0.0
	
	# Cria a animação dele subindo para a posição final
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", pos_final_y, 0.4).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "modulate:a", 1.0, 0.4)
