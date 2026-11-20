class_name MonitorVirtual
extends Control
## Monitor virtual do HumaxOS: renderiza a área de trabalho DENTRO de um SubViewport, mostrado numa "tela de monitor" sobre uma mesa simples
## (parede neutra, tampo, pé do monitor) e um fundo levemente desfocado. É a APRESENTAÇÃO PADRÃO do jogo: a CenaGameplay (cena_gameplay.tscn, uma
## cena herdada daqui com o foco já no computador) é o destino de Novo Jogo, Continuar, Carregar e Recomeçar (Cenas.GAMEPLAY). Esta cena também roda
## sozinha (F6, foco no mundo físico): sem um jogo em andamento, a própria área de trabalho abre um (AreaDeTrabalho._garantir_jogo).
## O Esc e a pausa NUNCA dependem do foco: com o foco no mundo físico, o Esc abre a pausa pelo desktop (`abrir_pausa`) e o foco volta para ele.
##
## COMO O MOUSE É CONVERTIDO: o SubViewportContainer (sem `stretch`) desenha o desktop na resolução VIRTUAL escolhida e é escalado para caber
## na tela do monitor (`scale`). O próprio motor converte cada evento de mouse com o inverso da transformação global do contêiner, então um
## clique na tela física cai no ponto certo do desktop em qualquer resolução. `converter_ponto` faz a mesma conta para quem precisa dela
## (o GerenciadorJanelas, que recebe a entrada na raiz, a usa para achar a janela clicada).
##
## REGRA DE FOCO (um só destino para a entrada, nunca dois ao mesmo tempo):
##   - FISICO (padrão): o desktop NÃO recebe entrada (gui_disable_input) e o mundo físico recebe tudo. Clicar dentro da tela do monitor ou
##     apertar F8 (`nexus_alternar_foco_monitor`) passa o foco para o desktop; esse clique é consumido (não vai a lugar nenhum).
##   - DESKTOP: só o desktop recebe teclado e mouse. Apertar F8 ou clicar FORA da tela devolve o foco ao mundo físico (o clique também é
##     consumido). O mundo físico deve perguntar `mundo_fisico_pode_receber_entrada` antes de tratar teclado/mouse; além disso o monitor
##     marca o teclado como tratado em _unhandled_input enquanto o desktop tem o foco.
##   - ESC e as teclas de acessibilidade NUNCA são presas por esta regra: o ESC pertence a quem tem o foco (no desktop abre a pausa) e os
##     atalhos de segurança (Ctrl+Shift+D: modo conforto; F11: tela cheia) funcionam também com o foco no mundo físico.
## O sistema continua rodando com o foco no mundo físico (mensagens chegam, a narrativa anda): só a ENTRADA muda de destino.
##
## ACESSIBILIDADE: o foco aparece em TEXTO (`IndicadorFoco`, e `AvisoFoco` sobre a tela), não só em cor. Alto contraste: fundo físico sem
## desfoque e quase preto, moldura branca grossa, tema de alto contraste também dentro do desktop. Modo conforto / reduzir animações: a
## troca de foco é instantânea e o desfoque fica fixo (nada pisca nem se mexe).

enum Foco { FISICO, DESKTOP }
## O que um clique do mouse faz com o foco (decidido por `decidir_clique`, a regra única de roteamento do mouse).
enum DecisaoClique { IGNORAR, ENTRAR_NO_DESKTOP, VOLTAR_AO_MUNDO_FISICO }

signal foco_alterado(foco: int)
signal resolucao_alterada(resolucao: Vector2i)

const GRUPO := "monitor_virtual"
const ACAO_ALTERNAR := "nexus_alternar_foco_monitor"
const RESOLUCAO_PADRAO := Vector2i(1920, 1080)
const RESOLUCAO_MINIMA := Vector2i(640, 360)
const RESOLUCAO_MAXIMA := Vector2i(3840, 2160)
const RESOLUCOES: Array = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]
const RAIO_DESFOQUE := 2.0
const ESCURECER_PADRAO := 0.25
const ESCURECER_CONFORTO := 0.5
const ESCURECER_ALTO_CONTRASTE := 0.85
const TEXTO_FOCO_FISICO := "Foco: mundo físico — F8 ou um clique na tela passa o controle para o computador."
const TEXTO_FOCO_DESKTOP := "Foco: computador — F8 ou um clique fora da tela devolve o controle ao mundo físico."
const TEXTO_AVISO := "Clique na tela ou pressione F8 para usar o computador"

