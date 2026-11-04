extends Control

const JANELA_BASE = preload("res://JanelaBase.tscn")
const APP_CONFIG = preload("res://Apps/Configuracoes/AppConfig.tscn")
const APP_EMAIL = preload("res://Apps/Email/AppEmail.tscn")
const APP_CHAT = preload("res://Apps/Mensagens/AppMensageiro.tscn")
const POPUP_NOTIFICACAO = preload("res://UI_Core/PopUpNotificacao.tscn")
const APP_NAVEGADOR = preload("res://Apps/Arquivos/AppNavegador.tscn")
const APP_LEITOR_TEXTO = preload("res://Apps/Arquivos/AppLeitorTexto.tscn")

@onready var area_de_janelas: Control = $AreaDeJanelas
@onready var btn_iniciar: Button = $BarraDeTarefas/MarginContainer/HBoxContainer/BtnIniciar
@onready var btn_email: Button = $BarraDeTarefas/MarginContainer/HBoxContainer/BtnEmail
@onready var btn_chat: Button = $BarraDeTarefas/MarginContainer/HBoxContainer/BtnChat
@onready var btn_navegador: Button = $BarraDeTarefas/MarginContainer/HBoxContainer/BtnNavegador

func _ready() -> void:
	btn_iniciar.pressed.connect(func(): abrir_app(APP_CONFIG))
	btn_email.pressed.connect(func(): abrir_app(APP_EMAIL))
	
	# Alterado para usar a nova função que foca ou abre o chat
	btn_chat.pressed.connect(focar_ou_abrir_chat) 
	
	btn_navegador.pressed.connect(func(): abrir_app(APP_NAVEGADOR))
	
	# Teste de disparo (simulando uma mensagem que chega)
	get_tree().create_timer(2.0).timeout.connect(func(): notificar_nova_mensagem("NEXUS", "Nova mensagem urgente recebida!"))

func abrir_app(app_preload) -> void:
	var nova_janela = app_preload.instantiate()
	area_de_janelas.add_child(nova_janela)
	nova_janela.position = Vector2(100, 100)

# --- SUB-03: VERIFICAÇÃO DE FOCO ---
func notificar_nova_mensagem(remetente: String, texto: String) -> void:
	var chat_em_foco = false
	var janelas = area_de_janelas.get_children()
	
	# No Godot, a última janela da árvore é a que está a ser desenhada por cima (em foco)
	if janelas.size() > 0:
		var ultima_janela = janelas[-1]
		# Verifica se a janela do topo é o chat e se não está minimizada (invisível)
		if ultima_janela.scene_file_path == APP_CHAT.resource_path and ultima_janela.visible:
			chat_em_foco = true
			
	# Só dispara o banner e o áudio se o jogador estiver fora do chat
	if not chat_em_foco:
		disparar_notificacao(remetente, texto)

func disparar_notificacao(titulo: String, mensagem: String) -> void:
	var pop_up = POPUP_NOTIFICACAO.instantiate()
	add_child(pop_up)
	pop_up.configurar_mensagem(titulo, mensagem)
	
	# --- SUB-04: LIGAÇÃO DO CLIQUE NO BANNER ---
	pop_up.clicado_para_abrir_chat.connect(focar_ou_abrir_chat)

# --- FUNÇÃO PARA RESTAURAR O FOCO DA JANELA ---
func focar_ou_abrir_chat() -> void:
	var chat_aberto = false
	
	# Procura na lista de janelas se o chat já existe
	for janela in area_de_janelas.get_children():
		if janela.scene_file_path == APP_CHAT.resource_path:
			chat_aberto = true
			area_de_janelas.move_child(janela, -1) # Move para o topo da lista (foco visual)
			if not janela.visible:
				janela.show() # Restaura se estiver minimizado
			break
			
	if not chat_aberto:
		abrir_app(APP_CHAT)

func abrir_leitor_texto(nome_arquivo: String, conteudo: String) -> void:
	var leitor = APP_LEITOR_TEXTO.instantiate()
	add_child(leitor)
	var tamanho_tela = get_viewport_rect().size
	leitor.position = Vector2((tamanho_tela.x / 2) - (leitor.size.x / 2), (tamanho_tela.y / 2) - (leitor.size.y / 2))
	leitor.abrir_arquivo(nome_arquivo, conteudo)
