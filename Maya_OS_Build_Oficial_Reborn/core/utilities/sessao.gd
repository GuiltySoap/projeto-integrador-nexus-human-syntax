class_name Sessao
extends RefCounted
## Fluxos de sessão compartilhados pelo Menu Principal, pela Pausa e pela Tela de Fim de Jogo: novo jogo, recomeçar, carregar o
## salvamento anterior e voltar ao Menu Principal. As três telas chamam SÓ estas funções, então "Carregar" é a mesma ação
## em qualquer lugar e não existe um segundo sistema de carga ou de reinício.
##
## Nada aqui guarda estado do jogo (isso é do GerenciadorEstado/GerenciadorNarrativa) nem grava arquivos (isso é do
## SistemaPersistencia, que já salva ao iniciar cada Task). Aqui só se ordena o que já existe:
##   1) conferir tudo o que pode falhar ANTES de mexer em qualquer coisa (o arquivo de salvamento, a cena de destino);
##   2) desligar a sessão atual (a área de trabalho solta sinais e fecha janelas);
##   3) trocar o estado (campanha nova ou salvamento aplicado);
##   4) trocar a cena, com a árvore despausada (tudo isso é feito por `Cenas.ir_para`, que roda os passos 2 e 3 no gancho
##      `preparar`, depois que a cena de destino já foi carregada).
## Os autoloads continuam os mesmos: só os dados que eles guardam são reiniciados ou substituídos. As configurações do
## jogador (áudio, tela, acessibilidade) não fazem parte da campanha e nunca são alteradas aqui.

## De onde a tela chama. Define quais pontos de carga valem: o Menu aceita qualquer salvamento (inclusive de uma história
## concluída, que reabre o epílogo); a Pausa e o Fim de Jogo só aceitam pontos seguros (sem final), para nunca reabrir um
## final por cima de uma sessão que acabou de recomeçar.
enum Origem { MENU, PAUSA, FIM_DE_JOGO }

const MSG_SEM_REGISTRO := "Nenhum registro de sessão disponível."
const MSG_SEM_SALVAMENTO := "Nenhum salvamento anterior disponível."
const MSG_FALHA_CARGA := "Não foi possível restaurar a sessão. O estado atual permanece protegido."
const MSG_FALHA_TROCA := "Não foi possível abrir a próxima tela. O jogo continua como estava."
const TEXTO_CONFIRMAR_MENU := "Retornar ao Menu Inicial?\n\nO progresso não salvo da sessão atual poderá ser perdido."
const TEXTO_CONFIRMAR_CARGA := "Carregar o último salvamento?\n\nO progresso não salvo desta sessão será descartado."
const TEXTO_CONFIRMAR_RECOMECAR := "Recomeçar o jogo?\n\nA campanha volta ao início e todo o progresso atual será descartado. O salvamento existente será substituído por este novo começo. As configurações do jogo (áudio, tela e acessibilidade) são mantidas."


## Ponto de carga (salvamento principal ou checkpoint) que a tela de `origem` pode usar. Ver SistemaPersistencia.ponto_de_carga.
static func ponto_de_carga(origem: int) -> Dictionary:
	return SistemaPersistencia.ponto_de_carga(origem != Origem.MENU)


## Mensagem para quando não há o que carregar a partir de `origem`.
static func mensagem_sem_ponto(origem: int) -> String:
	return MSG_SEM_REGISTRO if origem == Origem.MENU else MSG_SEM_SALVAMENTO


## Texto curto que descreve um ponto de carga ("Ana — Setup e Reconhecimento · salvo em ...", "Ana — história concluída · ...").
static func descrever_ponto(ponto: Dictionary) -> String:
	if not bool(ponto.get("existe", false)):
		return ""
	var situacao: String = "história concluída" if str(ponto.get("final_id", "")) != "" else GerenciadorNarrativa.titulo_da_etapa(int(ponto.get("etapa", 1)))
	var origem: String = "checkpoint" if str(ponto.get("tipo", "")) == "checkpoint" else "salvo"
	var quando: String = str(ponto.get("salvo_em", ""))
	return "%s — %s (%s%s)" % [str(ponto.get("nome", "")), situacao, origem, (" em " + quando) if quando != "" else ""]


## Resumo curto do progresso de um ponto de carga para as caixas de confirmação ("Setup e Reconhecimento, de Ana" / "história concluída, de Ana").
static func resumo_curto(ponto: Dictionary) -> String:
	if not bool(ponto.get("existe", false)):
		return ""
	var situacao: String = "história concluída" if str(ponto.get("final_id", "")) != "" else GerenciadorNarrativa.titulo_da_etapa(int(ponto.get("etapa", 1)))
	var nome: String = str(ponto.get("nome", ""))
	return "%s, de %s" % [situacao, nome] if nome != "" else situacao


