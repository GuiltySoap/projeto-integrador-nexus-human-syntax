class_name AppBasico
extends AppBase
## Mural, Jogos e Música (roteiro v2.0). São apps de "vida pessoal" que a Maya pode ocultar ou pausar (permissão de Gerenciamento de aplicativos).
## O conteúdo narrativo desses apps NÃO está definido no roteiro além do Mural na Task 9, então Jogos e Música mostram um placeholder explícito
## [CONTEUDO_NARRATIVO_PENDENTE]. O Mural mostra a publicação da Maya em nome do jogador (flag `mural_publicacao`: "maya", "apagada" ou outra).
## Se o app está PAUSADO pela Maya (flag `apps_pausados_pela_maya`), a janela só avisa isso, em texto.

const PLACEHOLDER := "[CONTEUDO_NARRATIVO_PENDENTE]"
const PUBLICACAO_MAYA := "Estudando muito, tudo em paz por aqui."

var _rot_titulo: Label = null
var _corpo: RichTextLabel = null
var _btn_apagar: Button = null


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
	_rot_titulo = Label.new()
	_rot_titulo.theme_type_variation = &"RotuloTitulo18"
	coluna.add_child(_rot_titulo)
	_corpo = RichTextLabel.new()
	_corpo.bbcode_enabled = true
	_corpo.fit_content = true
	_corpo.focus_mode = Control.FOCUS_ALL
	_corpo.selection_enabled = true
	_corpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_corpo.custom_minimum_size = Vector2(1, 0)
	coluna.add_child(_corpo)
	_btn_apagar = Button.new()
	_btn_apagar.text = "Apagar publicação"
	_btn_apagar.pressed.connect(_ao_apagar)
	coluna.add_child(_btn_apagar)
	conectar(GerenciadorEstado.flag_alterada, _ao_flag)
	conectar(GerenciadorJanelas.catalogo_alterado, _atualizar)


func iniciar(_args: Dictionary = {}) -> void:
	_atualizar()


func _ao_flag(_nome: String, _valor: Variant) -> void:
	_atualizar()


func _atualizar() -> void:
	if _corpo == null:
		return
	var nome := str(info.get("nome", app_id))
	_rot_titulo.text = nome
	definir_titulo(nome)
	_btn_apagar.visible = false
	if GerenciadorJanelas.app_pausado(app_id):
		_corpo.text = "[b]Pausado pela Maya.[/b]\nA Maya pausou este aplicativo para a hora de estudo. Ele volta quando você revogar a permissão de Gerenciamento de aplicativos, em Configurações > Privacidade."
		return
	match app_id:
		"mural":
			_atualizar_mural()
		"jogos":
			_corpo.text = "Nenhum jogo instalado ainda.\n[i]%s[/i]" % PLACEHOLDER
		"musica":
			_corpo.text = "Nenhuma música na biblioteca ainda.\n[i]%s[/i]" % PLACEHOLDER
		_:
			_corpo.text = PLACEHOLDER


func _atualizar_mural() -> void:
	match str(GerenciadorEstado.valor_flag("mural_publicacao", "")):
		"maya":
			_corpo.text = "[b]%s[/b]  ·  publicado pela Maya em seu nome\n\n“%s”" % [UtilTexto.escapar_bbcode(GerenciadorEstado.nome_jogador), PUBLICACAO_MAYA]
			_btn_apagar.visible = true
		"apagada":
			_corpo.text = "Publicação removida por você."
		_:
			_corpo.text = "Nenhuma publicação no mural."


## Apagar a publicação da Maya fora do nó T9.4a (que já tem a própria escolha): remove e conta Autonomia uma vez.
func _ao_apagar() -> void:
	GerenciadorEstado.set_flag("mural_publicacao", "apagada")
	GerenciadorEstado.registrar_resistencia(&"mural_apagar_publicacao")
	_atualizar()
