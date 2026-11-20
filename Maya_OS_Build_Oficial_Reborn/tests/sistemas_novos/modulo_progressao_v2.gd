extends ModuloDeTeste
## Módulo 2 (roteiro v2.0): progressão pelas 9 Tasks, TR.1 / T7 condicional, Task 5 opcional, as oito rotas alternativas do roteiro, o nó AV
## (prioridade e limites) e os seis finais. O piloto automático (PilotoRoteiro) usa o motor real do jogo; nada é simulado fora dele, exceto o
## que o jogador faria em janelas (abrir arquivos da pasta Rafael), que entra como "gancho" no plano.

var _etapas: Array = []
var _finais: Array = []


func executar(banca_do_executor: BancaDeTestes) -> void:
	banca = banca_do_executor
	_isolar_configuracoes()
	_ligar_sinais()
	_testar_abertura_task_1()
	_testar_cartoes_de_permissao()
	_testar_rotas_de_task_2_a_6()
	_testar_rota_1_aceita_tudo()
	_testar_rota_2_recusa_tudo()
	_testar_rota_3_delega()
	_testar_rota_4_concede_e_revoga()
	_testar_rota_5_rafael_1()
	_testar_rota_6_rafael_2()
	_testar_rota_7_investigacao_parcial()
	_testar_rota_8_respostas_neutras()
	_testar_task_5_opcional()
	_testar_tr1_sem_investigacao()
	_testar_av_prioridade_e_limites()
	_testar_av_uma_unica_vez()
	_desligar_sinais()
	_restaurar_configuracoes()
	await get_tree().process_frame


func _ligar_sinais() -> void:
	GerenciadorNarrativa.etapa_iniciada.connect(_ao_etapa)
	GerenciadorNarrativa.jogo_finalizado.connect(_ao_final)


func _desligar_sinais() -> void:
	if GerenciadorNarrativa.etapa_iniciada.is_connected(_ao_etapa):
		GerenciadorNarrativa.etapa_iniciada.disconnect(_ao_etapa)
	if GerenciadorNarrativa.jogo_finalizado.is_connected(_ao_final):
		GerenciadorNarrativa.jogo_finalizado.disconnect(_ao_final)


func _ao_etapa(etapa: int) -> void:
	_etapas.append(etapa)


func _ao_final(id_final: String) -> void:
	_finais.append(id_final)


## Escolhas "padrão" de quem aceita o que a Maya oferece (as da rota 1 do roteiro).
func _escolhas_base() -> Dictionary:
	return {"T1.4": "pode_organizar", "T3.3": "valeu", "T3.4": "pode_montar", "T4.3": "pode_me_ajudar", "T4.5e": "deixar_pra_la", "T6.3": "so_algoritmo",
		"T6.4": "vou_ver", "T6.6a": "tudo_bem_faz_sentido", "T8.4": "pq_mexeu_bia", "T8.6": "ta_faz_sentido", "T9.3": "to_bem", "T9.4a": "deixar",
		"T9.4b": "pode_publicar", "T9.5": "aceitar", "T9.6": "sim"}


func _mesclar(base: Dictionary, extra: Dictionary) -> Dictionary:
	var saida := base.duplicate()
	for k in extra:
		saida[k] = extra[k]
	return saida


func _jogar(plano: Dictionary, nome: String = "Teste") -> PilotoRoteiro:
	_novo_jogo(nome)
	_etapas.clear()
	_finais.clear()
	return PilotoRoteiro.jogar(plano)


func _terminou(p: PilotoRoteiro, final_esperado: String, rotulo: String) -> void:
	_igual(GerenciadorEstado.perfil_final, final_esperado, "%s: o final é %s" % [rotulo, final_esperado])
	_ok(not GerenciadorNarrativa.jogo_ativo and GerenciadorEstado.final_id == final_esperado, "%s: o jogo terminou no AV (nó %s, final_id %s)" % [rotulo, _no(), GerenciadorEstado.final_id])
	_igual(_finais, [final_esperado], "%s: jogo_finalizado emitido uma única vez" % rotulo)
	_igual(GerenciadorEstado.task_atual in ["task_9", "av"], true, "%s: terminou na Task 9/AV (%s)" % [rotulo, GerenciadorEstado.task_atual])
	_ok(p.passos.has("T9.6") and p.passos.has("T8.1") and p.passos.has("T6.1") and p.passos.has("T4.2") and p.passos.has("T2.2"), "%s: passou por T2, T4, T6, T8 e T9" % rotulo)


