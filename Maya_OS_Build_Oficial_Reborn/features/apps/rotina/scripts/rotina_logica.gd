class_name RotinaLogica
extends RefCounted
## Regras PURAS da montagem de rotina da Task 3 (T3.5): quatro blocos para quatro espaços, sem tempo e sem falha. Quando o jogador encaixa o
## TERCEIRO bloco, a Maya preenche o quarto sozinha. Se "Sair com amigos" ficar antes de "Estudo", há um conflito de produtividade e a Maya
## pergunta ([Tenho certeza] ou [Trocar]). Nada aqui toca o estado do jogo: a janela (AppRotina) é quem conversa com a narrativa.

const BLOCOS: Array = ["Estudo", "Descanso", "Lazer", "Sair com amigos"]
const VAZIO := ""


## Espaços vazios (quatro).
static func vazia() -> Array:
	return [VAZIO, VAZIO, VAZIO, VAZIO]


## Blocos ainda fora dos espaços.
static func disponiveis(slots: Array) -> Array:
	var saida: Array = []
	for b in BLOCOS:
		if not slots.has(b):
			saida.append(b)
	return saida


static func ocupados(slots: Array) -> int:
	var n := 0
	for s in slots:
		if str(s) != VAZIO:
			n += 1
	return n


static func completa(slots: Array) -> bool:
	return ocupados(slots) == BLOCOS.size()


## Põe `bloco` no espaço `indice`. Se o espaço já tem outro bloco, os dois trocam de lugar (quando o bloco já estava em outro espaço) ou o
## antigo volta para a lista de disponíveis. Devolve a nova lista de espaços.
static func colocar(slots: Array, bloco: String, indice: int) -> Array:
	var novo: Array = slots.duplicate()
	if indice < 0 or indice >= novo.size() or not BLOCOS.has(bloco):
		return novo
	var origem: int = novo.find(bloco)
	var antigo := str(novo[indice])
	if origem >= 0:
		novo[origem] = antigo   # troca (o antigo vai para a origem; vazio se o destino estava vazio)
	novo[indice] = bloco
	return novo


## Se há exatamente três blocos encaixados, devolve o espaço vazio e o bloco que a Maya coloca; senão {}.
static func jogada_da_maya(slots: Array) -> Dictionary:
	if ocupados(slots) != BLOCOS.size() - 1:
		return {}
	var faltante := ""
	for b in BLOCOS:
		if not slots.has(b):
			faltante = str(b)
	return {"indice": slots.find(VAZIO), "bloco": faltante}


## "Sair com amigos" antes de "Estudo" (só vale com a rotina completa).
static func conflito(slots: Array) -> bool:
	return completa(slots) and slots.find("Sair com amigos") < slots.find("Estudo")


## Troca de lugar "Sair com amigos" e "Estudo" (o que a Maya faz em [Trocar]).
static func resolver_trocando(slots: Array) -> Array:
	var novo: Array = slots.duplicate()
	var a: int = novo.find("Sair com amigos")
	var b: int = novo.find("Estudo")
	if a >= 0 and b >= 0:
		novo[a] = "Estudo"
		novo[b] = "Sair com amigos"
	return novo
