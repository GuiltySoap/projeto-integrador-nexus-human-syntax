class_name AppMensageiro
extends AppBase
## Mensageiro do roteiro v2.0. Antes da Task 6 ("aguardando indexação") não há conversas; depois da sincronização (Task 6.2) o app lista
## as conversas do histórico sincronizado (somente leitura) e as que o jogo acrescenta. Quando a Maya tem o Gerenciamento do Mensageiro,
## os contatos ganham as seções Importantes/Outros, algumas mensagens chegam ocultadas ("Mostrar mesmo assim", Autonomia +1 uma vez por
## mensagem) e, nas Tasks 6 e 9, a Maya pode enviar a resposta no lugar do jogador: uma BARRA DE ENVIO de 3 s (6 s com "Tempo estendido")
## com o botão [Cancelar envio] focado por padrão; cancelar envia o que o jogador escreveu.
## As respostas do jogador são sempre botões (sem digitação livre), vindos do nó de escolha atual do roteiro quando ele pertence a esta conversa.
## Toda regra vive no GerenciadorNarrativa/FluxoRoteiro; este app só desenha o resultado e repassa as ações do jogador.
## Args: {"contato": "bia"}.
##
## A interface (lista de contatos, cabeçalho, área de mensagens, escolhas) vive em app_mensageiro.tscn. Dinâmico: uma linha por contato
## (item_contato.tscn), um balão por mensagem (balao_chat.tscn) e um botão por opção (item_escolha.tscn).

const LARGURA_BALAO_PADRAO := 480
const TEXTO_AGUARDANDO := "Aguardando indexação do Mensageiro. As conversas aparecem aqui depois da sincronização da Maya."

@export var cena_contato: PackedScene
@export var cena_balao: PackedScene
@export var cena_escolha: PackedScene

var _pronta: bool = false
var _contato_atual: String = ""
var _grupo: ButtonGroup = ButtonGroup.new()
var _itens_contatos: Array = []
var _baloes: Array = []
var _botoes_escolha: Array = []
var _barra_caixa: VBoxContainer = null
var _barra_progresso: ProgressBar = null
var _barra_texto: Label = null
var _barra_cancelar: Button = null

@onready var _lista_contatos: VBoxContainer = %ListaContatos
@onready var _painel_conversa: VBoxContainer = %PainelConversa
@onready var _rot_nome: Label = %RotuloNome
@onready var _rot_status: Label = %RotuloStatus
@onready var _rolagem: ScrollContainer = %Rolagem
@onready var _lista_mensagens: VBoxContainer = %ListaMensagens
@onready var _rot_vazio: Label = %RotuloVazio
@onready var _area_escolhas: VBoxContainer = %AreaEscolhas
@onready var _rot_dica: Label = %RotuloDica


func _ready() -> void:
	super()
	_pronta = UiKit.refs_ok(self, {
		"ListaContatos": _lista_contatos, "PainelConversa": _painel_conversa, "RotuloNome": _rot_nome, "RotuloStatus": _rot_status,
		"Rolagem": _rolagem, "ListaMensagens": _lista_mensagens, "RotuloVazio": _rot_vazio, "AreaEscolhas": _area_escolhas,
		"RotuloDica": _rot_dica,
	})
	if cena_contato == null or cena_balao == null or cena_escolha == null:
		push_error("AppMensageiro: cena_contato, cena_balao e cena_escolha precisam ser definidas no Inspetor.")
		_pronta = false
	if not _pronta:
		return
	_rot_dica.visible = false
	_montar_barra()
	conectar(GerenciadorEstado.mensagem_recebida, _ao_mensagem_recebida)
	conectar(GerenciadorEstado.mensagem_atualizada, _ao_mensagem_atualizada)
	conectar(GerenciadorEstado.flag_alterada, _ao_flag_alterada)
	conectar(GerenciadorNarrativa.etapa_iniciada, _ao_etapa)
	conectar(GerenciadorNarrativa.apresentacao_mudou, _ao_apresentacao)
	conectar(GerenciadorNarrativa.barra_envio_mudou, _ao_barra)
	conectar(GerenciadorNarrativa.mensagem_revelada, _ao_revelada)


