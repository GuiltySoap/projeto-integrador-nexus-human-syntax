class_name AppRelatorio
extends AppBase
## Relatórios da Maya (roteiro v2.0): o de SINCRONIZAÇÃO (Task 1) e o de CUIDADO (Task 8), lidos de core/data/narrativa/relatorios_v2.json.
## Cada linha só aparece se a condição `se` vale agora; `destaque_se` marca a linha com "▶" (texto, não só cor). Marcadores no texto:
##   {ocultas}         quantas mensagens a Maya ocultou no Mensageiro;
##   {rafael_abertos}  quantos arquivos da pasta Rafael o jogador abriu.
## Ações de linha: "conversas" abre a lista das conversas sincronizadas (somente leitura); "mensagem:<texto>" mostra o texto abaixo da tabela.
## Args: {"relatorio": "sincronizacao" | "cuidado"}.

var _id: String = ""
var _rot_titulo: Label = null
var _grade: GridContainer = null
var _rot_mensagem: Label = null
var _caixa_conversas: VBoxContainer = null
var _lista: ItemList = null
var _texto_conversa: RichTextLabel = null
var _itens: Array = []


func _ready() -> void:
	super._ready()
	var margem := MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 14)
	add_child(margem)
	var rolagem := ScrollContainer.new()
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margem.add_child(rolagem)
	var coluna := VBoxContainer.new()
	coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	coluna.add_theme_constant_override("separation", 10)
	rolagem.add_child(coluna)
	_rot_titulo = Label.new()
	_rot_titulo.theme_type_variation = &"RotuloTitulo18"
	_rot_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rot_titulo.custom_minimum_size = Vector2(1, 0)
	coluna.add_child(_rot_titulo)
	_grade = GridContainer.new()
	_grade.columns = 3
	_grade.add_theme_constant_override("h_separation", 14)
	_grade.add_theme_constant_override("v_separation", 8)
	coluna.add_child(_grade)
	_rot_mensagem = Label.new()
	_rot_mensagem.theme_type_variation = &"RotuloAcento"
	_rot_mensagem.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rot_mensagem.custom_minimum_size = Vector2(1, 0)
	_rot_mensagem.visible = false
	coluna.add_child(_rot_mensagem)
	_caixa_conversas = VBoxContainer.new()
	_caixa_conversas.visible = false
	_lista = ItemList.new()
	_lista.custom_minimum_size = Vector2(0, 96)
	_lista.item_selected.connect(_ao_conversa)
	_caixa_conversas.add_child(_lista)
	_texto_conversa = RichTextLabel.new()
	_texto_conversa.bbcode_enabled = true
	_texto_conversa.fit_content = true
	_texto_conversa.custom_minimum_size = Vector2(1, 0)
	_caixa_conversas.add_child(_texto_conversa)
	coluna.add_child(_caixa_conversas)
	var fechar := Button.new()
	fechar.text = "Fechar"
	fechar.pressed.connect(_ao_fechar_janela)
	coluna.add_child(fechar)


func iniciar(args: Dictionary = {}) -> void:
	var id_novo := str(args.get("relatorio", _id))
	if id_novo != "":
		_id = id_novo
	_montar()


func receber_args(args: Dictionary) -> void:
	iniciar(args)


## Substitui os marcadores do texto pelos números do estado atual.
static func preencher(texto: String) -> String:
	var t := FluxoRoteiro.texto(texto)
	if t.contains("{ocultas}"):
		t = t.replace("{ocultas}", str(contar_ocultas()))
	if t.contains("{rafael_abertos}"):
		t = t.replace("{rafael_abertos}", str(contar_rafael_abertos()))
	return t


## Mensagens que a Maya ocultou (continuam marcadas com `texto_oculto` mesmo depois de reveladas).
static func contar_ocultas() -> int:
	var n := 0
	for contato in GerenciadorEstado.chat:
		for e in GerenciadorEstado.historico(str(contato)):
			if e is Dictionary and (e as Dictionary).has("texto_oculto"):
				n += 1
	return n


