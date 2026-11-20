extends ModuloDeTeste
## Módulo 8 da suíte: marca visual (§22). O registro `Marca` (caminhos, nomes, validação de tamanho, proporção e transparência), o componente
## `LogoMarca` (proporção, fallback para o nome em texto, alto contraste) e o contrato do logo do HumaxOS, que ainda NÃO foi fornecido:
## enquanto o arquivo oficial não existir, o jogo usa o nome em texto; quando ele for colocado em shared/assets/branding/, este módulo passa a
## exigir que seja um logo válido (tamanho, proporção e fundo recortado) sem nenhuma outra mudança.

const ARQ_LOGO := "res://shared/ui/logo_marca/scenes/logo_marca.tscn"
const OFICIAIS: PackedStringArray = ["maya_marca", "maya_completa", "icone_jogo"]


func executar(banca_do_executor: BancaDeTestes) -> void:
	banca = banca_do_executor
	_isolar_configuracoes()
	GerenciadorConfiguracoes.definir("alto_contraste", false, false)
	_testar_registro()
	_testar_funcoes_puras()
	_testar_logos_oficiais()
	_testar_logo_do_humaxos()
	await _testar_componente_com_imagem()
	await _testar_componente_sem_imagem()
	await _testar_alto_contraste()
	_restaurar_configuracoes()
	await get_tree().process_frame


func _novo_logo(id_marca: String, altura_px: float) -> LogoMarca:
	var logo: LogoMarca = LogoMarca.criar(id_marca, altura_px)
	add_child(logo)
	return logo


func _testar_registro() -> void:
	_secao("Marca: registro, nomes e caminhos")
	var ids: Array = Array(Marca.ids())
	ids.sort()
	_igual(ids, ["humaxos", "icone_jogo", "maya_completa", "maya_marca"], "o registro tem as quatro marcas: Maya (símbolo e logo completa), ícone do jogo e HumaxOS")
	var nomes: Array = [["maya_marca", "Maya"], ["maya_completa", "Maya Human Syntax"], ["icone_jogo", "Maya Human Syntax"], ["humaxos", "HumaxOS"], ["inexistente", ""]]
	for caso in nomes:
		var par: Array = caso
		_igual(Marca.nome(str(par[0])), par[1], "nome da marca %s" % str(par[0]))
	for id_marca in Marca.ids():
		_ok(Marca.conhecida(id_marca) and not Marca.caminhos(id_marca).is_empty(), "%s é conhecida e tem pelo menos um caminho candidato" % id_marca)
		for caminho in Marca.caminhos(id_marca):
			_ok(caminho.begins_with("res://"), "%s: o caminho candidato é um recurso do projeto (%s)" % [id_marca, caminho])
	_ok(not Marca.conhecida("inexistente") and not Marca.conhecida(""), "ids desconhecidos não são marcas")
	_ok(Marca.caminhos("inexistente").is_empty(), "uma marca desconhecida não tem caminhos")
	_igual(Marca.caminho_existente("inexistente"), "", "...nem arquivo")
	_ok(Marca.carregar("inexistente") == null, "...e carregar devolve null (nunca erro)")
	_igual(Marca.caminhos("humaxos").size(), 3, "o HumaxOS aceita três formatos (png, svg, webp) na pasta de branding")
	for caminho in Marca.caminhos("humaxos"):
		_ok(caminho.begins_with("res://shared/assets/branding/humaxos_logo."), "o logo do HumaxOS mora em shared/assets/branding/ (%s)" % caminho.get_file())
	var rotulos := PackedStringArray()
	for id_marca in Marca.ids():
		for chave in ["caminhos", "nome", "transparente", "oficial"]:
			if not (Marca.REGISTRO[id_marca] as Dictionary).has(chave):
				rotulos.append("%s.%s" % [id_marca, chave])
	_igual(",".join(rotulos), "", "toda entrada do registro tem caminhos, nome, transparente e oficial")


func _testar_funcoes_puras() -> void:
	_secao("Marca: tamanho por altura, proporção e validação de ids")
	var tamanhos: Array = [[100.0, 2.0, Vector2(200, 100)], [96.0, 1.0, Vector2(96, 96)], [100.0, 0.0, Vector2(100, 100)], [100.0, -3.0, Vector2(100, 100)], [-5.0, 1.0, Vector2(0, 0)], [50.0, 0.5, Vector2(25, 50)]]
	for caso in tamanhos:
		var par: Array = caso
		_igual(Marca.tamanho_para_altura(float(par[0]), float(par[1])), par[2], "tamanho_para_altura(%s, %s)" % [str(par[0]), str(par[1])])
	var proporcoes: Array = [[1.0, true], [4.0, true], [0.25, true], [2.0, true], [4.01, false], [0.24, false], [0.0, false], [-1.0, false]]
	for caso in proporcoes:
		var par_proporcao: Array = caso
		_igual(Marca.proporcao_valida(float(par_proporcao[0])), par_proporcao[1], "proporção %s %s" % [str(par_proporcao[0]), "é válida" if bool(par_proporcao[1]) else "é recusada"])
	var desconhecida: Dictionary = Marca.validar("inexistente")
	_ok(not bool(desconhecida["ok"]) and not bool(desconhecida["existe"]), "validar de uma marca desconhecida: não ok e não existe")
	_igual(desconhecida["erros"], ["marca desconhecida: inexistente"], "...com o erro 'marca desconhecida'")


