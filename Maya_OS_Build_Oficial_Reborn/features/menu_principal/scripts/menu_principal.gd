class_name MenuPrincipal
extends Control
## Menu Principal: vem depois da Splash Screen (Executável -> Splash -> Menu) e é o destino de "Retornar ao Menu Inicial" (Pausa,
## Fim de Jogo e Tela Final). Não inicia o jogo sozinho: tudo começa por uma escolha do jogador.
##   - Novo Jogo: se já há progresso, pede confirmação (explicando que a campanha será reiniciada e o salvamento substituído; as
##     configurações são mantidas). Depois abre o boot diegético do HumaxOS na TelaBoot (BIOS, registro de usuário com nome +
##     acessibilidade e saudação da Maya), que reinicia a campanha pela API de sempre (GerenciadorNarrativa.iniciar_novo_jogo)
##     e abre a área de trabalho no Dia 1.
##   - Carregar: usa Sessao.carregar (a mesma ação da Pausa e do Fim de Jogo). Desativado, com a mensagem "Nenhum registro de
##     sessão disponível.", quando não há salvamento nem checkpoint válido. Se a restauração falhar, o jogador continua aqui e o
##     estado atual não é tocado; um salvamento inválido nunca é apagado.
##   - Opções e Créditos: painéis sobre o menu (os mesmos componentes do jogo). Esc fecha.
##   - Sair do jogo: fecha o aplicativo (a TelaBoot já oferecia isto; sem o botão não haveria saída além de Alt+F4).
## Toda a estrutura (fundo, camada atmosférica, logo, botões, painéis, confirmação e indicador de carregamento) vive em
## menu_principal.tscn. Este script liga os botões, mantém o estado do botão Carregar e os avisos e cuida do foco.

var _ocupado: bool = false
var _acao_pendente: StringName = &""
var _origem_modal: Control = null
var _ponto: Dictionary = {}
var _cx := Conexoes.new()

@onready var _fundo: ColorRect = %Fundo
@onready var _margem: MarginContainer = %MargemPrincipal
@onready var _btn_novo: Button = %BotaoNovoJogo
@onready var _btn_carregar: Button = %BotaoCarregar
@onready var _btn_opcoes: Button = %BotaoOpcoes
@onready var _btn_creditos: Button = %BotaoCreditos
@onready var _btn_sair: Button = %BotaoSair
@onready var _linha_status: Control = %LinhaStatus
@onready var _icone_status: Label = %IconeStatus
@onready var _rot_status: Label = %MensagemStatus
@onready var _rot_salvamento: Label = %RotuloSalvamento
@onready var _rot_versao: Label = %Versao
@onready var _painel_opcoes: PainelOpcoes = %PainelOpcoes
@onready var _painel_creditos: PainelCreditos = %PainelCreditos
@onready var _dialogo: PainelConfirmacao = %DialogoConfirmacao
@onready var _indicador: IndicadorCarregamento = %IndicadorCarregamento


func _ready() -> void:
	TemaNexus.definir_dia(1)
	TemaNexus.aplicar(get_tree())
	# Chegar ao menu (do boot, da pausa, do fim de jogo) sempre encerra a sessão anterior e a trilha dela.
	GerenciadorNarrativa.sair_do_jogo()
	SistemaAudio.parar_bgm()
	if not UiKit.refs_ok(self, {"Fundo": _fundo, "MargemPrincipal": _margem, "BotaoNovoJogo": _btn_novo, "BotaoCarregar": _btn_carregar,
			"BotaoOpcoes": _btn_opcoes, "BotaoCreditos": _btn_creditos, "BotaoSair": _btn_sair, "LinhaStatus": _linha_status, "IconeStatus": _icone_status,
			"MensagemStatus": _rot_status, "RotuloSalvamento": _rot_salvamento, "Versao": _rot_versao, "PainelOpcoes": _painel_opcoes,
			"PainelCreditos": _painel_creditos, "DialogoConfirmacao": _dialogo, "IndicadorCarregamento": _indicador}):
		return
	_cx.ligar(GerenciadorConfiguracoes.configuracao_alterada, _ao_configuracao)
	_aplicar_cores()
	var motor: Dictionary = Engine.get_version_info()
	_rot_versao.text = "HumaxOS 1.0 — simulação · Godot %s" % str(motor.get("string", "4.x"))
	_atualizar_estado()
	_btn_novo.call_deferred("grab_focus")
	if GerenciadorConfiguracoes.animacoes_permitidas():
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 0.45)


