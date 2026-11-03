extends "res://JanelaBase.gd"

const BALAO_CHAT = preload("res://Apps/Mensagens/BalaoChat.tscn")
const BALAO_NEXUS = preload("res://Apps/Mensagens/BalaoNexus.tscn")

@onready var historico: VBoxContainer = $AreaConteudo/VBoxContainer/ScrollContainer/HistoricoMensagens
@onready var caixa_escolhas: VBoxContainer = $AreaConteudo/VBoxContainer/CaixaDeEscolhas

func _ready() -> void:
	# Injeta dados temporários para o teste visual
	if GerenciadorEstado.dados.is_empty() or not GerenciadorEstado.dados.has("fala_nexus"):
		GerenciadorEstado.dados = {
			"fala_nexus": "Sistema inicializado. Aguardando input do usuário...",
			"opcoes": [
				{"id": 1, "texto": "O que aconteceu com meus arquivos?"},
				{"id": 2, "texto": "Quem está aí?"}
			]
		}
	
	# Agora o sistema tem dados reais para construir a tela
	renderizar_mensagens_do_json()

# Função principal quando o jogador clica numa opção
func _on_botao_escolha_clicado(id_da_escolha: int, texto_escolha: String) -> void:
	# 1. Trava a UI
	desativar_botoes()
	
	# 2. Adiciona o que o jogador escolheu ao histórico visualmente
	adicionar_balao_jogador(texto_escolha)
	
	# --- INÍCIO DA US 04: INDICADOR DE DIGITAÇÃO ---
	# Cria um aviso temporário de digitação direto no histórico
	var indicador = Label.new()
	indicador.text = "NEXUS está digitando..."
	indicador.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6)) # Cinza discreto
	historico.add_child(indicador)
	
	# Pausa a execução por 2 segundos para simular o tempo de resposta
	await get_tree().create_timer(2.0).timeout
	
	# Remove o aviso da tela antes de exibir a resposta real
	indicador.queue_free()
	# --- FIM DA US 04 ---
	
	# 3. Executa o C no background
	# Usamos globalize_path para garantir que o Godot ache o .exe no Windows
	#var caminho_executavel = ProjectSettings.globalize_path("res://_Backend/nexus_core.exe")
	#var argumentos = [str(id_da_escolha)]
	#var saida = []
	
	#OS.execute(caminho_executavel, argumentos, saida)
	
	# 4. Atualiza o Autoload e refaz a tela
	GerenciadorEstado.carregar_json()
	renderizar_mensagens_do_json()

# --- FUNÇÕES AUXILIARES ---

func desativar_botoes() -> void:
	for botao in caixa_escolhas.get_children():
		botao.disabled = true

func renderizar_mensagens_do_json() -> void:
	# 1. Limpa os botões antigos da escolha anterior
	for filho in caixa_escolhas.get_children():
		filho.queue_free()
		
	var dados = GerenciadorEstado.dados
	
	# 2. Instancia a resposta da NEXUS
	if dados.has("fala_nexus"):
		adicionar_balao_nexus(dados["fala_nexus"])
		
	# 3. Instancia os botões novos
	if dados.has("opcoes"):
		for opcao in dados["opcoes"]:
			var btn = Button.new()
			btn.text = opcao["texto"]
			
			# Conecta o clique do botão gerado à função principal
			btn.pressed.connect(func(): _on_botao_escolha_clicado(opcao["id"], opcao["texto"]))
			
			caixa_escolhas.add_child(btn)

func adicionar_balao_jogador(texto: String) -> void:
	var balao = BALAO_CHAT.instantiate()
	historico.add_child(balao)
	balao.get_node("Label").text = texto

func adicionar_balao_nexus(texto: String) -> void:
	var balao = BALAO_NEXUS.instantiate()
	historico.add_child(balao)
	balao.get_node("Label").text = texto
