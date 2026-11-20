extends Node
## Teste da SPLASH SCREEN (a abertura da marca, primeira cena do jogo), com o vídeo, o som, as entradas e as trocas de cena de verdade.
## Prova, em ordem: (1) o projeto e os assets (cena principal, vídeo Ogg Theora, logo estática, nada duplicado, nada de .mp4); (2) a cena e o
## script (nós, ajustes, só os serviços permitidos, nenhuma ação nova no InputMap); (3) a geometria em várias proporções (logo centralizada,
## sem distorção, fundo preto, vídeo em 16:9 sem esticar); (4) a execução limpa até o fim do vídeo e a chegada ao Menu Principal; (5) o pulo
## por Espaço, Enter, Esc, mouse, controle, repetido e ainda durante o carregamento; (6) as falhas do vídeo (ausente, caminho vazio, formato
## desconhecido, codec incompatível, arquivo vazio, `finished` que nunca vem); (7) as falhas do destino (Menu ausente, cena ilegível) e a
## nova tentativa; (8) a acessibilidade (modo conforto, sem flashes, reduzir animações, alto contraste, reduzir ruído, volume); (9) a abertura
## uma única vez por execução e a integridade do jogo (nada de BIOS, nada de salvamento, autoloads únicos, som residual).
## Os fluxos Novo Jogo e Carregar depois do Menu são provados em tests/fluxo_sessao (que agora começa pela Splash).
##
## Como usar: abra tests/splash/splash.tscn no editor e pressione F6. Dura cerca de 2 minutos e TOCA O SOM da abertura (baixo). O resultado vai
## para o painel Saída e para tests/_saida/splash/log.txt (linhas "OK" / "FALHA"; a última linha é o resumo), com capturas de tela dos estados
## principais em tests/_saida/splash/*.png. Código de saída: 0 = tudo certo; 1 = alguma verificação falhou.
## Segurança: o salvamento e as preferências reais do jogador (user://nexus_os/) nunca são lidos nem gravados: tudo vai para uma pasta própria
## de user://nexus_os_teste_splash/ (nada é apagado; cada execução usa uma pasta nova). O teste não aciona F11 (mexeria na janela do jogador).
## O Depurador mostra mensagens de propósito nas simulações de falha (avisos da própria Splash, erros do carregador de recursos e da camada
## `Cenas`): são esperadas. Qualquer outra mensagem é problema.

const SAIDA := "res://tests/_saida/splash/"
const PASTA_BASE := "user://nexus_os_teste_splash"
const LIMITE_TROCA := 25.0
## [nome, tamanho lógico] de cada proporção (a base do jogo é 1920x1080; o stretch `expand` cresce a área nas outras).
const PROPORCOES: Array = [
	["16x9", Vector2i(1920, 1080)],
	["16x10", Vector2i(1920, 1200)],
	["21x9", Vector2i(2560, 1080)],
	["4x3", Vector2i(1920, 1440)],
	["9x16", Vector2i(1080, 1920)],
]
## Vídeo H.264 + AAC (64x64, 1 s, 2,7 KB) em base64: o "codec incompatível" das simulações de falha (a Godot só toca Ogg Theora).
const MP4_H264_B64 := "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"


var _log: PackedStringArray = []
var _verificacoes: int = 0
var _falhas: int = 0
var _arvore: SceneTree = null
var _pasta: String = ""
var _destino_stub: String = ""
var _destino_quebrado: String = ""
var _video_h264_disfarcado: String = ""
var _video_h264_mp4: String = ""
var _video_vazio: String = ""
var _criados: Dictionary = {}
var _audio_players_no_inicio: int = 0
var _volume_bgm_db_no_inicio: float = 0.0
## Quando a Splash de teste foi instanciada (para medir o tempo total até o destino, e não só o tempo depois da decisão de sair).
var _marca_instancia_ms: int = 0


func _ready() -> void:
	_arvore = get_tree()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA))
	await _arvore.process_frame  # a raiz está ocupada durante o _ready da cena atual
	# Sai de baixo da "cena atual": a troca de cena descarta a cena atual, e este teste precisa sobreviver a ela.
	_arvore.root.remove_child(self)
	_arvore.root.add_child(self)
	_arvore.current_scene = null
	await _executar()
	_registrar("INFO: mensagens esperadas no Depurador: os avisos da Splash (um por simulação de falha), os erros do carregador de vídeo (arquivos falsos), o erro da camada Cenas (Menu ausente e cena ilegível) e os erros do carregador de cenas (cena ilegível)")
	_registrar("RESULTADO: %d verificações, %d falhas." % [_verificacoes, _falhas])
	_gravar()
	_arvore.quit(1 if _falhas > 0 else 0)


func _executar() -> void:
	var pasta_real: String = SistemaPersistencia.pasta
	var cfg_real: String = GerenciadorConfiguracoes.caminho
	var cfg_persistencia: bool = GerenciadorConfiguracoes.persistencia_habilitada
	var valores_antes: Dictionary = GerenciadorConfiguracoes.valores.duplicate(true)
	var habilitado_antes: bool = SistemaPersistencia.habilitado
	_pasta = _nova_pasta()
	_registrar("INFO: pasta desta execução = %s (o salvamento e as preferências reais não são tocados)" % _pasta)
	SistemaPersistencia.pasta = _pasta + "/salvamento"
	SistemaPersistencia.habilitado = false
	GerenciadorConfiguracoes.caminho = _pasta + "/configuracoes_teste.cfg"
	GerenciadorConfiguracoes.persistencia_habilitada = false
	_preparar_arquivos_de_teste()
	_configurar_padrao()
	_audio_players_no_inicio = _contar_audio_players()
	_volume_bgm_db_no_inicio = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("BGM"))
	_arvore.node_added.connect(_ao_no_adicionado)

	await _etapa_projeto_e_assets()
	await _etapa_cena_e_servicos()
	await _etapa_geometria()
	await _etapa_execucao_limpa()
	await _etapa_pular()
	await _etapa_falhas_do_video()
	await _etapa_falhas_do_destino()
	await _etapa_acessibilidade()
	await _etapa_uma_vez_e_integridade()

	_arvore.node_added.disconnect(_ao_no_adicionado)
	GerenciadorConfiguracoes.caminho = cfg_real
	GerenciadorConfiguracoes.persistencia_habilitada = cfg_persistencia
	GerenciadorConfiguracoes.valores = valores_antes
	SistemaAudio.aplicar_volumes()
	SistemaPersistencia.pasta = pasta_real
	SistemaPersistencia.habilitado = habilitado_antes
	_ok(SistemaPersistencia.pasta == SistemaPersistencia.PASTA and GerenciadorConfiguracoes.caminho == GerenciadorConfiguracoes.CAMINHO, "depois do teste o jogo volta a gravar em user://nexus_os")


# ------------------------------------------------------------------ 1) projeto e assets
func _etapa_projeto_e_assets() -> void:
	_registrar("== projeto e assets")
	var principal: String = _cena_principal_do_projeto()
	_ok(principal == Cenas.SPLASH, "a cena principal do projeto é a Splash (veio %s)" % principal)
	_ok(ResourceLoader.exists(Cenas.SPLASH) and load(Cenas.SPLASH) is PackedScene, "a cena da Splash existe e carrega")
	var video: Resource = load(SplashScreen.CAMINHO_VIDEO)
	_ok(video is VideoStream and video.get_class() == "VideoStreamTheora", "o vídeo da logo é um VideoStreamTheora (Ogg Theora, o único formato que a Godot toca)")
	var cabecalho: PackedByteArray = FileAccess.get_file_as_bytes(SplashScreen.CAMINHO_VIDEO).slice(0, 4)
	_ok(cabecalho.get_string_from_ascii() == "OggS", "o arquivo do vídeo é um contêiner Ogg de verdade (começa com OggS)")
	var logo: Texture2D = load("res://features/splash_screen/assets/mayaos_intro_logo.png") as Texture2D
	_ok(logo != null and logo.get_width() == 1024 and logo.get_height() == 1024, "a logo estática carrega (1024x1024)")
	if logo != null:
		var imagem: Image = logo.get_image()
		var preto: bool = true
		for canto in [Vector2i(0, 0), Vector2i(1008, 0), Vector2i(0, 1008), Vector2i(1008, 1008)]:
			var origem: Vector2i = canto
			for dy in 16:
				for dx in 16:
					var c: Color = imagem.get_pixel(origem.x + dx, origem.y + dy)
					if c.r > 0.0 or c.g > 0.0 or c.b > 0.0:
						preto = false
		_ok(preto, "os cantos da logo estática são pretos puros (sem borda nem quadrado de ruído sobre o fundo preto)")
	var arquivos: Array = []
	for nome in DirAccess.get_files_at("res://features/splash_screen/assets/"):
		if not (nome.ends_with(".import") or nome.ends_with(".uid")):
			arquivos.append(nome)
	arquivos.sort()
	_ok(arquivos == ["maya_human_syntax_intro.ogv", "mayaos_intro_logo.png"], "a pasta de assets tem só o vídeo .ogv e a logo .png (nada duplicado, sem .mp4 nem .jpg: %s)" % str(arquivos))
	var exportacao: bool = FileAccess.file_exists("res://export_presets.cfg")
	_registrar("INFO: export_presets.cfg %s (o filtro de exportação precisa incluir *.ogv: o vídeo não é um recurso importado)" % ("existe" if exportacao else "não existe neste projeto"))