## A cena do desktop mostrada na tela. Vazio: a área de trabalho do jogo (Cenas.AREA_DE_TRABALHO). Os testes colocam uma cena leve aqui.
@export var cena_desktop: PackedScene
## Começa com o foco no desktop (padrão: no mundo físico, a regra explícita).
@export var iniciar_no_desktop: bool = false
## Clicar fora da tela do monitor, com o foco no desktop, devolve o foco ao mundo físico (a CenaGameplay desliga isto: sem mundo físico para
## explorar, um clique perdido na parede não pode tirar o jogador do computador; o F8 continua alternando).
@export var clique_fora_devolve_o_foco: bool = true
## Textura do fundo físico (opcional). Vazio: um degradê escuro de placeholder.
@export var textura_fundo: Texture2D

var _foco: Foco = Foco.FISICO
var _resolucao: Vector2i = RESOLUCAO_PADRAO
var _desktop: Node = null
var _pronta: bool = false

@onready var _fundo: TextureRect = %FundoFisico
@onready var _desfoque: ColorRect = %DesfoqueFundo
@onready var _rotulo_cenario: Label = %RotuloCenario
@onready var _moldura: PanelContainer = %Moldura
@onready var _area_tela: Control = %AreaTela
@onready var _container: SubViewportContainer = %ContainerTela
@onready var _viewport: SubViewport = %Desktop
@onready var _aviso: Label = %AvisoFoco
@onready var _indicador: Label = %IndicadorFoco


## O mundo físico pode tratar a entrada agora? Sim quando NÃO há monitor virtual na árvore ou quando nenhum deles entregou o foco ao desktop.
## É a pergunta que o gameplay físico faz antes de tratar teclado/mouse (o único ponto de decisão: não há dois sistemas de entrada).
static func mundo_fisico_pode_receber_entrada(arvore: SceneTree) -> bool:
	if arvore == null:
		return true
	for no in arvore.get_nodes_in_group(GRUPO):
		if no is MonitorVirtual and (no as MonitorVirtual).desktop_tem_foco():
			return false
	return true


## Ajuste de escala e posição para encaixar uma resolução virtual numa área, sem distorcer (letterbox). Função pura: {escala, posicao}.
static func encaixar(tamanho_virtual: Vector2i, area: Vector2) -> Dictionary:
	if tamanho_virtual.x <= 0 or tamanho_virtual.y <= 0 or area.x <= 0.0 or area.y <= 0.0:
		return {"escala": 1.0, "posicao": Vector2.ZERO}
	var escala := minf(area.x / float(tamanho_virtual.x), area.y / float(tamanho_virtual.y))
	return {"escala": escala, "posicao": (area - Vector2(tamanho_virtual) * escala) / 2.0}


## A resolução é aceitável para o monitor? (Entre RESOLUCAO_MINIMA e RESOLUCAO_MAXIMA.)
static func resolucao_valida(tamanho_virtual: Vector2i) -> bool:
	return tamanho_virtual.x >= RESOLUCAO_MINIMA.x and tamanho_virtual.y >= RESOLUCAO_MINIMA.y and tamanho_virtual.x <= RESOLUCAO_MAXIMA.x and tamanho_virtual.y <= RESOLUCAO_MAXIMA.y


func _ready() -> void:
	_pronta = UiKit.refs_ok(self, {
		"FundoFisico": _fundo, "DesfoqueFundo": _desfoque, "RotuloCenario": _rotulo_cenario, "Moldura": _moldura, "AreaTela": _area_tela,
		"ContainerTela": _container, "Desktop": _viewport, "AvisoFoco": _aviso, "IndicadorFoco": _indicador,
	})
	if not _pronta:
		return
	add_to_group(GRUPO)
	_container.stretch = false
	_container.pivot_offset = Vector2.ZERO
	_fundo.texture = textura_fundo if textura_fundo != null else _criar_fundo_placeholder()
	_viewport.gui_disable_input = true
	_viewport.size = _resolucao
	_area_tela.resized.connect(_ajustar)
	GerenciadorConfiguracoes.configuracao_alterada.connect(_ao_configuracao_alterada)
	GerenciadorJanelas.definir_conversor_de_ponto(converter_ponto)
	_montar_desktop()
	_ajustar()
	_aplicar_acessibilidade()
	_definir_foco(Foco.DESKTOP if iniciar_no_desktop else Foco.FISICO)


