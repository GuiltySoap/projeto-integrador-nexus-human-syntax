class_name Conexoes
extends RefCounted
## Guarda conexões de sinais e as desfaz de uma vez (chame desligar_tudo() em _exit_tree).
## Evita sinais pendurados em autoloads quando uma tela/janela é destruída.

var _lista: Array = []


func ligar(sinal: Signal, alvo: Callable) -> void:
	if sinal.is_connected(alvo):
		return
	sinal.connect(alvo)
	_lista.append([sinal, alvo])


func desligar_tudo() -> void:
	for par in _lista:
		var s: Signal = par[0]
		var c: Callable = par[1]
		if s.is_connected(c):
			s.disconnect(c)
	_lista.clear()