func _cena_principal_do_projeto() -> String:
	var principal: String = str(ProjectSettings.get_setting("application/run/main_scene"))
	if principal.begins_with("uid://"):
		var id_da_cena: int = ResourceUID.text_to_id(principal)
		if ResourceUID.has_id(id_da_cena):
			principal = ResourceUID.get_id_path(id_da_cena)
	return principal


# ------------------------------------------------------------------ 2) cena, script e serviços
func _etapa_cena_e_servicos() -> void:
	_registrar("== cena, script e serviços")
	var pacote: PackedScene = load(Cenas.SPLASH) as PackedScene
	var raiz: Node = pacote.instantiate()
	_ok(raiz is SplashScreen and raiz.get_script() != null, "a raiz da cena é uma SplashScreen")
	_ok(raiz.process_mode == Node.PROCESS_MODE_ALWAYS, "a Splash processa mesmo com a árvore pausada (nunca fica presa)")
	var video: VideoStreamPlayer = raiz.get_node_or_null("%VideoLogo") as VideoStreamPlayer
	var logo: TextureRect = raiz.get_node_or_null("%LogoFallback") as TextureRect
	var fundo: ColorRect = raiz.get_node_or_null("%FundoPreto") as ColorRect
	var cortina: ColorRect = raiz.get_node_or_null("%FadeOverlay") as ColorRect
	var proporcao: AspectRatioContainer = raiz.get_node_or_null("%ContainerVideo") as AspectRatioContainer
	var dica: Label = raiz.get_node_or_null("%IndicadorPular") as Label
	_ok(video != null and logo != null and fundo != null and cortina != null and proporcao != null and dica != null, "a cena tem VideoLogo, LogoFallback, FundoPreto, FadeOverlay, ContainerVideo e IndicadorPular")
	if video != null and logo != null and fundo != null and cortina != null and proporcao != null and dica != null:
		_ok(not video.autoplay and not video.loop, "o vídeo não tem autoplay (a Splash o inicia uma única vez) nem laço")
		_ok(video.expand and video.get_parent() == proporcao, "o vídeo expande dentro do AspectRatioContainer (preenche sem distorcer)")
		_ok(proporcao.stretch_mode == AspectRatioContainer.STRETCH_FIT and absf(proporcao.ratio - 16.0 / 9.0) < 0.001, "o contêiner encaixa o vídeo na tela inteira (fit) na proporção 16:9")
		_ok(logo.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED and logo.expand_mode == TextureRect.EXPAND_IGNORE_SIZE, "a logo estática é centralizada e mantém a proporção (sem esticar)")
		_ok(fundo.color == Color(0, 0, 0, 1) and cortina.color == Color(0, 0, 0, 1), "o fundo e o fade são pretos puros")
		_ok(dica.text == "Pressione Espaço para pular", "o aviso de pulo diz '%s'" % dica.text)
	raiz.free()
	# nenhuma ação nova no InputMap: o pulo usa as ações que o jogo já tem
	_ok(InputMap.has_action("ui_accept") and InputMap.has_action("ui_cancel") and not InputMap.has_action("skip_splash"), "o pulo reaproveita ui_accept e ui_cancel (nenhuma ação skip_splash foi criada)")
	_ok(_acao_tem_tecla("ui_accept", KEY_SPACE) and _acao_tem_tecla("ui_accept", KEY_ENTER) and _acao_tem_tecla("ui_cancel", KEY_ESCAPE), "ui_accept cobre Espaço e Enter; ui_cancel cobre Esc")
	# O controle pula por QUALQUER botão (tratado direto no script): não depende de o InputMap padrão do motor ter um botão em ui_accept.
	_registrar("INFO: eventos do motor: ui_accept = %s; ui_cancel = %s" % [_eventos_da_acao("ui_accept"), _eventos_da_acao("ui_cancel")])
	# o script só usa os serviços permitidos
	var codigo: String = _codigo_sem_comentarios("res://features/splash_screen/scripts/splash_screen.gd")
	_ok(codigo.contains("InputEventJoypadButton"), "o botão do controle pula a abertura por código próprio (ui_accept do motor tem botão de controle: %s)" % str(_acao_tem_botao_do_controle("ui_accept")))
	var proibidos: Array = ["SistemaPersistencia", "GerenciadorNarrativa", "GerenciadorEstado", "GerenciadorJanelas", "Sessao", "TelaBoot", "Cenas.BOOT", "Cenas.AREA_DE_TRABALHO", "Cenas.FINAL", "AudioStreamPlayer", "change_scene", "tela_boot", "area_de_trabalho", "RelogioGlobal", "SistemaNotificacoes", "SistemaArquivosVirtual"]
	var achados: Array = []
	for termo in proibidos:
		if codigo.contains(str(termo)):
			achados.append(termo)
	_ok(achados.is_empty(), "o script da Splash não toca boot, jogo, salvamento, narrativa nem apps (termos proibidos achados: %s)" % str(achados))
	_ok(codigo.contains("Cenas.ir_para") and not codigo.contains("get_tree().change_scene"), "a saída passa pela camada Cenas (nenhum change_scene direto)")
	# nada do jogo leva de volta à Splash
	var referencias: Array = []
	for pasta in ["res://core", "res://features", "res://shared"]:
		for caminho in _listar_gd(pasta):
			if caminho.ends_with("splash_screen.gd") or caminho.ends_with("cenas.gd"):
				continue
			if _codigo_sem_comentarios(caminho).contains("SPLASH") or _codigo_sem_comentarios(caminho).contains("splash_screen.tscn"):
				referencias.append(caminho)
	_ok(referencias.is_empty(), "nenhum script do jogo pede a Splash de volta (referências: %s)" % str(referencias))
	var boot: String = _codigo_sem_comentarios("res://features/shell/tela_boot/scripts/tela_boot.gd")
	_ok(not boot.contains("_ir_para_menu()") and not boot.contains("_deve_ir_ao_menu_principal"), "a BIOS da TelaBoot não leva mais ao Menu (a ordem é Splash, Menu, Novo Jogo, BIOS)")


func _acao_tem_tecla(acao: String, tecla: Key) -> bool:
	for evento in InputMap.action_get_events(acao):
		if evento is InputEventKey and ((evento as InputEventKey).keycode == tecla or (evento as InputEventKey).physical_keycode == tecla):
			return true
	return false


func _eventos_da_acao(acao: String) -> String:
	var textos: PackedStringArray = []
	for evento in InputMap.action_get_events(acao):
		textos.append(evento.as_text())
	return "[%s]" % ", ".join(textos)


func _acao_tem_botao_do_controle(acao: String) -> bool:
	for evento in InputMap.action_get_events(acao):
		if evento is InputEventJoypadButton:
			return true
	return false


func _codigo_sem_comentarios(caminho: String) -> String:
	var linhas: PackedStringArray = FileAccess.get_file_as_string(caminho).split("\n")
	var saida: PackedStringArray = []
	for linha in linhas:
		var corte: int = linha.find("#")
		saida.append(linha if corte < 0 else linha.substr(0, corte))
	return "\n".join(saida)


func _listar_gd(pasta: String) -> Array:
	var achados: Array = []
	for arquivo in DirAccess.get_files_at(pasta):
		if arquivo.ends_with(".gd"):
			achados.append(pasta + "/" + arquivo)
	for sub in DirAccess.get_directories_at(pasta):
		achados.append_array(_listar_gd(pasta + "/" + sub))
	return achados


