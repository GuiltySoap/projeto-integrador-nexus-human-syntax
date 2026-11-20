class_name AppTerminal
extends AppBase
## Terminal SIMULADO do sistema. Nenhum comando toca o computador real: tudo opera sobre o VFS e os dados do jogo.
## Comandos de arquivos (ls, cd, cat, tree, open...) e, no roteiro v2.0, os comandos de permissões:
##   listar permissoes        mostra as cinco permissões e o estado de cada uma (Ativada/Desativada)
##   revogar <id ou número>   revoga uma permissão ativa pelo MESMO serviço das Configurações (Permissoes.revogar): um passo até o fim da
##                            Task 8; na Task 9 a primeira tentativa de cada permissão é adiada ("maya: comando adiado. você parece cansado.")
## Setas ↑/↓ navegam no histórico; Tab completa comandos e caminhos. Cada comando emite `comando_executado` (comando, argumentos, ok, pasta).
##
## A interface (painel da saída, rótulo do prompt e campo de comando) vive em app_terminal.tscn e os sinais do campo
## (`text_submitted`, `gui_input`) estão ligados na própria cena. O único conteúdo dinâmico é o texto da saída (RichTextLabel).

const MAX_LINHAS := 400
const COMANDOS: Array = ["help", "ajuda", "ls", "cd", "pwd", "cat", "tree", "whoami", "clear", "echo", "history", "open", "edit", "listar", "revogar", "exit"]
## Quantos argumentos (e de que tamanho) o evento `comando_executado` guarda.
const MAX_ARGUMENTOS_NO_EVENTO := 8
const MAX_TAMANHO_ARGUMENTO := 80
const COMANDOS_BLOQUEADOS: Array = ["rm", "rmdir", "del", "format", "shutdown", "reboot", "sudo", "dd", "mv", "cp", "chmod", "curl", "wget", "ssh"]
const COR_OK := "#4ade80"
const COR_ERRO := "#f87171"
const COR_AVISO := "#fbbf24"
const COR_ACENTO := "#38bdf8"
const COR_FRACA := "#94a3b8"

var _cwd: String = SistemaArquivosVirtual.PASTA_USUARIO
var _linhas: Array = []
var _historico: Array = []
var _pos_historico: int = 0
var _ocupado: bool = false
var _pronta: bool = false
var _banner_escrito: bool = false
## O comando em execução falhou? (_erro e os avisos de comando bloqueado ligam; `_executar` zera antes de cada comando e informa o evento.)
var _falhou: bool = false

@onready var _saida: RichTextLabel = %Saida
@onready var _campo: LineEdit = %Campo
@onready var _rot_prompt: Label = %RotuloPrompt


func _ready() -> void:
	super()
	_pronta = UiKit.refs_ok(self, {"Saida": _saida, "Campo": _campo, "RotuloPrompt": _rot_prompt})
	if _pronta:
		_atualizar_prompt()


func iniciar(_args: Dictionary = {}) -> void:
	if not _pronta:
		return
	if not _banner_escrito:
		_banner_escrito = true
		_banner()
	ao_focar()


func ao_focar() -> void:
	if _pronta:
		UiKit.focar_depois(_campo)


func _banner() -> void:
	_escrever("[color=%s][b]HumaxOS Terminal 1.0[/b][/color] — ambiente simulado: nenhum comando afeta o seu computador real." % COR_ACENTO)
	_escrever("[color=%s]Digite [b]help[/b] para ver os comandos. Tab completa, ↑/↓ percorrem o histórico.[/color]" % COR_FRACA)
	_escrever("")


# ------------------------------------------------------------------ saída
func _escrever(bbcode: String) -> void:
	_linhas.append(bbcode)
	if _linhas.size() > MAX_LINHAS:
		_linhas = _linhas.slice(_linhas.size() - (MAX_LINHAS - 100))
		_saida.text = "\n".join(PackedStringArray(_linhas)) + "\n"
	else:
		_saida.append_text(bbcode + "\n")


func _erro(texto: String) -> void:
	_falhou = true
	_escrever("[color=%s]%s[/color]" % [COR_ERRO, texto])


func _prompt_texto() -> String:
	var caminho := _cwd
	if caminho == SistemaArquivosVirtual.PASTA_USUARIO:
		caminho = "~"
	elif caminho.begins_with(SistemaArquivosVirtual.PASTA_USUARIO + "/"):
		caminho = "~" + caminho.substr(SistemaArquivosVirtual.PASTA_USUARIO.length())
	return "%s@humax:%s$" % [_nome_usuario(), caminho]


