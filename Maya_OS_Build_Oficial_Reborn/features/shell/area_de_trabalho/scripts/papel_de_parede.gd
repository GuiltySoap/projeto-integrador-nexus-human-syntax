class_name PapelDeParede
extends Control
## Papel de parede que acompanha o dia. No modo "dia" usa res://shared/assets/textures/wallpaper_<dia>.png (ou wallpaper.png)
## quando o arquivo existe; sem ele, ou com "Alto contraste" ligado, volta ao desenho procedural com a paleta do dia.
## Modos (Configurações): "dia" (imagem do dia + grade; no fallback procedural: gradiente + grade + círculos + marca "HumaxOS"),
## "grade" (gradiente + grade discreta, nunca a imagem) e "preto". A imagem traz a própria composição, então círculos e marca
## d'água só existem no fallback. A imagem cobre a área sem deformar (corte centralizado): o projeto usa stretch "expand",
## então a janela pode ter qualquer proporção.
## O desenho é procedural (a paleta muda a cada dia), por isso fica em _draw; o nó e o layout estão em papel_de_parede.tscn.

## Distância entre as linhas da grade, em pixels.
@export_range(16.0, 256.0, 1.0) var passo_grade: float = 64.0

var _gradiente: GradientTexture2D
var _textura: Texture2D = null


func _ready() -> void:
	atualizar()


func atualizar() -> void:
	var p := TemaNexus.paleta()
	var topo: Color = p["fundo"]
	var meio: Color = p["painel"]
	var acento: Color = p["acento"]
	var g := Gradient.new()
	g.colors = PackedColorArray([topo, meio.lerp(acento, 0.16), topo])
	g.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	_gradiente = GradientTexture2D.new()
	_gradiente.gradient = g
	_gradiente.fill = GradientTexture2D.FILL_LINEAR
	_gradiente.fill_from = Vector2(0.15, 0.0)
	_gradiente.fill_to = Vector2(0.85, 1.0)
	_gradiente.width = 256
	_gradiente.height = 256
	_textura = null
	for caminho in ["res://shared/assets/textures/wallpaper_%d.png" % TemaNexus.dia_atual, "res://shared/assets/textures/wallpaper.png"]:
		if ResourceLoader.exists(caminho):
			var t: Resource = load(caminho)
			if t is Texture2D:
				_textura = t
				break
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


## A imagem do dia só aparece no modo "dia" e sem alto contraste (que exige fundo liso para os ícones e legendas).
func _usa_imagem(modo: String) -> bool:
	return _textura != null and modo == "dia" and not bool(GerenciadorConfiguracoes.obter("alto_contraste"))


## Parte da imagem que cobre a área inteira sem deformar: corta o excedente, centralizado.
static func recorte_de_cobertura(tamanho_imagem: Vector2, tamanho_area: Vector2) -> Rect2:
	if tamanho_imagem.x <= 0.0 or tamanho_imagem.y <= 0.0 or tamanho_area.x <= 0.0 or tamanho_area.y <= 0.0:
		return Rect2(Vector2.ZERO, tamanho_imagem)
	var escala := maxf(tamanho_area.x / tamanho_imagem.x, tamanho_area.y / tamanho_imagem.y)
	var visivel := tamanho_area / escala
	return Rect2((tamanho_imagem - visivel) * 0.5, visivel)


func _draw() -> void:
	var area := Rect2(Vector2.ZERO, size)
	var modo := str(GerenciadorConfiguracoes.obter("papel_de_parede"))
	if modo == "preto":
		draw_rect(area, Color.BLACK)
		return
	var p := TemaNexus.paleta()
	var acento: Color = p["acento"]
	var acento2: Color = p["acento2"]
	var com_imagem := _usa_imagem(modo)
	if com_imagem:
		draw_texture_rect_region(_textura, area, recorte_de_cobertura(_textura.get_size(), size))
	elif _gradiente != null:
		draw_texture_rect(_gradiente, area, false)
	var passo: float = passo_grade
	var cor_grade := Color(acento.r, acento.g, acento.b, 0.06)
	var x := 0.0
	while x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), cor_grade, 1.0)
		x += passo
	var y := 0.0
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), cor_grade, 1.0)
		y += passo
	if modo == "grade" or com_imagem:
		return
	draw_circle(Vector2(size.x * 0.78, size.y * 0.32), size.y * 0.30, Color(acento.r, acento.g, acento.b, 0.07))
	draw_circle(Vector2(size.x * 0.22, size.y * 0.78), size.y * 0.24, Color(acento2.r, acento2.g, acento2.b, 0.06))
	var fonte := ThemeDB.fallback_font
	if fonte != null:
		var tamanho := int(size.y * 0.14)
		draw_string(fonte, Vector2(0, size.y * 0.58), "HumaxOS", HORIZONTAL_ALIGNMENT_CENTER, size.x, tamanho, Color(acento.r, acento.g, acento.b, 0.07))
