class_name UiKit
extends RefCounted
## Utilitários de interface. NÃO constroem Controls: toda a estrutura visual vive em cenas (.tscn) e as aparências vêm
## de "type variations" do Theme criado em TemaNexus. Aqui ficam só funções auxiliares usadas pelos scripts das cenas:
## conferir as referências essenciais (refs_ok), esvaziar/limpar contêineres de conteúdo dinâmico e escalar medidas
## pelo tamanho de texto escolhido nas Configurações.
## (Os antigos construtores `rotulo`, `botao`, `caixa_h/v`, `margem`, `painel`, `linha`, `rolagem`, `rico`... foram
## removidos: nenhum script os usa mais. Para criar interface, monte a cena no editor.)


## Escala uma medida em pixels pelo "Tamanho do texto" das Configurações (a mesma conta das variações de Label do tema).
static func escalar(px: int) -> int:
	return int(round(float(px) * float(GerenciadorConfiguracoes.obter("tamanho_texto"))))


## Remove e libera todos os filhos de uma vez (evita que filhos "mortos" ainda entrem no layout por um quadro).
## Dá o foco ao controle no próximo quadro, só se ele ainda existir, estiver na árvore e visível (evita o erro `grab_focus` fora da árvore
## quando a janela fecha ou é descartada antes do foco chegar).
static func focar_depois(controle: Control) -> void:
	if controle != null:
		_focar_agora.call_deferred(controle)


static func _focar_agora(controle: Control) -> void:
	if is_instance_valid(controle) and controle.is_inside_tree() and controle.is_visible_in_tree():
		controle.grab_focus()


static func limpar_filhos(no: Node) -> void:
	for filho in no.get_children():
		no.remove_child(filho)
		filho.queue_free()


## Confere as referências essenciais de uma cena (nós pegos com @onready var x = %Nome). Se algum estiver ausente,
## registra o erro uma única vez e devolve false: o script aborta o _ready em vez de derrubar o jogo.
## Uso: if not UiKit.refs_ok(self, {"Rotulo": _rotulo, "Icone": _icone}): return
static func refs_ok(dono: Node, refs: Dictionary) -> bool:
	var ok: bool = true
	for nome in refs:
		if refs[nome] == null:
			push_error("%s: nó essencial ausente na cena: %%%s" % [dono.name, nome])
			ok = false
	return ok


## Remove da árvore (e libera) itens dinâmicos guardados em uma lista, sem mexer nos outros filhos do contêiner
## (por exemplo, rótulos e cabeçalhos que já existem na cena). Esvazia a lista recebida.
static func remover_itens(itens: Array) -> void:
	for item in itens:
		var no: Node = item as Node
		if no == null or not is_instance_valid(no):
			continue
		var pai: Node = no.get_parent()
		if pai != null:
			pai.remove_child(no)
		no.queue_free()
	itens.clear()


## Enquanto um painel modal (opções, créditos, confirmação) está aberto, o que há por trás não pode receber foco: sem isto, Tab ou
## as setas levariam o foco para os botões escondidos atrás do painel. `travar = true` tira o foco de TUDO o que está dentro
## de `fundo` (guardando o `focus_mode` de cada controle em um metadado); `false` devolve exatamente o que havia.
static func travar_foco(fundo: Node, travar: bool) -> void:
	if fundo == null:
		return
	var alvos: Array = fundo.find_children("*", "Control", true, false)
	if fundo is Control:
		alvos.append(fundo)
	for no in alvos:
		var controle: Control = no as Control
		if controle == null:
			continue
		if travar:
			if not controle.has_meta("foco_original"):
				controle.set_meta("foco_original", int(controle.focus_mode))
				controle.focus_mode = Control.FOCUS_NONE
		elif controle.has_meta("foco_original"):
			controle.focus_mode = int(controle.get_meta("foco_original")) as Control.FocusMode
			controle.remove_meta("foco_original")


## Liga a navegação por teclado/controle de uma lista de controles em coluna como um anel: de cima para baixo e de volta ao
## primeiro (e Tab/Shift+Tab também), sem nunca sair da lista. Esquerda/direita ficam no próprio controle. Controles
## invisíveis ou desativados ficam de fora do anel (é só chamar de novo quando o estado deles mudar).
static func ligar_foco_circular(controles: Array) -> void:
	var anel: Array[Control] = []
	for item in controles:
		var c: Control = item as Control
		if c == null or not is_instance_valid(c) or not c.visible:
			continue
		var botao: BaseButton = c as BaseButton
		if botao != null and botao.disabled:
			continue
		anel.append(c)
	for i in anel.size():
		var atual: Control = anel[i]
		var anterior: Control = anel[(i + anel.size() - 1) % anel.size()]
		var seguinte: Control = anel[(i + 1) % anel.size()]
		atual.focus_neighbor_top = atual.get_path_to(anterior)
		atual.focus_neighbor_bottom = atual.get_path_to(seguinte)
		atual.focus_previous = atual.get_path_to(anterior)
		atual.focus_next = atual.get_path_to(seguinte)
		atual.focus_neighbor_left = atual.get_path_to(atual)
		atual.focus_neighbor_right = atual.get_path_to(atual)