func _nome_usuario() -> String:
	var n := UtilTexto.normalizar_chave(GerenciadorEstado.nome_jogador)
	return n if n != "" else "usuario"


func _atualizar_prompt() -> void:
	_rot_prompt.text = _prompt_texto()


# ------------------------------------------------------------------ entrada
func _ao_enviar(texto: String) -> void:
	_campo.clear()
	if _ocupado:
		return
	var linha := texto.strip_edges()
	_escrever("[color=%s]%s[/color] %s" % [COR_OK, _prompt_texto(), UtilTexto.escapar_bbcode(linha)])
	if linha == "":
		return
	_historico.append(linha)
	if _historico.size() > 100:
		_historico.pop_front()
	_pos_historico = _historico.size()
	_executar(linha)


func _ao_entrada_campo(evento: InputEvent) -> void:
	if not (evento is InputEventKey) or not evento.pressed:
		return
	var tecla: int = evento.keycode
	if tecla == KEY_UP:
		accept_event()
		_navegar_historico(-1)
	elif tecla == KEY_DOWN:
		accept_event()
		_navegar_historico(1)
	elif tecla == KEY_TAB:
		accept_event()
		_completar()
	elif tecla == KEY_L and evento.ctrl_pressed:
		accept_event()
		_limpar()


func _navegar_historico(passo: int) -> void:
	if _historico.is_empty():
		return
	_pos_historico = clampi(_pos_historico + passo, 0, _historico.size())
	_campo.text = "" if _pos_historico >= _historico.size() else str(_historico[_pos_historico])
	_campo.caret_column = _campo.text.length()


func _completar() -> void:
	var texto := _campo.text
	var partes := texto.split(" ")
	var ultimo: String = partes[partes.size() - 1]
	var candidatos: Array = []
	var prefixo_texto := texto.substr(0, texto.length() - ultimo.length())
	if partes.size() == 1:
		for c in _todos_comandos():
			if str(c).begins_with(ultimo.to_lower()):
				candidatos.append(str(c))
	elif str(partes[0]).to_lower() == "revogar":
		for id_perm in Permissoes.ids():
			if str(id_perm).begins_with(ultimo.to_lower()):
				candidatos.append(str(id_perm))
	elif str(partes[0]).to_lower() == "listar":
		if "permissoes".begins_with(ultimo.to_lower()):
			candidatos.append("permissoes")
	else:
		var pasta := _cwd
		var nome_parcial := ultimo
		var barra := ultimo.rfind("/")
		var diretorio_digitado := ""
		if barra >= 0:
			diretorio_digitado = ultimo.substr(0, barra + 1)
			nome_parcial = ultimo.substr(barra + 1)
			pasta = _resolver(diretorio_digitado)
		if pasta != "" and SistemaArquivosVirtual.eh_pasta(pasta):
			for no in SistemaArquivosVirtual.listar(pasta, false):
				var nome := SistemaArquivosVirtual.nome_do_caminho(str(no["caminho"]))
				if nome.to_lower().begins_with(nome_parcial.to_lower()):
					var sufixo := "/" if str(no.get("tipo", "")) == "pasta" else ""
					var item := diretorio_digitado + nome + sufixo
					candidatos.append("\"%s\"" % item if nome.contains(" ") else item)
	if candidatos.is_empty():
		return
	if candidatos.size() == 1:
		_campo.text = prefixo_texto + str(candidatos[0])
		_campo.caret_column = _campo.text.length()
		return
	_escrever("[color=%s]%s[/color]" % [COR_FRACA, "   ".join(PackedStringArray(candidatos))])


func _todos_comandos() -> Array:
	return COMANDOS.duplicate()


## As aspas duplas da linha fecham (número par)? Linha com aspa aberta é erro de sintaxe: o Terminal não adivinha o que o jogador quis.
static func aspas_balanceadas(linha: String) -> bool:
	return linha.count("\"") % 2 == 0


## Divide a linha em argumentos respeitando aspas duplas ("Nova pasta"). Estática e determinística: os testes chamam direto.
static func tokenizar(linha: String) -> PackedStringArray:
	var saida := PackedStringArray()
	var atual := ""
	var entre_aspas := false
	for i in linha.length():
		var c: String = linha[i]
		if c == "\"":
			entre_aspas = not entre_aspas
		elif c == " " and not entre_aspas:
			if atual != "":
				saida.append(atual)
				atual = ""
		else:
			atual += c
	if atual != "":
		saida.append(atual)
	return saida


