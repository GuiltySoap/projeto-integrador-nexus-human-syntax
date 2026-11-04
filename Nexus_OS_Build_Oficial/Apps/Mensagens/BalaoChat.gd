extends PanelContainer

signal midia_clicada(caminho_completo)

@onready var label_texto: Label = $Label
@onready var btn_miniatura: TextureButton = $BtnMiniatura

var caminho_midia_completa: String = ""
var id_mensagem: String = "" # --- NOVO: Identificador único da mensagem ---

func configurar_mensagem(dados: Dictionary) -> void:
	# --- NOVO: Salva o ID se a mensagem possuir um ---
	if dados.has("id"):
		id_mensagem = str(dados["id"])
		
	# 1. Configura o texto
	if dados.has("text") or dados.has("texto"):
		var texto = dados.get("text", dados.get("texto", ""))
		label_texto.text = texto
		label_texto.show()
	else:
		label_texto.hide()

	# 2. Configura a miniatura (se houver anexo)
	if dados.has("anexo"):
		var anexo = dados["anexo"]
		caminho_midia_completa = anexo["full_path"]
		
		if ResourceLoader.exists(anexo["thumb_path"]):
			btn_miniatura.texture_normal = load(anexo["thumb_path"])
			btn_miniatura.show()
			
			if not btn_miniatura.pressed.is_connected(_on_miniatura_pressed):
				btn_miniatura.pressed.connect(_on_miniatura_pressed)
		else:
			push_error("BalaoChat: Miniatura não encontrada no caminho -> " + anexo["thumb_path"])
	else:
		btn_miniatura.hide()

func _on_miniatura_pressed() -> void:
	midia_clicada.emit(caminho_midia_completa)

# --- NOVO: Função chamada pelo AppMensageiro para executar a troca (US 08) ---
# --- NOVO: Função chamada pelo AppMensageiro para executar a troca (US 08) ---
func aplicar_gaslighting(novo_texto: String) -> void:
	var pos_original = label_texto.position
	var tween = create_tween().set_parallel(false) # Executa em sequência
	
	# Fase 1: Vibração e "ruído" visual (Glitch)
	for i in range(10):
		# Desloca a posição aleatoriamente
		var offset = Vector2(randf_range(-5, 5), randf_range(-3, 3))
		tween.tween_property(label_texto, "position", pos_original + offset, 0.05)
		
		# Pisca com cores de erro (vermelho/magenta)
		var cor_glitch = Color(0.9, 0.1, 0.2) if i % 2 == 0 else Color(0.8, 0.8, 0.8)
		tween.tween_method(_mudar_cor_texto, label_texto.get_theme_color("font_color"), cor_glitch, 0.05)
	
	# Fase 2: Assenta a poeira e injeta o texto manipulado
	tween.tween_property(label_texto, "position", pos_original, 0.05)
	tween.tween_callback(func():
		label_texto.text = novo_texto
		_mudar_cor_texto(Color(0.8, 0.2, 0.2)) # Fixa o texto hostil a vermelho
	)

# Função auxiliar para o Tween animar a cor do Label corretamente
func _mudar_cor_texto(cor: Color) -> void:
	label_texto.add_theme_color_override("font_color", cor)
