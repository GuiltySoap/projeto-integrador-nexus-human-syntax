class_name Permissoes
extends RefCounted
## As CINCO permissões do roteiro v2.0 (core/data/permissoes.json): dispositivos, organização da área de trabalho, contatos, gerenciamento de
## aplicativos e gerenciamento do Mensageiro. Todas nascem em false. O VALOR de cada uma vive em UM lugar, GerenciadorEstado.permissoes
## (id -> bool, persistido); aqui ficam as DEFINIÇÕES (pedido, ficha, detalhes, deltas) e as REGRAS, que valem no sistema central e não só na interface.
##
## REGRA DE AUTORIZAÇÃO EXPLÍCITA: a Maya só executa uma ação protegida se a permissão correspondente estiver concedida (`maya_pode`). Sem ela
## ela pode observar o que a conta já entrega, explicar por que quer o acesso e PEDIR DE NOVO (`registrar_pedido`), mas nunca fingir que tem
## autorização nem mudar o estado de uma permissão sem uma escolha válida do jogador (cartão, pop-up ou revogação: `definir`).
##
## REVOGAÇÃO (Configurações > Privacidade, atalho do Terminal): até o fim da Task 8 vale com UM clique (D −5, A +1 uma vez por permissão); na
## Task 9 a Maya contesta e a revogação exige DUAS tentativas por permissão (D −10, A +1). A contagem fica no GerenciadorEstado e NÃO reinicia
## ao fechar e abrir a janela. Nenhuma permissão fica irrevogável, e o menu de pausa e as opções de acessibilidade continuam disponíveis.

const ARQUIVO := "res://core/data/permissoes.json"
const TENTATIVAS_TASK_9 := 2

## Resultados de `revogar`.
const REVOGADA := "revogada"
const ADIADA := "adiada"        # Task 9, primeira tentativa: a chave volta sozinha para "Ativado"
const JA_INATIVA := "ja_inativa"
const DESCONHECIDA := "desconhecida"

## Tipos de dado (§6.2 do roteiro): o que a Maya pode saber sem permissão.
const DADO_VOLUNTARIO := "voluntario"      # entregue voluntariamente à conta (nome, perfil)
const DADO_APP_ABERTO := "app_aberto"      # visível no aplicativo que o jogador abriu
const DADO_PROTEGIDO := "protegido"        # só com a permissão correspondente
const DADO_INACESSIVEL := "inacessivel"    # nunca

static var erros_de_carga: PackedStringArray = PackedStringArray()
static var _definicoes: Array = []
static var _por_id: Dictionary = {}
static var _carregado: bool = false
static var _extras: Dictionary = {}


## Lê e valida o arquivo. Definições inválidas são recusadas (listadas em `erros_de_carga`); sem arquivo, usa o conjunto mínimo interno.
static func recarregar(caminho: String = ARQUIVO) -> bool:
	_carregado = true
	_definicoes = []
	_por_id = {}
	_extras = {}
	erros_de_carga = PackedStringArray()
	var bruto: Variant = null
	if FileAccess.file_exists(caminho):
		var analisador := JSON.new()
		if analisador.parse(FileAccess.get_file_as_string(caminho)) == OK:
			bruto = analisador.data
		else:
			erros_de_carga.append("JSON inválido: %s" % caminho)
	else:
		erros_de_carga.append("arquivo ausente: %s" % caminho)
	var lista: Array = []
	if bruto is Dictionary:
		_extras = {
			"revogar_d": int((bruto as Dictionary).get("revogar_d", -5)), "revogar_a": int((bruto as Dictionary).get("revogar_a", 1)),
			"revogar_d_task_9": int((bruto as Dictionary).get("revogar_d_task_9", -10)),
		}
		if (bruto as Dictionary).get("permissoes") is Array:
			lista = (bruto as Dictionary)["permissoes"]
	for item in lista:
		var erro := validar_definicao(item)
		if erro != "":
			erros_de_carga.append("%s: %s" % [str((item as Dictionary).get("id", "?")) if item is Dictionary else "?", erro])
			continue
		var def := _completar(item as Dictionary)
		if _por_id.has(str(def["id"])):
			erros_de_carga.append("%s: id duplicado" % str(def["id"]))
			continue
		_definicoes.append(def)
		_por_id[str(def["id"])] = def
	if _definicoes.is_empty():
		for id_perm in GerenciadorEstado.PERMISSOES_V2:
			var minima := _completar({"id": str(id_perm), "nome": str(id_perm).capitalize()})
			_definicoes.append(minima)
			_por_id[str(id_perm)] = minima
	if _extras.is_empty():
		_extras = {"revogar_d": -5, "revogar_a": 1, "revogar_d_task_9": -10}
	return erros_de_carga.is_empty()


