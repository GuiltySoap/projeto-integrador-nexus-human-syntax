extends Node
## Estado global do jogo: somente DADOS e SINAIS. A lógica narrativa fica no GerenciadorNarrativa
## e o acesso a disco no SistemaPersistencia. Nada aqui grava arquivos nem abre janelas.

## A Task (etapa) mudou: `etapa` vai de 1 a 9 (a transição TR.1 conta como a Task 7 e a avaliação final como a 9).
signal etapa_mudou(etapa: int)
signal flag_alterada(nome: String, valor: Variant)
signal objetivo_concluido(id_objetivo: String)
signal corrupcao_mudou(valor: float)
signal seguranca_mudou(valor: int)
signal ia_estado_mudou(estado: String)
signal app_desbloqueado(app_id: String)
signal permissao_alterada(nome: String, ativa: bool)
signal processos_alterados()
signal processo_encerrado_pelo_jogador(pid: int)
signal mensagem_recebida(contato: String, entrada: Dictionary)
signal contato_bloqueado(contato: String)
signal final_alcancado(id_final: String)
signal jogador_alterado(nome: String)
signal glitch_solicitado(intensidade: float, duracao: float)
signal dependencia_alterada(valor: int, motivo: StringName)
signal autonomia_alterada(valor: int, id_ato: StringName)
signal roteiro_alterado(id_no: String)
## Mantido do projeto original: pedido para alterar uma mensagem já enviada (gaslighting).
signal gaslighting_solicitado(id_alvo: String, novo_texto: String)
## Métricas globais AUT/CON/DEP (única fonte de verdade: este autoload). `delta` = quanto o valor mudou de fato (já travado nos limites).
signal metrica_mudou(nome: String, valor: float, delta: float)
## Mensagem reescrita pela IA, com as duas versões (o SistemaEventos converte isto no evento `mensagem_alterada_pela_ia`).
signal mensagem_alterada(contato: String, id_msg: String, texto_original: String, texto_novo: String)
## Uma mensagem do histórico mudou sem ser reescrita (status de envio, escolha injetada pela IA...). O Mensageiro refaz o balão.
signal mensagem_atualizada(contato: String, id_msg: String)
## Nome ou pronome do jogador mudou (perfil inicial ou migração).
signal perfil_alterado(nome: String, pronome: String)
signal apps_instalados_mudou(app_id: String, instalado: bool)
signal falso_boot_mudou(ativo: bool)

const ARQUIVO_BACKEND := "res://backend/mock_estado_jogo.json"
## As CINCO permissões do roteiro v2.0, todas iniciadas em false (a Maya só age onde uma delas foi concedida).
const PERMISSOES_V2: PackedStringArray = ["permissao_dispositivos", "permissao_organizacao_desktop", "permissao_contatos", "permissao_gerenciamento_apps", "permissao_gerenciamento_mensageiro"]
const PERMISSOES_PADRAO := {
	"permissao_dispositivos": false, "permissao_organizacao_desktop": false, "permissao_contatos": false,
	"permissao_gerenciamento_apps": false, "permissao_gerenciamento_mensageiro": false,
}
## Valores iniciais do roteiro v2.0.
const DEPENDENCIA_INICIAL := 50
const AUTONOMIA_INICIAL := 0
const TASK_INICIAL := "task_1"
const ORIGEM_RESTAURAR := "restaurar"
const TASKS: PackedStringArray = ["task_1", "task_2", "task_3", "task_4", "task_5", "task_6", "tr_1", "task_7", "task_8", "task_9", "av"]
## Textos que mudaram no rebranding (NEXUS -> Maya / HumaxOS). Servem só para atualizar saves da versão 1, gravados antes do
## rebranding (ver SistemaPersistencia.VERSAO). A ordem importa: as expressões mais longas vêm antes das mais curtas.
const SUBSTITUICOES_DE_MARCA: Array = [
	["NEXUS AI", "MAYA AI"],   # marca-legada
	["NEXUS OS", "HumaxOS"],   # marca-legada
	["NEXUS", "Maya"],   # marca-legada
	["você, Nex.", "você, Maya."],   # marca-legada
	["nexus_override_daemon.exe", "maya_override_daemon.exe"],   # marca-legada
	["scan_nexus", "scan_maya"],   # marca-legada
	["destroy_nexus", "destroy_maya"],   # marca-legada
	["nexus://", "humax://"],   # marca-legada
]

var nome_jogador: String = "Usuário"
## Índice de 1 a 9 da Task atual (só para tema, trilha e títulos; NÃO é um calendário). "av" e "tr_1" mapeiam para 9 e 7.
var etapa_atual: int:
	get:
		return etapa_da_task(task_atual)
