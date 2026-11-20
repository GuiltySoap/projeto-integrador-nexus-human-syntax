extends Node
## Relógio único do jogo. Evita criar vários Timers: todos os sistemas escutam estes sinais.

signal segundo_passou(unix: int)
signal minuto_mudou(hora: int, minuto: int)

const MESES := ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"]
const DIAS_SEMANA := ["domingo", "segunda-feira", "terça-feira", "quarta-feira", "quinta-feira", "sexta-feira", "sábado"]

var _acumulado: float = 0.0
var _ultimo_minuto: int = -1


func _process(delta: float) -> void:
	_acumulado += delta
	if _acumulado < 1.0:
		return
	_acumulado -= 1.0
	var agora := Time.get_datetime_dict_from_system()
	segundo_passou.emit(int(Time.get_unix_time_from_system()))
	if int(agora["minute"]) != _ultimo_minuto:
		_ultimo_minuto = int(agora["minute"])
		minuto_mudou.emit(int(agora["hour"]), _ultimo_minuto)


func hora_texto(com_segundos: bool = false) -> String:
	var d := Time.get_datetime_dict_from_system()
	if com_segundos:
		return "%02d:%02d:%02d" % [d["hour"], d["minute"], d["second"]]
	return "%02d:%02d" % [d["hour"], d["minute"]]


func data_texto() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%02d/%02d/%04d" % [d["day"], d["month"], d["year"]]


## Data fictícia do jogo: o Dia N da narrativa acontece (N-1) dias depois do início da sessão.
func data_do_jogo(dia: int, inicio_unix: int) -> Dictionary:
	var base := inicio_unix if inicio_unix > 0 else int(Time.get_unix_time_from_system())
	return Time.get_datetime_dict_from_unix_time(base + (dia - 1) * 86400)


func data_jogo_texto(dia: int, inicio_unix: int) -> String:
	var d := data_do_jogo(dia, inicio_unix)
	return "%02d/%02d/%04d" % [d["day"], d["month"], d["year"]]


func nome_mes(mes: int) -> String:
	return MESES[clampi(mes - 1, 0, 11)]


func nome_dia_semana(indice: int) -> String:
	return DIAS_SEMANA[clampi(indice, 0, 6)]


func dias_no_mes(ano: int, mes: int) -> int:
	match mes:
		2:
			var bissexto := (ano % 4 == 0 and ano % 100 != 0) or ano % 400 == 0
			return 29 if bissexto else 28
		4, 6, 9, 11:
			return 30
		_:
			return 31


## Dia da semana (0 = domingo) do primeiro dia do mês.
func dia_semana_do_primeiro(ano: int, mes: int) -> int:
	var unix := Time.get_unix_time_from_datetime_dict({"year": ano, "month": mes, "day": 1, "hour": 12, "minute": 0, "second": 0})
	var d := Time.get_datetime_dict_from_unix_time(unix)
	return int(d["weekday"])
