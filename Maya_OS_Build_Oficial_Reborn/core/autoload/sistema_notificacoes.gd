extends Node
## Fila e histórico de notificações. Só dados e sinais: quem desenha os toasts é a área de trabalho
## e quem abre aplicativos a partir de um toast é o próprio shell (este autoload não conhece janelas).

signal notificacao_emitida(notificacao: Dictionary)
signal historico_alterado()

const NIVEIS := ["info", "ia", "aviso", "erro", "critico", "sucesso"]
const LIMITE_HISTORICO := 60
const JANELA_DEDUP := 3.0  # segundos: mesma notificação repetida dentro deste intervalo é ignorada

var historico: Array = []
var silenciar_toasts: bool = false
var _contador: int = 0
var _ultima: Dictionary = {}
var _agora: float = 0.0


func _process(delta: float) -> void:
	_agora += delta


func notificar(titulo: String, texto: String, nivel: String = "info", duracao: float = 6.0, abrir_app: String = "") -> Dictionary:
	var nivel_ok := nivel if NIVEIS.has(nivel) else "info"
	var titulo_fmt := GerenciadorEstado.formatar(titulo)
	var texto_fmt := GerenciadorEstado.formatar(texto)
	var assinatura := titulo_fmt + "|" + texto_fmt
	if _ultima.get("assinatura", "") == assinatura and _agora - float(_ultima.get("quando", -100.0)) < JANELA_DEDUP:
		return {}
	_ultima = {"assinatura": assinatura, "quando": _agora}
	_contador += 1
	var n := {
		"id": _contador,
		"titulo": titulo_fmt,
		"texto": texto_fmt,
		"nivel": nivel_ok,
		"duracao": clampf(duracao, 2.0, 20.0),
		"abrir_app": abrir_app,
		"hora": RelogioGlobal.hora_texto(),
		"lida": false,
		"exibir_toast": not silenciar_toasts,
	}
	historico.push_front(n)
	if historico.size() > LIMITE_HISTORICO:
		historico.resize(LIMITE_HISTORICO)
	notificacao_emitida.emit(n)
	historico_alterado.emit()
	return n


func nao_lidas() -> int:
	var total := 0
	for n in historico:
		if not bool(n.get("lida", false)):
			total += 1
	return total


func marcar_lida(id_notificacao: int) -> void:
	for n in historico:
		if int(n.get("id", -1)) == id_notificacao and not bool(n.get("lida", false)):
			n["lida"] = true
			historico_alterado.emit()
			return


func marcar_todas_lidas() -> void:
	for n in historico:
		n["lida"] = true
	historico_alterado.emit()


func limpar_historico() -> void:
	historico.clear()
	historico_alterado.emit()