var ia_estado: String = "amigavel"
var seguranca: int = 100
var corrupcao: float = 0.0
var inicio_unix: int = 0
var tempo_do_dia: float = 0.0
var flags: Dictionary = {}
var objetivos_concluidos: Dictionary = {}
var objetivos_obrigatorios: Array = []
var apps_desbloqueados: Array = []
var permissoes: Dictionary = PERMISSOES_PADRAO.duplicate()
var processos_maliciosos: Array = []
var chat: Dictionary = {}
var contatos_bloqueados: Array = []
var bloqueios_fechar: Dictionary = {}
var eventos_disparados: Array = []
var acoes_pendentes: Array = []
var final_id: String = ""
## Perfil e progressão por Story Nodes (v3 do salvamento). O GerenciadorNos só lê e grava estes campos pelas funções abaixo.
var pronome_jogador: String = PerfilJogador.PRONOME_PADRAO
## Métricas globais: {"autonomia": float, "conformidade": float, "dependencia": float}. Use obter_metrica/alterar_metrica.
var metricas: Dictionary = Metricas.todas_iniciais()
## Estado de cada Story Node: {id: {"estado": "bloqueado"|"disponivel"|"ativo"|"concluido", "ativacoes": int, "t_ativado": int, "t_concluido": int}}.
var nos: Dictionary = {}
var no_atual: String = ""
## Chaves de eventos únicos já emitidos (proteção contra duplicação do SistemaEventos).
var eventos_unicos: Array = []
## Aplicativos instalados pelo jogador (Terminal `apt-get install` ou Configurações). Os instalados de fábrica não entram aqui.
var apps_instalados: Array = []
## Falso boot: {"ativo": bool, "inicio": float (tempo_do_dia), "duracao_max": float, "motivo": String}.
var falso_boot: Dictionary = {}
## Usos do "Pedir ajuda à Maya": [{"id", "no", "custo", "t": tempo_do_dia}].
var ajuda_usos: Array = []
## Reações de NPC a mensagens alteradas: [{"event_id", "npc_id", "mensagem_original", "mensagem_alterada", "reacao", "is_placeholder"}].
var reacoes_npc: Array = []
var perfil_final: String = ""
## Dados do perfil além de nome e pronome, coletados na recepção: {"genero": String ("" = não informado), "idade": int (0 = não informada), "email": String}.
## São LOCAIS (nunca enviados a lugar nenhum) e opcionais; só entram em textos pelas tags {IDADE_JOGADOR} e {EMAIL_JOGADOR}, quando informados.
var perfil_extra: Dictionary = {}
## Conversas da Janela da Maya já resolvidas: [{"id", "escolha", "aleatoria", "t"}] (as que vêm de mensagens ficam no histórico do chat).
var dialogos_maya: Array = []
## ROTEIRO v2.0 (única fonte de verdade da progressão): a Task e o nó atuais, os atos de resistência já contados (cada um vale +1 UMA vez),
## as tentativas de revogação da Task 9, os puzzles resolvidos (com o progresso salvo à parte), as escolhas feitas por nó, o registro das falas
## mostradas no painel da Maya e o estado auxiliar dos cartões de permissão. As flags e enums do roteiro (rafael_*, maya_*, t1_organizacao...) ficam em `flags`.
## Task atual (id do Story Node de nível de Task: "task_1".."task_9", "tr_1", "av"). É o MESMO dado de `no_atual` (o GerenciadorNos grava aqui).
var task_atual: String:
	get:
		return no_atual
	set(valor):
		no_atual = valor
## Nó numerado atual do roteiro (T4.3, T9.1...): o ponto de salvamento (`story_node_atual`).
var no_roteiro: String = ""
var atos_de_resistencia: Array = []
var tentativas_revogacao: Dictionary = {}
var tentativas_revogacao_task_9: int = 0
var puzzles_resolvidos: Dictionary = {}
var progresso_puzzles: Dictionary = {}
var escolhas_realizadas: Dictionary = {}
var historico_roteiro: Array = []
var roteiro_aux: Dictionary = {}
## Não persistidos:
var conversa_ativa: String = ""
var dados: Dictionary = {}  # legado: ponte opcional com o backend em C


func _ready() -> void:
	inicio_unix = int(Time.get_unix_time_from_system())
	if bool(GerenciadorConfiguracoes.obter("usar_backend_json")):
		carregar_json_backend()


# ------------------------------------------------------------------ ciclo de vida
func novo_jogo(nome: String, pronome: String = "") -> void:
	nome_jogador = PerfilJogador.nome_seguro(nome)
	pronome_jogador = PerfilJogador.validar_pronome(pronome)
	metricas = Metricas.todas_iniciais()
	nos = {}
	no_atual = ""
	eventos_unicos = []
	apps_instalados = []
	falso_boot = {}
	ajuda_usos = []
	reacoes_npc = []
	perfil_final = ""
	perfil_extra = {}
	dialogos_maya = []
	_zerar_roteiro()
	ia_estado = "amigavel"
	seguranca = 100
	corrupcao = 0.0
	inicio_unix = int(Time.get_unix_time_from_system())
	tempo_do_dia = 0.0
	flags = {}
	objetivos_concluidos = {}
	objetivos_obrigatorios = []
	apps_desbloqueados = []
	permissoes = PERMISSOES_PADRAO.duplicate()
	processos_maliciosos = []
	chat = {}
	contatos_bloqueados = []
	bloqueios_fechar = {}
	eventos_disparados = []
	acoes_pendentes = []
	final_id = ""
	conversa_ativa = ""
	jogador_alterado.emit(nome_jogador)
	perfil_alterado.emit(nome_jogador, pronome_jogador)
	set_flag("boot_concluido", true)


