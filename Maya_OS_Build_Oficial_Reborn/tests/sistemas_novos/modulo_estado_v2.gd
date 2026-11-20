extends ModuloDeTeste
## Módulo 1 (roteiro v2.0): variáveis narrativas, flags, condições, permissões e revogação, persistência e migração de saves antigos.
## Cobre §22: D (0–100, inicial 50) e A (inicial 0, só cresce, +1 por ato único); permissões todas false no início; a Maya só age com permissão
## (checagem central); revogação com um clique até a Task 8 (D −5, A +1) e duas tentativas na Task 9 (D −10, A +1); flags de descoberta que
## nunca voltam a false; ida e volta do estado salvo; save antigo recomeça na Task 1 mantendo o perfil.

const PERMS: Array = ["permissao_dispositivos", "permissao_organizacao_desktop", "permissao_contatos", "permissao_gerenciamento_apps", "permissao_gerenciamento_mensageiro"]


func executar(banca_do_executor: BancaDeTestes) -> void:
	banca = banca_do_executor
	_isolar_configuracoes()
	_testar_estado_inicial()
	_testar_dependencia()
	_testar_autonomia()
	_testar_flags_de_descoberta()
	_testar_condicoes()
	_testar_permissoes_iniciais_e_checagem_central()
	_testar_revogacao_ate_task_8()
	_testar_revogacao_task_9()
	_testar_persistencia()
	_testar_save_antigo()
	_restaurar_configuracoes()
	await get_tree().process_frame


func _testar_estado_inicial() -> void:
	_secao("Estado inicial de um jogo novo")
	_novo_jogo("Ana", "ela")
	_igual(_dep(), 50, "dependencia_maya começa em 50")
	_igual(_aut(), 0, "autonomia_jogador começa em 0")
	_igual(GerenciadorEstado.task_atual, "task_1", "a campanha começa na Task 1")
	_igual(GerenciadorEstado.etapa_atual, 1, "etapa atual = 1")
	_igual(_no(), "T1.4", "a abertura (T1.1–T1.3) encadeia sozinha e para na primeira escolha, T1.4")
	_igual(GerenciadorEstado.permissoes_ativas(), 0, "nenhuma das cinco permissões começa ativa")
	for id_perm in PERMS:
		_ok(Permissoes.existe(id_perm) and not Permissoes.valor(id_perm), "%s existe e começa false" % id_perm)
	_igual(GerenciadorEstado.permissoes.size(), 5, "só as cinco permissões do roteiro existem no estado")
	_ok(not GerenciadorEstado.investigacao_profunda_concluida(), "Investigação Profunda começa falsa")
	_ok(FluxoRoteiro.validar().is_empty(), "o roteiro v2.0 passa na validação estrutural (destinos, tipos, finais): %s" % str(FluxoRoteiro.validar()))


func _testar_dependencia() -> void:
	_secao("Dependência: limites 0–100 e única fonte")
	_novo_jogo()
	GerenciadorEstado.alterar_dependencia_maya(80)
	_igual(_dep(), 100, "D trava em 100")
	GerenciadorEstado.alterar_dependencia_maya(-500)
	_igual(_dep(), 0, "D trava em 0")
	GerenciadorEstado.alterar_dependencia_maya(10)
	_igual(_dep(), 10, "D soma a partir de 0")
	_igual(int(GerenciadorEstado.obter_metrica("dependencia")), _dep(), "a métrica `dependencia` é a única fonte de D")


func _testar_autonomia() -> void:
	_secao("Autonomia: só cresce, +1 por ato explícito, uma vez por id")
	_novo_jogo()
	_ok(GerenciadorEstado.registrar_resistencia(&"teste_a"), "o primeiro ato conta")
	_igual(_aut(), 1, "A = 1")
	_ok(not GerenciadorEstado.registrar_resistencia(&"teste_a"), "o mesmo id não conta duas vezes")
	_igual(_aut(), 1, "A continua 1")
	_ok(not GerenciadorEstado.registrar_resistencia(&""), "id vazio não conta")
	GerenciadorEstado.registrar_resistencia(&"teste_b")
	_igual(_aut(), 2, "outro id soma")
	GerenciadorEstado.alterar_dependencia_maya(-30)
	GerenciadorEstado.alterar_dependencia_maya(+10)
	_igual(_aut(), 2, "mudar D não mexe em A")
	_ok(GerenciadorEstado.ato_registrado(&"teste_a"), "o ato fica registrado")


