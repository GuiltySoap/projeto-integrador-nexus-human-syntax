class_name DialogoNexus
extends Control
## Diálogo modal do sistema: alerta, confirmação, entrada de texto ou escolha entre 2+ opções.
## Sempre dá para cancelar com Esc ou com o botão de cancelar (nenhum diálogo prende o jogador).
## Clicar na cortina (fora do painel) não decide nada: só os botões, Enter/Espaço no botão focado ou Esc resolvem o diálogo.
## Resultado pelo sinal `resolvido`: true (alerta/confirmar), false/null (cancelado), String (texto) ou int (escolha; -1 = cancelado).
##
## A estrutura (cortina, painel, título, texto, campo, mensagem de erro e botões) vive em dialogo_nexus.tscn; este script só
## preenche os textos, mostra/oculta o que cada modo usa e resolve o resultado. Os botões do modo "escolha" são o único conteúdo
## dinâmico (a quantidade de opções muda a cada chamada). Uso: `DialogoNexus.criar(...)` ou `criar_escolha(...)` e adicionar à árvore.

signal resolvido(resultado: Variant)

enum Modo { ALERTA, CONFIRMAR, TEXTO, ESCOLHA }

const CENA := "res://shared/ui/dialogo_nexus/scenes/dialogo_nexus.tscn"

var _modo: Modo = Modo.ALERTA
var _titulo: String = ""
var _texto: String = ""
var _rotulo_ok: String = "OK"
var _rotulo_cancelar: String = "Cancelar"
var _placeholder: String = ""
var _oculto: bool = false
var _perigo: bool = false
var _foco_seguro: bool = false
var _valor_inicial: String = ""
var _opcoes: PackedStringArray = PackedStringArray()
var _indice_padrao: int = 0
var _indice_perigo: int = -1
var _botoes_escolha: Array[Button] = []
var _foco: Control
var _encerrado: bool = false
var _pronto: bool = false

@onready var _rotulo_titulo: Label = %RotuloTitulo
@onready var _rotulo_corpo: Label = %RotuloCorpo
@onready var _campo: LineEdit = %Campo
@onready var _rotulo_erro: Label = %RotuloErro
@onready var _botoes: HBoxContainer = %Botoes
@onready var _botao_cancelar: Button = %BotaoCancelar
@onready var _botao_ok: Button = %BotaoOk


## Instancia a cena já configurada (alerta, confirmação ou entrada de texto).
static func criar(titulo: String, texto: String, modo: Modo = Modo.ALERTA, rotulo_ok: String = "OK", rotulo_cancelar: String = "Cancelar", placeholder: String = "", oculto: bool = false, perigo: bool = false, valor_inicial: String = "", foco_seguro: bool = false) -> DialogoNexus:
	var d := (load(CENA) as PackedScene).instantiate() as DialogoNexus
	d.montar(titulo, texto, modo, rotulo_ok, rotulo_cancelar, placeholder, oculto, perigo, valor_inicial, foco_seguro)
	return d


## Instancia a cena já configurada com várias opções (ex.: Salvar / Não salvar / Continuar editando).
static func criar_escolha(titulo: String, texto: String, opcoes: PackedStringArray, indice_padrao: int = 0, indice_perigo: int = -1) -> DialogoNexus:
	var d := (load(CENA) as PackedScene).instantiate() as DialogoNexus
	d.montar_escolha(titulo, texto, opcoes, indice_padrao, indice_perigo)
	return d


## Configura o diálogo (pode ser chamado antes ou depois de adicionar à árvore).
## `foco_seguro` (só no modo confirmar): o foco inicial vai para o botão de cancelar, para que um Enter/Espaço acidental
## logo ao abrir nunca confirme uma decisão irreversível. Quem quer confirmar precisa clicar ou navegar até o botão de confirmar.
func montar(titulo: String, texto: String, modo: Modo = Modo.ALERTA, rotulo_ok: String = "OK", rotulo_cancelar: String = "Cancelar", placeholder: String = "", oculto: bool = false, perigo: bool = false, valor_inicial: String = "", foco_seguro: bool = false) -> void:
	_modo = modo
	_titulo = titulo
	_texto = texto
	_rotulo_ok = rotulo_ok
	_rotulo_cancelar = rotulo_cancelar
	_placeholder = placeholder
	_oculto = oculto
	_perigo = perigo
	_foco_seguro = foco_seguro
	_valor_inicial = valor_inicial
	_aplicar()


