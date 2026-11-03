extends PanelContainer

@onready var lbl_titulo: Label = $VBoxContainer/BarraSuperior/Titulo
@onready var txt_corpo: RichTextLabel = $VBoxContainer/CorpoTexto
@onready var btn_fechar: Button = $VBoxContainer/BarraSuperior/BtnFechar

# Referências para os novos botões
@onready var btn_minimizar: Button = $VBoxContainer/BarraSuperior/BtnMinimizar
@onready var btn_maximizar: Button = $VBoxContainer/BarraSuperior/BtnMaximizar

# Variáveis para a lógica de Maximizar
var esta_maximizado: bool = false
var tamanho_original: Vector2
var posicao_original: Vector2

func _ready() -> void:
	# Conectando os 3 botões
	btn_fechar.pressed.connect(queue_free)
	btn_maximizar.pressed.connect(alternar_maximizar)
	btn_minimizar.pressed.connect(tentar_minimizar)

func abrir_arquivo(nome_arquivo: String, conteudo: String) -> void:
	lbl_titulo.text = nome_arquivo
	txt_corpo.text = conteudo

func alternar_maximizar() -> void:
	if not esta_maximizado:
		# 1. Guarda o tamanho e posição atuais antes de esticar
		tamanho_original = size
		posicao_original = position
		
		# 2. Calcula o tamanho máximo (Tela inteira MENOS a barra de tarefas)
		var tamanho_tela = get_viewport_rect().size
		var altura_barra_tarefas = 60 # Ajuste este valor para a altura exata da sua barra
		
		# 3. Estica a janela
		position = Vector2(0, 0) # Vai para o canto superior esquerdo
		size = Vector2(tamanho_tela.x, tamanho_tela.y - altura_barra_tarefas)
		esta_maximizado = true
	else:
		# 4. Se já estava maximizado, restaura ao normal
		size = tamanho_original
		position = posicao_original
		esta_maximizado = false

func tentar_minimizar() -> void:
	# Como a AreaDeTrabalho instanciou esta janela, ela é o pai direto
	var desktop = get_parent() 
	
	if desktop.has_method("disparar_notificacao"):
		desktop.disparar_notificacao(
			"⚠️ VIOLAÇÃO DE FOCO", 
			"A ocultação de tarefas ativas é estritamente proibida. Produtividade requer atenção constante."
		)
