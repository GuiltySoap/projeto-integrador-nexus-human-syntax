class_name SplashScreen
extends Control
## Splash Screen: a abertura da marca ("Maya Human Syntax"). É a PRIMEIRA cena do jogo (`run/main_scene`) e fica fora da narrativa:
## só mostra a logo animada e entrega o jogador ao Menu Principal, quando a animação termina ou o jogador pula.
##   Executável -> Splash Screen -> Menu Principal -> { Novo Jogo (BIOS do HumaxOS, registro, Maya) | Carregar | Opções | Créditos }
## A Splash NÃO toca na BIOS do HumaxOS (TelaBoot), na área de trabalho, no estado de um novo jogo, na narrativa, na progressão, nos
## checkpoints, nos salvamentos, no terminal nem em app algum: ela só consome três serviços já existentes: `Cenas` (a única camada
## de troca de cena), `SistemaAudio` (o barramento BGM, que obedece ao volume do jogador) e `GerenciadorConfiguracoes` (acessibilidade).
##
## Como a imagem e o som chegam:
##   1) a logo ESTÁTICA (mayaos_intro_logo.png) aparece no primeiro quadro, sobre fundo preto: nunca há tela vazia ou branca;
##   2) o vídeo (maya_human_syntax_intro.ogv; a Godot só toca Ogg Theora, com som Ogg Vorbis) é pedido em segundo plano
##      (`ResourceLoader.load_threaded_request`) e iniciado uma única vez; o vídeo fica invisível até existir o primeiro quadro válido;
##   3) só então a logo estática se dissolve e o vídeo toca em tela cheia, sem distorcer (AspectRatioContainer), com o som no barramento
##      BGM (volume do jogador; "Reduzir ruído" abaixa 6 dB);
##   4) no fim (`finished`) ou ao pular, o vídeo e o som param, um fade curto escurece a tela e `Cenas.ir_para` abre o Menu Principal.
## Falhas (vídeo ausente ou ilegível, codec incompatível, importação, `finished` que nunca vem, recurso que nunca carrega) deixam a
## logo estática na tela por um tempo seguro e seguem para o Menu do mesmo jeito; o motivo vai para o log de desenvolvimento.
## Se o Menu não puder ser aberto, o jogador vê um aviso com "Tentar novamente" e "Sair do jogo" (nunca a BIOS, o jogo ou uma tela preta).
##
## Pular: Espaço/Enter (`ui_accept`), Esc (`ui_cancel`), qualquer botão do mouse, qualquer botão do controle ou toque na tela; as ações
## do InputMap são as que o jogo já usa (nenhuma ação nova). Vale em qualquer momento, inclusive enquanto o vídeo ainda carrega.
## Toda saída passa por `_ir_para_menu_principal`, protegida por `_transicao_iniciada`: o fim do vídeo, o pulo, o tempo limite e os
## cliques repetidos nunca trocam de cena duas vezes. Depois do fade, a troca espera o jogador parar de apertar por 0,25 s (no máximo 1 s):
## quem aperta Enter várias vezes para pular não acerta, sem querer, o primeiro botão do Menu.
## Acessibilidade: com "Reduzir glitch", "Sem flashes" ou "Reduzir animações" a animação (que tem uma rajada de glitch) não toca: fica a
## logo estática por um tempo mínimo e depois o Menu, sem fades. Ctrl+Shift+D (modo conforto) e F11 funcionam aqui como em qualquer tela.
## A abertura vale uma vez por execução do jogo (`ja_exibida`): nada no jogo volta a ela.

