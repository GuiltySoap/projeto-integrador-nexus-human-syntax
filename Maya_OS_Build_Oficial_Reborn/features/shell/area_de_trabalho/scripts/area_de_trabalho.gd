class_name AreaDeTrabalho
extends Control
## Cena principal do "sistema operacional". As camadas (fundo, ícones, widgets, janelas, barra/menus, toasts, efeitos,
## modais e depuração) e todas as peças do shell são nós e instâncias de area_de_trabalho.tscn (edite-as no editor);
## este script liga os autoloads ao visual e trata os atalhos globais.
## A ordem das camadas é a ordem dos filhos (a última fica por cima).
## Nenhuma regra de história vive aqui: o motor (GerenciadorNarrativa) emite sinais e o shell só reage a eles.
## Duas telas sobrepostas moram nesta cena e pausam o jogo de verdade (get_tree().paused): o Menu de Pausa (Esc) e, só se a
## TelaFinal não puder abrir, a Tela de Fim de Jogo. Esta cena também sabe se desligar (`encerrar_sessao`) quando o jogo
## reinicia, carrega um salvamento ou volta ao Menu Principal por baixo dela.

## Atalho da grade de ícones (conteúdo dinâmico: um por app da área de trabalho, mais a Lixeira). Definido na cena.
@export var cena_icone: PackedScene

var _cx := Conexoes.new()
var _pronto: bool = false
## A sessão está terminando (final alcançado ou troca de cena em curso): o Esc não abre mais a pausa.
var _encerrando: bool = false

@onready var _c_janelas: Control = %CamadaJanelas
@onready var _c_modais: Control = %CamadaModais
@onready var _fundo: PapelDeParede = %PapelDeParede
@onready var _grade_icones: VFlowContainer = %GradeIcones
@onready var _widget_relogio: WidgetRelogio = %WidgetRelogio
@onready var _barra: BarraTarefas = %BarraTarefas
@onready var _menu: MenuIniciar = %MenuIniciar
@onready var _central: CentroNotificacoes = %CentroNotificacoes
@onready var _toasts: PilhaToasts = %PilhaToasts
@onready var _efeito: EfeitoGlitch = %EfeitoGlitch
@onready var _debug: PainelDebug = %PainelDebug
@onready var _pausa: MenuPausa = %MenuPausa
@onready var _fim_de_jogo: TelaFimDeJogo = %TelaFimDeJogo


func _enter_tree() -> void:
	# Roda antes do _ready dos filhos: as peças do shell leem o estado do jogo e o tema assim que ficam prontas.
	_garantir_jogo()
	TemaNexus.definir_etapa(GerenciadorEstado.etapa_atual)
	TemaNexus.aplicar(get_tree())


func _ready() -> void:
	if not UiKit.refs_ok(self, {"CamadaJanelas": _c_janelas, "CamadaModais": _c_modais, "PapelDeParede": _fundo, "GradeIcones": _grade_icones,
			"WidgetRelogio": _widget_relogio, "BarraTarefas": _barra, "MenuIniciar": _menu,
			"CentroNotificacoes": _central, "PilhaToasts": _toasts, "EfeitoGlitch": _efeito, "PainelDebug": _debug, "MenuPausa": _pausa, "TelaFimDeJogo": _fim_de_jogo}):
		return
	_efeito.definir_alvo_tremor(_c_janelas)
	_barra.menu_pedido.connect(_ao_menu_pedido)
	_barra.notificacoes_pedido.connect(_ao_central_pedido)
	_menu.aberto_alterado.connect(_ao_menu_aberto)
	_menu.sair_pedido.connect(_ao_sair_para_boot)
	_reconstruir_icones()
	GerenciadorJanelas.registrar_camadas(_c_janelas, _c_modais)
	_conectar()
	_iniciar_sessao.call_deferred()


func _exit_tree() -> void:
	_cx.desligar_tudo()
	GerenciadorJanelas.limpar_camadas()
	GerenciadorNarrativa.pausado = true


