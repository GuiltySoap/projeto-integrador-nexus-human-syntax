class_name BancaDeTestes
extends RefCounted
## Contador e relatório compartilhados pelos módulos da suíte dos sistemas novos (tests/sistemas_novos/).
## Cada verificação vira uma linha "OK: ..." ou "FALHA: ..." no painel Saída e em <pasta>/log.txt; quem decide o código de saída é o executor.

var verificacoes: int = 0
var falhas: int = 0

var _pasta: String = ""
var _log: PackedStringArray = PackedStringArray()


func _init(pasta: String = "") -> void:
	_pasta = pasta


## Registra uma verificação. Devolve a própria condição (para `if not b.ok(...): return`).
func ok(condicao: bool, mensagem: String) -> bool:
	verificacoes += 1
	if not condicao:
		falhas += 1
	registrar("%s: %s" % ["OK" if condicao else "FALHA", mensagem])
	return condicao


## Compara o valor obtido com o esperado (números por aproximação; o resto por tipo e valor) e mostra os dois na falha.
func igual(obtido: Variant, esperado: Variant, mensagem: String) -> bool:
	var certo: bool = false
	if _eh_numero(obtido) and _eh_numero(esperado):
		certo = is_equal_approx(float(obtido), float(esperado))
	else:
		certo = typeof(obtido) == typeof(esperado) and obtido == esperado
	if certo:
		return ok(true, mensagem)
	return ok(false, "%s (obtido %s, esperado %s)" % [mensagem, var_to_str(obtido), var_to_str(esperado)])


## Compara dois números com tolerância (padrão 0,001).
func perto(obtido: float, esperado: float, mensagem: String, tolerancia: float = 0.001) -> bool:
	if absf(obtido - esperado) <= tolerancia:
		return ok(true, mensagem)
	return ok(false, "%s (obtido %s, esperado %s)" % [mensagem, str(obtido), str(esperado)])


func secao(titulo: String) -> void:
	registrar("== %s" % titulo)


func registrar(linha: String) -> void:
	_log.append(linha)
	print("[sistemas_novos] ", linha)


## Grava o relatório. Sem pasta (ou sem permissão de gravação) não faz nada: o painel Saída já tem tudo.
func gravar() -> void:
	if _pasta == "":
		return
	var f := FileAccess.open(_pasta + "log.txt", FileAccess.WRITE)
	if f == null:
		return
	f.store_string("\n".join(_log) + "\n")
	f.close()


static func _eh_numero(valor: Variant) -> bool:
	return typeof(valor) == TYPE_INT or typeof(valor) == TYPE_FLOAT
