extends "res://JanelaBase.gd"

# Precarrega os moldes de ícone e modais
const ICONE_FICHEIRO = preload("res://Apps/IconeFicheiro.tscn")
const PASSWORD_MODAL_SCENE = preload("res://PasswordModal.tscn")
const MINIGAME_LOGICA_SCENE = preload("res://MinigameLogica.tscn")

@onready var grid_arquivos: GridContainer = $AreaConteudo/HSplitContainer/PanelDireito/ScrollContainer/GridContainer

var minigame_logica: Control
var icarus_desbloqueado: bool = false
var password_modal_instancia = null
var arquivo_pendente_desbloqueio: Dictionary = {}

# Banco de dados de arquivos
var sistema_de_arquivos = [
	{"nome": "System_Logs", "tipo": "pasta", "is_locked": false},
	{"nome": "Personal_Data", "tipo": "pasta", "is_locked": false},
	{"nome": "PROJECT_Icarus", "tipo": "pasta", "is_locked": false},
	{"nome": "read_me.txt", "tipo": "texto", "is_locked": false},
	{"nome": "memorias_backup.zip", "tipo": "zip", "is_locked": true, "senha": "icarus_syntax"},
	{"nome": "NEXUSCore.exe", "tipo": "executavel", "is_locked": false},
	{"nome": "data_stream.png", "tipo": "imagem_corrompida", "is_locked": false}
]

func _ready() -> void:
	_instanciar_modal_senha()
	_instanciar_minigame()
	gerar_arquivos()

func _instanciar_minigame() -> void:
	if not minigame_logica:
		minigame_logica = MINIGAME_LOGICA_SCENE.instantiate()
		add_child(minigame_logica)
	
	if not minigame_logica.puzzle_solved.is_connected(_on_icarus_puzzle_solved):
		minigame_logica.puzzle_solved.connect(_on_icarus_puzzle_solved)

func _on_ficheiro_icarus_clicado() -> void:
	if icarus_desbloqueado:
		_abrir_conteudo_icarus()
	else:
		minigame_logica.open_modal()

func _on_icarus_puzzle_solved() -> void:
	icarus_desbloqueado = true
	print("NEXUS: Ficheiro PROJECT_Icarus desbloqueado com sucesso!")
	_abrir_conteudo_icarus()

func _abrir_conteudo_icarus() -> void:
	var desktop = get_parent().get_parent()
	var texto_icarus = "--- [PROJETO ÍCARO - REGISTRO CRÍTICO] ---\n\nStatus: Recuperado.\nProtocolos de contenção desativados."
	
	if desktop.has_method("abrir_leitor_texto"):
		desktop.abrir_leitor_texto("PROJECT_Icarus", texto_icarus)
	else:
		print("NEXUS: Conteúdo de PROJECT_Icarus exibido.")

func _instanciar_modal_senha() -> void:
	if PASSWORD_MODAL_SCENE:
		password_modal_instancia = PASSWORD_MODAL_SCENE.instantiate()
		add_child(password_modal_instancia)
		password_modal_instancia.hide()
		
		password_modal_instancia.password_submitted.connect(_validar_senha)
		password_modal_instancia.cancelled.connect(_ao_cancelar_senha)

func gerar_arquivos() -> void:
	for child in grid_arquivos.get_children():
		child.queue_free()
		
	for arquivo in sistema_de_arquivos:
		var novo_icone = ICONE_FICHEIRO.instantiate()
		grid_arquivos.add_child(novo_icone)
		
		var label_nome = novo_icone.get_node("VBoxContainer/NomeFicheiro")
		var botao = novo_icone.get_node("BotaoClique")
		
		label_nome.text = arquivo["nome"]
		botao.pressed.connect(func(): tentar_abrir_arquivo(arquivo))

func tentar_abrir_arquivo(arquivo: Dictionary) -> void:
	if arquivo.get("is_locked", false):
		arquivo_pendente_desbloqueio = arquivo
		if password_modal_instancia:
			password_modal_instancia.open_modal()
		return
		
	abrir_arquivo(arquivo["nome"], arquivo["tipo"])

func _validar_senha(senha_digitada: String) -> void:
	if arquivo_pendente_desbloqueio.is_empty():
		return
		
	var senha_correta = arquivo_pendente_desbloqueio.get("senha", "")
	
	if senha_digitada == senha_correta:
		arquivo_pendente_desbloqueio["is_locked"] = false
		if password_modal_instancia:
			password_modal_instancia.hide()
		
		print("NEXUS: Arquivo " + arquivo_pendente_desbloqueio["nome"] + " desbloqueado com sucesso!")
		abrir_arquivo(arquivo_pendente_desbloqueio["nome"], arquivo_pendente_desbloqueio["tipo"])
		arquivo_pendente_desbloqueio = {}
	else:
		if password_modal_instancia:
			password_modal_instancia.show_error("Acesso Negado")

func _ao_cancelar_senha() -> void:
	arquivo_pendente_desbloqueio = {}

func abrir_arquivo(nome: String, tipo: String) -> void:
	var desktop = get_parent().get_parent()
	
	if nome == "PROJECT_Icarus":
		_on_ficheiro_icarus_clicado()
			
	elif nome == "read_me.txt":
		var texto_corporativo = "Bem-vindo ao NEXUS OS.\n\nLembre-se: Produtividade é Obediência. Pausas não autorizadas serão descontadas dos seus créditos sociais.\n\nSua estação está sendo monitorada."
		
		if desktop.has_method("abrir_leitor_texto"):
			desktop.abrir_leitor_texto(nome, texto_corporativo)		
			
	elif nome == "memorias_backup.zip":
		print("NEXUS: Acessando arquivo descompactado memorias_backup.zip...")
		
	elif tipo == "texto" or tipo == "imagem_corrompida":
		print("NEXUS: Abrindo visualizador para " + nome + "...")
	else:
		print("NEXUS: Acessando pasta " + nome)
