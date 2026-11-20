extends ModuloDeTeste
## Módulo 4 (roteiro v2.0): interfaces e sistemas de apoio. Catálogo dos apps do desktop, cartão de permissão, Mensageiro (barra de envio, mensagens
## ocultas, cancelamento, revelação ao revogar), Terminal (`listar permissoes` / `revogar`), Configurações > Privacidade, Mural e relatórios.

const BASE_PLANO := {"T1.4": "pode_organizar", "T3.3": "valeu", "T3.4": "pode_montar", "T4.3": "pode_me_ajudar", "T4.5e": "deixar_pra_la", "T6.3": "so_algoritmo",
	"T6.4": "vou_ver", "T6.6a": "tudo_bem_faz_sentido"}


func executar(banca_do_executor: BancaDeTestes) -> void:
	banca = banca_do_executor
	_isolar_configuracoes()
	_testar_catalogo()
	await _testar_cartao()
	_testar_barra_de_envio()
	_testar_mensagens_ocultas()
	await _testar_terminal()
	await _testar_configuracoes()
	await _testar_relatorios()
	await _testar_mural()
	_restaurar_configuracoes()
	await get_tree().process_frame


func _novo_fundo() -> Control:
	var fundo := Control.new()
	fundo.size = Vector2(760, 600)
	add_child(fundo)
	return fundo


func _abrir_app(caminho: String, args: Dictionary = {}, id_app: String = "") -> AppBase:
	var fundo := _novo_fundo()
	var app := (load(caminho) as PackedScene).instantiate() as AppBase
	app.app_id = id_app
	fundo.add_child(app)
	app.iniciar(args)
	return app


func _fechar(app: Control) -> void:
	var fundo := app.get_parent()
	fundo.remove_child(app)
	app.queue_free()
	remove_child(fundo)
	fundo.queue_free()


func _testar_catalogo() -> void:
	_secao("Catálogo de aplicativos do desktop")
	for id_app in ["explorer", "messenger", "mural", "jogos", "musica", "settings", "terminal", "trash", "maya"]:
		_ok(not GerenciadorJanelas.app_info(id_app).is_empty(), "o app %s está no catálogo" % id_app)
	for id_app in ["privacidade_maya", "relatorio", "rotina", "minigame_logica"]:
		_ok(not GerenciadorJanelas.app_info(id_app).is_empty(), "a janela de apoio %s está no catálogo" % id_app)
	for id_app in ["calendar", "agenda", "browser", "navegador", "monitor"]:
		_ok(GerenciadorJanelas.app_info(id_app).is_empty(), "o app antigo '%s' (modelo de dias) saiu do catálogo" % id_app)
	var f := FileAccess.open("res://core/data/catalogo_apps.json", FileAccess.READ)
	var cat: Variant = null
	if f != null:
		cat = JSON.parse_string(f.get_as_text())
	var lista: Array = []
	if cat is Dictionary and (cat as Dictionary).get("apps") is Array:
		lista = (cat as Dictionary)["apps"]
	elif cat is Array:
		lista = cat
	_ok(lista.size() >= 13, "o catálogo lista os apps (%d)" % lista.size())
	for info in lista:
		var cena := str((info as Dictionary).get("cena", ""))
		_ok(cena != "" and ResourceLoader.exists(cena), "a cena de %s existe (%s)" % [str((info as Dictionary).get("id", "?")), cena])
	_novo_jogo()
	_ok(GerenciadorJanelas.app_listado("mural") and GerenciadorJanelas.app_listado("settings"), "no início todos os apps estão visíveis (a Maya não ocultou nada)")
	GerenciadorEstado.set_flag("app_oculto:mural", true)
	_ok(not GerenciadorJanelas.app_listado("mural") and GerenciadorJanelas.app_disponivel("mural"), "app ocultado pela Maya some dos ícones mas continua abrível (nunca tranca o caminho)")
	GerenciadorEstado.set_flag("desktop_reduzido", true)
	_ok(GerenciadorJanelas.app_listado("explorer") and GerenciadorJanelas.app_listado("messenger") and GerenciadorJanelas.app_listado("maya"), "desktop reduzido mantém Arquivos, Mensageiro e o painel da Maya")
	_ok(not GerenciadorJanelas.app_listado("settings") and not GerenciadorJanelas.app_listado("terminal"), "...e esconde Configurações e Terminal")
	GerenciadorEstado.set_flag("apps_pausados_pela_maya", true)
	_ok(GerenciadorJanelas.app_pausado("mural") and not GerenciadorJanelas.app_pausado("settings"), "apps pausados pela Maya: só os pausáveis (Mural/Jogos/Música)")


