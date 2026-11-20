class_name BarraTarefas
extends PanelContainer
## Barra de tarefas: botão Iniciar, apps fixados (lidos do catálogo), janelas abertas, bandeja
## (segurança, corrupção, microfone, notificações), relógio em tempo real e, no extremo direito depois da data, o WidgetMaya (logo oficial da Maya).
## Tudo é derivado do GerenciadorJanelas (catálogo/janelas) e do GerenciadorEstado; nada é duplicado aqui.
## A estrutura fixa (Iniciar, bandeja, relógio) está em barra_de_tarefas.tscn; os botões de app/janela são instâncias
## de botao_tarefa.tscn. A altura da barra (52 px) é definida na cena.

signal menu_pedido()
signal notificacoes_pedido()

## Item da barra (botao_tarefa.tscn): um por app fixado e um por janela aberta (conteúdo dinâmico).
@export var cena_botao: PackedScene

var _cx := Conexoes.new()

@onready var _btn_iniciar: Button = %BotaoIniciar
@onready var _caixa_fixados: HBoxContainer = %CaixaFixados
@onready var _caixa_janelas: HBoxContainer = %CaixaJanelas
@onready var _rot_seg: Label = %RotuloSeg
@onready var _rot_cor: Label = %RotuloCor
@onready var _rot_mic: Label = %RotuloMic
@onready var _btn_notif: Button = %BotaoNotificacoes
@onready var _rot_hora: Label = %RotuloHora
@onready var _rot_data: Label = %RotuloData
@onready var _widget_maya: WidgetMaya = %WidgetMaya


func _ready() -> void:
	if not UiKit.refs_ok(self, {"BotaoIniciar": _btn_iniciar, "CaixaFixados": _caixa_fixados, "CaixaJanelas": _caixa_janelas,
			"RotuloSeg": _rot_seg, "RotuloCor": _rot_cor, "RotuloMic": _rot_mic, "BotaoNotificacoes": _btn_notif,
			"RotuloHora": _rot_hora, "RotuloData": _rot_data, "WidgetMaya": _widget_maya}):
		return
	_cx.ligar(GerenciadorJanelas.janelas_alteradas, _reconstruir_janelas)
	_cx.ligar(GerenciadorJanelas.catalogo_alterado, _reconstruir_fixados)
	_cx.ligar(GerenciadorEstado.permissao_alterada, _ao_permissao)
	_cx.ligar(SistemaNotificacoes.historico_alterado, _atualizar_notificacoes)
	_cx.ligar(RelogioGlobal.minuto_mudou, _ao_minuto)
	_aplicar_marca()
	atualizar_tudo()


func _exit_tree() -> void:
	_cx.desligar_tudo()


## Botão Iniciar: com o logo oficial do HumaxOS disponível (Marca), ele aparece como ícone ao lado do texto "◆  HumaxOS" (que continua lá:
## é o nome do sistema para quem não vê o ícone e o que os testes e o leitor de tela encontram). Sem o arquivo, nada muda.
func _aplicar_marca() -> void:
	var logo: Texture2D = Marca.carregar(Marca.HUMAXOS)
	if logo == null:
		return
	_btn_iniciar.icon = logo
	_btn_iniciar.expand_icon = true
	_btn_iniciar.add_theme_constant_override("icon_max_width", UiKit.escalar(22))


func atualizar_tudo() -> void:
	_reconstruir_fixados()
	_reconstruir_janelas()
	_rot_seg.visible = false   # o roteiro v2.0 não tem Segurança nem Corrupção: Dependência e Autonomia são variáveis ocultas
	_rot_cor.visible = false
	_ao_permissao("", false)
	_atualizar_notificacoes()
	_atualizar_relogio()
	_widget_maya.atualizar()


func definir_menu_aberto(aberto: bool) -> void:
	if _btn_iniciar != null:
		_btn_iniciar.set_pressed_no_signal(aberto)


func _novo_botao() -> BotaoTarefaApp:
	if cena_botao == null:
		push_error("BarraTarefas: 'cena_botao' não definida (veja barra_de_tarefas.tscn).")
		return null
	return cena_botao.instantiate() as BotaoTarefaApp


# ------------------------------------------------------------------ atualizações
func _reconstruir_fixados() -> void:
	UiKit.limpar_filhos(_caixa_fixados)
	for info in GerenciadorJanelas.apps_fixados():
		var b: BotaoTarefaApp = _novo_botao()
		if b == null:
			return
		_caixa_fixados.add_child(b)
		b.configurar(info, "", 44.0)
		b.tooltip_text = "%s" % str(info.get("nome", ""))
		b.pressed.connect(_ao_fixado.bind(str(info.get("id", ""))))


func _reconstruir_janelas() -> void:
	UiKit.limpar_filhos(_caixa_janelas)
	var ativa := GerenciadorJanelas.janela_ativa()
	for j in GerenciadorJanelas.janelas():
		var janela := j as JanelaBase
		if janela == null:
			continue
		var b: BotaoTarefaApp = _novo_botao()
		if b == null:
			return
		_caixa_janelas.add_child(b)
		b.configurar(janela.info, janela.titulo, 170.0)
		b.definir_destaque(janela == ativa and not janela.minimizada)
		b.tooltip_text = janela.titulo + (" (minimizada)" if janela.minimizada else "")
		b.pressed.connect(_ao_botao_janela.bind(janela))


func _colorir(rotulo: Label, texto: String, cor: Color) -> void:
	rotulo.text = texto
	rotulo.add_theme_color_override("font_color", cor)


## Indicador de quantas das cinco permissões a Maya tem agora (texto, nunca só cor).
func _ao_permissao(_nome: String, _ativa: bool) -> void:
	var n := GerenciadorEstado.permissoes_ativas()
	_colorir(_rot_mic, "MAYA %d/5" % n, TemaNexus.cor("aviso") if n > 0 else TemaNexus.cor("texto_fraco"))
	_rot_mic.tooltip_text = "Permissões ativas da Maya: %d de 5 (Configurações > Privacidade)" % n


func _atualizar_notificacoes() -> void:
	var n := SistemaNotificacoes.nao_lidas()
	_btn_notif.text = "🔔 %d" % n if n > 0 else "🔔"


func _atualizar_relogio() -> void:
	_rot_hora.text = RelogioGlobal.hora_texto()
	_rot_data.text = ""   # sem calendário no jogo
	_rot_data.visible = false


func _ao_minuto(_hora: int, _minuto: int) -> void:
	_atualizar_relogio()



# ------------------------------------------------------------------ ações
# Conectado na cena: BotaoIniciar.pressed
func _ao_iniciar() -> void:
	menu_pedido.emit()


# Conectado na cena: BotaoNotificacoes.pressed
func _ao_notificacoes() -> void:
	notificacoes_pedido.emit()


func _ao_fixado(app_id: String) -> void:
	GerenciadorJanelas.abrir_app(app_id)


func _ao_botao_janela(janela: JanelaBase) -> void:
	if is_instance_valid(janela):
		GerenciadorJanelas.alternar_da_barra(janela)
