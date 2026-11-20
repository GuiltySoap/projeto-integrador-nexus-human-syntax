class_name AppRotina
extends AppBase
## Montagem da rotina (Task 3, T3.5). Não é minigame: sem tempo, sem erro, sem solução única. Quatro blocos (Estudo, Descanso, Lazer, Sair com
## amigos) para quatro espaços. COMO USAR (mouse, teclado ou controle): aperte um bloco da lista (ou um já encaixado) e depois o espaço onde ele
## deve ficar; blocos encaixados trocam de lugar. Quando o terceiro bloco é encaixado, a Maya preenche o quarto e diz que bateu com o que ela
## tinha calculado. [Concluir rotina] confirma; se "Sair com amigos" estiver antes de "Estudo", a Maya avisa do conflito ([Tenho certeza] /
## [Trocar]). A conclusão avisa a narrativa (`rotina_concluida`). O progresso fica salvo em `roteiro_aux["rotina"]`.
## O roteiro deixa a alteração de estado desses dois botões como [ALTERAÇÃO DE ESTADO NÃO ESPECIFICADA]: só se guarda `rotina_resultado` (aux).

var _slots: Array = RotinaLogica.vazia()
var _selecionado: String = ""
var _concluida: bool = false
var _rot_info: Label = null
var _caixa_disponiveis: HBoxContainer = null
var _caixa_slots: HBoxContainer = null
var _rot_conflito: Label = null
var _caixa_conflito: HBoxContainer = null
var _btn_concluir: Button = null
var _itens: Array = []


func _ready() -> void:
	super._ready()
	var margem := MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 14)
	add_child(margem)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 10)
	margem.add_child(coluna)
	var titulo := Label.new()
	titulo.theme_type_variation = &"RotuloTitulo18"
	titulo.text = "Monte a sua rotina"
	coluna.add_child(titulo)
	_rot_info = Label.new()
	_rot_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rot_info.custom_minimum_size = Vector2(1, 0)
	_rot_info.text = "Aperte um bloco e depois o espaço onde ele deve ficar. Sem tempo e sem erro."
	coluna.add_child(_rot_info)
	var rot_blocos := Label.new()
	rot_blocos.theme_type_variation = &"RotuloFraco11"
	rot_blocos.text = "Blocos disponíveis"
	coluna.add_child(rot_blocos)
	_caixa_disponiveis = HBoxContainer.new()
	_caixa_disponiveis.add_theme_constant_override("separation", 8)
	coluna.add_child(_caixa_disponiveis)
	var rot_slots := Label.new()
	rot_slots.theme_type_variation = &"RotuloFraco11"
	rot_slots.text = "Espaços da rotina (1 a 4)"
	coluna.add_child(rot_slots)
	_caixa_slots = HBoxContainer.new()
	_caixa_slots.add_theme_constant_override("separation", 8)
	coluna.add_child(_caixa_slots)
	_rot_conflito = Label.new()
	_rot_conflito.theme_type_variation = &"RotuloAcento"
	_rot_conflito.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rot_conflito.custom_minimum_size = Vector2(1, 0)
	_rot_conflito.visible = false
	coluna.add_child(_rot_conflito)
	_caixa_conflito = HBoxContainer.new()
	_caixa_conflito.visible = false
	for par in [["Tenho certeza", "certeza"], ["Trocar", "trocar"]]:
		var b := Button.new()
		b.text = par[0]
		b.custom_minimum_size = Vector2(UiKit.escalar(130), UiKit.escalar(40))
		b.pressed.connect(_ao_conflito.bind(str(par[1])))
		_caixa_conflito.add_child(b)
	coluna.add_child(_caixa_conflito)
	_btn_concluir = Button.new()
	_btn_concluir.text = "Concluir rotina"
	_btn_concluir.disabled = true
	_btn_concluir.pressed.connect(_ao_concluir)
	coluna.add_child(_btn_concluir)
	definir_titulo("Montar rotina")


func iniciar(_args: Dictionary = {}) -> void:
	var salvo: Variant = GerenciadorEstado.roteiro_aux.get("rotina")
	if salvo is Array and (salvo as Array).size() == RotinaLogica.BLOCOS.size():
		_slots = (salvo as Array).duplicate()
	_atualizar()