func _input(evento: InputEvent) -> void:
	if not (evento is InputEventKey) or not evento.pressed:
		return
	# Teclas de segurança funcionam mesmo com um diálogo aberto.
	if evento.is_action_pressed("nexus_forcar_desativar"):
		get_viewport().set_input_as_handled()
		ativar_modo_conforto()
		return
	if evento.is_action_pressed("nexus_tela_cheia"):
		get_viewport().set_input_as_handled()
		GerenciadorConfiguracoes.alternar_tela_cheia()
		return
	if GerenciadorJanelas.modal_ativo():
		return
	# Esc com o cursor num campo de texto (comando do Terminal, Bloco de Notas, endereço do Navegador...): o campo consumiria a tecla
	# na etapa da interface e ela nunca chegaria a `_unhandled_input`, então a pausa só abriria depois de o jogador sair do campo.
	# Aqui ela é lida antes. Quem tem Esc próprio (menu Iniciar, central de notificações, diálogos) já a tratou e consumiu em
	# `_input` quando estava aberto, e `pode_pausar()` confere o resto.
	if evento.is_action_pressed("ui_cancel") and _foco_em_campo_de_texto() and pode_pausar():
		get_viewport().set_input_as_handled()
		_pausa.abrir()
		return
	if evento.is_action_pressed("nexus_menu_iniciar"):
		get_viewport().set_input_as_handled()
		_ao_menu_pedido()
	elif evento.is_action_pressed("nexus_painel_debug"):
		get_viewport().set_input_as_handled()
		_alternar_debug()
	elif evento.is_action_pressed("nexus_abrir_terminal"):
		get_viewport().set_input_as_handled()
		_abrir_terminal()
	elif evento.is_action_pressed("nexus_pedir_ajuda"):
		get_viewport().set_input_as_handled()
		GerenciadorJanelas.abrir_app("maya")   # Ctrl+Shift+H: o painel da Maya (sempre disponível, também sem mouse)


## Esc abre o Menu de Pausa quando nada mais usou a tecla: o menu Iniciar, a central de notificações, os diálogos, os apps e a
## própria pausa tratam o Esc antes (em `_input`/GUI) e o consomem, então só chega aqui um Esc "livre".
func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel") and pode_pausar():
		get_viewport().set_input_as_handled()
		_pausa.abrir()


## O foco do teclado está num campo de texto (LineEdit ou TextEdit)? Esses campos tratam o Esc por conta própria.
func _foco_em_campo_de_texto() -> bool:
	var dono: Control = get_viewport().gui_get_focus_owner()
	return dono is LineEdit or dono is TextEdit


## O Esc pode abrir a pausa agora? Só com a área de trabalho pronta e o jogo rodando, sem troca de cena em curso, sem nada pausado,
## sem diálogo/menu/central aberto e sem a Tela de Fim de Jogo na frente.
func pode_pausar() -> bool:
	if not _pronto or _encerrando or get_tree().paused or Cenas.em_transicao() or not GerenciadorNarrativa.jogo_ativo:
		return false
	return not GerenciadorJanelas.modal_ativo() and not GerenciadorJanelas.overlay_ativo and not _menu.esta_aberto() and not _central.esta_aberto()


## Abre o Menu de Pausa se o jogo pode ser pausado agora (o monitor virtual chama isto quando o Esc chega com o foco no mundo físico). Devolve true se abriu.
func abrir_pausa() -> bool:
	if not pode_pausar():
		return false
	_pausa.abrir()
	return true


## Chamado por `Sessao` logo antes de o estado do jogo ser trocado por baixo desta cena (recomeçar, carregar, voltar ao menu):
## solta tudo o que a liga aos autoloads, fecha as janelas (cada app se encerra como de costume) e para de reagir a teclas.
## A cena em si é descartada pela troca de cena que vem em seguida.
func encerrar_sessao() -> void:
	if _encerrando:
		return
	_encerrando = true
	_cx.desligar_tudo()
	GerenciadorJanelas.overlay_ativo = false
	_menu.fechar()
	_central.fechar()
	GerenciadorJanelas.fechar_todas()
	_toasts.limpar()
	GerenciadorNarrativa.pausado = true