const CAMINHO_VIDEO := "res://features/splash_screen/assets/maya_human_syntax_intro.ogv"
## "Reduzir ruído" abaixa o som da abertura nesta quantidade (a mesma diferença que a trilha do jogo usa: -6 dB para -12 dB).
const REDUCAO_RUIDO_DB := -6.0
## Depois da falha do vídeo, a logo estática fica pelo menos este tempo (em segundos), para a marca ser vista.
const MINIMO_APOS_FALHA_S := 1.0
## Fade de saída com "Reduzir animações" ligado (o normal é `duracao_fade_saida_s`).
const DURACAO_FADE_REDUZIDO_S := 0.15
const DURACAO_DICA_S := 0.4
const ALFA_DICA := 0.7
const ALFA_LOGO_NA_FALHA := 0.25
## Descida curta do volume antes de parar o som ao pular (evita o estalo de um corte seco).
const DURACAO_SAIDA_DO_AUDIO_S := 0.12
## Quem aperta Espaço/Enter várias vezes para pular não pode acertar o primeiro botão do Menu: depois do fade, a troca espera o
## jogador ficar este tempo sem apertar (e, no pior caso, `LIMITE_ESPERA_PELO_SILENCIO_S` depois do fim do fade).
const SILENCIO_ANTES_DE_TROCAR_S := 0.25
const LIMITE_ESPERA_PELO_SILENCIO_S := 1.0
## Configurações que, ao serem ligadas, trocam a animação pela logo estática (a animação tem uma rajada de glitch).
const CHAVES_DA_ANIMACAO: Array = ["reduzir_glitch", "sem_flashes", "reduzir_animacoes"]

enum Fase { CARREGANDO, REPRODUZINDO, ESTATICA, SAINDO, FALHA_NO_DESTINO }

## A abertura aparece uma única vez por execução: se a cena for instanciada de novo no mesmo processo, vai direto ao destino.
## (Os testes zeram este marcador a cada instância.)
static var ja_exibida: bool = false

## Caminho do vídeo da logo (só Ogg Theora, `.ogv`, toca no núcleo da Godot 4.7). O padrão é o arquivo do projeto.
@export_file("*.ogv") var caminho_video: String = CAMINHO_VIDEO
## Cena que a abertura entrega ao terminar: sempre o Menu Principal. O campo existe para os testes e para quem queira trocar o destino.
@export_file("*.tscn") var caminho_destino: String = Cenas.MENU_PRINCIPAL
## Desligue só para exibir a abertura de novo no mesmo processo (por exemplo, uma futura opção "Assistir abertura").
@export var exibir_somente_uma_vez: bool = true
@export_group("Tempos (segundos)")
## Quanto esperar o vídeo ficar disponível antes de desistir dele.
@export var tempo_maximo_carga_s: float = 4.0
## Quanto esperar, depois de iniciar o vídeo, pelo primeiro quadro válido.
@export var tempo_primeiro_quadro_s: float = 3.0
## Limite de segurança para o vídeo inteiro (a animação dura 10 s): se `finished` nunca vier, a abertura termina mesmo assim.
@export var tempo_maximo_reproducao_s: float = 15.0
## Tempo mínimo da logo estática (falha do vídeo ou acessibilidade), contado desde a abertura da cena.
@export var duracao_estatica_s: float = 2.5
## Dissolução da logo estática quando o primeiro quadro do vídeo está pronto.
@export var duracao_dissolver_s: float = 0.5
## Fade para preto antes de trocar de cena (cai para 0,15 s com "Reduzir animações").
@export var duracao_fade_saida_s: float = 0.35
## Atraso para aparecer o aviso "Pressione Espaço para pular".
@export var atraso_dica_s: float = 1.0
@export_group("Áudio")
## O som da abertura foi masterizado baixo (cerca de -32 LUFS contra -20 LUFS das trilhas do jogo, que tocam a -6 dB):
## +6 dB iguala o nível ao da trilha do jogo nos volumes padrão. O volume geral, de música e o mudo do jogador continuam valendo.
@export var ganho_audio_db: float = 6.0