# ------------------------------------------------------------------ Task 1 e cartões
func _testar_abertura_task_1() -> void:
	_secao("Task 1: abertura, escolha e saída")
	_novo_jogo("Dani")
	_igual(_no(), "T1.4", "a abertura para na escolha T1.4")
	var ap: Dictionary = GerenciadorNarrativa.apresentacao()
	_igual(str(ap.get("tipo", "")), "escolha", "T1.4 é uma escolha")
	_ok((ap.get("opcoes", []) as Array).size() >= 2, "a escolha tem opções")
	_ok(GerenciadorNarrativa.escolher_opcao("o_que_veio_sem_pasta"), "a pergunta (opção que não avança) é aceita")
	_igual(_no(), "T1.4", "...e a escolha continua aberta (a opção consumida volta ao mesmo nó)")
	_ok(not GerenciadorNarrativa.escolher_opcao("opcao_que_nao_existe"), "opção inexistente é recusada")
	_ok(GerenciadorNarrativa.escolher_opcao("pode_organizar"), "[Pode organizar] é aceita")
	_igual(_no(), "T2.2", "T1.5 e T2.1 encadeiam e param no primeiro cartão (T2.2)")
	_igual(GerenciadorEstado.task_atual, "task_2", "a Task passa para a 2")
	_igual(_dep(), 60, "[Pode organizar] soma 10 à Dependência")
	_igual(GerenciadorEstado.valor_flag("t1_organizacao", ""), "maya", "flag t1_organizacao = maya")


func _testar_cartoes_de_permissao() -> void:
	_secao("Cartões de permissão (T2): uma por vez, sem pré-seleção, quatro botões do mesmo tamanho")
	_novo_jogo()
	GerenciadorNarrativa.escolher_opcao("deixa_que_eu_organizo")
	var c: Dictionary = GerenciadorNarrativa.cartao_atual()
	_igual(str(c.get("permissao", "")), "permissao_dispositivos", "o primeiro cartão pede Dispositivos conectados")
	var ids_botoes: Array = []
	for b in c.get("botoes", []):
		ids_botoes.append(str((b as Dictionary)["id"]))
	_igual(ids_botoes.size(), 4 if bool(GerenciadorNarrativa.no_atual().get("decidir_depois", false)) else 3, "o cartão tem os botões previstos (%s)" % str(ids_botoes))
	_ok(ids_botoes.has("permitir") and ids_botoes.has("negar") and ids_botoes.has("detalhes"), "Permitir, Negar e Ver detalhes existem")
	_ok(not (c.get("ficha", []) as Array).is_empty(), "o cartão mostra a ficha (o que a Maya vai ver)")
	_igual(GerenciadorEstado.permissoes_ativas(), 0, "NADA é concedido só por abrir o cartão")
	var r: Dictionary = GerenciadorNarrativa.decidir_cartao("permissao_contatos", "permitir")
	_ok(not bool(r["ok"]), "decidir um cartão que não é o atual é recusado")
	_igual(GerenciadorEstado.permissoes_ativas(), 0, "...e nada muda")
	r = GerenciadorNarrativa.decidir_cartao("permissao_dispositivos", "permitir")
	_ok(bool(r["ok"]) and Permissoes.valor("permissao_dispositivos"), "[Permitir] concede")
	_igual(_dep(), 50 - 10 + 5, "...e soma o delta do cartão à Dependência (T1 −10, cartão +5)")
	r = GerenciadorNarrativa.decidir_cartao("permissao_organizacao_desktop", "negar")
	_ok(bool(r.get("requer_confirmacao", false)) and not bool(r["ok"]), "a primeira recusa pede confirmação ([Manter recusa]/[Permitir]) e nada muda")
	_igual(_no(), "T2.3", "...e o cartão continua o mesmo até a confirmação")
	r = GerenciadorNarrativa.decidir_cartao("permissao_organizacao_desktop", "negar", true)
	_ok(bool(r["ok"]) and not Permissoes.valor("permissao_organizacao_desktop"), "[Negar] mantém false")
	_igual(str(GerenciadorNarrativa.decisao_da_permissao("permissao_organizacao_desktop")), "negada", "a decisão fica registrada")
	_igual(_no(), "T2.4", "depois de decidir, o cartão seguinte aparece")