func _exit_tree() -> void:
	if not _pronta:
		return
	if _area_tela.resized.is_connected(_ajustar):
		_area_tela.resized.disconnect(_ajustar)
	if GerenciadorConfiguracoes.configuracao_alterada.is_connected(_ao_configuracao_alterada):
		GerenciadorConfiguracoes.configuracao_alterada.disconnect(_ao_configuracao_alterada)
	GerenciadorJanelas.definir_conversor_de_ponto(Callable())


## Instancia o desktop dentro do SubViewport com o tema do jogo. (Um Control dentro de um SubViewport não herda o tema da janela
## principal, então o tema, inclusive o de alto contraste, é aplicado direto na raiz do desktop.)
func _montar_desktop() -> void:
	var cena: PackedScene = cena_desktop
	if cena == null and ResourceLoader.exists(Cenas.AREA_DE_TRABALHO):
		cena = load(Cenas.AREA_DE_TRABALHO) as PackedScene
	if cena == null:
		push_error("MonitorVirtual: não há cena de desktop para mostrar na tela.")
		return
	_desktop = cena.instantiate()
	# O monitor (e o SubViewport) processam sempre, para o encaminhamento de teclas e o Esc seguirem funcionando com o jogo pausado; o
	# DESKTOP continua pausável: a pausa do jogo para o desktop como parava antes de ele morar dentro do monitor.
	_desktop.process_mode = Node.PROCESS_MODE_PAUSABLE
	_viewport.add_child(_desktop)
	_aplicar_tema_no_desktop()


func desktop() -> Node:
	return _desktop


func viewport_do_desktop() -> SubViewport:
	return _viewport


func _criar_fundo_placeholder() -> Texture2D:
	var gradiente := Gradient.new()
	gradiente.set_color(0, Color(0.80, 0.81, 0.84))   # parede neutra, clara no centro e mais escura nas bordas
	gradiente.set_color(1, Color(0.46, 0.47, 0.52))
	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.5, 0.45)
	textura.fill_to = Vector2(1.0, 1.0)
	textura.width = 256
	textura.height = 256
	return textura


# ------------------------------------------------------------------ resolução e encaixe
func resolucao() -> Vector2i:
	return _resolucao


## Troca a resolução VIRTUAL do monitor (o desktop é redesenhado nela). Recusa valores fora dos limites. Devolve true se mudou.
func definir_resolucao(nova: Vector2i) -> bool:
	if not resolucao_valida(nova) or nova == _resolucao:
		return false
	_resolucao = nova
	if _pronta:
		_viewport.size = nova
		_ajustar()
	resolucao_alterada.emit(nova)
	return true


## Encaixa o desktop na tela do monitor: escala sem distorcer e centraliza (as bordas que sobrarem ficam pretas).
func _ajustar() -> void:
	if not _pronta:
		return
	var ajuste := encaixar(_resolucao, _area_tela.size)
	var escala: float = float(ajuste["escala"])
	_container.size = Vector2(_resolucao)
	_container.scale = Vector2(escala, escala)
	_container.position = ajuste["posicao"]


## Ponto da tela física (coordenadas da janela) -> ponto do desktop (coordenadas do SubViewport). É o inverso da transformação que o
## motor usa para encaminhar o mouse ao desktop, então vale em qualquer resolução, escala ou posição do monitor.
func converter_ponto(ponto_global: Vector2) -> Vector2:
	if not _pronta:
		return ponto_global
	return _container.get_global_transform_with_canvas().affine_inverse() * ponto_global


## Ponto do desktop (coordenadas do SubViewport) -> ponto da tela física (coordenadas da janela): o inverso de `converter_ponto`.
func converter_para_tela(ponto_desktop: Vector2) -> Vector2:
	if not _pronta:
		return ponto_desktop
	return _container.get_global_transform_with_canvas() * ponto_desktop


## O ponto da tela física cai dentro da imagem do desktop (a tela do monitor, sem as bordas pretas do encaixe)?
func ponto_dentro_do_monitor(ponto_global: Vector2) -> bool:
	if not _pronta:
		return false
	return Rect2(Vector2.ZERO, Vector2(_resolucao)).has_point(converter_ponto(ponto_global))


# ------------------------------------------------------------------ foco
func foco() -> int:
	return _foco


func desktop_tem_foco() -> bool:
	return _foco == Foco.DESKTOP


func entrar_no_desktop() -> void:
	_definir_foco(Foco.DESKTOP)


func voltar_ao_mundo_fisico() -> void:
	_definir_foco(Foco.FISICO)