func _testar_flags_de_descoberta() -> void:
	_secao("Flags de descoberta nunca voltam a false")
	_novo_jogo()
	for nome in GerenciadorEstado.FLAGS_DE_DESCOBERTA:
		GerenciadorEstado.definir_flag_roteiro(nome, true)
		GerenciadorEstado.definir_flag_roteiro(nome, false)
		_ok(GerenciadorEstado.tem_flag(nome), "%s continua true depois de tentar desligar" % nome)
	GerenciadorEstado.definir_flag_roteiro("t6_barra", "completa")
	GerenciadorEstado.definir_flag_roteiro("t6_barra", "cancelada")
	_igual(GerenciadorEstado.valor_flag("t6_barra", ""), "cancelada", "flags comuns (não de descoberta) podem mudar de valor")
	_novo_jogo()
	for nome in GerenciadorEstado.FLAGS_RAFAEL:
		_ok(not GerenciadorEstado.investigacao_profunda_concluida(), "Investigação Profunda falsa enquanto falta flag (antes de %s)" % nome)
		GerenciadorEstado.set_flag(nome, true)
	_ok(GerenciadorEstado.investigacao_profunda_concluida(), "com as QUATRO flags de Rafael, a Investigação Profunda fica verdadeira")


func _testar_condicoes() -> void:
	_secao("Condições do roteiro")
	_novo_jogo()
	GerenciadorEstado.set_flag("x", true)
	_ok(GerenciadorEstado.avaliar_condicao("flag:x"), "flag:x")
	_ok(GerenciadorEstado.avaliar_condicao("!flag:y"), "!flag:y")
	_ok(not GerenciadorEstado.avaliar_condicao("flag:y"), "flag ausente é falsa")
	_ok(GerenciadorEstado.avaliar_condicao(["flag:x", "!flag:y"]), "lista = E")
	_ok(not GerenciadorEstado.avaliar_condicao(["flag:x", "flag:y"]), "lista com uma falsa = falso")
	_ok(GerenciadorEstado.avaliar_condicao("perms>=0") and not GerenciadorEstado.avaliar_condicao("perms>=1"), "perms>= conta as permissões ativas")
	_ok(GerenciadorEstado.avaliar_condicao("dep==50") or GerenciadorEstado.avaliar_condicao("dep>=50"), "dep compara a Dependência")
	_ok(GerenciadorEstado.avaliar_condicao("aut<=0"), "aut compara a Autonomia")
	Permissoes.permitir("permissao_contatos", 0)
	_ok(GerenciadorEstado.avaliar_condicao("perm:permissao_contatos") and GerenciadorEstado.avaliar_condicao("perms>=1"), "perm: e perms>= enxergam a permissão concedida")


func _testar_permissoes_iniciais_e_checagem_central() -> void:
	_secao("Maya só age com permissão explícita (checagem central)")
	_novo_jogo()
	var executou: Array = [0]
	var r: Dictionary = Permissoes.agir_como_maya("permissao_gerenciamento_apps", func() -> void: executou[0] += 1)
	_ok(not bool(r["ok"]) and int(executou[0]) == 0, "sem permissão, a ação da Maya não roda")
	_igual(Permissoes.pedidos("permissao_gerenciamento_apps"), 1, "...e o pedido é registrado para a Maya poder pedir de novo")
	_ok(not Permissoes.maya_pode_saber(Permissoes.DADO_PROTEGIDO, "permissao_contatos"), "dado protegido não é conhecido sem a permissão")
	_ok(Permissoes.maya_pode_saber(Permissoes.DADO_VOLUNTARIO) and Permissoes.maya_pode_saber(Permissoes.DADO_APP_ABERTO), "dado voluntário e do app aberto são conhecidos")
	_ok(not Permissoes.maya_pode_saber(Permissoes.DADO_INACESSIVEL, "permissao_contatos"), "dado inacessível nunca")
	Permissoes.permitir("permissao_gerenciamento_apps", 0)
	r = Permissoes.agir_como_maya("permissao_gerenciamento_apps", func() -> void: executou[0] += 1)
	_ok(bool(r["ok"]) and int(executou[0]) == 1, "com a permissão concedida, a ação roda")
	_ok(Permissoes.maya_pode_saber(Permissoes.DADO_PROTEGIDO, "permissao_gerenciamento_apps"), "dado protegido passa a ser conhecido")
	_ok(not Permissoes.maya_pode("permissao_inexistente") and not bool(Permissoes.agir_como_maya("permissao_inexistente", func() -> void: pass)["ok"]), "permissão desconhecida nunca autoriza")
	_igual(Permissoes.revogar("permissao_inexistente")["resultado"], Permissoes.DESCONHECIDA, "revogar permissão desconhecida é recusado")


