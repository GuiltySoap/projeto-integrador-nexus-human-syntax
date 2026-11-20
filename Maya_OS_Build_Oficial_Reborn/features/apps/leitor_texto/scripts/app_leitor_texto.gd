class_name AppLeitorTexto
extends AppBase
## Leitor de texto SOMENTE LEITURA: logs do sistema, arquivos protegidos e arquivos já decifrados.
## O conteúdo é mostrado como texto puro (nenhum BBCode é interpretado). Para editar, o jogador abre o arquivo
## no Bloco de Notas (arquivos protegidos podem ser salvos como cópia com outro nome).
## Args: {"caminho": "/sistema/System_Logs/boot.log"}.
##
## A interface (caminho, botão, corpo, rodapé) vive em app_leitor_texto.tscn; este script só decide o que mostrar.

var _caminho: String = ""
var _pronta: bool = false

@onready var _rot_caminho: Label = %RotuloCaminho
@onready var _botao_editor: Button = %BotaoEditor
@onready var _corpo: RichTextLabel = %Corpo
@onready var _rot_estado: Label = %RotuloEstado


func _ready() -> void:
	super()
	_pronta = UiKit.refs_ok(self, {"RotuloCaminho": _rot_caminho, "BotaoEditor": _botao_editor, "Corpo": _corpo, "RotuloEstado": _rot_estado})
	if not _pronta:
		return
	conectar(SistemaArquivosVirtual.arquivo_alterado, _ao_arquivo_alterado)
	conectar(GerenciadorNarrativa.etapa_iniciada, _ao_dia_iniciado)


func iniciar(args: Dictionary = {}) -> void:
	if not _pronta:
		return
	var alvo := str(args.get("caminho", ""))
	if alvo != "":
		_abrir(alvo)
	elif _caminho == "":
		_mostrar_mensagem("Nenhum arquivo aberto. Abra um arquivo de texto pelo Explorador.")


func receber_args(args: Dictionary) -> void:
	iniciar(args)


func _abrir(caminho: String) -> void:
	var c := SistemaArquivosVirtual.resolver(caminho)
	if c == "" or not SistemaArquivosVirtual.acessivel(c, true) or not SistemaArquivosVirtual.eh_arquivo(c):
		_mostrar_mensagem("Arquivo não encontrado.")
		return
	var no: Dictionary = SistemaArquivosVirtual.obter_no(c)
	if SistemaArquivosVirtual.bloqueado_narrativamente(no):
		_mostrar_mensagem("Este arquivo ainda está bloqueado e não pode ser lido agora.")
		return
	if SistemaArquivosVirtual.esta_criptografado(no):
		_mostrar_mensagem("Este arquivo está criptografado. Abra-o pelo Explorador de Arquivos para informar a chave.")
		return
	_caminho = c
	_botao_editor.disabled = false
	AbridorArquivos.registrar_abertura(c)
	_mostrar_conteudo()


func _mostrar_conteudo() -> void:
	var texto := SistemaArquivosVirtual.ler_texto(_caminho)
	_rot_caminho.text = _caminho
	_corpo.text = texto
	_corpo.scroll_to_line(0)
	var linhas: int = 0 if texto == "" else texto.count("\n") + 1
	_rot_estado.text = "%d linha(s) · %d caractere(s)" % [linhas, texto.length()]
	if SistemaArquivosVirtual.esta_corrompido(SistemaArquivosVirtual.obter_no(_caminho)):
		_rot_estado.text += " · ⚠ arquivo corrompido: leitura parcial"
	definir_titulo("Leitor de Texto — " + SistemaArquivosVirtual.nome_do_caminho(_caminho))


func _mostrar_mensagem(texto: String) -> void:
	_caminho = ""
	_rot_caminho.text = ""
	_corpo.text = texto
	_rot_estado.text = ""
	_botao_editor.disabled = true


# Ligado ao sinal pressed do BotaoEditor na cena.
func _ao_abrir_no_editor() -> void:
	if _caminho != "":
		GerenciadorJanelas.abrir_app("text_editor", {"caminho": _caminho})


func _ao_arquivo_alterado(caminho: String) -> void:
	if _caminho != "" and caminho == _caminho:
		_mostrar_conteudo()


func _ao_dia_iniciado(_dia: int) -> void:
	if _caminho != "":
		_mostrar_conteudo()
