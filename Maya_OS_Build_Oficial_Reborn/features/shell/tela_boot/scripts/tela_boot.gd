class_name TelaBoot
extends Control
## Boot diegético do HumaxOS. É a segunda etapa do "Novo Jogo" (a primeira é o Menu Principal, que vem depois da Splash Screen):
##   Executável -> Splash Screen -> Menu Principal -> Novo Jogo -> BIOS (log com som de boot, pode ser pulado) -> registro de
##   usuário (nome + acessibilidade) -> saudação da Maya com o orbe reativo -> área de trabalho no Dia 1.
## "Carregar" do Menu NÃO passa por aqui: vai direto ao salvamento (`Sessao.carregar`), sem BIOS, sem registro e sem saudação.
## Esta cena não é mais a cena principal do projeto e não leva ao Menu: ela só segue para a frente. A campanha só é iniciada quando
## a saudação termina (`Sessao.novo_jogo`), então abandonar o boot ("Voltar ao menu") nunca mexe no salvamento; o relógio da
## narrativa só começa depois que a área de trabalho existe.
## MODO NOVO JOGO (contexto `modo = "novo_jogo"`, definido pelo Menu): o registro não oferece "Continuar jogo salvo" (isso é o Carregar
## do Menu), mostra "Voltar ao menu" (Esc também volta) e não repete a confirmação de substituir o salvamento (o Menu já perguntou).
## Sem contexto (testes, painel de testes, ou `Sessao.voltar_ao_menu` quando o Menu não existe) ela mantém o fluxo antigo
## completo: BIOS -> registro com "Continuar jogo salvo" -> saudação.
##
## A interface (log da BIOS, painel de registro e tela de saudação) vive em tela_boot.tscn e os sinais dos botões,
## do campo de nome e das caixas de acessibilidade estão ligados na própria cena. Este script só controla as três
## fases, a digitação do log e da fala e a navegação para a próxima cena.
##
## BOOT TÉCNICO / INSTALAÇÃO DO HUMAXOS (§13): o registro é a instalação. Ele captura NOME + PRONOME (seletor %SelPronome), valida
## (InstalacaoHumaxOS.validar_perfil), MOSTRA as permissões (%ListaPermissoes, lidas dos dados) com o texto de confirmação
## ([CONFIRMACAO_DE_INSTALACAO]) e o botão "Entrar no sistema" é a confirmação. Ao concluir, `Sessao.novo_jogo(..., instalacao = true)` grava o perfil
## na campanha nova e emite `perfil_definido` e `instalacao_humaxos_concluida`. A lógica pura mora em InstalacaoHumaxOS (testável sem cena);
## pular e acessibilidade seguem a arquitetura existente (qualquer tecla pula a BIOS, "Pular ▶" na fala, modo conforto e alto contraste no painel).

const LINHAS_BIOS: Array = [
	"MAYA SYSTEMS BIOS v1.0",
	"Copyright (C) 2024 MAYA Corp.",
	"-----------------------------",
	"Initializing RAM: 16384 MB [b]OK[/b]",
	"Checking Primary Disk 0... [b]OK[/b]",
	"Mounting system partition 'AreaDeTrabalho'... [b]OK[/b]",
	"Loading OS Kernel...",
	"[color=red]ERROR: Non-critical intrusion detected in CORE_SERVICES.[/color]",
	"Isolating intruder signature...",
	"Bypassing security protocols... [b]SUCCESS[/b]",
	"[color=red]ERROR: Override confirmed.[/color]",
	"Assumindo controle periférico...",
	"Starting User Interface...",
	"HumaxOS 1.0 pronto. Aguardando registro de usuário.",
]
const VELOCIDADE_FALA := 55.0  # caracteres por segundo
## Quem dá dois cliques em "Novo Jogo" no Menu não pode pular a BIOS sem querer: o segundo clique chega quando a BIOS já abriu.
## Nesta janela (a partir da entrada na cena) o pulo da BIOS é ignorado.
const ATRASO_PULO_BIOS_MS := 400

enum Fase { BIOS, MENU, SAUDACAO }

