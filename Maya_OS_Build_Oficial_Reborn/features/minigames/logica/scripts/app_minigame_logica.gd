class_name AppMinigameLogica
extends AppBase
## Janela dos minigames de lógica (roteiro v2.0): `ordenar_lista3` (exercício da Task 4, tutorial do formato), `historico_fragmentado` (Task 5) e
## `trava_rafael` (Task 7). Todos: sem tempo, tentativas ilimitadas, mouse / teclado (setas + Enter) / controle (os controles são Buttons nativos
## e o foco circula entre eles), [Verificar] ou [Confirmar], [Sair] com o progresso salvo (`progresso_puzzles`) e [Como jogar] sempre disponível.
## O tutorial de abertura é pulado se `conhecimento_logico_adquirido`. As regras vivem em LogicaOrdem e LogicaContradicao (puras e testáveis);
## as definições (textos, ordem inicial, soluções) vêm de `core/data/minigames_logica.json`.
## Resultado: `GerenciadorNarrativa.concluir_minigame(id, "ok"|"sair")` (quando o nó atual é esse minigame). Aberto direto pelo arquivo
## (`origem` = "arquivo"), a trava do Rafael marca `minigame_rafael_resolvido` e abre o bloco de notas.

const CAMINHO_DADOS := "res://core/data/minigames_logica.json"
const ARQUIVO_TRAVA := "/home/usuario/Rafael/bloco_de_notas_oculto.txt"

static var _cache: Dictionary = {}

var _id: String = ""
var _def: Dictionary = {}
var _origem: String = ""
var _estado: Dictionary = {}
var _selecionada: String = ""
var _escolha: String = ""
var _encerrado: bool = false

var _rot_titulo: Label = null
var _rot_instrucao: Label = null
var _rot_msg: Label = null
var _rot_dica: Label = null
var _painel_tutorial: PanelContainer = null
var _rot_tutorial: Label = null
var _corpo: VBoxContainer = null
var _caixa_bandeja: VBoxContainer = null
var _caixa_slots: VBoxContainer = null
var _caixa_evidencias: VBoxContainer = null
var _caixa_afirmacoes: VBoxContainer = null
var _btn_verificar: Button = null
var _btn_devolver: Button = null
var _btn_sair: Button = null
var _btn_ajuda: Button = null
var _itens: Array = []


## Definições do JSON (cache estático). Devolve {} se o arquivo faltar.
static func definicoes() -> Dictionary:
	if _cache.is_empty():
		var f := FileAccess.open(CAMINHO_DADOS, FileAccess.READ)
		if f != null:
			var j: Variant = JSON.parse_string(f.get_as_text())
			if j is Dictionary:
				_cache = j
	return _cache


static func definicao(id: String) -> Dictionary:
	var m: Variant = definicoes().get("minigames", {})
	if m is Dictionary and (m as Dictionary).get(id) is Dictionary:
		return (m as Dictionary)[id]
	return {}


static func texto_como_jogar() -> String:
	return str((definicoes().get("comuns", {}) as Dictionary).get("como_jogar", ""))


