class_name TelaFinal
extends Control
## Tela dos SEIS FINAIS do roteiro v2.0 (AV). Lê o final alcançado (GerenciadorEstado.final_id) e a sequência de passos de
## core/data/narrativa/finais_v2.json, e a apresenta um passo por vez, sem digitação animada nem flashes:
##   1. cada passo mostra o título e as linhas (narração, Maya, sistema, mensagem, comparação) cujas condições (`se`) valem agora;
##   2. passos com `acoes` mostram os botões do passo (a resposta aparece abaixo); os demais mostram [Continuar];
##   3. o final "Modo manual" (recusa total) acrescenta as respostas obrigatórias do roteiro;
##   4. mini-epílogo (frase final do final);
##   5. CARTÃO DE ENCERRAMENTO: dois pedidos de permissão fictícios (app de despertador e teclado), com [Permitir] e [Negar]. NADA é gravado
##      (nem permissão, nem Dependência, nem Autonomia, nem flag): é só a encenação de que o pedido continua depois do jogo;
##   6. a Tela de Fim de Jogo abre por cima, com as saídas de sessão (recomeçar, carregar, menu) e "Rever epílogo".
## Esc, com tudo lido, abre a Tela de Fim de Jogo. Botões focáveis por teclado e controle; texto sempre legível (sem depender de cor).
## "Tentar de novo (início da Task 9)" volta ao checkpoint da Task 9, quando existe.

const ATRASO_FIM_DE_JOGO := 0.4
const COR_FALA := {"narracao": "#e2e8f0", "maya": "#a78bfa", "sistema": "#fbbf24", "mensagem": "#7dd3fc", "comparacao": "#94a3b8"}

var _id: String = ""
var _dados: Dictionary = {}
var _passos: Array = []
var _indice: int = 0
var _fase: String = "passos"   # passos | epilogo | cartao | fim
var _cartao_indice: int = 0
var _concluida: bool = false
var _saindo: bool = false

var _rot_titulo: Label = null
var _rot_faixa: Label = null
var _rot_passo: Label = null
var _texto: RichTextLabel = null
var _caixa_botoes: HBoxContainer = null
var _rolagem: ScrollContainer = null

@onready var _fundo: ColorRect = %Fundo
@onready var _fim_de_jogo: TelaFimDeJogo = %TelaFimDeJogo


func _ready() -> void:
	if not UiKit.refs_ok(self, {"Fundo": _fundo, "TelaFimDeJogo": _fim_de_jogo}):
		return
	_id = GerenciadorEstado.final_id
	if _id == "" or FluxoRoteiro.final_def(_id).is_empty():
		_id = "meio_termo_2"   # cena aberta direto no editor
	_dados = FluxoRoteiro.final_def(_id)
	TemaNexus.aplicar(get_tree())
	_fundo.color = TemaNexus.cor("fundo")
	_montar()
	_passos = _passos_validos()
	SistemaAudio.parar_bgm()
	_mostrar_passo()


# ------------------------------------------------------------------ montagem
func _montar() -> void:
	var margem := MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 32)
	add_child(margem)
	move_child(margem, _fundo.get_index() + 1)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 12)
	margem.add_child(coluna)
	_rot_titulo = Label.new()
	_rot_titulo.theme_type_variation = &"RotuloTitulo18"
	_rot_titulo.text = str(_dados.get("nome", "FIM"))
	coluna.add_child(_rot_titulo)
	_rot_faixa = Label.new()
	_rot_faixa.theme_type_variation = &"RotuloFraco"
	_rot_faixa.text = str(_dados.get("faixa", ""))
	coluna.add_child(_rot_faixa)
	_rot_passo = Label.new()
	_rot_passo.theme_type_variation = &"RotuloAcento"
	coluna.add_child(_rot_passo)
	_rolagem = ScrollContainer.new()
	_rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	coluna.add_child(_rolagem)
	_texto = RichTextLabel.new()
	_texto.bbcode_enabled = true
	_texto.fit_content = true
	_texto.scroll_active = false
	_texto.selection_enabled = true
	_texto.focus_mode = Control.FOCUS_ALL
	_texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_texto.custom_minimum_size = Vector2(1, 0)
	_rolagem.add_child(_texto)
	_caixa_botoes = HBoxContainer.new()
	_caixa_botoes.add_theme_constant_override("separation", 10)
	coluna.add_child(_caixa_botoes)


func _input(evento: InputEvent) -> void:
	if evento.is_action_pressed("nexus_forcar_desativar"):
		get_viewport().set_input_as_handled()
		GerenciadorConfiguracoes.ativar_modo_conforto()
	elif evento.is_action_pressed("nexus_tela_cheia"):
		get_viewport().set_input_as_handled()
		GerenciadorConfiguracoes.alternar_tela_cheia()