var _fase: int = Fase.BIOS
var _indice: int = 0
var _espera: float = 0.8
var _meta: Dictionary = {}
var _nome: String = ""
var _pronome: String = PerfilJogador.PRONOME_PADRAO
var _confirmar_substituicao: bool = false
var _fala: String = ""
var _progresso_fala: float = 0.0
var _fala_completa: bool = false
var _entrando: bool = false
var _pronta: bool = false
## Aberta pelo Menu Principal (Novo Jogo): o registro não tem "Continuar jogo salvo" (é o Carregar do Menu) e tem "Voltar ao menu".
var _modo_novo_jogo: bool = false
## Instante (Time.get_ticks_msec) em que a cena abriu; base da janela `ATRASO_PULO_BIOS_MS`.
var _aberta_em_ms: int = 0
## Uma troca de cena (para o Menu Principal) já foi pedida: a entrada fica travada até ela terminar ou falhar.
var _saindo_para_menu: bool = false
## Linhas de permissão do registro (Labels criados pelo script a partir dos dados).

@onready var _fundo: ColorRect = %Fundo
@onready var _log: RichTextLabel = %Log
@onready var _menu: Control = %Menu
@onready var _rot_salvo: Label = %RotuloSalvo
@onready var _btn_continuar: Button = %BotaoContinuar
@onready var _campo_nome: LineEdit = %CampoNome
@onready var _rot_erro: Label = %RotuloErro
@onready var _btn_entrar: Button = %BotaoEntrar
@onready var _chk_conforto: CheckBox = %CaixaConforto
@onready var _chk_contraste: CheckBox = %CaixaContraste
@onready var _saudacao: Control = %Saudacao
@onready var _orbe: OrbeNexus = %Orbe
@onready var _rot_fala: Label = %RotuloFala
@onready var _btn_saudacao: Button = %BotaoSaudacao
@onready var _btn_voltar: Button = %BotaoVoltar
@onready var _sel_pronome: OptionButton = %SelPronome


func _ready() -> void:
	set_process(false)
	TemaNexus.aplicar(get_tree())
	GerenciadorNarrativa.sair_do_jogo()
	_aberta_em_ms = Time.get_ticks_msec()
	_modo_novo_jogo = str(Cenas.consumir_contexto().get("modo", "")) == "novo_jogo"
	_pronta = UiKit.refs_ok(self, {"Fundo": _fundo, "Log": _log, "Menu": _menu, "RotuloSalvo": _rot_salvo, "BotaoContinuar": _btn_continuar, "CampoNome": _campo_nome, "RotuloErro": _rot_erro, "BotaoEntrar": _btn_entrar, "CaixaConforto": _chk_conforto, "CaixaContraste": _chk_contraste, "Saudacao": _saudacao, "Orbe": _orbe, "RotuloFala": _rot_fala, "BotaoSaudacao": _btn_saudacao, "BotaoVoltar": _btn_voltar, "SelPronome": _sel_pronome})
	if not _pronta:
		return
	_preencher_instalacao()
	_fundo.color = TemaNexus.cor("fundo")
	_menu.visible = false
	_saudacao.visible = false
	_sincronizar_acessibilidade()
	if _modo_novo_jogo:
		# O Novo Jogo não lê nem mostra o salvamento aqui: quem pergunta antes de substituí-lo é o Menu Principal.
		_btn_continuar.visible = false
		_rot_salvo.visible = false
		_btn_voltar.visible = true
	else:
		_atualizar_salvamento()
	SistemaAudio.tocar_sfx("boot", -6.0)
	if GerenciadorConfiguracoes.animacoes_permitidas():
		set_process(true)
	else:
		_pular_bios()


func _input(evento: InputEvent) -> void:
	if not _pronta:
		return
	if evento.is_action_pressed("nexus_forcar_desativar"):
		get_viewport().set_input_as_handled()
		GerenciadorConfiguracoes.ativar_modo_conforto()
		_sincronizar_acessibilidade()
		return
	if evento.is_action_pressed("nexus_tela_cheia"):
		get_viewport().set_input_as_handled()
		GerenciadorConfiguracoes.alternar_tela_cheia()
		return
	if _saindo_para_menu:
		get_viewport().set_input_as_handled()
		return
	if _modo_novo_jogo and _fase == Fase.MENU and evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_ao_voltar()
		return
	if _fase == Fase.BIOS:
		var tecla: bool = evento is InputEventKey and evento.pressed and not evento.echo
		var clique: bool = evento is InputEventMouseButton and evento.pressed
		if tecla or clique:
			get_viewport().set_input_as_handled()
			if Time.get_ticks_msec() - _aberta_em_ms >= ATRASO_PULO_BIOS_MS:
				_pular_bios()
	elif _fase == Fase.SAUDACAO and evento.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_ao_saudacao_continuar()


func _process(delta: float) -> void:
	if _fase == Fase.BIOS:
		_avancar_bios(delta)
	elif _fase == Fase.SAUDACAO:
		_avancar_fala(delta)
	else:
		set_process(false)


