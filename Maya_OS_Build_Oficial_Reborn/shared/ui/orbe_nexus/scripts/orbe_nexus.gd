class_name OrbeNexus
extends Control
## Orbe animado da Maya. Reage ao estado da IA (cor) e a eventos (pulso). Desenhado em código (animação procedural);
## o nó e o tamanho mínimo estão em orbe_nexus.tscn (as telas que o usam podem ajustar o tamanho na instância).
## Com "reduzir animações" o orbe fica estático (um único desenho, sem _process).

var estado: String = "amigavel"
var energia: float = 0.0
var _fase: float = 0.0


func _ready() -> void:
	set_process(GerenciadorConfiguracoes.animacoes_permitidas())


func definir_estado(novo: String) -> void:
	estado = novo
	queue_redraw()


## Dá um "pulso" no orbe (mensagem recebida, evento, fala da IA).
func reagir(forca: float = 0.7) -> void:
	if not GerenciadorConfiguracoes.animacoes_permitidas():
		return
	energia = clampf(energia + forca, 0.0, 1.0)
	set_process(true)


func _process(delta: float) -> void:
	_fase += delta * (1.0 + energia * 3.0)
	energia = maxf(0.0, energia - delta * 1.2)
	queue_redraw()


func _cores() -> Array:
	return cores_de(estado)


## Par de cores [principal, secundária] de um estado da IA (também usado pelo WidgetMaya, que não desenha mais um orbe).
static func cores_de(estado_ia: String) -> Array:
	match estado_ia:
		"controladora":
			return [Color.html("#38bdf8"), Color.html("#818cf8")]
		"revelada":
			return [Color.html("#e11d48"), Color.html("#a855f7")]
		"isolando":
			return [Color.html("#ef4444"), Color.html("#f97316")]
		"colapso":
			return [Color.html("#22c55e"), Color.html("#ef4444")]
		_:
			return [Color.html("#8b5cf6"), Color.html("#38bdf8")]


func _draw() -> void:
	var c := size / 2.0
	var base := minf(size.x, size.y) * 0.5
	if base <= 1.0:
		return
	var pulso := 0.5 + 0.5 * sin(_fase * 2.0)
	var r := base * (0.50 + 0.04 * pulso + 0.10 * energia)
	var cores := _cores()
	var principal: Color = cores[0]
	var secundaria: Color = cores[1]
	draw_circle(c, base * 0.98, Color(principal.r, principal.g, principal.b, 0.06 + 0.06 * energia))
	draw_circle(c, base * 0.78, Color(principal.r, principal.g, principal.b, 0.12))
	draw_circle(c, r, Color(principal.r, principal.g, principal.b, 0.88))
	draw_circle(c - Vector2(r * 0.25, r * 0.30), r * 0.55, Color(secundaria.r, secundaria.g, secundaria.b, 0.55))
	draw_arc(c, r * 1.28, _fase, _fase + PI * 1.2, 48, Color(secundaria.r, secundaria.g, secundaria.b, 0.9), 2.0, true)
	draw_arc(c, r * 1.42, -_fase * 0.7, -_fase * 0.7 + PI * 0.6, 32, Color(principal.r, principal.g, principal.b, 0.6), 1.5, true)
	if estado == "colapso" or estado == "isolando":
		var passo := floorf(_fase * 6.0)
		for i in 3:
			var y := c.y + (fmod(passo * 17.0 + float(i) * 41.0, base * 1.6) - base * 0.8)
			draw_rect(Rect2(c.x - base * 0.7, y, base * 1.4, 2.0), Color(secundaria.r, secundaria.g, secundaria.b, 0.35))
