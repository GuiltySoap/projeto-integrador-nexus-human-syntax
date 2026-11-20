class_name AppConfig
extends AppBase
## Configurações do HumaxOS: Personalização, Áudio, Acessibilidade, Privacidade e Sistema.
## PRIVACIDADE (roteiro v2.0): lista as cinco permissões da Maya (core/data/permissoes.json), todas desativadas no início. O jogador revoga
## com UM clique até o fim da Task 8 (Dependência −5, Autonomia +1 uma vez por permissão). Na Task 9 a Maya contesta: a primeira tentativa de
## cada permissão é ADIADA (a chave volta a "Ativado" e a Maya diz "Acho que você clicou sem querer."; nada muda) e a segunda revoga
## (Dependência −10, Autonomia +1). A regra vive em `Permissoes.revogar`; esta tela só chama e mostra o resultado. Não há botão que
## fuja do mouse, temporizador nem texto que esconda o estado real: a chave sempre mostra "Ativado" ou "Desativado" em texto.
## Permissões desativadas não são religadas aqui: elas só são concedidas pelo cartão de permissão da Maya (decisão explícita do jogador).
## ACESSIBILIDADE inclui "Tempo estendido nas barras de envio" (`tempo_estendido`: 3 s → 6 s).
## Args: {"pagina": "personalizacao" | "audio" | "acessibilidade" | "privacidade" | "sistema"}.
##
## A interface vive em app_config.tscn: menu lateral, as páginas e as linhas de configuração (instâncias de LinhaOpcao, LinhaCheck e
## LinhaSlider, cada uma com a `chave` no Inspector). As linhas de permissão são criadas aqui, com o mesmo componente LinhaCheck.

const CHAVES_ESPERADAS: Array = [
	"papel_de_parede", "tema", "tamanho_texto", "volume_master", "volume_bgm", "volume_sfx", "reduzir_glitch", "reduzir_tremor",
	"sem_flashes", "reduzir_ruido", "reduzir_animacoes", "alto_contraste", "tempo_estendido", "modo_depuracao",
	"desativar_efeitos_agressivos", "mostrar_indicador_oculto",
]
const CENA_LINHA_CHECK := "res://features/apps/config/components/linha_check/scenes/linha_check.tscn"

var _pronta: bool = false
var _pagina_atual: String = ""
var _paginas: Dictionary = {}       ## id da página -> ScrollContainer
var _botoes_menu: Dictionary = {}   ## id da página -> Button do menu
var _linhas: Dictionary = {}        ## chave da configuração -> LinhaOpcao | LinhaCheck | LinhaSlider
var _linhas_perm: Dictionary = {}   ## id da permissão -> LinhaCheck
var _rot_aviso: Label = null        ## a fala da Maya quando a revogação é adiada (também lida por leitores de tela)

@onready var _pg_personalizacao: ScrollContainer = %PaginaPersonalizacao
@onready var _pg_audio: ScrollContainer = %PaginaAudio
@onready var _pg_acessibilidade: ScrollContainer = %PaginaAcessibilidade
@onready var _pg_privacidade: ScrollContainer = %PaginaPrivacidade
@onready var _pg_sistema: ScrollContainer = %PaginaSistema
@onready var _bt_personalizacao: Button = %BotaoPersonalizacao
@onready var _bt_audio: Button = %BotaoAudio
@onready var _bt_acessibilidade: Button = %BotaoAcessibilidade
@onready var _bt_privacidade: Button = %BotaoPrivacidade
@onready var _bt_sistema: Button = %BotaoSistema
@onready var _lista_permissoes: Control = %ListaPermissoes
@onready var _rot_monitoramento: Label = %RotuloMonitoramento
@onready var _rot_sistema: Label = %RotuloSistema


func _ready() -> void:
	super()
	_pronta = UiKit.refs_ok(self, {
		"PaginaPersonalizacao": _pg_personalizacao, "PaginaAudio": _pg_audio, "PaginaAcessibilidade": _pg_acessibilidade,
		"PaginaPrivacidade": _pg_privacidade, "PaginaSistema": _pg_sistema, "BotaoPersonalizacao": _bt_personalizacao,
		"BotaoAudio": _bt_audio, "BotaoAcessibilidade": _bt_acessibilidade, "BotaoPrivacidade": _bt_privacidade,
		"BotaoSistema": _bt_sistema, "ListaPermissoes": _lista_permissoes, "RotuloMonitoramento": _rot_monitoramento,
		"RotuloSistema": _rot_sistema,
	})
	if not _pronta:
		return
	_paginas = {
		"personalizacao": _pg_personalizacao, "audio": _pg_audio, "acessibilidade": _pg_acessibilidade,
		"privacidade": _pg_privacidade, "sistema": _pg_sistema,
	}
	_botoes_menu = {
		"personalizacao": _bt_personalizacao, "audio": _bt_audio, "acessibilidade": _bt_acessibilidade,
		"privacidade": _bt_privacidade, "sistema": _bt_sistema,
	}
	_coletar_linhas()
	_criar_linhas_de_permissao()
	conectar(GerenciadorConfiguracoes.configuracao_alterada, _ao_configuracao_alterada)
	conectar(GerenciadorEstado.permissao_alterada, _ao_permissao_alterada)
	conectar(GerenciadorEstado.etapa_mudou, _ao_etapa_mudou)
	_sincronizar_tudo()


