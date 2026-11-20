@tool
extends EditorScript
## Varredura EXATA dos avisos de configuração de nó (o triângulo amarelo da árvore de nós do editor): abre cada
## cena do jogo no editor, espera a doca "Cena" montar a árvore e lê os botões de aviso dos itens dela.
## (Node.get_configuration_warnings() não é exposto ao GDScript; a única fonte confiável é o próprio editor.)
##
## Como usar: abra este arquivo no editor de scripts e use Arquivo > Executar (Ctrl+Shift+X). O resultado vai
## para o painel Saída e para tests/_saida/avisos_editor/log_editor.txt (uma linha "AVISO" por nó; a última
## linha é o resumo). Cenas que já estavam abertas continuam abertas; as demais são fechadas depois de lidas.
## Não modifica nenhuma cena. As cenas de tests/ ficam de fora.

const SAIDA := "res://tests/_saida/avisos_editor/"

## O editor solta a referência a este script assim que _run() devolve o controle no primeiro await; guardar a si
## mesmo mantém o objeto vivo até a varredura terminar (sem isso a continuação depois do await nunca acontece).
var _vivo: EditorScript = null


func _run() -> void:
	_vivo = self
	var base: Control = EditorInterface.get_base_control()
	var quadros := base.get_tree()
	var abertas := EditorInterface.get_open_scenes()
	var origem := ""
	var atual := EditorInterface.get_edited_scene_root()
	if atual != null:
		origem = atual.scene_file_path
	var caminhos: PackedStringArray = []
	_listar("res://", caminhos, 0)
	caminhos.sort()
	var icone_aviso: Texture2D = EditorInterface.get_editor_theme().get_icon("NodeWarning", "EditorIcons")
	var linhas: PackedStringArray = []
	var cenas := 0
	var nos_com_aviso := 0
	for caminho in caminhos:
		var ja_aberta := abertas.has(caminho)
		EditorInterface.open_scene_from_path(caminho)
		var raiz: Node = null
		for i in 60:
			await quadros.process_frame
			raiz = EditorInterface.get_edited_scene_root()
			if raiz != null and raiz.scene_file_path == caminho:
				break
		for i in 4:
			await quadros.process_frame
		if raiz == null or raiz.scene_file_path != caminho:
			linhas.append("ERRO: não foi possível abrir %s" % caminho)
			continue
		cenas += 1
		var achados: Array[String] = []
		_ler_doca(base, raiz.name, icone_aviso, achados)
		for achado in achados:
			nos_com_aviso += 1
			linhas.append("AVISO %s :: %s" % [caminho.trim_prefix("res://"), achado])
		if not ja_aberta:
			EditorInterface.close_scene()
	if origem != "":
		EditorInterface.open_scene_from_path(origem)
	linhas.append("RESULTADO: %d cenas conferidas, %d avisos." % [cenas, nos_com_aviso])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA))
	var f := FileAccess.open(SAIDA + "log_editor.txt", FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(linhas) + "\n")
		f.close()
	for linha in linhas:
		print("[varredura_editor] ", linha)
	_vivo = null


func _listar(pasta: String, saida: PackedStringArray, nivel: int) -> void:
	if nivel > 8 or pasta.begins_with("res://tests") or pasta.contains("/.") or pasta.contains("/_saida"):
		return
	var dir := DirAccess.open(pasta)
	if dir == null:
		return
	for sub in dir.get_directories():
		_listar(pasta.path_join(sub), saida, nivel + 1)
	for arquivo in dir.get_files():
		if arquivo.ends_with(".tscn"):
			saida.append(pasta.path_join(arquivo))


## Acha a árvore da doca "Cena" (a que tem a raiz da cena aberta) e junta, para cada item com botão de aviso, o
## caminho do nó e o texto da dica do botão.
func _ler_doca(base: Node, nome_raiz: String, icone_aviso: Texture2D, achados: Array[String]) -> void:
	for candidato in base.find_children("*", "Tree", true, false):
		var arvore := candidato as Tree
		var topo := arvore.get_root()
		if topo == null:
			continue
		var item_raiz: TreeItem = null
		if topo.get_text(0) == nome_raiz:
			item_raiz = topo
		elif topo.get_first_child() != null and topo.get_first_child().get_text(0) == nome_raiz:
			item_raiz = topo.get_first_child()
		if item_raiz == null:
			continue
		_coletar(item_raiz, "", icone_aviso, achados)
		return


func _coletar(item: TreeItem, prefixo: String, icone_aviso: Texture2D, achados: Array[String]) -> void:
	var caminho := item.get_text(0) if prefixo == "" else prefixo + "/" + item.get_text(0)
	for i in item.get_button_count(0):
		var dica := item.get_button_tooltip_text(0, i)
		if item.get_button(0, i) == icone_aviso or dica.containsn("warning"):
			achados.append("%s :: %s" % [caminho, dica.replace("\n", " ")])
	var filho := item.get_first_child()
	while filho != null:
		_coletar(filho, caminho, icone_aviso, achados)
		filho = filho.get_next()