func _process(_delta: float) -> void:
	if _pronta and _barra_caixa != null and _barra_caixa.visible:
		_atualizar_barra()


func iniciar(args: Dictionary = {}) -> void:
	if not _pronta:
		return
	_atualizar_contatos()
	var alvo := str(args.get("contato", ""))
	if alvo == "" or not _contato_existe(alvo):
		if _contato_atual != "" and _contato_existe(_contato_atual):
			alvo = _contato_atual
		else:
			alvo = _contato_inicial()
	_selecionar(alvo)


func receber_args(args: Dictionary) -> void:
	iniciar(args)


func ao_focar() -> void:
	if _pronta and _contato_atual != "":
		GerenciadorEstado.marcar_lidas(_contato_atual)
		_atualizar_contatos()
		_focar_primeiro.call_deferred()


func ao_fechar() -> void:
	GerenciadorEstado.conversa_ativa = ""


# ------------------------------------------------------------------ contatos
func _contato_existe(id_contato: String) -> bool:
	for c in GerenciadorNarrativa.contatos_disponiveis():
		if str(c["id"]) == id_contato:
			return true
	return false


## Abre primeiro a conversa que o roteiro pede (escolha ou barra de envio), depois a que tem mensagens não lidas, depois a primeira.
func _contato_inicial() -> String:
	var contatos: Array = GerenciadorNarrativa.contatos_disponiveis()
	var pedido := str(GerenciadorNarrativa.apresentacao().get("contato", ""))
	if pedido != "" and _contato_existe(pedido):
		return pedido
	for c in contatos:
		if GerenciadorEstado.nao_lidas(str(c["id"])) > 0:
			return str(c["id"])
	return str(contatos[0]["id"]) if not contatos.is_empty() else ""


func _atualizar_contatos() -> void:
	UiKit.remover_itens(_itens_contatos)
	var secao_atual := ""
	for c in GerenciadorNarrativa.contatos_disponiveis():
		var id_contato := str(c["id"])
		var secao := str(c.get("secao", ""))
		if secao != "" and secao != secao_atual:
			secao_atual = secao
			var titulo := Label.new()
			titulo.text = secao
			titulo.theme_type_variation = &"RotuloAcento11"
			_lista_contatos.add_child(titulo)
			_itens_contatos.append(titulo)
		var historico: Array = GerenciadorNarrativa.mensagens_da_conversa(id_contato)
		var previa := ""
		if not historico.is_empty():
			var ultima: Dictionary = historico[historico.size() - 1]
			previa = UtilTexto.truncar(str(ultima.get("texto", "")), 30)
		var item := cena_contato.instantiate() as ItemContato
		_lista_contatos.add_child(item)
		item.configurar(c, previa, GerenciadorEstado.nao_lidas(id_contato), id_contato == _contato_atual, _grupo)
		item.selecionado.connect(_selecionar)
		_itens_contatos.append(item)


# ------------------------------------------------------------------ conversa
func _selecionar(id_contato: String) -> void:
	_contato_atual = id_contato
	GerenciadorEstado.conversa_ativa = id_contato
	_reconstruir_conversa()
	_atualizar_contatos()
	if is_visible_in_tree():
		_focar_primeiro.call_deferred()