var _fase: int = Fase.CARREGANDO
var _pronta: bool = false
var _transicao_iniciada: bool = false
var _saida_imediata: bool = false
var _motivo_da_saida: String = ""
var _saida_pronta: bool = false
var _troca_pedida: bool = false
var _ultimo_pedido_s: float = -10.0
var _tempo_saindo: float = 0.0
var _modo_estatico: bool = false
var _carga_pedida: bool = false
var _reproducao_iniciada: bool = false
var _quadro_valido_visto: bool = false
var _dica_mostrada: bool = false
var _alfa_dica: float = ALFA_DICA
var _tempo_total: float = 0.0
var _tempo_na_fase: float = 0.0
var _tempo_reproduzindo: float = 0.0
var _duracao_da_fase_estatica: float = 0.0
var _tween_logo: Tween = null
var _tween_saida: Tween = null
var _tween_audio: Tween = null
var _cx := Conexoes.new()

@onready var _fundo: ColorRect = %FundoPreto
@onready var _proporcao: AspectRatioContainer = %ContainerVideo
@onready var _video: VideoStreamPlayer = %VideoLogo
@onready var _logo: TextureRect = %LogoFallback
@onready var _camada_interacao: Control = %CamadaInteracao
@onready var _dica: Label = %IndicadorPular
@onready var _painel_falha: Control = %PainelFalha
@onready var _rot_falha: Label = %MensagemFalha
@onready var _btn_tentar: Button = %BotaoTentarNovamente
@onready var _btn_sair: Button = %BotaoSair
@onready var _cortina: ColorRect = %FadeOverlay


func _ready() -> void:
	TemaNexus.aplicar(get_tree())
	_pronta = UiKit.refs_ok(self, {"FundoPreto": _fundo, "ContainerVideo": _proporcao, "VideoLogo": _video, "LogoFallback": _logo,
			"CamadaInteracao": _camada_interacao, "IndicadorPular": _dica, "PainelFalha": _painel_falha, "MensagemFalha": _rot_falha,
			"BotaoTentarNovamente": _btn_tentar, "BotaoSair": _btn_sair, "FadeOverlay": _cortina})
	if not _pronta:
		# Cena incompleta (não deveria acontecer): não prende o jogador, vai direto ao Menu.
		_saida_imediata = true
		_ir_para_menu_principal.call_deferred("a cena da abertura está incompleta")
		return
	_cx.ligar(GerenciadorConfiguracoes.configuracao_alterada, _ao_configuracao_alterada)
	# Estado do primeiro quadro: fundo preto, logo estática à vista, vídeo invisível (nada de quadro vazio ou branco), sem fade.
	_video.bus = SistemaAudio.BUS_BGM
	_video.modulate.a = 0.0
	_logo.visible = true
	_logo.modulate.a = 1.0
	_cortina.modulate.a = 0.0
	_painel_falha.visible = false
	_dica.modulate.a = 0.0
	_aplicar_estilo_da_dica()
	if exibir_somente_uma_vez and ja_exibida:
		_saida_imediata = true
		_ir_para_menu_principal.call_deferred("a abertura já foi exibida nesta execução")
		return
	ja_exibida = true
	if _deve_evitar_o_video():
		_iniciar_fase_estatica()
	else:
		_pedir_video()


func _exit_tree() -> void:
	# Saída por qualquer caminho (troca de cena, janela fechada, teste): nada de som, vídeo ou conexão sobrando.
	_transicao_iniciada = true
	_cx.desligar_tudo()
	for animacao in [_tween_logo, _tween_saida, _tween_audio]:
		var tween: Tween = animacao as Tween
		if tween != null and tween.is_valid():
			tween.kill()
	_parar_midia(false)
	if _video != null and is_instance_valid(_video):
		_video.stream = null
	_recolher_carga_pendente()


func _notification(que: int) -> void:
	if que == NOTIFICATION_WM_CLOSE_REQUEST:
		# Janela fechada durante a abertura: o som para junto, e nenhuma troca de cena começa no meio do fechamento.
		_transicao_iniciada = true
		_parar_midia(false)


