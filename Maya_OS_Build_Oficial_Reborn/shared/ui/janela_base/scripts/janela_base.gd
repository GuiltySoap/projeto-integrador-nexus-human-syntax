class_name JanelaBase
extends Control
## Janela do sistema operacional simulado: barra de título, minimizar/maximizar/fechar, arrastar,
## redimensionar pelas bordas, limites de tela, tamanho mínimo e restauração do tamanho.
## A janela nunca se destrói sozinha: ela emite pedido_* e o GerenciadorJanelas decide (foco, bloqueios narrativos).
##
## A estrutura visual (fundo, barra de título, botões, área de conteúdo e as 8 alças de redimensionar) está em
## janela_base.tscn e pode ser editada no Godot; as conexões de sinais dos botões, da barra e das alças também
## estão na cena. Este script cuida só do comportamento. O conteúdo (um AppBase) é inserido em %Area.
## As aparências ativa/inativa são "type variations" do Theme (PainelJanela, BarraJanela...), alternadas aqui.

signal pedido_fechar(janela: JanelaBase)
signal pedido_minimizar(janela: JanelaBase)
signal maximizada_alterada(janela: JanelaBase, esta_maximizada: bool)
signal movida(janela: JanelaBase)
signal redimensionada(janela: JanelaBase)

const ALTURA_BARRA := 38  ## usada só se %Barra ainda não tiver altura; o valor real é o da barra na cena
const MARGEM_VISIVEL := 90.0

@export var titulo: String = "Janela":
	set(valor):
		titulo = valor
		if is_node_ready():
			_rotulo_titulo.text = valor
@export var tamanho_min: Vector2 = Vector2(320, 220)
@export var pode_maximizar: bool = true

var app_id: String = ""
var pid: int = 0
var info: Dictionary = {}
var maximizada: bool = false
var minimizada: bool = false
var ativa: bool = false
var conteudo: Control = null

var _rect_restaurar: Rect2 = Rect2()
var _arrastando: bool = false
var _offset_arraste: Vector2 = Vector2.ZERO
var _redimensionando: Vector2i = Vector2i.ZERO
var _rect_origem: Rect2 = Rect2()
var _mouse_origem: Vector2 = Vector2.ZERO
var _tween_tremor: Tween
var _tween_titulo: Tween

@onready var _fundo: Panel = %Fundo
@onready var _barra: Panel = %Barra
@onready var _rotulo_titulo: Label = %RotuloTitulo
@onready var _icone_app: IconeApp = %IconeApp
@onready var _btn_max: Button = %BotaoMaximizar
@onready var _icone_max: IconeBotao = %IconeMaximizar
@onready var _area: Control = %Area
@onready var _alcas: Control = %Alcas


func _ready() -> void:
	if _fundo == null or _barra == null or _rotulo_titulo == null or _area == null or _alcas == null:
		push_error("JanelaBase: a cena está incompleta (faltam nós únicos como %Fundo, %Barra, %RotuloTitulo, %Area ou %Alcas).")
		return
	set_process(false)
	custom_minimum_size = tamanho_min
	_rotulo_titulo.text = titulo
	_aplicar_estilo()
	_atualizar_botao_max()


func _process(_delta: float) -> void:
	# Segurança: se o botão do mouse foi solto fora da janela do jogo, encerra o arraste/redimensionamento.
	if (_arrastando or _redimensionando != Vector2i.ZERO) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_parar_interacao()


# ------------------------------------------------------------------ API
func configurar(dados_app: Dictionary, no_conteudo: Control, tamanho_inicial: Vector2, posicao_inicial: Vector2) -> void:
	info = dados_app
	app_id = str(dados_app.get("id", ""))
	var t_min: Variant = dados_app.get("tamanho_min", [320, 220])
	if t_min is Array and t_min.size() >= 2:
		tamanho_min = Vector2(float(t_min[0]), float(t_min[1]))
	custom_minimum_size = tamanho_min
	definir_titulo(str(dados_app.get("nome", "Janela")))
	var area := get_parent_area_size()
	var tam := Vector2(maxf(tamanho_inicial.x, tamanho_min.x), maxf(tamanho_inicial.y, tamanho_min.y))
	if area.x > 0.0 and area.y > 0.0:
		tam = Vector2(minf(tam.x, maxf(area.x, tamanho_min.x)), minf(tam.y, maxf(area.y, tamanho_min.y)))
	size = tam
	position = limitar_posicao(posicao_inicial)
	pivot_offset = size / 2.0
	_montar_conteudo(no_conteudo)
	_icone_app.configurar(info, 22)
	_animar_abertura()


