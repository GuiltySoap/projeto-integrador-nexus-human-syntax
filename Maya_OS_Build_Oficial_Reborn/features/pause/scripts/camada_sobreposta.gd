class_name CamadaSobreposta
extends Control
## Base do Menu de Pausa e da Tela de Fim de Jogo: uma camada por cima do jogo que PAUSA a árvore, prende o foco nela mesma e
## oferece as ações de sessão (carregar o salvamento anterior, recomeçar, voltar ao Menu Principal), sempre com confirmação
## quando algo pode ser perdido. As duas telas fazem as mesmas três ações pela mesma fachada (Sessao), então "Carregar" é igual
## em todo o jogo; cada tela só decide quais botões mostra e o que o Esc faz.
##
## É um Control de tela cheia (não um CanvasLayer): o Theme do jogo é aplicado na janela raiz e só desce por Controls e Windows,
## então uma camada de Control herda a aparência como todo o resto da interface. A ordem de desenho é a ordem dos filhos da cena
## dona (a última fica por cima) e `z_index` alto garante que nada a cubra.
## As duas cenas têm estes nós de apoio, com nome único: PainelConfirmacao, IndicadorCarregamento, LinhaStatus, IconeStatus e
## MensagemStatus (mais o painel dos botões, que cada cena informa em `_painel_principal`). Regras comuns:
##   - `PROCESS_MODE_WHEN_PAUSED` (definido na cena): a camada continua respondendo com a árvore pausada, enquanto o jogo por
##     trás (relógio da narrativa, autosave, animações, temporizadores, trilha) fica parado. Os sons de interface não pausam;
##   - a pausa é desfeita em TODO caminho de saída: ao fechar, ao trocar de cena (`Cenas` despausa antes da troca) e se a
##     própria camada sair da árvore (`_exit_tree`);
##   - enquanto um painel (confirmação, opções) está aberto, o foco não vaza para os botões atrás dele (UiKit.travar_foco);
##   - durante uma troca de cena os botões ficam desativados, o IndicadorCarregamento cobre a tela e o Esc não faz nada; se a
##     troca falhar antes de mudar qualquer coisa, a tela mostra o erro e continua como estava;
##   - as teclas de segurança (Ctrl+Shift+D e F11) funcionam aqui: o jogo que as trata está pausado.

var _aberta: bool = false
var _ocupado: bool = false
var _acao_pendente: StringName = &""
var _ultima_acao: StringName = &""
var _origem_modal: Control = null
var _foco_do_jogo: Control = null
## A coluna de botões da cena (o que perde o foco enquanto um painel está por cima). Cada cena a define antes de `_refs_base_ok()`.
var _painel_principal: Control = null

@onready var _confirmacao: PainelConfirmacao = %PainelConfirmacao
@onready var _indicador: IndicadorCarregamento = %IndicadorCarregamento
@onready var _linha_status: Control = %LinhaStatus
@onready var _icone_status: Label = %IconeStatus
@onready var _rot_status: Label = %MensagemStatus


func esta_aberta() -> bool:
	return _aberta


# ------------------------------------------------------------------ o que cada tela define
## Botões da coluna principal, de cima para baixo. Servem ao anel de foco e ao bloqueio durante a troca de cena.
func _botoes() -> Array:
	return []


## De onde a tela chama a fachada de sessão (define quais pontos de carga valem).
func _origem_sessao() -> Sessao.Origem:
	return Sessao.Origem.PAUSA


## Botão que originou cada ação (para devolver o foco depois de cancelar ou de uma falha).
func _botao_da_acao(_acao: StringName) -> Button:
	return null


## Há outro painel aberto por cima dos botões (ex.: as opções)? A confirmação já é conferida aqui.
func _painel_extra_aberto() -> bool:
	return false


## Reaplica o que depende do estado do jogo (ex.: Salvar só com o jogo ativo) quando a camada abre ou uma troca falha.
func _atualizar_estado_dos_botoes() -> void:
	pass


func _refs_base_ok() -> bool:
	return UiKit.refs_ok(self, {"painel principal": _painel_principal, "PainelConfirmacao": _confirmacao, "IndicadorCarregamento": _indicador, "LinhaStatus": _linha_status, "IconeStatus": _icone_status, "MensagemStatus": _rot_status})