# ------------------------------------------------------------------ 3) geometria
func _etapa_geometria() -> void:
	_registrar("== geometria: logo centralizada, sem distorção, fundo preto e vídeo 16:9 sem esticar")
	# A) logo estática (com "Reduzir animações" não há vídeo): a caixa do logotipo em cada proporção contra a de 16:9
	GerenciadorConfiguracoes.definir("reduzir_animacoes", true, false)
	var referencia: Rect2 = Rect2()
	for proporcao in PROPORCOES:
		var nome: String = str(proporcao[0])
		var tamanho: Vector2i = proporcao[1]
		var sub: SubViewport = await _montar_viewport(tamanho)
		var splash: SplashScreen = _adicionar_splash(sub, {"duracao_estatica_s": 60.0})
		await _esperar_quadros(4)
		var imagem: Image = sub.get_texture().get_image()
		var caixa: Rect2 = _caixa_do_logo(imagem)
		if nome == "16x9":
			referencia = caixa
			_ok(caixa.size.y > 0.80 * float(tamanho.y) and caixa.size.y < 0.95 * float(tamanho.y), "16x9: a logo ocupa %.0f%% da altura" % (100.0 * caixa.size.y / float(tamanho.y)))
		var escala: float = float(mini(tamanho.x, tamanho.y)) / 1080.0
		var centro_logica: Vector2 = Vector2(1920.0, 1080.0) / 2.0
		var esperado: Rect2 = Rect2((referencia.position - centro_logica) * escala + Vector2(tamanho) / 2.0, referencia.size * escala)
		var tolerancia: float = 0.012 * float(mini(tamanho.x, tamanho.y)) + 8.0
		_ok(absf(caixa.position.x - esperado.position.x) <= tolerancia and absf(caixa.position.y - esperado.position.y) <= tolerancia and absf(caixa.size.x - esperado.size.x) <= tolerancia and absf(caixa.size.y - esperado.size.y) <= tolerancia, "%s: a logo está centralizada e em escala uniforme (caixa %s, esperada %s)" % [nome, str(caixa), str(esperado)])
		_ok(absf(caixa.size.x / caixa.size.y - referencia.size.x / referencia.size.y) < 0.03, "%s: a proporção da logo não muda (%.3f contra %.3f em 16x9)" % [nome, caixa.size.x / caixa.size.y, referencia.size.x / referencia.size.y])
		_ok(_cantos_pretos(imagem), "%s: os cantos e as faixas laterais são pretos puros (sem barras brancas nem bordas)" % nome)
		if nome == "4x3" or nome == "9x16":
			await _foto_de(sub, "geometria_" + nome)
		sub.queue_free()
		await _arvore.process_frame
		if is_instance_valid(splash):
			splash.queue_free()
	GerenciadorConfiguracoes.definir("reduzir_animacoes", false, false)
	# B) vídeo: o retângulo do player tem 16:9, fica centralizado e encostado nas bordas da menor dimensão
	for proporcao in PROPORCOES:
		var nome: String = str(proporcao[0])
		var tamanho: Vector2i = proporcao[1]
		var sub: SubViewport = await _montar_viewport(tamanho)
		var splash: SplashScreen = _adicionar_splash(sub, {})
		var tocando: bool = await _esperar_ate(func() -> bool: return splash.video_em_reproducao(), 6.0)
		_ok(tocando, "%s: o vídeo começou a passar" % nome)
		if tocando:
			await _esperar(0.3)
			var player: VideoStreamPlayer = splash.get_node("%VideoLogo") as VideoStreamPlayer
			var retangulo: Rect2 = player.get_global_rect()
			var dentro: bool = retangulo.position.x >= -0.5 and retangulo.position.y >= -0.5 and retangulo.end.x <= float(tamanho.x) + 0.5 and retangulo.end.y <= float(tamanho.y) + 0.5
			var encostado: bool = absf(retangulo.size.x - float(tamanho.x)) < 1.0 or absf(retangulo.size.y - float(tamanho.y)) < 1.0
			var centro_ok: bool = retangulo.get_center().distance_to(Vector2(tamanho) / 2.0) < 1.0
			_ok(absf(retangulo.size.x / retangulo.size.y - 16.0 / 9.0) < 0.01, "%s: o vídeo mantém a proporção 16:9 (%s)" % [nome, str(retangulo.size)])
			_ok(dentro and encostado and centro_ok, "%s: o vídeo está dentro da tela, encostado em uma das dimensões e centralizado (%s em %s)" % [nome, str(retangulo), str(tamanho)])
		sub.queue_free()
		await _arvore.process_frame
	_ok(_contar_nos_do_tipo("VideoStreamPlayer") == 0 and _contar_cenas(SplashScreen) == 0, "as Splashes de teste foram embora da árvore (nenhum player sobrando)")


func _montar_viewport(tamanho: Vector2i) -> SubViewport:
	var sub: SubViewport = SubViewport.new()
	sub.size = tamanho
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_arvore.root.add_child(sub)
	await _arvore.process_frame
	return sub


## Instancia a Splash dentro de um SubViewport (o Theme global só desce até os filhos diretos da janela, então ele é copiado).
func _adicionar_splash(pai: Node, ajustes: Dictionary) -> SplashScreen:
	SplashScreen.ja_exibida = false
	var splash: SplashScreen = (load(Cenas.SPLASH) as PackedScene).instantiate() as SplashScreen
	splash.caminho_destino = _destino_stub
	splash.theme = _arvore.root.theme
	for chave in ajustes:
		splash.set(str(chave), ajustes[chave])
	pai.add_child(splash)
	return splash


## Caixa (em pixels) do que não é fundo preto na imagem, medida numa versão reduzida em quatro vezes.
func _caixa_do_logo(imagem: Image) -> Rect2:
	var reduzida: Image = imagem.duplicate() as Image
	var fator: int = 4
	reduzida.resize(maxi(1, int(imagem.get_width() * 0.25)), maxi(1, int(imagem.get_height() * 0.25)), Image.INTERPOLATE_BILINEAR)
	var x0: int = 1000000
	var y0: int = 1000000
	var x1: int = -1
	var y1: int = -1
	for y in reduzida.get_height():
		for x in reduzida.get_width():
			var c: Color = reduzida.get_pixel(x, y)
			if maxf(c.r, maxf(c.g, c.b)) > 0.12:
				x0 = mini(x0, x)
				y0 = mini(y0, y)
				x1 = maxi(x1, x)
				y1 = maxi(y1, y)
	if x1 < 0:
		return Rect2()
	return Rect2(Vector2(x0 * fator, y0 * fator), Vector2((x1 - x0 + 1) * fator, (y1 - y0 + 1) * fator))


## Os quatro cantos da imagem (blocos de 8x8) e a coluna do meio da borda esquerda são pretos puros.
func _cantos_pretos(imagem: Image) -> bool:
	var largura: int = imagem.get_width()
	var altura: int = imagem.get_height()
	for origem in [Vector2i(0, 0), Vector2i(largura - 8, 0), Vector2i(0, altura - 8), Vector2i(largura - 8, altura - 8), Vector2i(0, int(altura * 0.5)), Vector2i(largura - 8, int(altura * 0.5))]:
		var o: Vector2i = origem
		for dy in 8:
			for dx in 8:
				var c: Color = imagem.get_pixel(o.x + dx, o.y + dy)
				if c.r > 0.0 or c.g > 0.0 or c.b > 0.0:
					return false
	return true


