class_name PainelConfirmacao
extends Control
## Painel de confirmação reutilizável (Menu Principal, Pausa e Fim de Jogo): título + texto + [Cancelar] [Confirmar].
## Fica oculto até `perguntar()`. A resposta vem pelos sinais `confirmado` e `cancelado`.
##   - O foco inicial vai para "Cancelar": um Enter/Espaço acidental ao abrir nunca confirma algo destrutivo.
##   - Esc cancela e tem PRIORIDADE sobre qualquer outro tratamento de Esc da tela (usa `_input` e consome a tecla).
##   - Clicar fora do painel (na cortina) não decide nada, e Tab/setas ficam presos nos dois botões.
## O texto pode trazer o título e o corpo separados por uma linha em branco ("Título?\n\nCorpo.").
## A estrutura (cortina, painel, textos e botões) vive em painel_confirmacao.tscn; nada é criado em código.

signal confirmado
signal cancelado

var _aberto: bool = false
var _foco_anterior: Control = null

@onready var _rotulo_titulo: Label = %RotuloTitulo
@onready var _rotulo_texto: Label = %RotuloTexto
@onready var _botao_cancelar: Button = %BotaoCancelar
@onready var _botao_confirmar: Button = %BotaoConfirmar


func _ready() -> void:
	visible = false
	if not UiKit.refs_ok(self, {"RotuloTitulo": _rotulo_titulo, "RotuloTexto": _rotulo_texto, "BotaoCancelar": _botao_cancelar, "BotaoConfirmar": _botao_confirmar}):
		return
	UiKit.ligar_foco_circular([_botao_cancelar, _botao_confirmar])
	_botao_cancelar.focus_neighbor_left = _botao_cancelar.get_path_to(_botao_confirmar)
	_botao_cancelar.focus_neighbor_right = _botao_cancelar.get_path_to(_botao_confirmar)
	_botao_confirmar.focus_neighbor_left = _botao_confirmar.get_path_to(_botao_cancelar)
	_botao_confirmar.focus_neighbor_right = _botao_confirmar.get_path_to(_botao_cancelar)


func esta_aberto() -> bool:
	return _aberto


## Abre a pergunta. `perigo` desenha o botão de confirmar como ação destrutiva (e a pergunta continua com o foco em "Cancelar").
func perguntar(texto: String, rotulo_confirmar: String = "Confirmar", rotulo_cancelar: String = "Cancelar", perigo: bool = false) -> void:
	if _botao_confirmar == null:
		return
	var partes: PackedStringArray = texto.split("\n\n", true, 1)
	_rotulo_titulo.text = partes[0]
	_rotulo_texto.text = partes[1] if partes.size() > 1 else ""
	_rotulo_texto.visible = partes.size() > 1
	_botao_confirmar.text = rotulo_confirmar
	_botao_cancelar.text = rotulo_cancelar
	_botao_confirmar.theme_type_variation = &"BotaoPerigo" if perigo else &"BotaoPrimario"
	if not _aberto:
		_foco_anterior = get_viewport().gui_get_focus_owner()
	_aberto = true
	visible = true
	_botao_cancelar.call_deferred("grab_focus")


## Fecha sem emitir resposta (usado quando a tela que perguntou some ou muda de estado).
func fechar() -> void:
	if not _aberto:
		return
	_aberto = false
	visible = false
	if _foco_anterior != null and is_instance_valid(_foco_anterior) and _foco_anterior.is_visible_in_tree() and _foco_anterior.focus_mode != Control.FOCUS_NONE:
		_foco_anterior.grab_focus()
	_foco_anterior = null


func _input(evento: InputEvent) -> void:
	if _aberto and evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_ao_cancelar()


func _ao_cancelar() -> void:
	if not _aberto:
		return
	fechar()
	cancelado.emit()


func _ao_confirmar() -> void:
	if not _aberto:
		return
	fechar()
	confirmado.emit()