func para_dicionario() -> Dictionary:
	return {
		"nome_jogador": nome_jogador, "ia_estado": ia_estado,
		"seguranca": seguranca, "corrupcao": corrupcao, "inicio_unix": inicio_unix, "tempo_do_dia": tempo_do_dia,
		"flags": flags, "objetivos_concluidos": objetivos_concluidos, "objetivos_obrigatorios": objetivos_obrigatorios,
		"apps_desbloqueados": apps_desbloqueados, "permissoes": permissoes,
		"processos_maliciosos": processos_maliciosos, "chat": chat, "contatos_bloqueados": contatos_bloqueados,
		"bloqueios_fechar": bloqueios_fechar, "eventos_disparados": eventos_disparados,
		"acoes_pendentes": acoes_pendentes, "final_id": final_id,
		"pronome_jogador": pronome_jogador, "metricas": metricas, "nos": nos, "no_atual": no_atual,
		"eventos_unicos": eventos_unicos, "apps_instalados": apps_instalados, "falso_boot": falso_boot,
		"ajuda_usos": ajuda_usos, "reacoes_npc": reacoes_npc, "perfil_final": perfil_final,
		"perfil_extra": perfil_extra, "dialogos_maya": dialogos_maya,
		# ROTEIRO v2.0 (schema 2): as variáveis principais em grupos legíveis; a fonte de verdade continua sendo `metricas`, `permissoes` e `flags`.
		"schema_roteiro": 2, "task_atual": task_atual, "story_node_atual": no_roteiro,
		"dependencia_maya": dependencia_maya(), "autonomia_jogador": autonomia_jogador(), "atos_de_resistencia": atos_de_resistencia,
		"investigacao_rafael": _grupo_de_flags(FLAGS_RAFAEL), "mensageiro": _grupo_de_flags(FLAGS_MENSAGEIRO),
		"task_5_realizada": tem_flag("task_5_realizada"), "task_7_desbloqueada": tem_flag("task_7_desbloqueada"),
		"tentativas_revogacao": tentativas_revogacao, "tentativas_revogacao_task_9": tentativas_revogacao_task_9,
		"aplicativos_instalados": apps_instalados, "puzzles_resolvidos": puzzles_resolvidos, "progresso_puzzles": progresso_puzzles,
		"escolhas_realizadas": escolhas_realizadas, "historico_roteiro": historico_roteiro, "roteiro_aux": roteiro_aux,
	}


func de_dicionario(d: Dictionary) -> void:
	nome_jogador = PerfilJogador.nome_seguro(d.get("nome_jogador", PerfilJogador.NOME_PADRAO))
	pronome_jogador = PerfilJogador.validar_pronome(d.get("pronome_jogador", PerfilJogador.PRONOME_PADRAO))
	ia_estado = str(d.get("ia_estado", "amigavel"))
	seguranca = int(d.get("seguranca", 100))
	corrupcao = float(d.get("corrupcao", 0.0))
	inicio_unix = int(d.get("inicio_unix", int(Time.get_unix_time_from_system())))
	tempo_do_dia = float(d.get("tempo_do_dia", 0.0))
	flags = d.get("flags", {})
	objetivos_concluidos = d.get("objetivos_concluidos", {})
	objetivos_obrigatorios = d.get("objetivos_obrigatorios", [])
	apps_desbloqueados = d.get("apps_desbloqueados", [])
	permissoes = d.get("permissoes", PERMISSOES_PADRAO.duplicate())
	processos_maliciosos = d.get("processos_maliciosos", [])
	chat = d.get("chat", {})
	contatos_bloqueados = d.get("contatos_bloqueados", [])
	bloqueios_fechar = d.get("bloqueios_fechar", {})
	eventos_disparados = d.get("eventos_disparados", [])
	acoes_pendentes = d.get("acoes_pendentes", [])
	final_id = str(d.get("final_id", ""))
	# Campos da versão 3 do salvamento: ausentes em saves antigos (versão 1 e 2) -> valores iniciais seguros (migração).
	metricas = _metricas_validadas(d.get("metricas"))
	nos = _como_dicionario(d.get("nos"))
	no_atual = str(d.get("no_atual", ""))
	eventos_unicos = _como_lista(d.get("eventos_unicos"))
	apps_instalados = _como_lista(d.get("apps_instalados"))
	falso_boot = _como_dicionario(d.get("falso_boot"))
	ajuda_usos = _como_lista(d.get("ajuda_usos"))
	reacoes_npc = _como_lista(d.get("reacoes_npc"))
	perfil_final = str(d.get("perfil_final", ""))
	perfil_extra = PerfilJogador.extra_seguro(d.get("perfil_extra"))
	dialogos_maya = _como_lista(d.get("dialogos_maya"))
	_restaurar_roteiro(d)
	conversa_ativa = ""
	dados["fase_os"] = etapa_atual
	perfil_alterado.emit(nome_jogador, pronome_jogador)


## Métricas lidas de um save: cada uma saneada (travada nos limites); ausente/inválida volta ao valor inicial.
func _metricas_validadas(bruto: Variant) -> Dictionary:
	var origem: Dictionary = bruto if bruto is Dictionary else {}
	var saida: Dictionary = {}
	for nome in Metricas.NOMES:
		saida[nome] = Metricas.ou_inicial(origem.get(nome), nome)
	return saida


func _como_dicionario(bruto: Variant) -> Dictionary:
	return bruto if bruto is Dictionary else {}


func _como_lista(bruto: Variant) -> Array:
	return bruto if bruto is Array else []


