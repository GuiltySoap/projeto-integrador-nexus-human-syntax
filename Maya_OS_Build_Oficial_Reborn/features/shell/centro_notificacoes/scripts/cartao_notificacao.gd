class_name CartaoNotificacao
extends PanelContainer
## Uma notificação no histórico da central. Item reutilizável (cartao_notificacao.tscn): a central instancia um por
## notificação. Aqui entram só o texto, a cor do nível e o botão "Abrir <app>".

signal abrir_app_pedido(app_id: String)

var _dados: Dictionary = {}
var _app_id: String = ""

@onready var _tag: Label = %Tag
@onready var _nova: Label = %Nova
@onready var _hora: Label = %Hora
@onready var _titulo: Label = %Titulo
@onready var _corpo: Label = %Corpo
@onready var _botao_abrir: Button = %BotaoAbrir


func _ready() -> void:
	if not UiKit.refs_ok(self, {"Tag": _tag, "Nova": _nova, "Hora": _hora, "Titulo": _titulo, "Corpo": _corpo, "BotaoAbrir": _botao_abrir}):
		return
	_aplicar()


## n: item de SistemaNotificacoes.historico. Pode ser chamada antes ou depois de a cena entrar na árvore.
func configurar(n: Dictionary) -> void:
	_dados = n
	if is_node_ready():
		_aplicar()


func _aplicar() -> void:
	if _dados.is_empty():
		return
	var nivel: String = str(_dados.get("nivel", "info"))
	_tag.text = PopupNotificacao.tag_do_nivel(nivel)
	_tag.add_theme_color_override("font_color", PopupNotificacao.cor_do_nivel(nivel))
	_nova.visible = not bool(_dados.get("lida", false))
	_hora.text = str(_dados.get("hora", ""))
	_titulo.text = str(_dados.get("titulo", ""))
	_corpo.text = str(_dados.get("texto", ""))
	_app_id = str(_dados.get("abrir_app", ""))
	_botao_abrir.visible = _app_id != ""
	if _app_id != "":
		var nome_app: String = str(GerenciadorJanelas.app_info(_app_id).get("nome", _app_id))
		_botao_abrir.text = "Abrir %s" % nome_app


# Conectado na cena: BotaoAbrir.pressed
func _ao_abrir() -> void:
	abrir_app_pedido.emit(_app_id)