## Esc, com a sequência inteira lida, abre a Tela de Fim de Jogo (a Pausa não existe aqui: o jogo já terminou).
func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel") and _concluida and em_cena_principal() and abrir_fim_de_jogo():
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ passos
func _passos_validos() -> Array:
	var saida: Array = []
	for p in _dados.get("passos", []):
		var pd: Dictionary = p
		if pd.has("se") and not GerenciadorEstado.avaliar_condicao(pd["se"]):
			continue
		if pd.has("oculta_se") and GerenciadorEstado.avaliar_condicao(pd["oculta_se"]):
			continue
		saida.append(pd)
	return saida


## Linhas de um passo que valem agora (`se` / `oculta_se`), já com o texto formatado ({NOME_JOGADOR}...).
func linhas_do_passo(passo: Dictionary) -> Array:
	var saida: Array = []
	for l in passo.get("linhas", []):
		var ld: Dictionary = l
		if ld.has("se") and not GerenciadorEstado.avaliar_condicao(ld["se"]):
			continue
		if ld.has("oculta_se") and GerenciadorEstado.avaliar_condicao(ld["oculta_se"]):
			continue
		saida.append(ld)
	return saida


func _mostrar_passo() -> void:
	_fase = "passos"
	if _indice >= _passos.size():
		_mostrar_epilogo()
		return
	var passo: Dictionary = _passos[_indice]
	_rot_passo.text = str(passo.get("titulo", ""))
	_texto.clear()
	for ld in linhas_do_passo(passo):
		_escrever_linha(ld)
	_rolagem.scroll_vertical = 0
	_limpar_botoes()
	var acoes: Array = passo.get("acoes", [])
	if acoes.is_empty():
		_botao("Continuar", _ao_continuar)
	else:
		for a in acoes:
			_botao(str((a as Dictionary).get("rotulo", "OK")), _ao_acao.bind(str((a as Dictionary).get("id", ""))))
	_focar_primeiro()


func _escrever_linha(ld: Dictionary) -> void:
	var tipo := str(ld.get("tipo", "narracao"))
	var texto := UtilTexto.escapar_bbcode(FluxoRoteiro.texto(str(ld.get("texto", ""))))
	var cor := str(COR_FALA.get(tipo, "#e2e8f0"))
	match tipo:
		"maya":
			texto = "[b]Maya:[/b] " + texto
		"sistema":
			texto = "[i]" + texto + "[/i]"
		"mensagem":
			var quem := str(ld.get("quem", ""))
			var nome := str(GerenciadorNarrativa.info_contato(quem).get("nome", quem)) if quem != "" else ""
			texto = "[b]%s:[/b] %s" % [UtilTexto.escapar_bbcode(nome), texto] if nome != "" else texto
		"comparacao":
			var voce := UtilTexto.escapar_bbcode(FluxoRoteiro.texto(str(ld.get("voce", ""))))
			texto = "[b]Diário do Rafael:[/b] %s\n[b]O que você fez:[/b] %s" % [texto, voce]
	_texto.append_text("[color=%s]%s[/color]\n\n" % [cor, texto])


func _ao_continuar() -> void:
	_indice += 1
	_mostrar_passo()


## Um botão de ação do passo: mostra a resposta (se houver) e troca os botões por [Continuar]. Nada é gravado.
func _ao_acao(id_acao: String) -> void:
	var passo: Dictionary = _passos[_indice]
	for a in passo.get("acoes", []):
		var ad: Dictionary = a
		if str(ad.get("id", "")) != id_acao:
			continue
		for ld in ad.get("resposta", []):
			_escrever_linha(ld)
		break
	_limpar_botoes()
	_botao("Continuar", _ao_continuar)
	_focar_primeiro()
	_rolar_para_fim()


# ------------------------------------------------------------------ epílogo e cartão de encerramento
func _mostrar_epilogo() -> void:
	_fase = "epilogo"
	_rot_passo.text = "Epílogo"
	_texto.clear()
	var respostas: Variant = _dados.get("respostas_obrigatorias")
	if respostas is Dictionary:
		for pergunta in respostas:
			_texto.append_text("[b]%s[/b]\n%s\n\n" % [UtilTexto.escapar_bbcode(str(pergunta)), UtilTexto.escapar_bbcode(FluxoRoteiro.texto(str((respostas as Dictionary)[pergunta])))])
	_texto.append_text("[i]%s[/i]\n" % UtilTexto.escapar_bbcode(FluxoRoteiro.texto(str(_dados.get("epilogo", "")))))
	_limpar_botoes()
	_botao("Continuar", _ao_epilogo_lido)
	_focar_primeiro()


func _ao_epilogo_lido() -> void:
	_cartao_indice = 0
	_mostrar_cartao()