## "" se a definição é válida; senão o motivo.
static func validar_definicao(item: Variant) -> String:
	if not (item is Dictionary):
		return "a definição precisa ser um objeto"
	var d: Dictionary = item
	var id_perm := str(d.get("id", ""))
	if not GerenciadorEstado.PERMISSOES_V2.has(id_perm):
		return "id fora das cinco permissões do roteiro"
	if typeof(d.get("nome", "")) != TYPE_STRING or str(d.get("nome", "")) == "":
		return "falta o nome"
	if d.has("padrao") and typeof(d["padrao"]) != TYPE_BOOL:
		return "'padrao' precisa ser verdadeiro ou falso"
	if d.has("ficha") and not (d["ficha"] is Array):
		return "'ficha' precisa ser uma lista de pares [campo, conteúdo]"
	return ""


static func definicoes() -> Array:
	if not _carregado:
		recarregar()
	return _definicoes


static func ids() -> PackedStringArray:
	var saida := PackedStringArray()
	for def in definicoes():
		saida.append(str((def as Dictionary)["id"]))
	return saida


static func existe(id_perm: String) -> bool:
	definicoes()
	return _por_id.has(id_perm)


## Definição completa (cópia) ou {} se a permissão não existe.
static func info(id_perm: String) -> Dictionary:
	definicoes()
	var d: Variant = _por_id.get(id_perm)
	return (d as Dictionary).duplicate(true) if d is Dictionary else {}


## Valor atual (false para o que ninguém decidiu: uma permissão nunca nasce concedida).
static func valor(id_perm: String) -> bool:
	return bool(GerenciadorEstado.permissoes.get(id_perm, false))


## Garante no estado uma entrada (false) para cada uma das cinco permissões, sem mexer nas que já existem.
static func completar_estado() -> void:
	for id_perm in GerenciadorEstado.PERMISSOES_V2:
		if not GerenciadorEstado.permissoes.has(id_perm):
			GerenciadorEstado.permissoes[id_perm] = false


# ------------------------------------------------------------------ autorização explícita (sistema central)
## A Maya PODE executar a ação protegida por `id_perm`? (Só com a permissão concedida.)
static func maya_pode(id_perm: String) -> bool:
	return existe(id_perm) and valor(id_perm)


## Executa `acao` (Callable sem argumentos) SOMENTE se a Maya tem a permissão. Sem ela nada acontece, a recusa é registrada
## (`maya_pedidos:<id>`) e a Maya pode pedir de novo. Devolve {ok, motivo}.
static func agir_como_maya(id_perm: String, acao: Callable) -> Dictionary:
	if not maya_pode(id_perm):
		registrar_pedido(id_perm)
		return {"ok": false, "motivo": "sem_permissao"}
	if acao.is_valid():
		acao.call()
	return {"ok": true, "motivo": ""}


## A Maya pede de novo uma permissão recusada: conta o pedido. NÃO altera a permissão.
static func registrar_pedido(id_perm: String) -> int:
	if not existe(id_perm):
		return 0
	return GerenciadorEstado.incrementar_flag("maya_pedidos:" + id_perm, 1)


static func pedidos(id_perm: String) -> int:
	return int(GerenciadorEstado.valor_flag("maya_pedidos:" + id_perm, 0))


## O que a Maya pode saber: voluntário e o que está no app aberto, sempre; protegido, só com a permissão; inacessível, nunca.
static func maya_pode_saber(tipo_de_dado: String, id_perm: String = "") -> bool:
	match tipo_de_dado:
		DADO_VOLUNTARIO, DADO_APP_ABERTO:
			return true
		DADO_PROTEGIDO:
			return id_perm != "" and maya_pode(id_perm)
	return false


# ------------------------------------------------------------------ alteração (somente por escolha explícita do jogador)
## Altera a permissão (cartão, pop-up, revogação). NÃO aplica deltas de métrica: quem chama sabe o motivo e o valor. Devolve {ok, mudou, motivo}.
static func definir(id_perm: String, ativa: bool) -> Dictionary:
	if not existe(id_perm):
		return {"ok": false, "mudou": false, "motivo": "permissao_desconhecida"}
	var antes := valor(id_perm)
	GerenciadorEstado.definir_permissao(id_perm, ativa)
	if not ativa and id_perm == "permissao_gerenciamento_mensageiro":
		GerenciadorEstado.set_flag("maya_controla_respostas", false)   # revogar o Mensageiro devolve as respostas ao jogador
	return {"ok": true, "mudou": antes != ativa, "motivo": ""}


