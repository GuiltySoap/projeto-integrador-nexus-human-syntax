class_name MenuPausa
extends CamadaSobreposta
## Menu de Pausa do jogo (a área de trabalho). Abre com Esc (ação `ui_cancel`, a mesma do resto do jogo) e PAUSA de verdade
## (`get_tree().paused`): relógio da narrativa, autosave, animações, temporizadores e a trilha ficam parados; só este menu e os
## sons de interface continuam. Existe uma única instância, que mora na cena da área de trabalho; Esc apenas a mostra e a esconde.
##   - Continuar (ou Esc de novo): fecha e retoma exatamente de onde estava, com o foco no que o tinha antes.
##   - Salvar jogo: grava o salvamento principal agora (o mesmo do autosave) e avisa se deu certo.
##   - Carregar salvamento anterior: o mesmo carregamento do botão Carregar do Menu Principal (Sessao.carregar), só com pontos
##     seguros e com confirmação. Sem ponto válido: "Nenhum salvamento anterior disponível.".
##   - Recomeçar jogo: reinicia a campanha no Dia 1 mantendo o nome do usuário, com confirmação (o salvamento é substituído).
##   - Opções: o mesmo painel do Menu Principal. Retornar ao menu inicial: com confirmação.
## Quem decide quando o Esc pode abrir a pausa é a área de trabalho (nada de modal aberto, jogo ativo, sem troca em andamento);
## quem fecha com Esc é este menu (a confirmação e as opções usam `_input` e consomem o Esc antes, então têm prioridade).
## Toda a estrutura vive em menu_pausa.tscn; a lógica comum das ações vive em CamadaSobreposta.

signal aberto_alterado(aberto: bool)

@onready var _btn_continuar: Button = %BotaoContinuar
@onready var _btn_salvar: Button = %BotaoSalvar
@onready var _btn_carregar: Button = %BotaoCarregar
@onready var _btn_recomecar: Button = %BotaoRecomecar
@onready var _btn_opcoes: Button = %BotaoOpcoes
@onready var _btn_menu: Button = %BotaoMenuInicial
@onready var _rot_contexto: Label = %RotuloContexto
@onready var _painel_opcoes: PainelOpcoes = %PainelOpcoes
@onready var _coluna: Control = %PainelPrincipal


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	_painel_principal = _coluna
	if not _refs_base_ok():
		return
	if not UiKit.refs_ok(self, {"BotaoContinuar": _btn_continuar, "BotaoSalvar": _btn_salvar, "BotaoCarregar": _btn_carregar, "BotaoRecomecar": _btn_recomecar, "BotaoOpcoes": _btn_opcoes, "BotaoMenuInicial": _btn_menu, "RotuloContexto": _rot_contexto, "PainelOpcoes": _painel_opcoes}):
		return
	_ligar_foco()


func _botoes() -> Array:
	return [_btn_continuar, _btn_salvar, _btn_carregar, _btn_recomecar, _btn_opcoes, _btn_menu]


func _origem_sessao() -> Sessao.Origem:
	return Sessao.Origem.PAUSA


func _botao_da_acao(acao: StringName) -> Button:
	match acao:
		&"carregar":
			return _btn_carregar
		&"recomecar":
			return _btn_recomecar
		&"menu":
			return _btn_menu
	return _btn_continuar


func _painel_extra_aberto() -> bool:
	return _painel_opcoes.esta_aberto()


func _atualizar_estado_dos_botoes() -> void:
	var titulo: String = GerenciadorNarrativa.titulo_da_etapa(GerenciadorEstado.etapa_atual)
	_rot_contexto.text = "%s · %s" % [GerenciadorEstado.nome_jogador, titulo] if titulo != "" else GerenciadorEstado.nome_jogador
	_btn_salvar.disabled = _ocupado or not SistemaPersistencia.habilitado or not GerenciadorNarrativa.jogo_ativo


## Abre a pausa. Devolve false (sem mudar nada) se já está aberta, se há uma troca de cena em curso ou se a árvore já está
## pausada por outra camada (ex.: Fim de Jogo).
func abrir() -> bool:
	if _aberta or _ocupado or Cenas.em_transicao() or get_tree().paused:
		return false
	_abrir_camada()
	SistemaAudio.tocar_sfx("clique", -6.0)
	_btn_continuar.call_deferred("grab_focus")
	aberto_alterado.emit(true)
	return true


## Fecha a pausa e retoma o jogo. Não faz nada durante uma troca de cena (o Esc fica sem efeito até ela terminar ou falhar).
func fechar() -> void:
	if not _aberta or _ocupado:
		return
	if _painel_opcoes.esta_aberto():
		_painel_opcoes.fechar()
	_fechar_camada()
	SistemaAudio.tocar_sfx("clique", -8.0)
	aberto_alterado.emit(false)


## Esc com a pausa aberta fecha a pausa. A confirmação e as opções usam `_input` e consomem o Esc antes: só chega aqui o que
## nenhum painel tratou. Sempre marca a tecla como tratada, senão a área de trabalho (já despausada) a leria como "abrir".
func _unhandled_input(evento: InputEvent) -> void:
	if _aberta and evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		fechar()


# ------------------------------------------------------------------ botões (ligados na cena)
func _ao_continuar() -> void:
	fechar()


func _ao_salvar() -> void:
	if _bloqueado():
		return
	SistemaAudio.tocar_sfx("clique", -8.0)
	if SistemaPersistencia.salvar():
		_mostrar_status("Progresso salvo.", false)
	else:
		_mostrar_status("Não foi possível salvar o progresso.", true)


func _ao_carregar() -> void:
	_iniciar_carga(_btn_carregar)


func _ao_recomecar() -> void:
	_iniciar_recomeco(_btn_recomecar)


func _ao_menu_inicial() -> void:
	_iniciar_menu(_btn_menu)


func _ao_opcoes() -> void:
	if _bloqueado():
		return
	SistemaAudio.tocar_sfx("clique", -8.0)
	_limpar_status()
	_abrir_modal(_btn_opcoes)
	_painel_opcoes.abrir()