func _input(evento: InputEvent) -> void:
	if not _pronta:
		return
	# As teclas de segurança funcionam em qualquer tela: Ctrl+Shift+D (modo conforto) e F11 (tela cheia).
	if evento.is_action_pressed("nexus_forcar_desativar"):
		get_viewport().set_input_as_handled()
		GerenciadorConfiguracoes.ativar_modo_conforto()
		return
	if evento.is_action_pressed("nexus_tela_cheia"):
		get_viewport().set_input_as_handled()
		GerenciadorConfiguracoes.alternar_tela_cheia()
		return
	if _fase == Fase.FALHA_NO_DESTINO or not _eh_pedido_de_pular(evento):
		return
	get_viewport().set_input_as_handled()
	# Todo pedido conta como "o jogador ainda está apertando": a troca de cena espera ele parar (`_acompanhar_saida`).
	_ultimo_pedido_s = _tempo_total
	_ir_para_menu_principal("pulada pelo jogador")


func _process(delta: float) -> void:
	_tempo_total += delta
	_tempo_na_fase += delta
	match _fase:
		Fase.CARREGANDO:
			_acompanhar_carga()
		Fase.REPRODUZINDO:
			_acompanhar_reproducao(delta)
		Fase.ESTATICA:
			if _tempo_na_fase >= _duracao_da_fase_estatica:
				_ir_para_menu_principal("fim da logo estática")
		Fase.SAINDO:
			_acompanhar_saida(delta)
	_atualizar_dica()


# ------------------------------------------------------------------ estado (leitura, para os testes e para quem integra)
## Já saiu (ou está saindo) da abertura: depois disso nenhuma outra troca de cena pode começar a partir daqui.
func transicao_iniciada() -> bool:
	return _transicao_iniciada


## O vídeo está passando de verdade: já houve um quadro válido e o player continua tocando.
func video_em_reproducao() -> bool:
	return _fase == Fase.REPRODUZINDO and _quadro_valido_visto and _video != null and _video.is_playing()


## Só a logo estática está sendo mostrada (a animação falhou ou foi trocada por acessibilidade).
func modo_estatico() -> bool:
	return _fase == Fase.ESTATICA


## O Menu não pôde ser aberto e o aviso com "Tentar novamente" está na tela.
func falha_no_destino() -> bool:
	return _fase == Fase.FALHA_NO_DESTINO


func fase_atual() -> int:
	return _fase


## Por que a abertura terminou ("fim da animação", "pulada pelo jogador", "fim da logo estática", "tempo máximo da animação"...).
func motivo_da_saida() -> String:
	return _motivo_da_saida


# ------------------------------------------------------------------ carregamento e reprodução do vídeo
func _deve_evitar_o_video() -> bool:
	return not GerenciadorConfiguracoes.glitch_permitido() or bool(GerenciadorConfiguracoes.obter("sem_flashes")) or not GerenciadorConfiguracoes.animacoes_permitidas()


## Pede o vídeo em segundo plano. Se ele não existir ou o pedido for recusado, fica a logo estática.
func _pedir_video() -> void:
	_fase = Fase.CARREGANDO
	_tempo_na_fase = 0.0
	if not ResourceLoader.exists(caminho_video):
		_voltar_ao_estatico("arquivo ausente ou formato não reconhecido: '%s'" % caminho_video, true)
		return
	var erro_do_pedido: Error = ResourceLoader.load_threaded_request(caminho_video)
	if erro_do_pedido != OK:
		_voltar_ao_estatico("a carga em segundo plano foi recusada (erro %d)" % int(erro_do_pedido), true)
		return
	_carga_pedida = true


func _acompanhar_carga() -> void:
	if not _carga_pedida:
		return
	var estado: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(caminho_video)
	if estado == ResourceLoader.THREAD_LOAD_LOADED:
		var recurso: Resource = ResourceLoader.load_threaded_get(caminho_video)
		_carga_pedida = false
		_iniciar_reproducao(recurso)
	elif estado == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		if _tempo_na_fase > tempo_maximo_carga_s:
			_voltar_ao_estatico("o vídeo não ficou disponível em %.1f s" % _tempo_na_fase, true)
	else:
		_voltar_ao_estatico("o recurso do vídeo não pôde ser carregado (importação ou formato inválido)", true)


