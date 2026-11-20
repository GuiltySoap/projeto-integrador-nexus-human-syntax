extends Node
## OBSOLETO: esta cena não faz mais a varredura; ela só avisa e encerra.
##
## A primeira versão desta ferramenta instanciava cada .tscn em tempo de execução e chamava
## Node.get_configuration_warnings() para listar os avisos de configuração de nó (o triângulo amarelo da árvore de
## nós no editor). Essa função não é exposta ao GDScript na Godot 4.7, então a varredura em tempo de execução não
## funciona (o depurador para com "Nonexistent function 'get_configuration_warnings'").
##
## A verificação que vale é tests/avisos_editor/varredura_editor.gd (um EditorScript): abra o arquivo no editor de
## scripts e use Arquivo → Executar (Ctrl+Shift+X). Ela abre cada cena no editor e lê os avisos do painel Cena, o
## mesmo que o desenvolvedor vê. O resultado vai para tests/_saida/avisos_editor/log_editor.txt.
##
## Esta cena continua no projeto apenas porque o arquivo não pôde ser apagado pela ferramenta que fez a migração;
## pode ser removida com segurança (nada a referencia).


func _ready() -> void:
	print("[avisos_editor] OBSOLETO: use tests/avisos_editor/varredura_editor.gd (Arquivo > Executar, Ctrl+Shift+X).")
	get_tree().quit()