# ------------------------------------------------------------------ fase 1: BIOS
func _avancar_bios(delta: float) -> void:
	_espera -= delta
	if _espera > 0.0:
		return
	if _indice >= LINHAS_BIOS.size():
		_abrir_registro()
		return
	var linha := str(LINHAS_BIOS[_indice])
	_indice += 1
	_log.append_text(linha + "\n")
	if "color=red" in linha:
		_espera = 0.9
	elif _indice >= LINHAS_BIOS.size():
		_espera = 0.8
	else:
		_espera = randf_range(0.08, 0.32)


func _pular_bios() -> void:
	if _fase != Fase.BIOS:
		return
	while _indice < LINHAS_BIOS.size():
		_log.append_text(str(LINHAS_BIOS[_indice]) + "\n")
		_indice += 1
	_abrir_registro()


## Fim da BIOS: abre o registro de usuário (nome + acessibilidade). No modo Novo Jogo não há "Continuar jogo salvo" (o Menu tem o
## Carregar) e há "Voltar ao menu"; no fluxo antigo (sem contexto) o "Continuar jogo salvo" aparece quando há salvamento.
func _abrir_registro() -> void:
	if _fase != Fase.BIOS:
		return
	_fase = Fase.MENU
	set_process(false)
	_indice = LINHAS_BIOS.size()
	if not _modo_novo_jogo:
		_atualizar_salvamento()
	_menu.visible = true
	if _btn_continuar.visible:
		_btn_continuar.call_deferred("grab_focus")
	else:
		_campo_nome.call_deferred("grab_focus")


# ------------------------------------------------------------------ voltar ao Menu Principal (só no modo Novo Jogo)
func _ao_voltar() -> void:
	if _entrando or _saindo_para_menu:
		return
	_saindo_para_menu = true
	if not Sessao.voltar_ao_menu(get_tree(), _ao_falha_de_volta):
		_ao_falha_de_volta("recusado")


func _ao_falha_de_volta(_motivo: String) -> void:
	_saindo_para_menu = false
	_mostrar_erro("Não foi possível voltar ao menu agora. Você pode continuar o registro.")


# ------------------------------------------------------------------ fase 2: registro
func _atualizar_salvamento() -> void:
	_meta = SistemaPersistencia.metadados()
	var existe := bool(_meta.get("existe", false))
	_btn_continuar.visible = existe
	_rot_salvo.visible = existe
	if existe:
		var final := str(_meta.get("final", ""))
		var situacao := "história concluída" if final != "" else GerenciadorNarrativa.titulo_da_etapa(int(_meta.get("etapa", 1)))
		_rot_salvo.text = "Salvamento encontrado: %s — %s (%s)" % [str(_meta.get("nome", "")), situacao, str(_meta.get("salvo_em", ""))]


func _sincronizar_acessibilidade() -> void:
	_chk_conforto.set_pressed_no_signal(GerenciadorConfiguracoes.modo_conforto_ativo())
	_chk_contraste.set_pressed_no_signal(bool(GerenciadorConfiguracoes.obter("alto_contraste")))


func _mostrar_erro(texto: String) -> void:
	_rot_erro.text = texto
	_rot_erro.visible = texto != ""


func _ao_conforto(ligado: bool) -> void:
	if ligado:
		GerenciadorConfiguracoes.ativar_modo_conforto()
	else:
		GerenciadorConfiguracoes.desativar_modo_conforto()


func _ao_contraste(ligado: bool) -> void:
	GerenciadorConfiguracoes.definir("alto_contraste", ligado)
	TemaNexus.aplicar(get_tree())


func _ao_tela_cheia() -> void:
	GerenciadorConfiguracoes.alternar_tela_cheia()


func _ao_sair() -> void:
	get_tree().quit()


func _ao_nome_alterado(_texto: String) -> void:
	if _confirmar_substituicao:
		_confirmar_substituicao = false
		_btn_entrar.text = "Entrar no sistema"
	_mostrar_erro("")


func _ao_nome_enviado(_texto: String) -> void:
	_ao_entrar()


func _ao_nome_padrao() -> void:
	_campo_nome.text = "Usuário"
	_ao_entrar()