# ------------------------------------------------------------------ 4) execução limpa
func _etapa_execucao_limpa() -> void:
	_registrar("== execução limpa: Splash (vídeo inteiro, sem tocar em nada) -> Menu Principal")
	_configurar_padrao()
	var splash: SplashScreen = await _abrir_splash_real("execução limpa")
	if splash == null:
		return
	var inicio: int = Time.get_ticks_msec()
	var video: VideoStreamPlayer = splash.get_node("%VideoLogo") as VideoStreamPlayer
	var logo: TextureRect = splash.get_node("%LogoFallback") as TextureRect
	# o primeiro quadro desenhado já tem a logo estática, sobre preto, sem nada branco
	await RenderingServer.frame_post_draw
	var primeiro: float = _luma_media_da_tela()
	_ok(logo.visible and is_equal_approx(logo.modulate.a, 1.0) and video.modulate.a == 0.0, "o primeiro quadro mostra a logo estática inteira e o vídeo ainda invisível")
	_ok(primeiro > 0.02 and primeiro < 0.30, "o primeiro quadro desenhado tem a logo sobre preto (luminância média %.3f; um quadro vazio seria 0 e um branco, perto de 1)" % primeiro)
	await _foto("01_primeiro_quadro_logo_estatica")
	_ok(_contar_nos_do_tipo("VideoStreamPlayer") == 1 and _contar_audio_players() == _audio_players_no_inicio, "um único VideoStreamPlayer e nenhum player de áudio a mais que os do jogo (%d)" % _contar_audio_players())
	_ok(video.bus == &"BGM" and not video.autoplay, "o som do vídeo passa pelo barramento BGM (volume do jogador) e o vídeo não tem autoplay")
	# observa os quadros da abertura: nenhum branco e o vídeo entra sozinho
	var maxima: float = primeiro
	var quadro_do_video_s: float = -1.0
	var fim_da_observacao: int = Time.get_ticks_msec() + 2500
	while Time.get_ticks_msec() < fim_da_observacao:
		await RenderingServer.frame_post_draw
		maxima = maxf(maxima, _luma_media_da_tela())
		if quadro_do_video_s < 0.0 and splash.video_em_reproducao():
			quadro_do_video_s = float(Time.get_ticks_msec() - inicio) / 1000.0
	_ok(quadro_do_video_s > 0.0 and quadro_do_video_s < 3.0, "o vídeo começa sozinho, sem pedir clique (primeiro quadro válido em %.2f s)" % quadro_do_video_s)
	_ok(maxima < 0.30, "nenhum dos quadros da abertura é branco (luminância média máxima %.3f)" % maxima)
	_ok(not logo.visible and video.modulate.a == 1.0, "depois do primeiro quadro válido a logo estática sai e o vídeo aparece")
	_ok(is_equal_approx(video.volume_db, splash.ganho_audio_db), "o som do vídeo toca com o ganho de calibração (%.1f dB) sobre o volume do jogador" % video.volume_db)
	# acompanha até o fim: pico do som no barramento BGM, motivo da saída e chegada ao Menu
	var pico_maximo: float = -80.0
	var motivo: String = ""
	var foto_tirada: bool = false
	var fim: int = Time.get_ticks_msec() + int(LIMITE_TROCA * 1000.0)
	var menu: Node = null
	while Time.get_ticks_msec() < fim:
		if is_instance_valid(splash):
			pico_maximo = maxf(pico_maximo, _pico_bgm_db())
			if motivo == "" and splash.transicao_iniciada():
				motivo = splash.motivo_da_saida()
			if not foto_tirada and video.stream_position > 7.0:
				foto_tirada = true
				await _foto("02_video_logo_completa")
		var cena: Node = _cena_atual()
		if cena is MenuPrincipal and not Cenas.em_transicao():
			menu = cena
			break
		await _arvore.process_frame
	var duracao: float = float(Time.get_ticks_msec() - inicio) / 1000.0
	_ok(menu != null, "o Menu Principal abre sozinho no fim do vídeo (%.1f s depois da abertura)" % duracao)
	_ok(duracao > 9.5 and duracao < 15.0, "a abertura dura a animação inteira: %.1f s (o vídeo tem 10 s)" % duracao)
	_ok(motivo == "fim da animação", "a saída foi pelo fim da animação (motivo: '%s')" % motivo)
	_ok(pico_maximo > -70.0, "o som do vídeo foi mixado no barramento BGM (pico %.1f dB)" % pico_maximo)
	if menu == null:
		return
	await _esperar(1.0)
	_verificar_chegada_ao_menu("execução limpa", true)


## O que vale ao chegar ao Menu Principal depois da Splash (execução limpa ou pulo).
func _verificar_chegada_ao_menu(rotulo: String, olhar_som: bool) -> void:
	var menu: MenuPrincipal = _cena_atual() as MenuPrincipal
	if not _ok(menu != null, "%s: a cena atual é o Menu Principal" % rotulo):
		return
	_ok(_contagem("MenuPrincipal") == 1, "%s: o Menu Principal foi criado uma única vez (sem instância dupla)" % rotulo)
	_ok(_contagem("TelaBoot") == 0 and _contagem("AreaDeTrabalho") == 0, "%s: a BIOS (TelaBoot) e o jogo (área de trabalho) não foram abertos" % rotulo)
	_ok(not GerenciadorNarrativa.jogo_ativo and not _arvore.paused and not Cenas.em_transicao(), "%s: nenhum jogo ativo, árvore sem pausa e sem troca em curso" % rotulo)
	_ok(_contar_cenas(SplashScreen) == 0 and _contar_nos_do_tipo("VideoStreamPlayer") == 0, "%s: a Splash e o player de vídeo saíram da árvore" % rotulo)
	_ok(_botao(menu, "BotaoNovoJogo").has_focus() and not _botao(menu, "BotaoNovoJogo").disabled, "%s: o Menu responde (foco em Novo Jogo, botão ativo)" % rotulo)
	_ok(not SistemaPersistencia.existe_salvamento() and not SistemaPersistencia.existe_ponto_de_carga(), "%s: a Splash não criou salvamento nem checkpoint" % rotulo)
	_ok(_contar_audio_players() == _audio_players_no_inicio, "%s: nenhum player de áudio ficou sobrando" % rotulo)
	if olhar_som:
		_ok(_pico_bgm_db() < -70.0, "%s: não há som residual no Menu (pico do BGM %.1f dB)" % [rotulo, _pico_bgm_db()])
	_ok(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("BGM")) - _volume_bgm_db_no_inicio) < 0.01, "%s: o volume do barramento BGM não foi alterado" % rotulo)


# ------------------------------------------------------------------ 5) pular
func _etapa_pular() -> void:
	_registrar("== pular a abertura (o vídeo e o som param e o Menu abre uma única vez)")
	await _variante_de_pulo("Espaço (com o som já audível)", func() -> void: await _tecla_fisica(KEY_SPACE), true)
	await _variante_de_pulo("Enter", func() -> void: await _tecla_fisica(KEY_ENTER))
	await _variante_de_pulo("Enter do teclado numérico", func() -> void: await _tecla_fisica(KEY_KP_ENTER))
	await _variante_de_pulo("Esc", func() -> void: await _tecla_fisica(KEY_ESCAPE))
	await _variante_de_pulo("clique esquerdo do mouse", func() -> void: await _clique_na_posicao(_arvore.root.get_final_transform() * Vector2(960.0, 540.0)))
	await _variante_de_pulo("clique direito do mouse", func() -> void: await _clique_na_posicao(_arvore.root.get_final_transform() * Vector2(960.0, 540.0), MOUSE_BUTTON_RIGHT))
	await _variante_de_pulo("botão A do controle", func() -> void: await _botao_do_controle(JOY_BUTTON_A))
	await _variante_de_pulo("botão B do controle", func() -> void: await _botao_do_controle(JOY_BUTTON_B))
	await _variante_de_pulo("entradas repetidas (6 Enter, 2 cliques e Esc, em sequência)", func() -> void:
		for i in 6:
			await _tecla_fisica(KEY_ENTER)
		await _clique_na_posicao(_arvore.root.get_final_transform() * Vector2(500.0, 300.0))
		await _clique_na_posicao(_arvore.root.get_final_transform() * Vector2(900.0, 600.0))
		await _tecla_fisica(KEY_ESCAPE))
	await _pular_durante_o_carregamento()
	await _roda_do_mouse_e_teclas_que_nao_pulam()


## Abre a Splash como na partida real, espera o vídeo passar, manda a entrada e confere tudo até o Menu.
func _variante_de_pulo(rotulo: String, enviar: Callable, olhar_som: bool = false) -> void:
	_configurar_padrao()
	var splash: SplashScreen = await _abrir_splash_real(rotulo)
	if splash == null:
		return
	var video: VideoStreamPlayer = splash.get_node("%VideoLogo") as VideoStreamPlayer
	var tocando: bool = await _esperar_ate(func() -> bool: return splash.video_em_reproducao(), 6.0)
	_ok(tocando, "%s: o vídeo está passando antes do pulo" % rotulo)
	var pico_antes: float = -80.0
	if olhar_som:
		await _esperar_ate(func() -> bool: return video.stream_position > 3.7, 8.0)
		pico_antes = _pico_bgm_db()
		_ok(pico_antes > -70.0, "%s: o som estava audível no barramento BGM (pico %.1f dB, posição %.1f s)" % [rotulo, pico_antes, video.stream_position])
	else:
		await _esperar(0.3)
	await enviar.call()
	var saida: Dictionary = await _acompanhar_saida(splash, video, MenuPrincipal)
	_ok(bool(saida["chegou"]), "%s: o Menu Principal abriu (%.2f s depois do pulo)" % [rotulo, float(saida["segundos"])])
	_ok(str(saida["motivo"]) == "pulada pelo jogador", "%s: a saída foi o pulo do jogador (motivo: '%s')" % [rotulo, str(saida["motivo"])])
	_ok(float(saida["video_parou_em"]) >= 0.0 and float(saida["video_parou_em"]) < 0.6, "%s: o vídeo parou logo depois do pulo (em %.2f s)" % [rotulo, float(saida["video_parou_em"])])
	await _esperar(0.8)
	_verificar_chegada_ao_menu(rotulo, true)
	if olhar_som:
		_ok(_pico_bgm_db() < pico_antes - 5.0, "%s: o som parou (pico %.1f dB antes, %.1f dB depois)" % [rotulo, pico_antes, _pico_bgm_db()])