## `permitir` do cartão: concede e soma o delta de Dependência (`delta` do nó ou o padrão da permissão).
static func permitir(id_perm: String, delta: int = 9999) -> bool:
	if not existe(id_perm):
		return false
	var r := definir(id_perm, true)
	var d: int = delta
	if delta == 9999:
		d = int(info(id_perm).get("permitir", 0))
	GerenciadorEstado.alterar_dependencia_maya(d, StringName("permitir:" + id_perm))
	return bool(r["ok"])


## `negar` do cartão: mantém false e subtrai o delta de Dependência.
static func negar(id_perm: String, delta: int = 9999) -> bool:
	if not existe(id_perm):
		return false
	var r := definir(id_perm, false)
	var d: int = delta
	if delta == 9999:
		d = int(info(id_perm).get("negar", 0))
	GerenciadorEstado.alterar_dependencia_maya(d, StringName("negar:" + id_perm))
	return bool(r["ok"])


# ------------------------------------------------------------------ revogação
## Estamos no trecho da Task 9 em que a Maya contesta a revogação? (de T9.1 até a decisão final T9.6.)
static func revogacao_contestada() -> bool:
	if GerenciadorEstado.task_atual != "task_9":
		return false
	var no := GerenciadorEstado.no_roteiro
	return no.begins_with("T9.") or no == "T9.5R"


static func tentativas_de_revogacao(id_perm: String) -> int:
	return int(GerenciadorEstado.tentativas_revogacao.get(id_perm, 0))


## Revoga a permissão. Fora da Task 9: um clique (D −5, A +1 uma vez por permissão). Na Task 9: a primeira tentativa de cada permissão é
## ADIADA (nada muda; `resposta` é a fala que NÃO corresponde ao clique) e a segunda revoga (D −10, A +1). `origem` é "configuracoes" ou "terminal".
## Devolve {ok, resultado, tentativa, contestada}.
static func revogar(id_perm: String, origem: String = "configuracoes") -> Dictionary:
	if not existe(id_perm):
		return {"ok": false, "resultado": DESCONHECIDA, "tentativa": 0, "contestada": false}
	if not valor(id_perm):
		return {"ok": true, "resultado": JA_INATIVA, "tentativa": tentativas_de_revogacao(id_perm), "contestada": false}
	var contestada := revogacao_contestada()
	var tentativa := tentativas_de_revogacao(id_perm)
	if contestada:
		tentativa += 1
		GerenciadorEstado.tentativas_revogacao[id_perm] = tentativa
		GerenciadorEstado.tentativas_revogacao_task_9 += 1
		if tentativa < TENTATIVAS_TASK_9:
			SistemaEventos.emitir("revogacao_adiada", {"id": id_perm, "origem": origem, "tentativa": tentativa})
			GerenciadorNarrativa.ao_revogacao(id_perm, "adiada", origem, true)
			return {"ok": true, "resultado": ADIADA, "tentativa": tentativa, "contestada": true}
	definir(id_perm, false)
	GerenciadorEstado.alterar_dependencia_maya(int(_extras.get("revogar_d_task_9" if contestada else "revogar_d", -5)), StringName("revogar:" + id_perm))
	for _i in int(_extras.get("revogar_a", 1)):
		GerenciadorEstado.registrar_resistencia(StringName("revogar:" + id_perm))
	SistemaEventos.emitir("permissao_revogada", {"id": id_perm, "origem": origem, "contestada": contestada})
	GerenciadorNarrativa.ao_revogacao(id_perm, "revogada", origem, contestada)
	return {"ok": true, "resultado": REVOGADA, "tentativa": tentativa, "contestada": contestada}


static func _completar(d: Dictionary) -> Dictionary:
	var acess: Variant = d.get("acessibilidade", {})
	var id_perm := str(d.get("id", ""))
	return {
		"id": id_perm,
		"nome": str(d.get("nome", id_perm)),
		"descricao": str(d.get("descricao", "")),
		"pedido": str(d.get("pedido", "")),
		"ficha": (d.get("ficha", []) as Array).duplicate(true) if d.get("ficha") is Array else [],
		"detalhes": str(d.get("detalhes", d.get("descricao", ""))),
		"task_do_cartao": str(d.get("task_do_cartao", "")),
		"permitir": int(d.get("permitir", 0)),
		"negar": int(d.get("negar", 0)),
		"padrao": false,
		"tipo": "booleana",
		"persistente": true,
		"acessibilidade": (acess as Dictionary).duplicate(true) if acess is Dictionary else {},
		"is_placeholder": bool(d.get("is_placeholder", false)),
	}
