class_name WidgetMaya
extends Button
## Widget da Maya na BARRA DE TAREFAS, no extremo direito, logo depois da data e do relógio. Mostra o LOGO OFICIAL da Maya (Marca.MAYA_MARCA) no lugar do
## antigo orbe (o orbe continua só nas telas de saudação/menu). Mantém a lógica de antes: reage ao estado da IA (cor do brilho), pulsa quando a
## Maya fala (`reagir`), tem hover, clique e foco por teclado. Clicar NÃO abre o Mensageiro: abre a JANELA DA MAYA (app `maya`).
## Estados (nunca só cor): normal · hover (logo maior) · pressionado (menor) · notificação (selo com a contagem de mensagens novas da Maya) ·
## ativa (traço sob o logo enquanto a janela está aberta) · glitch (deslocamento do logo, SÓ com EfeitosTerror liberando e animações permitidas) ·
## bloqueada (reservado; a Maya está sempre clicável: o jogador nunca fica sem orientação).
## Acessibilidade: dica com nome e contagem; foco visível pelo tema do Button; alto contraste = moldura branca de 2 px; modo conforto/reduzir
## animações = sem pulso nem deslocamento. Sem o arquivo do logo: placeholder técnico "M" (dependência registrada em shared/assets/branding/LEIA-ME.md).

const APP_ID := "maya"
const CONTATO := "maya"
const LADO_BASE := 40
const NOME := "Maya"

var estado_ia: String = "amigavel"
var energia: float = 0.0
var _fase: float = 0.0
var _textura: Texture2D = null
var _nao_lidas: int = 0
var _aberta: bool = false
var _bloqueada: bool = false
var _cx := Conexoes.new()


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = Vector2(UiKit.escalar(LADO_BASE + 6), UiKit.escalar(LADO_BASE))
	_textura = Marca.carregar(Marca.MAYA_MARCA)
	pressed.connect(_ao_pressionado)
	_cx.ligar(GerenciadorEstado.ia_estado_mudou, definir_estado)
	_cx.ligar(GerenciadorEstado.mensagem_recebida, _ao_mensagem)
	_cx.ligar(GerenciadorEstado.mensagem_atualizada, _ao_mensagem_atualizada)
	_cx.ligar(GerenciadorEstado.flag_alterada, _ao_flag)
	_cx.ligar(GerenciadorJanelas.janelas_alteradas, _atualizar_janela)
	_cx.ligar(GerenciadorConfiguracoes.configuracao_alterada, _ao_configuracao)
	estado_ia = GerenciadorEstado.ia_estado
	set_process(GerenciadorConfiguracoes.animacoes_permitidas())
	atualizar()


func _exit_tree() -> void:
	_cx.desligar_tudo()


## Relê tudo (estado da IA, mensagens novas, janela aberta, falso boot) e redesenha.
func atualizar() -> void:
	estado_ia = GerenciadorEstado.ia_estado
	_nao_lidas = GerenciadorEstado.nao_lidas(CONTATO)
	_bloqueada = false
	_atualizar_janela()
	_atualizar_dica()
	queue_redraw()


func definir_estado(novo: String) -> void:
	estado_ia = novo
	_atualizar_dica()
	queue_redraw()


## Pulso (a Maya falou, evento...). Com animações reduzidas não faz nada.
func reagir(forca: float = 0.7) -> void:
	if not GerenciadorConfiguracoes.animacoes_permitidas():
		return
	energia = clampf(energia + forca, 0.0, 1.0)
	set_process(true)


## Mensagens da Maya ainda não lidas (o selo mostra este número).
func nao_lidas() -> int:
	return _nao_lidas


func janela_aberta() -> bool:
	return _aberta


func bloqueada() -> bool:
	return _bloqueada


## Há logo oficial carregado? (false = está usando o placeholder técnico)
func tem_logo() -> bool:
	return _textura != null


## O glitch visual está liberado agora? (justificativa sistêmica + acessibilidade; EfeitosTerror é a regra única)
func glitch_ativo() -> bool:
	return false   # o roteiro v2.0 não usa glitch no logo


func _process(delta: float) -> void:
	_fase += delta * (1.0 + energia * 3.0)
	energia = maxf(0.0, energia - delta * 1.2)
	queue_redraw()