## Inicia o vídeo uma única vez. O player continua invisível até o primeiro quadro válido (`_acompanhar_reproducao`).
func _iniciar_reproducao(recurso: Resource) -> void:
	if _reproducao_iniciada:
		return
	if not (recurso is VideoStream):
		_voltar_ao_estatico("recurso incompatível com VideoStreamPlayer", false)
		return
	_reproducao_iniciada = true
	_video.volume_db = _volume_do_video_db()
	_video.stream = recurso as VideoStream
	_video.finished.connect(_ao_video_terminou, CONNECT_ONE_SHOT)
	_video.play()
	if not _video.is_playing():
		_voltar_ao_estatico("o vídeo não iniciou (formato ou codec incompatível)", false)
		return
	_fase = Fase.REPRODUZINDO
	_tempo_na_fase = 0.0
	_tempo_reproduzindo = 0.0


func _acompanhar_reproducao(delta: float) -> void:
	if not _quadro_valido_visto:
		if _tem_quadro_valido():
			_ao_primeiro_quadro()
		elif not _video.is_playing() or _tempo_na_fase > tempo_primeiro_quadro_s:
			_voltar_ao_estatico("o vídeo não produziu imagem em %.1f s" % _tempo_na_fase, false)
		return
	_tempo_reproduzindo += delta
	if not _video.is_playing():
		# O player parou sem avisar com `finished`: é o fim do vídeo do mesmo jeito.
		_ao_video_terminou()
	elif _tempo_reproduzindo > tempo_maximo_reproducao_s:
		push_warning("SplashScreen: o vídeo passou de %.0f s sem terminar; seguindo para o Menu." % tempo_maximo_reproducao_s)
		_ir_para_menu_principal("tempo máximo da animação")


func _tem_quadro_valido() -> bool:
	var textura: Texture2D = _video.get_video_texture()
	return textura != null and textura.get_width() > 0 and textura.get_height() > 0


## Primeiro quadro válido: o vídeo passa a existir na tela (a proporção vem do próprio vídeo) e a logo estática se dissolve.
func _ao_primeiro_quadro() -> void:
	_quadro_valido_visto = true
	var tamanho: Vector2 = _video.get_video_texture().get_size()
	if tamanho.y > 0.0:
		_proporcao.ratio = tamanho.x / tamanho.y
	_video.modulate.a = 1.0
	_matar(_tween_logo)
	if duracao_dissolver_s <= 0.0 or not GerenciadorConfiguracoes.animacoes_permitidas():
		_logo.visible = false
		return
	_tween_logo = create_tween()
	_tween_logo.tween_property(_logo, "modulate:a", 0.0, duracao_dissolver_s)
	_tween_logo.tween_callback(_logo.hide)


func _ao_video_terminou() -> void:
	_ir_para_menu_principal("fim da animação")


func _volume_do_video_db() -> float:
	var volume: float = ganho_audio_db
	if bool(GerenciadorConfiguracoes.obter("reduzir_ruido")):
		volume += REDUCAO_RUIDO_DB
	return volume


# ------------------------------------------------------------------ logo estática
## Só a logo estática, por um tempo mínimo: acessibilidade ligada ou falha do vídeo (a falha passa antes por `_voltar_ao_estatico`).
func _iniciar_fase_estatica() -> void:
	_matar(_tween_logo)
	_parar_midia(false)
	_modo_estatico = true
	_fase = Fase.ESTATICA
	_tempo_na_fase = 0.0
	_duracao_da_fase_estatica = maxf(MINIMO_APOS_FALHA_S, duracao_estatica_s - _tempo_total)
	_video.modulate.a = 0.0
	_logo.visible = true
	_logo.modulate.a = 1.0


## O vídeo falhou: registra o motivo (log de desenvolvimento, nunca na tela) e fica a logo estática.
func _voltar_ao_estatico(motivo: String, na_carga: bool) -> void:
	if _transicao_iniciada or _fase == Fase.ESTATICA:
		return
	if na_carga:
		push_warning("SplashScreen: Falha ao carregar a animação da logo. Utilizando imagem estática. (%s)" % motivo)
	else:
		push_warning("SplashScreen: Não foi possível reproduzir a animação da Splash Screen. Utilizando fallback estático. (%s)" % motivo)
	_iniciar_fase_estatica()


