extends Node
## Preferências do jogador (visual, áudio e acessibilidade). Persistidas em user://.
## As permissões simuladas e o progresso ficam no GerenciadorEstado (pertencem à narrativa).

signal configuracao_alterada(chave: String, valor: Variant)

const PASTA := "user://nexus_os"
const CAMINHO := "user://nexus_os/configuracoes.cfg"
const PADRAO := {
	"papel_de_parede": "dia",          # dia | grade | preto
	"tema": "auto",                    # auto | roxo | azul | verde
	"volume_master": 0.8,
	"volume_bgm": 0.35,
	"volume_sfx": 0.8,
	"reduzir_glitch": false,
	"reduzir_tremor": false,
	"sem_flashes": false,
	"reduzir_ruido": false,
	"reduzir_animacoes": false,
	"alto_contraste": false,
	"tamanho_texto": 1.0,
	"dificuldade_processo": "normal",  # relaxado | normal | intenso
	"usar_backend_json": false,        # ponte opcional com o backend em C
	"modo_depuracao": false,           # libera o painel de testes (F9) fora do editor
	"desativar_efeitos_agressivos": false,   # MASTER TOGGLE: desliga todo efeito de interface agressivo (dark patterns, glitch condicional, tremor)
	"tempo_estendido": false,                # acessibilidade: a barra de envio da Maya (Task 6) dura 6 s em vez de 3 s
	"mostrar_indicador_oculto": true,        # mostra a marca discreta em mensagens que a Maya alterou ou censurou (acessibilidade: leitores de tela)
}
const CHAVES_CONFORTO := ["reduzir_glitch", "reduzir_tremor", "sem_flashes", "reduzir_ruido", "reduzir_animacoes"]
## Atalhos registrados em código: nome -> [tecla, ctrl, shift]
const ACOES := {
	"nexus_menu_iniciar": [KEY_F1, false, false],
	"nexus_tela_cheia": [KEY_F11, false, false],
	"nexus_painel_debug": [KEY_F9, false, false],
	"nexus_proxima_janela": [KEY_TAB, true, false],
	"nexus_fechar_janela": [KEY_W, true, false],
	"nexus_minimizar_janela": [KEY_M, true, false],
	"nexus_abrir_terminal": [KEY_T, true, true],
	"nexus_forcar_desativar": [KEY_D, true, true],
	"nexus_pedir_ajuda": [KEY_H, true, true],
	"nexus_alternar_foco_monitor": [KEY_F8, false, false],
}

var valores: Dictionary = PADRAO.duplicate()
## Desligue em testes automáticos: com `false`, salvar() não escreve em user:// e as preferências reais do jogador ficam intactas.
var persistencia_habilitada: bool = true
## Arquivo das preferências. Só os testes automáticos trocam isto (por um arquivo próprio em user://), para nunca tocarem nas
## preferências reais do jogador. Fora de user:// nada é gravado.
var caminho: String = CAMINHO


func _ready() -> void:
	carregar()
	_registrar_acoes()


func obter(chave: String) -> Variant:
	return valores.get(chave, PADRAO.get(chave))


func definir(chave: String, valor: Variant, salvar_agora: bool = true) -> void:
	if not PADRAO.has(chave) or valores.get(chave) == valor:
		return
	valores[chave] = valor
	configuracao_alterada.emit(chave, valor)
	if salvar_agora:
		salvar()


func redefinir_acessibilidade() -> void:
	for chave in ["reduzir_glitch", "reduzir_tremor", "sem_flashes", "reduzir_ruido", "reduzir_animacoes", "alto_contraste", "tamanho_texto"]:
		definir(chave, PADRAO[chave], false)
	salvar()


func carregar() -> void:
	var cf := ConfigFile.new()
	if cf.load(caminho) != OK:
		return
	for chave in PADRAO:
		var v: Variant = cf.get_value("config", chave, PADRAO[chave])
		if typeof(v) == typeof(PADRAO[chave]):
			valores[chave] = v


func salvar() -> void:
	if not persistencia_habilitada:
		return
	if not caminho.begins_with("user://"):
		push_warning("GerenciadorConfiguracoes: o arquivo de preferências precisa ficar em user:// (veio %s); nada foi gravado." % caminho)
		return
	DirAccess.make_dir_recursive_absolute(caminho.get_base_dir())
	var cf := ConfigFile.new()
	for chave in valores:
		cf.set_value("config", chave, valores[chave])
	if cf.save(caminho) != OK:
		push_warning("GerenciadorConfiguracoes: não foi possível salvar as configurações.")


## "Modo conforto": desliga de uma vez glitch, tremor, flashes, ruído e animações (também no atalho Ctrl+Shift+D).
func ativar_modo_conforto() -> void:
	for chave in CHAVES_CONFORTO:
		definir(chave, true, false)
	salvar()


func desativar_modo_conforto() -> void:
	for chave in CHAVES_CONFORTO:
		definir(chave, false, false)
	salvar()


func modo_conforto_ativo() -> bool:
	for chave in CHAVES_CONFORTO:
		if not bool(obter(chave)):
			return false
	return true


func alternar_tela_cheia() -> void:
	var modo := DisplayServer.window_get_mode()
	if modo == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN or modo == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var tamanho := Vector2i(1280, 720)
		DisplayServer.window_set_size(tamanho)
		var tela := DisplayServer.screen_get_size()
		DisplayServer.window_set_position(Vector2i(maxi(0, floori((tela.x - tamanho.x) / 2.0)), maxi(0, floori((tela.y - tamanho.y) / 2.0))))
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


## Efeitos intensos só rodam quando o jogador não os desativou.
func glitch_permitido() -> bool:
	return not bool(obter("reduzir_glitch")) and not efeitos_agressivos_desativados()


func tremor_permitido() -> bool:
	return not bool(obter("reduzir_tremor")) and not efeitos_agressivos_desativados()


## Master Toggle "Desativar efeitos de interface agressivos": quando ligado, nenhum dark pattern, glitch condicional ou tremor roda.
## Não faz parte de `redefinir_acessibilidade` de propósito: restaurar padrões não pode reativar efeitos que o jogador desligou.
func efeitos_agressivos_desativados() -> bool:
	return bool(obter("desativar_efeitos_agressivos"))


func animacoes_permitidas() -> bool:
	return not bool(obter("reduzir_animacoes"))


func _registrar_acoes() -> void:
	for acao in ACOES:
		if InputMap.has_action(acao):
			continue
		InputMap.add_action(acao)
		var cfg: Array = ACOES[acao]
		var ev := InputEventKey.new()
		ev.keycode = cfg[0]
		ev.ctrl_pressed = cfg[1]
		ev.shift_pressed = cfg[2]
		InputMap.action_add_event(acao, ev)
