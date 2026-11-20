class_name ItemEscolha
extends Button
## Botão de resposta (item reutilizável de item_escolha.tscn): uma opção do nó de escolha atual do roteiro. Usado pelo Mensageiro e pelo
## painel da Maya. O texto da opção é o texto do botão; nada de ícone ou cor como único sinal.

signal escolhida(id_escolha: String)

var id_escolha: String = ""


## opcao: {id, texto} de GerenciadorNarrativa.apresentacao()["opcoes"].
func configurar(opcao: Dictionary) -> void:
	id_escolha = str(opcao.get("id", ""))
	text = str(opcao.get("texto", "…"))
	tooltip_text = ""
	focus_mode = Control.FOCUS_ALL


# Ligado ao sinal pressed na própria cena.
func _ao_pressionado() -> void:
	escolhida.emit(id_escolha)