## "Modo conforto": reduz tudo o que pode incomodar (glitch, tremor, flashes, ruído, animações).
func ativar_modo_conforto() -> void:
	GerenciadorConfiguracoes.ativar_modo_conforto()
	SistemaNotificacoes.notificar("Modo conforto ativado", "Glitch, tremor, flashes, ruído e animações foram reduzidos. Ajuste em Configurações > Acessibilidade.", "info", 7.0)


# ------------------------------------------------------------------ montagem
func _garantir_jogo() -> void:
	if GerenciadorNarrativa.jogo_ativo or GerenciadorEstado.final_id != "":
		return
	# Cena aberta direto (F6 no editor): retoma o salvamento ou começa um jogo de teste.
	if SistemaPersistencia.existe_salvamento() and SistemaPersistencia.carregar():
		GerenciadorNarrativa.retomar()
	else:
		GerenciadorNarrativa.iniciar_novo_jogo("Usuário")


## Depois de trocar de dia ou de tema: a aparência vem das type variations do Theme (já recriado), então basta fechar
## o que estiver aberto, limpar os toasts e reler os dados que dependem da paleta (cores dos indicadores, atalhos).
func _atualizar_shell() -> void:
	_menu.fechar()
	_central.fechar()
	GerenciadorJanelas.overlay_ativo = false
	_toasts.limpar()
	_reconstruir_icones()
	_widget_relogio.atualizar()
	if _pronto:
		_barra.atualizar_tudo()


func _reconstruir_icones() -> void:
	UiKit.limpar_filhos(_grade_icones)
	if cena_icone == null:
		push_error("AreaDeTrabalho: 'cena_icone' não definida (veja area_de_trabalho.tscn).")
		return
	for info in GerenciadorJanelas.apps_da_area_de_trabalho():
		_novo_icone(info)


func _novo_icone(info: Dictionary) -> void:
	var icone: IconeAreaDeTrabalho = cena_icone.instantiate() as IconeAreaDeTrabalho
	icone.abrir_pedido.connect(_ao_icone_aberto)
	_grade_icones.add_child(icone)
	icone.configurar(info)


func _conectar() -> void:
	_cx.ligar(GerenciadorNarrativa.janela_solicitada, _ao_janela_solicitada)
	_cx.ligar(GerenciadorNarrativa.jogo_finalizado, _ao_final)
	_cx.ligar(GerenciadorNarrativa.etapa_iniciada, _ao_etapa_iniciada)
	_cx.ligar(GerenciadorEstado.glitch_solicitado, _ao_glitch)
	_cx.ligar(GerenciadorJanelas.catalogo_alterado, _reconstruir_icones)
	_cx.ligar(GerenciadorConfiguracoes.configuracao_alterada, _ao_configuracao)


## Roda um quadro depois do _ready: com tudo montado, o roteiro pode começar (e as janelas que ele pediu antes de a cena existir abrem).
func _iniciar_sessao() -> void:
	_pronto = true
	_barra.atualizar_tudo()
	_efeito.atualizar_base()
	SistemaAudio.tocar_sfx("boot", -8.0)
	GerenciadorNarrativa.pausado = false
	_abrir_janelas_pendentes()


func _abrir_janelas_pendentes() -> void:
	var fila: Array = GerenciadorNarrativa.janelas_pendentes.duplicate()
	GerenciadorNarrativa.janelas_pendentes.clear()
	for pedido in fila:
		GerenciadorJanelas.abrir_app(str((pedido as Dictionary)["app"]), (pedido as Dictionary).get("args", {}))


# ------------------------------------------------------------------ reações aos autoloads
## Uma janela que o roteiro pediu (relatório, cartões de permissão, minigame...).
func _ao_janela_solicitada(app_id: String, args: Dictionary) -> void:
	GerenciadorJanelas.abrir_app(app_id, args)