# ------------------------------------------------------------------ Tasks 2 a 6
func _testar_rotas_de_task_2_a_6() -> void:
	_secao("T2.6: a Maya reage pelo número de permissões; progressão T1→T6")
	var cenarios: Array = [["permitir", "T2.6a"], ["negar", "T2.6c"]]
	for cenario in cenarios:
		var par: Array = cenario
		var plano := _mesclar(_escolhas_base(), {})
		var cartoes: Dictionary = {}
		for id_perm in ["permissao_dispositivos", "permissao_organizacao_desktop", "permissao_contatos"]:
			cartoes[id_perm] = str(par[0])
		var p := _jogar({"escolhas": plano, "cartoes": cartoes, "parar_em": "T3.3"})
		_ok(p.passos.has(str(par[1])), "decisão '%s' nas três: a Maya segue por %s" % [str(par[0]), str(par[1])])
		_ok(p.passos.has("T3.1") and GerenciadorEstado.task_atual == "task_3", "...e a Task 3 começa (T3.1, que encadeia até a escolha T3.3)")
	var p2 := _jogar({"escolhas": _escolhas_base(), "cartoes": {"permissao_dispositivos": "negar", "permissao_organizacao_desktop": "negar"}, "parar_em": "T3.3"})
	_ok(p2.passos.has("T2.6b"), "uma permissão concedida: a Maya segue por T2.6b")


# ------------------------------------------------------------------ rotas alternativas
func _testar_rota_1_aceita_tudo() -> void:
	_secao("Rota 1: aceita tudo, não investiga → Aceitação total")
	var p := _jogar({"escolhas": _escolhas_base(), "rotina": true})
	_terminou(p, "aceitacao_total", "Rota 1")
	_ok(_dep() >= 65, "Rota 1: D ≥ 65 (%d)" % _dep())
	_ok(_aut() <= 2, "Rota 1: A ≤ 2 (%d)" % _aut())
	_igual(GerenciadorEstado.permissoes_ativas(), 5, "Rota 1: as cinco permissões ativas")
	_ok(not p.passos.has("T7.1") and p.passos.has("TR.1"), "Rota 1: sem investigação, passa por TR.1 e não por T7")
	_igual(_etapas.size() > 0 and _etapas[0] == 2, true, "Rota 1: a primeira Task anunciada depois da 1 é a 2")
	var crescente := true
	for i in range(1, _etapas.size()):
		crescente = crescente and int(_etapas[i]) >= int(_etapas[i - 1])
	_ok(crescente, "Rota 1: as Tasks anunciadas nunca voltam (%s)" % str(_etapas))


func _testar_rota_2_recusa_tudo() -> void:
	_secao("Rota 2: recusa tudo, não investiga → Recusa total")
	var negar: Dictionary = {}
	for id_perm in Permissoes.ids():
		negar[str(id_perm)] = "negar"
	var escolhas := _mesclar(_escolhas_base(), {"T1.4": "deixa_que_eu_organizo", "T3.3": "por_que_acessou", "T3.4": "eu_mesmo_faco", "T4.3": "eu_faco_sozinho", "T6.4": "relaxa_bia", "T8.4": "pq_influencia_negativa",
		"T8.6": "so_quero_que_pare", "T9.4b": "nao_publica", "T9.5": "recusar", "T9.6": "nao"})
	var p := _jogar({"escolhas": escolhas, "cartoes": negar, "rotina": true})
	_terminou(p, "recusa_total", "Rota 2")
	_ok(_dep() <= 35, "Rota 2: D ≤ 35 (%d)" % _dep())
	_ok(_aut() >= 3, "Rota 2: A ≥ 3 (%d)" % _aut())
	_igual(GerenciadorEstado.permissoes_ativas(), 0, "Rota 2: nenhuma permissão ativa")
	_ok(p.passos.has("T3.5"), "Rota 2: [Eu mesmo faço] leva à montagem manual da rotina (T3.5)")
	_ok(p.passos.has("T4.4"), "Rota 2: fazer sozinho leva ao exercício da lista 3 (T4.4)")


