class_name LogicaContradicao
extends RefCounted
## Regras PURAS de "A trava do Rafael" (Task 7): entre três afirmações, escolher a que as evidências desmentem. Sem tempo, tentativas ilimitadas.
## Estado: {"erros": int, "resolvido": bool}. Dica depois de dois erros: a linha "saí. ela não sabe." fica destacada em E1.


static func estado_inicial() -> Dictionary:
	return {"erros": 0, "resolvido": false}


static func carregar(salvo: Variant) -> Dictionary:
	var base := estado_inicial()
	if salvo is Dictionary:
		base["erros"] = maxi(0, int((salvo as Dictionary).get("erros", 0)))
		base["resolvido"] = bool((salvo as Dictionary).get("resolvido", false))
	return base


static func afirmacao(def: Dictionary, id: String) -> Dictionary:
	for a in def.get("afirmacoes", []):
		if str((a as Dictionary).get("id", "")) == id:
			return a
	return {}


## [Confirmar]: devolve {"ok", "mensagem", "estado"}. Escolha inexistente não conta como erro.
static func confirmar(def: Dictionary, estado: Dictionary, id: String) -> Dictionary:
	var a := afirmacao(def, id)
	var novo := estado.duplicate()
	if a.is_empty():
		return {"ok": false, "mensagem": "", "estado": novo}
	if bool(a.get("correta", false)):
		novo["resolvido"] = true
		return {"ok": true, "mensagem": "", "estado": novo}
	novo["erros"] = int(estado.get("erros", 0)) + 1
	var refs: Array = a.get("confirmada_por", [])
	var lista := ", ".join(PackedStringArray(refs.map(func(x): return str(x))))
	return {"ok": false, "mensagem": str(def.get("erro_formato", "%s")) % lista, "estado": novo}


static func dica_ativa(estado: Dictionary, limite: int = 2) -> bool:
	return int(estado.get("erros", 0)) >= limite