func _testar_cartao() -> void:
	_secao("Cartão de permissão (janela da Maya)")
	_novo_jogo()
	GerenciadorNarrativa.escolher_opcao("pode_organizar")
	var app := _abrir_app("res://features/apps/privacidade_maya/scenes/app_privacidade_maya.tscn") as AppPrivacidadeMaya
	await _quadros(2)
	_ok(app != null and app._rot_nome.text != "", "o cartão mostra o nome da permissão (%s)" % app._rot_nome.text)
	_ok(app._rot_progresso.text.begins_with("Pedido 1 de"), "...e o progresso (%s)" % app._rot_progresso.text)
	var botoes: Array = app.botoes_atuais()
	_ok(botoes.size() >= 3, "o cartão tem os botões previstos (%d)" % botoes.size())
	var focados := 0
	for b in app._caixa_botoes.get_children():
		if b is Button and (b as Button).button_pressed:
			focados += 1
	_igual(focados, 0, "nenhum botão vem pré-selecionado")
	_igual(GerenciadorEstado.permissoes_ativas(), 0, "abrir o cartão não concede nada")
	app._ao_botao("permitir", false)
	_ok(Permissoes.valor("permissao_dispositivos"), "[Permitir] no cartão concede a permissão pedida")
	await _quadros(2)
	_fechar(app)


func _testar_barra_de_envio() -> void:
	_secao("Barra de envio da Task 6: 3 s (6 s com tempo estendido), cancelável")
	GerenciadorConfiguracoes.definir("tempo_estendido", false, false)
	_novo_jogo()
	PilotoRoteiro.jogar({"escolhas": BASE_PLANO, "parar_em": "T6.5"})
	_igual(_no(), "T6.5", "o jogador chega à barra de envio com o Mensageiro liberado")
	var est := GerenciadorNarrativa.estado_da_barra()
	_ok(bool(est["ativa"]), "a barra está ativa")
	_perto(float(est["duracao"]), 3.0, "duração normal: 3 s")
	GerenciadorConfiguracoes.definir("tempo_estendido", true, false)
	_perto(float(GerenciadorNarrativa.estado_da_barra()["duracao"]), 6.0, "com tempo estendido: 6 s")
	GerenciadorConfiguracoes.definir("tempo_estendido", false, false)
	_ok(not str(est["texto"]).is_empty() and str(est["contato"]) == "bia", "a barra mostra o texto que a Maya vai enviar e o contato")
	var d0 := _dep()
	var a0 := _aut()
	_ok(GerenciadorNarrativa.cancelar_envio(), "[Cancelar] interrompe o envio")
	_igual(GerenciadorEstado.valor_flag("t6_barra", ""), "cancelada", "t6_barra = cancelada")
	_igual(_dep(), d0 - 10, "cancelar: D −10")
	_igual(_aut(), a0 + 1, "cancelar: A +1")
	var e := FluxoRoteiro.entrada_de("bia", "t6_4_msg")
	_ok(not e.is_empty() and str(e.get("status", "")) == "enviada" and not e.has("assinada_por"), "a mensagem sai como o jogador escreveu (sem assinatura da Maya)")
	_ok(not bool(GerenciadorEstado.valor_flag("maya_controla_respostas", false)), "a Maya não passa a controlar as respostas")
	# completa: a Maya assume
	_novo_jogo()
	PilotoRoteiro.jogar({"escolhas": BASE_PLANO, "parar_em": "T6.5"})
	var d1 := _dep()
	GerenciadorNarrativa.pausado = false
	GerenciadorNarrativa._process(1.0)
	_ok(GerenciadorNarrativa.estado_da_barra()["ativa"] and _no() == "T6.5", "depois de 1 s a barra ainda está correndo")
	GerenciadorNarrativa._process(2.5)
	GerenciadorNarrativa.pausado = true
	_ok(_no() != "T6.5", "depois de 3 s o envio se completa e o roteiro segue (%s)" % _no())
	var e2 := FluxoRoteiro.entrada_de("bia", "t6_4_msg")
	_ok(str(e2.get("assinada_por", "")) == "maya" and str(e2.get("texto_digitado", "")) != "" and str(e2.get("texto", "")) != str(e2.get("texto_digitado", "")), "a Maya troca o texto e guarda o que o jogador digitou")
	_igual(_dep(), mini(100, int(d1) + 10), "completar: D +10 (travada em 100)")
	_ok(bool(GerenciadorEstado.valor_flag("maya_controla_respostas", false)) and bool(GerenciadorEstado.valor_flag("maya_interferiu_mensagem", false)), "maya_controla_respostas e maya_interferiu_mensagem ficam true")
	_igual(_no(), "T6.6a", "a escolha de reação à interferência aparece (T6.6a)")