func _reconstruir_conversa() -> void:
	UiKit.remover_itens(_baloes)
	_rot_vazio.visible = false
	if _contato_atual == "" or not _contato_existe(_contato_atual):
		_rot_nome.text = "Mensagens"
		var indexado := GerenciadorEstado.tem_flag("mensageiro_indexado")
		_rot_status.text = "Nenhuma conversa disponível." if indexado else TEXTO_AGUARDANDO
		_rot_vazio.text = _rot_status.text
		_rot_vazio.visible = true
		_area_escolhas.visible = false
		_barra_caixa.visible = false
		return
	var dados_contato: Dictionary = GerenciadorNarrativa.info_contato(_contato_atual)
	_rot_nome.text = "%s %s" % [str(dados_contato.get("icone", "?")), str(dados_contato.get("nome", _contato_atual))]
	_rot_status.text = "histórico sincronizado (somente leitura)" if _tem_sincronizada(_contato_atual) else ""
	var historico: Array = GerenciadorNarrativa.mensagens_da_conversa(_contato_atual)
	_rot_vazio.text = "Nenhuma mensagem ainda."
	_rot_vazio.visible = historico.is_empty()
	for entrada in historico:
		_adicionar_balao(entrada)
	_atualizar_escolhas()
	GerenciadorEstado.marcar_lidas(_contato_atual)
	GerenciadorEstado.set_flag("conversa_lida:" + _contato_atual, true)
	_rolar_para_fim()


func _tem_sincronizada(id_contato: String) -> bool:
	for m in GerenciadorNarrativa.mensagens_da_conversa(id_contato):
		if bool((m as Dictionary).get("sincronizada", false)):
			return true
	return false


func _adicionar_balao(entrada: Dictionary) -> void:
	_rot_vazio.visible = false
	var balao := cena_balao.instantiate() as BalaoChat
	_lista_mensagens.add_child(balao)
	balao.configurar(entrada, _largura_maxima_balao())
	balao.mostrar_solicitado.connect(_ao_mostrar)
	_baloes.append(balao)


func _largura_maxima_balao() -> int:
	var largura: float = _painel_conversa.size.x
	if largura < 200.0:
		return LARGURA_BALAO_PADRAO
	return int(maxf(largura * 0.68, 240.0))


## Opções de resposta: só quando o nó de escolha atual é desta conversa (contexto "chat" e contato igual). Senão o painel da Maya as mostra.
func _atualizar_escolhas() -> void:
	UiKit.remover_itens(_botoes_escolha)
	var ap: Dictionary = GerenciadorNarrativa.apresentacao()
	var daqui: bool = str(ap.get("contexto", "")) == "chat" and str(ap.get("contato", "")) == _contato_atual
	var opcoes: Array = ap.get("opcoes", []) if daqui else []
	_area_escolhas.visible = not opcoes.is_empty()
	for opcao in opcoes:
		var botao := cena_escolha.instantiate() as ItemEscolha
		_area_escolhas.add_child(botao)
		botao.configurar(opcao)
		botao.escolhida.connect(_ao_escolher)
		_botoes_escolha.append(botao)
	_atualizar_barra()


## Barra de envio da Maya: criada uma vez, mostrada só enquanto o nó atual é uma barra desta conversa.
func _montar_barra() -> void:
	_barra_caixa = VBoxContainer.new()
	_barra_caixa.name = "BarraDeEnvio"
	_barra_caixa.visible = false
	_barra_texto = Label.new()
	_barra_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_barra_texto.custom_minimum_size = Vector2(1, 0)
	_barra_caixa.add_child(_barra_texto)
	_barra_progresso = ProgressBar.new()
	_barra_progresso.min_value = 0.0
	_barra_progresso.max_value = 1.0
	_barra_progresso.step = 0.01
	_barra_progresso.custom_minimum_size = Vector2(0, 14)
	_barra_caixa.add_child(_barra_progresso)
	_barra_cancelar = Button.new()
	_barra_cancelar.text = "Cancelar envio"
	_barra_cancelar.tooltip_text = "Envia a mensagem como você escreveu, sem a versão da Maya."
	_barra_cancelar.pressed.connect(_ao_cancelar_envio)
	_barra_caixa.add_child(_barra_cancelar)
	_painel_conversa.add_child(_barra_caixa)
	_painel_conversa.move_child(_barra_caixa, _area_escolhas.get_index())


