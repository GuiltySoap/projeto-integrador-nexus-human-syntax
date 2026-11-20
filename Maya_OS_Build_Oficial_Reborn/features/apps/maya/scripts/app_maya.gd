class_name AppMaya
extends AppBase
## Painel da Maya (roteiro v2.0): o lugar onde ela fala com o jogador. Não é um chat livre: mostra o histórico recente das falas, a fala atual e,
## quando o nó do roteiro é uma escolha, os botões de resposta (sem digitação livre). Abre sozinho na Task 1 e pelo logo da barra de tarefas,
## pelo menu Iniciar ("Falar com a Maya") e por Ctrl+Shift+H.
##   Cabecalho       logo oficial, nome e papel;
##   AreaDeDialogo   histórico das falas, a escolha atual (ItemEscolha) e uma linha de resultado;
##   AreaDeAcoes     "Fechar janelas" (volta ao desktop quando a Maya espera por isso) e "Abrir o Mensageiro" (quando a resposta é numa conversa);
##   RotuloEspera    o que a Maya está esperando (em texto, para leitor de tela).
## Nenhuma regra mora aqui: o motor (GerenciadorNarrativa) decide tudo; o painel desenha `apresentacao()` e repassa o clique.

@export var cena_escolha: PackedScene

var _botoes_escolha: Array = []
var _linhas: Array = []

@onready var _logo: LogoMarca = %Logo
@onready var _rolagem: ScrollContainer = %Rolagem
@onready var _lista_falas: VBoxContainer = %ListaFalas
@onready var _rot_fala_atual: Label = %RotuloFalaAtual
@onready var _area_escolhas: VBoxContainer = %AreaEscolhas
@onready var _rot_resultado: Label = %RotuloResultado
@onready var _rot_espera: Label = %RotuloEspera
@onready var _btn_fechar: Button = %BotaoFecharJanelas
@onready var _btn_mensageiro: Button = %BotaoAbrirMensageiro


func _ready() -> void:
	super._ready()
	if not UiKit.refs_ok(self, {"Logo": _logo, "Rolagem": _rolagem, "ListaFalas": _lista_falas, "RotuloFalaAtual": _rot_fala_atual,
			"AreaEscolhas": _area_escolhas, "RotuloResultado": _rot_resultado, "RotuloEspera": _rot_espera, "BotaoFecharJanelas": _btn_fechar,
			"BotaoAbrirMensageiro": _btn_mensageiro}):
		return
	focus_mode = Control.FOCUS_ALL
	definir_titulo("Painel da Maya")
	conectar(GerenciadorNarrativa.apresentacao_mudou, _atualizar)
	conectar(GerenciadorNarrativa.fala_adicionada, _ao_fala)
	conectar(GerenciadorNarrativa.etapa_iniciada, _ao_etapa)
	conectar(GerenciadorJanelas.janelas_alteradas, _atualizar)
	_reconstruir_historico()
	_atualizar()


func iniciar(_args: Dictionary = {}) -> void:
	_atualizar()
	ao_focar()


func receber_args(args: Dictionary) -> void:
	iniciar(args)


func ao_focar() -> void:
	_focar_primeiro.call_deferred()


func _focar_primeiro() -> void:
	if not is_inside_tree() or not is_visible_in_tree():
		return
	for b in _botoes_escolha:
		if is_instance_valid(b):
			(b as ItemEscolha).grab_focus()
			return
	if _btn_mensageiro.visible:
		_btn_mensageiro.grab_focus()
	elif _btn_fechar.visible and not _btn_fechar.disabled:
		_btn_fechar.grab_focus()


# ------------------------------------------------------------------ histórico
func _reconstruir_historico() -> void:
	UiKit.remover_itens(_linhas)
	for fala in GerenciadorNarrativa.historico_da_maya():
		_adicionar_linha(fala)
	_rolar_para_fim()


func _adicionar_linha(fala: Dictionary) -> void:
	var quem := str(fala.get("quem", "maya"))
	var rotulo := Label.new()
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rotulo.custom_minimum_size = Vector2(1, 0)
	var nome := "Maya"
	match quem:
		"jogador":
			nome = GerenciadorEstado.nome_jogador if GerenciadorEstado.nome_jogador != "" else "Você"
			rotulo.theme_type_variation = &"RotuloAcento"
		"sistema":
			nome = "Sistema"
			rotulo.theme_type_variation = &"RotuloFraco"
		"other":
			nome = "…"
			rotulo.theme_type_variation = &"RotuloFraco"
	rotulo.text = "%s: %s" % [nome, str(fala.get("texto", ""))]
	_lista_falas.add_child(rotulo)
	_linhas.append(rotulo)


