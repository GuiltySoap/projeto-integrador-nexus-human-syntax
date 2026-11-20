class_name DialogoArquivo
extends Control
## Seletor de arquivos do sistema simulado (abrir/salvar). Trabalha somente com o VFS.
## Resultado pelo sinal `resolvido`: caminho escolhido ou "" quando cancelado.
##
## A estrutura (cortina, painel, título, barra da pasta, lista, campo de nome, erro e botões) vive em dialogo_arquivo.tscn e os
## sinais dos controles estão ligados na própria cena. O único conteúdo dinâmico são as linhas da lista (arquivos da pasta atual).
## Uso: `DialogoArquivo.criar(modo, pasta_inicial, nome_sugerido, extensoes)` e adicionar à árvore.

signal resolvido(caminho: String)

enum Modo { ABRIR, SALVAR }

const CENA := "res://shared/ui/dialogo_arquivo/scenes/dialogo_arquivo.tscn"

var _modo: Modo = Modo.ABRIR
var _pasta: String = SistemaArquivosVirtual.PASTA_USUARIO
var _extensoes: PackedStringArray = PackedStringArray()
var _nome_sugerido: String = ""
var _itens: Array = []
var _encerrado: bool = false
var _pronto: bool = false

@onready var _rotulo_titulo: Label = %RotuloTitulo
@onready var _rotulo_pasta: Label = %RotuloPasta
@onready var _lista: ItemList = %Lista
@onready var _campo_nome: LineEdit = %Campo
@onready var _erro: Label = %RotuloErro
@onready var _botao_confirmar: Button = %BotaoConfirmar


## Instancia a cena já configurada.
static func criar(modo: Modo, pasta_inicial: String, nome_sugerido: String = "", extensoes: PackedStringArray = PackedStringArray()) -> DialogoArquivo:
	var d := (load(CENA) as PackedScene).instantiate() as DialogoArquivo
	d.montar(modo, pasta_inicial, nome_sugerido, extensoes)
	return d


## Configura o seletor (pode ser chamado antes ou depois de adicionar à árvore).
func montar(modo: Modo, pasta_inicial: String, nome_sugerido: String = "", extensoes: PackedStringArray = PackedStringArray()) -> void:
	_modo = modo
	_extensoes = extensoes
	_nome_sugerido = nome_sugerido
	var inicial := SistemaArquivosVirtual.resolver(pasta_inicial)
	if inicial != "" and SistemaArquivosVirtual.eh_pasta(inicial):
		_pasta = inicial
	_aplicar()


func _ready() -> void:
	_pronto = UiKit.refs_ok(self, {"RotuloTitulo": _rotulo_titulo, "RotuloPasta": _rotulo_pasta, "Lista": _lista, "Campo": _campo_nome, "RotuloErro": _erro, "BotaoConfirmar": _botao_confirmar})
	_aplicar()


func _aplicar() -> void:
	if not is_node_ready() or not _pronto:
		return
	_rotulo_titulo.text = "Abrir arquivo" if _modo == Modo.ABRIR else "Salvar como"
	_campo_nome.visible = _modo == Modo.SALVAR
	_campo_nome.text = _nome_sugerido
	_botao_confirmar.text = "Abrir" if _modo == Modo.ABRIR else "Salvar"
	_erro.visible = false
	_atualizar_lista()


func _input(evento: InputEvent) -> void:
	if not _encerrado and evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_ao_cancelar()


func _atualizar_lista() -> void:
	_lista.clear()
	_itens.clear()
	_rotulo_pasta.text = _pasta
	for no in SistemaArquivosVirtual.listar(_pasta, false):
		var nome := SistemaArquivosVirtual.nome_do_caminho(str(no.get("caminho", "")))
		var eh_pasta := str(no.get("tipo", "")) == "pasta"
		if not eh_pasta and not _extensao_permitida(nome):
			continue
		if not eh_pasta and (SistemaArquivosVirtual.esta_criptografado(no) or SistemaArquivosVirtual.bloqueado_narrativamente(no) or SistemaArquivosVirtual.esta_corrompido(no)):
			continue   # só arquivos que dá para abrir/gravar de verdade aparecem no seletor
		_lista.add_item(("📁 " if eh_pasta else "📄 ") + nome)
		_itens.append(no)


func _extensao_permitida(nome: String) -> bool:
	if _extensoes.is_empty():
		return true
	return _extensoes.has(UtilTexto.extensao(nome))


func _ao_item_ativado(indice: int) -> void:
	if indice < 0 or indice >= _itens.size():
		return
	var no: Dictionary = _itens[indice]
	var caminho := str(no.get("caminho", ""))
	if str(no.get("tipo", "")) == "pasta":
		if SistemaArquivosVirtual.bloqueada(no):
			_mostrar_erro("Esta pasta está bloqueada.")
			return
		_pasta = caminho
		_erro.visible = false
		_atualizar_lista()
	elif _modo == Modo.ABRIR:
		_finalizar(caminho)
	else:
		_campo_nome.text = SistemaArquivosVirtual.nome_do_caminho(caminho)


func _ao_item_selecionado(indice: int) -> void:
	if indice < 0 or indice >= _itens.size():
		return
	var no: Dictionary = _itens[indice]
	if _modo == Modo.SALVAR and str(no.get("tipo", "")) == "arquivo":
		_campo_nome.text = SistemaArquivosVirtual.nome_do_caminho(str(no.get("caminho", "")))


func _ao_subir() -> void:
	_pasta = SistemaArquivosVirtual.caminho_pai(_pasta)
	_erro.visible = false
	_atualizar_lista()


func _ao_nome_enviado(_t: String) -> void:
	_ao_confirmar()


func _ao_confirmar() -> void:
	if _modo == Modo.ABRIR:
		var sel := _lista.get_selected_items()
		if sel.is_empty():
			_mostrar_erro("Selecione um arquivo.")
			return
		_ao_item_ativado(sel[0])
		return
	var nome := _campo_nome.text.strip_edges()
	if not SistemaArquivosVirtual.validar_nome(nome):
		_mostrar_erro("Nome inválido. Evite / \\ : * ? \" < > |")
		return
	if SistemaArquivosVirtual.somente_leitura(_pasta):
		_mostrar_erro("Esta pasta é somente leitura. Escolha outra (ex.: Documentos).")
		return
	_finalizar(SistemaArquivosVirtual.juntar(_pasta, nome))


func _ao_cancelar() -> void:
	_finalizar("")


func _mostrar_erro(texto: String) -> void:
	_erro.text = texto
	_erro.visible = true


func _finalizar(caminho: String) -> void:
	if _encerrado:
		return
	_encerrado = true
	resolvido.emit(caminho)
	queue_free()