func _ready() -> void:
	super._ready()
	var margem := MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 14)
	add_child(margem)
	var rolagem := ScrollContainer.new()
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margem.add_child(rolagem)
	var coluna := VBoxContainer.new()
	coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	coluna.add_theme_constant_override("separation", 10)
	rolagem.add_child(coluna)
	_rot_titulo = Label.new()
	_rot_titulo.theme_type_variation = &"RotuloTitulo18"
	coluna.add_child(_rot_titulo)
	_rot_instrucao = _rotulo(coluna)
	_painel_tutorial = PanelContainer.new()
	_painel_tutorial.theme_type_variation = &"PainelCartao"
	_painel_tutorial.visible = false
	var caixa_tut := VBoxContainer.new()
	_painel_tutorial.add_child(caixa_tut)
	_rot_tutorial = _rotulo(caixa_tut)
	var btn_entendi := Button.new()
	btn_entendi.text = "Entendi"
	btn_entendi.pressed.connect(_fechar_tutorial)
	caixa_tut.add_child(btn_entendi)
	coluna.add_child(_painel_tutorial)
	_corpo = VBoxContainer.new()
	_corpo.add_theme_constant_override("separation", 8)
	coluna.add_child(_corpo)
	_rot_msg = _rotulo(coluna)
	_rot_msg.theme_type_variation = &"RotuloAcento"
	_rot_dica = _rotulo(coluna)
	_rot_dica.theme_type_variation = &"RotuloAcento"
	var barra := HBoxContainer.new()
	barra.add_theme_constant_override("separation", 8)
	coluna.add_child(barra)
	_btn_verificar = Button.new()
	_btn_verificar.theme_type_variation = &"BotaoPrimario"
	_btn_verificar.pressed.connect(_ao_verificar)
	barra.add_child(_btn_verificar)
	_btn_devolver = Button.new()
	_btn_devolver.text = "Devolver à bandeja"
	_btn_devolver.pressed.connect(_ao_devolver)
	barra.add_child(_btn_devolver)
	_btn_ajuda = Button.new()
	_btn_ajuda.text = "Como jogar"
	_btn_ajuda.pressed.connect(_abrir_tutorial)
	barra.add_child(_btn_ajuda)
	_btn_sair = Button.new()
	_btn_sair.text = "Sair"
	_btn_sair.pressed.connect(_ao_sair)
	barra.add_child(_btn_sair)


func _rotulo(pai: Node) -> Label:
	var r := Label.new()
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.custom_minimum_size = Vector2(1, 0)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pai.add_child(r)
	return r


func iniciar(args: Dictionary = {}) -> void:
	_id = str(args.get("minigame", ""))
	_origem = str(args.get("origem", ""))
	_def = definicao(_id)
	_encerrado = false
	_selecionada = ""
	_escolha = ""
	if _def.is_empty():
		_rot_titulo.text = "Minigame indisponível"
		_rot_instrucao.text = "[CONTEUDO_NARRATIVO_PENDENTE]"
		_btn_verificar.visible = false
		_btn_devolver.visible = false
		return
	_rot_titulo.text = str(_def.get("titulo", ""))
	definir_titulo("Lógica: %s" % str(_def.get("titulo", "")))
	_rot_instrucao.text = str(_def.get("instrucao", ""))
	var salvo: Variant = GerenciadorEstado.progresso_puzzles.get(_id)
	if _tipo() == "ordem":
		_estado = LogicaOrdem.carregar(_def, salvo)
		_btn_verificar.text = "Verificar"
	else:
		_estado = LogicaContradicao.carregar(salvo)
		_btn_verificar.text = "Confirmar"
		_btn_devolver.visible = false
		_rot_instrucao.text = "%s\n%s" % [str(_def.get("cabecalho", "")), str(_def.get("instrucao", ""))]
	_rot_tutorial.text = texto_como_jogar()
	_painel_tutorial.visible = not GerenciadorEstado.tem_flag("conhecimento_logico_adquirido")
	_montar()
	if _painel_tutorial.visible:
		UiKit.focar_depois((_painel_tutorial.get_child(0).get_child(1) as Button))


func _tipo() -> String:
	return str(_def.get("tipo", ""))


func _abrir_tutorial() -> void:
	_painel_tutorial.visible = true
	UiKit.focar_depois((_painel_tutorial.get_child(0).get_child(1) as Button))


func _fechar_tutorial() -> void:
	_painel_tutorial.visible = false
	UiKit.focar_depois(_btn_verificar)


func _salvar() -> void:
	GerenciadorEstado.progresso_puzzles[_id] = _estado.duplicate(true)


# ------------------------------------------------------------------ interface
func _montar() -> void:
	UiKit.remover_itens(_itens)
	for filho in _corpo.get_children():
		_corpo.remove_child(filho)
		filho.queue_free()
	_caixa_bandeja = null
	_caixa_slots = null
	_caixa_evidencias = null
	_caixa_afirmacoes = null
	if _tipo() == "ordem":
		_montar_ordem()
	else:
		_montar_contradicao()
	_atualizar()


