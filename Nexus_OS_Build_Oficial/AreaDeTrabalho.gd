extends Control

# Dizemos ao script onde está o arquivo da janela para ele "carregar" na memória
const JANELA_BASE = preload("res://JanelaBase.tscn")
const APP_CONFIG = preload("res://Apps/Configuracoes/AppConfig.tscn")
const APP_EMAIL = preload("res://Apps/Email/AppEmail.tscn") # Substitua pelo caminho real se precisar!
const APP_CHAT = preload("res://Apps/Mensagens/AppMensageiro.tscn") # Caminho do novo app!
const POPUP_NOTIFICACAO = preload("res://UI_Core/PopUpNotificacao.tscn")
const APP_NAVEGADOR = preload("res://Apps/Arquivos/AppNavegador.tscn")
const APP_LEITOR_TEXTO = preload("res://Apps/Arquivos/AppLeitorTexto.tscn")

@onready var area_de_janelas: Control = $AreaDeJanelas
@onready var btn_iniciar: Button = $BarraDeTarefas/MarginContainer/HBoxContainer/BtnIniciar
@onready var btn_email: Button = $BarraDeTarefas/MarginContainer/HBoxContainer/BtnEmail
@onready var btn_chat: Button = $BarraDeTarefas/MarginContainer/HBoxContainer/BtnChat # Nova referência
@onready var btn_navegador: Button = $BarraDeTarefas/MarginContainer/HBoxContainer/BtnNavegador

func _ready() -> void:
	btn_iniciar.pressed.connect(func(): abrir_app(APP_CONFIG))
	btn_email.pressed.connect(func(): abrir_app(APP_EMAIL))
	btn_chat.pressed.connect(func(): abrir_app(APP_CHAT)) # Conectando o clique
	btn_navegador.pressed.connect(func(): abrir_app(APP_NAVEGADOR))
	
	# Dispara um teste 2 segundos após o jogo abrir
	get_tree().create_timer(2.0).timeout.connect(func(): disparar_notificacao("NEXUS INFORMA", "Seu tempo de pausa acabou. Retorne aos e-mails."))
	
func abrir_app(app_preload) -> void:
	var nova_janela = app_preload.instantiate()
	area_de_janelas.add_child(nova_janela)
	nova_janela.position = Vector2(100, 100)
	
func disparar_notificacao(titulo: String, mensagem: String) -> void:
	var pop_up = POPUP_NOTIFICACAO.instantiate()
	add_child(pop_up) 
	
	# Só passamos os textos. O pop-up se vira com o resto!
	pop_up.configurar_mensagem(titulo, mensagem)
func abrir_leitor_texto(nome_arquivo: String, conteudo: String) -> void:
	var leitor = APP_LEITOR_TEXTO.instantiate()
	add_child(leitor)
	
	# Centraliza a janela na tela para uma boa leitura inicial
	var tamanho_tela = get_viewport_rect().size
	leitor.position = Vector2((tamanho_tela.x / 2) - (leitor.size.x / 2), (tamanho_tela.y / 2) - (leitor.size.y / 2))
	
	# Envia os dados para o script da janela
	leitor.abrir_arquivo(nome_arquivo, conteudo)
	
