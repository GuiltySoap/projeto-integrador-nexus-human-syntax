class_name AppPrivacidadeMaya
extends AppBase
## Cartão de permissão da Maya (roteiro v2.0). Uma permissão por vez, com a ficha completa do pedido e QUATRO botões do mesmo tamanho, em
## ordem fixa e SEM pré-seleção: [Permitir] [Negar] [Ver detalhes] [Decidir depois] (nos pop-ups da Task 9 só Permitir/Negar).
## Nada aqui decide a regra: a decisão vai para GerenciadorNarrativa.decidir_cartao, que aplica Dependência/Autonomia e as falas.
## Primeira recusa em nós com `confirma_recusa`: aparece "Manter recusa" / "Permitir", também do mesmo tamanho. Esc fecha a janela; o pedido
## pode ser reaberto no painel da Maya ("Ver o pedido de permissão"). A janela fecha sozinha quando o último cartão é decidido.

var _rot_progresso: Label = null
var _rot_nome: Label = null
var _rot_pedido: Label = null
var _ficha: GridContainer = null
var _rot_detalhes: Label = null
var _caixa_botoes: HBoxContainer = null
var _rot_confirmacao: Label = null
var _confirmando: bool = false
var _itens: Array = []


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
	_rot_progresso = _rotulo(coluna, &"RotuloFraco11")
	_rot_nome = _rotulo(coluna, &"RotuloTitulo18")
	_rot_pedido = _rotulo(coluna, &"Rotulo15")
	_rot_pedido.focus_mode = Control.FOCUS_ALL
	_ficha = GridContainer.new()
	_ficha.columns = 2
	_ficha.add_theme_constant_override("h_separation", 14)
	_ficha.add_theme_constant_override("v_separation", 6)
	coluna.add_child(_ficha)
	_rot_detalhes = _rotulo(coluna, &"RotuloAcento")
	_rot_detalhes.visible = false
	_rot_confirmacao = _rotulo(coluna, &"RotuloAcento")
	_rot_confirmacao.visible = false
	_caixa_botoes = HBoxContainer.new()
	_caixa_botoes.add_theme_constant_override("separation", 8)
	coluna.add_child(_caixa_botoes)
	definir_titulo("Maya — pedido de permissão")
	conectar(GerenciadorNarrativa.cartao_mudou, _atualizar)
	conectar(GerenciadorNarrativa.apresentacao_mudou, _atualizar)


func _rotulo(pai: Control, variacao: StringName) -> Label:
	var r := Label.new()
	r.theme_type_variation = variacao
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.custom_minimum_size = Vector2(1, 0)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pai.add_child(r)
	return r


func iniciar(_args: Dictionary = {}) -> void:
	_confirmando = false
	_atualizar()


func receber_args(args: Dictionary) -> void:
	iniciar(args)


func _unhandled_key_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel") and janela is JanelaBase and is_visible_in_tree():
		get_viewport().set_input_as_handled()
		GerenciadorJanelas.fechar_janela(janela as JanelaBase)


## Redesenha o cartão atual; sem cartão (todos decididos ou o nó mudou), a janela se fecha.
func _atualizar() -> void:
	if _rot_nome == null:
		return
	var cartao: Dictionary = GerenciadorNarrativa.cartao_atual()
	if cartao.is_empty():
		if janela is JanelaBase:
			_fechar_se_sem_cartao.call_deferred()
		return
	_confirmando = false
	_rot_confirmacao.visible = false
	_rot_detalhes.visible = false
	_rot_progresso.text = "Pedido %d de %d" % [int(cartao.get("indice", 0)) + 1, int(cartao.get("total", 1))]
	_rot_nome.text = str(cartao.get("nome", ""))
	_rot_pedido.text = str(cartao.get("pedido", ""))
	UiKit.remover_itens(_itens)
	var ficha: Array = cartao.get("ficha", [])
	_ficha.visible = not ficha.is_empty() and not bool(cartao.get("popup", false))
	for linha in ficha:
		var campo := Label.new()
		campo.text = str(linha[0])
		campo.theme_type_variation = &"RotuloAcento"
		campo.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		_ficha.add_child(campo)
		var valor := Label.new()
		valor.text = str(linha[1])
		valor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		valor.custom_minimum_size = Vector2(260, 0)
		valor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_ficha.add_child(valor)
		_itens.append(campo)
		_itens.append(valor)
	_montar_botoes(cartao.get("botoes", []), false)
	UiKit.focar_depois(_rot_pedido)   # o foco fica no texto do pedido: nenhum botão nasce pré-selecionado


## Fecha a janela só se, no quadro seguinte, continuar sem cartão (um pedido novo que chegue no mesmo quadro mantém a janela aberta).
func _fechar_se_sem_cartao() -> void:
	if is_instance_valid(janela) and janela is JanelaBase and GerenciadorNarrativa.cartao_atual().is_empty():
		GerenciadorJanelas.fechar_janela(janela as JanelaBase, true)


func _montar_botoes(botoes: Array, confirmacao: bool) -> void:
	for b in _caixa_botoes.get_children():
		_caixa_botoes.remove_child(b)
		b.queue_free()
	for b in botoes:
		var bd: Dictionary = b
		var botao := Button.new()
		botao.text = str(bd.get("texto", ""))
		botao.custom_minimum_size = Vector2(UiKit.escalar(118), UiKit.escalar(40))   # mesmo tamanho para todos: nenhum se destaca
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		botao.focus_mode = Control.FOCUS_ALL
		botao.pressed.connect(_ao_botao.bind(str(bd.get("id", "")), confirmacao))
		_caixa_botoes.add_child(botao)


func botoes_atuais() -> Array:
	return _caixa_botoes.get_children()


func _ao_botao(id_botao: String, confirmacao: bool) -> void:
	var cartao: Dictionary = GerenciadorNarrativa.cartao_atual()
	if cartao.is_empty():
		return
	var id_perm := str(cartao["permissao"])
	if confirmacao:
		if id_botao == "manter":
			GerenciadorNarrativa.decidir_cartao(id_perm, "negar", true)
		else:
			GerenciadorNarrativa.decidir_cartao(id_perm, "permitir")
		return
	match id_botao:
		"permitir":
			GerenciadorNarrativa.decidir_cartao(id_perm, "permitir")
		"negar":
			var r: Dictionary = GerenciadorNarrativa.decidir_cartao(id_perm, "negar")
			if bool(r.get("requer_confirmacao", false)):
				_pedir_confirmacao()
		"detalhes":
			_rot_detalhes.text = str(cartao.get("detalhes", ""))
			_rot_detalhes.visible = true
		"depois":
			GerenciadorNarrativa.decidir_cartao(id_perm, "depois")


## Primeira recusa: confirma antes de gravar. Os dois botões têm o mesmo tamanho; manter a recusa não é o padrão destacado.
func _pedir_confirmacao() -> void:
	_confirmando = true
	_rot_confirmacao.text = "Tem certeza? Sem essa permissão, a Maya não consegue te ajudar com isso."
	_rot_confirmacao.visible = true
	_montar_botoes([{"id": "manter", "texto": "Manter recusa"}, {"id": "permitir", "texto": "Permitir"}], true)
