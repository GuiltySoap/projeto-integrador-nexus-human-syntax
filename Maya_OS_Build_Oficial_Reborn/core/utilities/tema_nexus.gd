class_name TemaNexus
extends RefCounted
## Paletas por dia narrativo e construção do Theme em código.
## Em execução, o Theme é aplicado na janela raiz (get_tree().root.theme), então vale para toda a interface (dia narrativo,
## contraste e tamanho de texto). Para o EDITOR mostrar as cenas com as mesmas aparências, o projeto aponta (Project Settings >
## GUI > Theme > Custom) para res://shared/theme/tema_nexus_base.tres: uma cópia do dia 1 gravada por
## tests/exportar_tema/exportar_tema.tscn. Regrave-a quando mudar este arquivo ou tema_variacoes.gd.

static var dia_atual: int = 1
static var _paletas_cache: Dictionary = {}
static var _fonte_mono: Font = null
static var _fonte_ui: Font = null

const ACENTOS_MANUAIS := {"roxo": "#8b5cf6", "azul": "#38bdf8", "verde": "#4ade80"}


static func _def(fundo: String, painel: String, acento: String, acento2: String, texto: String, fraco: String, perigo: String) -> Dictionary:
	return {
		"fundo": Color.html(fundo), "painel": Color.html(painel), "acento": Color.html(acento), "acento2": Color.html(acento2),
		"texto": Color.html(texto), "texto_fraco": Color.html(fraco), "perigo": Color.html(perigo),
		"ok": Color.html("#4ade80"), "aviso": Color.html("#fbbf24"),
	}


static func _paletas() -> Dictionary:
	if _paletas_cache.is_empty():
		_paletas_cache = {
			1: _def("#0b0a1a", "#15132c", "#8b5cf6", "#38bdf8", "#ece9ff", "#9a96c4", "#fb7185"),
			2: _def("#080d1a", "#101a30", "#38bdf8", "#6366f1", "#e6f1ff", "#8fa5c8", "#fb7185"),
			3: _def("#12091a", "#1d1028", "#e11d48", "#a855f7", "#f6e9ff", "#b497c4", "#fb7185"),
			4: _def("#0a0506", "#1a0c0e", "#ef4444", "#f97316", "#ffe9e9", "#c49a9a", "#ff5c5c"),
			5: _def("#050505", "#0d0d0d", "#ef4444", "#22c55e", "#e8ffe8", "#8fb48f", "#ff3b3b"),
		}
	return _paletas_cache


## Etapa do roteiro (1 a 9) -> paleta (1 a 5): o jogo não tem dias; a paleta acompanha o avanço das Tasks.
static func definir_etapa(etapa: int) -> void:
	definir_dia(clampi(ceili(etapa / 2.0), 1, 5))


static func definir_dia(d: int) -> void:
	dia_atual = clampi(d, 1, 5)


## Paleta efetiva: dia narrativo + preferências do jogador (tema manual e alto contraste).
static func paleta() -> Dictionary:
	var p: Dictionary = _paletas()[dia_atual].duplicate()
	var tema := str(GerenciadorConfiguracoes.obter("tema"))
	if ACENTOS_MANUAIS.has(tema):
		p["acento"] = Color.html(ACENTOS_MANUAIS[tema])
	if bool(GerenciadorConfiguracoes.obter("alto_contraste")):
		p["fundo"] = Color(0, 0, 0)
		p["painel"] = Color(0.04, 0.04, 0.04)
		p["texto"] = Color(1, 1, 1)
		p["texto_fraco"] = Color(0.85, 0.85, 0.85)
		p["acento"] = Color.html("#ffd400")
		p["acento2"] = Color.html("#00e5ff")
		p["perigo"] = Color.html("#ff5252")
	var a: Color = p["acento"]
	p["borda"] = Color(a.r, a.g, a.b, 0.55 if not bool(GerenciadorConfiguracoes.obter("alto_contraste")) else 1.0)
	var pn: Color = p["painel"]
	p["vidro"] = Color(pn.r, pn.g, pn.b, 0.90 if not bool(GerenciadorConfiguracoes.obter("alto_contraste")) else 1.0)
	return p