## Acessibilidade ligada no meio da animação (por exemplo Ctrl+Shift+D): a animação para e fica a logo estática.
func _trocar_por_estatica_por_acessibilidade() -> void:
	if _transicao_iniciada or _fase == Fase.ESTATICA or _fase == Fase.FALHA_NO_DESTINO:
		return
	_iniciar_fase_estatica()


# ------------------------------------------------------------------ saída: a única porta para o Menu Principal
## Fim da abertura (vídeo terminado, pulo, tempo limite ou logo estática concluída). A guarda `_transicao_iniciada` garante uma única saída:
## `finished`, o teclado, o mouse e o tempo limite podem chegar juntos que só a primeira conta.
func _ir_para_menu_principal(motivo: String = "") -> void:
	if _transicao_iniciada:
		return
	_transicao_iniciada = true
	_motivo_da_saida = motivo
	_fase = Fase.SAINDO
	_tempo_saindo = 0.0
	_esconder_dica()
	_parar_midia(true)
	var duracao: float = _duracao_do_fade_de_saida()
	if not _pronta or duracao <= 0.0:
		_saida_pronta = true
		return
	_cortina.modulate.a = 0.0
	_tween_saida = create_tween()
	_tween_saida.tween_property(_cortina, "modulate:a", 1.0, duracao)
	_tween_saida.tween_callback(_ao_fade_concluido)


func _ao_fade_concluido() -> void:
	_saida_pronta = true


func _duracao_do_fade_de_saida() -> float:
	if _saida_imediata:
		return 0.0
	if not GerenciadorConfiguracoes.animacoes_permitidas():
		return DURACAO_FADE_REDUZIDO_S
	return duracao_fade_saida_s


## Fase de saída: com o fade pronto, a troca de cena espera o jogador parar de apertar (veja `SILENCIO_ANTES_DE_TROCAR_S`).
func _acompanhar_saida(delta: float) -> void:
	_tempo_saindo += delta
	if not _saida_pronta or _troca_pedida:
		return
	if _tempo_total - _ultimo_pedido_s >= SILENCIO_ANTES_DE_TROCAR_S or _tempo_saindo >= LIMITE_ESPERA_PELO_SILENCIO_S + duracao_fade_saida_s:
		_trocar_de_cena()


## Entrega o jogador ao Menu pela camada de troca de cena do jogo (despausa a árvore antes de sair, como toda troca).
func _trocar_de_cena() -> void:
	_troca_pedida = true
	get_tree().paused = false
	if Cenas.ir_para(get_tree(), caminho_destino, _ao_falha_da_troca):
		return
	_ao_falha_da_troca("o pedido de troca foi recusado (cena ausente ou outra troca em curso)")


func _ao_falha_da_troca(motivo: String) -> void:
	push_warning("SplashScreen: não foi possível abrir '%s': %s" % [caminho_destino, motivo])
	if not _pronta or not is_inside_tree():
		return
	_fase = Fase.FALHA_NO_DESTINO
	_matar(_tween_saida)
	_cortina.modulate.a = 0.0
	_camada_interacao.visible = false
	_video.modulate.a = 0.0
	_logo.visible = true
	_logo.modulate.a = ALFA_LOGO_NA_FALHA
	_painel_falha.visible = true
	_btn_tentar.grab_focus()


func _ao_tentar_novamente() -> void:
	if _fase != Fase.FALHA_NO_DESTINO:
		return
	_painel_falha.visible = false
	_logo.modulate.a = 1.0
	# A guarda só volta a abrir por este pedido explícito do jogador: é uma nova tentativa, não um segundo disparo.
	_transicao_iniciada = false
	_saida_pronta = false
	_troca_pedida = false
	_ultimo_pedido_s = -10.0
	_saida_imediata = true
	_ir_para_menu_principal("nova tentativa")