func _resolver(entrada: String) -> String:
	var absoluto := SistemaArquivosVirtual.resolver_relativo(_cwd, entrada)
	return SistemaArquivosVirtual.resolver(absoluto) if absoluto != "" else ""


func _limpar() -> void:
	_linhas.clear()
	_saida.clear()


# ------------------------------------------------------------------ execução
func _executar(linha: String) -> void:
	_falhou = false
	if not aspas_balanceadas(linha):
		_erro("erro de sintaxe: aspas não fechadas")
		_emitir_comando(linha.get_slice(" ", 0).to_lower(), PackedStringArray(), false)
		return
	var t := tokenizar(linha)
	if t.is_empty():
		return
	var cmd := t[0].to_lower()
	var args := t.slice(1)
	_despachar(cmd, args)
	_emitir_comando(cmd, args, not _falhou)


## Emite `comando_executado` (o registro e quem assina o evento ficam sabendo; o Terminal não conhece quem escuta).
func _emitir_comando(cmd: String, args: PackedStringArray, ok: bool) -> void:
	var argumentos: Array = []
	for i in mini(args.size(), MAX_ARGUMENTOS_NO_EVENTO):
		argumentos.append(args[i].left(MAX_TAMANHO_ARGUMENTO))
	SistemaEventos.emitir("comando_executado", {"comando": cmd.left(MAX_TAMANHO_ARGUMENTO), "argumentos": argumentos, "ok": ok, "pasta": _cwd}, "terminal")


func _despachar(cmd: String, args: PackedStringArray) -> void:
	if COMANDOS_BLOQUEADOS.has(cmd):
		_falhou = true
		_escrever("[color=%s]'%s' está desativado na simulação: este terminal não altera nada fora do jogo. Use o Explorador (Excluir move para a Lixeira).[/color]" % [COR_AVISO, UtilTexto.escapar_bbcode(cmd)])
		return
	match cmd:
		"help", "ajuda":
			_cmd_ajuda()
		"ls":
			_cmd_ls(args)
		"cd":
			_cmd_cd(args)
		"pwd":
			_escrever(_cwd)
		"cat":
			_cmd_cat(args)
		"tree":
			_cmd_tree(args)
		"whoami":
			_escrever(_nome_usuario())
		"clear":
			_limpar()
		"echo":
			_escrever(UtilTexto.escapar_bbcode(" ".join(args)))
		"history":
			for i in _historico.size():
				_escrever("[color=%s]%3d[/color]  %s" % [COR_FRACA, i + 1, UtilTexto.escapar_bbcode(str(_historico[i]))])
		"listar":
			_cmd_listar(args)
		"revogar":
			_cmd_revogar(args)
		"mkdir", "touch":
			_cmd_criar(cmd, args)
		"open", "edit":
			_cmd_abrir(args)
		"exit":
			if janela is JanelaBase:
				GerenciadorJanelas.fechar_janela(janela as JanelaBase)
		_:
			_erro("comando não encontrado: %s (digite help)" % UtilTexto.escapar_bbcode(cmd))


func _cmd_ajuda() -> void:
	_escrever("[b]Comandos[/b]")
	var itens := [
		["ls [-a] [-l] [pasta]", "lista arquivos (-a mostra ocultos, quando liberado)"],
		["cd <pasta>", "entra numa pasta (cd sozinho volta ao início)"],
		["pwd, whoami, clear, echo, history", "utilidades"],
		["cat <arquivo>", "mostra um arquivo de texto"],
		["tree [pasta]", "mostra a árvore de pastas"],
		["open <item> / edit <arquivo>", "abre no aplicativo apropriado"],
		["mkdir <nome> / touch <nome>", "cria pasta / arquivo vazio"],
		["listar permissoes", "mostra as cinco permissões da Maya e o estado de cada uma"],
		["revogar <id ou número>", "revoga uma permissão ativa (o mesmo que desmarcar em Configurações > Privacidade)"],
		["exit", "fecha o terminal"],
	]
	for item in itens:
		_escrever("  [color=%s]%-38s[/color] %s" % [COR_ACENTO, str(item[0]), str(item[1])])


## `listar permissoes`: a lista numerada das cinco permissões com o estado real de cada uma.
func _cmd_listar(args: PackedStringArray) -> void:
	if args.is_empty() or args[0].to_lower() != "permissoes":
		_erro("uso: listar permissoes")
		return
	var ids := Permissoes.ids()
	for i in ids.size():
		var id_perm: String = ids[i]
		var ativa := Permissoes.valor(id_perm)
		_escrever("  %d. %-34s [color=%s]%s[/color]   (%s)" % [i + 1, UtilTexto.escapar_bbcode(str(Permissoes.info(id_perm).get("nome", id_perm))),
			COR_OK if ativa else COR_FRACA, "Ativada" if ativa else "Desativada", id_perm])