func definir_titulo(novo: String) -> void:
	titulo = novo


func definir_ativa(valor: bool) -> void:
	if ativa == valor:
		return
	ativa = valor
	_aplicar_estilo()


func definir_minimizada(valor: bool) -> void:
	minimizada = valor
	visible = not valor


func alternar_maximizar() -> void:
	if not pode_maximizar:
		return
	if maximizada:
		maximizada = false
		size = Vector2(maxf(_rect_restaurar.size.x, tamanho_min.x), maxf(_rect_restaurar.size.y, tamanho_min.y))
		position = limitar_posicao(_rect_restaurar.position)
	else:
		_rect_restaurar = Rect2(position, size)
		maximizada = true
		position = Vector2.ZERO
		size = get_parent_area_size()
	_atualizar_botao_max()
	_alcas.visible = not maximizada
	maximizada_alterada.emit(self, maximizada)


## Reajusta a janela depois que a área disponível mudou (tela cheia, redimensionamento da janela do jogo).
func reajustar() -> void:
	var area := get_parent_area_size()
	if area.x <= 0.0 or area.y <= 0.0:
		return
	if maximizada:
		position = Vector2.ZERO
		size = area
		return
	size = Vector2(minf(size.x, maxf(area.x, tamanho_min.x)), minf(size.y, maxf(area.y, tamanho_min.y)))
	position = limitar_posicao(position)


## Mantém a barra de título sempre alcançável (nenhuma janela pode "sumir" da tela).
func limitar_posicao(pos: Vector2) -> Vector2:
	var area := get_parent_area_size()
	if area.x <= 0.0 or area.y <= 0.0:
		return pos
	var x := clampf(pos.x, -size.x + MARGEM_VISIVEL, maxf(area.x - MARGEM_VISIVEL, 0.0))
	var y := clampf(pos.y, 0.0, maxf(area.y - _altura_barra(), 0.0))
	return Vector2(x, y)


func tremer() -> void:
	if not GerenciadorConfiguracoes.tremor_permitido() or maximizada:
		_pulsar_borda()
		return
	if _tween_tremor != null and _tween_tremor.is_valid():
		_tween_tremor.kill()
	var origem_x := position.x
	_tween_tremor = create_tween()
	for dx in [10.0, -10.0, 6.0, -6.0, 0.0]:
		_tween_tremor.tween_property(self, "position:x", origem_x + float(dx), 0.04)


func glitch_titulo(duracao: float = 0.8) -> void:
	if not GerenciadorConfiguracoes.glitch_permitido() or _rotulo_titulo == null:
		return
	if _tween_titulo != null and _tween_titulo.is_valid():
		_tween_titulo.kill()
	_tween_titulo = create_tween()
	var passos := maxi(2, int(duracao / 0.12))
	for i in passos:
		_tween_titulo.tween_callback(_embaralhar_titulo.bind(i))
		_tween_titulo.tween_interval(0.12)
	_tween_titulo.tween_callback(_restaurar_titulo)


## O Theme é reaplicado na raiz e as variações se atualizam sozinhas; isto só reaplica o estado da janela.
func atualizar_tema() -> void:
	_aplicar_estilo()
	_atualizar_botao_max()


func solicitar_fechar() -> void:
	pedido_fechar.emit(self)


func solicitar_minimizar() -> void:
	pedido_minimizar.emit(self)


## Destruição final (somente o GerenciadorJanelas chama).
func destruir() -> void:
	_parar_interacao()
	if _tween_tremor != null and _tween_tremor.is_valid():
		_tween_tremor.kill()
	if _tween_titulo != null and _tween_titulo.is_valid():
		_tween_titulo.kill()
	queue_free()


# ------------------------------------------------------------------ conteúdo e aparência
func _montar_conteudo(no_conteudo: Control) -> void:
	if no_conteudo == null or _area == null:
		return
	conteudo = no_conteudo
	_area.add_child(no_conteudo)
	no_conteudo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _altura_barra() -> float:
	if _barra != null and _barra.custom_minimum_size.y > 0.0:
		return _barra.custom_minimum_size.y
	return float(ALTURA_BARRA)


## Alterna as variações do Theme conforme a janela esteja ativa (foco) ou não.
func _aplicar_estilo() -> void:
	if _fundo == null or _barra == null or _rotulo_titulo == null:
		return
	_fundo.theme_type_variation = &"PainelJanelaAtiva" if ativa else &"PainelJanela"
	_barra.theme_type_variation = &"BarraJanelaAtiva" if ativa else &"BarraJanela"
	_rotulo_titulo.theme_type_variation = &"" if ativa else &"RotuloFraco"