func _testar_logos_oficiais() -> void:
	_secao("Marca: os logos oficiais (Maya) existem, são válidos e têm a transparência certa")
	for id_marca in OFICIAIS:
		_ok(Marca.existe(id_marca), "%s: o arquivo existe e está importado (%s)" % [id_marca, Marca.caminho_existente(id_marca)])
		var v: Dictionary = Marca.validar(id_marca)
		_ok(bool(v["ok"]), "%s: passa em Marca.validar %s" % [id_marca, "; ".join(PackedStringArray(v["erros"]))])
		_ok(int(v["largura"]) >= Marca.LADO_MINIMO and int(v["altura"]) >= Marca.LADO_MINIMO, "%s: tem tamanho de logo (%dx%d)" % [id_marca, int(v["largura"]), int(v["altura"])])
		_ok(Marca.proporcao_valida(float(v["proporcao"])), "%s: proporção razoável (%.2f)" % [id_marca, float(v["proporcao"])])
		var textura: Texture2D = Marca.carregar(id_marca)
		_ok(textura != null and textura.get_width() == int(v["largura"]), "%s: carregar devolve a textura" % id_marca)
	_igual(str(Marca.validar("maya_marca")["transparencia"]), "real", "o símbolo da Maya tem transparência de verdade (sem retângulo de fundo)")
	_igual(str(Marca.validar("icone_jogo")["transparencia"]), "real", "o ícone do jogo tem cantos transparentes")
	_igual(str(Marca.validar("maya_completa")["transparencia"]), "opaca", "a logo completa é sobre fundo preto (sem alfa), como definido")
	_ok(FileAccess.file_exists("res://shared/assets/icons/icone_maya.png"), "o arquivo do ícone do jogo está no projeto")
	_igual(str(ProjectSettings.get_setting("application/config/icon", "")), "res://shared/assets/icons/icone_maya.png", "o ícone do projeto é o ícone da Maya")


func _testar_logo_do_humaxos() -> void:
	_secao("Marca: logo do HumaxOS (pendente até o arquivo oficial ser fornecido)")
	var existe: bool = Marca.existe("humaxos")
	var v: Dictionary = Marca.validar("humaxos")
	_igual(bool(v["existe"]), existe, "validar e existe concordam")
	if existe:
		_info("o logo oficial do HumaxOS foi encontrado: %s" % str(v["caminho"]))
		_ok(bool(v["ok"]), "o logo do HumaxOS é válido (tamanho, proporção, fundo recortado) %s" % "; ".join(PackedStringArray(v["erros"])))
		_ok(Marca.carregar("humaxos") != null, "...e carrega")
	else:
		_info("o logo oficial do HumaxOS ainda NÃO foi fornecido: o jogo usa o nome em texto (pendência real)")
		_ok(not bool(v["ok"]), "sem arquivo: validar não aprova")
		_ok(Marca.carregar("humaxos") == null, "...e carregar devolve null, sem erro")
		var erros: Array = v["erros"]
		_ok(erros.size() == 1 and str(erros[0]).contains("o jogo usa o nome em texto"), "...e o erro explica que o jogo usa o nome em texto")
		_igual(Marca.caminho_existente("humaxos"), "", "...e nenhum caminho candidato existe")