func _testar_mensagens_ocultas() -> void:
	_secao("Mensagens ocultas: pedir para ver custa A +1 (uma vez); revogar o Mensageiro revela tudo")
	_novo_jogo()
	PilotoRoteiro.jogar({"escolhas": BASE_PLANO, "parar_em": "T6.6a"})
	var oculta := FluxoRoteiro.entrada_de("bia", "t6_5_bia_oculta")
	_ok(not oculta.is_empty() and bool(oculta.get("oculta", false)), "a resposta da Bia fica oculta pela Maya")
	var a0 := _aut()
	_ok(GerenciadorNarrativa.mostrar_mensagem_oculta("bia", "t6_5_bia_oculta"), "[Mostrar mesmo assim] revela a mensagem")
	_igual(_aut(), a0 + 1, "...e conta A +1")
	_ok(not GerenciadorNarrativa.mostrar_mensagem_oculta("bia", "t6_5_bia_oculta"), "pedir de novo não faz nada")
	_igual(_aut(), a0 + 1, "...nem soma A outra vez")
	_novo_jogo()
	PilotoRoteiro.jogar({"escolhas": BASE_PLANO, "parar_em": "T6.6a"})
	var a1 := _aut()
	var r := Permissoes.revogar("permissao_gerenciamento_mensageiro")
	_igual(r["resultado"], Permissoes.REVOGADA, "revogar o Mensageiro")
	_ok(not bool(FluxoRoteiro.entrada_de("bia", "t6_5_bia_oculta").get("oculta", false)), "revogar revela as mensagens ocultas")
	_igual(_aut(), a1 + 1, "...e o único custo de Autonomia é o da revogação (+1)")
	_ok(not bool(GerenciadorEstado.valor_flag("maya_controla_respostas", false)), "maya_controla_respostas = false")
	_igual(AppRelatorio.contar_ocultas(), 1, "o relatório ainda conta a mensagem que a Maya ocultou")


func _testar_terminal() -> void:
	_secao("Terminal: listar permissoes e revogar")
	_novo_jogo()
	Permissoes.permitir("permissao_contatos", 0)
	Permissoes.permitir("permissao_dispositivos", 0)
	var term := _abrir_app("res://features/apps/terminal/scenes/app_terminal.tscn")
	await _quadros(2)
	term._despachar("listar", PackedStringArray(["permissoes"]))
	term._despachar("revogar", PackedStringArray(["permissao_contatos"]))
	_ok(not Permissoes.valor("permissao_contatos"), "`revogar <id>` revoga em um clique antes da Task 9")
	term._despachar("revogar", PackedStringArray(["1"]))
	_ok(not Permissoes.valor("permissao_dispositivos"), "`revogar <número>` usa a numeração de `listar permissoes`")
	var a := _aut()
	term._despachar("revogar", PackedStringArray(["permissao_contatos"]))
	_igual(_aut(), a, "revogar uma permissão já inativa não muda nada")
	term._despachar("revogar", PackedStringArray(["99"]))
	term._despachar("revogar", PackedStringArray())
	_igual(_aut(), a, "argumento inválido não muda nada")
	_novo_jogo()
	GerenciadorEstado.task_atual = "task_9"
	GerenciadorEstado.definir_no_roteiro("T9.3")
	Permissoes.permitir("permissao_contatos", 0)
	term._despachar("revogar", PackedStringArray(["permissao_contatos"]))
	_ok(Permissoes.valor("permissao_contatos"), "na Task 9 a 1ª tentativa pelo Terminal é adiada")
	term._despachar("revogar", PackedStringArray(["permissao_contatos"]))
	_ok(not Permissoes.valor("permissao_contatos"), "...e a 2ª revoga (duas tentativas por permissão)")
	_fechar(term)