## Cartão de encerramento: dois pedidos de permissão FICTÍCIOS. As duas respostas fecham o cartão sem registrar nada.
func _mostrar_cartao() -> void:
	_fase = "cartao"
	var cartoes: Array = FluxoRoteiro.cartao_de_encerramento()
	if _cartao_indice >= cartoes.size():
		_concluir()
		return
	_rot_passo.text = "Pedido de permissão"
	_texto.clear()
	_texto.append_text("[color=#fbbf24]%s[/color]\n\n[i]Este pedido é só parte da história: nada que você escolher aqui é registrado.[/i]\n" % UtilTexto.escapar_bbcode(FluxoRoteiro.texto(str((cartoes[_cartao_indice] as Dictionary).get("texto", "")))))
	_limpar_botoes()
	_botao("Permitir", _ao_cartao_respondido)
	_botao("Negar", _ao_cartao_respondido)
	_focar_primeiro()


func _ao_cartao_respondido() -> void:
	_cartao_indice += 1
	_mostrar_cartao()


func _concluir() -> void:
	_fase = "fim"
	_concluida = true
	_rot_passo.text = "Fim"
	_texto.clear()
	_texto.append_text("[b]%s[/b]\n%s\n\n%s\n" % [UtilTexto.escapar_bbcode(str(_dados.get("nome", ""))), UtilTexto.escapar_bbcode(str(_dados.get("faixa", ""))), UtilTexto.escapar_bbcode(TelaFimDeJogo.resumo_da_jornada())])
	_limpar_botoes()
	if SistemaPersistencia.existe_checkpoint(9):
		_botao("Tentar de novo (início da Task 9)", _ao_repetir_task_9)
	_botao("Mais opções", _ao_mais_opcoes)
	_botao("Voltar ao início", _ao_voltar_ao_inicio)
	_focar_primeiro()
	if em_cena_principal():
		var t := create_tween()
		t.tween_interval(ATRASO_FIM_DE_JOGO)
		t.tween_callback(abrir_fim_de_jogo)


# ------------------------------------------------------------------ botões
func _limpar_botoes() -> void:
	for b in _caixa_botoes.get_children():
		_caixa_botoes.remove_child(b)
		b.queue_free()


func _botao(rotulo: String, ao_apertar: Callable) -> void:
	var b := Button.new()
	b.text = rotulo
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(ao_apertar)
	_caixa_botoes.add_child(b)


func botoes_atuais() -> Array:
	return _caixa_botoes.get_children()


func _focar_primeiro() -> void:
	await get_tree().process_frame
	if is_inside_tree() and _caixa_botoes.get_child_count() > 0:
		(_caixa_botoes.get_child(0) as Button).grab_focus()


func _rolar_para_fim() -> void:
	await get_tree().process_frame
	if is_inside_tree():
		_rolagem.scroll_vertical = int(_rolagem.get_v_scroll_bar().max_value)


# ------------------------------------------------------------------ saídas
## Esta tela é a cena em execução do jogo? (Os testes a instanciam como filha de outra cena: aí ela não abre nada sozinha.)
func em_cena_principal() -> bool:
	return is_inside_tree() and get_tree().current_scene == self


## Abre a Tela de Fim de Jogo por cima desta (uma única vez por vez). Devolve false se não abriu (já aberta, saindo ou em troca).
func abrir_fim_de_jogo() -> bool:
	if _saindo or not is_inside_tree():
		return false
	var motivo: String = "%s\n\nA história chegou ao fim. Escolha o que fazer agora." % str(_dados.get("nome", "FIM"))
	return _fim_de_jogo.abrir(motivo, TelaFimDeJogo.resumo_da_jornada(), Color.html("#8b5cf6"), true)


func _ao_mais_opcoes() -> void:
	abrir_fim_de_jogo()


## "Rever epílogo": a Tela de Fim de Jogo fechou; o foco vai para a primeira saída desta tela.
func _ao_fim_de_jogo_revisto() -> void:
	_focar_primeiro()


## "Tentar de novo (início da Task 9)": pela fachada de sessão, que confere o checkpoint e carrega a cena antes de trocar o estado.
func _ao_repetir_task_9() -> void:
	if _saindo:
		return
	_saindo = true
	if not Sessao.carregar_checkpoint(get_tree(), 9, _ao_falha_ao_repetir):
		_ao_falha_ao_repetir("recusado")


func _ao_falha_ao_repetir(_motivo: String) -> void:
	_saindo = false
	SistemaNotificacoes.notificar("Checkpoint", "Não foi possível carregar o checkpoint da Task 9.", "erro", 5.0)


## "Voltar ao início": o Menu Principal, pela mesma fachada da Pausa (a campanha concluída continua salva).
func _ao_voltar_ao_inicio() -> void:
	if _saindo:
		return
	_saindo = true
	if not Sessao.voltar_ao_menu(get_tree(), _ao_falha_ao_sair):
		_ao_falha_ao_sair("recusado")


func _ao_falha_ao_sair(_motivo: String) -> void:
	_saindo = false