## Pular no primeiro quadro, com o vídeo ainda carregando em segundo plano (a Splash instanciada e o Espaço no mesmo quadro).
func _pular_durante_o_carregamento() -> void:
	_configurar_padrao()
	_zerar_contagens()
	var splash: SplashScreen = _instanciar_splash_como_cena_atual({"caminho_destino": Cenas.MENU_PRINCIPAL})
	_ok(splash.fase_atual() == SplashScreen.Fase.CARREGANDO and not splash.video_em_reproducao(), "durante o carregamento: a Splash está carregando o vídeo em segundo plano (nenhum quadro ainda)")
	await _tecla_fisica(KEY_SPACE)
	var saida: Dictionary = await _acompanhar_saida(splash, splash.get_node("%VideoLogo") as VideoStreamPlayer, MenuPrincipal)
	_ok(bool(saida["chegou"]) and str(saida["motivo"]) == "pulada pelo jogador", "durante o carregamento: o Espaço leva ao Menu na hora (motivo: '%s', %.2f s)" % [str(saida["motivo"]), float(saida["segundos"])])
	await _esperar(0.8)
	_verificar_chegada_ao_menu("durante o carregamento", true)


## A roda do mouse e uma tecla qualquer não pulam: só as ações de aceitar e cancelar, os botões do mouse e os do controle.
func _roda_do_mouse_e_teclas_que_nao_pulam() -> void:
	_configurar_padrao()
	var splash: SplashScreen = await _abrir_splash_real("entradas que não pulam")
	if splash == null:
		return
	await _esperar_ate(func() -> bool: return splash.video_em_reproducao(), 6.0)
	for pressionado in [true, false]:
		var roda: InputEventMouseButton = InputEventMouseButton.new()
		roda.button_index = MOUSE_BUTTON_WHEEL_DOWN
		roda.pressed = pressionado
		roda.position = Vector2(400.0, 300.0)
		Input.parse_input_event(roda)
		await _arvore.process_frame
	await _tecla_fisica(KEY_A)
	await _tecla_fisica(KEY_SHIFT)
	await _esperar(0.5)
	_ok(not splash.transicao_iniciada() and splash.video_em_reproducao(), "a roda do mouse, a letra A e o Shift não pulam a abertura (o vídeo segue passando)")
	await _tecla_fisica(KEY_SPACE)
	var saida: Dictionary = await _acompanhar_saida(splash, splash.get_node("%VideoLogo") as VideoStreamPlayer, MenuPrincipal)
	_ok(bool(saida["chegou"]), "depois disso o Espaço pula normalmente")
	await _esperar(0.5)


# ------------------------------------------------------------------ 6) falhas do vídeo
func _etapa_falhas_do_video() -> void:
	_registrar("== falhas do vídeo: a logo estática fica e o jogador chega ao Menu (aqui, ao destino de teste)")
	await _falha_de_video("arquivo ausente", {"caminho_video": "res://features/splash_screen/assets/nao_existe.ogv"})
	await _falha_de_video("caminho vazio", {"caminho_video": ""})
	await _falha_de_video("formato desconhecido (.mp4)", {"caminho_video": _video_h264_mp4})
	await _falha_de_video("codec incompatível (H.264 dentro de um .ogv)", {"caminho_video": _video_h264_disfarcado, "tempo_primeiro_quadro_s": 1.0})
	await _falha_de_video("arquivo de vídeo vazio", {"caminho_video": _video_vazio, "tempo_primeiro_quadro_s": 1.0})
	await _sinal_finished_que_nao_vem()
	await _pular_a_logo_estatica()


## Instancia a Splash com `ajustes` e confere: logo estática desde o primeiro quadro, sem quadro branco, saída sozinha para o destino de teste.
func _falha_de_video(rotulo: String, ajustes: Dictionary) -> void:
	_configurar_padrao()
	_zerar_contagens()
	var ajuste: Dictionary = ajustes.duplicate()
	ajuste["duracao_estatica_s"] = 1.5
	var splash: SplashScreen = _instanciar_splash_como_cena_atual(ajuste)
	var video: VideoStreamPlayer = splash.get_node("%VideoLogo") as VideoStreamPlayer
	var logo: TextureRect = splash.get_node("%LogoFallback") as TextureRect
	await RenderingServer.frame_post_draw
	var primeiro: float = _luma_media_da_tela()
	_ok(logo.visible and is_equal_approx(logo.modulate.a, 1.0) and primeiro > 0.02 and primeiro < 0.30, "%s: a logo estática está na tela no primeiro quadro (luminância média %.3f, nada branco nem vazio)" % [rotulo, primeiro])
	var maxima: float = primeiro
	var minima: float = primeiro
	var inicio: int = Time.get_ticks_msec()
	var fase_estatica_vista: bool = false
	var foto_tirada: bool = false
	var motivo: String = ""
	while Time.get_ticks_msec() - inicio < 12000:
		await RenderingServer.frame_post_draw
		if is_instance_valid(splash):
			if splash.modo_estatico():
				fase_estatica_vista = true
			if motivo == "" and splash.transicao_iniciada():
				motivo = splash.motivo_da_saida()
			if not splash.transicao_iniciada():
				var luma: float = _luma_media_da_tela()
				maxima = maxf(maxima, luma)
				minima = minf(minima, luma)
		# a foto é tirada durante a fase estática (depois da saída só sobra o destino de teste, que é preto)
		if rotulo == "arquivo ausente" and not foto_tirada and is_instance_valid(splash) and splash.modo_estatico() and not splash.transicao_iniciada():
			foto_tirada = true
			await _foto("03_falha_de_video_logo_estatica")
		var cena: Node = _cena_atual()
		if cena != null and cena.name == &"DestinoTeste" and not Cenas.em_transicao():
			break
	_ok(fase_estatica_vista, "%s: a Splash passou para a logo estática" % rotulo)
	_ok(maxima < 0.30 and minima > 0.02, "%s: enquanto a logo estática ficou, nenhum quadro foi branco ou vazio (luminância média entre %.3f e %.3f)" % [rotulo, minima, maxima])
	_ok(motivo == "fim da logo estática", "%s: depois do tempo seguro a Splash segue sozinha (motivo: '%s')" % [rotulo, motivo])
	var chegou: bool = _cena_atual() != null and _cena_atual().name == &"DestinoTeste"
	_ok(chegou and _contagem("TelaBoot") == 0 and _contagem("AreaDeTrabalho") == 0 and not _arvore.paused, "%s: o jogador chega ao destino sem BIOS, sem jogo e sem pausa" % rotulo)
	if is_instance_valid(video):
		_ok(not video.is_playing(), "%s: nenhum vídeo ficou tocando" % rotulo)
	if rotulo == "arquivo ausente":
		_ok(foto_tirada, "%s: a foto da logo estática foi tirada durante a fase estática" % rotulo)
	await _esperar(0.3)


## `finished` que nunca vem: o vídeo real em laço (não termina nunca) e um limite curto; a Splash precisa terminar sozinha.
func _sinal_finished_que_nao_vem() -> void:
	_configurar_padrao()
	_zerar_contagens()
	var splash: SplashScreen = _instanciar_splash_como_cena_atual({"tempo_maximo_reproducao_s": 1.0})
	var video: VideoStreamPlayer = splash.get_node("%VideoLogo") as VideoStreamPlayer
	video.loop = true
	var saida: Dictionary = await _acompanhar_saida(splash, video, "DestinoTeste")
	_ok(bool(saida["chegou"]) and str(saida["motivo"]) == "tempo máximo da animação", "`finished` que nunca vem: o limite de segurança encerra a abertura (motivo: '%s', %.1f s)" % [str(saida["motivo"]), float(saida["segundos"])])
	_ok(float(saida["total_s"]) > 1.0 and float(saida["total_s"]) < 8.0, "`finished` que nunca vem: a abertura termina em tempo razoável (limite de 1 s de vídeo; %.1f s no total)" % float(saida["total_s"]))
	await _esperar(0.8)
	_ok(_pico_bgm_db() < -70.0 and _contar_nos_do_tipo("VideoStreamPlayer") == 0, "`finished` que nunca vem: o som parou e o player foi liberado")


## Mesmo no modo estático o jogador pode pular de imediato (a logo estática por um tempo mínimo, mas nunca presa).
func _pular_a_logo_estatica() -> void:
	_configurar_padrao()
	_zerar_contagens()
	var splash: SplashScreen = _instanciar_splash_como_cena_atual({"caminho_video": "res://features/splash_screen/assets/nao_existe.ogv", "duracao_estatica_s": 30.0})
	await _esperar(0.4)
	_ok(splash.modo_estatico(), "logo estática de 30 s (vídeo ausente): a Splash está só com a imagem")
	await _tecla_fisica(KEY_ENTER)
	var saida: Dictionary = await _acompanhar_saida(splash, splash.get_node("%VideoLogo") as VideoStreamPlayer, "DestinoTeste")
	_ok(bool(saida["chegou"]) and str(saida["motivo"]) == "pulada pelo jogador" and float(saida["segundos"]) < 3.0, "logo estática: Enter pula na hora (%.2f s)" % float(saida["segundos"]))