func _draw() -> void:
	var centro := size / 2.0
	var base := minf(size.x, size.y) * 0.5
	if base <= 1.0:
		return
	var cores: Array = OrbeNexus.cores_de(estado_ia)
	var principal: Color = cores[0]
	var secundaria: Color = cores[1]
	var passou: bool = is_hovered()
	var apertado: bool = button_pressed or (is_hovered() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	var fator_base := 0.96 if apertado else (1.08 if passou else 1.0)
	var pulso := 0.5 + 0.5 * sin(_fase * 2.0) if GerenciadorConfiguracoes.animacoes_permitidas() else 0.5
	var transparencia := 0.45 if _bloqueada else 1.0
	# Brilho atrás do logo: mesma paleta por estado da IA que o orbe tinha.
	draw_circle(centro, base * (0.92 + 0.08 * pulso + 0.12 * energia), Color(principal.r, principal.g, principal.b, (0.10 + 0.08 * pulso + 0.18 * energia + (0.10 if passou else 0.0)) * transparencia))
	var lado := base * 1.7 * fator_base
	var desloc := Vector2.ZERO
	if glitch_ativo():
		desloc = Vector2(sin(_fase * 37.0) * 1.8, cos(_fase * 29.0) * 0.9)
	if _textura != null:
		var tam_tex: Vector2 = _textura.get_size()
		var escala := lado / maxf(tam_tex.x, tam_tex.y)
		var tamanho := tam_tex * escala
		var pos := centro - tamanho / 2.0 + desloc
		if glitch_ativo():
			draw_texture_rect(_textura, Rect2(pos + Vector2(2.0, 0.0), tamanho), false, Color(secundaria.r, secundaria.g, secundaria.b, 0.35))
			draw_texture_rect(_textura, Rect2(pos - Vector2(2.0, 0.0), tamanho), false, Color(principal.r, principal.g, principal.b, 0.35))
		draw_texture_rect(_textura, Rect2(pos, tamanho), false, Color(1, 1, 1, transparencia))
	else:
		var fonte: Font = get_theme_default_font()
		var tamanho_fonte := int(lado * 0.8)
		var largura := fonte.get_string_size("M", HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho_fonte).x
		draw_string(fonte, Vector2(centro.x - largura / 2.0, centro.y + tamanho_fonte * 0.33) + desloc, "M", HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho_fonte, Color(principal.r, principal.g, principal.b, transparencia))
	# Janela aberta: traço sob o logo (texto/forma, não só cor).
	if _aberta:
		draw_line(Vector2(centro.x - base * 0.6, size.y - 3.0), Vector2(centro.x + base * 0.6, size.y - 3.0), Color.WHITE, 3.0)
	# Notificação: selo com a contagem.
	if _nao_lidas > 0:
		var raio := maxf(base * 0.34, 7.0)
		var selo := Vector2(size.x - raio - 1.0, raio + 1.0)
		draw_circle(selo, raio, Color(0.92, 0.2, 0.3, 1.0))
		var fonte2: Font = get_theme_default_font()
		var rotulo := str(mini(_nao_lidas, 9)) + ("+" if _nao_lidas > 9 else "")
		var tf := int(raio * 1.3)
		var larg := fonte2.get_string_size(rotulo, HORIZONTAL_ALIGNMENT_LEFT, -1, tf).x
		draw_string(fonte2, Vector2(selo.x - larg / 2.0, selo.y + tf * 0.35), rotulo, HORIZONTAL_ALIGNMENT_LEFT, -1, tf, Color.WHITE)
	if GerenciadorConfiguracoes.obter("alto_contraste"):
		draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE, false, 2.0)


func _atualizar_dica() -> void:
	var texto := "%s — assistente (%s). Abre a janela da Maya." % [NOME, "sempre disponível"]
	if _nao_lidas > 0:
		texto += " %d mensagem(ns) nova(s)." % _nao_lidas
	if _bloqueada:
		texto += " O sistema está reiniciando."
	if _textura == null:
		texto += " (logo oficial indisponível: placeholder)"
	tooltip_text = texto


func _atualizar_janela() -> void:
	var antes := _aberta
	_aberta = GerenciadorJanelas.app_aberto(APP_ID)
	if antes != _aberta:
		queue_redraw()


func _ao_pressionado() -> void:
	GerenciadorJanelas.abrir_app(APP_ID)


func _ao_mensagem(contato: String, _entrada: Dictionary) -> void:
	if contato != CONTATO:
		return
	_nao_lidas = GerenciadorEstado.nao_lidas(CONTATO)
	_atualizar_dica()
	reagir(0.8)
	queue_redraw()


func _ao_mensagem_atualizada(contato: String, _id_msg: String) -> void:
	if contato == CONTATO:
		_nao_lidas = GerenciadorEstado.nao_lidas(CONTATO)
		_atualizar_dica()
		queue_redraw()


func _ao_flag(nome: String, _valor: Variant) -> void:
	if nome == "conversa_lida:" + CONTATO:
		atualizar()


func _ao_configuracao(chave: String, _valor: Variant) -> void:
	if chave == "alto_contraste" or chave == "reduzir_animacoes" or chave == "modo_conforto" or chave == "reduzir_glitch" or chave == "desativar_efeitos_agressivos":
		set_process(GerenciadorConfiguracoes.animacoes_permitidas())
		queue_redraw()
