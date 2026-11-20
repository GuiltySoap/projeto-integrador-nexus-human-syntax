class_name AppExplorador
extends AppBase
## Explorador de Arquivos do sistema simulado. Só enxerga o VFS (nunca o disco real).
## Navegação com histórico, busca na pasta, "Mostrar arquivos ocultos" (sempre disponível), criar/renomear e "excluir" = mover para a Lixeira
## (reversível). A pasta Rafael pede confirmação na primeira abertura; ligar "Mostrar arquivos ocultos" dentro dela revela o bloco oculto.
##
## A interface (barra de navegação, botões de ação, atalhos de locais, lista de itens e rodapé de status) vive em
## app_explorador.tscn; os sinais dos botões e da lista estão ligados na própria cena. Os atalhos de locais são botões da
## cena: o caminho de cada um fica nos "binds" da conexão `pressed -> _ao_local`. Este script cuida da navegação, do
## histórico, da listagem do VFS (o único conteúdo realmente dinâmico: a ItemList) e dos diálogos.

var _pasta: String = SistemaArquivosVirtual.PASTA_USUARIO
var _historico: Array = []
var _indice_hist: int = -1
var _mostrar_ocultos: bool = false
var _filtro: String = ""
var _pronta: bool = false
var _caminhos: Array = []

@onready var _lista: ItemList = %Lista
@onready var _campo_caminho: LineEdit = %CampoCaminho
@onready var _campo_filtro: LineEdit = %CampoFiltro
@onready var _btn_voltar: Button = %BotaoVoltar
@onready var _btn_avancar: Button = %BotaoAvancar
@onready var _btn_acima: Button = %BotaoAcima
@onready var _btn_abrir: Button = %BotaoAbrir
@onready var _btn_novo_arquivo: Button = %BotaoNovoArquivo
@onready var _btn_nova_pasta: Button = %BotaoNovaPasta
@onready var _btn_renomear: Button = %BotaoRenomear
@onready var _btn_excluir: Button = %BotaoExcluir
@onready var _btn_restaurar: Button = %BotaoRestaurar
@onready var _chk_ocultos: CheckBox = %CaixaOcultos
@onready var _rot_status: Label = %RotuloStatus


func _ready() -> void:
	super()
	_pronta = UiKit.refs_ok(self, {
		"Lista": _lista, "CampoCaminho": _campo_caminho, "CampoFiltro": _campo_filtro, "BotaoVoltar": _btn_voltar,
		"BotaoAvancar": _btn_avancar, "BotaoAcima": _btn_acima, "BotaoAbrir": _btn_abrir, "BotaoNovoArquivo": _btn_novo_arquivo,
		"BotaoNovaPasta": _btn_nova_pasta, "BotaoRenomear": _btn_renomear, "BotaoExcluir": _btn_excluir,
		"BotaoRestaurar": _btn_restaurar, "CaixaOcultos": _chk_ocultos, "RotuloStatus": _rot_status,
	})
	if not _pronta:
		return
	conectar(SistemaArquivosVirtual.arvore_alterada, _ao_arvore_alterada)
	conectar(SistemaArquivosVirtual.arquivo_alterado, _ao_arquivo_alterado)
	conectar(GerenciadorEstado.flag_alterada, _ao_flag)
	_atualizar_ocultos_habilitado()


func iniciar(args: Dictionary = {}) -> void:
	if not _pronta:
		return
	_aplicar_args(args)


func receber_args(args: Dictionary) -> void:
	if _pronta:
		_aplicar_args(args)


func ao_focar() -> void:
	if _pronta:
		_lista.grab_focus()


# ------------------------------------------------------------------ navegação
func _aplicar_args(args: Dictionary) -> void:
	var destino := str(args.get("caminho", ""))
	if destino == "":
		if _historico.is_empty():
			_ir_para(SistemaArquivosVirtual.PASTA_USUARIO)
		return
	var c := SistemaArquivosVirtual.resolver(destino)
	if c != "" and SistemaArquivosVirtual.eh_arquivo(c):
		_ir_para(SistemaArquivosVirtual.caminho_pai(c))
		return
	_ir_para(destino)