func iniciar(args: Dictionary = {}) -> void:
	if not _pronta:
		return
	var alvo := str(args.get("pagina", ""))
	_mostrar_pagina(alvo if _paginas.has(alvo) else (_pagina_atual if _pagina_atual != "" else "personalizacao"))


func receber_args(args: Dictionary) -> void:
	iniciar(args)


func ao_fechar() -> void:
	GerenciadorConfiguracoes.salvar()


## Guarda as linhas de configuração que já existem na cena, indexadas pela `chave` de cada uma.
func _coletar_linhas() -> void:
	for tipo in ["LinhaOpcao", "LinhaCheck", "LinhaSlider"]:
		for no in find_children("*", tipo, true, false):
			_linhas[str(no.get("chave"))] = no
	for chave in CHAVES_ESPERADAS:
		if not _linhas.has(chave):
			push_error("AppConfig: falta na cena uma linha para a configuração '%s'." % chave)


## Uma linha por permissão dos dados. A caixa só pode ser DESMARCADA aqui (revogar); religar é decisão do cartão da Maya.
func _criar_linhas_de_permissao() -> void:
	var cena: PackedScene = load(CENA_LINHA_CHECK) as PackedScene
	if cena == null:
		push_error("AppConfig: não foi possível carregar o componente de linha das permissões.")
		return
	for def in Permissoes.definicoes():
		var d: Dictionary = def
		var id_perm := str(d["id"])
		var cartao := PanelContainer.new()
		cartao.name = "Cartao_" + id_perm
		cartao.theme_type_variation = &"PainelCartao"
		var margem := MarginContainer.new()
		margem.name = "Margem"
		for lado in ["left", "right", "top", "bottom"]:
			margem.add_theme_constant_override("margin_" + lado, 10)
		var linha := cena.instantiate() as LinhaCheck
		linha.name = "Permissao_" + id_perm
		linha.chave = id_perm
		linha.titulo = str(d.get("nome", id_perm))
		linha.descricao = str(d.get("descricao", ""))
		cartao.tooltip_text = str((d.get("acessibilidade", {}) as Dictionary).get("descricao", ""))
		cartao.add_child(margem)
		margem.add_child(linha)
		linha.alternada.connect(_ao_permissao_alternada)
		_lista_permissoes.add_child(cartao)
		_linhas_perm[id_perm] = linha
	_rot_aviso = Label.new()
	_rot_aviso.name = "AvisoDaMaya"
	_rot_aviso.theme_type_variation = &"RotuloAcento"
	_rot_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rot_aviso.custom_minimum_size = Vector2(1, 0)
	_rot_aviso.visible = false
	_lista_permissoes.add_child(_rot_aviso)


# ------------------------------------------------------------------ páginas
func _mostrar_pagina(id_pagina: String) -> void:
	if not _pronta or not _paginas.has(id_pagina):
		return
	_pagina_atual = id_pagina
	for chave in _paginas:
		var pagina: Control = _paginas[chave]
		pagina.visible = str(chave) == id_pagina
	for chave in _botoes_menu:
		var b: Button = _botoes_menu[chave]
		b.set_pressed_no_signal(str(chave) == id_pagina)
	if id_pagina == "privacidade":
		GerenciadorEstado.set_flag("privacidade_visitada", true)
		_atualizar_permissoes()
	elif id_pagina == "sistema":
		_atualizar_sistema()


# ------------------------------------------------------------------ sincronização
func _sincronizar_tudo() -> void:
	for chave in _linhas:
		_sincronizar_controle(str(chave))
	_atualizar_permissoes()
	_atualizar_sistema()


func _sincronizar_controle(chave: String) -> void:
	var linha: Control = _linhas.get(chave)
	if linha == null:
		return
	var valor: Variant = GerenciadorConfiguracoes.obter(chave)
	if linha is LinhaCheck:
		(linha as LinhaCheck).definir_ativa(bool(valor))
	elif linha is LinhaSlider:
		(linha as LinhaSlider).definir_valor(float(valor))
	elif linha is LinhaOpcao:
		(linha as LinhaOpcao).definir_valor(valor)