func _ao_fala(fala: Dictionary) -> void:
	_adicionar_linha(fala)
	_rolar_para_fim()


func _ao_etapa(_etapa: int) -> void:
	_atualizar()


func _rolar_para_fim() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if is_inside_tree():
		_rolagem.scroll_vertical = int(_rolagem.get_v_scroll_bar().max_value)


# ------------------------------------------------------------------ escolha atual
func _atualizar() -> void:
	if not is_node_ready():
		return
	UiKit.remover_itens(_botoes_escolha)
	var ap: Dictionary = GerenciadorNarrativa.apresentacao()
	var chat: bool = str(ap.get("contexto", "")) == "chat"
	var opcoes: Array = ap.get("opcoes", [])
	_rot_fala_atual.text = ""
	_area_escolhas.visible = not opcoes.is_empty() and not chat
	if not chat and cena_escolha != null:
		for opcao in opcoes:
			var botao := cena_escolha.instantiate() as ItemEscolha
			_area_escolhas.add_child(botao)
			botao.configurar(opcao)
			botao.escolhida.connect(_ao_escolher)
			_botoes_escolha.append(botao)
	var avisos: PackedStringArray = PackedStringArray()
	for removida in GerenciadorNarrativa.opcoes_removidas():
		avisos.append(str(removida))
	_rot_resultado.text = " ".join(avisos)
	_rot_resultado.visible = not avisos.is_empty()
	var app_do_no := str(ap.get("app", ""))
	_btn_mensageiro.visible = (chat and not opcoes.is_empty()) or (app_do_no != "" and not GerenciadorJanelas.app_aberto(app_do_no))
	if chat:
		_btn_mensageiro.text = "Abrir o Mensageiro"
	elif app_do_no == "privacidade_maya":
		_btn_mensageiro.text = "Ver o pedido de permissão"
	elif app_do_no == "minigame_logica":
		_btn_mensageiro.text = "Abrir o desafio de lógica"
	elif app_do_no != "":
		_btn_mensageiro.text = "Abrir a janela"
	var espera := str(ap.get("espera", ""))
	_btn_fechar.visible = espera == "retorno_desktop" or GerenciadorJanelas.janelas().size() > 1
	_rot_espera.text = _texto_da_espera(ap, chat, espera)
	_rot_espera.visible = _rot_espera.text != ""
	if is_visible_in_tree():
		_focar_primeiro.call_deferred()


func _texto_da_espera(ap: Dictionary, chat: bool, espera: String) -> String:
	if chat and not (ap.get("opcoes", []) as Array).is_empty():
		return "Responda na conversa do Mensageiro."
	if espera == "retorno_desktop":
		return "A Maya espera você fechar as janelas e voltar para a área de trabalho."
	if str(ap.get("tipo", "")) == "barra_envio":
		return "A Maya está enviando uma mensagem por você. Cancele no Mensageiro, se quiser."
	return ""


func _ao_escolher(id_escolha: String) -> void:
	GerenciadorNarrativa.escolher_opcao(id_escolha)


# Ligado na cena: BotaoFecharJanelas.pressed
func _ao_fechar_janelas() -> void:
	for j in GerenciadorJanelas.janelas().duplicate():
		if j != janela and j is JanelaBase:
			GerenciadorJanelas.fechar_janela(j as JanelaBase)
	if janela is JanelaBase:
		GerenciadorJanelas.fechar_janela(janela as JanelaBase)


# Ligado na cena: BotaoAbrirMensageiro.pressed
func _ao_abrir_mensageiro() -> void:
	var ap: Dictionary = GerenciadorNarrativa.apresentacao()
	if str(ap.get("contexto", "")) == "chat" or str(ap.get("app", "")) == "":
		GerenciadorJanelas.abrir_app("messenger", {"contato": str(ap.get("contato", ""))})
	else:
		GerenciadorJanelas.abrir_app(str(ap["app"]), ap.get("args", {}))