func _atualizar_barra() -> void:
	if _barra_caixa == null:
		return
	var b: Dictionary = GerenciadorNarrativa.estado_da_barra()
	var visivel: bool = bool(b.get("ativa", false)) and str(b.get("contato", "")) == _contato_atual
	var estava := _barra_caixa.visible
	_barra_caixa.visible = visivel
	if not visivel:
		return
	_barra_texto.text = "%s: “%s”" % [str(b.get("rotulo", "Maya está enviando por você")), str(b.get("texto", ""))]
	_barra_progresso.value = float(b.get("progresso", 0.0))
	if not estava:
		UiKit.focar_depois(_barra_cancelar)   # [Cancelar envio] já nasce focado: Enter/Espaço cancela, sem mouse


## Leva o foco do teclado ao botão de cancelar (se a barra está ativa) ou à primeira opção.
func _focar_primeiro() -> void:
	if not is_inside_tree() or not is_visible_in_tree():
		return
	if _barra_caixa != null and _barra_caixa.visible:
		_barra_cancelar.grab_focus()
		return
	for botao in _botoes_escolha:
		if is_instance_valid(botao):
			(botao as ItemEscolha).grab_focus()
			return


func _rolar_para_fim() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if is_inside_tree():
		_rolagem.scroll_vertical = int(_rolagem.get_v_scroll_bar().max_value)


# ------------------------------------------------------------------ eventos
func _ao_escolher(id_escolha: String) -> void:
	GerenciadorNarrativa.escolher_opcao(id_escolha)


func _ao_cancelar_envio() -> void:
	GerenciadorNarrativa.cancelar_envio()


func _ao_mostrar(id_msg: String) -> void:
	GerenciadorNarrativa.mostrar_mensagem_oculta(_contato_atual, id_msg)


func _ao_revelada(_contato: String, _id_msg: String) -> void:
	pass   # o balão é refeito por mensagem_atualizada


func _ao_mensagem_recebida(contato: String, entrada: Dictionary) -> void:
	_atualizar_contatos()
	if contato != _contato_atual:
		return
	_adicionar_balao(entrada)
	if is_visible_in_tree():
		GerenciadorEstado.marcar_lidas(contato)
	_rolar_para_fim()


## Uma mensagem mudou (pendente → enviada, ocultada → mostrada): refaz só o balão dela.
func _ao_mensagem_atualizada(contato: String, id_msg: String) -> void:
	if contato != _contato_atual:
		return
	var entrada: Dictionary = {}
	for e in GerenciadorEstado.historico(contato):
		if str((e as Dictionary).get("id", "")) == id_msg:
			entrada = e
			break
	for balao in _baloes:
		if is_instance_valid(balao) and (balao as BalaoChat).id_mensagem() == id_msg and not entrada.is_empty():
			(balao as BalaoChat).configurar(entrada, _largura_maxima_balao())
			break
	_atualizar_contatos()


func _ao_flag_alterada(nome: String, _valor: Variant) -> void:
	if nome == "mensageiro_indexado" or nome == "contatos_reordenados":
		_atualizar_contatos()
		if _contato_atual == "" or not _contato_existe(_contato_atual):
			_selecionar(_contato_inicial())


func _ao_etapa(_etapa: int) -> void:
	_atualizar_contatos()
	if _contato_atual != "" and not _contato_existe(_contato_atual):
		_selecionar(_contato_inicial())


func _ao_apresentacao() -> void:
	var pedido := str(GerenciadorNarrativa.apresentacao().get("contato", ""))
	if pedido != "" and pedido != _contato_atual and _contato_existe(pedido):
		_selecionar(pedido)
	else:
		_atualizar_escolhas()
		if is_visible_in_tree():
			_focar_primeiro.call_deferred()


func _ao_barra(_ativa: bool, _progresso: float) -> void:
	_atualizar_barra()
	if is_visible_in_tree():
		_focar_primeiro.call_deferred()
