class_name PilotoRoteiro
extends RefCounted
## Jogador automático e determinístico do roteiro v2.0 para os testes: percorre os nós usando o MESMO motor do jogo (GerenciadorNarrativa).
## O plano diz o que fazer em cada ponto; o que o plano não cita usa o padrão (primeira opção visível; cartões: permitir; barra: completa).
##   plano = {
##     "escolhas":  {"T1.4": "pode_organizar", ...},   # id do nó -> id da opção
##     "cartoes":   {"permissao_contatos": "negar"},   # id da permissão -> "permitir" | "negar" (padrão "permitir")
##     "barra":     "completa" | "cancelar",
##     "minigames": "ok" | "sair",
##     "rotina":    true,                              # T3.5: conclui a janela da rotina
##     "parar_em":  "T6.5",                            # para ANTES de agir neste nó
##     "ganchos":   {"T7.4": Callable},                # roda UMA vez ao chegar no nó (simula o que o jogador faz fora do chat)
##   }
## Devolve o nó em que parou. Nunca passa de LIMITE passos (evita laço infinito num teste com defeito).

const LIMITE := 600

var passos: Array = []   # todos os nós em que o roteiro entrou, na ordem
var _ganchos_usados: Dictionary = {}


static func jogar(plano: Dictionary) -> PilotoRoteiro:
	var p := PilotoRoteiro.new()
	# Registra TODOS os nós em que o roteiro entrou, inclusive fala/rota que encadeiam sozinhos.
	GerenciadorNarrativa.no_entrou.connect(p._ao_entrar)
	p._rodar(plano)
	if GerenciadorNarrativa.no_entrou.is_connected(p._ao_entrar):
		GerenciadorNarrativa.no_entrou.disconnect(p._ao_entrar)
	return p


func _ao_entrar(id_no: String) -> void:
	passos.append(id_no)


func _rodar(plano: Dictionary) -> void:
	for _i in LIMITE:
		var id_no := GerenciadorEstado.no_roteiro
		if not GerenciadorNarrativa.jogo_ativo:
			return
		if str(plano.get("parar_em", "")) == id_no:
			return
		var ganchos: Dictionary = plano.get("ganchos", {})
		if ganchos.has(id_no) and not _ganchos_usados.has(id_no):
			_ganchos_usados[id_no] = true
			(ganchos[id_no] as Callable).call()
			if GerenciadorEstado.no_roteiro != id_no:
				continue   # o gancho mudou de nó
		var def := GerenciadorNarrativa.no_atual()
		var tipo := str(def.get("tipo", ""))
		var andou := false
		match tipo:
			"escolha":
				andou = _escolher(def, id_no, plano)
			"espera":
				andou = _esperar(def, id_no, plano)
			"cartoes":
				andou = _cartoes(plano)
			"janela":
				GerenciadorNarrativa.notificar(str(def.get("espera", "")))
				andou = GerenciadorEstado.no_roteiro != id_no
			"minigame":
				GerenciadorNarrativa.concluir_minigame(str(def.get("minigame", "")), str(plano.get("minigames", "ok")))
				andou = GerenciadorEstado.no_roteiro != id_no
			"barra_envio":
				if str(plano.get("barra", "completa")) == "cancelar":
					andou = GerenciadorNarrativa.cancelar_envio()
					if not andou:
						GerenciadorNarrativa.pausado = false
						GerenciadorNarrativa._process(0.01)
						andou = GerenciadorNarrativa.cancelar_envio()
				else:
					GerenciadorNarrativa.pausado = false
					GerenciadorNarrativa._process(GerenciadorNarrativa.duracao_da_barra() + 0.1)
					GerenciadorNarrativa.pausado = true
					andou = GerenciadorEstado.no_roteiro != id_no
			_:
				return   # fala/rota/fim encadeiam sozinhos; parar aqui significa que algo travou
		if not andou:
			return


func _escolher(def: Dictionary, id_no: String, plano: Dictionary) -> bool:
	var escolhas: Dictionary = plano.get("escolhas", {})
	var visiveis: Array = FluxoRoteiro.opcoes_visiveis(def, GerenciadorNarrativa._consumidas())
	if visiveis.is_empty():
		return false
	var id_opcao := str(escolhas.get(id_no, (visiveis[0] as Dictionary)["id"]))
	return GerenciadorNarrativa.escolher_opcao(id_opcao)


func _esperar(def: Dictionary, id_no: String, plano: Dictionary) -> bool:
	var escolhas: Dictionary = plano.get("escolhas", {})
	if escolhas.has(id_no):
		return GerenciadorNarrativa.escolher_opcao(str(escolhas[id_no]))
	var evento := str(def.get("evento", ""))
	if evento != "":
		GerenciadorNarrativa.notificar(evento)
		return GerenciadorEstado.no_roteiro != id_no
	if def.get("saidas") is Array and not (def["saidas"] as Array).is_empty():
		GerenciadorNarrativa.notificar(str(((def["saidas"] as Array)[0] as Dictionary).get("evento", "")))
		return GerenciadorEstado.no_roteiro != id_no
	if def.get("opcoes") is Array:
		var visiveis: Array = FluxoRoteiro.opcoes_visiveis(def, GerenciadorNarrativa._consumidas())
		if not visiveis.is_empty():
			return GerenciadorNarrativa.escolher_opcao(str((visiveis[0] as Dictionary)["id"]))
	return false


func _cartoes(plano: Dictionary) -> bool:
	var decisoes: Dictionary = plano.get("cartoes", {})
	var andou := false
	for _k in 12:
		var cartao := GerenciadorNarrativa.cartao_atual()
		if cartao.is_empty():
			break
		var id_perm := str(cartao["permissao"])
		var decisao := str(decisoes.get(id_perm, "permitir"))
		var r := GerenciadorNarrativa.decidir_cartao(id_perm, decisao)
		if bool(r.get("requer_confirmacao", false)):
			r = GerenciadorNarrativa.decidir_cartao(id_perm, decisao, true)
		andou = andou or bool(r.get("ok", false))
		if not bool(r.get("ok", false)):
			break
	return andou
