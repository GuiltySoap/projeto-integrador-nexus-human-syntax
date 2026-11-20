extends Node
## Ferramenta de manutenção: grava o Theme base do HumaxOS (dia 1, tamanho de texto 100%, sem alto contraste, preferências
## padrão) em res://shared/theme/tema_nexus_base.tres.
##
## Esse arquivo é o "Theme custom" do projeto (Project Settings > GUI > Theme > Custom, já apontado no project.godot).
## Serve para o EDITOR mostrar as cenas (.tscn) com as aparências do jogo, incluindo as type variations (RotuloTitulo20,
## PainelVidro, BotaoPrimario...), e para o Inspetor listá-las em "Theme Type Variation". Em execução o jogo continua
## montando o Theme por código (TemaNexus.aplicar: dia narrativo, contraste, tamanho de texto) e ele tem prioridade
## sobre o do projeto, então nada muda no jogo.
##
## Como usar: abra tests/exportar_tema/exportar_tema.tscn no editor e pressione F6. Regrave o arquivo sempre que mudar
## tema_nexus.gd ou tema_variacoes.gd (e rode `python3 tools/validar_projeto.py` para conferir as variações).
## Segurança: não grava preferências do jogador; só escreve o .tres e o log em tests/_saida/exportar_tema/.

const DESTINO := "res://shared/theme/tema_nexus_base.tres"
const SAIDA := "res://tests/_saida/exportar_tema/"


func _ready() -> void:
	await get_tree().process_frame
	GerenciadorConfiguracoes.persistencia_habilitada = false
	GerenciadorConfiguracoes.valores = GerenciadorConfiguracoes.PADRAO.duplicate()
	TemaNexus.definir_dia(1)
	var tema: Theme = TemaNexus.criar_tema()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DESTINO.get_base_dir()))
	var erro := ResourceSaver.save(tema, DESTINO)
	var linhas: PackedStringArray = []
	linhas.append("destino=%s erro=%d (%s)" % [DESTINO, erro, error_string(erro)])
	linhas.append("tipos com variação ou estilo no Theme: %d" % tema.get_type_list().size())
	linhas.append("variações de Label registradas: %d" % _contar_variacoes(tema, "Label"))
	linhas.append("tamanho do arquivo: %d bytes" % (FileAccess.get_file_as_bytes(DESTINO).size() if FileAccess.file_exists(DESTINO) else -1))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA))
	var f := FileAccess.open(SAIDA + "log.txt", FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(linhas) + "\n")
		f.close()
	for l in linhas:
		print("[exportar_tema] ", l)
	get_tree().quit(0 if erro == OK else 1)


func _contar_variacoes(tema: Theme, tipo_base: String) -> int:
	var n := 0
	for tipo in tema.get_type_list():
		if tema.get_type_variation_base(tipo) == tipo_base:
			n += 1
	return n