## `revogar <id ou número>`: usa o serviço central. Na Task 9 a primeira tentativa de cada permissão é adiada.
func _cmd_revogar(args: PackedStringArray) -> void:
	if args.is_empty():
		_erro("uso: revogar <id ou número>   (veja: listar permissoes)")
		return
	var ids := Permissoes.ids()
	var alvo := args[0].to_lower()
	var id_perm := ""
	if alvo.is_valid_int() and int(alvo) >= 1 and int(alvo) <= ids.size():
		id_perm = ids[int(alvo) - 1]
	elif ids.has(alvo):
		id_perm = alvo
	if id_perm == "":
		_erro("revogar: permissão desconhecida: %s" % UtilTexto.escapar_bbcode(args[0]))
		return
	var r: Dictionary = Permissoes.revogar(id_perm, "terminal")
	match str(r.get("resultado", "")):
		Permissoes.REVOGADA:
			GerenciadorEstado.set_flag("permissao_desativada_pelo_jogador", true)
			_escrever("[color=%s]permissão revogada:[/color] %s" % [COR_OK, UtilTexto.escapar_bbcode(str(Permissoes.info(id_perm).get("nome", id_perm)))])
		Permissoes.ADIADA:
			_escrever("[color=%s]maya: comando adiado. você parece cansado.[/color]" % COR_AVISO)
		Permissoes.JA_INATIVA:
			_escrever("a permissão já está desativada.")
		_:
			_erro("revogar: não foi possível revogar.")


func _cmd_ls(args: PackedStringArray) -> void:
	var mostrar_ocultos := false
	var longo := false
	var alvo := ""
	for a in args:
		if a.begins_with("-"):
			mostrar_ocultos = mostrar_ocultos or a.contains("a")
			longo = longo or a.contains("l")
		else:
			alvo = a
	var c := _resolver(alvo if alvo != "" else ".")
	if c == "" or not SistemaArquivosVirtual.acessivel(c, mostrar_ocultos):
		_erro("ls: não foi possível acessar '%s': arquivo ou pasta inexistente" % UtilTexto.escapar_bbcode(alvo))
		return
	if SistemaArquivosVirtual.eh_arquivo(c):
		_escrever(UtilTexto.escapar_bbcode(SistemaArquivosVirtual.nome_do_caminho(c)))
		return
	var no_pasta: Dictionary = SistemaArquivosVirtual.obter_no(c)
	if SistemaArquivosVirtual.bloqueada(no_pasta):
		_erro("ls: permissão negada: pasta bloqueada (resolva o puzzle no Explorador de Arquivos)")
		return
	var itens: Array = SistemaArquivosVirtual.listar(c, mostrar_ocultos)
	if itens.is_empty():
		_escrever("[color=%s](vazio)[/color]" % COR_FRACA)
		return
	for no in itens:
		var nome := UtilTexto.escapar_bbcode(SistemaArquivosVirtual.nome_do_caminho(str(no["caminho"])))
		var eh_pasta := str(no.get("tipo", "")) == "pasta"
		var rotulo := "[color=%s]%s/[/color]" % [COR_ACENTO, nome] if eh_pasta else nome
		if SistemaArquivosVirtual.bloqueada(no):
			rotulo += " [color=%s][bloqueada][/color]" % COR_AVISO
		elif SistemaArquivosVirtual.bloqueado_narrativamente(no):
			rotulo += " [color=%s][bloqueado][/color]" % COR_AVISO
		elif SistemaArquivosVirtual.esta_criptografado(no):
			rotulo += " [color=%s][criptografado][/color]" % COR_AVISO
		elif SistemaArquivosVirtual.esta_corrompido(no):
			rotulo += " [color=%s][corrompido][/color]" % COR_ERRO
		if bool(no.get("oculto", false)):
			rotulo += " [color=%s](oculto)[/color]" % COR_FRACA
		if longo:
			var permissao := "r-" if bool(no.get("somente_leitura", false)) else "rw"
			_escrever("%s  %8s  %s" % [permissao, SistemaArquivosVirtual.tamanho_legivel(no), rotulo])
		else:
			_escrever(rotulo)


