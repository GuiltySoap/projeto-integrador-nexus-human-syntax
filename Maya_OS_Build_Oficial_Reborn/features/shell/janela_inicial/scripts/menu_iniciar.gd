class_name MenuIniciar
extends Control
## Menu Iniciar: lista os aplicativos liberados (lidos do catálogo), busca aplicativos e arquivos do VFS
## e reúne Pedir ajuda, Salvar e Sair. Abre acima da barra de tarefas; Esc, F1 ou clicar fora fecham.
## Enquanto aberto marca GerenciadorJanelas.overlay_ativo (o gerenciador não rouba o foco por cliques).
## A estrutura (fundo, painel, cabeçalho, busca, grade, rodapé) está em menu_iniciar.tscn. Dinâmicos: um BotaoAppMenu
## por app na grade e um ResultadoBusca por resultado, instanciados dentro dos contêineres da cena.

signal aberto_alterado(aberto: bool)
signal sair_pedido()

const MAX_ARQUIVOS := 8

## Itens dinâmicos. Definidos em menu_iniciar.tscn.
@export var cena_botao_app: PackedScene
@export var cena_resultado: PackedScene

var _cx := Conexoes.new()
var _aberto: bool = false
var _acoes: Array = []

@onready var _campo: LineEdit = %Campo
@onready var _orbe: OrbeNexus = %Orbe
@onready var _rot_ia: Label = %RotuloIa
@onready var _rot_dia: Label = %RotuloDia
@onready var _rolagem_apps: ScrollContainer = %RolagemApps
@onready var _grade: GridContainer = %Grade
@onready var _rolagem_busca: ScrollContainer = %RolagemBusca
@onready var _sem_resultado: Label = %SemResultado
@onready var _secao_apps: VBoxContainer = %SecaoApps
@onready var _lista_apps: VBoxContainer = %ListaApps
@onready var _secao_arquivos: VBoxContainer = %SecaoArquivos
@onready var _lista_arquivos: VBoxContainer = %ListaArquivos


func _ready() -> void:
	if not UiKit.refs_ok(self, {"Campo": _campo, "Orbe": _orbe, "RotuloIa": _rot_ia, "RotuloDia": _rot_dia, "RolagemApps": _rolagem_apps,
			"Grade": _grade, "RolagemBusca": _rolagem_busca, "SemResultado": _sem_resultado, "SecaoApps": _secao_apps,
			"ListaApps": _lista_apps, "SecaoArquivos": _secao_arquivos, "ListaArquivos": _lista_arquivos}):
		return
	_cx.ligar(GerenciadorJanelas.catalogo_alterado, _ao_catalogo_alterado)


func _exit_tree() -> void:
	if _aberto:
		GerenciadorJanelas.overlay_ativo = false
	_cx.desligar_tudo()


func _input(evento: InputEvent) -> void:
	if _aberto and evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		fechar()


func esta_aberto() -> bool:
	return _aberto


func alternar() -> void:
	if _aberto:
		fechar()
	else:
		abrir()


func abrir() -> void:
	if _aberto:
		return
	_aberto = true
	visible = true
	GerenciadorJanelas.overlay_ativo = true
	_campo.text = ""
	_ao_busca("")
	_atualizar_cabecalho()
	_reconstruir_apps()
	GerenciadorEstado.set_flag("menu_iniciar_aberto", true)
	SistemaAudio.tocar_sfx("abrir")
	_campo.call_deferred("grab_focus")
	aberto_alterado.emit(true)


func fechar() -> void:
	if not _aberto:
		return
	_aberto = false
	visible = false
	GerenciadorJanelas.overlay_ativo = false
	aberto_alterado.emit(false)


# ------------------------------------------------------------------ conteúdo dinâmico
func _atualizar_cabecalho() -> void:
	_rot_dia.text = "HUMAXOS"
	_rot_ia.text = "Olá, %s." % GerenciadorEstado.nome_jogador
	_orbe.definir_estado(GerenciadorEstado.ia_estado)
	_orbe.reagir(0.6)


func _reconstruir_apps() -> void:
	UiKit.limpar_filhos(_grade)
	if cena_botao_app == null:
		push_error("MenuIniciar: 'cena_botao_app' não definida (veja menu_iniciar.tscn).")
		return
	for info in GerenciadorJanelas.apps_do_menu():
		var novo: bool = false
		var b: BotaoAppMenu = cena_botao_app.instantiate() as BotaoAppMenu
		b.pressed.connect(_ao_app.bind(str(info.get("id", ""))))
		_grade.add_child(b)
		b.configurar(info, novo)