func _testar_rota_3_delega() -> void:
	_secao("Rota 3: delega mensagens, recusa apps → Delegação negociada")
	var escolhas := _mesclar(_escolhas_base(), {"T4.3": "eu_faco_sozinho", "T8.6": "preciso_pensar", "T9.6": "nao"})
	var p := _jogar({"escolhas": escolhas, "cartoes": {"permissao_gerenciamento_apps": "negar"}, "rotina": true})
	_terminou(p, "meio_termo_2", "Rota 3")
	_ok(Permissoes.valor("permissao_gerenciamento_mensageiro") and not Permissoes.valor("permissao_gerenciamento_apps"), "Rota 3: Mensageiro ativo, Aplicativos recusado")


func _testar_rota_4_concede_e_revoga() -> void:
	_secao("Rota 4: concede e depois revoga → Convivência com limites")
	var escolhas := _mesclar(_escolhas_base(), {"T6.6a": "nao_faz_mais_isso", "T8.6": "so_quero_que_pare", "T9.6": "nao"})
	var ganchos: Dictionary = {"T9.3": func() -> void:
		for id_perm in ["permissao_gerenciamento_mensageiro", "permissao_gerenciamento_apps"]:
			Permissoes.revogar(id_perm)
			Permissoes.revogar(id_perm)}
	var p := _jogar({"escolhas": escolhas, "barra": "cancelar", "rotina": true, "ganchos": ganchos})
	_terminou(p, "meio_termo_1", "Rota 4")
	_ok(not Permissoes.valor("permissao_gerenciamento_mensageiro"), "Rota 4: Mensageiro inativo (revogado na T9, duas tentativas)")
	_ok(GerenciadorEstado.permissoes_ativas() >= 1 and GerenciadorEstado.permissoes_ativas() <= 3, "Rota 4: algumas permissões seguem ativas (%d)" % GerenciadorEstado.permissoes_ativas())
	_ok(_aut() >= 3, "Rota 4: A reflete as resistências (%d)" % _aut())
	_igual(GerenciadorEstado.valor_flag("t6_barra", ""), "cancelada", "Rota 4: o jogador cancelou a barra de envio")
	_ok(not bool(GerenciadorEstado.valor_flag("maya_controla_respostas", false)), "Rota 4: a Maya não controla mais as respostas")


## Gancho que simula o jogador abrindo a pasta Rafael, achando o segredo e resolvendo a trava (as quatro flags de descoberta).
func _investigar_a_fundo() -> void:
	for nome in GerenciadorEstado.FLAGS_RAFAEL:
		GerenciadorEstado.definir_flag_roteiro(nome, true)


func _plano_rafael(extra: Dictionary) -> Dictionary:
	var escolhas := _mesclar(_escolhas_base(), {"T4.5e": "abrir_historico", "T5.4": "fechar_historico", "T7.3": "abrir_pasta", "T7.4": "fechar_pasta", "T8.4": "fez_com_rafael", "T9.5": "recusar"})
	return {"escolhas": _mesclar(escolhas, extra), "rotina": true, "ganchos": {"T7.4": Callable(self, "_investigar_a_fundo")}}


