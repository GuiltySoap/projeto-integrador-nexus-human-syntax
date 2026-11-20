class_name ItemContato
extends Button
## Linha da lista de contatos do Mensageiro (item reutilizável de item_contato.tscn). O app instancia um por conversa disponível.
## O texto traz ícone, nome, ●N (mensagens não lidas) e a prévia da última mensagem: nada de só cor.

signal selecionado(id_contato: String)

var id_contato: String = ""


## contato: dados do contato (id, nome, icone); previa: trecho da última mensagem; nao_lidas: mensagens ainda não lidas;
## ativo: conversa aberta no momento; grupo: ButtonGroup compartilhado.
func configurar(contato: Dictionary, previa: String, nao_lidas: int, ativo: bool, grupo: ButtonGroup) -> void:
	id_contato = str(contato.get("id", ""))
	var nome := str(contato.get("nome", id_contato))
	var sufixo_nao_lidas := ("  ●%d" % nao_lidas) if nao_lidas > 0 else ""
	text = "%s %s%s\n%s" % [str(contato.get("icone", "?")), nome, sufixo_nao_lidas, previa]
	tooltip_text = "Abrir conversa com %s" % nome
	button_group = grupo
	set_pressed_no_signal(ativo)


# Ligado ao sinal pressed na própria cena.
func _ao_pressionado() -> void:
	selecionado.emit(id_contato)
