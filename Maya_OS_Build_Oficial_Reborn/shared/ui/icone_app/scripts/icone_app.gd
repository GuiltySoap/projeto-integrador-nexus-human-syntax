class_name IconeApp
extends Control
## Ícone de um aplicativo do catálogo. Usa res://shared/assets/icons/apps/<id>.svg|png quando existir; senão mostra
## um bloco colorido (cor do catálogo) com o emoji do app. A estrutura (imagem + bloco + glifo) está em
## icone_app.tscn; aqui só entram os dados que variam de app para app.
## Uso: instancie a cena e chame configurar(info_do_app, lado). Ex.: barra de tarefas, menu iniciar, janela.

const CAMINHO_ICONE := "res://shared/assets/icons/apps/%s.%s"
const EXTENSOES: Array[String] = ["svg", "png"]

@export var lado: int = 40:
	set(valor):
		lado = maxi(valor, 1)
		custom_minimum_size = Vector2(lado, lado)
		if is_node_ready():
			_atualizar()

var _app: Dictionary = {}

@onready var _imagem: TextureRect = %Imagem
@onready var _bloco: PanelContainer = %Bloco
@onready var _glifo: Label = %Glifo


func _ready() -> void:
	custom_minimum_size = Vector2(lado, lado)
	_atualizar()


## dados_app: um item do catálogo de apps (precisa de "id"; usa "cor" e "icone" no bloco de emoji).
func configurar(dados_app: Dictionary, novo_lado: int = 0) -> void:
	_app = dados_app
	if novo_lado > 0:
		lado = novo_lado
	if is_node_ready():
		_atualizar()


func _atualizar() -> void:
	var textura := _textura_do_app(str(_app.get("id", "")), str(_app.get("icone_arquivo", "")))
	_imagem.visible = textura != null
	_bloco.visible = textura == null
	if textura != null:
		_imagem.texture = textura
		return
	var cor_app := Color.html(str(_app.get("cor", "#8b5cf6")))
	_bloco.add_theme_stylebox_override("panel", TemaNexus.caixa(
		Color(cor_app.r, cor_app.g, cor_app.b, 0.28), Color(cor_app.r, cor_app.g, cor_app.b, 0.8), int(lado * 0.22), 1, 0, 0))
	_glifo.text = str(_app.get("icone", "?"))
	_glifo.add_theme_font_size_override("font_size", int(lado * 0.52))


## `arquivo`: ícone próprio declarado no catálogo (a Maya usa a logo oficial); sem ele (ou se o arquivo faltar) vale o SVG padrão do app e, por fim, o bloco com o glifo.
func _textura_do_app(id_app: String, arquivo: String = "") -> Texture2D:
	if arquivo != "" and ResourceLoader.exists(arquivo):
		var propria := load(arquivo) as Texture2D
		if propria != null:
			return propria
	if id_app == "":
		return null
	for ext in EXTENSOES:
		var caminho: String = CAMINHO_ICONE % [id_app, ext]
		if ResourceLoader.exists(caminho):
			return load(caminho) as Texture2D
	return null