# ------------------------------------------------------------------ componente
func _testar_componente_com_imagem() -> void:
	_secao("LogoMarca (cena real): proporção do arquivo, altura, dica de ferramenta e nome")
	var logo: LogoMarca = _novo_logo("maya_marca", 96.0)
	await get_tree().process_frame
	_ok(logo.tem_imagem(), "o logo da Maya mostra a imagem")
	_ok(logo.visible, "...e o componente aparece")
	_ok(not logo.nome_visivel(), "...sem o nome em texto (mostrar_nome desligado)")
	_igual(logo.tooltip_text, "Maya", "a dica de ferramenta é o nome da marca (texto alternativo)")
	_perto(logo.tamanho_da_imagem().y, 96.0, "a altura é a pedida")
	var textura: Texture2D = Marca.carregar("maya_marca")
	var proporcao: float = float(textura.get_width()) / float(textura.get_height()) if textura != null else 1.0
	_perto(logo.tamanho_da_imagem().x, 96.0 * proporcao, "a largura segue a proporção do arquivo (sem esticar)")
	logo.altura = 48.0
	_perto(logo.tamanho_da_imagem().y, 48.0, "mudar a altura atualiza o tamanho")
	_perto(logo.tamanho_da_imagem().x, 48.0 * proporcao, "...mantendo a proporção")
	logo.altura = 1.0
	_perto(logo.tamanho_da_imagem().y, 8.0, "a altura mínima é 8 px")
	logo.mostrar_nome = true
	_ok(logo.nome_visivel(), "mostrar_nome liga o nome em texto ao lado da imagem")
	logo.mostrar_nome = false
	_ok(not logo.nome_visivel(), "...e desliga")
	_ok(logo.mouse_filter == Control.MOUSE_FILTER_IGNORE, "o componente não recebe o mouse (é só identidade visual)")
	logo.marca = "maya_completa"
	_igual(logo.tooltip_text, "Maya Human Syntax", "trocar a marca atualiza a dica de ferramenta")
	_ok(logo.tem_imagem(), "...e a imagem")
	logo.queue_free()
	await get_tree().process_frame


func _testar_componente_sem_imagem() -> void:
	_secao("LogoMarca (cena real): sem arquivo o componente some ou mostra o nome em texto")
	var logo: LogoMarca = _novo_logo("inexistente", 96.0)
	await get_tree().process_frame
	_ok(not logo.tem_imagem(), "uma marca desconhecida não tem imagem")
	_ok(not logo.visible and not logo.nome_visivel(), "...e, por padrão, o componente some (a tela já tem o nome da marca)")
	_igual(logo.tamanho_da_imagem(), Vector2.ZERO, "...sem ocupar espaço")
	logo.ocultar_sem_imagem = false
	_igual(logo.nome_visivel(), false, "sem nome de marca (id desconhecido) não há texto de reserva")
	logo.marca = "humaxos"
	if Marca.existe("humaxos"):
		_ok(logo.tem_imagem() and logo.visible, "HumaxOS com arquivo: mostra a imagem")
	else:
		_ok(not logo.tem_imagem(), "HumaxOS sem arquivo: não tem imagem")
		_ok(logo.visible and logo.nome_visivel(), "...e com ocultar_sem_imagem desligado mostra o nome 'HumaxOS' em texto")
		var rotulo: Label = logo.get_node("%Nome")
		_igual(rotulo.text, "HumaxOS", "...o texto é HumaxOS")
		logo.ocultar_sem_imagem = true
		_ok(not logo.visible, "...e com ocultar_sem_imagem ligado o componente some")
	logo.queue_free()
	await get_tree().process_frame


func _testar_alto_contraste() -> void:
	_secao("LogoMarca (cena real): alto contraste")
	var logo: LogoMarca = _novo_logo("maya_marca", 96.0)
	await get_tree().process_frame
	var moldura: PanelContainer = logo.get_node("%Moldura")
	_ok(not logo.alto_contraste_ativo(), "alto contraste desligado")
	var caixa_normal: StyleBoxFlat = moldura.get_theme_stylebox("panel") as StyleBoxFlat
	_ok(caixa_normal != null and caixa_normal.bg_color.a == 0.0 and caixa_normal.border_width_left == 0, "a moldura é transparente e sem borda")
	GerenciadorConfiguracoes.definir("alto_contraste", true, false)
	await get_tree().process_frame
	_ok(logo.alto_contraste_ativo(), "ligar o alto contraste chega ao componente na hora")
	var caixa_alta: StyleBoxFlat = moldura.get_theme_stylebox("panel") as StyleBoxFlat
	_ok(caixa_alta != null and caixa_alta.bg_color == Color(0, 0, 0, 1), "a moldura vira preto sólido")
	_ok(caixa_alta != null and caixa_alta.border_width_left == LogoMarca.LARGURA_BORDA and caixa_alta.border_color == Color(1, 1, 1, 1), "...com borda branca de %d px" % LogoMarca.LARGURA_BORDA)
	_ok(logo.tem_imagem(), "...e a imagem continua lá")
	GerenciadorConfiguracoes.definir("alto_contraste", false, false)
	await get_tree().process_frame
	_ok(not logo.alto_contraste_ativo(), "desligar volta ao normal")
	var caixa_de_volta: StyleBoxFlat = moldura.get_theme_stylebox("panel") as StyleBoxFlat
	_ok(caixa_de_volta != null and caixa_de_volta.bg_color.a == 0.0, "...com a moldura transparente de novo")
	logo.queue_free()
	await get_tree().process_frame