## Arquivos da pasta Rafael que o jogador abriu (flags `arquivo_aberto:<caminho>`).
static func contar_rafael_abertos() -> int:
	var n := 0
	for chave in GerenciadorEstado.flags:
		var k := str(chave)
		if k.begins_with("arquivo_aberto:") and k.contains("rafael") and bool(GerenciadorEstado.flags[chave]):
			n += 1
	return n


## Linhas do relatório que valem agora: [{colunas, destaque, acao}].
static func linhas_visiveis(id_relatorio: String) -> Array:
	var def: Dictionary = FluxoRoteiro.relatorio(id_relatorio)
	var saida: Array = []
	for l in def.get("linhas", []):
		var ld: Dictionary = l
		if ld.has("se") and not GerenciadorEstado.avaliar_condicao(ld["se"]):
			continue
		var colunas: Array = []
		for c in ld.get("colunas", []):
			colunas.append(preencher(str(c)))
		saida.append({"colunas": colunas, "destaque": ld.has("destaque_se") and GerenciadorEstado.avaliar_condicao(ld["destaque_se"]), "acao": str(ld.get("acao", ""))})
	return saida


func _montar() -> void:
	var def: Dictionary = FluxoRoteiro.relatorio(_id)
	_rot_titulo.text = str(def.get("titulo", "Relatório"))
	definir_titulo(_rot_titulo.text)
	UiKit.remover_itens(_itens)
	_rot_mensagem.visible = false
	_caixa_conversas.visible = false
	_grade.columns = 3
	for c in def.get("colunas", []):
		var cab := Label.new()
		cab.text = str(c)
		cab.theme_type_variation = &"RotuloAcento"
		_grade.add_child(cab)
		_itens.append(cab)
	var vazio := Label.new()
	_grade.add_child(vazio)
	_itens.append(vazio)
	for linha in linhas_visiveis(_id):
		var ld: Dictionary = linha
		var colunas: Array = ld["colunas"]
		for i in colunas.size():
			var r := Label.new()
			r.text = ("▶ " if bool(ld["destaque"]) and i == 0 else "") + str(colunas[i])
			r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			r.custom_minimum_size = Vector2(200 if i == 0 else 280, 0)
			r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_grade.add_child(r)
			_itens.append(r)
		var acao := str(ld["acao"])
		if acao == "":
			var espaco := Control.new()
			_grade.add_child(espaco)
			_itens.append(espaco)
		else:
			var b := Button.new()
			b.text = "Abrir" if acao == "conversas" else "Detalhes"
			b.pressed.connect(_ao_acao.bind(acao))
			_grade.add_child(b)
			_itens.append(b)


func _ao_acao(acao: String) -> void:
	if acao == "conversas":
		_rot_mensagem.visible = false
		_abrir_conversas()
	elif acao.begins_with("mensagem:"):
		_caixa_conversas.visible = false
		_rot_mensagem.text = acao.substr(9)
		_rot_mensagem.visible = true


func _abrir_conversas() -> void:
	_lista.clear()
	for c in FluxoRoteiro.conversas_sincronizadas():
		_lista.add_item(str((c as Dictionary).get("titulo", (c as Dictionary).get("id", ""))))
	_texto_conversa.text = "Escolha uma conversa. O histórico sincronizado é somente leitura."
	_caixa_conversas.visible = true
	if _lista.item_count > 0:
		_lista.select(0)
		_ao_conversa(0)


func _ao_conversa(indice: int) -> void:
	var conversas: Array = FluxoRoteiro.conversas_sincronizadas()
	if indice < 0 or indice >= conversas.size():
		return
	var c: Dictionary = conversas[indice]
	_texto_conversa.clear()
	for m in c.get("mensagens", []):
		var quem := str(m[0])
		var nome := GerenciadorEstado.nome_jogador if quem == "jogador" else str(GerenciadorNarrativa.info_contato(quem).get("nome", quem))
		_texto_conversa.append_text("[b]%s:[/b] %s\n" % [UtilTexto.escapar_bbcode(nome), UtilTexto.escapar_bbcode(str(m[1]))])
	if str(c.get("nota", "")) != "":
		_texto_conversa.append_text("[i]%s[/i]\n" % UtilTexto.escapar_bbcode(str(c["nota"])))


func _ao_fechar_janela() -> void:
	if janela is JanelaBase:
		GerenciadorJanelas.fechar_janela(janela as JanelaBase)