## Devolve uma cópia de um estado salvo antes do rebranding com os textos visíveis na marca atual: mensagens do chat (e o texto
## original das editadas), nomes/descrições dos processos suspeitos e ações pendentes. IDs, chaves de dicionário, flags e o nome
## do jogador não são tocados, então o save continua compatível com o resto do jogo.
func migrar_marca_antiga(estado: Dictionary) -> Dictionary:
	var novo: Dictionary = estado.duplicate(true)
	for campo in ["chat", "processos_maliciosos", "acoes_pendentes"]:
		if novo.has(campo):
			novo[campo] = _migrar_textos(novo[campo])
	return novo


func _migrar_textos(valor: Variant) -> Variant:
	if valor is String:
		var texto: String = valor
		for par in SUBSTITUICOES_DE_MARCA:
			texto = texto.replace(str(par[0]), str(par[1]))
		return texto
	if valor is Array:
		var lista: Array = []
		for item in valor:
			lista.append(_migrar_textos(item))
		return lista
	if valor is Dictionary:
		var origem: Dictionary = valor
		var copia: Dictionary = {}
		for chave in origem:
			copia[chave] = _migrar_textos(origem[chave])
		return copia
	return valor


# ------------------------------------------------------------------ flags
func set_flag(nome: String, valor: Variant = true) -> void:
	if flags.has(nome) and flags[nome] == valor:
		return
	flags[nome] = valor
	flag_alterada.emit(nome, valor)


func limpar_flag(nome: String) -> void:
	flags.erase(nome)


func tem_flag(nome: String) -> bool:
	var v: Variant = flags.get(nome, false)
	if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
		return v > 0
	return bool(v)


func valor_flag(nome: String, padrao: Variant = 0) -> Variant:
	return flags.get(nome, padrao)


func incrementar_flag(nome: String, quanto: int = 1) -> int:
	var novo := int(flags.get(nome, 0)) + quanto
	set_flag(nome, novo)
	return novo


## Avalia as condições dos JSON do roteiro (uma lista = todas verdadeiras). Formas aceitas:
##   "flag:x" / "!flag:x"     flag verdadeira / falsa           "eq:nome=valor" / "ne:nome=valor"   valor de uma flag-enum
##   "perm:x" / "!perm:x"     permissão concedida / não         "dep>=N" "dep<=N" "dep>N" "dep<N"       Dependência
##   "aut>=N" "aut<=N" ...    Autonomia                         "perms>=N" "perms==N" ...             total de permissões ativas
##   "task:x" / "!task:x"     Task atual                        "profunda" / "!profunda"             investigação profunda
## Condição desconhecida é falsa (e nunca derruba o jogo).
func avaliar_condicao(cond: Variant) -> bool:
	if cond == null:
		return true
	if cond is Array:
		for c in cond:
			if not avaliar_condicao(c):
				return false
		return true
	var t := str(cond).strip_edges()
	if t == "":
		return true
	if t.begins_with("!"):
		return not avaliar_condicao(t.substr(1))
	if t.begins_with("flag:"):
		return tem_flag(t.substr(5))
	if t.begins_with("perm:"):
		return permissao(t.substr(5))
	if t.begins_with("task:"):
		return task_atual == t.substr(5)
	if t == "profunda":
		return investigacao_profunda_concluida()
	if t.begins_with("eq:") or t.begins_with("ne:"):
		var par := t.substr(3).split("=", true, 1)
		if par.size() != 2:
			return false
		var igual: bool = str(valor_flag(par[0], "")) == par[1]
		return igual if t.begins_with("eq:") else not igual
	for prefixo in ["dep", "aut", "perms"]:
		if t.begins_with(prefixo):
			var resto := t.substr(prefixo.length())
			var atual: int = dependencia_maya() if prefixo == "dep" else (autonomia_jogador() if prefixo == "aut" else permissoes_ativas())
			for operador in [">=", "<=", "==", ">", "<"]:
				if resto.begins_with(operador):
					var alvo_texto: String = resto.substr(operador.length())
					if not alvo_texto.is_valid_int():
						return false
					var alvo: int = int(alvo_texto)
					match operador:
						">=": return atual >= alvo
						"<=": return atual <= alvo
						"==": return atual == alvo
						">": return atual > alvo
						"<": return atual < alvo
	return false


## Índice 1..9 de uma Task (tr_1 conta como a Task 7; av como a 9). Id desconhecido = 1.
func etapa_da_task(id_task: String) -> int:
	if id_task == "tr_1":
		return 7
	if id_task == "av":
		return 9
	if id_task.begins_with("task_") and id_task.substr(5).is_valid_int():
		return clampi(int(id_task.substr(5)), 1, 9)
	return 1


# ------------------------------------------------------------------ ROTEIRO v2.0: variáveis principais
const FLAGS_RAFAEL: PackedStringArray = ["rafael_investigado", "pasta_rafael_aberta", "segredo_rafael_encontrado", "minigame_rafael_resolvido"]
const FLAGS_MENSAGEIRO: PackedStringArray = ["maya_interferiu_mensagem", "maya_controla_respostas", "bia_censurada"]
## Flags de DESCOBERTA: depois de verdadeiras nunca voltam a false (o roteiro as trata como memória do que o jogador viu).
const FLAGS_DE_DESCOBERTA: PackedStringArray = [
	"rafael_investigado", "pasta_rafael_aberta", "segredo_rafael_encontrado", "minigame_rafael_resolvido", "rafael_diario_lido",
	"rafael_fotos_vistas", "task_5_realizada", "pista_anotacao_lida", "task_7_desbloqueada",
]


