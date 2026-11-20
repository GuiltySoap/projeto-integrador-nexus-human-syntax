class_name PilhaToasts
extends Control
## Pilha de toasts no canto superior direito. No máximo 3 ao mesmo tempo (os demais esperam numa fila curta);
## avisos críticos furam a fila. Este nó é do shell, então é ele quem abre o app quando o jogador clica no toast.
## A cena (pilha_toasts.tscn) define o contêiner %Pilha; cada toast é uma instância de popup_notificacao.tscn
## (conteúdo dinâmico: um por notificação).

const MAX_SIMULTANEOS := 3
const MAX_FILA := 12

## Cena de um toast. Definida em pilha_toasts.tscn.
@export var cena_popup: PackedScene

var _cx := Conexoes.new()
var _fila: Array = []
var _ativos: int = 0

@onready var _pilha: VBoxContainer = %Pilha


func _ready() -> void:
	if not UiKit.refs_ok(self, {"Pilha": _pilha}):
		return
	_cx.ligar(SistemaNotificacoes.notificacao_emitida, _ao_notificacao)


func _exit_tree() -> void:
	_cx.desligar_tudo()


func limpar() -> void:
	_fila.clear()
	UiKit.limpar_filhos(_pilha)
	_ativos = 0


func _ao_notificacao(n: Dictionary) -> void:
	if not bool(n.get("exibir_toast", true)):
		return
	if _ativos >= MAX_SIMULTANEOS and str(n.get("nivel", "")) != "critico":
		if _fila.size() >= MAX_FILA:
			_fila.pop_front()
		_fila.append(n)
		return
	_mostrar(n)


func _mostrar(n: Dictionary) -> void:
	if cena_popup == null:
		push_error("PilhaToasts: 'cena_popup' não definida (veja pilha_toasts.tscn).")
		return
	var p: PopupNotificacao = cena_popup.instantiate() as PopupNotificacao
	if p == null:
		push_error("PilhaToasts: a cena do toast precisa ter o script PopupNotificacao na raiz.")
		return
	p.fechado.connect(_ao_fechado)
	p.abrir_pedido.connect(_ao_abrir_pedido)
	_pilha.add_child(p)
	p.configurar(n)
	_ativos += 1


func _ao_fechado(_popup: PopupNotificacao) -> void:
	_ativos = maxi(0, _ativos - 1)
	if not _fila.is_empty() and _ativos < MAX_SIMULTANEOS:
		var proxima: Dictionary = _fila.pop_front()
		_mostrar(proxima)


func _ao_abrir_pedido(app_id: String, id_notificacao: int) -> void:
	SistemaNotificacoes.marcar_lida(id_notificacao)
	if app_id != "":
		GerenciadorJanelas.abrir_app(app_id)
