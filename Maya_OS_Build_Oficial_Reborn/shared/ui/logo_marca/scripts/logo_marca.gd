class_name LogoMarca
extends HBoxContainer
## Logo da marca (Maya ou HumaxOS) como componente de cena: escolhe o arquivo pelo id em `Marca`, mantém a PROPORÇÃO do arquivo em qualquer
## altura, cai para o fallback quando o arquivo falta e muda de aparência em alto contraste.
##   - Sem imagem (arquivo ausente, não importado ou inválido): com `ocultar_sem_imagem` (padrão) o componente SOME e a tela fica com o
##     nome da marca em texto, que toda tela que usa este componente já tem; com `ocultar_sem_imagem = false` mostra o nome da marca em texto.
##   - Escala: a altura é `altura` (px da resolução de referência, 1920x1080); a largura sai da proporção do arquivo. O resto é o stretch
##     do projeto (canvas_items), então o logo escala junto com a tela, sem distorcer e sem sair do enquadramento do pai.
##   - Alto contraste: a moldura vira um retângulo preto sólido com borda branca. A arte com brilho neon continua legível e nunca depende do que
##     estiver atrás (o logo de fundo recortado fica sobre o preto; o logo com fundo próprio ganha o contorno que o separa do resto).
##   - A dica de ferramenta é o nome da marca (texto alternativo). O componente não recebe mouse nem foco: é só identidade visual.
## Uso (cena): instanciar logo_marca.tscn e definir `marca`, `altura` e, se quiser, `mostrar_nome`. Uso (código): `LogoMarca.criar(...)`.

const CENA := "res://shared/ui/logo_marca/scenes/logo_marca.tscn"
const LARGURA_BORDA := 3
const MARGEM_MOLDURA := 6

## Id de `Marca` (Marca.MAYA_MARCA, Marca.MAYA_COMPLETA, Marca.HUMAXOS).
@export var marca: String = Marca.MAYA_MARCA:
	set(valor):
		marca = valor
		_atualizar()
## Altura do logo, em pixels da resolução de referência.
@export var altura: float = 96.0:
	set(valor):
		altura = maxf(valor, 8.0)
		_atualizar()
## Mostra o nome da marca em texto ao lado da imagem (além da dica de ferramenta).
@export var mostrar_nome: bool = false:
	set(valor):
		mostrar_nome = valor
		_atualizar()
## Sem arquivo de imagem: some (true) ou mostra o nome em texto no lugar (false).
@export var ocultar_sem_imagem: bool = true:
	set(valor):
		ocultar_sem_imagem = valor
		_atualizar()

var _imagem_carregada: bool = false
var _alto_contraste: bool = false

@onready var _moldura: PanelContainer = %Moldura
@onready var _imagem: TextureRect = %Imagem
@onready var _nome: Label = %Nome


static func criar(id_marca: String, altura_px: float, com_nome: bool = false) -> LogoMarca:
	var logo := (load(CENA) as PackedScene).instantiate() as LogoMarca
	logo.marca = id_marca
	logo.altura = altura_px
	logo.mostrar_nome = com_nome
	return logo


func _ready() -> void:
	if not UiKit.refs_ok(self, {"Moldura": _moldura, "Imagem": _imagem, "Nome": _nome}):
		return
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GerenciadorConfiguracoes.configuracao_alterada.connect(_ao_configuracao_alterada)
	_atualizar()


func _exit_tree() -> void:
	if GerenciadorConfiguracoes.configuracao_alterada.is_connected(_ao_configuracao_alterada):
		GerenciadorConfiguracoes.configuracao_alterada.disconnect(_ao_configuracao_alterada)


## A imagem do logo está sendo mostrada agora? (Falso quando faltou o arquivo.)
func tem_imagem() -> bool:
	return _imagem_carregada


## O texto de reserva está visível (sem imagem e com `ocultar_sem_imagem` falso, ou com `mostrar_nome`)?
func nome_visivel() -> bool:
	return is_instance_valid(_nome) and _nome.visible


## Tamanho que o logo ocupa na tela (a imagem, mantida a proporção do arquivo).
func tamanho_da_imagem() -> Vector2:
	return _imagem.custom_minimum_size if is_instance_valid(_imagem) else Vector2.ZERO


func alto_contraste_ativo() -> bool:
	return _alto_contraste


func _ao_configuracao_alterada(chave: String, _valor: Variant) -> void:
	if chave == "alto_contraste":
		_atualizar()


func _atualizar() -> void:
	if not is_node_ready() or not is_instance_valid(_imagem):
		return
	_alto_contraste = bool(GerenciadorConfiguracoes.obter("alto_contraste"))
	var textura: Texture2D = Marca.carregar(marca)
	_imagem_carregada = textura != null
	var nome_da_marca := Marca.nome(marca)
	tooltip_text = nome_da_marca
	_imagem.texture = textura
	_moldura.visible = _imagem_carregada
	if _imagem_carregada:
		var proporcao := float(textura.get_width()) / maxf(float(textura.get_height()), 1.0)
		_imagem.custom_minimum_size = Marca.tamanho_para_altura(altura, proporcao)
	else:
		_imagem.custom_minimum_size = Vector2.ZERO
	var texto_sozinho: bool = (not _imagem_carregada) and not ocultar_sem_imagem
	_nome.text = nome_da_marca
	_nome.visible = (mostrar_nome and nome_da_marca != "") or (texto_sozinho and nome_da_marca != "")
	visible = _imagem_carregada or _nome.visible
	_aplicar_moldura()


## Moldura da imagem: transparente no uso normal; sólida (preto + borda branca) em alto contraste.
func _aplicar_moldura() -> void:
	var caixa := StyleBoxFlat.new()
	if _alto_contraste:
		caixa.bg_color = Color(0, 0, 0, 1)
		caixa.set_border_width_all(LARGURA_BORDA)
		caixa.border_color = Color(1, 1, 1, 1)
		caixa.set_content_margin_all(MARGEM_MOLDURA)
	else:
		caixa.bg_color = Color(0, 0, 0, 0)
		caixa.set_content_margin_all(0)
	_moldura.add_theme_stylebox_override("panel", caixa)