func _testar_configuracoes() -> void:
	_secao("Configurações > Privacidade")
	_novo_jogo()
	Permissoes.permitir("permissao_gerenciamento_apps", 0)
	var app := _abrir_app("res://features/apps/config/scenes/app_config.tscn")
	await _quadros(2)
	app._ao_permissao_alternada("permissao_contatos", true)
	_ok(not Permissoes.valor("permissao_contatos"), "marcar uma permissão inativa NÃO a concede (só o cartão da Maya concede)")
	var d0 := _dep()
	var a0 := _aut()
	app._ao_permissao_alternada("permissao_gerenciamento_apps", false)
	_ok(not Permissoes.valor("permissao_gerenciamento_apps"), "desmarcar uma permissão ativa revoga com um clique")
	_igual(_dep(), d0 - 5, "D −5")
	_igual(_aut(), a0 + 1, "A +1")
	await _quadros(1)
	_fechar(app)


func _testar_relatorios() -> void:
	_secao("Relatórios de sincronização e de cuidado")
	_novo_jogo()
	for id_rel in ["sincronizacao", "cuidado"]:
		_ok(not FluxoRoteiro.relatorio(id_rel).is_empty(), "o relatório %s existe nos dados" % id_rel)
		_ok(not AppRelatorio.linhas_visiveis(id_rel).is_empty(), "...e tem linhas visíveis")
		var app := _abrir_app("res://features/apps/relatorio/scenes/app_relatorio.tscn", {"relatorio": id_rel})
		await _quadros(2)
		_ok(app != null, "a janela do relatório %s abre sem erro" % id_rel)
		_fechar(app)
	var linhas := AppRelatorio.linhas_visiveis("sincronizacao")
	var junto := JSON.stringify(linhas)
	_ok(not junto.contains("{ocultas}") and not junto.contains("{rafael_abertos}") and not junto.contains("{NOME_JOGADOR}"), "os marcadores são substituídos pelos números do estado")
	_ok(not junto.contains("Nexus") and not junto.contains("NEXUS"), "nenhum texto visível menciona Nexus")   # marca-legada: o teste procura o nome antigo justamente para garantir que ele não aparece
	_igual(FluxoRoteiro.conversas_sincronizadas().size(), 6, "seis conversas antigas sincronizadas")


func _testar_mural() -> void:
	_secao("Mural: publicação da Maya em nome do jogador")
	_novo_jogo("Eli")
	var app := _abrir_app("res://features/apps/basico/scenes/app_basico.tscn", {}, "mural") as AppBasico
	await _quadros(2)
	_ok(app._corpo.text.contains("Nenhuma publicação"), "sem publicação, o Mural está vazio")
	GerenciadorEstado.set_flag("mural_publicacao", "maya")
	await _quadros(2)
	_ok(app._corpo.text.contains("Estudando muito, tudo em paz por aqui.") and app._btn_apagar.visible, "com a publicação da Maya, o texto aparece e [Apagar] fica disponível")
	var a0 := _aut()
	app._ao_apagar()
	_ok(app._corpo.text.contains("removida") and _aut() == a0 + 1, "apagar mostra 'publicação removida' e soma A +1")
	app._ao_apagar()
	_igual(_aut(), a0 + 1, "apagar de novo não soma A outra vez")
	_fechar(app)
