class_name AppBlocoDeNotas
extends AppBase
## Bloco de Notas: edita arquivos de texto do VFS (nada fora do jogo é lido ou gravado).
## Novo / Abrir / Salvar / Salvar como, atalhos Ctrl+N/O/S e aviso de alterações não salvas ao fechar
## (Salvar, Descartar ou Continuar editando — Esc nunca descarta sem querer).
## Args: {"caminho": "/home/usuario/documentos/nota.txt"}.
##
## A interface (barra de botões, aviso de somente leitura, editor, rodapé) vive em app_bloco_de_notas.tscn e os sinais dos
## botões e do editor estão ligados na própria cena; este script só cuida do documento, do salvamento e dos diálogos.

const EXTENSOES_TEXTO: Array = ["txt", "md", "log", "cfg", "ini", "csv", "json"]
const TITULO_APP := "Bloco de Notas"
const NOME_SEM_TITULO := "sem_titulo.txt"

var _caminho: String = ""
var _texto_salvo: String = ""
var _modificado: bool = false
var _somente_leitura: bool = false
var _ocupado: bool = false
var _pronta: bool = false

@onready var _editor: TextEdit = %Editor
@onready var _rot_arquivo: Label = %RotuloArquivo
@onready var _rot_aviso: Label = %RotuloAviso
@onready var _rot_posicao: Label = %RotuloPosicao
@onready var _rot_estado: Label = %RotuloEstado


func _ready() -> void:
	super()
	_pronta = UiKit.refs_ok(self, {
		"Editor": _editor, "RotuloArquivo": _rot_arquivo, "RotuloAviso": _rot_aviso, "RotuloPosicao": _rot_posicao, "RotuloEstado": _rot_estado,
	})
	if not _pronta:
		return
	conectar(SistemaArquivosVirtual.arquivo_alterado, _ao_arquivo_alterado)
	_atualizar_posicao()


func iniciar(args: Dictionary = {}) -> void:
	if not _pronta:
		return
	var caminho := str(args.get("caminho", ""))
	if caminho != "":
		_abrir_caminho(caminho)
	elif _caminho == "" and _editor.text == "":
		_novo_documento()
	ao_focar()


func receber_args(args: Dictionary) -> void:
	if _modificado and not await _decidir_alteracoes():
		return
	iniciar(args)


func ao_focar() -> void:
	if _pronta:
		_editor.call_deferred("grab_focus")


func pode_fechar() -> bool:
	return not _modificado


func confirmar_fechar() -> bool:
	if not _modificado:
		return true
	return await _decidir_alteracoes()


# ------------------------------------------------------------------ documento
func _novo_documento() -> void:
	_caminho = ""
	_somente_leitura = false
	_carregar_texto("")
	_atualizar_cabecalho()


func _carregar_texto(texto: String) -> void:
	_editor.text = texto
	_texto_salvo = texto
	_modificado = false
	_editor.editable = not _somente_leitura
	_editor.clear_undo_history()
	_editor.set_caret_line(0)
	_editor.set_caret_column(0)
	_atualizar_cabecalho()
	_atualizar_posicao()


func _abrir_caminho(caminho: String) -> void:
	var c := SistemaArquivosVirtual.resolver(caminho)
	if c == "" or not SistemaArquivosVirtual.acessivel(c, true) or not SistemaArquivosVirtual.eh_arquivo(c):
		_avisar("Não foi possível abrir: arquivo inexistente.")
		if _caminho == "" and _editor.text == "":
			_novo_documento()
		return
	var no: Dictionary = SistemaArquivosVirtual.obter_no(c)
	if SistemaArquivosVirtual.bloqueado_narrativamente(no):
		_avisar("Este arquivo ainda está bloqueado e não pode ser aberto agora.")
		if _caminho == "" and _editor.text == "":
			_novo_documento()
		return
	if SistemaArquivosVirtual.esta_criptografado(no):
		_avisar("Este arquivo está criptografado. Abra-o pelo Explorador de Arquivos para informar a chave.")
		if _caminho == "" and _editor.text == "":
			_novo_documento()
		return
	if SistemaArquivosVirtual.esta_corrompido(no):
		_avisar("Este arquivo está corrompido e não pode ser editado. Abra-o no Leitor de Texto (leitura parcial).")
		if _caminho == "" and _editor.text == "":
			_novo_documento()
		return
	_caminho = c
	_somente_leitura = SistemaArquivosVirtual.somente_leitura(c)
	_carregar_texto(SistemaArquivosVirtual.ler_texto(c))
	AbridorArquivos.registrar_abertura(c)