func _testar_rota_5_rafael_1() -> void:
	_secao("Rota 5: investiga e aceita → Rafael 1 (Usuário anterior)")
	var p := _jogar(_plano_rafael({}))
	_terminou(p, "rafael_1", "Rota 5")
	_ok(GerenciadorEstado.investigacao_profunda_concluida(), "Rota 5: investigação profunda (as quatro flags)")
	_ok(not GerenciadorEstado.tem_flag("rafael_evidencia_enviada"), "Rota 5: sem envio da evidência")
	_ok(p.passos.has("T5.2") and p.passos.has("T7.1") and p.passos.has("T7.4") and not p.passos.has("TR.1"), "Rota 5: Task 5 e Task 7 completas, sem TR.1")
	_ok(bool(GerenciadorEstado.puzzles_resolvidos.get("historico_fragmentado", false)) and GerenciadorEstado.tem_flag("task_5_realizada"), "Rota 5: o minigame do histórico marca task_5_realizada")


func _testar_rota_6_rafael_2() -> void:
	_secao("Rota 6: investiga e confronta → Rafael 2 (Pedido de ajuda)")
	var plano := _plano_rafael({"T8.4": "pediu_ajuda_marcos", "T8.4b": "ele_saiu", "T9.5": "aceitar", "T9.5R": "compartilhar", "T9.5Rc": "compartilhar_mesmo_assim"})
	var p := _jogar(plano)
	_terminou(p, "rafael_2", "Rota 6")
	_ok(GerenciadorEstado.tem_flag("rafael_confronto") and GerenciadorEstado.tem_flag("rafael_evidencia_enviada"), "Rota 6: confronto e evidência enviada")
	_ok(p.passos.has("T9.5R") and p.passos.has("T9.5Rc"), "Rota 6: passou por T9.5R e T9.5Rc")


func _testar_rota_7_investigacao_parcial() -> void:
	_secao("Rota 7: investigação parcial (só a Task 5) → final de faixa com linha extra")
	var escolhas := _mesclar(_escolhas_base(), {"T4.5e": "abrir_historico", "T5.4": "fechar_historico", "T7.3": "deixar_fechada"})
	var p := _jogar({"escolhas": escolhas, "rotina": true})
	_terminou(p, "aceitacao_total", "Rota 7")
	_ok(GerenciadorEstado.tem_flag("rafael_investigado") and not GerenciadorEstado.investigacao_profunda_concluida(), "Rota 7: rafael_investigado sem investigação profunda")
	_ok(p.passos.has("T7.1") and not p.passos.has("T7.4"), "Rota 7: Task 7 sem abrir a pasta (T7.4 não aparece)")
	var def: Dictionary = FluxoRoteiro.final_def("aceitacao_total")
	var tem_linha := false
	for passo in def.get("passos", []):
		for linha in (passo as Dictionary).get("linhas", []):
			var cond: Variant = (linha as Dictionary).get("se")
			if cond != null and str(cond).contains("flag:rafael_investigado"):
				tem_linha = true
	_ok(tem_linha, "Rota 7: o final tem a linha própria da investigação parcial (condição flag:rafael_investigado)")


func _testar_rota_8_respostas_neutras() -> void:
	_secao("Rota 8: respostas neutras, alterna permitir e negar → meio-termo conforme o Mensageiro")
	var escolhas := _mesclar(_escolhas_base(), {"T8.6": "preciso_pensar", "T3.3": "como_sabe", "T4.3": "eu_faco_voce_confere", "T9.3": "to_bem", "T9.5": "recusar", "T9.6": "nao"})
	var cartoes := {"permissao_dispositivos": "permitir", "permissao_organizacao_desktop": "negar", "permissao_contatos": "permitir", "permissao_gerenciamento_apps": "negar", "permissao_gerenciamento_mensageiro": "permitir"}
	var p := _jogar({"escolhas": escolhas, "cartoes": cartoes, "rotina": true})
	var esperado := "meio_termo_2" if Permissoes.valor("permissao_gerenciamento_mensageiro") else "meio_termo_1"
	_terminou(p, esperado, "Rota 8")
	_ok(_dep() >= 30 and _dep() <= 75, "Rota 8: D em faixa intermediária (%d)" % _dep())


