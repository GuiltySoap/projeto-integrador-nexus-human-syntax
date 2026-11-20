class_name PainelDebug
extends PanelContainer
## Painel de testes (F9) para validar o roteiro sem repetir tudo: ir a um nó, ajustar D e A, salvar e ver as flags. Só abre no
## editor/builds de depuração ou quando "Painel de testes" estiver ligado em Configurações > Sistema. Atualiza por sinais (sem Timer).
## A estrutura está em painel_debug.tscn; os botões chamam os métodos _ao_* abaixo por conexões de sinal da própria cena.

var _cx := Conexoes.new()
var _atualizacao_pendente: bool = false

@onready var _rot_estado: Label = %RotuloEstado
@onready var _lista: RichTextLabel = %ListaFlags
@onready var _campo_no: LineEdit = %CampoNo


static func permitido() -> bool:
	return OS.is_debug_build() or bool(GerenciadorConfiguracoes.obter("modo_depuracao"))


func _ready() -> void:
	if not UiKit.refs_ok(self, {"RotuloEstado": _rot_estado, "ListaFlags": _lista, "CampoNo": _campo_no}):
		return
	_cx.ligar(GerenciadorEstado.flag_alterada, _ao_flag)
	_cx.ligar(GerenciadorEstado.roteiro_alterado, _ao_roteiro)
	_cx.ligar(GerenciadorEstado.dependencia_alterada, _ao_variavel)
	_cx.ligar(GerenciadorEstado.autonomia_alterada, _ao_variavel)


func _exit_tree() -> void:
	_cx.desligar_tudo()


# Também conectado na cena: BotaoFechar.pressed
func alternar() -> void:
	visible = not visible
	if visible:
		atualizar()


func atualizar() -> void:
	_rot_estado.text = "%s | nó %s | D %d | A %d | permissões %d/5 | janelas: %d" % [
		GerenciadorEstado.task_atual, GerenciadorEstado.no_roteiro, GerenciadorEstado.dependencia_maya(), GerenciadorEstado.autonomia_jogador(),
		GerenciadorEstado.permissoes_ativas(), GerenciadorJanelas.janelas().size(),
	]
	var chaves: Array = GerenciadorEstado.flags.keys()
	chaves.sort()
	var linhas: PackedStringArray = PackedStringArray()
	for chave in chaves:
		linhas.append("%s = %s" % [UtilTexto.escapar_bbcode(str(chave)), UtilTexto.escapar_bbcode(str(GerenciadorEstado.flags[chave]))])
	_lista.text = "\n".join(linhas)


func _agendar_atualizacao() -> void:
	if _atualizacao_pendente or not visible:
		return
	_atualizacao_pendente = true
	_atualizar_adiado.call_deferred()


func _atualizar_adiado() -> void:
	_atualizacao_pendente = false
	if visible:
		atualizar()


func _ao_flag(_nome: String, _valor: Variant) -> void:
	_agendar_atualizacao()


func _ao_roteiro(_id_no: String) -> void:
	_agendar_atualizacao()


func _ao_variavel(_valor: int, _motivo: StringName) -> void:
	_agendar_atualizacao()


# Conectado na cena (botão): vai direto a um nó do roteiro (ex.: T6.3, T9.1, AV). Não refaz os efeitos dos nós anteriores.
func _ao_ir_para_no() -> void:
	var id_no := _campo_no.text.strip_edges()
	if not FluxoRoteiro.existe(id_no):
		SistemaNotificacoes.notificar("Painel de testes", "Nó inexistente: %s" % id_no, "aviso", 4.0)
		return
	GerenciadorNarrativa.ir_para_no(id_no)
	atualizar()


# Conectado na cena (botão)
func _ao_dependencia_mais() -> void:
	GerenciadorEstado.alterar_dependencia_maya(10, &"depuracao")
	atualizar()


# Conectado na cena (botão)
func _ao_dependencia_menos() -> void:
	GerenciadorEstado.alterar_dependencia_maya(-10, &"depuracao")
	atualizar()


# Conectado na cena (botão)
func _ao_toast_info() -> void:
	SistemaNotificacoes.notificar("Teste", "Notificação de teste (%d)." % Time.get_ticks_msec(), "info", 5.0)


# Conectado na cena (botão)
func _ao_salvar() -> void:
	var ok := SistemaPersistencia.salvar()
	SistemaNotificacoes.notificar("Painel de testes", "Salvo." if ok else "Falha ao salvar.", "sucesso" if ok else "erro", 3.0)