## Diálogo com várias opções. Esc = cancelar (-1). `indice_padrao` recebe o foco; `indice_perigo` (-1 = nenhum) é desenhado como ação destrutiva.
func montar_escolha(titulo: String, texto: String, opcoes: PackedStringArray, indice_padrao: int = 0, indice_perigo: int = -1) -> void:
	_modo = Modo.ESCOLHA
	_titulo = titulo
	_texto = texto
	_opcoes = opcoes
	_indice_padrao = indice_padrao
	_indice_perigo = indice_perigo
	_aplicar()


func _ready() -> void:
	_pronto = UiKit.refs_ok(self, {"RotuloTitulo": _rotulo_titulo, "RotuloCorpo": _rotulo_corpo, "Campo": _campo, "RotuloErro": _rotulo_erro, "Botoes": _botoes, "BotaoCancelar": _botao_cancelar, "BotaoOk": _botao_ok})
	_aplicar()
	if _foco != null:
		_foco.call_deferred("grab_focus")
	if _modo == Modo.TEXTO and _campo.text != "":
		_campo.call_deferred("select_all")


## Preenche a cena conforme o modo. Só roda com a cena pronta (montar() pode vir antes do _ready).
func _aplicar() -> void:
	if not is_node_ready() or not _pronto:
		return
	_rotulo_titulo.text = _titulo
	_rotulo_corpo.visible = _texto != ""
	_rotulo_corpo.text = GerenciadorEstado.formatar(_texto) if _texto != "" else ""
	_campo.visible = _modo == Modo.TEXTO
	_rotulo_erro.visible = false
	_botao_ok.text = _rotulo_ok
	_botao_ok.theme_type_variation = &"BotaoPerigo" if _perigo else &"BotaoPrimario"
	_botao_cancelar.text = _rotulo_cancelar
	_botao_cancelar.visible = _modo == Modo.CONFIRMAR or _modo == Modo.TEXTO
	_botao_ok.visible = _modo != Modo.ESCOLHA
	_foco = _botao_cancelar if _foco_seguro and _modo == Modo.CONFIRMAR else _botao_ok
	if _modo == Modo.TEXTO:
		_campo.placeholder_text = _placeholder
		_campo.secret = _oculto
		_campo.text = _valor_inicial
		_foco = _campo
	elif _modo == Modo.ESCOLHA:
		_montar_botoes_escolha()


## Único conteúdo dinâmico: um botão por opção, dentro da fileira de botões da cena.
func _montar_botoes_escolha() -> void:
	for antigo in _botoes_escolha:
		if is_instance_valid(antigo):
			antigo.queue_free()
	_botoes_escolha.clear()
	_foco = null
	for i in _opcoes.size():
		var b := Button.new()
		b.text = _opcoes[i]
		if i == _indice_perigo:
			b.theme_type_variation = &"BotaoPerigo"
		elif i == _indice_padrao:
			b.theme_type_variation = &"BotaoPrimario"
		b.pressed.connect(_ao_escolher.bind(i))
		_botoes.add_child(b)
		_botoes_escolha.append(b)
		if i == _indice_padrao:
			_foco = b
	if _foco == null and not _botoes_escolha.is_empty():
		_foco = _botoes_escolha[0]


func _input(evento: InputEvent) -> void:
	if _encerrado:
		return
	if evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_ao_cancelar()


## Permite ao chamador mostrar uma mensagem de erro sem fechar o diálogo (ex.: chave incorreta).
func mostrar_erro(mensagem: String) -> void:
	if not _pronto:
		return
	_rotulo_erro.text = mensagem
	_rotulo_erro.visible = true
	if _modo == Modo.TEXTO:
		_campo.select_all()
		_campo.grab_focus()


func _ao_texto_enviado(_texto_digitado: String) -> void:
	_ao_confirmar()


func _ao_confirmar() -> void:
	if _modo == Modo.TEXTO:
		_finalizar(_campo.text if _pronto else "")
	else:
		_finalizar(true)


func _ao_cancelar() -> void:
	if _modo == Modo.ALERTA:
		_finalizar(true)
	elif _modo == Modo.CONFIRMAR:
		_finalizar(false)
	elif _modo == Modo.ESCOLHA:
		_finalizar(-1)
	else:
		_finalizar(null)


func _ao_escolher(indice: int) -> void:
	_finalizar(indice)


func _finalizar(valor: Variant) -> void:
	if _encerrado:
		return
	_encerrado = true
	resolvido.emit(valor)
	queue_free()