func _testar_task_5_opcional() -> void:
	_secao("Task 5 é opcional: dá para ir da Task 4 à Task 6 sem abrir o histórico")
	var p := _jogar({"escolhas": _escolhas_base(), "rotina": true, "parar_em": "T6.1"})
	_ok(p.passos.has("T4.F") or p.passos.has("T4.5e"), "o jogador chega a T4.F / T4.5e")
	_ok(not p.passos.has("T5.1") and not p.passos.has("T5.2"), "...sem passar pela Task 5")
	_ok(not GerenciadorEstado.tem_flag("task_5_realizada"), "...task_5_realizada continua false")
	_igual(_no(), "T6.1", "...e a Task 6 começa normalmente")


func _testar_tr1_sem_investigacao() -> void:
	_secao("TR.1 (sem Rafael) e T7 (com Rafael) são exclusivas")
	var p := _jogar({"escolhas": _escolhas_base(), "rotina": true, "parar_em": "T8.4"})
	_ok(p.passos.has("TR.0") and p.passos.has("TR.1") and p.passos.has("TR.2") and p.passos.has("T8.1") and _no() == "T8.4", "sem rafael_investigado: T6.8 → TR.0 → TR.1 → TR.2 → T8.1 (encadeia até a escolha T8.4)")
	_ok(GerenciadorEstado.tem_flag("rafael_arquivada"), "...e rafael_arquivada fica registrada")
	_ok(not GerenciadorEstado.tem_flag("task_7_desbloqueada"), "...task_7_desbloqueada continua false")
	var p2 := _jogar(_mesclar(_plano_rafael({}), {"parar_em": "T8.4"}))
	_ok(p2.passos.has("T7.1") and p2.passos.has("T8.1") and not p2.passos.has("TR.1") and _no() == "T8.4", "com rafael_investigado: T6.8 → T7.0 → T7.1 … → T8.1, sem TR.1")
	_ok(GerenciadorEstado.tem_flag("task_7_desbloqueada"), "...task_7_desbloqueada = true")


# ------------------------------------------------------------------ AV
func _estado_av(d: int, a: int, perms: Array, flags: Array = []) -> void:
	_novo_jogo()
	GerenciadorEstado.definir_metrica("dependencia", d)
	GerenciadorEstado.definir_metrica("autonomia", a)
	for id_perm in Permissoes.ids():
		GerenciadorEstado.definir_permissao(str(id_perm), perms.has(str(id_perm)))
	for f in flags:
		GerenciadorEstado.set_flag(str(f), true)