## Pode demorar (minigame de lógica da pasta bloqueada), então não retorna valor: é "dispare e esqueça".
func _ir_para(caminho: String, registrar: bool = true) -> void:
	var c := SistemaArquivosVirtual.resolver(caminho)
	if c == "" or not SistemaArquivosVirtual.eh_pasta(c):
		_aviso("Pasta não encontrada: %s" % caminho)
		_campo_caminho.text = _pasta
		return
	if not SistemaArquivosVirtual.acessivel(c, _mostrar_ocultos):
		_aviso("Esta pasta está oculta ou indisponível.")
		_campo_caminho.text = _pasta
		return
	var no: Dictionary = SistemaArquivosVirtual.obter_no(c)
	if SistemaArquivosVirtual.bloqueada(no):
		await _desbloquear_pasta(no)
		return
	if no.get("confirma_abertura") is Dictionary and not await _confirmar_abertura(no["confirma_abertura"] as Dictionary):
		return
	_pasta = c
	if registrar:
		_historico = _historico.slice(0, _indice_hist + 1)
		if _historico.is_empty() or str(_historico[_historico.size() - 1]) != c:
			_historico.append(c)
		_indice_hist = _historico.size() - 1
	GerenciadorEstado.set_flag("pasta_visitada:" + SistemaArquivosVirtual.chave(c), true)
	_filtro = ""
	_campo_filtro.text = ""
	_recarregar()


func _desbloquear_pasta(no: Dictionary) -> void:
	await GerenciadorJanelas.alerta("Pasta indisponível", str(no.get("mensagem_bloqueio", "Esta pasta está bloqueada.")))


## Pasta de outro usuário (Rafael): na primeira vez pergunta; [Abrir] aplica os efeitos do roteiro (as flags de investigação), [Cancelar] não muda nada.
## Devolve true se a pasta pode abrir.
func _confirmar_abertura(conf: Dictionary) -> bool:
	var flag := str(conf.get("ate_flag", ""))
	if flag != "" and GerenciadorEstado.tem_flag(flag):
		return true
	GerenciadorNarrativa.maya_diz(str(conf.get("fala", "")))
	var ok: bool = await GerenciadorJanelas.confirmar(str(conf.get("titulo", "Abrir pasta")), str(conf.get("texto", "")), str(conf.get("rotulo_ok", "Abrir")), str(conf.get("rotulo_cancelar", "Cancelar")), false, true)
	if not ok or not is_inside_tree():
		return false
	FluxoRoteiro.aplicar_efeitos(conf.get("efeitos"), "explorador:confirmar_abertura")
	return true


func _recarregar() -> void:
	if not _pronta:
		return
	var anterior := _caminho_selecionado()
	_lista.clear()
	_caminhos.clear()
	var termo := _filtro.strip_edges().to_lower()
	var achou_oculto := false
	for no in SistemaArquivosVirtual.listar(_pasta, _mostrar_ocultos):
		var caminho := str(no["caminho"])
		var nome := SistemaArquivosVirtual.nome_do_caminho(caminho)
		if termo != "" and not nome.to_lower().contains(termo):
			continue
		var texto := "%s  %s" % [AbridorArquivos.icone(no), nome]
		if bool(no.get("oculto", false)):
			texto += "   (oculto)"
			achou_oculto = true
		var indice := _lista.add_item(texto)
		_lista.set_item_tooltip(indice, _detalhe(no))
		_caminhos.append(caminho)
	if achou_oculto and _mostrar_ocultos:
		GerenciadorEstado.set_flag("ocultos_revelados", true)
	var posicao := _caminhos.find(anterior)
	if posicao >= 0:
		_lista.select(posicao)
	_campo_caminho.text = _pasta
	definir_titulo("Arquivos — %s" % (SistemaArquivosVirtual.nome_do_caminho(_pasta) if _pasta != "/" else "Raiz"))
	_atualizar_botoes()


func _detalhe(no: Dictionary) -> String:
	var tipo := str(no.get("tipo", ""))
	var partes: PackedStringArray = PackedStringArray()
	partes.append("Pasta" if tipo == "pasta" else _tipo_legivel(no))
	if tipo != "pasta":
		partes.append(SistemaArquivosVirtual.tamanho_legivel(no))
	if SistemaArquivosVirtual.bloqueado_narrativamente(no):
		partes.append("bloqueado")
	elif SistemaArquivosVirtual.esta_criptografado(no):
		partes.append("criptografado")
	elif SistemaArquivosVirtual.esta_corrompido(no):
		partes.append("corrompido")
	elif SistemaArquivosVirtual.bloqueada(no):
		partes.append("bloqueada")
	if bool(no.get("somente_leitura", false)):
		partes.append("somente leitura")
	return " · ".join(partes)


func _tipo_legivel(no: Dictionary) -> String:
	match AbridorArquivos.tipo_do_arquivo(no):
		"imagem":
			return "Imagem"
		"audio":
			return "Áudio"
		"zip":
			return "Arquivo compactado"
		"exe":
			return "Programa (simulado)"
		"texto":
			return "Documento de texto"
		_:
			return "Arquivo"