func _exit_tree() -> void:
	# Saída de segurança: se a camada sair da árvore ainda aberta (cena trocada por fora), o jogo nunca fica pausado.
	if _aberta:
		_aberta = false
		_travar_o_resto(false)
		get_tree().paused = false


## Ctrl+Shift+D (modo conforto) e F11 (tela cheia) valem em qualquer tela, inclusive aqui. Só age com a camada aberta: fechada,
## ela também "processa" quando OUTRA camada pausa a árvore, e a tecla seria tratada duas vezes.
func _input(evento: InputEvent) -> void:
	if not _aberta:
		return
	if evento.is_action_pressed("nexus_forcar_desativar"):
		get_viewport().set_input_as_handled()
		GerenciadorConfiguracoes.ativar_modo_conforto()
	elif evento.is_action_pressed("nexus_tela_cheia"):
		get_viewport().set_input_as_handled()
		GerenciadorConfiguracoes.alternar_tela_cheia()


# ------------------------------------------------------------------ abrir e fechar
## Mostra a camada e pausa o jogo. O foco que o jogo tinha é guardado para ser devolvido ao fechar.
func _abrir_camada() -> void:
	_foco_do_jogo = get_viewport().gui_get_focus_owner()
	_travar_o_resto(true)
	_limpar_status()
	_atualizar_estado_dos_botoes()
	_ligar_foco()
	_aberta = true
	visible = true
	get_tree().paused = true


## Esconde a camada, despausa o jogo e devolve o foco ao que o tinha antes de abrir.
func _fechar_camada() -> void:
	_confirmacao.fechar()
	_aberta = false
	visible = false
	_travar_o_resto(false)
	get_tree().paused = false
	var destino: Control = _foco_do_jogo
	_foco_do_jogo = null
	if destino != null and is_instance_valid(destino) and destino.is_visible_in_tree() and destino.focus_mode != Control.FOCUS_NONE:
		destino.call_deferred("grab_focus")


## O jogo por trás (tudo o que está ao lado desta camada na cena dona) não pode receber foco enquanto ela está aberta: a navegação por
## Tab/setas procura candidatos em toda a cena, não só na camada, e levaria o foco para botões que estão pausados e escondidos.
func _travar_o_resto(travar: bool) -> void:
	var pai: Node = get_parent()
	if pai == null:
		return
	for irmao in pai.get_children():
		if irmao != self:
			UiKit.travar_foco(irmao, travar)


# ------------------------------------------------------------------ avisos, bloqueio e foco
## Aviso na própria camada. O estado de erro não depende só da cor: tem ícone próprio (⚠) além do texto.
func _mostrar_status(texto: String, erro: bool) -> void:
	_icone_status.text = "⚠" if erro else "ℹ"
	_icone_status.theme_type_variation = &"RotuloPerigo" if erro else &"RotuloFraco"
	_rot_status.theme_type_variation = &"RotuloPerigo" if erro else &"RotuloFraco"
	_rot_status.text = texto
	_linha_status.visible = texto != ""


func _limpar_status() -> void:
	_rot_status.text = ""
	_linha_status.visible = false


## Durante uma troca de cena: botões desativados e o indicador de carregamento cobrindo (e bloqueando) a tela.
func _definir_ocupado(ocupado: bool, texto: String = "") -> void:
	_ocupado = ocupado
	for item in _botoes():
		var botao: Button = item as Button
		if botao != null:
			botao.disabled = ocupado
	if ocupado:
		_indicador.mostrar(texto)
	else:
		_atualizar_estado_dos_botoes()
		_indicador.ocultar()
	_ligar_foco()


func _ligar_foco() -> void:
	UiKit.ligar_foco_circular(_botoes())


func _modal_aberto() -> bool:
	return _confirmacao.esta_aberto()


## Há algo que impede uma nova ação (troca em curso ou outro painel aberto)?
func _bloqueado() -> bool:
	return _ocupado or _modal_aberto() or _painel_extra_aberto()


## Abre um painel por cima da coluna principal: o que está atrás perde o foco (Tab/setas não vazam) até o painel fechar.
func _abrir_modal(origem: Control) -> void:
	_origem_modal = origem
	UiKit.travar_foco(_painel_principal, true)


