class_name PopupNotificacao
extends PanelContainer
## Toast no canto superior direito. Um único _process conta o tempo (sem Timer); passar o mouse pausa a contagem.
## Clicar abre o app associado (se houver) e dispensa. O nível aparece em texto (INFO, ERRO...), não só em cor.
## Nada pisca: só um fade curto (desligado em "reduzir animações").
## A estrutura está em popup_notificacao.tscn; a borda do painel vem das variações de tema PainelToast* (TemaVariacoes)
## e aqui entram só o texto, as cores por nível e a contagem regressiva.

signal fechado(popup: PopupNotificacao)
signal abrir_pedido(app_id: String, id_notificacao: int)

var dados: Dictionary = {}
var _total: float = 6.0
var _restante: float = 6.0
var _fechando: bool = false

@onready var _icone: Label = %Icone
@onready var _tag: Label = %Tag
@onready var _hora: Label = %Hora
@onready var _titulo: Label = %Titulo
@onready var _corpo: Label = %Corpo
@onready var _dica: Label = %Dica
@onready var _barra: ColorRect = %Barra


static func cor_do_nivel(nivel: String) -> Color:
	match nivel:
		"ia":
			return TemaNexus.cor("acento")
		"aviso":
			return TemaNexus.cor("aviso")
		"erro", "critico":
			return TemaNexus.cor("perigo")
		"sucesso":
			return TemaNexus.cor("ok")
		_:
			return TemaNexus.cor("acento2")


static func tag_do_nivel(nivel: String) -> String:
	match nivel:
		"ia":
			return "MAYA"
		"aviso":
			return "AVISO"
		"erro":
			return "ERRO"
		"critico":
			return "CRÍTICO"
		"sucesso":
			return "OK"
		_:
			return "INFO"


static func icone_do_nivel(nivel: String) -> String:
	match nivel:
		"ia":
			return "◉"
		"aviso":
			return "⚠"
		"erro":
			return "✖"
		"critico":
			return "⛔"
		"sucesso":
			return "✔"
		_:
			return "ℹ"


## Variação de tema do painel (cor da borda) para o nível da notificação.
static func variacao_do_nivel(nivel: String) -> StringName:
	match nivel:
		"ia":
			return &"PainelToastIa"
		"aviso":
			return &"PainelToastAviso"
		"erro", "critico":
			return &"PainelToastErro"
		"sucesso":
			return &"PainelToastSucesso"
		_:
			return &"PainelToastInfo"


## Pode ser chamada antes ou depois de a cena entrar na árvore.
func configurar(n: Dictionary) -> void:
	dados = n
	_total = maxf(float(n.get("duracao", 6.0)), 2.0)
	_restante = _total
	if is_node_ready():
		_aplicar()


func _aplicar() -> void:
	var nivel: String = str(dados.get("nivel", "info"))
	var cor: Color = cor_do_nivel(nivel)
	theme_type_variation = variacao_do_nivel(nivel)
	_icone.text = icone_do_nivel(nivel)
	_icone.add_theme_color_override("font_color", cor)
	_tag.text = tag_do_nivel(nivel)
	_tag.add_theme_color_override("font_color", cor)
	_hora.text = str(dados.get("hora", ""))
	_titulo.text = str(dados.get("titulo", ""))
	_corpo.text = str(dados.get("texto", ""))
	_dica.visible = str(dados.get("abrir_app", "")) != ""
	_barra.color = Color(cor.r, cor.g, cor.b, 0.85)


func _ready() -> void:
	if not UiKit.refs_ok(self, {"Icone": _icone, "Tag": _tag, "Hora": _hora, "Titulo": _titulo, "Corpo": _corpo, "Dica": _dica, "Barra": _barra}):
		set_process(false)
		return
	if not dados.is_empty():
		_aplicar()
	if GerenciadorConfiguracoes.animacoes_permitidas():
		modulate.a = 0.0
		var t := create_tween()
		t.tween_property(self, "modulate:a", 1.0, 0.18)


func _process(delta: float) -> void:
	if _fechando:
		return
	var sobre := get_global_rect().has_point(get_global_mouse_position())
	if not sobre:
		_restante -= delta
	_barra.anchor_right = clampf(_restante / _total, 0.0, 1.0)
	if _restante <= 0.0:
		fechar()


func fechar() -> void:
	if _fechando:
		return
	_fechando = true
	set_process(false)
	if GerenciadorConfiguracoes.animacoes_permitidas() and is_inside_tree():
		var t := create_tween()
		t.tween_property(self, "modulate:a", 0.0, 0.18)
		t.tween_callback(_concluir)
	else:
		_concluir()


func _concluir() -> void:
	fechado.emit(self)
	queue_free()


# Conectado na cena: gui_input
func _ao_entrada(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		abrir_pedido.emit(str(dados.get("abrir_app", "")), int(dados.get("id", -1)))
		fechar()


# Conectado na cena: BotaoFechar.pressed
func _ao_fechar_botao() -> void:
	abrir_pedido.emit("", int(dados.get("id", -1)))
	fechar()