func _montar_ordem() -> void:
	var r1 := Label.new()
	r1.theme_type_variation = &"RotuloFraco11"
	r1.text = "Bandeja"
	_corpo.add_child(r1)
	_caixa_bandeja = VBoxContainer.new()
	_corpo.add_child(_caixa_bandeja)
	var r2 := Label.new()
	r2.theme_type_variation = &"RotuloFraco11"
	r2.text = "Sequência (posição 1 a %d)" % (_estado["slots"] as Array).size()
	_corpo.add_child(r2)
	_caixa_slots = VBoxContainer.new()
	_corpo.add_child(_caixa_slots)


func _montar_contradicao() -> void:
	_caixa_evidencias = VBoxContainer.new()
	_caixa_evidencias.add_theme_constant_override("separation", 6)
	_corpo.add_child(_caixa_evidencias)
	var r := Label.new()
	r.theme_type_variation = &"RotuloFraco11"
	r.text = "Escolha uma frase e aperte Confirmar"
	_corpo.add_child(r)
	_caixa_afirmacoes = VBoxContainer.new()
	_corpo.add_child(_caixa_afirmacoes)


func _atualizar() -> void:
	UiKit.remover_itens(_itens)
	if _tipo() == "ordem":
		_atualizar_ordem()
	else:
		_atualizar_contradicao()


func _botao(pai: Node, texto: String, ao_apertar: Callable, desativado: bool = false) -> Button:
	var b := Button.new()
	b.text = texto
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(1, UiKit.escalar(40))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.disabled = desativado
	b.pressed.connect(ao_apertar)
	pai.add_child(b)
	_itens.append(b)
	return b


func _atualizar_ordem() -> void:
	for id in LogicaOrdem.bandeja(_def, _estado):
		var sel: bool = str(id) == _selecionada
		_botao(_caixa_bandeja, ("✓ " if sel else "") + LogicaOrdem.texto_da_peca(_def, str(id)), _ao_peca_da_bandeja.bind(str(id)))
	var slots: Array = _estado["slots"]
	var travados: Array = _estado["travados"]
	for i in slots.size():
		var peca := str(slots[i])
		var texto := "%d. (vazio)" % (i + 1)
		if peca != "":
			texto = "%d. %s" % [i + 1, LogicaOrdem.texto_da_peca(_def, peca)]
			if bool(travados[i]):
				texto += "  [travada]"
			elif peca == _selecionada:
				texto = "✓ " + texto
		_botao(_caixa_slots, texto, _ao_slot.bind(i), bool(travados[i]))
	_btn_devolver.disabled = _selecionada == "" or not (slots as Array).has(_selecionada)
	_btn_verificar.disabled = _encerrado
	_mostrar_dica(LogicaOrdem.dica_ativa(_estado, _limite("verificacoes_para_dica")), LogicaOrdem.texto_da_dica(_def, _estado))


func _atualizar_contradicao() -> void:
	var destacar := LogicaContradicao.dica_ativa(_estado, _limite("erros_para_dica"))
	for ev in _def.get("evidencias", []):
		var d: Dictionary = ev
		var painel := PanelContainer.new()
		painel.theme_type_variation = &"PainelCartao"
		var texto := RichTextLabel.new()
		texto.bbcode_enabled = true
		texto.fit_content = true
		texto.focus_mode = Control.FOCUS_ALL
		texto.custom_minimum_size = Vector2(1, 0)
		var linhas: PackedStringArray = []
		var destaque := int(d.get("linha_destacavel", -1))
		var lista: Array = d.get("linhas", [])
		for k in lista.size():
			var l := str(lista[k]).replace("[", "[lb]")
			linhas.append("[b][color=#ffd166]%s[/color][/b]" % l if destacar and k == destaque else l)
		texto.text = "[b]%s — %s[/b]\n%s" % [str(d.get("id", "")), str(d.get("titulo", "")), "\n".join(linhas)]
		painel.add_child(texto)
		_caixa_evidencias.add_child(painel)
		_itens.append(painel)
	for a in _def.get("afirmacoes", []):
		var d2: Dictionary = a
		var id := str(d2.get("id", ""))
		_botao(_caixa_afirmacoes, ("✓ " if id == _escolha else "") + "%s — %s" % [id, str(d2.get("texto", ""))], _ao_afirmacao.bind(id))
	_btn_verificar.disabled = _escolha == "" or _encerrado
	_mostrar_dica(false, "")


