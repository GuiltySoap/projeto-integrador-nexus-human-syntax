class_name Metricas
extends RefCounted
## Regras das métricas globais AUT (Autonomia), CON (Conformidade) e DEP (Dependência) e a fórmula única do perfil final.
## Funções PURAS: o valor de cada métrica vive em UM lugar só, o GerenciadorEstado (obter_metrica / definir_metrica /
## alterar_metrica); aplicativos e eventos nunca guardam cópia própria. Os limites e os pesos vêm de core/data/regras.json
## (Regras), com valores padrão seguros quando algo faltar.
##
## LIMITES: cada métrica tem mínimo, máximo e valor inicial (padrão: 0..100; roteiro v2.0: AUT 0 (contador que só cresce), CON 50 (legado inerte), DEP 50). Todo valor passa por
## `sanear`: números (int, float ou texto numérico) são convertidos e travados no intervalo; NaN, infinito, booleano, nulo,
## texto não numérico e métricas desconhecidas são REJEITADOS (o valor atual é mantido e o motivo é devolvido).
##
## FÓRMULA DO PERFIL FINAL (`perfil_final`, o único lugar onde ela existe):
##   - 3 perfis, cada um com um índice de 0 a 100 = soma de peso × valor, onde "inverso" usa (máximo + mínimo − valor):
##       autonomo   = 0,5·AUT + 0,3·(100−DEP) + 0,2·(100−CON)
##       conformado = 0,5·CON + 0,3·(100−AUT) + 0,2·DEP
##       dependente = 0,6·DEP + 0,2·(100−AUT) + 0,2·CON
##   - Limiar: se o MAIOR índice for menor que `limiar_minimo` (50), o perfil é "neutro".
##   - Empate: índices que diferem em menos que `epsilon` (0,001) empatam e vence o primeiro de `ordem_avaliacao`
##     (autonomo, conformado, dependente).
##   - Valores ausentes ou inválidos entram com o valor inicial da métrica.
##   - O perfil só CLASSIFICA o desfecho (variante do epílogo, registro e relatório). O final alcançado continua sendo decidido
##     pelos requisitos explícitos da narrativa (flags e provas); a matemática nunca substitui um requisito de progressão.

const AUTONOMIA := "autonomia"
const CONFORMIDADE := "conformidade"
const DEPENDENCIA := "dependencia"
const NOMES: PackedStringArray = ["autonomia", "conformidade", "dependencia"]
const SIGLAS: Dictionary = {"AUT": "autonomia", "CON": "conformidade", "DEP": "dependencia"}
const PERFIL_NEUTRO := "neutro"


## Nome canônico a partir de "AUT", "aut", "Autonomia", "autonomia"... ou "" se não for uma métrica.
static func normalizar_nome(entrada: Variant) -> String:
	if typeof(entrada) != TYPE_STRING and typeof(entrada) != TYPE_STRING_NAME:
		return ""
	var texto := str(entrada).strip_edges()
	var maiusculo := texto.to_upper()
	if SIGLAS.has(maiusculo):
		return str(SIGLAS[maiusculo])
	var minusculo := UtilTexto.normalizar_chave(texto)
	return minusculo if NOMES.has(minusculo) else ""


static func sigla(nome: String) -> String:
	for s in SIGLAS:
		if str(SIGLAS[s]) == nome:
			return str(s)
	return ""


static func rotulo(nome: String) -> String:
	return str(_definicao(nome).get("nome", nome.capitalize()))


static func minimo(nome: String) -> float:
	return _numero(_definicao(nome), "minimo", 0.0)


static func maximo(nome: String) -> float:
	var teto := _numero(_definicao(nome), "maximo", 100.0)
	return maxf(teto, minimo(nome))


static func inicial(nome: String) -> float:
	return clampf(_numero(_definicao(nome), "inicial", 0.0), minimo(nome), maximo(nome))


## Os valores iniciais de todas as métricas: {"autonomia": 50.0, ...}.
static func todas_iniciais() -> Dictionary:
	var saida: Dictionary = {}
	for nome in NOMES:
		saida[nome] = inicial(nome)
	return saida


## Converte e trava `valor` no intervalo da métrica. Devolve {ok, valor, ajustado, motivo}. `ajustado` = foi travado no limite.
static func sanear(valor: Variant, nome: String) -> Dictionary:
	var canonico := normalizar_nome(nome)
	if canonico == "":
		return {"ok": false, "valor": 0.0, "ajustado": false, "motivo": "metrica_desconhecida"}
	var numero_bruto: float = 0.0
	match typeof(valor):
		TYPE_INT, TYPE_FLOAT:
			numero_bruto = float(valor)
		TYPE_STRING, TYPE_STRING_NAME:
			var texto := str(valor).strip_edges()
			if not texto.is_valid_float():
				return {"ok": false, "valor": 0.0, "ajustado": false, "motivo": "valor_nao_numerico"}
			numero_bruto = texto.to_float()
		_:
			return {"ok": false, "valor": 0.0, "ajustado": false, "motivo": "tipo_invalido"}
	if is_nan(numero_bruto) or is_inf(numero_bruto):
		return {"ok": false, "valor": 0.0, "ajustado": false, "motivo": "valor_nao_finito"}
	var travado := clampf(numero_bruto, minimo(canonico), maximo(canonico))
	return {"ok": true, "valor": travado, "ajustado": not is_equal_approx(travado, numero_bruto), "motivo": ""}