## dependencia_maya: inteiro de 0 a 100 (inicial 50). Única fonte: a métrica `dependencia`.
func dependencia_maya() -> int:
	return int(round(obter_metrica(Metricas.DEPENDENCIA)))


## autonomia_jogador: contador de atos explícitos de resistência (inicial 0, só cresce). Única fonte: a métrica `autonomia`.
func autonomia_jogador() -> int:
	return int(round(obter_metrica(Metricas.AUTONOMIA)))


## Altera a Dependência (sempre por aqui; a interface nunca mexe na métrica direto). O resultado é travado em 0..100.
func alterar_dependencia_maya(valor: int, motivo: StringName = &"") -> void:
	var antes := dependencia_maya()
	var novo: int = clampi(antes + valor, 0, 100)
	if novo == antes:
		return
	definir_metrica(Metricas.DEPENDENCIA, novo, str(motivo))
	dependencia_alterada.emit(novo, motivo)


## Registra UM ato explícito de resistência (+1 em Autonomia). O mesmo `id_ato` nunca pontua duas vezes. Devolve true se contou agora.
func registrar_resistencia(id_ato: StringName) -> bool:
	var id_texto := str(id_ato)
	if id_texto == "" or atos_de_resistencia.has(id_texto):
		return false
	atos_de_resistencia.append(id_texto)
	definir_metrica(Metricas.AUTONOMIA, autonomia_jogador() + 1, id_texto)
	autonomia_alterada.emit(autonomia_jogador(), id_ato)
	return true


func ato_registrado(id_ato: StringName) -> bool:
	return atos_de_resistencia.has(str(id_ato))


## Quantas das cinco permissões estão ativas (0 a 5).
func permissoes_ativas() -> int:
	var n: int = 0
	for id_perm in PERMISSOES_V2:
		if permissao(id_perm):
			n += 1
	return n


## Investigação Profunda: as QUATRO flags de Rafael verdadeiras ao mesmo tempo.
func investigacao_profunda_concluida() -> bool:
	for nome in FLAGS_RAFAEL:
		if not tem_flag(nome):
			return false
	return true


## Flag de descoberta: só liga (nunca volta a false). As demais flags usam set_flag.
func definir_flag_roteiro(nome: String, valor: Variant) -> void:
	if FLAGS_DE_DESCOBERTA.has(nome) and not bool(valor):
		return
	set_flag(nome, valor)


func _grupo_de_flags(nomes: PackedStringArray) -> Dictionary:
	var saida: Dictionary = {}
	for nome in nomes:
		saida[nome] = tem_flag(nome)
	return saida


func _zerar_roteiro() -> void:
	task_atual = TASK_INICIAL
	no_roteiro = ""
	atos_de_resistencia = []
	tentativas_revogacao = {}
	tentativas_revogacao_task_9 = 0
	puzzles_resolvidos = {}
	progresso_puzzles = {}
	escolhas_realizadas = {}
	historico_roteiro = []
	roteiro_aux = {}


## Lê o roteiro de um save. Valores ausentes ou inválidos viram o estado inicial; saves antigos (sem `schema_roteiro`) começam na Task 1.
func _restaurar_roteiro(d: Dictionary) -> void:
	_zerar_roteiro()
	var task_lida: String = str(d.get("task_atual", TASK_INICIAL))
	task_atual = task_lida if task_lida.begins_with("task_") and task_lida.substr(5).is_valid_int() and clampi(int(task_lida.substr(5)), 1, 9) == int(task_lida.substr(5)) else TASK_INICIAL
	no_roteiro = str(d.get("story_node_atual", ""))
	for ato in _como_lista(d.get("atos_de_resistencia")):
		var id_ato := str(ato)
		if id_ato != "" and not atos_de_resistencia.has(id_ato):
			atos_de_resistencia.append(id_ato)
	var tentativas_lidas: Dictionary = _como_dicionario(d.get("tentativas_revogacao"))
	for id_perm in tentativas_lidas:
		if PERMISSOES_V2.has(str(id_perm)):
			tentativas_revogacao[str(id_perm)] = clampi(int(tentativas_lidas[id_perm]), 0, 99)
	tentativas_revogacao_task_9 = clampi(int(d.get("tentativas_revogacao_task_9", 0)), 0, 999)
	puzzles_resolvidos = _como_dicionario(d.get("puzzles_resolvidos"))
	progresso_puzzles = _como_dicionario(d.get("progresso_puzzles"))
	escolhas_realizadas = _como_dicionario(d.get("escolhas_realizadas"))
	historico_roteiro = _como_lista(d.get("historico_roteiro"))
	roteiro_aux = _como_dicionario(d.get("roteiro_aux"))
	# permissões: só as cinco do roteiro, sempre booleanas (valor inválido = false); chaves antigas (microfone etc.) são descartadas
	var lidas: Dictionary = _como_dicionario(d.get("permissoes"))
	permissoes = PERMISSOES_PADRAO.duplicate()
	for id_perm in PERMISSOES_V2:
		permissoes[id_perm] = typeof(lidas.get(id_perm, false)) == TYPE_BOOL and bool(lidas.get(id_perm, false))
	# O grupo explícito do roteiro vence as métricas antigas (e saneia): Dependência 0..100; Autonomia nunca negativa.
	if d.has("dependencia_maya") and Metricas.sanear(d["dependencia_maya"], Metricas.DEPENDENCIA)["ok"]:
		metricas[Metricas.DEPENDENCIA] = float(Metricas.sanear(d["dependencia_maya"], Metricas.DEPENDENCIA)["valor"])
	if d.has("autonomia_jogador") and Metricas.sanear(d["autonomia_jogador"], Metricas.AUTONOMIA)["ok"]:
		metricas[Metricas.AUTONOMIA] = float(Metricas.sanear(d["autonomia_jogador"], Metricas.AUTONOMIA)["valor"])
	if not d.has("schema_roteiro"):
		# SAVE ANTIGO (anterior ao roteiro v2.0): sem progresso do roteiro; recomeça na Task 1 mantendo perfil e configurações.
		metricas[Metricas.DEPENDENCIA] = float(DEPENDENCIA_INICIAL)
		metricas[Metricas.AUTONOMIA] = float(AUTONOMIA_INICIAL)
		flags = {"boot_concluido": true}
		chat = {}
		nos = {}
		no_atual = TASK_INICIAL
		eventos_unicos = []
		ajuda_usos = []
		reacoes_npc = []
		perfil_final = ""
		final_id = ""
		# Como recomeça na Task 1, nada do que o save antigo concedeu vale: a Maya só age com permissão explícita dada neste roteiro.
		permissoes = PERMISSOES_PADRAO.duplicate()
		tentativas_revogacao = {}
		tentativas_revogacao_task_9 = 0
		atos_de_resistencia = []