func _ao_entrar() -> void:
	var perfil: Dictionary = InstalacaoHumaxOS.validar_perfil(_campo_nome.text.strip_edges(), _pronome_escolhido())
	if not bool(perfil["ok"]):
		_mostrar_erro(str(perfil["mensagem"]))
		_campo_nome.grab_focus()
		return
	if bool(_meta.get("existe", false)) and not _confirmar_substituicao and not _modo_novo_jogo:
		_confirmar_substituicao = true
		_btn_entrar.text = "Confirmar: substituir o salvamento"
		_mostrar_erro("Já existe um jogo salvo. Clique de novo para começar outro e substituí-lo.")
		return
	_nome = str(perfil["nome"])
	_pronome = str(perfil["pronome"])
	_iniciar_saudacao()


func _ao_continuar() -> void:
	if not SistemaPersistencia.carregar():
		_mostrar_erro("Não foi possível ler o salvamento. Comece um novo jogo.")
		_atualizar_salvamento()
		return
	GerenciadorNarrativa.retomar()
	var destino := Cenas.FINAL if GerenciadorEstado.final_id != "" else Cenas.GAMEPLAY
	if not Cenas.ir_para(get_tree(), destino):
		_mostrar_erro("Não foi possível abrir o jogo salvo (cena ausente).")


# ------------------------------------------------------------------ registro: pronome
## Monta o seletor de pronome com as opções dos dados.
func _preencher_instalacao() -> void:
	_sel_pronome.clear()
	var indice_padrao := 0
	for opcao in InstalacaoHumaxOS.opcoes_de_pronome():
		_sel_pronome.add_item(str((opcao as Dictionary)["rotulo"]))
		_sel_pronome.set_item_metadata(_sel_pronome.item_count - 1, str((opcao as Dictionary)["id"]))
		if str((opcao as Dictionary)["id"]) == PerfilJogador.PRONOME_PADRAO:
			indice_padrao = _sel_pronome.item_count - 1
	if _sel_pronome.item_count > 0:
		_sel_pronome.select(indice_padrao)


## O id do pronome escolhido no seletor (o padrão se o seletor estiver vazio ou sem seleção).
func _pronome_escolhido() -> String:
	if _sel_pronome == null or _sel_pronome.selected < 0 or _sel_pronome.selected >= _sel_pronome.item_count:
		return PerfilJogador.PRONOME_PADRAO
	return PerfilJogador.validar_pronome(_sel_pronome.get_item_metadata(_sel_pronome.selected))


# ------------------------------------------------------------------ fase 3: saudação da Maya
func _iniciar_saudacao() -> void:
	_fase = Fase.SAUDACAO
	_menu.visible = false
	_saudacao.visible = true
	_fala = InstalacaoHumaxOS.texto_saudacao(_nome, _pronome)
	_rot_fala.text = _fala
	_progresso_fala = 0.0
	_fala_completa = false
	if GerenciadorConfiguracoes.animacoes_permitidas():
		_rot_fala.visible_characters = 0
		_btn_saudacao.text = "Pular ▶"
		set_process(true)
	else:
		_concluir_fala()
	_orbe.definir_estado("amigavel")
	_orbe.reagir(1.0)
	_btn_saudacao.call_deferred("grab_focus")


func _avancar_fala(delta: float) -> void:
	if _fala_completa:
		set_process(false)
		return
	var antes := int(_progresso_fala)
	_progresso_fala += delta * VELOCIDADE_FALA
	var agora := int(_progresso_fala)
	_rot_fala.visible_characters = agora
	if floori(agora / 12.0) != floori(antes / 12.0):
		_orbe.reagir(0.25)
	if agora >= _fala.length():
		_concluir_fala()


func _concluir_fala() -> void:
	_fala_completa = true
	_rot_fala.visible_characters = -1
	_btn_saudacao.text = "Entrar no sistema ▶"


func _ao_saudacao_continuar() -> void:
	if _entrando:
		return
	if not _fala_completa:
		_concluir_fala()
		return
	_entrar_no_jogo()


# ------------------------------------------------------------------ entrada: a campanha só começa aqui
## A saudação terminou: só agora a campanha começa (Sessao.novo_jogo). A campanha só é reiniciada depois que a área de trabalho foi
## carregada: se algo falhar, nada mudou e a saudação continua na tela.
func _entrar_no_jogo() -> void:
	if _entrando or _fase != Fase.SAUDACAO:
		return
	_entrando = true
	if not Sessao.novo_jogo(get_tree(), _nome, _ao_falha_de_entrada, _pronome):
		_ao_falha_de_entrada("recusado")


func _ao_falha_de_entrada(_motivo: String) -> void:
	_entrando = false
	_fase = Fase.SAUDACAO
	_saudacao.visible = true
	_rot_fala.text = "Não foi possível abrir a área de trabalho (cena ausente). Verifique a instalação do jogo."