## Valor guardado -> valor usável: saneado, ou o inicial quando estiver ausente/inválido (usado ao carregar saves).
static func ou_inicial(valor: Variant, nome: String) -> float:
	var r := sanear(valor, nome)
	return float(r["valor"]) if bool(r["ok"]) else inicial(normalizar_nome(nome))


## Aplica um incremento a `atual`, sempre dentro dos limites. Delta inválido (NaN, texto...) não altera nada.
static func aplicar_delta(atual: float, delta: Variant, nome: String) -> float:
	var passo: float = 0.0
	if delta_valido(delta):
		if typeof(delta) == TYPE_INT or typeof(delta) == TYPE_FLOAT:
			passo = float(delta)
		else:
			passo = str(delta).strip_edges().to_float()
	var base: float = atual
	if is_nan(base) or is_inf(base):
		base = inicial(nome)
	return clampf(base + passo, minimo(nome), maximo(nome))


## `delta` é um número utilizável? (usado para decidir se uma alteração deve ser registrada e avisada)
static func delta_valido(delta: Variant) -> bool:
	match typeof(delta):
		TYPE_INT:
			return true
		TYPE_FLOAT:
			return not (is_nan(float(delta)) or is_inf(float(delta)))
		TYPE_STRING, TYPE_STRING_NAME:
			var texto := str(delta).strip_edges()
			return texto.is_valid_float() and not (is_inf(texto.to_float()) or is_nan(texto.to_float()))
	return false


## Perfil final a partir dos valores {"autonomia": x, ...}. Devolve {perfil, indices, melhor, motivo}. Ver a fórmula no topo.
static func perfil_final(valores: Dictionary) -> Dictionary:
	var configuracao: Dictionary = Regras.secao("perfil_final")
	var limiar := float(configuracao.get("limiar_minimo", 50.0))
	var epsilon := absf(float(configuracao.get("epsilon", 0.001)))
	var perfis: Dictionary = configuracao.get("perfis", {}) if configuracao.get("perfis") is Dictionary else {}
	var ordem: Array = configuracao.get("ordem_avaliacao", []) if configuracao.get("ordem_avaliacao") is Array else []
	var usados: Dictionary = {}
	for nome in NOMES:
		usados[nome] = ou_inicial(valores.get(nome), nome)
	var indices: Dictionary = {}
	var ids: Array = []
	for id_perfil in ordem:
		if perfis.has(str(id_perfil)) and not ids.has(str(id_perfil)):
			ids.append(str(id_perfil))
	for id_perfil in perfis:
		if not ids.has(str(id_perfil)):
			ids.append(str(id_perfil))
	for id_perfil in ids:
		indices[id_perfil] = _indice(perfis.get(id_perfil), usados)
	var melhor_id := ""
	var melhor_valor := -1.0
	for id_perfil in ids:   # percorre na ordem de avaliação: só um índice MAIOR (além do epsilon) toma o lugar
		var v: float = float(indices[id_perfil])
		if melhor_id == "" or v > melhor_valor + epsilon:
			melhor_id = str(id_perfil)
			melhor_valor = v
	if melhor_id == "" or melhor_valor < limiar:
		return {"perfil": PERFIL_NEUTRO, "indices": indices, "melhor": melhor_valor, "motivo": "abaixo_do_limiar" if melhor_id != "" else "sem_perfis"}
	return {"perfil": melhor_id, "indices": indices, "melhor": melhor_valor, "motivo": ""}


# ------------------------------------------------------------------ internos
static func _definicao(nome: String) -> Dictionary:
	var canonico := normalizar_nome(nome)
	var todas: Dictionary = Regras.secao("metricas")
	var d: Variant = todas.get(canonico, {})
	return d if d is Dictionary else {}


static func _numero(d: Dictionary, chave: String, padrao: float) -> float:
	var v: Variant = d.get(chave, padrao)
	if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
		var f := float(v)
		return f if not (is_nan(f) or is_inf(f)) else padrao
	return padrao


## Índice de um perfil: soma de peso × valor (ou do valor invertido), cada termo [metrica, direcao(1|-1), peso].
static func _indice(perfil: Variant, valores: Dictionary) -> float:
	if not (perfil is Dictionary):
		return 0.0
	var termos: Variant = (perfil as Dictionary).get("termos", [])
	if not (termos is Array):
		return 0.0
	var total := 0.0
	for termo in termos:
		if not (termo is Array) or (termo as Array).size() < 3:
			continue
		var nome := normalizar_nome((termo as Array)[0])
		if nome == "":
			continue
		var valor := float(valores.get(nome, inicial(nome)))
		var direcao := int((termo as Array)[1])
		var peso := float((termo as Array)[2])
		if direcao < 0:
			valor = maximo(nome) + minimo(nome) - valor
		total += peso * valor
	return total