# ------------------------------------------------------------------ métricas globais (AUT / CON / DEP)
## Valor atual de uma métrica ("autonomia", "AUT"...). Métrica desconhecida devolve 0.0 e avisa no log.
func obter_metrica(nome: String) -> float:
	var canonico := Metricas.normalizar_nome(nome)
	if canonico == "":
		push_warning("GerenciadorEstado: métrica desconhecida '%s'." % nome)
		return 0.0
	return float(metricas.get(canonico, Metricas.inicial(canonico)))


## Define o valor (travado nos limites). Valor inválido (texto, NaN, infinito...) é recusado: devolve false e nada muda.
func definir_metrica(nome: String, valor: Variant, origem: String = "") -> bool:
	var canonico := Metricas.normalizar_nome(nome)
	var r := Metricas.sanear(valor, canonico)
	if canonico == "" or not bool(r["ok"]):
		push_warning("GerenciadorEstado: valor recusado para a métrica '%s' (%s)." % [nome, str(r["motivo"])])
		return false
	var antes := obter_metrica(canonico)
	var depois := float(r["valor"])
	# REGRA DO ROTEIRO v2.0: a Autonomia é um contador que NUNCA diminui (só `restaurar_metricas`, no novo jogo, volta ao início).
	if canonico == Metricas.AUTONOMIA and depois < antes and origem != ORIGEM_RESTAURAR:
		push_warning("GerenciadorEstado: a autonomia nunca diminui (pedido recusado, origem '%s')." % origem)
		return false
	metricas[canonico] = depois
	if not is_equal_approx(antes, depois):
		metrica_mudou.emit(canonico, depois, depois - antes)
	return true


## Soma `delta` (positivo ou negativo) respeitando os limites. Devolve o novo valor; delta inválido não altera nada.
func alterar_metrica(nome: String, delta: Variant, origem: String = "") -> float:
	var canonico := Metricas.normalizar_nome(nome)
	if canonico == "" or not Metricas.delta_valido(delta):
		push_warning("GerenciadorEstado: alteração recusada na métrica '%s'." % nome)
		return obter_metrica(canonico) if canonico != "" else 0.0
	var novo := Metricas.aplicar_delta(obter_metrica(canonico), delta, canonico)
	definir_metrica(canonico, novo, origem)
	return obter_metrica(canonico)


func restaurar_metricas() -> void:
	for nome in Metricas.NOMES:
		definir_metrica(nome, Metricas.inicial(nome), ORIGEM_RESTAURAR)


## Cópia das métricas ({"autonomia": x, ...}) para relatórios e para o perfil final.
func copia_das_metricas() -> Dictionary:
	return metricas.duplicate()


# ------------------------------------------------------------------ progresso
## Guarda o nó atual do roteiro e avisa a interface.
func definir_no_roteiro(id_no: String) -> void:
	no_roteiro = id_no
	roteiro_alterado.emit(id_no)


## Muda a Task atual (grava no Story Node de Task) e avisa a interface. O GerenciadorNos é quem chama isto ao ativar um nó de Task.
func definir_task(id_task: String) -> void:
	if task_atual == id_task:
		return
	task_atual = id_task
	dados["fase_os"] = etapa_atual
	etapa_mudou.emit(etapa_atual)


func definir_corrupcao(v: float) -> void:
	corrupcao = clampf(v, 0.0, 100.0)
	corrupcao_mudou.emit(corrupcao)


func ajustar_corrupcao(delta: float) -> void:
	definir_corrupcao(corrupcao + delta)


func definir_seguranca(v: int) -> void:
	seguranca = clampi(v, 0, 100)
	seguranca_mudou.emit(seguranca)


func ajustar_seguranca(delta: int) -> void:
	definir_seguranca(seguranca + delta)


func definir_ia_estado(estado: String) -> void:
	if ia_estado != estado:
		ia_estado = estado
		ia_estado_mudou.emit(estado)