func _fechar_modal() -> void:
	UiKit.travar_foco(_painel_principal, false)
	_ligar_foco()
	var origem: Control = _origem_modal
	_origem_modal = null
	if origem != null:
		_devolver_foco.call_deferred(origem)


## Devolve o foco ao botão que abriu o painel, a não ser que uma troca de cena já tenha começado (aí o foco é do indicador).
func _devolver_foco(destino: Control) -> void:
	if _ocupado or not _aberta or destino == null or not is_instance_valid(destino) or destino.focus_mode == Control.FOCUS_NONE:
		return
	var botao: BaseButton = destino as BaseButton
	if botao != null and botao.disabled:
		return
	destino.grab_focus()


# ------------------------------------------------------------------ as três ações de sessão (comuns às duas telas)
func _perguntar(acao: StringName, botao: Button, texto: String, rotulo_confirmar: String) -> void:
	_acao_pendente = acao
	_abrir_modal(botao)
	_confirmacao.perguntar(texto, rotulo_confirmar, "Cancelar", true)


## Carregar o salvamento anterior: sem ponto de carga válido só avisa; com ele, pergunta antes de descartar o progresso atual.
func _iniciar_carga(botao: Button) -> void:
	if _bloqueado():
		return
	SistemaAudio.tocar_sfx("clique", -8.0)
	_limpar_status()
	var origem: Sessao.Origem = _origem_sessao()
	if not bool(Sessao.ponto_de_carga(origem).get("existe", false)):
		_mostrar_status(Sessao.mensagem_sem_ponto(origem), false)
		return
	_perguntar(&"carregar", botao, Sessao.TEXTO_CONFIRMAR_CARGA, "Carregar")


## Recomeçar: a campanha volta ao Dia 1 e o salvamento é substituído; o texto da pergunta diz isso com todas as letras.
func _iniciar_recomeco(botao: Button) -> void:
	if _bloqueado():
		return
	SistemaAudio.tocar_sfx("clique", -8.0)
	_limpar_status()
	_perguntar(&"recomecar", botao, Sessao.TEXTO_CONFIRMAR_RECOMECAR, "Recomeçar")


func _iniciar_menu(botao: Button) -> void:
	if _bloqueado():
		return
	SistemaAudio.tocar_sfx("clique", -8.0)
	_limpar_status()
	_perguntar(&"menu", botao, Sessao.TEXTO_CONFIRMAR_MENU, "Retornar")


# ------------------------------------------------------------------ respostas da confirmação (ligadas na cena)
func _ao_confirmado() -> void:
	var acao: StringName = _acao_pendente
	_acao_pendente = &""
	_fechar_modal()
	if acao != &"":
		_ultima_acao = acao
		_executar_acao(acao)


func _ao_cancelado() -> void:
	_acao_pendente = &""
	_fechar_modal()


func _ao_painel_fechado() -> void:
	_fechar_modal()


## Executa a ação já confirmada. A fachada confere tudo o que pode falhar antes de mexer no jogo; se a troca for recusada ou
## falhar, `_ao_falha_de_troca` devolve a tela ao estado de antes (o jogo continua pausado, aqui, como estava).
func _executar_acao(acao: StringName) -> void:
	var aceito: bool = false
	match acao:
		&"carregar":
			_definir_ocupado(true, "Restaurando a sessão…")
			aceito = Sessao.carregar(get_tree(), _origem_sessao(), _ao_falha_de_troca)
		&"recomecar":
			_definir_ocupado(true, "Reiniciando o jogo…")
			aceito = Sessao.recomecar(get_tree(), _ao_falha_de_troca)
		&"menu":
			_definir_ocupado(true, "Voltando ao menu…")
			aceito = Sessao.voltar_ao_menu(get_tree(), _ao_falha_de_troca)
		_:
			return
	if not aceito:
		_ao_falha_de_troca("recusado")


func _ao_falha_de_troca(_motivo: String) -> void:
	if not _aberta:
		return
	_definir_ocupado(false)
	_mostrar_status(Sessao.MSG_FALHA_CARGA if _ultima_acao == &"carregar" else Sessao.MSG_FALHA_TROCA, true)
	var destino: Button = _botao_da_acao(_ultima_acao)
	if destino != null:
		destino.call_deferred("grab_focus")
