extends PanelContainer

signal clicado_para_abrir_chat

@onready var lbl_titulo: Label = $VBoxContainer/Titulo
@onready var lbl_mensagem: Label = $VBoxContainer/Mensagem
@onready var btn_clicavel: Button = $BtnClicavel
@onready var som_notificacao: AudioStreamPlayer = $SomNotificacao

func _ready() -> void:
	z_index = 100
	btn_clicavel.pressed.connect(_ao_banner_clicado)

func configurar_mensagem(titulo: String, texto: String) -> void:
	lbl_titulo.text = titulo
	lbl_mensagem.text = texto
	
	if som_notificacao.stream != null:
		som_notificacao.play()
	
	await get_tree().process_frame
	
	var tamanho_tela = get_viewport_rect().size
	var altura_balao = size.y
	var largura_balao = size.x
	
	var margem_superior = 20
	
	# Calcula para centralizar no topo da tela
	var pos_final_x = (tamanho_tela.x - largura_balao) / 2.0
	var pos_final_y = margem_superior
	
	# Posição inicial levemente acima da tela (escondido)
	position = Vector2(pos_final_x, pos_final_y - 80)
	modulate.a = 0.0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", pos_final_y, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	# Auto-destruição após 5 segundos se o jogador não clicar
	get_tree().create_timer(5.0).timeout.connect(fechar_notificacao)

func _ao_banner_clicado() -> void:
	clicado_para_abrir_chat.emit()
	fechar_notificacao()

func fechar_notificacao() -> void:
	# Animação de saída antes de deletar
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 50, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(queue_free)