func _exit_tree() -> void:
	_cx.desligar_tudo()


## As teclas de segurança funcionam em qualquer tela: Ctrl+Shift+D (modo conforto) e F11 (tela cheia).
func _input(evento: InputEvent) -> void:
	if evento.is_action_pressed("nexus_forcar_desativar"):
		get_viewport().set_input_as_handled()
		GerenciadorConfiguracoes.ativar_modo_conforto()
	elif evento.is_action_pressed("nexus_tela_cheia"):
		get_viewport().set_input_as_handled()
		GerenciadorConfiguracoes.alternar_tela_cheia()


# ------------------------------------------------------------------ estado da tela
## Relê o salvamento (o botão Carregar só vale com um ponto de carga válido) e refaz o aviso e o anel de foco.
func _atualizar_estado() -> void:
	_ponto = Sessao.ponto_de_carga(Sessao.Origem.MENU)
	var existe: bool = bool(_ponto.get("existe", false))
	_btn_carregar.disabled = _ocupado or not existe
	_btn_carregar.tooltip_text = "" if existe else Sessao.MSG_SEM_REGISTRO
	_rot_salvamento.visible = existe
	if existe:
		_rot_salvamento.text = "Salvamento: " + Sessao.descrever_ponto(_ponto)
		_limpar_status()
	else:
		_mostrar_status(Sessao.MSG_SEM_REGISTRO, false)
	_ligar_foco()


func _ligar_foco() -> void:
	UiKit.ligar_foco_circular([_btn_novo, _btn_carregar, _btn_opcoes, _btn_creditos, _btn_sair])


func _aplicar_cores() -> void:
	var cor_fundo: Color = TemaNexus.cor("fundo")
	_fundo.color = cor_fundo


## Aviso sob os botões. O estado de erro não depende só da cor: tem ícone próprio (⚠) além do texto.
func _mostrar_status(texto: String, erro: bool) -> void:
	_icone_status.text = "⚠" if erro else "ℹ"
	_icone_status.theme_type_variation = &"RotuloPerigo" if erro else &"RotuloFraco"
	_rot_status.theme_type_variation = &"RotuloPerigo" if erro else &"RotuloFraco"
	_rot_status.text = texto
	_linha_status.visible = texto != ""


func _limpar_status() -> void:
	_rot_status.text = ""
	_linha_status.visible = false


## Durante uma troca de cena: botões desativados e a camada de carregamento cobrindo (e bloqueando) a tela.
func _definir_ocupado(ocupado: bool, texto: String = "") -> void:
	_ocupado = ocupado
	if ocupado:
		_indicador.mostrar(texto)
	for botao in [_btn_novo, _btn_opcoes, _btn_creditos, _btn_sair]:
		(botao as Button).disabled = ocupado
	_btn_carregar.disabled = ocupado or not bool(_ponto.get("existe", false))
	if not ocupado:
		_indicador.ocultar()
	_ligar_foco()


func _modal_aberto() -> bool:
	return _dialogo.esta_aberto() or _painel_opcoes.esta_aberto() or _painel_creditos.esta_aberto()


## Abre um painel por cima do menu: o que está atrás perde o foco (Tab/setas não vazam) até o painel fechar.
func _abrir_modal(origem: Control) -> void:
	_origem_modal = origem
	UiKit.travar_foco(_margem, true)


func _fechar_modal() -> void:
	UiKit.travar_foco(_margem, false)
	_ligar_foco()
	var origem: Control = _origem_modal
	_origem_modal = null
	if origem != null:
		_devolver_foco.call_deferred(origem)


## Devolve o foco ao botão que abriu o painel, a não ser que uma troca de cena já tenha começado (aí o foco é do indicador).
func _devolver_foco(destino: Control) -> void:
	if _ocupado or destino == null or not is_instance_valid(destino) or destino.focus_mode == Control.FOCUS_NONE:
		return
	var botao: BaseButton = destino as BaseButton
	if botao != null and botao.disabled:
		return
	destino.grab_focus()