func _ao_sair() -> void:
	get_tree().quit()


# ------------------------------------------------------------------ entrada
func _eh_pedido_de_pular(evento: InputEvent) -> bool:
	if evento.is_echo():
		return false
	if evento.is_action_pressed("ui_accept") or evento.is_action_pressed("ui_cancel"):
		return true
	if evento is InputEventMouseButton:
		var clique: InputEventMouseButton = evento as InputEventMouseButton
		# A roda do mouse não pula: só os três botões de verdade.
		return clique.pressed and (clique.button_index == MOUSE_BUTTON_LEFT or clique.button_index == MOUSE_BUTTON_RIGHT or clique.button_index == MOUSE_BUTTON_MIDDLE)
	if evento is InputEventJoypadButton:
		return (evento as InputEventJoypadButton).pressed
	if evento is InputEventScreenTouch:
		return (evento as InputEventScreenTouch).pressed
	return false


# ------------------------------------------------------------------ aviso "Pressione Espaço para pular"
func _atualizar_dica() -> void:
	if _dica_mostrada or _transicao_iniciada or _fase == Fase.FALHA_NO_DESTINO or _tempo_total < atraso_dica_s:
		return
	_dica_mostrada = true
	if GerenciadorConfiguracoes.animacoes_permitidas():
		create_tween().tween_property(_dica, "modulate:a", _alfa_dica, DURACAO_DICA_S)
	else:
		_dica.modulate.a = _alfa_dica


func _esconder_dica() -> void:
	_dica_mostrada = true
	if _dica != null and is_instance_valid(_dica):
		_dica.modulate.a = 0.0


## Aviso discreto (texto fraco do tema, 70% opaco) e, com alto contraste, nítido: cor plena do tema de alto contraste.
func _aplicar_estilo_da_dica() -> void:
	_alfa_dica = 1.0 if bool(GerenciadorConfiguracoes.obter("alto_contraste")) else ALFA_DICA
	if _dica_mostrada and not _transicao_iniciada:
		_dica.modulate.a = _alfa_dica


func _ao_configuracao_alterada(chave: String, _valor: Variant) -> void:
	if not _pronta:
		return
	if chave in CHAVES_DA_ANIMACAO and _deve_evitar_o_video():
		_trocar_por_estatica_por_acessibilidade()
	elif chave == "reduzir_ruido" and _video != null and not _transicao_iniciada:
		_video.volume_db = _volume_do_video_db()
	elif chave == "alto_contraste" or chave == "tamanho_texto":
		TemaNexus.aplicar(get_tree())
		_aplicar_estilo_da_dica()


# ------------------------------------------------------------------ mídia e limpeza
## Para o vídeo e o som dele. `suave`: o volume desce em um instante antes de parar (sem estalo); sem ele, para na hora.
func _parar_midia(suave: bool) -> void:
	if _video == null or not is_instance_valid(_video):
		return
	if _video.finished.is_connected(_ao_video_terminou):
		_video.finished.disconnect(_ao_video_terminou)
	_matar(_tween_audio)
	if suave and _video.is_playing() and is_inside_tree():
		_tween_audio = create_tween()
		_tween_audio.tween_property(_video, "volume_db", -60.0, DURACAO_SAIDA_DO_AUDIO_S)
		_tween_audio.tween_callback(_video.stop)
		return
	_video.stop()


## Solta o resultado de uma carga em segundo plano que ninguém usou (pulo durante o carregamento). A Godot não tem como cancelar
## a carga; recolher o que já está pronto libera a tarefa, e o que ainda corre termina sozinho sem tocar nesta cena.
func _recolher_carga_pendente() -> void:
	if not _carga_pedida:
		return
	_carga_pedida = false
	if ResourceLoader.load_threaded_get_status(caminho_video) == ResourceLoader.THREAD_LOAD_LOADED:
		ResourceLoader.load_threaded_get(caminho_video)


func _matar(animacao: Tween) -> void:
	if animacao != null and animacao.is_valid():
		animacao.kill()