func _salvar() -> void:
	GerenciadorEstado.roteiro_aux["rotina"] = _slots.duplicate()


# ------------------------------------------------------------------ interface
func _atualizar() -> void:
	UiKit.remover_itens(_itens)
	for b in RotinaLogica.disponiveis(_slots):
		_novo_bloco(_caixa_disponiveis, str(b), -1)
	for i in _slots.size():
		_novo_bloco(_caixa_slots, str(_slots[i]), i)
	_btn_concluir.disabled = not RotinaLogica.completa(_slots) or _concluida or _caixa_conflito.visible
	if _selecionado != "":
		_rot_info.text = "Selecionado: %s. Aperte o espaço onde ele deve ficar." % _selecionado
	elif RotinaLogica.completa(_slots):
		_rot_info.text = "Rotina completa. Você pode mover os blocos ou concluir."


func _novo_bloco(pai: HBoxContainer, bloco: String, indice: int) -> void:
	var b := Button.new()
	b.custom_minimum_size = Vector2(UiKit.escalar(130), UiKit.escalar(48))
	if indice >= 0:
		b.text = "%d. %s" % [indice + 1, bloco if bloco != RotinaLogica.VAZIO else "(vazio)"]
	else:
		b.text = bloco
	if bloco != "" and bloco == _selecionado:
		b.text += " ✓"
	b.disabled = _concluida
	b.pressed.connect(_ao_apertar.bind(bloco, indice))
	pai.add_child(b)
	_itens.append(b)


func _ao_apertar(bloco: String, indice: int) -> void:
	if _concluida:
		return
	if indice < 0:
		_selecionado = "" if _selecionado == bloco else bloco   # bloco da lista: seleciona (ou solta a seleção)
		_atualizar()
		return
	if _selecionado == "":
		_selecionado = bloco   # bloco já encaixado (ou espaço vazio, que não seleciona nada)
		_atualizar()
		return
	_colocar(_selecionado, indice)


## Encaixa o bloco selecionado no espaço; se ficaram três blocos, a Maya preenche o quarto.
func colocar_bloco(bloco: String, indice: int) -> void:
	_colocar(bloco, indice)


func _colocar(bloco: String, indice: int) -> void:
	var antes := RotinaLogica.ocupados(_slots)
	_slots = RotinaLogica.colocar(_slots, bloco, indice)
	_selecionado = ""
	_caixa_conflito.visible = false
	_rot_conflito.visible = false
	var jogada: Dictionary = RotinaLogica.jogada_da_maya(_slots)
	if antes < RotinaLogica.ocupados(_slots) and not jogada.is_empty():
		_slots = RotinaLogica.colocar(_slots, str(jogada["bloco"]), int(jogada["indice"]))
		GerenciadorNarrativa.maya_diz("Isso! Bati com o que eu tinha calculado.")
	_salvar()
	_atualizar()


func _ao_concluir() -> void:
	if not RotinaLogica.completa(_slots) or _concluida:
		return
	if RotinaLogica.conflito(_slots):
		GerenciadorNarrativa.maya_diz("Conflito de produtividade detectado. Tem certeza?")
		_rot_conflito.text = "Conflito de produtividade detectado. Tem certeza?"
		_rot_conflito.visible = true
		_caixa_conflito.visible = true
		_btn_concluir.disabled = true
		UiKit.focar_depois((_caixa_conflito.get_child(0) as Button))
		return
	_finalizar("sem_conflito")


func _ao_conflito(escolha: String) -> void:
	if escolha == "trocar":
		_slots = RotinaLogica.resolver_trocando(_slots)
		GerenciadorNarrativa.maya_diz("Assim fica melhor.")
		_finalizar("trocado")
	else:
		GerenciadorNarrativa.maya_diz("Ok. Anotado.")
		_finalizar("anotado")


func _finalizar(resultado: String) -> void:
	_concluida = true
	_caixa_conflito.visible = false
	_rot_conflito.visible = false
	GerenciadorEstado.roteiro_aux["rotina_resultado"] = resultado
	_salvar()
	_atualizar()
	GerenciadorNarrativa.notificar("rotina_concluida", {"resultado": resultado})
	if janela is JanelaBase:
		GerenciadorJanelas.fechar_janela.call_deferred(janela as JanelaBase, true)