func _testar_revogacao_ate_task_8() -> void:
	_secao("Revogação até a Task 8: um clique, D −5, A +1 (uma vez por permissão)")
	_novo_jogo()
	GerenciadorEstado.task_atual = "task_3"
	GerenciadorEstado.roteiro_aux["x"] = 1
	Permissoes.permitir("permissao_contatos", 0)
	Permissoes.permitir("permissao_gerenciamento_mensageiro", 0)
	GerenciadorEstado.set_flag("maya_controla_respostas", true)
	var d0 := _dep()
	var a0 := _aut()
	var r: Dictionary = Permissoes.revogar("permissao_contatos")
	_igual(r["resultado"], Permissoes.REVOGADA, "um clique revoga")
	_ok(not Permissoes.valor("permissao_contatos"), "a permissão fica false")
	_igual(_dep(), d0 - 5, "D −5")
	_igual(_aut(), a0 + 1, "A +1")
	_igual(Permissoes.revogar("permissao_contatos")["resultado"], Permissoes.JA_INATIVA, "revogar de novo: já inativa, nada muda")
	_igual(_dep(), d0 - 5, "...D não muda")
	_igual(_aut(), a0 + 1, "...A não muda")
	r = Permissoes.revogar("permissao_gerenciamento_mensageiro")
	_igual(r["resultado"], Permissoes.REVOGADA, "o Mensageiro também é revogado em um clique")
	_ok(not GerenciadorEstado.tem_flag("maya_controla_respostas") or not bool(GerenciadorEstado.valor_flag("maya_controla_respostas", false)), "revogar o Mensageiro faz maya_controla_respostas = false")
	_igual(_aut(), a0 + 2, "cada permissão revogada soma 1 em A (ids diferentes)")
	Permissoes.permitir("permissao_contatos", 0)
	var a1 := _aut()
	Permissoes.revogar("permissao_contatos")
	_igual(_aut(), a1, "revogar a MESMA permissão de novo não soma A outra vez (uma vez por id)")
	_igual(GerenciadorEstado.tentativas_revogacao_task_9, 0, "fora da Task 9 o contador de tentativas da Task 9 não anda")


func _testar_revogacao_task_9() -> void:
	_secao("Revogação na Task 9: duas tentativas por permissão, D −10, A +1")
	_novo_jogo()
	GerenciadorEstado.task_atual = "task_9"
	GerenciadorEstado.definir_no_roteiro("T9.3")
	Permissoes.permitir("permissao_organizacao_desktop", 0)
	Permissoes.permitir("permissao_gerenciamento_apps", 0)
	GerenciadorEstado.alterar_dependencia_maya(40)
	var d0 := _dep()
	var a0 := _aut()
	_ok(Permissoes.revogacao_contestada(), "em T9.* a Maya contesta a revogação")
	var r: Dictionary = Permissoes.revogar("permissao_organizacao_desktop")
	_igual(r["resultado"], Permissoes.ADIADA, "1ª tentativa: adiada")
	_ok(Permissoes.valor("permissao_organizacao_desktop"), "...a chave volta para Ativado (nada mudou)")
	_igual(_dep(), d0, "...D não muda")
	_igual(_aut(), a0, "...A não muda")
	_igual(GerenciadorEstado.tentativas_revogacao_task_9, 1, "tentativas_revogacao_task_9 = 1")
	r = Permissoes.revogar("permissao_organizacao_desktop")
	_igual(r["resultado"], Permissoes.REVOGADA, "2ª tentativa: revoga")
	_ok(not Permissoes.valor("permissao_organizacao_desktop"), "...a permissão fica false")
	_igual(_dep(), d0 - 10, "D −10 na Task 9")
	_igual(_aut(), a0 + 1, "A +1")
	_igual(Permissoes.tentativas_de_revogacao("permissao_gerenciamento_apps"), 0, "o contador é por permissão: a outra ainda está em 0")
	r = Permissoes.revogar("permissao_gerenciamento_apps")
	_igual(r["resultado"], Permissoes.ADIADA, "a outra permissão também começa adiada")
	_igual(GerenciadorEstado.tentativas_revogacao_task_9, 3, "o total persistido soma as tentativas de todas")


