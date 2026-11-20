class_name Cenas
extends RefCounted
## Caminhos das cenas principais e a ÚNICA camada de troca de cena do jogo (abertura, boot, Menu Principal, jogo, tela final).
## Nenhuma tela chama `change_scene_to_file` por conta própria: todas passam por `Cenas.ir_para`.
##
## O que a camada garante em cada troca:
##   - uma transição por vez (`em_transicao()`): chamadas repetidas enquanto uma está em curso são recusadas;
##   - a cena de destino é conferida (`ResourceLoader.exists`) e carregada em segundo plano (com tempo limite) ANTES de
##     qualquer mudança de estado, então uma falha de carregamento deixa o jogo exatamente como estava;
##   - o gancho `preparar` (reiniciar a campanha, aplicar um salvamento...) só roda depois que a cena nova já está
##     carregada e pronta para ser instanciada, e ainda com a árvore pausada: o autosave e a narrativa não rodam no meio;
##   - a árvore é despausada (`paused = false`) imediatamente antes da troca, em qualquer caminho, então nenhuma cena
##     chega pausada ao destino;
##   - a guarda é sempre liberada: ao terminar, em qualquer falha e, por segurança, por um vigia de tempo.
## Os autoloads nunca são tocados: só a cena atual é substituída.
##
## `ir_para` é síncrona para quem chama (devolve se o pedido foi ACEITO) e a troca termina sozinha, em segundo plano.
## Quem precisa esperar o fim (testes) usa `await Cenas.aguardar_fim(arvore)`.

## Primeira cena do jogo (`run/main_scene`): a abertura da marca. Só entrega o jogador ao Menu Principal; nada a pede de volta.
const SPLASH := "res://features/splash_screen/scenes/splash_screen.tscn"
## BIOS do HumaxOS, registro de usuário e saudação da Maya: o boot diegético do Novo Jogo (aberto pelo Menu Principal).
const BOOT := "res://features/shell/tela_boot/scenes/tela_boot.tscn"
const MENU_PRINCIPAL := "res://features/menu_principal/scenes/menu_principal.tscn"
const AREA_DE_TRABALHO := "res://features/shell/area_de_trabalho/scenes/area_de_trabalho.tscn"
const FINAL := "res://features/narrative/finais/scenes/tela_final.tscn"
## Monitor virtual: a área de trabalho dentro de um SubViewport, num monitor sobre a mesa. Roda sozinho (F6): começa com o foco no mundo físico.
const MONITOR_VIRTUAL := "res://features/shell/monitor_virtual/scenes/monitor_virtual.tscn"
## CENA DE GAMEPLAY (apresentação padrão do jogo): o monitor virtual com o foco já no computador. É o destino de Novo Jogo, Continuar, Carregar e
## Recomeçar; o HumaxOS (AREA_DE_TRABALHO) vive dentro da tela dele. Uma única cena, um único sistema de entrada.
const GAMEPLAY := "res://features/shell/monitor_virtual/scenes/cena_gameplay.tscn"

## Tempo máximo (em segundos) para carregar uma cena. Passado disso a troca é abandonada e o jogador fica onde estava.
const LIMITE_CARREGAMENTO := 20.0
## Segurança extra: se uma troca nunca terminar por algum motivo, a guarda é liberada depois deste tempo (em segundos).
const LIMITE_GUARDA := 30.0

static var _em_transicao: bool = false
static var _destino: String = ""
static var _progresso: float = 0.0
## Número da transição em curso. Uma continuação antiga (de uma transição já encerrada ou liberada à força) se reconhece
## por não bater com este número e para sem mexer em nada.
static var _geracao: int = 0
## Recado de uma cena para a seguinte (ex.: "abrir o registro de novo jogo"). Lido uma única vez por quem chega.
static var _contexto: Dictionary = {}


## Há uma troca de cena em andamento? Telas e atalhos (como o ESC da pausa) consultam isto para não competir com ela.
static func em_transicao() -> bool:
	return _em_transicao


## Caminho da cena para onde a troca em andamento vai ("" quando não há troca).
static func destino() -> String:
	return _destino


## Progresso do carregamento da cena de destino, de 0.0 a 1.0 (para o indicador de carregamento).
static func progresso() -> float:
	return _progresso


## Guarda um recado para a próxima cena. Só dados simples; a cena que chega lê com `consumir_contexto()`.
static func definir_contexto(dados: Dictionary) -> void:
	_contexto = dados.duplicate(true)


## Devolve o recado deixado pela cena anterior (ou {}) e o apaga: cada recado vale para uma única leitura.
static func consumir_contexto() -> Dictionary:
	var dados: Dictionary = _contexto
	_contexto = {}
	return dados