func alternar_foco() -> void:
	_definir_foco(Foco.FISICO if _foco == Foco.DESKTOP else Foco.DESKTOP)


func _definir_foco(novo: Foco) -> void:
	var mudou := novo != _foco
	_foco = novo
	if not _pronta:
		return
	var no_desktop := _foco == Foco.DESKTOP
	_viewport.gui_disable_input = not no_desktop
	_container.mouse_filter = Control.MOUSE_FILTER_STOP if no_desktop else Control.MOUSE_FILTER_IGNORE
	if not no_desktop:
		_viewport.gui_release_focus()   # nenhum campo de texto do desktop continua "ouvindo" depois de sair
	_aviso.visible = not no_desktop
	_aviso.text = TEXTO_AVISO
	_indicador.text = TEXTO_FOCO_DESKTOP if no_desktop else TEXTO_FOCO_FISICO
	_atualizar_moldura()
	if mudou:
		foco_alterado.emit(int(_foco))


# ------------------------------------------------------------------ entrada
func _input(evento: InputEvent) -> void:
	if not _pronta:
		return
	if InputMap.has_action(ACAO_ALTERNAR) and evento.is_action_pressed(ACAO_ALTERNAR):
		get_viewport().set_input_as_handled()
		alternar_foco()
		return
	if _foco == Foco.FISICO:
		_atalhos_de_seguranca(evento)
	match decidir_clique(evento):
		DecisaoClique.ENTRAR_NO_DESKTOP:
			get_viewport().set_input_as_handled()
			entrar_no_desktop()
		DecisaoClique.VOLTAR_AO_MUNDO_FISICO:
			get_viewport().set_input_as_handled()
			voltar_ao_mundo_fisico()


## O que este evento faz com o foco? Só o botão esquerdo apertado conta: com o foco no mundo físico, um clique DENTRO da tela entra no
## desktop; com o foco no desktop, um clique FORA da tela (se `clique_fora_devolve_o_foco`) volta ao mundo físico. O clique que muda o
## foco é consumido (não chega a ninguém); qualquer outro segue o seu caminho.
func decidir_clique(evento: InputEvent) -> int:
	var clique := evento as InputEventMouseButton
	if not _pronta or clique == null or not clique.pressed or clique.button_index != MOUSE_BUTTON_LEFT:
		return DecisaoClique.IGNORAR
	var dentro := ponto_dentro_do_monitor(clique.position)
	if _foco == Foco.FISICO and dentro:
		return DecisaoClique.ENTRAR_NO_DESKTOP
	if _foco == Foco.DESKTOP and not dentro and clique_fora_devolve_o_foco:
		return DecisaoClique.VOLTAR_AO_MUNDO_FISICO
	return DecisaoClique.IGNORAR


## Com o desktop em foco, o teclado e o controle não passam para o mundo físico (um destino só para a entrada).
func consome_entrada_de_teclado(evento: InputEvent) -> bool:
	return _pronta and _foco == Foco.DESKTOP and (evento is InputEventKey or evento is InputEventJoypadButton or evento is InputEventJoypadMotion)


func _unhandled_input(evento: InputEvent) -> void:
	# Esc com o foco no mundo físico: o desktop não recebe teclas, então o monitor pede a pausa por ele (e entrega o foco, para o menu responder).
	# Com o jogo JÁ pausado, o Esc só devolve o foco e entrega a tecla ao desktop: o menu de pausa/opções que está aberto trata o Esc como sempre.
	if _pronta and _foco == Foco.FISICO and evento.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			entrar_no_desktop()
			_viewport.push_input(evento)
			get_viewport().set_input_as_handled()
			return
		if abrir_pausa():
			get_viewport().set_input_as_handled()
			entrar_no_desktop()
			return
	if consome_entrada_de_teclado(evento):
		get_viewport().set_input_as_handled()


## Abre o Menu de Pausa do desktop (se ele sabe abrir e o jogo pode pausar agora). Devolve true se abriu.
func abrir_pausa() -> bool:
	return _desktop != null and _desktop.has_method("abrir_pausa") and bool(_desktop.call("abrir_pausa"))


## `Sessao` chama isto na cena atual antes de trocar o estado do jogo por baixo dela: o desktop solta os autoloads e fecha as janelas como de costume.
func encerrar_sessao() -> void:
	if _desktop != null and is_instance_valid(_desktop) and _desktop.has_method("encerrar_sessao"):
		_desktop.call("encerrar_sessao")