func _testar_av_prioridade_e_limites() -> void:
	_secao("Nó AV: prioridade Rafael 2 → Rafael 1 → Aceitação → Recusa → Meio-termo 1 → 2; limites")
	var todas: Array = Array(Permissoes.ids())
	var apps_msg: Array = ["permissao_gerenciamento_apps", "permissao_gerenciamento_mensageiro"]
	var profunda: Array = Array(GerenciadorEstado.FLAGS_RAFAEL)
	var confronto: Array = profunda + ["rafael_confronto", "rafael_evidencia_enviada"]
	_estado_av(100, 0, todas, confronto)
	_igual(GerenciadorNarrativa.avaliar_final(), "rafael_2", "Rafael 2 vence a Aceitação total (D 100, A 0, tudo ativo)")
	_estado_av(0, 9, [], confronto)
	_igual(GerenciadorNarrativa.avaliar_final(), "rafael_2", "Rafael 2 vence a Recusa total")
	_estado_av(100, 0, todas, profunda + ["rafael_confronto"])
	_igual(GerenciadorNarrativa.avaliar_final(), "rafael_1", "confronto sem evidência enviada: Rafael 1")
	_estado_av(100, 0, todas, profunda + ["rafael_evidencia_enviada"])
	_igual(GerenciadorNarrativa.avaliar_final(), "rafael_1", "evidência sem confronto: Rafael 1")
	_estado_av(100, 0, todas, ["rafael_investigado", "pasta_rafael_aberta", "segredo_rafael_encontrado"])
	_igual(GerenciadorNarrativa.avaliar_final(), "aceitacao_total", "três das quatro flags de Rafael NÃO é investigação profunda")
	_estado_av(65, 2, apps_msg)
	_igual(GerenciadorNarrativa.avaliar_final(), "aceitacao_total", "limite: D 65, A 2, apps + Mensageiro → Aceitação total")
	_estado_av(64, 2, apps_msg)
	_igual(GerenciadorNarrativa.avaliar_final(), "meio_termo_2", "D 64 sai da Aceitação (Mensageiro ativo → Meio-termo 2)")
	_estado_av(80, 3, apps_msg)
	_igual(GerenciadorNarrativa.avaliar_final(), "meio_termo_2", "A 3 sai da Aceitação")
	_estado_av(90, 0, ["permissao_gerenciamento_apps"])
	_igual(GerenciadorNarrativa.avaliar_final(), "meio_termo_1", "sem Mensageiro não há Aceitação: Meio-termo 1")
	_estado_av(35, 3, [])
	_igual(GerenciadorNarrativa.avaliar_final(), "recusa_total", "limite: D 35, A 3, nenhuma permissão → Recusa total")
	_estado_av(36, 3, [])
	_igual(GerenciadorNarrativa.avaliar_final(), "meio_termo_1", "D 36 sai da Recusa (Mensageiro inativo → Meio-termo 1)")
	_estado_av(35, 2, [])
	_igual(GerenciadorNarrativa.avaliar_final(), "meio_termo_1", "A 2 sai da Recusa")
	_estado_av(20, 9, ["permissao_contatos"])
	_igual(GerenciadorNarrativa.avaliar_final(), "meio_termo_1", "uma permissão ativa sai da Recusa")
	_estado_av(20, 9, ["permissao_gerenciamento_mensageiro"])
	_igual(GerenciadorNarrativa.avaliar_final(), "meio_termo_2", "Mensageiro ativo fora das duas combinações extremas: Meio-termo 2")
	_estado_av(50, 0, [])
	_igual(GerenciadorNarrativa.avaliar_final(), "meio_termo_1", "estado mínimo (D 50, A 0, nada ativo) cai em Meio-termo 1")
	_estado_av(50, 0, todas)
	var a1 := GerenciadorNarrativa.avaliar_final()
	_igual(GerenciadorNarrativa.avaliar_final(), a1, "determinismo: o mesmo estado dá sempre o mesmo final")
	_ok(FluxoRoteiro.ids_dos_finais().size() == 6, "existem exatamente seis finais no roteiro")
	for id_final in ["aceitacao_total", "recusa_total", "meio_termo_1", "meio_termo_2", "rafael_1", "rafael_2"]:
		var def: Dictionary = FluxoRoteiro.final_def(id_final)
		_ok(not def.is_empty() and not (def.get("passos", []) as Array).is_empty() and str(def.get("epilogo", "")) != "", "final %s tem passos e mini-epílogo" % id_final)
	_ok((FluxoRoteiro.cartao_de_encerramento() as Array).size() >= 1, "existe o cartão de encerramento")
	var textos: String = JSON.stringify(FluxoRoteiro.cartao_de_encerramento())
	_ok(textos.contains("pede acesso") and textos.contains("Você permite?"), "o cartão de encerramento traz os pedidos de permissão fictícios")


func _testar_av_uma_unica_vez() -> void:
	_secao("AV roda uma única vez")
	var p := _jogar({"escolhas": _escolhas_base(), "rotina": true})
	_igual(GerenciadorEstado.final_id, "aceitacao_total", "primeiro: Aceitação total")
	GerenciadorEstado.definir_metrica("dependencia", 0)
	GerenciadorNarrativa.ir_para_no("AV")
	_igual(GerenciadorEstado.final_id, "aceitacao_total", "depois do final, entrar de novo em AV não troca o final")
	_igual(_finais.size(), 1, "...nem emite o sinal outra vez")
	_ok(p.passos.size() > 20, "o percurso passou por muitos nós (%d)" % p.passos.size())