func _atualizar_botao_max() -> void:
	if _btn_max == null or _icone_max == null:
		return
	_icone_max.definir_tipo("restaurar" if maximizada else "max")
	_btn_max.tooltip_text = "Restaurar" if maximizada else "Maximizar"
	_btn_max.disabled = not pode_maximizar


func _animar_abertura() -> void:
	if not GerenciadorConfiguracoes.animacoes_permitidas():
		return
	scale = Vector2(0.94, 0.94)
	modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.12)


func _pulsar_borda() -> void:
	if _fundo == null:
		return
	var tween := create_tween()
	_fundo.modulate = Color(1.0, 0.7, 0.7)
	tween.tween_property(_fundo, "modulate", Color(1, 1, 1), 0.5)


func _embaralhar_titulo(quadro: int = 0) -> void:
	if _rotulo_titulo != null:
		_rotulo_titulo.text = UtilTexto.corromper(titulo, 0.35, quadro)


func _restaurar_titulo() -> void:
	if _rotulo_titulo != null:
		_rotulo_titulo.text = titulo


# ------------------------------------------------------------------ entrada (conectada na cena)
func _ao_barra_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		if evento.pressed:
			if evento.double_click:
				alternar_maximizar()
				_parar_interacao()
				return
			if not maximizada:
				_arrastando = true
				_offset_arraste = get_global_mouse_position() - global_position
				set_process(true)
		else:
			_parar_interacao()
	elif evento is InputEventMouseMotion and _arrastando and not maximizada:
		var alvo := get_global_mouse_position() - _offset_arraste
		# global -> local do pai: a camada de janelas não é escalada, então basta subtrair a origem dela.
		var pai := get_parent() as Control
		var origem_pai := pai.global_position if pai != null else Vector2.ZERO
		position = limitar_posicao(alvo - origem_pai)
		movida.emit(self)


## "dir" vem do bind declarado na cena em cada alça (ex.: AlcaNoroeste = Vector2i(-1, -1)).
func _ao_alca_input(evento: InputEvent, dir: Vector2i) -> void:
	if maximizada:
		return
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		if evento.pressed:
			_redimensionando = dir
			_rect_origem = Rect2(position, size)
			_mouse_origem = get_global_mouse_position()
			set_process(true)
		else:
			_parar_interacao()
	elif evento is InputEventMouseMotion and _redimensionando != Vector2i.ZERO:
		var delta := get_global_mouse_position() - _mouse_origem
		_aplicar_redimensionamento(delta)


func _aplicar_redimensionamento(delta: Vector2) -> void:
	var area := get_parent_area_size()
	var pos := _rect_origem.position
	var tam := _rect_origem.size
	var d := _redimensionando
	if d.x == 1:
		tam.x = _rect_origem.size.x + delta.x
	elif d.x == -1:
		tam.x = _rect_origem.size.x - delta.x
		pos.x = _rect_origem.position.x + delta.x
	if d.y == 1:
		tam.y = _rect_origem.size.y + delta.y
	elif d.y == -1:
		tam.y = _rect_origem.size.y - delta.y
		pos.y = _rect_origem.position.y + delta.y
	# Tamanho mínimo (mantendo a borda oposta fixa).
	if tam.x < tamanho_min.x:
		if d.x == -1:
			pos.x -= tamanho_min.x - tam.x
		tam.x = tamanho_min.x
	if tam.y < tamanho_min.y:
		if d.y == -1:
			pos.y -= tamanho_min.y - tam.y
		tam.y = tamanho_min.y
	# Limites da área: nada de redimensionar para fora da tela.
	if pos.y < 0.0:
		tam.y += pos.y
		pos.y = 0.0
	if area.x > 0.0 and pos.x + tam.x > area.x and d.x == 1:
		tam.x = maxf(tamanho_min.x, area.x - pos.x)
	if area.y > 0.0 and pos.y + tam.y > area.y and d.y == 1:
		tam.y = maxf(tamanho_min.y, area.y - pos.y)
	position = pos
	size = tam
	redimensionada.emit(self)


func _parar_interacao() -> void:
	_arrastando = false
	_redimensionando = Vector2i.ZERO
	set_process(false)


func _ao_redimensionar() -> void:
	pivot_offset = size / 2.0


func _ao_minimizar_pressionado() -> void:
	pedido_minimizar.emit(self)


func _ao_maximizar_pressionado() -> void:
	alternar_maximizar()


func _ao_fechar_pressionado() -> void:
	pedido_fechar.emit(self)