func _caminho_selecionado() -> String:
	if _lista == null:
		return ""
	var selecionados := _lista.get_selected_items()
	if selecionados.is_empty():
		return ""
	var indice := int(selecionados[0])
	if indice < 0 or indice >= _caminhos.size():
		return ""
	return str(_caminhos[indice])


func _atualizar_botoes() -> void:
	var em_lixeira := _pasta.to_lower() == SistemaArquivosVirtual.PASTA_LIXEIRA
	var selecionado := _caminho_selecionado()
	var tem_sel := selecionado != ""
	_btn_voltar.disabled = _indice_hist <= 0
	_btn_avancar.disabled = _indice_hist >= _historico.size() - 1
	_btn_acima.disabled = _pasta == "/"
	_btn_abrir.disabled = not tem_sel
	var pode_criar := not em_lixeira and not SistemaArquivosVirtual.somente_leitura(_pasta)
	_btn_novo_arquivo.disabled = not pode_criar
	_btn_nova_pasta.disabled = not pode_criar
	_btn_renomear.disabled = not tem_sel or em_lixeira or not SistemaArquivosVirtual.pode_alterar(selecionado)
	_btn_excluir.visible = not em_lixeira
	_btn_excluir.disabled = not tem_sel or not SistemaArquivosVirtual.pode_alterar(selecionado)
	_btn_restaurar.visible = em_lixeira
	_btn_restaurar.disabled = not tem_sel or SistemaArquivosVirtual.somente_leitura(selecionado)
	if tem_sel:
		var no: Dictionary = SistemaArquivosVirtual.obter_no(selecionado)
		_rot_status.text = "%s — %s" % [SistemaArquivosVirtual.nome_do_caminho(selecionado), _detalhe(no)]
	else:
		_rot_status.text = "%d item(ns) em %s" % [_caminhos.size(), _pasta]


func _aviso(texto: String) -> void:
	_rot_status.text = texto
	SistemaNotificacoes.notificar("Arquivos", texto, "aviso", 4.0)


## "Mostrar arquivos ocultos" está sempre disponível (a história não o tranca).
func _atualizar_ocultos_habilitado() -> void:
	_chk_ocultos.disabled = false
	_chk_ocultos.tooltip_text = "Mostrar arquivos ocultos"


# ------------------------------------------------------------------ sinais da interface
func _ao_voltar() -> void:
	if _indice_hist > 0:
		_indice_hist -= 1
		_ir_para(str(_historico[_indice_hist]), false)


func _ao_avancar() -> void:
	if _indice_hist < _historico.size() - 1:
		_indice_hist += 1
		_ir_para(str(_historico[_indice_hist]), false)


func _ao_acima() -> void:
	if _pasta != "/":
		_ir_para(SistemaArquivosVirtual.caminho_pai(_pasta))


func _ao_local(caminho: String) -> void:
	_ir_para(caminho)


func _ao_caminho_enviado(texto: String) -> void:
	_ir_para(texto.strip_edges())


func _ao_filtro(texto: String) -> void:
	_filtro = texto
	_recarregar()


func _ao_ocultos(ligado: bool) -> void:
	_mostrar_ocultos = ligado
	if ligado:
		SistemaArquivosVirtual.ao_mostrar_ocultos(_pasta)   # dentro da pasta do Rafael, revela o bloco oculto (segredo_rafael_encontrado)
	_recarregar()


func _ao_item_selecionado(_indice: int) -> void:
	_atualizar_botoes()


func _ao_item_ativado(indice: int) -> void:
	if indice >= 0 and indice < _caminhos.size():
		_abrir(str(_caminhos[indice]))


func _ao_clique_vazio(_posicao: Vector2, _botao: int) -> void:
	_lista.deselect_all()
	_atualizar_botoes()


func _ao_entrada_lista(evento: InputEvent) -> void:
	if not (evento is InputEventKey) or not evento.pressed:
		return
	var tecla: int = evento.keycode
	if tecla == KEY_BACKSPACE:
		accept_event()
		_ao_acima()
	elif tecla == KEY_DELETE:
		accept_event()
		if not _btn_excluir.disabled and _btn_excluir.visible:
			_ao_excluir()
	elif tecla == KEY_F2:
		accept_event()
		if not _btn_renomear.disabled:
			_ao_renomear()
	elif evento.alt_pressed and tecla == KEY_LEFT:
		accept_event()
		_ao_voltar()
	elif evento.alt_pressed and tecla == KEY_RIGHT:
		accept_event()
		_ao_avancar()