# ------------------------------------------------------------------ 7) falhas do destino
func _etapa_falhas_do_destino() -> void:
	_registrar("== falhas do destino: o Menu ausente ou ilegível não deixa o jogador preso")
	_configurar_padrao()
	_zerar_contagens()
	var splash: SplashScreen = _instanciar_splash_como_cena_atual({"caminho_destino": "res://features/menu_principal/scenes/nao_existe.tscn"})
	await _esperar_ate(func() -> bool: return splash.video_em_reproducao(), 6.0)
	await _tecla_fisica(KEY_SPACE)
	var apareceu: bool = await _esperar_ate(func() -> bool: return splash.falha_no_destino(), 6.0)
	_ok(apareceu, "Menu ausente: depois do pulo a Splash mostra o aviso de falha em vez de travar")
	if not apareceu:
		return
	var painel: Control = splash.get_node("%PainelFalha") as Control
	var tentar: Button = splash.get_node("%BotaoTentarNovamente") as Button
	var sair: Button = splash.get_node("%BotaoSair") as Button
	var video: VideoStreamPlayer = splash.get_node("%VideoLogo") as VideoStreamPlayer
	await _esperar(0.3)
	_ok(painel.visible and tentar.visible and sair.visible and tentar.has_focus(), "Menu ausente: o aviso tem 'Tentar novamente' (com o foco) e 'Sair do jogo'")
	_ok(not video.is_playing() and not Cenas.em_transicao() and not _arvore.paused, "Menu ausente: o vídeo e o som pararam, não há troca presa e a árvore não está pausada")
	_ok(_cena_atual() == splash and _contagem("TelaBoot") == 0 and _contagem("AreaDeTrabalho") == 0, "Menu ausente: o jogador continua na Splash; nem a BIOS nem o jogo foram abertos")
	var luma: float = _luma_media_da_tela()
	_ok(luma > 0.005 and luma < 0.30, "Menu ausente: a tela não está branca nem vazia (luminância média %.3f)" % luma)
	await _foto("04_falha_no_destino")
	# a repetição das entradas durante a falha não faz nada; o Enter no botão tenta de novo e agora o destino existe
	await _tecla_fisica(KEY_SPACE)
	await _esperar(0.3)
	_ok(splash.falha_no_destino() and is_instance_valid(splash) and _cena_atual() == splash, "Menu ausente: o Espaço não pula o aviso (só os botões agem)")
	splash.caminho_destino = _destino_stub
	await _tecla_fisica(KEY_ENTER)
	var saida: Dictionary = await _acompanhar_saida(splash, video, "DestinoTeste")
	_ok(bool(saida["chegou"]) and str(saida["motivo"]) == "nova tentativa", "Menu ausente: 'Tentar novamente' chega ao destino quando ele existe (motivo: '%s')" % str(saida["motivo"]))

	# cena que existe mas não carrega (falha do carregador, depois de a camada Cenas aceitar o pedido)
	_zerar_contagens()
	var ilegivel: SplashScreen = _instanciar_splash_como_cena_atual({"caminho_destino": _destino_quebrado, "caminho_video": "res://features/splash_screen/assets/nao_existe.ogv", "duracao_estatica_s": 0.5})
	var falhou: bool = await _esperar_ate(func() -> bool: return ilegivel.falha_no_destino(), 10.0)
	_ok(falhou, "cena ilegível: a falha assíncrona da camada Cenas também leva ao aviso (sem tela preta permanente)")
	if falhou:
		await _esperar(0.3)
		_ok(not Cenas.em_transicao() and not _arvore.paused and (ilegivel.get_node("%BotaoTentarNovamente") as Button).has_focus(), "cena ilegível: a guarda da camada Cenas foi liberada e o botão 'Tentar novamente' tem o foco")
	if is_instance_valid(ilegivel):
		ilegivel.queue_free()
		_arvore.current_scene = null
		await _arvore.process_frame
	Cenas.liberar()


# ------------------------------------------------------------------ 8) acessibilidade
func _etapa_acessibilidade() -> void:
	_registrar("== acessibilidade: modo conforto, sem flashes, reduzir animações, alto contraste, ruído e volume")
	for chave in ["reduzir_animacoes", "sem_flashes", "reduzir_glitch"]:
		_configurar_padrao()
		_zerar_contagens()
		GerenciadorConfiguracoes.definir(str(chave), true, false)
		var splash: SplashScreen = _instanciar_splash_como_cena_atual({"duracao_estatica_s": 1.5})
		var video: VideoStreamPlayer = splash.get_node("%VideoLogo") as VideoStreamPlayer
		await _esperar(0.4)
		_ok(splash.modo_estatico() and video.stream == null and not video.is_playing(), "%s: a animação (com glitch) não toca; fica a logo estática" % chave)
		_ok((splash.get_node("%LogoFallback") as TextureRect).visible and _pico_bgm_db() < -70.0, "%s: a logo estática está à vista e nenhum som toca" % chave)
		var saida: Dictionary = await _acompanhar_saida(splash, video, "DestinoTeste")
		_ok(bool(saida["chegou"]) and str(saida["motivo"]) == "fim da logo estática", "%s: depois do tempo mínimo vai ao destino (motivo: '%s', %.1f s)" % [chave, str(saida["motivo"]), float(saida["segundos"])])
		if chave == "reduzir_animacoes":
			_ok(float(saida["total_s"]) >= 1.4 and float(saida["total_s"]) < 3.5 and float(saida["segundos"]) < 0.6, "reduzir_animacoes: a logo estática fica o tempo mínimo (%.2f s no total) e sai com fade curto (%.2f s)" % [float(saida["total_s"]), float(saida["segundos"])])
	# reduzir tremor e reduzir ruído não impedem o vídeo; o ruído abaixa o som em 6 dB
	_configurar_padrao()
	_zerar_contagens()
	GerenciadorConfiguracoes.definir("reduzir_tremor", true, false)
	GerenciadorConfiguracoes.definir("reduzir_ruido", true, false)
	var com_ruido: SplashScreen = _instanciar_splash_como_cena_atual({})
	var video_ruido: VideoStreamPlayer = com_ruido.get_node("%VideoLogo") as VideoStreamPlayer
	var passou: bool = await _esperar_ate(func() -> bool: return com_ruido.video_em_reproducao(), 6.0)
	_ok(passou, "reduzir tremor e ruído: o vídeo continua passando (só glitch, flashes e animações o substituem)")
	_ok(is_equal_approx(video_ruido.volume_db, com_ruido.ganho_audio_db + SplashScreen.REDUCAO_RUIDO_DB), "reduzir ruído: o som da abertura desce 6 dB (%.1f dB)" % video_ruido.volume_db)
	# mudar o ruído no meio do vídeo ajusta o volume; o modo conforto (atalho real Ctrl+Shift+D) troca o vídeo pela logo estática
	GerenciadorConfiguracoes.definir("reduzir_ruido", false, false)
	_ok(is_equal_approx(video_ruido.volume_db, com_ruido.ganho_audio_db), "desligar o ruído no meio do vídeo devolve o volume (%.1f dB)" % video_ruido.volume_db)
	await _atalho_fisico(KEY_D, true, true)
	await _esperar(0.4)
	_ok(GerenciadorConfiguracoes.modo_conforto_ativo(), "Ctrl+Shift+D funciona na Splash (modo conforto ligado)")
	_ok(com_ruido.modo_estatico() and not video_ruido.is_playing(), "modo conforto no meio do vídeo: o vídeo e o som param e fica a logo estática")
	await _esperar(0.5)
	_ok(_pico_bgm_db() < -70.0, "modo conforto: não sobra som (pico %.1f dB)" % _pico_bgm_db())
	await _tecla_fisica(KEY_SPACE)
	var saida_conforto: Dictionary = await _acompanhar_saida(com_ruido, video_ruido, "DestinoTeste")
	_ok(bool(saida_conforto["chegou"]), "modo conforto: o jogador ainda pode pular")
	# alto contraste: o aviso de pulo aparece nítido (opaco) em vez de discreto
	for contraste in [false, true]:
		_configurar_padrao()
		_zerar_contagens()
		GerenciadorConfiguracoes.definir("alto_contraste", contraste, false)
		var splash_contraste: SplashScreen = _instanciar_splash_como_cena_atual({})
		await _esperar(1.0 + 0.5 + 0.4)
		var aviso: Label = splash_contraste.get_node("%IndicadorPular") as Label
		var esperado: float = 1.0 if contraste else SplashScreen.ALFA_DICA
		_ok(is_equal_approx(aviso.modulate.a, esperado) and aviso.visible, "alto contraste %s: o aviso 'Pressione Espaço para pular' aparece com opacidade %.2f (veio %.2f)" % [str(contraste), esperado, aviso.modulate.a])
		if contraste:
			await _foto("05_alto_contraste_aviso")
		await _tecla_fisica(KEY_SPACE)
		await _acompanhar_saida(splash_contraste, splash_contraste.get_node("%VideoLogo") as VideoStreamPlayer, "DestinoTeste")
	# volume: o vídeo usa o barramento BGM, que obedece ao volume geral e ao de música; o mudo geral vale para a abertura também
	_configurar_padrao()
	_zerar_contagens()
	GerenciadorConfiguracoes.definir("volume_master", 0.0, false)
	var sem_volume: SplashScreen = _instanciar_splash_como_cena_atual({})
	await _esperar_ate(func() -> bool: return sem_volume.video_em_reproducao(), 6.0)
	var mestre: int = AudioServer.get_bus_index("Master")
	var bgm: int = AudioServer.get_bus_index("BGM")
	_ok(AudioServer.is_bus_mute(mestre) and AudioServer.get_bus_send(bgm) == &"Master" and (sem_volume.get_node("%VideoLogo") as VideoStreamPlayer).bus == &"BGM", "volume geral zerado: o vídeo (barramento BGM, que envia ao Master mudo) fica sem som")
	await _tecla_fisica(KEY_SPACE)
	await _acompanhar_saida(sem_volume, sem_volume.get_node("%VideoLogo") as VideoStreamPlayer, "DestinoTeste")
	_configurar_padrao()
	_ok(not AudioServer.is_bus_mute(mestre) and absf(AudioServer.get_bus_volume_db(bgm) - _volume_bgm_db_no_inicio) < 0.01, "o volume do jogador volta como estava (a Splash não altera os barramentos)")


