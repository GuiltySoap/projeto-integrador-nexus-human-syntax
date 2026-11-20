extends Node
## Suíte do ROTEIRO v2.0 (estado D/A, permissões e revogação, progressão pelas 9 Tasks, rotas alternativas, AV e seis finais, minigames de lógica,
## interfaces e marca). Cada módulo (tests/sistemas_novos/modulo_*.gd) começa de um jogo novo e mede o sistema de verdade, com os dados e as cenas
## reais do jogo; este executor só os roda em sequência, soma o resultado e protege o jogador:
##   - o salvamento e as preferências reais (user://nexus_os/) nunca são lidos nem gravados durante a suíte (os valores originais voltam no fim);
##   - o backend em C fica desligado (o teste mede o jogo em GDScript; a integração com o C tem a suíte própria `integracao_c`);
##   - nada é apagado; o que o teste grava vai para user://nexus_os_teste/ e tests/_saida/sistemas_novos/.
##
## Como usar: abra tests/sistemas_novos/sistemas_novos.tscn no editor e pressione F6, ou, sem janela:
##   godot --headless --path . res://tests/sistemas_novos/sistemas_novos.tscn
## O resultado vai para o painel Saída e para tests/_saida/sistemas_novos/log.txt (linhas "OK" / "FALHA"; a última linha é o resumo).
## Código de saída: 0 = tudo certo; 1 = alguma verificação falhou.
## Avisos esperados: alguns módulos provocam de propósito valores recusados que o jogo registra com push_warning; cada módulo informa
## quantos (`avisos_esperados`) e o total aparece no log. Qualquer outro aviso ou erro no Depurador é problema.

const SAIDA := "res://tests/_saida/sistemas_novos/"
const MODULOS: Array = [
	["Estado, permissões, revogação, persistência e migração (v2.0)", "res://tests/sistemas_novos/modulo_estado_v2.gd"],
	["Progressão das 9 Tasks, rotas alternativas, AV e seis finais (v2.0)", "res://tests/sistemas_novos/modulo_progressao_v2.gd"],
	["Minigames de lógica e montagem da rotina (v2.0)", "res://tests/sistemas_novos/modulo_minigames_v2.gd"],
	["Interfaces: cartões, Mensageiro, Terminal, Configurações, relatórios e Mural (v2.0)", "res://tests/sistemas_novos/modulo_interfaces_v2.gd"],
	["Área de trabalho de verdade: janelas pedidas pelo roteiro (v2.0)", "res://tests/sistemas_novos/modulo_desktop_v2.gd"],
	["Marca visual", "res://tests/sistemas_novos/modulo_marca.gd"],
]


func _ready() -> void:
	await get_tree().process_frame
	await _rodar()


func _rodar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA))
	var banca := BancaDeTestes.new(SAIDA)
	var avisos_esperados: int = 0

	# o que pertence ao jogador fica como estava: salvamento, preferências e backend
	var persistencia_antes: bool = SistemaPersistencia.habilitado
	var preferencias_antes: bool = GerenciadorConfiguracoes.persistencia_habilitada
	var backend_antes: Variant = GerenciadorConfiguracoes.obter("usar_backend_json")
	SistemaPersistencia.habilitado = false
	GerenciadorConfiguracoes.persistencia_habilitada = false
	GerenciadorConfiguracoes.definir("usar_backend_json", false, false)

	for item in MODULOS:
		var par: Array = item
		var titulo: String = str(par[0])
		var caminho: String = str(par[1])
		banca.registrar("##### %s (%s)" % [titulo, caminho.get_file()])
		var antes_verificacoes: int = banca.verificacoes
		var antes_falhas: int = banca.falhas
		var script: GDScript = load(caminho) as GDScript
		var modulo: ModuloDeTeste = null
		if script != null:
			modulo = script.new() as ModuloDeTeste
		if not banca.ok(modulo != null, "o módulo %s carrega" % caminho.get_file()):
			continue
		modulo.name = caminho.get_file().get_basename()
		add_child(modulo)
		await modulo.executar(banca)
		avisos_esperados += modulo.avisos_esperados
		remove_child(modulo)
		modulo.queue_free()
		await get_tree().process_frame
		banca.registrar("##### %s: %d verificações, %d falhas." % [titulo, banca.verificacoes - antes_verificacoes, banca.falhas - antes_falhas])

	SistemaPersistencia.habilitado = persistencia_antes
	GerenciadorConfiguracoes.persistencia_habilitada = preferencias_antes
	GerenciadorConfiguracoes.definir("usar_backend_json", backend_antes, false)
	banca.registrar("AVISOS ESPERADOS: %d (provocados de propósito pelos módulos)" % avisos_esperados)
	banca.registrar("RESULTADO: %d verificações, %d falhas." % [banca.verificacoes, banca.falhas])
	banca.gravar()
	get_tree().quit(1 if banca.falhas > 0 else 0)