func _limite(chave: String) -> int:
	return int((definicoes().get("comuns", {}) as Dictionary).get(chave, 2))


func _mostrar_dica(ativa: bool, texto: String) -> void:
	_rot_dica.visible = ativa and texto != ""
	_rot_dica.text = "Dica: %s" % texto


# ------------------------------------------------------------------ ordem
func _ao_peca_da_bandeja(id: String) -> void:
	_selecionada = "" if _selecionada == id else id
	_atualizar()


func _ao_slot(indice: int) -> void:
	if _encerrado:
		return
	var peca := str((_estado["slots"] as Array)[indice])
	if _selecionada != "":
		_estado = LogicaOrdem.colocar(_estado, _selecionada, indice)
		_selecionada = ""
		_rot_msg.text = ""
		_salvar()
	elif peca != "":
		_selecionada = peca   # pega a peça que já estava encaixada
	_atualizar()


func _ao_devolver() -> void:
	var indice: int = (_estado["slots"] as Array).find(_selecionada)
	if indice >= 0:
		_estado = LogicaOrdem.remover(_estado, indice)
		_selecionada = ""
		_salvar()
		_atualizar()


# ------------------------------------------------------------------ contradição
func _ao_afirmacao(id: String) -> void:
	_escolha = id
	_rot_msg.text = ""
	_atualizar()


# ------------------------------------------------------------------ verificar / confirmar
func _ao_verificar() -> void:
	if _encerrado or _def.is_empty():
		return
	if _tipo() == "ordem":
		var r: Dictionary = LogicaOrdem.verificar(_def, _estado)
		_estado = r["estado"]
		_selecionada = ""
		var novos: int = int(r["novos"])
		_rot_msg.text = ("%d peça(s) no lugar certo foram travadas." % novos) if novos > 0 else "Nenhuma peça nova no lugar certo. As erradas voltaram para a bandeja."
		_salvar()
		if LogicaOrdem.completo(_def, _estado):
			_rot_msg.text = "Sequência completa."
			_concluir_ok()
			return
		_atualizar()
	else:
		var r2: Dictionary = LogicaContradicao.confirmar(_def, _estado, _escolha)
		_estado = r2["estado"]
		_salvar()
		if bool(r2["ok"]):
			_concluir_ok()
			return
		_rot_msg.text = str(r2["mensagem"])
		_atualizar()


func _concluir_ok() -> void:
	_encerrado = true
	GerenciadorEstado.puzzles_resolvidos[_id] = true
	_btn_verificar.disabled = true
	if _id == "trava_rafael":
		var ja := GerenciadorEstado.tem_flag("minigame_rafael_resolvido")
		GerenciadorEstado.definir_flag_roteiro("minigame_rafael_resolvido", true)
		if not ja:
			GerenciadorNarrativa.maya_diz("Ele não sabia o que tava escrevendo.")
		if _origem == "arquivo":
			AbridorArquivos.abrir.call_deferred(ARQUIVO_TRAVA)   # o jogador abriu o bloco pelo arquivo: agora ele abre de verdade
	GerenciadorNarrativa.concluir_minigame(_id, "ok")
	_fechar_janela()


func _ao_sair() -> void:
	if _encerrado:
		return
	_encerrar_com_saida()
	_fechar_janela()


func _encerrar_com_saida() -> void:
	if _encerrado or _id == "":
		return
	_encerrado = true
	_salvar()
	GerenciadorNarrativa.concluir_minigame(_id, "sair")


func ao_fechar() -> void:
	if not _def.is_empty() and not _encerrado:
		_encerrar_com_saida()   # fechar a janela equivale a [Sair]: o progresso fica salvo


func _fechar_janela() -> void:
	if janela is JanelaBase:
		GerenciadorJanelas.fechar_janela.call_deferred(janela as JanelaBase, true)