# ------------------------------------------------------------------ busca
# Conectado na cena: Campo.text_changed
func _ao_busca(texto: String) -> void:
	var termo: String = texto.strip_edges()
	_acoes.clear()
	UiKit.limpar_filhos(_lista_apps)
	UiKit.limpar_filhos(_lista_arquivos)
	_rolagem_apps.visible = termo == ""
	_rolagem_busca.visible = termo != ""
	_sem_resultado.visible = false
	_secao_apps.visible = false
	_secao_arquivos.visible = false
	if termo == "":
		return
	var apps: Array = GerenciadorJanelas.buscar_apps(termo)
	var arquivos: Array = SistemaArquivosVirtual.buscar(termo, MAX_ARQUIVOS)
	if apps.is_empty() and arquivos.is_empty():
		var dica: String = "Nada encontrado para \"%s\"." % termo
		if termo.length() < 2:
			dica += " (Arquivos são buscados a partir de 2 letras.)"
		_sem_resultado.text = dica
		_sem_resultado.visible = true
		return
	_secao_apps.visible = not apps.is_empty()
	for info in apps:
		var r: ResultadoBusca = _novo_resultado(_lista_apps, {"tipo": "app", "alvo": str(info.get("id", ""))})
		if r != null:
			r.configurar_app(info, str(info.get("nome", "")), "Aplicativo")
	_secao_arquivos.visible = not arquivos.is_empty()
	for no in arquivos:
		var caminho: String = str(no.get("caminho", ""))
		var r: ResultadoBusca = _novo_resultado(_lista_arquivos, {"tipo": "arquivo", "alvo": caminho})
		if r != null:
			r.configurar_arquivo(AbridorArquivos.icone(no), SistemaArquivosVirtual.nome_do_caminho(caminho), caminho)


## Cria um resultado dentro da lista, registra a ação dele e conecta o clique.
func _novo_resultado(lista: Container, acao: Dictionary) -> ResultadoBusca:
	if cena_resultado == null:
		push_error("MenuIniciar: 'cena_resultado' não definida (veja menu_iniciar.tscn).")
		return null
	var indice: int = _acoes.size()
	_acoes.append(acao)
	var r: ResultadoBusca = cena_resultado.instantiate() as ResultadoBusca
	r.pressed.connect(_ao_resultado.bind(indice))
	lista.add_child(r)
	return r


func _executar(acao: Dictionary) -> void:
	fechar()
	var alvo: String = str(acao.get("alvo", ""))
	if str(acao.get("tipo", "")) == "app":
		GerenciadorJanelas.abrir_app(alvo)
	else:
		AbridorArquivos.abrir(alvo)


# ------------------------------------------------------------------ ações
# Conectado na cena: Fora.gui_input
func _ao_clique_fora(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.pressed:
		fechar()


func _ao_catalogo_alterado() -> void:
	if _aberto:
		_reconstruir_apps()
		if _campo.text.strip_edges() != "":
			_ao_busca(_campo.text)


func _ao_app(app_id: String) -> void:
	fechar()
	GerenciadorJanelas.abrir_app(app_id)


func _ao_resultado(indice: int) -> void:
	if indice >= 0 and indice < _acoes.size():
		var acao: Dictionary = _acoes[indice]
		_executar(acao)


# Conectado na cena: Campo.text_submitted
func _ao_busca_enviada(_texto: String) -> void:
	if not _acoes.is_empty():
		var acao: Dictionary = _acoes[0]
		_executar(acao)


# Conectado na cena: BotaoDica.pressed
func _ao_dica() -> void:
	fechar()
	GerenciadorJanelas.abrir_app("maya")   # "Falar com a Maya": o painel dela é o lugar da ajuda


# Conectado na cena: BotaoSalvar.pressed
func _ao_salvar() -> void:
	fechar()
	if SistemaPersistencia.salvar():
		SistemaNotificacoes.notificar("Jogo salvo", "Seu progresso foi gravado neste computador.", "sucesso", 3.0)
	else:
		SistemaNotificacoes.notificar("Falha ao salvar", "Não foi possível gravar o progresso. O jogo continua normalmente.", "erro", 6.0)


# Conectado na cena: BotaoSair.pressed
func _ao_sair() -> void:
	fechar()
	var ok: bool = await GerenciadorJanelas.confirmar("Sair para o início", "Seu progresso atual será salvo. Voltar à tela inicial?", "Salvar e sair", "Cancelar")
	if ok:
		SistemaPersistencia.salvar()
		sair_pedido.emit()
