class_name IndicadorCarregamento
extends Control
## Camada de "Carregando…" para as trocas de cena. Cobre a tela inteira, BLOQUEIA o mouse e leva o foco do teclado/controle
## para si (nada por trás recebe clique, Enter ou Espaço) e mostra o progresso do carregamento em segundo plano da camada `Cenas`.
## Fica oculta até `mostrar()`. Se a troca falhar, quem chamou usa `ocultar()` e o foco volta para onde estava.
## A estrutura (cortina, painel, texto e barra) vive em indicador_carregamento.tscn. Sem animação própria: só o número muda.

var _aberto: bool = false
var _foco_anterior: Control = null

@onready var _rotulo: Label = %Rotulo
@onready var _barra: ProgressBar = %Barra


func _ready() -> void:
	set_process(false)
	visible = false
	UiKit.refs_ok(self, {"Rotulo": _rotulo, "Barra": _barra})


func esta_aberto() -> bool:
	return _aberto


## Mostra o indicador com `texto`. Pode ser chamado de novo para só trocar o texto.
func mostrar(texto: String = "Carregando…") -> void:
	if _rotulo == null or _barra == null:
		return
	_rotulo.text = texto
	if _aberto:
		return
	_barra.value = 0.0
	_foco_anterior = get_viewport().gui_get_focus_owner()
	_aberto = true
	visible = true
	set_process(true)
	grab_focus()


## Esconde o indicador e devolve o foco a quem o tinha antes (se ainda estiver na tela).
func ocultar() -> void:
	if not _aberto:
		return
	_aberto = false
	visible = false
	set_process(false)
	release_focus()
	if _foco_anterior != null and is_instance_valid(_foco_anterior) and _foco_anterior.is_visible_in_tree() and _foco_anterior.focus_mode != Control.FOCUS_NONE:
		_foco_anterior.grab_focus()
	_foco_anterior = null


func _process(_delta: float) -> void:
	_barra.value = maxf(_barra.value, Cenas.progresso())


## Enquanto aberto, o indicador consome toda a entrada que chegaria até ele (incluindo Esc): ninguém age durante a troca.
func _gui_input(_evento: InputEvent) -> void:
	accept_event()