static func cor(nome: String) -> Color:
	return paleta().get(nome, Color.WHITE)


static func caixa(bg: Color, borda: Color = Color(0, 0, 0, 0), raio: int = 8, borda_larg: int = 1, margem_h: float = 10.0, margem_v: float = 6.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = borda
	sb.set_border_width_all(borda_larg if borda.a > 0.0 else 0)
	sb.set_corner_radius_all(raio)
	sb.content_margin_left = margem_h
	sb.content_margin_right = margem_h
	sb.content_margin_top = margem_v
	sb.content_margin_bottom = margem_v
	return sb


static func fonte_mono() -> Font:
	if _fonte_mono == null:
		if ResourceLoader.exists("res://shared/assets/fonts/mono.ttf"):
			_fonte_mono = load("res://shared/assets/fonts/mono.ttf")
		else:
			var f := SystemFont.new()
			f.font_names = PackedStringArray(["Cascadia Mono", "JetBrains Mono", "Consolas", "DejaVu Sans Mono", "Menlo", "Courier New", "monospace"])
			_fonte_mono = f
	return _fonte_mono


static func fonte_ui() -> Font:
	if _fonte_ui == null and ResourceLoader.exists("res://shared/assets/fonts/ui.ttf"):
		_fonte_ui = load("res://shared/assets/fonts/ui.ttf")
	return _fonte_ui


static func aplicar(arvore: SceneTree) -> void:
	arvore.root.theme = criar_tema()


static func _btn(t: Theme, tipo: String, bg: Color, hover: Color, press: Color, borda: Color, texto: Color, raio: int = 6) -> void:
	t.set_stylebox("normal", tipo, caixa(bg, borda, raio))
	t.set_stylebox("hover", tipo, caixa(hover, borda, raio))
	t.set_stylebox("pressed", tipo, caixa(press, borda, raio))
	t.set_stylebox("hover_pressed", tipo, caixa(press, borda, raio))
	t.set_stylebox("disabled", tipo, caixa(Color(bg.r, bg.g, bg.b, bg.a * 0.45), Color(borda.r, borda.g, borda.b, borda.a * 0.4), raio))
	var foco := caixa(Color(0, 0, 0, 0), cor("acento2"), raio, 2)
	foco.draw_center = false
	t.set_stylebox("focus", tipo, foco)
	t.set_color("font_color", tipo, texto)
	t.set_color("font_hover_color", tipo, texto)
	t.set_color("font_pressed_color", tipo, texto)
	t.set_color("font_hover_pressed_color", tipo, texto)
	t.set_color("font_focus_color", tipo, texto)
	t.set_color("font_disabled_color", tipo, Color(texto.r, texto.g, texto.b, 0.4))


static func criar_tema() -> Theme:
	var p := paleta()
	var t := Theme.new()
	var escala := float(GerenciadorConfiguracoes.obter("tamanho_texto"))
	t.default_font_size = int(round(15.0 * escala))
	if fonte_ui() != null:
		t.default_font = fonte_ui()
	var texto: Color = p["texto"]
	var fraco: Color = p["texto_fraco"]
	var acento: Color = p["acento"]
	var acento2: Color = p["acento2"]
	var perigo: Color = p["perigo"]
	var borda: Color = p["borda"]
	var painel: Color = p["painel"]
	var borda_suave := Color(1, 1, 1, 0.10)
	var vazio := StyleBoxEmpty.new()

	# Labels e texto rico
	t.set_color("font_color", "Label", texto)
	t.set_color("default_color", "RichTextLabel", texto)
	t.set_color("selection_color", "RichTextLabel", Color(acento.r, acento.g, acento.b, 0.45))
	t.set_stylebox("normal", "RichTextLabel", vazio)
	t.set_stylebox("focus", "RichTextLabel", vazio)
	if fonte_mono() != null:
		t.set_font("mono_font", "RichTextLabel", fonte_mono())
	t.set_type_variation("RotuloFraco", "Label")
	t.set_color("font_color", "RotuloFraco", fraco)
	t.set_type_variation("RotuloTitulo", "Label")
	t.set_color("font_color", "RotuloTitulo", texto)
	t.set_font_size("font_size", "RotuloTitulo", int(round(22.0 * escala)))
	t.set_type_variation("RotuloAcento", "Label")
	t.set_color("font_color", "RotuloAcento", acento2)
	t.set_type_variation("RotuloPerigo", "Label")
	t.set_color("font_color", "RotuloPerigo", perigo)
	t.set_type_variation("RotuloMono", "Label")
	t.set_color("font_color", "RotuloMono", texto)
	if fonte_mono() != null:
		t.set_font("font", "RotuloMono", fonte_mono())
	# Variações geradas por tabela (rótulos por tamanho/estilo, painéis usados pelas cenas): tema_variacoes.gd
	TemaVariacoes.registrar(t, p, escala, fonte_mono())

	# Botões
	var fundo_btn := Color(1, 1, 1, 0.07)
	_btn(t, "Button", fundo_btn, Color(acento.r, acento.g, acento.b, 0.28), Color(acento.r, acento.g, acento.b, 0.50), borda_suave, texto)
	t.set_type_variation("BotaoPrimario", "Button")
	_btn(t, "BotaoPrimario", Color(acento.r, acento.g, acento.b, 0.55), Color(acento.r, acento.g, acento.b, 0.75), Color(acento.r, acento.g, acento.b, 0.95), borda, Color(1, 1, 1))
	t.set_type_variation("BotaoPerigo", "Button")
	_btn(t, "BotaoPerigo", Color(perigo.r, perigo.g, perigo.b, 0.30), Color(perigo.r, perigo.g, perigo.b, 0.55), Color(perigo.r, perigo.g, perigo.b, 0.80), Color(perigo.r, perigo.g, perigo.b, 0.7), Color(1, 1, 1))
	t.set_type_variation("BotaoPlano", "Button")
	_btn(t, "BotaoPlano", Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.10), Color(acento.r, acento.g, acento.b, 0.35), Color(0, 0, 0, 0), texto, 4)
	t.set_type_variation("BotaoJanela", "Button")
	_btn(t, "BotaoJanela", Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.14), Color(1, 1, 1, 0.24), Color(0, 0, 0, 0), texto, 4)
	t.set_type_variation("BotaoFechar", "Button")
	_btn(t, "BotaoFechar", Color(1, 1, 1, 0.0), Color(perigo.r, perigo.g, perigo.b, 0.80), Color(perigo.r, perigo.g, perigo.b, 1.0), Color(0, 0, 0, 0), texto, 4)
	t.set_type_variation("BotaoTarefa", "Button")
	_btn(t, "BotaoTarefa", Color(1, 1, 1, 0.05), Color(1, 1, 1, 0.14), Color(acento.r, acento.g, acento.b, 0.35), Color(0, 0, 0, 0), texto, 8)
	t.set_type_variation("BotaoTarefaAtivo", "Button")
	_btn(t, "BotaoTarefaAtivo", Color(acento.r, acento.g, acento.b, 0.32), Color(acento.r, acento.g, acento.b, 0.45), Color(acento.r, acento.g, acento.b, 0.55), borda, texto, 8)

	# CheckBox / CheckButton (sem fundo de botão)
	for tipo in ["CheckBox", "CheckButton"]:
		for nome in ["normal", "pressed", "hover", "hover_pressed", "disabled"]:
			t.set_stylebox(nome, tipo, vazio)
		var foco_c := caixa(Color(0, 0, 0, 0), acento2, 4, 1)
		foco_c.draw_center = false
		t.set_stylebox("focus", tipo, foco_c)
		for nome_cor in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			t.set_color(nome_cor, tipo, texto)

	# Campos de texto
	var campo := caixa(Color(0, 0, 0, 0.38), borda_suave, 6)
	var campo_foco := caixa(Color(0, 0, 0, 0.5), acento, 6)
	for tipo in ["LineEdit", "TextEdit"]:
		t.set_stylebox("normal", tipo, campo)
		t.set_stylebox("focus", tipo, campo_foco)
		t.set_stylebox("read_only", tipo, caixa(Color(0, 0, 0, 0.22), borda_suave, 6))
		t.set_color("font_color", tipo, texto)
		t.set_color("font_selected_color", tipo, Color(1, 1, 1))
		t.set_color("font_placeholder_color", tipo, Color(fraco.r, fraco.g, fraco.b, 0.65))
		t.set_color("caret_color", tipo, acento2)
		t.set_color("selection_color", tipo, Color(acento.r, acento.g, acento.b, 0.50))
	t.set_color("font_readonly_color", "TextEdit", fraco)
	t.set_color("font_uneditable_color", "LineEdit", fraco)
	if fonte_mono() != null:
		t.set_type_variation("CampoMono", "LineEdit")
		t.set_font("font", "CampoMono", fonte_mono())
		t.set_type_variation("TextoMono", "TextEdit")
		t.set_font("font", "TextoMono", fonte_mono())

	# Painéis
	t.set_stylebox("panel", "PanelContainer", caixa(painel, borda_suave, 8, 1, 8, 6))
	t.set_stylebox("panel", "Panel", caixa(painel, borda_suave, 8, 1, 8, 6))
	t.set_type_variation("PainelVidro", "PanelContainer")
	var vidro := caixa(p["vidro"], borda, 10, 1, 0, 0)
	vidro.shadow_color = Color(acento.r, acento.g, acento.b, 0.22)
	vidro.shadow_size = 14
	t.set_stylebox("panel", "PainelVidro", vidro)
	t.set_type_variation("PainelEscuro", "PanelContainer")
	t.set_stylebox("panel", "PainelEscuro", caixa(Color(0, 0, 0, 0.30), borda_suave, 8, 1, 8, 6))
	t.set_type_variation("PainelCartao", "PanelContainer")
	t.set_stylebox("panel", "PainelCartao", caixa(Color(1, 1, 1, 0.05), borda_suave, 10, 1, 12, 10))
	t.set_type_variation("PainelBarra", "PanelContainer")
	t.set_stylebox("panel", "PainelBarra", caixa(Color(painel.r, painel.g, painel.b, 0.96), borda, 0, 1, 8, 4))
	t.set_type_variation("PainelAlerta", "PanelContainer")
	t.set_stylebox("panel", "PainelAlerta", caixa(Color(perigo.r, perigo.g, perigo.b, 0.16), Color(perigo.r, perigo.g, perigo.b, 0.7), 8, 1, 12, 8))

	# Janela do sistema (JanelaBase): fundo e barra de título, cada um em dois estados (inativa e ativa).
	# A cena janela_base.tscn só escolhe a variação; o script alterna entre as duas conforme o foco.
	t.set_type_variation("PainelJanela", "Panel")
	t.set_stylebox("panel", "PainelJanela", caixa(p["vidro"], Color(1, 1, 1, 0.16), 10, 1, 0, 0))
	t.set_type_variation("PainelJanelaAtiva", "Panel")
	var janela_ativa := caixa(p["vidro"], acento, 10, 2, 0, 0)
	janela_ativa.shadow_color = Color(acento.r, acento.g, acento.b, 0.30)
	janela_ativa.shadow_size = 18
	t.set_stylebox("panel", "PainelJanelaAtiva", janela_ativa)
	for estado in ["BarraJanela", "BarraJanelaAtiva"]:
		t.set_type_variation(estado, "Panel")
		var barra_janela := caixa(Color(acento.r, acento.g, acento.b, 0.24 if estado == "BarraJanelaAtiva" else 0.07), Color(0, 0, 0, 0), 10, 0, 0, 0)
		barra_janela.corner_radius_bottom_left = 0
		barra_janela.corner_radius_bottom_right = 0
		t.set_stylebox("panel", estado, barra_janela)

	# Listas e menus
	t.set_stylebox("panel", "ItemList", caixa(Color(0, 0, 0, 0.22), borda_suave, 6, 1, 4, 4))
	t.set_stylebox("focus", "ItemList", vazio)
	t.set_stylebox("selected", "ItemList", caixa(Color(acento.r, acento.g, acento.b, 0.42), Color(0, 0, 0, 0), 4, 0, 4, 2))
	t.set_stylebox("selected_focus", "ItemList", caixa(Color(acento.r, acento.g, acento.b, 0.55), Color(0, 0, 0, 0), 4, 0, 4, 2))
	t.set_stylebox("hovered", "ItemList", caixa(Color(1, 1, 1, 0.08), Color(0, 0, 0, 0), 4, 0, 4, 2))
	t.set_color("font_color", "ItemList", texto)
	t.set_color("font_hovered_color", "ItemList", texto)
	t.set_color("font_selected_color", "ItemList", Color(1, 1, 1))
	t.set_constant("v_separation", "ItemList", 4)
	t.set_stylebox("panel", "PopupMenu", caixa(Color(painel.r, painel.g, painel.b, 0.98), borda, 6, 1, 6, 6))
	t.set_stylebox("hover", "PopupMenu", caixa(Color(acento.r, acento.g, acento.b, 0.40), Color(0, 0, 0, 0), 4, 0, 6, 3))
	t.set_color("font_color", "PopupMenu", texto)
	t.set_color("font_hover_color", "PopupMenu", Color(1, 1, 1))
	t.set_stylebox("panel", "TooltipPanel", caixa(Color(painel.r, painel.g, painel.b, 0.98), borda, 6, 1, 8, 5))
	t.set_color("font_color", "TooltipLabel", texto)

	# Barras de rolagem, sliders e progresso
	var trilho := caixa(Color(1, 1, 1, 0.05), Color(0, 0, 0, 0), 4, 0, 0, 0)
	var pegador := caixa(Color(acento.r, acento.g, acento.b, 0.55), Color(0, 0, 0, 0), 4, 0, 0, 0)
	var pegador_hl := caixa(Color(acento.r, acento.g, acento.b, 0.80), Color(0, 0, 0, 0), 4, 0, 0, 0)
	for tipo in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", tipo, trilho)
		t.set_stylebox("scroll_focus", tipo, trilho)
		t.set_stylebox("grabber", tipo, pegador)
		t.set_stylebox("grabber_highlight", tipo, pegador_hl)
		t.set_stylebox("grabber_pressed", tipo, pegador_hl)
	t.set_stylebox("slider", "HSlider", caixa(Color(1, 1, 1, 0.12), Color(0, 0, 0, 0), 3, 0, 0, 2))
	t.set_stylebox("grabber_area", "HSlider", caixa(Color(acento.r, acento.g, acento.b, 0.75), Color(0, 0, 0, 0), 3, 0, 0, 2))
	t.set_stylebox("grabber_area_highlight", "HSlider", caixa(Color(acento2.r, acento2.g, acento2.b, 0.85), Color(0, 0, 0, 0), 3, 0, 0, 2))
	t.set_stylebox("background", "ProgressBar", caixa(Color(1, 1, 1, 0.08), borda_suave, 4, 1, 0, 0))
	t.set_stylebox("fill", "ProgressBar", caixa(Color(acento.r, acento.g, acento.b, 0.85), Color(0, 0, 0, 0), 4, 0, 0, 0))
	t.set_color("font_color", "ProgressBar", Color(1, 1, 1))
	t.set_type_variation("BarraPerigo", "ProgressBar")
	t.set_stylebox("fill", "BarraPerigo", caixa(Color(perigo.r, perigo.g, perigo.b, 0.9), Color(0, 0, 0, 0), 4, 0, 0, 0))
	t.set_type_variation("BarraOk", "ProgressBar")
	t.set_stylebox("fill", "BarraOk", caixa(Color(0.29, 0.87, 0.5, 0.85), Color(0, 0, 0, 0), 4, 0, 0, 0))
	var linha_sep := StyleBoxLine.new()
	linha_sep.color = Color(1, 1, 1, 0.12)
	linha_sep.thickness = 1
	t.set_stylebox("separator", "HSeparator", linha_sep)
	return t