func _cmd_cd(args: PackedStringArray) -> void:
	var alvo: String = args[0] if not args.is_empty() else "~"
	var c := _resolver(alvo)
	if c == "" or not SistemaArquivosVirtual.acessivel(c, false):
		_erro("cd: %s: pasta inexistente" % UtilTexto.escapar_bbcode(alvo))
		return
	if not SistemaArquivosVirtual.eh_pasta(c):
		_erro("cd: %s: não é uma pasta" % UtilTexto.escapar_bbcode(alvo))
		return
	if SistemaArquivosVirtual.bloqueada(SistemaArquivosVirtual.obter_no(c)):
		_erro("cd: permissão negada: pasta bloqueada (resolva o puzzle no Explorador de Arquivos)")
		return
	_cwd = c
	GerenciadorEstado.set_flag("pasta_visitada:" + SistemaArquivosVirtual.chave(c), true)
	_atualizar_prompt()


func _cmd_cat(args: PackedStringArray) -> void:
	if args.is_empty():
		_erro("uso: cat <arquivo>")
		return
	var c := _resolver(args[0])
	if c == "" or not SistemaArquivosVirtual.acessivel(c, false) or not SistemaArquivosVirtual.eh_arquivo(c):
		_erro("cat: %s: arquivo inexistente" % UtilTexto.escapar_bbcode(args[0]))
		return
	var no: Dictionary = SistemaArquivosVirtual.obter_no(c)
	if SistemaArquivosVirtual.bloqueado_narrativamente(no):
		_erro("cat: %s: arquivo bloqueado (ainda não liberado)" % UtilTexto.escapar_bbcode(args[0]))
		return
	var tipo := AbridorArquivos.tipo_do_arquivo(no)
	if tipo != "texto" and tipo != "outro":
		_erro("cat: arquivo binário. Use: open %s" % UtilTexto.escapar_bbcode(args[0]))
		return
	if SistemaArquivosVirtual.esta_corrompido(no):
		_escrever("[color=%s]aviso: arquivo corrompido, leitura parcial.[/color]" % COR_AVISO)
	var texto := SistemaArquivosVirtual.ler_texto(c)
	for linha in texto.split("\n"):
		_escrever(UtilTexto.escapar_bbcode(linha))
	AbridorArquivos.registrar_abertura(c)


func _cmd_tree(args: PackedStringArray) -> void:
	var c := _resolver(args[0] if not args.is_empty() else ".")
	if c == "" or not SistemaArquivosVirtual.acessivel(c, false) or not SistemaArquivosVirtual.eh_pasta(c):
		_erro("tree: pasta inexistente")
		return
	_escrever("[color=%s]%s[/color]" % [COR_ACENTO, UtilTexto.escapar_bbcode(c)])
	_arvore(c, "", 0)


func _arvore(pasta: String, prefixo: String, nivel: int) -> void:
	if nivel >= 3 or SistemaArquivosVirtual.bloqueada(SistemaArquivosVirtual.obter_no(pasta)):
		return
	var itens: Array = SistemaArquivosVirtual.listar(pasta, false)
	for i in itens.size():
		var no: Dictionary = itens[i]
		var ultimo := i == itens.size() - 1
		var nome := UtilTexto.escapar_bbcode(SistemaArquivosVirtual.nome_do_caminho(str(no["caminho"])))
		var eh_pasta := str(no.get("tipo", "")) == "pasta"
		_escrever("%s%s %s" % [prefixo, "└──" if ultimo else "├──", "[color=%s]%s/[/color]" % [COR_ACENTO, nome] if eh_pasta else nome])
		if eh_pasta:
			_arvore(str(no["caminho"]), prefixo + ("    " if ultimo else "│   "), nivel + 1)


func _cmd_criar(cmd: String, args: PackedStringArray) -> void:
	if args.is_empty():
		_erro("uso: %s <nome>" % cmd)
		return
	var nome: String = args[0]
	var criado := ""
	if cmd == "mkdir":
		criado = SistemaArquivosVirtual.criar_pasta(_cwd, nome)
	else:
		criado = SistemaArquivosVirtual.criar_arquivo(_cwd, nome)
	if criado == "":
		_erro("%s: não foi possível criar '%s' (nome inválido, já existe ou pasta protegida)" % [cmd, UtilTexto.escapar_bbcode(nome)])


func _cmd_abrir(args: PackedStringArray) -> void:
	if args.is_empty():
		_erro("uso: open <arquivo ou pasta>")
		return
	var c := _resolver(args[0])
	if c == "" or not SistemaArquivosVirtual.acessivel(c, false):
		_erro("open: %s: item inexistente" % UtilTexto.escapar_bbcode(args[0]))
		return
	AbridorArquivos.abrir(c)