# ------------------------------------------------------------------ 9) uma vez por execução e integridade
func _etapa_uma_vez_e_integridade() -> void:
	_registrar("== uma vez por execução e integridade do jogo")
	_configurar_padrao()
	_zerar_contagens()
	SplashScreen.ja_exibida = true
	var pacote: PackedScene = load(Cenas.SPLASH) as PackedScene
	var repetida: SplashScreen = pacote.instantiate() as SplashScreen
	repetida.caminho_destino = _destino_stub
	var cena_anterior: Node = _cena_atual()
	_arvore.root.add_child(repetida)
	_arvore.current_scene = repetida
	if cena_anterior != null and is_instance_valid(cena_anterior):
		cena_anterior.queue_free()  # sem isto o destino chegaria com outro nome (a Godot renomeia nós irmãos de mesmo nome)
	_marca_instancia_ms = Time.get_ticks_msec()
	var saida: Dictionary = await _acompanhar_saida(repetida, repetida.get_node("%VideoLogo") as VideoStreamPlayer, "DestinoTeste")
	_ok(bool(saida["chegou"]) and str(saida["motivo"]) == "a abertura já foi exibida nesta execução", "a Splash já exibida nesta execução vai direto ao destino, sem vídeo (motivo: '%s')" % str(saida["motivo"]))
	_ok(_contar_nos_do_tipo("VideoStreamPlayer") == 0 and _pico_bgm_db() < -70.0, "a Splash repetida não tocou vídeo nem som")
	# autoloads únicos e sem sobras
	var duplicados: Array = []
	for propriedade in ProjectSettings.get_property_list():
		var nome_propriedade: String = str(propriedade["name"])
		if nome_propriedade.begins_with("autoload/"):
			var nome: String = nome_propriedade.substr(9)
			var total: int = 0
			for filho in _arvore.root.get_children():
				if str(filho.name) == nome:
					total += 1
			if total != 1:
				duplicados.append("%s=%d" % [nome, total])
	_ok(duplicados.is_empty(), "cada autoload existe uma única vez na árvore (problemas: %s)" % str(duplicados))
	_ok(_contar_audio_players() == _audio_players_no_inicio and not _arvore.paused and not Cenas.em_transicao(), "nenhum player de áudio a mais, árvore sem pausa e sem troca em curso")
	var arquivos_do_save: PackedStringArray = DirAccess.get_files_at(_pasta + "/salvamento") if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_pasta + "/salvamento")) else PackedStringArray()
	_ok(arquivos_do_save.is_empty(), "a Splash não gravou nenhum arquivo de salvamento (%d arquivos)" % arquivos_do_save.size())
	# a janela fechada no meio do vídeo: o som para e nada tenta trocar de cena
	_configurar_padrao()
	_zerar_contagens()
	var fechada: SplashScreen = _instanciar_splash_como_cena_atual({})
	var video: VideoStreamPlayer = fechada.get_node("%VideoLogo") as VideoStreamPlayer
	await _esperar_ate(func() -> bool: return fechada.video_em_reproducao(), 6.0)
	await _esperar(1.2)
	fechada.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	_ok(fechada.transicao_iniciada() and not video.is_playing(), "janela fechada no meio do vídeo: o vídeo e o som param e nenhuma troca de cena começa")
	_arvore.current_scene = null
	fechada.queue_free()
	await _esperar(0.8)
	_ok(_contar_nos_do_tipo("VideoStreamPlayer") == 0 and _pico_bgm_db() < -70.0 and not Cenas.em_transicao() and _contagem("DestinoTeste") == 0, "janela fechada: o player foi liberado, não há som residual nem troca em curso")


# ------------------------------------------------------------------ apoio: cenas
## A partida real: o motor instancia a cena principal do projeto sem passar por `Cenas`. Devolve a Splash (ou null).
func _abrir_splash_real(rotulo: String) -> SplashScreen:
	SplashScreen.ja_exibida = false
	_zerar_contagens()
	var anterior: Node = _cena_atual()
	var id_anterior: int = anterior.get_instance_id() if anterior != null else 0
	if not _ok(_arvore.change_scene_to_file(Cenas.SPLASH) == OK, "%s: a Splash entra como cena principal, como na partida real" % rotulo):
		return null
	var chegou: bool = await _esperar_ate(func() -> bool:
		var cena: Node = _cena_atual()
		return cena is SplashScreen and cena.get_instance_id() != id_anterior, 8.0)
	if not _ok(chegou, "%s: a Splash chegou" % rotulo):
		return null
	return _cena_atual() as SplashScreen


## Instancia a Splash e a põe como cena atual (para ela poder trocar de cena como na partida real), com o destino de teste.
func _instanciar_splash_como_cena_atual(ajustes: Dictionary) -> SplashScreen:
	SplashScreen.ja_exibida = false
	var splash: SplashScreen = (load(Cenas.SPLASH) as PackedScene).instantiate() as SplashScreen
	splash.caminho_destino = _destino_stub
	for chave in ajustes:
		splash.set(str(chave), ajustes[chave])
	var anterior: Node = _cena_atual()
	_arvore.root.add_child(splash)
	_arvore.current_scene = splash
	if anterior != null and anterior != splash and is_instance_valid(anterior):
		anterior.queue_free()
	_marca_instancia_ms = Time.get_ticks_msec()
	return splash


## Acompanha a Splash até ela sair: o motivo da saída (lido enquanto ela existe), quando o vídeo parou e a chegada da cena de destino.
## `destino`: uma classe (MenuPrincipal) ou o nome do nó raiz (String) da cena esperada.
func _acompanhar_saida(splash: SplashScreen, video: VideoStreamPlayer, destino: Variant, limite: float = LIMITE_TROCA) -> Dictionary:
	var id_splash: int = splash.get_instance_id()
	var inicio: int = Time.get_ticks_msec()
	var marca_saida: int = 0
	var motivo: String = ""
	var video_parou_em: float = -1.0
	var chegou: bool = false
	while float(Time.get_ticks_msec() - inicio) / 1000.0 < limite:
		if is_instance_valid(splash) and splash.get_instance_id() == id_splash:
			if motivo == "" and splash.transicao_iniciada():
				motivo = splash.motivo_da_saida()
				marca_saida = Time.get_ticks_msec()
			if marca_saida > 0 and video_parou_em < 0.0 and is_instance_valid(video) and not video.is_playing():
				video_parou_em = float(Time.get_ticks_msec() - marca_saida) / 1000.0
		var cena: Node = _cena_atual()
		if cena != null and cena.get_instance_id() != id_splash and _eh_destino(cena, destino) and not Cenas.em_transicao():
			chegou = true
			break
		await _arvore.process_frame
	if video_parou_em < 0.0 and marca_saida > 0:
		video_parou_em = 0.0 if (not is_instance_valid(video) or not video.is_playing()) else -1.0
	var agora: int = Time.get_ticks_msec()
	var segundos: float = float(agora - (marca_saida if marca_saida > 0 else inicio)) / 1000.0
	## Do instante em que a Splash foi instanciada até a chegada ao destino (inclui a animação, o fade e a espera pelo silêncio).
	var total_s: float = float(agora - (_marca_instancia_ms if _marca_instancia_ms > 0 else inicio)) / 1000.0
	if chegou:
		await _esperar(0.4)  # o primeiro quadro da cena nova, o foco inicial e o que é adiado
	return {"motivo": motivo, "chegou": chegou, "video_parou_em": video_parou_em, "segundos": segundos, "total_s": total_s}


