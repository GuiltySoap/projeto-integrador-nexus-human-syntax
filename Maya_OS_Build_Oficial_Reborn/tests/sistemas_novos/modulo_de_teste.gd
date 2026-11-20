class_name ModuloDeTeste
extends Node
## Base dos módulos da suíte (roteiro v2.0). O executor (sistemas_novos.gd) cria cada módulo, põe na árvore e chama `executar`.
## Cada módulo começa de um jogo novo (`_novo_jogo`) e usa os atalhos abaixo. Nada aqui apaga arquivos nem escreve fora de
## user://nexus_os_teste/ e tests/_saida/sistemas_novos/; o salvamento e as preferências do jogador ficam isolados.

var banca: BancaDeTestes = null
## Avisos que o módulo PROVOCA de propósito (valores recusados que o jogo registra com push_warning); o executor soma e informa.
var avisos_esperados: int = 0

var _config_valores: Dictionary = {}
var _config_persistencia: bool = true
var _config_isolada: bool = false


## Roda o módulo. Os módulos sobrescrevem este método.
func executar(banca_do_executor: BancaDeTestes) -> void:
	banca = banca_do_executor
	await get_tree().process_frame


func _ok(condicao: bool, mensagem: String) -> bool:
	return banca.ok(condicao, mensagem)


func _igual(obtido: Variant, esperado: Variant, mensagem: String) -> bool:
	return banca.igual(obtido, esperado, mensagem)


func _perto(obtido: float, esperado: float, mensagem: String, tolerancia: float = 0.001) -> bool:
	return banca.perto(obtido, esperado, mensagem, tolerancia)


func _secao(titulo: String) -> void:
	banca.secao(titulo)


func _info(texto: String) -> void:
	banca.registrar("INFO: " + texto)


func _quadros(quantos: int) -> void:
	for _i in quantos:
		await get_tree().process_frame


## Campanha nova (Task 1, nó T1.1), com o salvamento desligado e o registro de eventos zerado. `pausado` fica true (sem relógio).
func _novo_jogo(nome: String = "Teste", pronome: String = "") -> void:
	SistemaPersistencia.habilitado = false
	GerenciadorNarrativa.iniciar_novo_jogo(nome, pronome)
	GerenciadorNarrativa.pausado = true
	SistemaEventos.limpar_registro()


func _dep() -> int:
	return GerenciadorEstado.dependencia_maya()


func _aut() -> int:
	return GerenciadorEstado.autonomia_jogador()


func _no() -> String:
	return GerenciadorEstado.no_roteiro


## Pasta de gravação própria desta execução (nunca a do jogo).
func _pasta_de_teste(nome: String) -> String:
	return "user://nexus_os_teste/sistemas_novos/%s_%d_%d" % [nome, int(Time.get_unix_time_from_system()), Time.get_ticks_usec() % 1000000]


## Isola as preferências do jogador: nada é gravado em user://nexus_os enquanto o módulo mexe nelas.
func _isolar_configuracoes() -> void:
	if _config_isolada:
		return
	_config_isolada = true
	_config_valores = GerenciadorConfiguracoes.valores.duplicate()
	_config_persistencia = GerenciadorConfiguracoes.persistencia_habilitada
	GerenciadorConfiguracoes.persistencia_habilitada = false


func _restaurar_configuracoes() -> void:
	if not _config_isolada:
		return
	for chave in _config_valores:
		GerenciadorConfiguracoes.definir(str(chave), _config_valores[chave], false)
	GerenciadorConfiguracoes.persistencia_habilitada = _config_persistencia
	_config_isolada = false
