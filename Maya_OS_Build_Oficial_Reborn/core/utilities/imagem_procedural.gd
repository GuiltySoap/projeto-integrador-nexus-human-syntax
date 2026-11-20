class_name ImagemProcedural
extends RefCounted
## Gera imagens substitutas (placeholders) quando o arquivo real ainda não existe em res://shared/assets/textures.
## O puzzle de metadados NÃO depende da imagem: a pista está nos metadados do arquivo virtual.


static func textura(proc: Dictionary, largura: int = 480, altura: int = 320) -> ImageTexture:
	var semente := int(proc.get("semente", 1))
	var estilo := str(proc.get("estilo", "abstrato"))
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var img := Image.create_empty(largura, altura, false, Image.FORMAT_RGBA8)
	var c1 := Color.from_hsv(rng.randf(), 0.55, 0.30)
	var c2 := Color.from_hsv(fmod(c1.h + 0.12 + rng.randf() * 0.2, 1.0), 0.65, 0.80)
	for y in altura:
		img.fill_rect(Rect2i(0, y, largura, 1), c1.lerp(c2, float(y) / float(altura)))
	match estilo:
		"palco":
			for i in 7:
				var x := int(rng.randf() * largura)
				img.fill_rect(Rect2i(x, 0, 14 + int(rng.randf() * 20), int(altura * 0.7)), Color(1.0, 0.95, 0.7, 0.0).lerp(c2.lightened(0.5), 0.55))
			var largura_pessoa: int = floori(largura / 24.0)
			for i in 24:
				var altura_p: int = 30 + int(rng.randf() * 50)
				img.fill_rect(Rect2i(i * largura_pessoa, altura - altura_p, largura_pessoa + 2, altura_p), Color(0.03, 0.02, 0.05))
		"parque":
			img.fill_rect(Rect2i(0, int(altura * 0.62), largura, int(altura * 0.38)), Color(0.12, 0.38, 0.18))
			_circulo(img, int(largura * 0.8), int(altura * 0.2), 34, Color(1.0, 0.9, 0.4))
			for i in 4:
				_circulo(img, 60 + i * 110, int(altura * 0.55), 30 + int(rng.randf() * 18), Color(0.08, 0.28, 0.12))
		"corrompido":
			for i in 60:
				var cor := Color.from_hsv(rng.randf(), 0.9, 0.9) if rng.randf() < 0.3 else Color(0, 0, 0)
				img.fill_rect(Rect2i(int(rng.randf() * largura), int(rng.randf() * altura), 20 + int(rng.randf() * 160), 2 + int(rng.randf() * 8)), cor)
		_:
			for i in 8:
				_circulo(img, int(rng.randf() * largura), int(rng.randf() * altura), 15 + int(rng.randf() * 45), Color.from_hsv(rng.randf(), 0.6, 0.9))
	return ImageTexture.create_from_image(img)


static func _circulo(img: Image, cx: int, cy: int, raio: int, cor: Color) -> void:
	var y0 := maxi(cy - raio, 0)
	var y1 := mini(cy + raio + 1, img.get_height())
	var x0 := maxi(cx - raio, 0)
	var x1 := mini(cx + raio + 1, img.get_width())
	for y in range(y0, y1):
		for x in range(x0, x1):
			var dx := x - cx
			var dy := y - cy
			if dx * dx + dy * dy <= raio * raio:
				img.set_pixel(x, y, cor)