func _eh_destino(cena: Node, destino: Variant) -> bool:
	if destino is String:
		return cena.name == StringName(str(destino))
	return is_instance_of(cena, destino)


func _cena_atual() -> Node:
	var cena: Node = _arvore.current_scene
	return cena if cena != null and is_instance_valid(cena) else null   # ternario-ok: o outro ramo é um objeto


## Quantos nós do tipo `tipo` há diretamente sob a raiz (para provar que nenhuma cena ficou duplicada ou esquecida).
func _contar_cenas(tipo: Variant) -> int:
	var total: int = 0
	for filho in _arvore.root.get_children():
		if is_instance_valid(filho) and not filho.is_queued_for_deletion() and is_instance_of(filho, tipo):
			total += 1
	return total


func _contar_nos_do_tipo(classe: String) -> int:
	var total: int = 0
	for no in _arvore.root.find_children("*", classe, true, false):
		if not no.is_queued_for_deletion():
			total += 1
	return total


func _contar_audio_players() -> int:
	return _contar_nos_do_tipo("AudioStreamPlayer")


func _ao_no_adicionado(no: Node) -> void:
	var chave: String = ""
	if no is MenuPrincipal:
		chave = "MenuPrincipal"
	elif no is TelaBoot:
		chave = "TelaBoot"
	elif no is AreaDeTrabalho:
		chave = "AreaDeTrabalho"
	elif no.name == &"DestinoTeste":
		chave = "DestinoTeste"
	if chave != "":
		_criados[chave] = int(_criados.get(chave, 0)) + 1


func _contagem(chave: String) -> int:
	return int(_criados.get(chave, 0))


func _zerar_contagens() -> void:
	_criados.clear()


## Preferências de fábrica (sem modo conforto, volumes padrão) para cada cenário; nada disso vai para o disco.
func _configurar_padrao() -> void:
	GerenciadorConfiguracoes.valores = GerenciadorConfiguracoes.PADRAO.duplicate()
	SistemaAudio.aplicar_volumes()


# ------------------------------------------------------------------ apoio: arquivos de teste
func _preparar_arquivos_de_teste() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_pasta))
	var raiz: Control = Control.new()
	raiz.name = "DestinoTeste"
	var pacote: PackedScene = PackedScene.new()
	pacote.pack(raiz)
	raiz.free()
	_destino_stub = _pasta + "/destino_teste.tscn"
	ResourceSaver.save(pacote, _destino_stub)
	_destino_quebrado = _pasta + "/cena_ilegivel.tscn"
	_gravar_texto(_destino_quebrado, "isto não é uma cena da Godot\n[gd_scene\n")
	var h264: PackedByteArray = Marshalls.base64_to_raw(MP4_H264_B64)
	_video_h264_disfarcado = _pasta + "/video_h264_disfarcado.ogv"
	_video_h264_mp4 = _pasta + "/video_h264.mp4"
	_video_vazio = _pasta + "/video_vazio.ogv"
	_gravar_bytes(_video_h264_disfarcado, h264)
	_gravar_bytes(_video_h264_mp4, h264)
	_gravar_bytes(_video_vazio, PackedByteArray())
	_ok(ResourceLoader.exists(_destino_stub) and FileAccess.file_exists(_video_h264_mp4) and h264.size() > 1000, "arquivos de teste prontos em %s (destino, cena ilegível e três vídeos falsos)" % _pasta)


func _nova_pasta() -> String:
	return "%s/exec_%d_%d" % [PASTA_BASE, int(Time.get_unix_time_from_system()), Time.get_ticks_usec() % 100000]


func _gravar_texto(caminho: String, texto: String) -> void:
	var f: FileAccess = FileAccess.open(caminho, FileAccess.WRITE)
	if f != null:
		f.store_string(texto)
		f.close()


func _gravar_bytes(caminho: String, bytes: PackedByteArray) -> void:
	var f: FileAccess = FileAccess.open(caminho, FileAccess.WRITE)
	if f != null:
		f.store_buffer(bytes)
		f.close()


func _botao(pai: Node, nome: String) -> Button:
	var botao: Button = pai.get_node_or_null("%" + nome) as Button
	if botao == null:
		_ok(false, "nó %%%s existe em %s" % [nome, pai.name])
		return Button.new()
	return botao


# ------------------------------------------------------------------ apoio: imagem, som e tempo
## Luminância média (0 a 1) do quadro atual da janela, numa versão reduzida.
func _luma_media_da_tela() -> float:
	var imagem: Image = get_viewport().get_texture().get_image()
	if imagem == null:
		return -1.0
	var pequena: Image = imagem.duplicate() as Image
	pequena.resize(64, 36, Image.INTERPOLATE_TRILINEAR)
	var soma: float = 0.0
	for y in 36:
		for x in 64:
			var c: Color = pequena.get_pixel(x, y)
			soma += 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
	return soma / 2304.0


## Pico (dB) mais alto dos dois canais do barramento BGM, o do som da abertura. -80 é silêncio.
func _pico_bgm_db() -> float:
	var indice: int = AudioServer.get_bus_index("BGM")
	if indice < 0:
		return -80.0
	return maxf(AudioServer.get_bus_peak_volume_left_db(indice, 0), AudioServer.get_bus_peak_volume_right_db(indice, 0))


func _esperar_quadros(quantos: int) -> void:
	for i in quantos:
		await RenderingServer.frame_post_draw


func _esperar_ate(condicao: Callable, limite: float = 10.0) -> bool:
	var inicio: int = Time.get_ticks_msec()
	while float(Time.get_ticks_msec() - inicio) / 1000.0 < limite:
		if bool(condicao.call()):
			return true
		await _arvore.process_frame
	return bool(condicao.call())


func _esperar(segundos: float) -> void:
	await _arvore.create_timer(segundos).timeout


# ------------------------------------------------------------------ apoio: entradas
## Tecla do teclado físico: o evento passa pelo mesmo caminho do jogo (Input -> janela -> GUI -> _unhandled_input).
func _tecla_fisica(codigo: Key) -> void:
	for pressionada in [true, false]:
		var evento: InputEventKey = InputEventKey.new()
		evento.keycode = codigo
		evento.physical_keycode = codigo
		evento.pressed = pressionada
		Input.parse_input_event(evento)
		await _arvore.process_frame


func _atalho_fisico(codigo: Key, ctrl: bool, shift: bool) -> void:
	for pressionada in [true, false]:
		var evento: InputEventKey = InputEventKey.new()
		evento.keycode = codigo
		evento.physical_keycode = codigo
		evento.ctrl_pressed = ctrl
		evento.shift_pressed = shift
		evento.pressed = pressionada
		Input.parse_input_event(evento)
		await _arvore.process_frame


## Clique do mouse de verdade (pressionar e soltar) na posição da janela, pelo mesmo caminho de entrada do jogador.
func _clique_na_posicao(posicao: Vector2, botao: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	for pressionado in [true, false]:
		var evento: InputEventMouseButton = InputEventMouseButton.new()
		evento.button_index = botao
		evento.pressed = pressionado
		evento.position = posicao
		evento.global_position = posicao
		Input.parse_input_event(evento)
		await _arvore.process_frame


func _botao_do_controle(botao: JoyButton) -> void:
	for pressionado in [true, false]:
		var evento: InputEventJoypadButton = InputEventJoypadButton.new()
		evento.button_index = botao
		evento.pressed = pressionado
		Input.parse_input_event(evento)
		await _arvore.process_frame


## Salva a imagem da janela do jogo em tests/_saida/splash/<nome>.png (conferência visual; não entra no resultado).
func _foto(nome: String) -> void:
	await RenderingServer.frame_post_draw
	var imagem: Image = get_viewport().get_texture().get_image()
	if imagem != null:
		imagem.save_png(ProjectSettings.globalize_path(SAIDA + nome + ".png"))


func _foto_de(vp: Viewport, nome: String) -> void:
	await RenderingServer.frame_post_draw
	var imagem: Image = vp.get_texture().get_image()
	if imagem != null:
		imagem.save_png(ProjectSettings.globalize_path(SAIDA + nome + ".png"))


func _ok(condicao: bool, mensagem: String) -> bool:
	_verificacoes += 1
	if not condicao:
		_falhas += 1
	_registrar("%s: %s" % ["OK" if condicao else "FALHA", mensagem])
	return condicao


func _registrar(linha: String) -> void:
	_log.append(linha)
	print("[splash] ", linha)


func _gravar() -> void:
	var f: FileAccess = FileAccess.open(SAIDA + "log.txt", FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(_log) + "\n")
		f.close()
