class_name AppBase
extends Control
## Contrato de todo aplicativo que roda dentro de uma JanelaBase.
## O GerenciadorJanelas instancia a cena do app, adiciona à janela e então chama iniciar(args).
## Conexões feitas com conectar() são desfeitas sozinhas em _exit_tree (evita sinais pendurados).

signal titulo_alterado(novo_titulo: String)

var app_id: String = ""
var info: Dictionary = {}
var janela: Control = null  # JanelaBase; tipo genérico para não criar dependência circular de class_name
var _conexoes: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Chamado uma vez depois que o app já está na árvore. args vem de abrir_app(id, args).
func iniciar(_args: Dictionary = {}) -> void:
	pass


## Chamado quando o app já está aberto (instância única) e alguém pede para abri-lo de novo com outros args.
func receber_args(args: Dictionary) -> void:
	iniciar(args)


## Respostas síncronas: sem alterações pendentes, pode fechar.
func pode_fechar() -> bool:
	return true


## Os apps com alterações não salvas sobrescrevem este método e podem usar await (ex.: diálogo de confirmação).
func confirmar_fechar() -> bool:
	return pode_fechar()


func ao_focar() -> void:
	pass


func ao_fechar() -> void:
	pass


func definir_titulo(texto: String) -> void:
	titulo_alterado.emit(texto)


func conectar(sinal: Signal, alvo: Callable) -> void:
	if sinal.is_connected(alvo):
		return
	sinal.connect(alvo)
	_conexoes.append([sinal, alvo])


func _exit_tree() -> void:
	for par in _conexoes:
		var s: Signal = par[0]
		var c: Callable = par[1]
		if s.is_connected(c):
			s.disconnect(c)
	_conexoes.clear()
