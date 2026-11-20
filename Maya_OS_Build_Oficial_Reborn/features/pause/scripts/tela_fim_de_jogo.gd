class_name TelaFimDeJogo
extends CamadaSobreposta
## Tela de Fim de Jogo: aparece sozinha quando a história termina e oferece as três saídas (Recomeçar Jogo, Carregar Salvamento
## Anterior, Retornar ao Menu Inicial), sempre com confirmação e sem nunca deixar o jogador sem saída.
##
## O gatilho é o evento que já existe: GerenciadorNarrativa.jogo_finalizado (os quatro finais). A TelaFinal o recebe, mostra o
## epílogo e, depois dele, abre esta tela; se a TelaFinal não puder abrir, a área de trabalho abre esta tela no lugar. Esta tela
## NÃO decide quando o jogo termina nem guarda estado: só recebe o que mostrar em `abrir()`.
##   - abre uma única vez (segunda chamada é ignorada) e pausa a árvore, como a Pausa;
##   - Carregar usa só pontos seguros (sem final): carregar o salvamento do próprio final reabriria esta tela em ciclo;
##   - "Rever epílogo" (só quando a TelaFinal é a dona) fecha esta tela e devolve a TelaFinal, com o resumo e as saídas dela;
##   - Esc faz o mesmo que "Rever epílogo" quando ele existe; sem ele, não faz nada (não há "continuar" depois do fim).
## Toda a estrutura vive em tela_fim_de_jogo.tscn; a lógica comum das ações vive em CamadaSobreposta.

## O jogador pediu para rever o epílogo (a tela dona volta a ser a visível e já pode agir).
signal rever_pedido

var _pode_rever: bool = false

@onready var _rot_titulo: Label = %Titulo
@onready var _rot_motivo: Label = %MensagemMotivo
@onready var _rot_resumo: Label = %Resumo
@onready var _btn_recomecar: Button = %BotaoRecomecar
@onready var _btn_carregar: Button = %BotaoCarregar
@onready var _btn_menu: Button = %BotaoMenuInicial
@onready var _btn_rever: Button = %BotaoRever
@onready var _painel: Control = %Painel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	_painel_principal = _painel
	if not _refs_base_ok():
		return
	if not UiKit.refs_ok(self, {"Titulo": _rot_titulo, "MensagemMotivo": _rot_motivo, "Resumo": _rot_resumo, "BotaoRecomecar": _btn_recomecar, "BotaoCarregar": _btn_carregar, "BotaoMenuInicial": _btn_menu, "BotaoRever": _btn_rever, "Painel": _painel}):
		return
	_ligar_foco()


## Uma linha com o resumo da jornada, lido do estado do jogo (a mesma fonte das linhas de resumo da TelaFinal).
static func resumo_da_jornada() -> String:
	return "Usuário: %s · Dependência da Maya: %d · Autonomia: %d" % [GerenciadorEstado.nome_jogador, GerenciadorEstado.dependencia_maya(), GerenciadorEstado.autonomia_jogador()]


func _botoes() -> Array:
	return [_btn_recomecar, _btn_carregar, _btn_menu, _btn_rever]


func _origem_sessao() -> Sessao.Origem:
	return Sessao.Origem.FIM_DE_JOGO


func _botao_da_acao(acao: StringName) -> Button:
	match acao:
		&"carregar":
			return _btn_carregar
		&"menu":
			return _btn_menu
	return _btn_recomecar


func _atualizar_estado_dos_botoes() -> void:
	_btn_rever.visible = _pode_rever
	_btn_rever.disabled = _ocupado


## Abre a tela de fim de jogo e pausa a árvore. `motivo` é o texto principal (o final alcançado, ou por que o epílogo não abriu),
## `resumo` uma linha com o resumo da jornada e `cor_motivo` a cor do final. Devolve false, sem mudar nada, se a tela já está
## aberta ou se há uma troca de cena em curso (aí o jogador já está saindo para outro lugar).
func abrir(motivo: String, resumo: String, cor_motivo: Color = Color(1, 1, 1, 1), pode_rever: bool = false) -> bool:
	if _aberta or _ocupado or Cenas.em_transicao():
		return false
	_pode_rever = pode_rever
	_rot_motivo.text = motivo
	_rot_motivo.add_theme_color_override("font_color", cor_motivo)
	_rot_resumo.text = resumo
	_rot_resumo.visible = resumo != ""
	_abrir_camada()
	SistemaAudio.tocar_sfx("clique", -6.0)
	_btn_recomecar.call_deferred("grab_focus")
	return true


## Fecha a tela (só "Rever epílogo" a fecha) e devolve o jogo ao que estava por trás.
func _fechar() -> void:
	if not _aberta or _ocupado:
		return
	_fechar_camada()


## Esc faz o mesmo que "Rever epílogo" quando ele existe. A confirmação consome o Esc antes (`_input`), então só chega aqui o
## que ela não tratou. Marca a tecla como tratada para a tela dona não reagir a ela.
func _unhandled_input(evento: InputEvent) -> void:
	if _aberta and evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _pode_rever and not _bloqueado():
			_ao_rever()


# ------------------------------------------------------------------ botões (ligados na cena)
func _ao_recomecar() -> void:
	_iniciar_recomeco(_btn_recomecar)


func _ao_carregar() -> void:
	_iniciar_carga(_btn_carregar)


func _ao_menu_inicial() -> void:
	_iniciar_menu(_btn_menu)


func _ao_rever() -> void:
	if _bloqueado() or not _pode_rever:
		return
	SistemaAudio.tocar_sfx("clique", -8.0)
	_fechar()
	rever_pedido.emit()