func _nome_exibido() -> String:
	return SistemaArquivosVirtual.nome_do_caminho(_caminho) if _caminho != "" else NOME_SEM_TITULO


func _atualizar_cabecalho() -> void:
	if not _pronta:
		return
	var marca := " ●" if _modificado else ""
	_rot_arquivo.text = (_caminho if _caminho != "" else "(documento novo)") + marca
	_rot_aviso.visible = _somente_leitura
	definir_titulo("%s — %s%s" % [TITULO_APP, _nome_exibido(), "*" if _modificado else ""])


# Ligado ao sinal caret_changed do Editor na cena.
func _atualizar_posicao() -> void:
	if not _pronta:
		return
	var linha := _editor.get_caret_line() + 1
	var coluna := _editor.get_caret_column() + 1
	_rot_posicao.text = "Ln %d, Col %d · %d caracteres" % [linha, coluna, _editor.text.length()]


func _avisar(texto: String) -> void:
	if _pronta:
		_rot_estado.text = texto


# ------------------------------------------------------------------ eventos
# Ligado ao sinal text_changed do Editor na cena.
func _ao_texto_alterado() -> void:
	var agora := _editor.text != _texto_salvo
	if agora != _modificado:
		_modificado = agora
		_atualizar_cabecalho()
	_atualizar_posicao()
	if _modificado and _editor.text.length() > SistemaArquivosVirtual.TAMANHO_MAX_TEXTO:
		_avisar("Atenção: o texto passou do limite de %d caracteres e não poderá ser salvo." % SistemaArquivosVirtual.TAMANHO_MAX_TEXTO)


# Ligado ao sinal gui_input do Editor na cena: atalhos Ctrl+N / Ctrl+O / Ctrl+S / Ctrl+Shift+S.
func _ao_entrada_editor(evento: InputEvent) -> void:
	if not (evento is InputEventKey) or not evento.pressed or not evento.ctrl_pressed:
		return
	var tecla: int = evento.keycode
	if tecla == KEY_S:
		accept_event()
		if evento.shift_pressed:
			_ao_salvar_como()
		else:
			_ao_salvar()
	elif tecla == KEY_O:
		accept_event()
		_ao_abrir()
	elif tecla == KEY_N:
		accept_event()
		_ao_novo()


func _ao_arquivo_alterado(caminho: String) -> void:
	# Outro app (ou o terminal) mexeu no arquivo aberto: só avisa; nunca sobrescreve o que o jogador está digitando.
	if caminho == _caminho and not _modificado and not _ocupado:
		var texto := SistemaArquivosVirtual.ler_texto(_caminho)
		if texto != _texto_salvo:
			_carregar_texto(texto)
			_avisar("O arquivo foi atualizado por outro aplicativo.")


func _ao_novo() -> void:
	if _ocupado:
		return
	_ocupado = true
	var seguir: bool = true
	if _modificado:
		seguir = await _decidir_alteracoes()
	_ocupado = false
	if seguir and is_inside_tree():
		_novo_documento()
		_avisar("Novo documento.")
		ao_focar()


func _ao_abrir() -> void:
	if _ocupado:
		return
	_ocupado = true
	var seguir: bool = true
	if _modificado:
		seguir = await _decidir_alteracoes()
	if not seguir or not is_inside_tree():
		_ocupado = false
		return
	var pasta := SistemaArquivosVirtual.caminho_pai(_caminho) if _caminho != "" else _pasta_padrao()
	var escolhido: String = await GerenciadorJanelas.escolher_arquivo(DialogoArquivo.Modo.ABRIR, pasta)
	_ocupado = false
	if escolhido == "" or not is_inside_tree():
		return
	_abrir_caminho(escolhido)
	ao_focar()


