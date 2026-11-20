class_name BalaoChat
extends HBoxContainer
## Balão de mensagem do Mensageiro (balao_chat.tscn). A estrutura (bolha, etiqueta, texto, hora, botão) vive na cena; este script só
## escolhe o estilo conforme o tipo da mensagem, preenche os textos e mede a largura do texto.
## Etiquetas de tipo são sempre TEXTO (nunca só cor): "🔒 ocultada pela Maya", "✎ enviada pela Maya", "… pendente".
## Mensagem OCULTADA pela Maya (permissão de Gerenciamento do Mensageiro): mostra o texto-substituto e o botão "Mostrar mesmo assim"
## (emite `mostrar_solicitado`; o app chama GerenciadorNarrativa.mostrar_mensagem_oculta, que soma Autonomia uma vez por mensagem).
## Mensagem ENVIADA PELA MAYA no lugar do jogador: mostra "Ver o que você escreveu" (o texto digitado), sem custo.
## Uso: instanciar a cena, adicionar ao contêiner e chamar configurar(entrada, largura_max).

## O jogador abriu o texto original (digitado por ele) de uma mensagem assinada pela Maya.
signal original_visto(id_msg: String)
## O jogador pediu para ver uma mensagem ocultada pela Maya.
signal mostrar_solicitado(id_msg: String)

const TEXTO_OCULTA := "Mensagem ocultada pela Maya: pode te deixar ansioso."

@export var variacao_bolha_propria: StringName = &"BolhaPropria"
@export var variacao_bolha_sistema: StringName = &"BolhaSistema"
@export var variacao_bolha_padrao: StringName = &"BolhaPadrao"
@export var variacao_texto: StringName = &"Rotulo15"
@export var variacao_texto_sistema: StringName = &"RotuloFraco15"
@export var variacao_etiqueta: StringName = &"RotuloAcento11"

var _entrada: Dictionary = {}
var _largura_max: int = 480
var _mostrando_original: bool = false
var _pronto: bool = false

@onready var _bolha: PanelContainer = %Bolha
@onready var _rot_etiqueta: Label = %RotuloEtiqueta
@onready var _rot_texto: Label = %RotuloTexto
@onready var _rot_hora: Label = %RotuloHora
@onready var _btn_original: Button = %BotaoOriginal
@onready var _area_anexos: VBoxContainer = %AreaAnexos
@onready var _rot_status: Label = %RotuloStatus
@onready var _rot_indicador: Label = %RotuloIndicador
@onready var _btn_reenviar: Button = %BotaoReenviar


func _ready() -> void:
	_pronto = UiKit.refs_ok(self, {
		"Bolha": _bolha, "RotuloEtiqueta": _rot_etiqueta, "RotuloTexto": _rot_texto, "RotuloHora": _rot_hora, "BotaoOriginal": _btn_original,
		"AreaAnexos": _area_anexos, "RotuloStatus": _rot_status, "RotuloIndicador": _rot_indicador, "BotaoReenviar": _btn_reenviar,
	})
	if _pronto and not _entrada.is_empty():
		_aplicar()


## Id da mensagem que este balão mostra ("" se ainda não foi configurado).
func id_mensagem() -> String:
	return str(_entrada.get("id", ""))


## entrada: item do histórico ({autor, tipo, texto, hora, id, oculta, texto_original, texto_digitado, assinada_por, pendente}).
func configurar(entrada: Dictionary, largura_max: int = 480) -> void:
	_entrada = entrada
	_largura_max = largura_max
	_mostrando_original = false
	if is_node_ready() and _pronto:
		_aplicar()


func _aplicar() -> void:
	var autor := str(_entrada.get("autor", ""))
	var tipo := str(_entrada.get("tipo", "normal"))
	var proprio: bool = autor == "jogador"
	var sistema: bool = autor == "sistema" or tipo == "sistema"
	var oculta: bool = bool(_entrada.get("oculta", false))
	var pela_maya: bool = str(_entrada.get("assinada_por", "")) == "maya"
	if proprio:
		alignment = BoxContainer.ALIGNMENT_END
		_bolha.theme_type_variation = variacao_bolha_propria
	elif sistema:
		alignment = BoxContainer.ALIGNMENT_CENTER
		_bolha.theme_type_variation = variacao_bolha_sistema
	else:
		alignment = BoxContainer.ALIGNMENT_BEGIN
		_bolha.theme_type_variation = variacao_bolha_padrao

	var etiquetas: PackedStringArray = PackedStringArray()
	if oculta:
		etiquetas.append("🔒 ocultada pela Maya")
	if pela_maya:
		etiquetas.append("✎ enviada pela Maya")
	if bool(_entrada.get("pendente", false)) or str(_entrada.get("status", "")) == "enviando":
		etiquetas.append("… pendente")
	_rot_etiqueta.visible = not etiquetas.is_empty()
	_rot_etiqueta.text = " · ".join(etiquetas)
	_rot_etiqueta.theme_type_variation = variacao_etiqueta
	_rot_texto.theme_type_variation = variacao_texto_sistema if sistema else variacao_texto
	_mostrar_texto(TEXTO_OCULTA if oculta else str(_entrada.get("texto", "")), true)

	var hora := str(_entrada.get("hora", ""))
	_rot_hora.visible = hora != ""
	_rot_hora.text = hora
	if oculta:
		_btn_original.visible = true
		_btn_original.text = "Mostrar mesmo assim"
		_btn_original.tooltip_text = "Mostra a mensagem que a Maya ocultou."
	elif pela_maya and (_entrada.has("texto_digitado") or _entrada.has("texto_original")):
		_btn_original.visible = true
		_btn_original.text = "Ver o que você escreveu"
		_btn_original.tooltip_text = ""
	else:
		_btn_original.visible = false
	# Sem status de envio, indicador, anexos nem reenvio no roteiro v2.0.
	_rot_status.visible = false
	_rot_indicador.visible = false
	_btn_reenviar.visible = false
	_area_anexos.visible = false


## Define o texto do balão. medir: recalcula a largura mínima (depois o balão quebra linha).
func _mostrar_texto(texto: String, medir: bool) -> void:
	_rot_texto.text = texto
	if not medir:
		return
	var fonte: Font = _rot_texto.get_theme_font(&"font")
	var tamanho: int = _rot_texto.get_theme_font_size(&"font_size")
	var largura: float = fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x
	_rot_texto.custom_minimum_size = Vector2(clampf(largura + 8.0, 64.0, float(_largura_max)), 0)


# Ligado ao sinal pressed do BotaoReenviar na cena (sem uso no roteiro v2.0).
func _ao_reenviar() -> void:
	pass


# Ligado ao sinal pressed do BotaoOriginal na cena.
func _ao_alternar_original() -> void:
	if bool(_entrada.get("oculta", false)):
		mostrar_solicitado.emit(id_mensagem())
		return
	_mostrando_original = not _mostrando_original
	if _mostrando_original:
		var original := str(_entrada.get("texto_digitado", _entrada.get("texto_original", "")))
		_mostrar_texto("Você escreveu: " + original, false)
		_btn_original.text = "Ver o que foi enviado"
		original_visto.emit(id_mensagem())
	else:
		_mostrar_texto(str(_entrada.get("texto", "")), false)
		_btn_original.text = "Ver o que você escreveu"
