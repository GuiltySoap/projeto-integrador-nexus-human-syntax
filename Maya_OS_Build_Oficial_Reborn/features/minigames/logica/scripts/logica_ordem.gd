class_name LogicaOrdem
extends RefCounted
## Regras PURAS dos minigames de ORDEM (Exercício da lista 3 e Histórico fragmentado). Determinístico, sem tempo, tentativas ilimitadas.
## Estado: `slots` (id da peça em cada posição ou "" se vazio), `travados` (bool por posição) e `sem_acerto` (verificações seguidas sem acerto novo).
## As peças fora dos espaços formam a bandeja, na ordem de `inicio`. [Verificar] trava as peças certas e devolve as erradas à bandeja.

const VAZIO := ""


static func estado_inicial(def: Dictionary) -> Dictionary:
	var n: int = (def.get("solucao", []) as Array).size()
	var slots: Array = []
	var travados: Array = []
	for i in n:
		slots.append(VAZIO)
		travados.append(false)
	return {"slots": slots, "travados": travados, "sem_acerto": 0}


## Normaliza um progresso salvo (pode vir de JSON antigo ou corrompido); devolve o estado inicial se não bater com a definição.
static func carregar(def: Dictionary, salvo: Variant) -> Dictionary:
	var base := estado_inicial(def)
	if not (salvo is Dictionary):
		return base
	var s: Dictionary = salvo
	var n: int = (base["slots"] as Array).size()
	var ids: Array = _ids(def)
	if not (s.get("slots") is Array) or not (s.get("travados") is Array) or (s["slots"] as Array).size() != n or (s["travados"] as Array).size() != n:
		return base
	var vistos: Dictionary = {}
	var slots: Array = []
	var travados: Array = []
	for i in n:
		var p := str((s["slots"] as Array)[i])
		if p != VAZIO and (not ids.has(p) or vistos.has(p)):
			return base   # progresso inválido: volta ao estado inicial inteiro, sem aproveitar parte dele
		if p != VAZIO:
			vistos[p] = true
		slots.append(p)
		travados.append(bool((s["travados"] as Array)[i]) and p != VAZIO)
	base["slots"] = slots
	base["travados"] = travados
	base["sem_acerto"] = maxi(0, int(s.get("sem_acerto", 0)))
	return base


static func _ids(def: Dictionary) -> Array:
	var ids: Array = []
	for p in def.get("pecas", []):
		ids.append(str((p as Dictionary).get("id", "")))
	return ids


## Peças fora dos espaços, na ordem de `inicio`.
static func bandeja(def: Dictionary, estado: Dictionary) -> Array:
	var saida: Array = []
	for id in def.get("inicio", []):
		if not (estado["slots"] as Array).has(str(id)):
			saida.append(str(id))
	return saida


## Põe a peça no espaço. Espaços travados não mudam; a peça que já estava ali volta para a bandeja; se a peça estava em outro espaço, sai de lá.
static func colocar(estado: Dictionary, peca: String, indice: int) -> Dictionary:
	var slots: Array = (estado["slots"] as Array).duplicate()
	var travados: Array = estado["travados"] as Array
	if indice < 0 or indice >= slots.size() or bool(travados[indice]):
		return estado
	var origem: int = slots.find(peca)
	if origem >= 0 and bool(travados[origem]):
		return estado
	if origem >= 0:
		slots[origem] = VAZIO
	slots[indice] = peca
	var novo := estado.duplicate()
	novo["slots"] = slots
	return novo


## Devolve a peça do espaço à bandeja (ignora espaço travado ou vazio).
static func remover(estado: Dictionary, indice: int) -> Dictionary:
	var slots: Array = (estado["slots"] as Array).duplicate()
	if indice < 0 or indice >= slots.size() or bool((estado["travados"] as Array)[indice]):
		return estado
	slots[indice] = VAZIO
	var novo := estado.duplicate()
	novo["slots"] = slots
	return novo


static func completo(def: Dictionary, estado: Dictionary) -> bool:
	return (estado["slots"] as Array) == (def.get("solucao", []) as Array)


## [Verificar]: trava as peças na posição certa e devolve as erradas. Conta acertos NOVOS; sem acerto novo soma em `sem_acerto`, com acerto zera.
static func verificar(def: Dictionary, estado: Dictionary) -> Dictionary:
	var solucao: Array = def.get("solucao", [])
	var slots: Array = (estado["slots"] as Array).duplicate()
	var travados: Array = (estado["travados"] as Array).duplicate()
	var novos := 0
	for i in slots.size():
		if str(slots[i]) == VAZIO:
			continue
		if str(slots[i]) == str(solucao[i]):
			if not bool(travados[i]):
				novos += 1
			travados[i] = true
		else:
			slots[i] = VAZIO
			travados[i] = false
	var sem_acerto: int = 0 if novos > 0 else int(estado.get("sem_acerto", 0)) + 1
	return {"estado": {"slots": slots, "travados": travados, "sem_acerto": sem_acerto}, "novos": novos}


## A dica aparece depois de `limite` verificações seguidas sem acerto novo.
static func dica_ativa(estado: Dictionary, limite: int = 2) -> bool:
	return int(estado.get("sem_acerto", 0)) >= limite


## Texto da dica. Com `dica_por_posicao`: na primeira posição não travada, "Esta mensagem responde a: '[trecho da anterior]'" (a peça anterior na solução).
## Sem ela: a dica fixa da definição.
static func texto_da_dica(def: Dictionary, estado: Dictionary) -> String:
	if not bool(def.get("dica_por_posicao", false)):
		return str(def.get("dica", ""))
	var indice := primeira_nao_travada(estado)
	if indice < 0:
		return ""
	if indice == 0:
		return "A primeira mensagem é a que abre a conversa: não responde a nada."
	var anterior: String = str((def.get("solucao", []) as Array)[indice - 1])
	return str(def.get("dica_formato", "%s")) % texto_da_peca(def, anterior)


static func primeira_nao_travada(estado: Dictionary) -> int:
	var travados: Array = estado["travados"] as Array
	for i in travados.size():
		if not bool(travados[i]):
			return i
	return -1


static func texto_da_peca(def: Dictionary, id: String) -> String:
	for p in def.get("pecas", []):
		if str((p as Dictionary).get("id", "")) == id:
			return str((p as Dictionary).get("texto", ""))
	return ""