## Teclas de segurança que valem mesmo com o foco no mundo físico (o desktop trata as mesmas teclas quando está em foco).
func _atalhos_de_seguranca(evento: InputEvent) -> void:
	if not (evento is InputEventKey) or not evento.pressed:
		return
	if InputMap.has_action("nexus_forcar_desativar") and evento.is_action_pressed("nexus_forcar_desativar"):
		get_viewport().set_input_as_handled()
		GerenciadorConfiguracoes.ativar_modo_conforto()
	elif InputMap.has_action("nexus_tela_cheia") and evento.is_action_pressed("nexus_tela_cheia"):
		get_viewport().set_input_as_handled()
		GerenciadorConfiguracoes.alternar_tela_cheia()


# ------------------------------------------------------------------ acessibilidade
func _ao_configuracao_alterada(chave: String, _valor: Variant) -> void:
	if ["alto_contraste", "tamanho_texto", "tema", "reduzir_animacoes", "reduzir_glitch", "reduzir_tremor", "sem_flashes", "reduzir_ruido"].has(chave):
		_aplicar_acessibilidade()
		_aplicar_tema_no_desktop()


func alto_contraste() -> bool:
	return bool(GerenciadorConfiguracoes.obter("alto_contraste"))


## Sem transição animada: modo conforto ligado ou "reduzir animações".
func sem_animacoes() -> bool:
	return GerenciadorConfiguracoes.modo_conforto_ativo() or bool(GerenciadorConfiguracoes.obter("reduzir_animacoes"))


## O raio de desfoque do fundo físico agora (0 em alto contraste: o fundo fica nítido e quase preto, sem competir com o desktop).
func raio_do_desfoque() -> float:
	if not _pronta or _desfoque.material == null:
		return 0.0
	return float((_desfoque.material as ShaderMaterial).get_shader_parameter("raio"))


func escurecer_do_fundo() -> float:
	if not _pronta or _desfoque.material == null:
		return 0.0
	return float((_desfoque.material as ShaderMaterial).get_shader_parameter("escurecer"))


func _aplicar_acessibilidade() -> void:
	if not _pronta or _desfoque.material == null:
		return
	var material_desfoque := _desfoque.material as ShaderMaterial
	if alto_contraste():
		material_desfoque.set_shader_parameter("raio", 0.0)
		material_desfoque.set_shader_parameter("escurecer", ESCURECER_ALTO_CONTRASTE)
	else:
		material_desfoque.set_shader_parameter("raio", RAIO_DESFOQUE)
		material_desfoque.set_shader_parameter("escurecer", ESCURECER_CONFORTO if sem_animacoes() else ESCURECER_PADRAO)
	_atualizar_moldura()
	_pintar_mesa()


## Mesa, base e pé do monitor: cores discretas; em alto contraste ficam quase pretas (o monitor continua sendo o único foco visual).
func _pintar_mesa() -> void:
	var contraste: bool = alto_contraste()
	var cores := {"Mesa": Color(0.30, 0.24, 0.19), "BaseMonitor": Color(0.16, 0.16, 0.19), "PeMonitor": Color(0.12, 0.12, 0.15)}
	for nome in cores:
		var peca := get_node_or_null("%" + str(nome)) as ColorRect
		if peca != null:
			peca.color = Color(0.02, 0.02, 0.03) if contraste else (cores[nome] as Color)


func _aplicar_tema_no_desktop() -> void:
	if _desktop is Control:
		(_desktop as Control).theme = TemaNexus.criar_tema()


## Moldura do monitor: a borda muda com o foco E com o alto contraste (e o texto do indicador diz o foco: nada depende só da cor).
func _atualizar_moldura() -> void:
	if not _pronta:
		return
	var no_desktop := _foco == Foco.DESKTOP
	var caixa := StyleBoxFlat.new()
	caixa.bg_color = Color(0.03, 0.03, 0.05, 1.0)
	caixa.set_corner_radius_all(10)
	var largura := 2
	var cor_borda := Color(0.35, 0.40, 0.50, 1.0)
	if no_desktop:
		largura = 3
		cor_borda = Color(0.22, 0.74, 0.97, 1.0)
	if alto_contraste():
		largura = 5 if no_desktop else 3
		cor_borda = Color(1.0, 1.0, 1.0, 1.0)
	caixa.set_border_width_all(largura)
	caixa.border_color = cor_borda
	_moldura.add_theme_stylebox_override("panel", caixa)
