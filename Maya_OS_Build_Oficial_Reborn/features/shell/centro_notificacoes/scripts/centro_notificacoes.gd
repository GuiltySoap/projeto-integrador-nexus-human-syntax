class_name CentroNotificacoes
extends Control
## Central de notificações: histórico (até 60), opção de silenciar pop-ups e atalhos para os apps.
## Abre acima da barra de tarefas, no canto direito. Esc ou clicar fora fecha. Ao abrir/fechar, tudo vira "lido".
## A estrutura (fundo, painel, cabeçalho, rolagem) está em centro_notificacoes.tscn; cada notificação do histórico é
## uma instância de cartao_notificacao.tscn (conteúdo dinâmico) dentro de %Lista.

signal aberto_alterado(aberto: bool)

## Item do histórico. Definido em centro_notificacoes.tscn.
@export var cena_cartao: PackedScene

var _cx := Conexoes.new()
var _aberto: bool = false
var _reconstruindo: bool = false

@onready var _rot_resumo: Label = %RotuloResumo
@onready var _chk_silenciar: CheckBox = %Silenciar
@onready var _lista: VBoxContainer = %Lista
@onready var _rot_vazio: Label = %RotuloVazio


func _ready() -> void:
	if not UiKit.refs_ok(self, {"RotuloResumo": _rot_resumo, "Silenciar": _chk_silenciar, "Lista": _lista, "RotuloVazio": _rot_vazio}):
		return
	_cx.ligar(SistemaNotificacoes.historico_alterado, _ao_historico)


func _exit_tree() -> void:
	if _aberto:
		GerenciadorJanelas.overlay_ativo = false
	_cx.desligar_tudo()


func _input(evento: InputEvent) -> void:
	if _aberto and evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		fechar()


func esta_aberto() -> bool:
	return _aberto


func alternar() -> void:
	if _aberto:
		fechar()
	else:
		abrir()


func abrir() -> void:
	if _aberto:
		return
	_aberto = true
	visible = true
	GerenciadorJanelas.overlay_ativo = true
	_chk_silenciar.set_pressed_no_signal(SistemaNotificacoes.silenciar_toasts)
	_reconstruir()
	_marcar_lidas()
	SistemaAudio.tocar_sfx("abrir")
	aberto_alterado.emit(true)


func fechar() -> void:
	if not _aberto:
		return
	_aberto = false
	visible = false
	GerenciadorJanelas.overlay_ativo = false
	_marcar_lidas()
	aberto_alterado.emit(false)


# ------------------------------------------------------------------ conteúdo dinâmico
func _reconstruir() -> void:
	_reconstruindo = true
	for filho in _lista.get_children():
		if filho != _rot_vazio:
			_lista.remove_child(filho)
			filho.queue_free()
	var historico: Array = SistemaNotificacoes.historico
	var novas: int = SistemaNotificacoes.nao_lidas()
	_rot_resumo.text = "%d no total · %d nova(s)" % [historico.size(), novas]
	_rot_vazio.visible = historico.is_empty()
	if cena_cartao == null:
		push_error("CentroNotificacoes: 'cena_cartao' não definida (veja centro_notificacoes.tscn).")
	else:
		for n in historico:
			var cartao: CartaoNotificacao = cena_cartao.instantiate() as CartaoNotificacao
			cartao.abrir_app_pedido.connect(_ao_abrir_app)
			_lista.add_child(cartao)
			cartao.configurar(n)
	_reconstruindo = false


func _marcar_lidas() -> void:
	_reconstruindo = true
	SistemaNotificacoes.marcar_todas_lidas()
	_reconstruindo = false


# ------------------------------------------------------------------ ações
func _ao_historico() -> void:
	if _aberto and not _reconstruindo:
		_reconstruir()


# Conectado na cena: Fora.gui_input
func _ao_clique_fora(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.pressed:
		fechar()


# Conectado na cena: BotaoLimpar.pressed
func _ao_limpar() -> void:
	SistemaNotificacoes.limpar_historico()


# Conectado na cena: Silenciar.toggled
func _ao_silenciar(ligado: bool) -> void:
	SistemaNotificacoes.silenciar_toasts = ligado


func _ao_abrir_app(app_id: String) -> void:
	fechar()
	GerenciadorJanelas.abrir_app(app_id)
