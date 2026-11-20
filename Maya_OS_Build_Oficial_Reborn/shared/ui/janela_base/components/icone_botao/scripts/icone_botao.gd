@tool
class_name IconeBotao
extends Control
## Ícone vetorial dos botões da barra de título (minimizar, maximizar, restaurar e fechar).
## É desenhado em _draw(): não depende de fontes de símbolos nem de imagens e acompanha a cor do tema.
## Uso: coloque-o como filho de um Button (ele preenche o botão) e escolha o desenho em "Tipo" no Inspetor.

@export_enum("min", "max", "restaurar", "fechar") var tipo: String = "fechar":
	set(valor):
		tipo = valor
		queue_redraw()


func definir_tipo(novo: String) -> void:
	tipo = novo


func _notification(quando: int) -> void:
	if quando == NOTIFICATION_THEME_CHANGED:
		queue_redraw()


## A cor do glifo é a cor de texto do botão pai (assim troca junto com o tema e o alto contraste).
func _cor_do_glifo() -> Color:
	var botao := get_parent() as Button
	if botao != null:
		return botao.get_theme_color("font_color")
	return get_theme_color("font_color", "Button")


func _draw() -> void:
	var cor := _cor_do_glifo()
	var c := size / 2.0
	var r := minf(size.x, size.y) * 0.22
	var e := 1.6
	match tipo:
		"min":
			draw_line(Vector2(c.x - r, c.y + r * 0.6), Vector2(c.x + r, c.y + r * 0.6), cor, e)
		"max":
			draw_rect(Rect2(c.x - r, c.y - r, r * 2.0, r * 2.0), cor, false, e)
		"restaurar":
			draw_rect(Rect2(c.x - r, c.y - r * 0.3, r * 1.5, r * 1.5), cor, false, e)
			draw_polyline(PackedVector2Array([
				Vector2(c.x - r * 0.3, c.y - r * 0.3), Vector2(c.x - r * 0.3, c.y - r),
				Vector2(c.x + r, c.y - r), Vector2(c.x + r, c.y + r * 0.3), Vector2(c.x + r * 0.3, c.y + r * 0.3)]), cor, e)
		_:
			draw_line(Vector2(c.x - r, c.y - r), Vector2(c.x + r, c.y + r), cor, e)
			draw_line(Vector2(c.x + r, c.y - r), Vector2(c.x - r, c.y + r), cor, e)