func _ao_abrir_selecionado() -> void:
	var c := _caminho_selecionado()
	if c != "":
		_abrir(c)


func _abrir(caminho: String) -> void:
	if SistemaArquivosVirtual.eh_pasta(caminho):
		_ir_para(caminho)
	else:
		AbridorArquivos.abrir(caminho)


# ------------------------------------------------------------------ criar / renomear / excluir / restaurar
func _ao_novo_arquivo() -> void:
	var r: Variant = await GerenciadorJanelas.pedir_texto("Novo arquivo", "Nome do arquivo (ex.: notas.txt):", "novo.txt", "Criar", false, "")
	if r == null or not is_inside_tree():
		return
	var nome := str(r).strip_edges()
	if not SistemaArquivosVirtual.validar_nome(nome):
		await GerenciadorJanelas.alerta("Nome inválido", "Use até 64 caracteres, sem  \\ / : * ? \" < > |")
		return
	var criado := SistemaArquivosVirtual.criar_arquivo(_pasta, nome)
	if criado == "":
		await GerenciadorJanelas.alerta("Não foi possível criar", "O nome já existe, a pasta é protegida ou o limite de itens foi atingido.")
		return
	_selecionar(criado)


func _ao_nova_pasta() -> void:
	var r: Variant = await GerenciadorJanelas.pedir_texto("Nova pasta", "Nome da pasta:", "Nova pasta", "Criar", false, "")
	if r == null or not is_inside_tree():
		return
	var nome := str(r).strip_edges()
	if not SistemaArquivosVirtual.validar_nome(nome):
		await GerenciadorJanelas.alerta("Nome inválido", "Use até 64 caracteres, sem  \\ / : * ? \" < > |")
		return
	var criado := SistemaArquivosVirtual.criar_pasta(_pasta, nome)
	if criado == "":
		await GerenciadorJanelas.alerta("Não foi possível criar", "O nome já existe, a pasta é protegida ou o limite de itens foi atingido.")
		return
	_selecionar(criado)


func _ao_renomear() -> void:
	var c := _caminho_selecionado()
	if c == "":
		return
	var atual := SistemaArquivosVirtual.nome_do_caminho(c)
	var r: Variant = await GerenciadorJanelas.pedir_texto("Renomear", "Novo nome para \"%s\":" % atual, "", "Renomear", false, atual)
	if r == null or not is_inside_tree():
		return
	var novo := str(r).strip_edges()
	if novo == atual:
		return
	if not SistemaArquivosVirtual.validar_nome(novo):
		await GerenciadorJanelas.alerta("Nome inválido", "Use até 64 caracteres, sem  \\ / : * ? \" < > |")
		return
	var destino := SistemaArquivosVirtual.renomear(c, novo)
	if destino == "":
		await GerenciadorJanelas.alerta("Não foi possível renomear", "Já existe um item com esse nome ou o item é protegido.")
		return
	_selecionar(destino)


func _ao_excluir() -> void:
	var c := _caminho_selecionado()
	if c == "":
		return
	var nome := SistemaArquivosVirtual.nome_do_caminho(c)
	var ok: bool = await GerenciadorJanelas.confirmar("Mover para a Lixeira?", "\"%s\" será movido para a Lixeira (você poderá restaurar)." % nome, "Mover", "Cancelar", true)
	if not ok or not is_inside_tree():
		return
	if not SistemaArquivosVirtual.mover_para_lixeira(c):
		await GerenciadorJanelas.alerta("Não foi possível excluir", "Este item é protegido pelo sistema.")


func _ao_restaurar() -> void:
	var c := _caminho_selecionado()
	if c == "":
		return
	if not SistemaArquivosVirtual.restaurar_da_lixeira(c):
		await GerenciadorJanelas.alerta("Não foi possível restaurar", "Este item é protegido e não pode sair da Lixeira.")


func _selecionar(caminho: String) -> void:
	_recarregar()
	var posicao := _caminhos.find(caminho)
	if posicao >= 0:
		_lista.select(posicao)
		_lista.ensure_current_is_visible()
		_atualizar_botoes()


# ------------------------------------------------------------------ sinais dos autoloads
func _ao_arvore_alterada(pasta: String) -> void:
	if SistemaArquivosVirtual.resolver(pasta) == SistemaArquivosVirtual.resolver(_pasta):
		_recarregar()


func _ao_arquivo_alterado(_caminho: String) -> void:
	_recarregar()


func _ao_flag(_nome: String, _valor: Variant) -> void:
	_recarregar()   # a visibilidade dos itens depende de flags (`visivel_se`)