## Carrega o ponto de carga de `origem`. Devolve `false`, sem mudar nada, se não há ponto válido ou se já há uma troca de
## cena em curso (a tela mostra a mensagem). Devolve `true` quando o pedido foi aceito; a troca termina sozinha e, se
## falhar antes de qualquer mudança de estado, chama `ao_falhar(motivo)` com o jogo exatamente como estava.
static func carregar(arvore: SceneTree, origem: int, ao_falhar: Callable = Callable()) -> bool:
	var ponto: Dictionary = ponto_de_carga(origem)
	if not bool(ponto.get("existe", false)):
		return false
	# O conteúdo é lido e conferido AQUI, uma única vez: o que será aplicado é exatamente o que passou na conferência.
	var dados: Dictionary = SistemaPersistencia.ler_conferido(str(ponto["caminho"]))
	if dados.is_empty():
		return false
	var destino: String = Cenas.GAMEPLAY if str(ponto.get("final_id", "")) == "" else Cenas.FINAL
	return Cenas.ir_para(arvore, destino, ao_falhar, Callable(Sessao, &"_preparar_carga").bind(arvore, dados))


## Repete o início de uma Task a partir do checkpoint dela (a TelaFinal usa o da Task 9). Pelo mesmo caminho de `carregar`: o arquivo
## é lido e conferido antes, a cena de destino é carregada antes, e o estado só muda depois disso. Devolve `false`, sem mudar
## nada, se o checkpoint não existe, é inválido ou se já há uma troca de cena em curso.
static func carregar_checkpoint(arvore: SceneTree, etapa: int, ao_falhar: Callable = Callable()) -> bool:
	if not SistemaPersistencia.existe_checkpoint(etapa):
		return false
	var dados: Dictionary = SistemaPersistencia.ler_conferido(SistemaPersistencia.caminho_do_checkpoint(etapa))
	if dados.is_empty():
		return false
	var estado: Variant = dados.get("estado", {})
	var final_id: String = str((estado as Dictionary).get("final_id", "")) if typeof(estado) == TYPE_DICTIONARY else ""
	var destino: String = Cenas.GAMEPLAY if final_id == "" else Cenas.FINAL
	return Cenas.ir_para(arvore, destino, ao_falhar, Callable(Sessao, &"_preparar_carga").bind(arvore, dados))


## Começa uma campanha nova com `nome` (e `pronome`, "" = neutro) e abre a área de trabalho na Task 1. A campanha atual só é substituída
## depois que a área de trabalho foi carregada. As configurações do jogador não são tocadas.
static func novo_jogo(arvore: SceneTree, nome: String, ao_falhar: Callable = Callable(), pronome: String = "") -> bool:
	return Cenas.ir_para(arvore, Cenas.GAMEPLAY, ao_falhar, Callable(Sessao, &"_preparar_novo").bind(arvore, nome, pronome))


## "Recomeçar Jogo": o mesmo reinício de campanha do Novo Jogo, mantendo o nome e o pronome do jogador. Todas as variáveis do roteiro
## (permissões, Dependência, Autonomia, flags, tentativas de revogação) voltam ao estado inicial.
static func recomecar(arvore: SceneTree, ao_falhar: Callable = Callable()) -> bool:
	return novo_jogo(arvore, GerenciadorEstado.nome_jogador, ao_falhar, GerenciadorEstado.pronome_jogador)


## Volta ao Menu Principal. Não salva nada além do que o autosave já salvou (a tela avisa que o progresso não salvo pode ser
## perdido) e não apaga nada.
static func voltar_ao_menu(arvore: SceneTree, ao_falhar: Callable = Callable()) -> bool:
	var destino: String = Cenas.MENU_PRINCIPAL if ResourceLoader.exists(Cenas.MENU_PRINCIPAL) else Cenas.BOOT
	return Cenas.ir_para(arvore, destino, ao_falhar, Callable(Sessao, &"_preparar_menu").bind(arvore))


# ------------------------------------------------------------------ ganchos de `Cenas.ir_para` (rodam com a cena nova já carregada)
static func _preparar_carga(arvore: SceneTree, dados: Dictionary) -> bool:
	_encerrar_cena_atual(arvore)
	SistemaNotificacoes.limpar_historico()
	SistemaPersistencia.aplicar_dados(dados)
	GerenciadorNarrativa.retomar()
	return true


static func _preparar_novo(arvore: SceneTree, nome: String, pronome: String) -> bool:
	_encerrar_cena_atual(arvore)
	# Um salvamento principal ilegível seria sobrescrito pelo primeiro autosave: antes, ele é preservado (sem apagar nada).
	SistemaPersistencia.preservar_se_invalido()
	SistemaNotificacoes.limpar_historico()
	GerenciadorNarrativa.iniciar_novo_jogo(nome, pronome)
	return true


static func _preparar_menu(arvore: SceneTree) -> bool:
	_encerrar_cena_atual(arvore)
	GerenciadorNarrativa.sair_do_jogo()
	SistemaAudio.parar_bgm()
	return true


## Pede à cena atual (a área de trabalho) que desligue a sessão: soltar sinais, fechar janelas e parar efeitos.
## Quem não tem `encerrar_sessao` (menus, tela final) simplesmente não é tocado.
static func _encerrar_cena_atual(arvore: SceneTree) -> void:
	var cena: Node = arvore.current_scene
	if cena != null and is_instance_valid(cena) and cena.has_method("encerrar_sessao"):
		cena.call("encerrar_sessao")