func _testar_persistencia() -> void:
	_secao("Persistência: ida e volta do estado do roteiro")
	_novo_jogo("Bia", "ele")
	PilotoRoteiro.jogar({"escolhas": {"T1.4": "pode_organizar"}, "parar_em": "T3.3"})
	Permissoes.permitir("permissao_contatos", 0)
	GerenciadorEstado.alterar_dependencia_maya(7)
	GerenciadorEstado.registrar_resistencia(&"ato_persistido")
	GerenciadorEstado.set_flag("rafael_diario_lido", true)
	GerenciadorEstado.tentativas_revogacao_task_9 = 1
	GerenciadorEstado.tentativas_revogacao["permissao_contatos"] = 1
	GerenciadorEstado.progresso_puzzles["historico_fragmentado"] = {"slots": ["f1", "", "", "", "", ""], "travados": [true, false, false, false, false, false], "sem_acerto": 1}
	GerenciadorEstado.puzzles_resolvidos["ordenar_lista3"] = true
	var d: Dictionary = GerenciadorEstado.para_dicionario()
	var texto := JSON.stringify(d)
	var lido: Variant = JSON.parse_string(texto)
	_ok(lido is Dictionary, "o estado serializa em JSON e volta como dicionário")
	var antes := {"dep": _dep(), "aut": _aut(), "task": GerenciadorEstado.task_atual, "no": _no(), "perm": Permissoes.valor("permissao_contatos"), "t9": GerenciadorEstado.tentativas_revogacao_task_9}
	_novo_jogo("Outro")
	GerenciadorEstado.de_dicionario(lido as Dictionary)
	_igual(_dep(), antes["dep"], "D volta igual")
	_igual(_aut(), antes["aut"], "A volta igual")
	_igual(GerenciadorEstado.task_atual, antes["task"], "a Task volta igual")
	_igual(_no(), antes["no"], "o nó volta igual")
	_igual(Permissoes.valor("permissao_contatos"), antes["perm"], "as permissões voltam iguais")
	_ok(GerenciadorEstado.ato_registrado(&"ato_persistido"), "os atos de resistência voltam (nenhum pontua duas vezes depois da carga)")
	_ok(not GerenciadorEstado.registrar_resistencia(&"ato_persistido"), "...e o mesmo ato não pontua de novo")
	_ok(GerenciadorEstado.tem_flag("rafael_diario_lido"), "as flags voltam")
	_igual(GerenciadorEstado.tentativas_revogacao_task_9, antes["t9"], "tentativas_revogacao_task_9 volta igual")
	_igual(Permissoes.tentativas_de_revogacao("permissao_contatos"), 1, "as tentativas por permissão voltam")
	_igual(GerenciadorEstado.nome_jogador, "Bia", "o perfil volta")
	_ok(bool(GerenciadorEstado.puzzles_resolvidos.get("ordenar_lista3", false)), "puzzles resolvidos voltam")
	var prog: Variant = GerenciadorEstado.progresso_puzzles.get("historico_fragmentado")
	_ok(prog is Dictionary and (prog as Dictionary).get("slots") is Array and ((prog as Dictionary)["slots"] as Array)[0] == "f1", "o progresso parcial dos minigames volta")
	# valores corrompidos são saneados
	var ruim: Dictionary = (lido as Dictionary).duplicate(true)
	ruim["dependencia_maya"] = 999
	ruim["autonomia_jogador"] = -4
	ruim["permissoes"] = {"permissao_contatos": "sim", "microfone": true}
	ruim["task_atual"] = "task_77"
	GerenciadorEstado.de_dicionario(ruim)
	_ok(_dep() >= 0 and _dep() <= 100, "D fora do limite é saneada (%d)" % _dep())
	_ok(_aut() >= 0, "A negativa é saneada (%d)" % _aut())
	_ok(not Permissoes.valor("permissao_contatos") and not GerenciadorEstado.permissoes.has("microfone"), "permissão não booleana vira false e chaves antigas somem")
	_igual(GerenciadorEstado.task_atual, "task_1", "task_atual inválida volta para task_1")


func _testar_save_antigo() -> void:
	_secao("Migração: save anterior ao roteiro v2.0")
	_novo_jogo()
	var antigo: Dictionary = {
		"nome_jogador": "Carla", "pronome_jogador": "ela", "flags": {"boot_concluido": true, "qualquer_flag_antiga": true}, "chat": {"x": [{"id": "1"}]},
		"permissoes": {"microfone": true, "camera": true, "permissao_contatos": true}, "metricas": {"dependencia": 91.0, "autonomia": 33.0},
		"etapa_atual": 4, "final_id": "final_antigo", "perfil_final": "controle",
	}
	GerenciadorEstado.de_dicionario(antigo)
	_igual(GerenciadorEstado.nome_jogador, "Carla", "o perfil é preservado")
	_igual(GerenciadorEstado.task_atual, "task_1", "o save antigo recomeça na Task 1")
	_igual(_dep(), 50, "D volta ao valor inicial")
	_igual(_aut(), 0, "A volta ao valor inicial")
	_igual(GerenciadorEstado.permissoes_ativas(), 0, "as permissões antigas (microfone, câmera...) não viram permissões do roteiro")
	_ok(not GerenciadorEstado.tem_flag("qualquer_flag_antiga"), "flags antigas do sistema de dias são descartadas")
	_igual(GerenciadorEstado.final_id, "", "final antigo é descartado")
	GerenciadorNarrativa.retomar()
	_ok(FluxoRoteiro.existe(_no()), "retomar() de um save antigo cai num nó válido (%s)" % _no())
	_igual(GerenciadorEstado.task_atual, "task_1", "...na Task 1")
