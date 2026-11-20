class_name WidgetRelogio
extends PanelContainer
## Relógio grande da área de trabalho: só a hora real do sistema (o jogo não tem dias nem calendário).
## Atualiza só quando o minuto muda (sinal do RelogioGlobal): sem Timer próprio.
## A estrutura (painel, margens e os três rótulos) está em widget_relogio.tscn.

var _cx := Conexoes.new()

@onready var _rot_hora: Label = %RotuloHora
@onready var _rot_data: Label = %RotuloData
@onready var _rot_dia: Label = %RotuloDia


func _ready() -> void:
	if not UiKit.refs_ok(self, {"RotuloHora": _rot_hora, "RotuloData": _rot_data, "RotuloDia": _rot_dia}):
		return
	_cx.ligar(RelogioGlobal.minuto_mudou, _ao_minuto)
	atualizar()


func _exit_tree() -> void:
	_cx.desligar_tudo()


func atualizar() -> void:
	_rot_hora.text = RelogioGlobal.hora_texto()
	_rot_data.text = ""   # sem calendário no jogo: o relógio mostra só a hora
	_rot_data.visible = false
	_rot_dia.text = "HUMAXOS"


func _ao_minuto(_hora: int, _minuto: int) -> void:
	atualizar()