## Uma Task nova começou: a paleta acompanha o avanço da história.
func _ao_etapa_iniciada(etapa: int) -> void:
	TemaNexus.definir_etapa(etapa)
	TemaNexus.aplicar(get_tree())
	_fundo.atualizar()
	GerenciadorJanelas.atualizar_temas()
	_atualizar_shell()
	_efeito.atualizar_base()
	SistemaAudio.tocar_bgm(clampi(ceili(etapa / 2.0), 1, 5))


func _ao_final(_id_final: String) -> void:
	_encerrando = true
	GerenciadorNarrativa.pausado = true
	GerenciadorJanelas.overlay_ativo = false
	var t := create_tween()
	if GerenciadorConfiguracoes.animacoes_permitidas():
		t.tween_property(self, "modulate:a", 0.0, 1.2)
	else:
		t.tween_interval(0.2)
	t.tween_callback(_ir_para_final)


func _ir_para_final() -> void:
	if not Cenas.ir_para(get_tree(), Cenas.FINAL, _ao_falha_do_final):
		_ao_falha_do_final("recusado")


## A TelaFinal não pôde abrir (cena ausente, falha de carga ou outra troca em curso). Em vez de deixar o jogador numa área de
## trabalho já encerrada e sem saída, a Tela de Fim de Jogo abre aqui mesmo, com as mesmas saídas (recomeçar, carregar, menu).
func _ao_falha_do_final(_motivo: String) -> void:
	modulate.a = 1.0
	var dados_final: Dictionary = FluxoRoteiro.final_def(GerenciadorEstado.final_id)
	var titulo: String = str(dados_final.get("nome", "FIM"))
	_fim_de_jogo.abrir("%s\n\nA sessão chegou ao fim, mas o epílogo não pôde ser aberto." % titulo, TelaFimDeJogo.resumo_da_jornada(), Color.html("#8b5cf6"), false)


func _ao_glitch(intensidade: float, duracao: float) -> void:
	_efeito.disparar(intensidade, duracao)


func _ao_configuracao(chave: String, _valor: Variant) -> void:
	match chave:
		"tema", "alto_contraste", "tamanho_texto":
			TemaNexus.aplicar(get_tree())
			_fundo.atualizar()
			GerenciadorJanelas.atualizar_temas()
			_atualizar_shell()
			_efeito.atualizar_base()
		"papel_de_parede":
			_fundo.atualizar()
		"reduzir_glitch", "sem_flashes":
			_efeito.atualizar_base()


# ------------------------------------------------------------------ interações do shell
func _ao_icone_aberto(app_id: String) -> void:
	GerenciadorJanelas.abrir_app(app_id)


func _ao_menu_pedido() -> void:
	_central.fechar()
	_menu.alternar()


func _ao_central_pedido() -> void:
	_menu.fechar()
	_central.alternar()


func _ao_menu_aberto(aberto: bool) -> void:
	_barra.definir_menu_aberto(aberto)


func _alternar_debug() -> void:
	if not PainelDebug.permitido():
		SistemaNotificacoes.notificar("Painel de testes", "Desativado. Ligue em Configurações > Sistema para usar o F9.", "info", 5.0)
		return
	_debug.alternar()


func _abrir_terminal() -> void:
	GerenciadorJanelas.abrir_app("terminal")   # o atalho Ctrl+Shift+T também é um caminho para o Terminal quando o ícone saiu da área de trabalho


## "Sair para o início" do menu Iniciar (que já salvou): volta ao Menu Principal pela mesma fachada da Pausa.
func _ao_sair_para_boot() -> void:
	if not Sessao.voltar_ao_menu(get_tree(), _ao_falha_ao_sair):
		_ao_falha_ao_sair("recusado")


func _ao_falha_ao_sair(_motivo: String) -> void:
	SistemaNotificacoes.notificar("Erro", "O menu inicial não pôde ser aberto. O jogo continua.", "erro", 6.0)