func _ao_salvar() -> void:
	if _ocupado:
		return
	_ocupado = true
	await _salvar()
	_ocupado = false
	if is_inside_tree():
		ao_focar()


func _ao_salvar_como() -> void:
	if _ocupado:
		return
	_ocupado = true
	await _salvar_como()
	_ocupado = false
	if is_inside_tree():
		ao_focar()


# ------------------------------------------------------------------ gravação
func _pasta_padrao() -> String:
	var docs := SistemaArquivosVirtual.resolver(SistemaArquivosVirtual.PASTA_USUARIO + "/documentos")
	return docs if docs != "" else SistemaArquivosVirtual.PASTA_USUARIO


## Retorna true se o texto foi gravado.
func _salvar() -> bool:
	if _caminho == "":
		return await _salvar_como()
	if _somente_leitura:
		await GerenciadorJanelas.alerta("Arquivo somente leitura", "“%s” não pode ser alterado. Use “Salvar como…” para criar uma cópia." % _nome_exibido())
		return false
	return _gravar_existente(_caminho)


func _salvar_como() -> bool:
	var pasta := SistemaArquivosVirtual.caminho_pai(_caminho) if _caminho != "" else _pasta_padrao()
	if SistemaArquivosVirtual.somente_leitura(pasta):
		pasta = _pasta_padrao()
	var escolhido: String = await GerenciadorJanelas.escolher_arquivo(DialogoArquivo.Modo.SALVAR, pasta, _nome_exibido(), PackedStringArray(EXTENSOES_TEXTO))
	if escolhido == "" or not is_inside_tree():
		return false
	if UtilTexto.extensao(SistemaArquivosVirtual.nome_do_caminho(escolhido)) == "":
		escolhido += ".txt"
	if SistemaArquivosVirtual.existe(escolhido):
		if SistemaArquivosVirtual.eh_pasta(escolhido):
			await GerenciadorJanelas.alerta("Nome em uso", "Já existe uma pasta com esse nome.")
			return false
		var substituir: bool = await GerenciadorJanelas.confirmar("Substituir arquivo?", "“%s” já existe. Deseja substituí-lo?" % SistemaArquivosVirtual.nome_do_caminho(escolhido), "Substituir", "Cancelar", true)
		if not substituir or not is_inside_tree():
			return false
		if not _gravar_existente(escolhido):
			return false
		_caminho = SistemaArquivosVirtual.resolver(escolhido)
	else:
		var criado := SistemaArquivosVirtual.criar_arquivo(SistemaArquivosVirtual.caminho_pai(escolhido), SistemaArquivosVirtual.nome_do_caminho(escolhido), _editor.text)
		if criado == "":
			await GerenciadorJanelas.alerta("Não foi possível salvar", "Pasta protegida, nome inválido, texto muito grande ou limite de arquivos atingido.")
			return false
		_caminho = criado
		_confirmar_gravacao()
	_somente_leitura = false
	_editor.editable = true
	_atualizar_cabecalho()
	return true


func _gravar_existente(caminho: String) -> bool:
	if not SistemaArquivosVirtual.escrever_texto(caminho, _editor.text):
		_avisar("Não foi possível salvar (arquivo protegido ou texto maior que o limite).")
		SistemaAudio.tocar_sfx("erro")
		return false
	_confirmar_gravacao()
	return true


func _confirmar_gravacao() -> void:
	_texto_salvo = _editor.text
	_modificado = false
	_atualizar_cabecalho()
	_avisar("Salvo às %s." % RelogioGlobal.hora_texto(true))


## Salvar / Descartar / Continuar editando. Retorna true se o chamador pode prosseguir.
func _decidir_alteracoes() -> bool:
	var escolha: int = await GerenciadorJanelas.escolher("Salvar alterações?", "“%s” tem alterações que ainda não foram salvas." % _nome_exibido(), PackedStringArray(["Salvar", "Descartar", "Continuar editando"]), 0, 1)
	if not is_inside_tree():
		return false
	if escolha == 0:
		return await _salvar()
	return escolha == 1
