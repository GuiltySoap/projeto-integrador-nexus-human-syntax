extends "res://JanelaBase.gd"

const BALAO_CHAT = preload("res://Apps/Mensagens/BalaoChat.tscn")
const BALAO_NEXUS = preload("res://Apps/Mensagens/BalaoNexus.tscn")

@onready var scroll_container: ScrollContainer = $AreaConteudo/VBoxContainer/ScrollContainer
@onready var historico: VBoxContainer = $AreaConteudo/VBoxContainer/ScrollContainer/HistoricoMensagens
@onready var caixa_escolhas: VBoxContainer = $AreaConteudo/VBoxContainer/CaixaDeEscolhas
@onready var media_modal = $MediaViewerModal

var posicao_scroll_salva: int = 0

func _ready() -> void:
	# Conecta o fechamento do modal para restaurar o scroll e o foco
	#if media_modal and not media_modal.modal_closed.is_connected(_ao_fechar_midia_modal):
		#media_modal.modal_closed.connect(_ao_fechar_midia_modal)

	# Injeta dados temporários para o teste visual
	#if GerenciadorEstado.dados.is_empty() or not GerenciadorEstado.dados.has("fala_nexus"):
		#GerenciadorEstado.dados = {
			#"fala_nexus": "Sistema inicializado. Aguardando input do usuário...",
			#"opcoes": [
				#{"id": 1, "texto": "O que aconteceu com meus arquivos?"},
				#{"id": 2, "texto": "Quem está aí?"}
			#]
		#}
	# TESTE DA US 08: Injeta uma mensagem com ID "msg_01"
	adicionar_balao_jogador({"id": "msg_01", "texto": "Eu confio em você, Nex."})
	
	# Passados 4 segundos, o sistema invade o histórico e altera a mensagem
	get_tree().create_timer(4.0).timeout.connect(func(): executar_gaslighting("msg_01", "Eu odeio você, Nex."))
	# Quando o estado global ditar, alteramos a mensagem na interface
	GerenciadorEstado.gaslighting_solicitado.connect(executar_gaslighting)
	# Agora o sistema tem dados reais para construir a tela
	#renderizar_mensagens_do_json()

# Função principal quando o jogador clica numa opção
func _on_botao_escolha_clicado(id_da_escolha: int, texto_escolha: String) -> void:
	# 1. Trava a UI
	desativar_botoes()
	
	# 2. Adiciona o que o jogador escolheu ao histórico visualmente
	adicionar_balao_jogador({"texto": texto_escolha})
	
	# --- INÍCIO DA US 04: INDICADOR DE DIGITAÇÃO ---
	var indicador = Label.new()
	indicador.text = "NEXUS está digitando..."
	indicador.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	historico.add_child(indicador)
	
	await get_tree().create_timer(2.0).timeout
	
	indicador.queue_free()
	# --- FIM DA US 04 ---
	
	# 3. Atualiza o Autoload e refaz a tela
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
			btn.pressed.connect(func(): _on_botao_escolha_clicado(opcao["id"], opcao["texto"]))
			caixa_escolhas.add_child(btn)

func adicionar_balao_jogador(dados_ou_texto: Variant) -> void:
	var balao = BALAO_CHAT.instantiate()
	historico.add_child(balao)
	
	# Aceita tanto Dicionário com anexo quanto String de texto simples
	if dados_ou_texto is Dictionary:
		balao.configurar_mensagem(dados_ou_texto)
	else:
		balao.configurar_mensagem({"texto": str(dados_ou_texto)})
	
	# Conecta a mídia do balão ao modal
	if not balao.midia_clicada.is_connected(_abrir_midia_em_tela_cheia):
		balao.midia_clicada.connect(_abrir_midia_em_tela_cheia)

func adicionar_balao_nexus(texto: String) -> void:
	var balao = BALAO_NEXUS.instantiate()
	historico.add_child(balao)
	balao.get_node("Label").text = texto

# --- LÓGICA DE MODAL E FOCO/SCROLL (SUB-04) ---

func _abrir_midia_em_tela_cheia(caminho: String) -> void:
	posicao_scroll_salva = scroll_container.scroll_vertical
	media_modal.exibir_midia(caminho)

func _ao_fechar_midia_modal() -> void:
	# Restaura a posição exata de scroll
	scroll_container.scroll_vertical = posicao_scroll_salva
	
	# Restaura o foco para os botões de escolha ou para o chat
	if caixa_escolhas.visible and caixa_escolhas.get_child_count() > 0:
		caixa_escolhas.get_child(0).grab_focus()
	else:
		scroll_container.grab_focus()

func executar_gaslighting(id_alvo: String, texto_corrompido: String) -> void:
	# Percorre todas as mensagens atualmente desenhadas no ecrã
	for balao in historico.get_children():
		# Verifica se o nó tem a propriedade id_mensagem e se corresponde ao alvo
		if "id_mensagem" in balao and balao.id_mensagem == id_alvo:
			balao.aplicar_gaslighting(texto_corrompido)
			
			# Opcional: Força o scroll a descer para a mensagem alterada
			# scroll_container.ensure_control_visible(balao) 
			break
	