## Pede a troca para `caminho`. Devolve `false` (e não muda nada) se já há uma troca em curso, se não há árvore ou se a cena
## não existe. Devolve `true` quando o pedido foi aceito; dali em diante a troca corre sozinha:
##   1) carrega a cena em segundo plano (sem mexer no jogo);
##   2) roda `preparar` (sem argumentos; deve devolver `true`; `false` cancela a troca) já com a cena carregada;
##   3) despausa a árvore e troca a cena.
## Se algo falhar nas etapas 1 ou 2, a guarda é liberada, o motivo vai para o log e `ao_falhar(motivo: String)` é chamado
## (a tela mostra a mensagem ao jogador). A troca em si (etapa 3) só começa depois que as etapas que podem falhar passaram.
static func ir_para(arvore: SceneTree, caminho: String, ao_falhar: Callable = Callable(), preparar: Callable = Callable()) -> bool:
	if arvore == null:
		return false
	if _em_transicao:
		push_warning("Cenas: troca para %s recusada; já há uma em andamento (%s)." % [caminho, _destino])
		return false
	if not ResourceLoader.exists(caminho):
		push_error("Cenas: cena ausente: %s" % caminho)
		return false
	_em_transicao = true
	_destino = caminho
	_progresso = 0.0
	_geracao += 1
	if caminho == GAMEPLAY and ResourceLoader.exists(AREA_DE_TRABALHO):
		ResourceLoader.load_threaded_request(AREA_DE_TRABALHO)   # o monitor monta a área de trabalho dentro da tela: já começa a carregá-la em segundo plano
	_executar(arvore, caminho, ao_falhar, preparar, _geracao)
	_vigiar(arvore, _geracao)
	return true


## Espera a troca em andamento terminar (ou o limite de tempo, em segundos). Devolve `true` se não há mais troca em curso.
static func aguardar_fim(arvore: SceneTree, limite: float = 15.0) -> bool:
	var inicio: int = Time.get_ticks_msec()
	while _em_transicao and float(Time.get_ticks_msec() - inicio) / 1000.0 < limite:
		await arvore.process_frame
	return not _em_transicao


## Abandona a troca em curso e libera a guarda. É a saída de emergência (e dos testes); o fluxo normal nunca precisa dela.
static func liberar() -> void:
	_geracao += 1
	_em_transicao = false
	_destino = ""
	_progresso = 0.0


# ------------------------------------------------------------------ internos
static func _executar(arvore: SceneTree, caminho: String, ao_falhar: Callable, preparar: Callable, geracao: int) -> void:
	# Um quadro de espera ANTES de tudo: uma cena já em memória (a área de trabalho que o monitor virtual acabou de usar) carregaria na hora e a troca
	# inteira, inclusive uma falha, terminaria dentro da própria chamada de `ir_para`; assim quem recebe `true` sempre vê a guarda ligada e a falha
	# sempre chega depois do retorno.
	await arvore.process_frame
	if geracao != _geracao:
		return
	var pacote: PackedScene = await _carregar(arvore, caminho, geracao)
	if geracao != _geracao:
		return
	if pacote == null or not pacote.can_instantiate():
		_falhar(geracao, "a cena não pôde ser carregada: %s" % caminho, ao_falhar)
		return
	if preparar.is_valid():
		var resultado: Variant = preparar.call()
		if typeof(resultado) == TYPE_BOOL and not bool(resultado):
			_falhar(geracao, "a preparação da troca para %s foi recusada" % caminho, ao_falhar)
			return
	arvore.paused = false
	var erro: Error = arvore.change_scene_to_packed(pacote)
	if erro != OK:
		_falhar(geracao, "falha ao trocar para %s (erro %d)" % [caminho, erro], ao_falhar)
		return
	# A cena nova só entra na árvore no fim do quadro: a guarda fica até ela estar lá e ter rodado o primeiro quadro.
	await arvore.process_frame
	await arvore.process_frame
	_encerrar(geracao)


## Carrega a cena em segundo plano. Devolve null em caso de erro ou de estouro do tempo limite.
static func _carregar(arvore: SceneTree, caminho: String, geracao: int) -> PackedScene:
	if ResourceLoader.load_threaded_request(caminho) != OK:
		# Alternativa: carga direta (plataforma sem carga em segundo plano). As cenas do jogo são pequenas.
		return ResourceLoader.load(caminho) as PackedScene
	var inicio: int = Time.get_ticks_msec()
	var info: Array = []
	while float(Time.get_ticks_msec() - inicio) / 1000.0 < LIMITE_CARREGAMENTO:
		var estado: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(caminho, info)
		if geracao != _geracao:
			return null
		if not info.is_empty():
			_progresso = clampf(float(info[0]), 0.0, 1.0)
		if estado == ResourceLoader.THREAD_LOAD_LOADED:
			_progresso = 1.0
			return ResourceLoader.load_threaded_get(caminho) as PackedScene
		if estado != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			return null
		await arvore.process_frame
	push_error("Cenas: tempo esgotado ao carregar %s." % caminho)
	return null


static func _falhar(geracao: int, motivo: String, ao_falhar: Callable) -> void:
	push_error("Cenas: %s." % motivo)
	_encerrar(geracao)
	if ao_falhar.is_valid():
		ao_falhar.call(motivo)


static func _encerrar(geracao: int) -> void:
	if geracao != _geracao:
		return
	_em_transicao = false
	_destino = ""
	_progresso = 0.0


## Vigia independente: se a transição `geracao` ainda estiver marcada como em curso depois do limite, libera a guarda.
## Sem isto, um erro inesperado no meio da troca deixaria o jogo recusando todas as trocas seguintes.
static func _vigiar(arvore: SceneTree, geracao: int) -> void:
	await arvore.create_timer(LIMITE_GUARDA).timeout
	if geracao == _geracao and _em_transicao:
		push_error("Cenas: a troca para %s não terminou em %d s; a guarda foi liberada." % [_destino, int(LIMITE_GUARDA)])
		_encerrar(geracao)