func _atualizar_permissoes() -> void:
	if not _pronta:
		return
	var ativas: int = 0
	for nome in _linhas_perm:
		var ligada := Permissoes.valor(str(nome))
		if ligada:
			ativas += 1
		var linha: LinhaCheck = _linhas_perm[nome]
		linha.definir_ativa(ligada)
		linha.set_meta("estado_texto", "Ativado" if ligada else "Desativado")
		linha.descricao = "%s\nEstado: %s" % [str(Permissoes.info(str(nome)).get("descricao", "")), "Ativado" if ligada else "Desativado"]
	var total: int = _linhas_perm.size()
	if ativas == 0:
		_rot_monitoramento.text = "Nenhuma permissão ativa. A Maya não age sobre nada."
	else:
		_rot_monitoramento.text = "%d de %d permissões ativas. Desmarque uma caixa para revogar." % [ativas, total]


func _atualizar_sistema() -> void:
	if not _pronta:
		return
	var versao: Dictionary = Engine.get_version_info()
	_rot_sistema.text = "HumaxOS 1.0 — simulação\nUsuário: %s\nTask atual: %s\nMotor: Godot %s" % [
		GerenciadorEstado.nome_jogador, GerenciadorNarrativa.titulo_da_etapa(GerenciadorEstado.etapa_atual), str(versao.get("string", "4.x")),
	]


# ------------------------------------------------------------------ eventos das linhas e botões (ligados na cena)
func _ao_opcao(chave: String, valor: Variant) -> void:
	GerenciadorConfiguracoes.definir(chave, valor)
	SistemaAudio.tocar_sfx("clique", -8.0)


func _ao_alternar(chave: String, ativa: bool) -> void:
	GerenciadorConfiguracoes.definir(chave, ativa)


func _ao_slider(chave: String, valor: float) -> void:
	GerenciadorConfiguracoes.definir(chave, valor, false)


func _ao_slider_solto(_chave: String) -> void:
	GerenciadorConfiguracoes.salvar()
	SistemaAudio.tocar_sfx("clique", -6.0)


func _ao_testar_som() -> void:
	SistemaAudio.tocar_sfx("notificacao")


func _ao_ativar_conforto() -> void:
	GerenciadorConfiguracoes.ativar_modo_conforto()
	SistemaNotificacoes.notificar("Acessibilidade", "Modo conforto ativado: efeitos intensos desligados.", "sucesso", 4.0)


func _ao_desativar_conforto() -> void:
	GerenciadorConfiguracoes.desativar_modo_conforto()


func _ao_restaurar_acessibilidade() -> void:
	GerenciadorConfiguracoes.redefinir_acessibilidade()


func _ao_tela_cheia() -> void:
	GerenciadorConfiguracoes.alternar_tela_cheia()


func _ao_salvar_jogo() -> void:
	if SistemaPersistencia.salvar():
		SistemaNotificacoes.notificar("Sistema", "Jogo salvo.", "sucesso", 3.0)
	else:
		SistemaNotificacoes.notificar("Sistema", "Não foi possível salvar o jogo.", "erro", 5.0)


# ------------------------------------------------------------------ sinais dos autoloads
func _ao_configuracao_alterada(chave: String, _valor: Variant) -> void:
	_sincronizar_controle(chave)


func _ao_permissao_alterada(_nome: String, _ativa: bool) -> void:
	_atualizar_permissoes()


func _ao_etapa_mudou(_etapa: int) -> void:
	_atualizar_sistema()


# ------------------------------------------------------------------ privacidade: revogação
## A caixa foi clicada. Marcar uma permissão desativada NÃO a concede (só o cartão da Maya concede): a caixa volta ao estado real.
## Desmarcar uma ativa revoga pelo serviço central, que decide entre revogar e adiar (Task 9, primeira tentativa).
func _ao_permissao_alternada(nome: String, ativa: bool) -> void:
	if ativa:
		_atualizar_permissoes()
		_mostrar_aviso("Esta permissão só é concedida pelo cartão de permissão da Maya.")
		return
	var r: Dictionary = Permissoes.revogar(nome, "configuracoes")
	match str(r.get("resultado", "")):
		Permissoes.REVOGADA:
			GerenciadorEstado.set_flag("permissao_desativada_pelo_jogador", true)
			_mostrar_aviso("")
			SistemaNotificacoes.notificar("Privacidade", "Permissão revogada.", "info", 3.0)
		Permissoes.ADIADA:
			_mostrar_aviso("Maya: Acho que você clicou sem querer.")   # a mesma fala vai para o painel da Maya
		_:
			_mostrar_aviso("")
	_atualizar_permissoes()


func _mostrar_aviso(texto: String) -> void:
	if _rot_aviso == null:
		return
	_rot_aviso.text = texto
	_rot_aviso.visible = texto != ""