# ------------------------------------------------------------------ botões
func _ao_novo_jogo() -> void:
	if _ocupado or _modal_aberto():
		return
	SistemaAudio.tocar_sfx("clique", -8.0)
	_limpar_status()
	_ponto = Sessao.ponto_de_carga(Sessao.Origem.MENU)
	if not bool(_ponto.get("existe", false)):
		_iniciar_novo_jogo()
		return
	_acao_pendente = &"novo_jogo"
	_abrir_modal(_btn_novo)
	_dialogo.perguntar("Iniciar um novo jogo?\n\nO progresso da campanha atual (%s) será reiniciado e o salvamento existente será substituído. As configurações do jogo (áudio, tela e acessibilidade) são mantidas." % Sessao.resumo_curto(_ponto), "Novo jogo", "Cancelar", true)


func _ao_carregar() -> void:
	if _ocupado or _modal_aberto():
		return
	SistemaAudio.tocar_sfx("clique", -8.0)
	_limpar_status()
	_ponto = Sessao.ponto_de_carga(Sessao.Origem.MENU)
	if not bool(_ponto.get("existe", false)):
		_atualizar_estado()
		return
	_definir_ocupado(true, "Restaurando a sessão…")
	if not Sessao.carregar(get_tree(), Sessao.Origem.MENU, _ao_falha_de_carga):
		_ao_falha_de_carga("recusado")


func _ao_opcoes() -> void:
	if _ocupado or _modal_aberto():
		return
	SistemaAudio.tocar_sfx("clique", -8.0)
	_abrir_modal(_btn_opcoes)
	_painel_opcoes.abrir()


func _ao_creditos() -> void:
	if _ocupado or _modal_aberto():
		return
	SistemaAudio.tocar_sfx("clique", -8.0)
	_abrir_modal(_btn_creditos)
	_painel_creditos.abrir()


func _ao_sair() -> void:
	if _ocupado or _modal_aberto():
		return
	get_tree().quit()


# ------------------------------------------------------------------ respostas dos painéis
func _ao_painel_fechado() -> void:
	_fechar_modal()


func _ao_confirmado() -> void:
	var acao: StringName = _acao_pendente
	_acao_pendente = &""
	_fechar_modal()
	if acao == &"novo_jogo":
		_iniciar_novo_jogo()


func _ao_cancelado() -> void:
	_acao_pendente = &""
	_fechar_modal()


# ------------------------------------------------------------------ trocas de cena
## O boot diegético do HumaxOS (BIOS, registro de usuário e saudação da Maya) é a sequência do Novo Jogo e vive na TelaBoot, que o
## Menu abre em modo "novo_jogo". Nada é reiniciado aqui: a campanha só é substituída quando o jogador conclui o registro e entra
## no sistema (e "Voltar ao menu" no registro não mexe em nada). O Carregar não passa pela TelaBoot.
func _iniciar_novo_jogo() -> void:
	_definir_ocupado(true, "Iniciando o HumaxOS…")
	Cenas.definir_contexto({"modo": "novo_jogo"})
	if not Cenas.ir_para(get_tree(), Cenas.BOOT, _ao_falha_de_troca):
		_ao_falha_de_troca("recusado")


func _ao_falha_de_troca(_motivo: String) -> void:
	Cenas.consumir_contexto()
	_definir_ocupado(false)
	_mostrar_status(Sessao.MSG_FALHA_TROCA, true)
	_btn_novo.call_deferred("grab_focus")


func _ao_falha_de_carga(_motivo: String) -> void:
	_definir_ocupado(false)
	_atualizar_estado()
	_mostrar_status(Sessao.MSG_FALHA_CARGA, true)
	_btn_carregar.call_deferred("grab_focus")


## Tema, contraste e tamanho do texto mudam na hora quando o jogador mexe nas Opções.
func _ao_configuracao(chave: String, _valor: Variant) -> void:
	match chave:
		"tema", "alto_contraste", "tamanho_texto":
			TemaNexus.aplicar(get_tree())
			_aplicar_cores()