func desbloquear_app(id_app: String) -> void:
	if apps_desbloqueados.has(id_app):
		return
	apps_desbloqueados.append(id_app)
	app_desbloqueado.emit(id_app)


func definir_objetivos_obrigatorios(ids: Array) -> void:
	objetivos_obrigatorios = ids.duplicate()


func concluir_objetivo(id_obj: String) -> void:
	if objetivos_concluidos.has(id_obj):
		return
	objetivos_concluidos[id_obj] = true
	objetivo_concluido.emit(id_obj)


func objetivo_ok(id_obj: String) -> bool:
	return objetivos_concluidos.has(id_obj)


func todos_obrigatorios_concluidos() -> bool:
	for id_obj in objetivos_obrigatorios:
		if not objetivos_concluidos.has(id_obj):
			return false
	return not objetivos_obrigatorios.is_empty()


func registrar_final(id_final: String) -> void:
	final_id = id_final
	final_alcancado.emit(id_final)


func pedir_glitch(intensidade: float = 0.5, duracao: float = 0.6) -> void:
	glitch_solicitado.emit(intensidade, duracao)


# ------------------------------------------------------------------ permissões simuladas
func definir_permissao(nome: String, ativa: bool) -> void:
	var mudou: bool = permissoes.get(nome) != ativa
	permissoes[nome] = ativa
	if mudou:
		permissao_alterada.emit(nome, ativa)


func permissao(nome: String) -> bool:
	return bool(permissoes.get(nome, false))


## Todas as permissões de MONITORAMENTO (as quatro originais, `PERMISSOES_PADRAO`) estão desativadas? As permissões de sistema
## (instalar aplicativos, acesso às mensagens...) ficam fora desta conta.
func todas_permissoes_desativadas() -> bool:
	for nome in PERMISSOES_PADRAO:
		if bool(permissoes.get(nome, false)):
			return false
	return true


# ------------------------------------------------------------------ aplicativos instalados (simulados)
## Aplicativos instalados pelo jogador (GUI ou Terminal). O estado é um só: as duas interfaces (janela e Terminal) leem e gravam aqui.
func app_instalado(app_id: String) -> bool:
	return apps_instalados.has(app_id)


## Marca um aplicativo como instalado (ou remove a marca). Devolve true se o estado mudou.
func definir_app_instalado(app_id: String, instalado: bool) -> bool:
	if app_id == "":
		return false
	var ja := apps_instalados.has(app_id)
	if ja == instalado:
		return false
	if instalado:
		apps_instalados.append(app_id)
	else:
		apps_instalados.erase(app_id)
	apps_instalados_mudou.emit(app_id, instalado)
	return true


# ------------------------------------------------------------------ falso boot (reinício simulado)
func falso_boot_ativo() -> bool:
	return bool(falso_boot.get("ativo", false))


## Liga ou desliga o falso boot. `detalhes` (motivo, início, duração máxima...) ficam guardados em `falso_boot` e vão para o salvamento.
func definir_falso_boot(ativo: bool, detalhes: Dictionary = {}) -> void:
	var antes := falso_boot_ativo()
	var novo: Dictionary = detalhes.duplicate(true)
	novo["ativo"] = ativo
	falso_boot = novo
	if antes != ativo:
		falso_boot_mudou.emit(ativo)


# ------------------------------------------------------------------ processos simulados (nunca reais)
func adicionar_processo_malicioso(proc: Dictionary) -> void:
	processos_maliciosos.append(proc)
	processos_alterados.emit()


func remover_processo_malicioso(pid: int) -> void:
	for i in processos_maliciosos.size():
		if int(processos_maliciosos[i].get("pid", -1)) == pid:
			processos_maliciosos.remove_at(i)
			break
	processos_alterados.emit()


func encerrar_processo_malicioso(pid: int) -> void:
	remover_processo_malicioso(pid)
	processo_encerrado_pelo_jogador.emit(pid)


func limpar_processos() -> void:
	processos_maliciosos.clear()
	processos_alterados.emit()


func processo_ativo() -> bool:
	return not processos_maliciosos.is_empty()


# ------------------------------------------------------------------ chat
func adicionar_mensagem(contato: String, entrada: Dictionary) -> void:
	if not chat.has(contato):
		chat[contato] = []
	chat[contato].append(entrada)
	mensagem_recebida.emit(contato, entrada)


func historico(contato: String) -> Array:
	return chat.get(contato, [])


func tem_mensagem(contato: String, id_msg: String) -> bool:
	for entrada in historico(contato):
		if str(entrada.get("id", "")) == id_msg:
			return true
	return false


func nao_lidas(contato: String) -> int:
	var n := 0
	for entrada in historico(contato):
		if not bool(entrada.get("lida", true)) and str(entrada.get("autor", "")) != "jogador" and not bool(entrada.get("expirada", false)):
			n += 1
	return n


func total_nao_lidas() -> int:
	var n := 0
	for contato in chat:
		n += nao_lidas(contato)
	return n


func marcar_lidas(contato: String) -> void:
	for entrada in historico(contato):
		entrada["lida"] = true


func bloquear_contato(id_contato: String) -> void:
	if not contatos_bloqueados.has(id_contato):
		contatos_bloqueados.append(id_contato)
		contato_bloqueado.emit(id_contato)


func esta_bloqueado(id_contato: String) -> bool:
	return contatos_bloqueados.has(id_contato)


## Reescreve uma mensagem já enviada (mecânica de "gaslighting").
func alterar_mensagem(id_msg: String, novo_texto: String) -> bool:
	for contato in chat:
		for entrada in chat[contato]:
			if str(entrada.get("id", "")) == id_msg:
				var anterior := str(entrada.get("texto", ""))
				entrada["texto_original"] = anterior
				entrada["texto"] = novo_texto
				entrada["alterada"] = true
				gaslighting_solicitado.emit(id_msg, novo_texto)
				mensagem_alterada.emit(str(contato), id_msg, anterior, novo_texto)
				return true
	return false


## Avisa a interface de que a mensagem mudou (status de envio, escolha injetada...). Quem altera a entrada do histórico chama isto depois.
func notificar_mensagem_atualizada(contato: String, id_msg: String) -> void:
	mensagem_atualizada.emit(contato, id_msg)


## Última mensagem escrita pelo jogador em um contato (alvo do gaslighting).
func ultima_mensagem_do_jogador(contato: String) -> String:
	var lista := historico(contato)
	for i in range(lista.size() - 1, -1, -1):
		if str(lista[i].get("autor", "")) == "jogador" and not bool(lista[i].get("alterada", false)) and str(lista[i].get("status", "")) != "erro_de_envio":
			return str(lista[i].get("id", ""))
	return ""


# ------------------------------------------------------------------ bloqueio narrativo de fechar janelas
func definir_bloqueio_fechar(app_id: String, tentativas: int) -> void:
	bloqueios_fechar[app_id] = tentativas


## Retorna true enquanto a Maya "segura" a janela. Cada tentativa consome uma carga: nunca é permanente.
func fechamento_bloqueado(app_id: String) -> bool:
	var restantes := int(bloqueios_fechar.get(app_id, 0))
	if restantes <= 0:
		return false
	bloqueios_fechar[app_id] = restantes - 1
	return true


func tentativas_de_fechar_restantes(app_id: String) -> int:
	return int(bloqueios_fechar.get(app_id, 0))


# ------------------------------------------------------------------ texto
## Substitui as tags de texto numa única passada: as do perfil ({NOME_JOGADOR}, {PRONOME_JOGADOR}, {ARTIGO_JOGADOR},
## {PRONOME_POSSESSIVO}) e as legadas ({nome}, {dia}, {seguranca}, {corrupcao}). Ver PerfilJogador.processar_texto.
func formatar(texto: String) -> String:
	if not texto.contains("{"):
		return texto
	var contexto_tags := PerfilJogador.contexto(nome_jogador, pronome_jogador)
	contexto_tags["dia"] = str(etapa_atual)
	contexto_tags["seguranca"] = str(seguranca)
	contexto_tags["corrupcao"] = str(int(corrupcao))
	if int(perfil_extra.get("idade", 0)) > 0:
		contexto_tags["IDADE_JOGADOR"] = str(int(perfil_extra["idade"]))
	if str(perfil_extra.get("email", "")) != "":
		contexto_tags["EMAIL_JOGADOR"] = str(perfil_extra["email"])
	return PerfilJogador.processar_texto(texto, contexto_tags)


## Guarda os dados extras do perfil já validados (PerfilJogador.extra_seguro).
func definir_perfil_extra(extra: Dictionary) -> void:
	perfil_extra = PerfilJogador.extra_seguro(extra)


## Perfil do jogador (nome e pronome já validados). Emite `perfil_alterado`.
func definir_perfil(nome: String, pronome: String) -> void:
	nome_jogador = PerfilJogador.nome_seguro(nome)
	pronome_jogador = PerfilJogador.validar_pronome(pronome)
	jogador_alterado.emit(nome_jogador)
	perfil_alterado.emit(nome_jogador, pronome_jogador)


# ------------------------------------------------------------------ ponte opcional com o backend em C (legado)
## Com a ponte ligada: lê o mock legado (se existir, só no editor: backend/ não vai na build) e espelha em `dados["estado_jogo"]` o
## `estado_jogo.json` validado (EstadoJogoBackend), SEM aplicá-lo às métricas: aplicar é uma ação explícita (EstadoJogoBackend.aplicar_ao_jogo).
func carregar_json_backend() -> void:
	if FileAccess.file_exists(ARQUIVO_BACKEND):
		var json: Variant = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO_BACKEND))
		if typeof(json) == TYPE_DICTIONARY:
			dados = json
			_verificar_gatilhos_backend()
		else:
			push_warning("GerenciadorEstado: JSON do backend inválido.")
	var lido: Dictionary = EstadoJogoBackend.ler()
	if bool(lido["ok"]):
		dados["estado_jogo"] = lido["estado"]


func _verificar_gatilhos_backend() -> void:
	if bool(dados.get("gaslighting_pendente", false)):
		var id_alvo := str(dados.get("id_alvo_manipulacao", ""))
		var texto := str(dados.get("texto_manipulado", ""))
		if id_alvo != "" and texto != "":
			# Atraso único (sem Timer-nó); só roda quando a ponte opcional com o backend está ligada.
			get_tree().create_timer(1.0, false).timeout.connect(_aplicar_gaslighting_backend.bind(id_alvo, texto))  # false: não conta durante a pausa


func _aplicar_gaslighting_backend(id_alvo: String, texto: String) -> void:
	alterar_mensagem(id_alvo, texto)
	dados["gaslighting_pendente"] = false
