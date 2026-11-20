extends Node
## Gerenciador de janelas e catálogo de aplicativos.
## - O catálogo (core/data/catalogo_apps.json) é a ÚNICA fonte de apps: menu iniciar, ícones da área de trabalho,
##   barra de tarefas e busca consultam este autoload.
## - Cuida de foco/z-order, minimizar/restaurar, fechamento (com bloqueios narrativos finitos) e diálogos modais.
## - Não conhece a narrativa: usa apenas o GerenciadorEstado (flags e bloqueios) e as notificações.

signal janela_aberta(janela: JanelaBase)
signal janela_fechada(janela: JanelaBase)
signal janela_focada(janela: JanelaBase)
signal janelas_alteradas()
signal catalogo_alterado()

const ARQUIVO_CATALOGO := "res://core/data/catalogo_apps.json"
const APPS_DO_DESKTOP_REDUZIDO: PackedStringArray = ["explorer", "messenger", "maya"]
const CENA_JANELA := "res://shared/ui/janela_base/scenes/janela_base.tscn"
const TENTATIVAS_MINIMIZAR_BLOQUEADAS := 2

var catalogo: Array = []
## Verdadeiro enquanto o menu iniciar/central de notificações estiver aberto (o clique central não rouba o foco).
var overlay_ativo: bool = false
## Como converter um ponto da tela física num ponto do desktop. O monitor virtual (SubViewport) registra o dele aqui; sem monitor, o ponto vale como está.
var _conversor_de_ponto: Callable = Callable()

var _por_id: Dictionary = {}
var _janelas: Array = []
var _ativa: JanelaBase = null
var _camada_janelas: Control = null
var _camada_modais: Control = null
var _proximo_pid: int = 1204
var _cascata: int = 0


func _ready() -> void:
	_carregar_catalogo()
	GerenciadorEstado.flag_alterada.connect(_ao_flag)


func _exit_tree() -> void:
	if GerenciadorEstado.flag_alterada.is_connected(_ao_flag):
		GerenciadorEstado.flag_alterada.disconnect(_ao_flag)


func _input(evento: InputEvent) -> void:
	if _camada_janelas == null or modal_ativo():
		return
	if evento is InputEventMouseButton and evento.pressed and not overlay_ativo:
		if evento.button_index == MOUSE_BUTTON_LEFT or evento.button_index == MOUSE_BUTTON_RIGHT:
			var alvo := _janela_em(_ponto_do_desktop(evento.global_position))
			if alvo != null and alvo != _ativa:
				focar(alvo)
		return
	if evento.is_action_pressed("nexus_proxima_janela"):
		get_viewport().set_input_as_handled()
		proxima_janela()
	elif evento.is_action_pressed("nexus_fechar_janela"):
		get_viewport().set_input_as_handled()
		fechar_ativa()
	elif evento.is_action_pressed("nexus_minimizar_janela"):
		get_viewport().set_input_as_handled()
		minimizar_ativa()


# ------------------------------------------------------------------ catálogo
func app_info(app_id: String) -> Dictionary:
	return _por_id.get(app_id, {})


## O app existe no catálogo e pode ser aberto (por ícone, atalho em Arquivos, Terminal...). Esconder um ícone nunca tranca o caminho.
func app_disponivel(app_id: String) -> bool:
	return not app_info(app_id).is_empty()


## O app aparece nos ícones, no menu e na barra? Regra CENTRAL da visibilidade (o roteiro só liga flags):
##   `app_oculto:<id>`  a Maya ocultou o app (T4.2 Mural/Jogos/Música);  `desktop_reduzido`  só Arquivos, Mensageiro e o painel da Maya (T9.1).
func app_listado(app_id: String) -> bool:
	if app_info(app_id).is_empty():
		return false
	if GerenciadorEstado.tem_flag("app_oculto:" + app_id):
		return false
	if GerenciadorEstado.tem_flag("desktop_reduzido") and not APPS_DO_DESKTOP_REDUZIDO.has(app_id):
		return false
	return true


## O app foi pausado pela Maya (T9.1)? O Mural, Jogos e Música não abrem; o aviso é o do roteiro.
func app_pausado(app_id: String) -> bool:
	return bool(app_info(app_id).get("pausavel", false)) and GerenciadorEstado.tem_flag("apps_pausados_pela_maya")


func apps_do_menu() -> Array:
	return _filtrar("menu_iniciar")


func apps_da_area_de_trabalho() -> Array:
	return _filtrar("area_de_trabalho")


func apps_fixados() -> Array:
	return _filtrar("fixado")


func buscar_apps(texto: String) -> Array:
	var termo := texto.strip_edges().to_lower()
	var saida: Array = []
	if termo == "":
		return saida
	for info in catalogo:
		if app_listado(str(info["id"])) and bool(info.get("menu_iniciar", true)):
			if str(info["nome"]).to_lower().contains(termo) or str(info["id"]).to_lower().contains(termo):
				saida.append(info)
	return saida


# ------------------------------------------------------------------ camadas (registradas pela área de trabalho)
func registrar_camadas(camada_janelas: Control, camada_modais: Control) -> void:
	limpar_camadas()
	_camada_janelas = camada_janelas
	_camada_modais = camada_modais
	if _camada_janelas != null and not _camada_janelas.resized.is_connected(_ao_area_redimensionada):
		_camada_janelas.resized.connect(_ao_area_redimensionada)


func limpar_camadas() -> void:
	if _camada_janelas != null and is_instance_valid(_camada_janelas) and _camada_janelas.resized.is_connected(_ao_area_redimensionada):
		_camada_janelas.resized.disconnect(_ao_area_redimensionada)
	_camada_janelas = null
	_camada_modais = null
	_janelas.clear()
	_ativa = null
	overlay_ativo = false
	_cascata = 0


func area_util() -> Vector2:
	if _camada_janelas == null:
		return Vector2(1920, 1032)
	return _camada_janelas.size


# ------------------------------------------------------------------ abrir / fechar
func abrir_app(app_id: String, args: Dictionary = {}) -> JanelaBase:
	var info := app_info(app_id)
	if info.is_empty():
		SistemaNotificacoes.notificar("Sistema", "Aplicativo desconhecido: %s" % app_id, "erro")
		return null
	if app_pausado(app_id):
		SistemaAudio.tocar_sfx("erro")
		SistemaNotificacoes.notificar("Pausado pela Maya", "Pausado pela Maya: você já passou do seu limite.", "ia", 6.0)
		return null
	if info.get("args_padrao") is Dictionary:
		var com_padrao: Dictionary = (info["args_padrao"] as Dictionary).duplicate()
		com_padrao.merge(args, true)
		args = com_padrao
	if _camada_janelas == null:
		push_warning("GerenciadorJanelas: sem camada de janelas registrada.")
		return null
	if not bool(info.get("multiplas_instancias", true)):
		var existente := _janela_do_app(app_id)
		if existente != null:
			if existente.minimizada:
				restaurar(existente)
			focar(existente)
			var app_existente := existente.conteudo as AppBase
			if app_existente != null and not args.is_empty():
				app_existente.receber_args(args)
			return existente
	var caminho_cena := str(info.get("cena", ""))
	if caminho_cena == "" or not ResourceLoader.exists(caminho_cena):
		_falha_ao_abrir(info, "cena ausente: %s" % caminho_cena)
		return null
	var cena := load(caminho_cena) as PackedScene
	if cena == null:
		_falha_ao_abrir(info, "recurso não é uma cena")
		return null
	var no := cena.instantiate()
	var conteudo := no as Control
	if conteudo == null:
		if no != null:
			no.queue_free()
		_falha_ao_abrir(info, "a raiz da cena não é um Control")
		return null

	var janela := _criar_janela()
	if janela == null:
		conteudo.queue_free()
		_falha_ao_abrir(info, "a cena da janela não pôde ser criada")
		return null
	janela.name = "Janela_%s_%d" % [app_id, _proximo_pid]
	janela.pid = _proximo_pid
	_proximo_pid += 7
	_camada_janelas.add_child(janela)
	var tamanho := _vetor(info.get("tamanho", [800, 560]), Vector2(800, 560))
	var app := conteudo as AppBase
	if app != null:
		app.app_id = app_id
		app.info = info
		app.janela = janela
		app.titulo_alterado.connect(janela.definir_titulo)
	janela.configurar(info, conteudo, tamanho, _posicao_em_cascata(tamanho))
	janela.pedido_fechar.connect(_ao_pedido_fechar)
	janela.pedido_minimizar.connect(_ao_pedido_minimizar)
	_janelas.append(janela)
	GerenciadorEstado.set_flag("app_aberto:" + app_id, true)
	SistemaAudio.tocar_sfx("abrir")
	GerenciadorNarrativa.notificar("app_aberto:" + app_id)
	if app != null:
		app.iniciar(args)
	focar(janela)
	janela_aberta.emit(janela)
	janelas_alteradas.emit()
	return janela


## Fecha a janela. Respeita o aviso de alterações do app e o bloqueio narrativo (que é finito).
func fechar_janela(janela: JanelaBase, forcar: bool = false) -> void:
	if janela == null or not is_instance_valid(janela) or not _janelas.has(janela):
		return
	if bool(janela.get_meta("fechando", false)):
		return
	if not forcar:
		if GerenciadorEstado.fechamento_bloqueado(janela.app_id):
			janela.tremer()
			SistemaAudio.tocar_sfx("erro")
			var restantes := GerenciadorEstado.tentativas_de_fechar_restantes(janela.app_id)
			var complemento := " Tente fechar novamente." if restantes > 0 else " Você pode fechar agora."
			SistemaNotificacoes.notificar("Maya", "Esta janela deve permanecer aberta, {nome}." + complemento, "aviso", 4.0)
			return
		var app := janela.conteudo as AppBase
		if app != null:
			janela.set_meta("fechando", true)
			# Alguns apps pedem confirmação ao jogador (coroutine); o padrão da AppBase responde na hora.
			@warning_ignore("redundant_await")
			var pode: bool = await app.confirmar_fechar()
			if not is_instance_valid(janela):
				return
			janela.set_meta("fechando", false)
			if not pode:
				return
	_finalizar_fechamento(janela)


func fechar_todas() -> void:
	for janela in _janelas.duplicate():
		if is_instance_valid(janela):
			_finalizar_fechamento(janela)


func fechar_ativa() -> void:
	if _ativa != null and is_instance_valid(_ativa):
		fechar_janela(_ativa)


func minimizar_ativa() -> void:
	if _ativa != null and is_instance_valid(_ativa):
		minimizar(_ativa)


func minimizar(janela: JanelaBase, forcar: bool = false) -> void:
	if janela == null or not is_instance_valid(janela) or not _janelas.has(janela) or janela.minimizada:
		return
	if not forcar and GerenciadorEstado.tem_flag("foco_forcado"):
		var n := int(janela.get_meta("tentativas_min", 0)) + 1
		janela.set_meta("tentativas_min", n)
		if n <= TENTATIVAS_MINIMIZAR_BLOQUEADAS:
			janela.tremer()
			SistemaAudio.tocar_sfx("erro")
			SistemaNotificacoes.notificar("Maya", "Mantenha o foco, {nome}. Minimizar não é recomendado. Tente de novo se realmente quiser.", "aviso", 4.0)
			return
	janela.definir_minimizada(true)
	janela.definir_ativa(false)
	if _ativa == janela:
		_ativa = null
	SistemaAudio.tocar_sfx("minimizar")
	_focar_topo()
	janelas_alteradas.emit()


func restaurar(janela: JanelaBase) -> void:
	if janela == null or not is_instance_valid(janela) or not _janelas.has(janela):
		return
	janela.definir_minimizada(false)
	focar(janela)
	janelas_alteradas.emit()


func focar(janela: JanelaBase) -> void:
	if janela == null or not is_instance_valid(janela) or not _janelas.has(janela) or _camada_janelas == null:
		return
	if janela.minimizada:
		janela.definir_minimizada(false)
	_camada_janelas.move_child(janela, -1)
	if _ativa == janela:
		return
	if _ativa != null and is_instance_valid(_ativa):
		_ativa.definir_ativa(false)
	_ativa = janela
	janela.definir_ativa(true)
	var app := janela.conteudo as AppBase
	if app != null:
		app.ao_focar()
	janela_focada.emit(janela)
	janelas_alteradas.emit()


## Clique na barra de tarefas: restaura, minimiza (se ativa) ou só foca.
func alternar_da_barra(janela: JanelaBase) -> void:
	if janela == null or not is_instance_valid(janela):
		return
	if janela.minimizada:
		restaurar(janela)
	elif janela == _ativa:
		minimizar(janela)
	else:
		focar(janela)


func proxima_janela() -> void:
	var ordem := _ordem_z()
	if ordem.size() < 2:
		return
	focar(ordem[ordem.size() - 2])


# ------------------------------------------------------------------ consulta
func janela_ativa() -> JanelaBase:
	return _ativa if _ativa != null and is_instance_valid(_ativa) else null   # ternario-ok: o outro ramo é um objeto


func janelas() -> Array:
	return _janelas.duplicate()


func janelas_do_app(app_id: String) -> Array:
	var saida: Array = []
	for j in _janelas:
		if is_instance_valid(j) and j.app_id == app_id:
			saida.append(j)
	return saida


func app_aberto(app_id: String) -> bool:
	return _janela_do_app(app_id) != null


## Processos "reais" do jogo (um por janela aberta) para o Monitor do Sistema. Nada aqui é um processo do SO.
func processos_abertos() -> Array:
	var saida: Array = []
	for j in _janelas:
		if is_instance_valid(j):
			saida.append({"pid": j.pid, "nome": str(j.info.get("processo", j.app_id + ".exe")), "app_id": j.app_id, "titulo": j.titulo})
	return saida


func atualizar_temas() -> void:
	for j in _janelas:
		if is_instance_valid(j):
			j.atualizar_tema()


func glitch_nas_janelas(duracao: float = 0.8) -> void:
	for j in _janelas:
		if is_instance_valid(j):
			j.glitch_titulo(duracao)


# ------------------------------------------------------------------ diálogos modais
func modal_ativo() -> bool:
	return _camada_modais != null and is_instance_valid(_camada_modais) and _camada_modais.get_child_count() > 0


func abrir_modal(no: Control) -> bool:
	if _camada_modais == null or not is_instance_valid(_camada_modais):
		if no != null:
			no.queue_free()
		return false
	_camada_modais.add_child(no)
	return true


func alerta(titulo: String, texto: String, rotulo: String = "OK") -> void:
	var d := DialogoNexus.criar(titulo, texto, DialogoNexus.Modo.ALERTA, rotulo)
	if abrir_modal(d):
		await d.resolvido


## `foco_seguro`: o foco inicial fica no botão de cancelar (use em decisões irreversíveis; o padrão mantém o foco no confirmar).
func confirmar(titulo: String, texto: String, rotulo_ok: String = "Confirmar", rotulo_cancelar: String = "Cancelar", perigo: bool = false, foco_seguro: bool = false) -> bool:
	var d := DialogoNexus.criar(titulo, texto, DialogoNexus.Modo.CONFIRMAR, rotulo_ok, rotulo_cancelar, "", false, perigo, "", foco_seguro)
	if not abrir_modal(d):
		return false
	var r: Variant = await d.resolvido
	return bool(r)


## Mostra várias opções e devolve o índice escolhido (ou -1 se o jogador cancelou com Esc).
func escolher(titulo: String, texto: String, opcoes: PackedStringArray, indice_padrao: int = 0, indice_perigo: int = -1) -> int:
	var d := DialogoNexus.criar_escolha(titulo, texto, opcoes, indice_padrao, indice_perigo)
	if not abrir_modal(d):
		return -1
	var r: Variant = await d.resolvido
	return int(r)


## Retorna o texto digitado ou null se o jogador cancelou.
func pedir_texto(titulo: String, texto: String, placeholder: String = "", rotulo_ok: String = "OK", oculto: bool = false, valor_inicial: String = "") -> Variant:
	var d := DialogoNexus.criar(titulo, texto, DialogoNexus.Modo.TEXTO, rotulo_ok, "Cancelar", placeholder, oculto, false, valor_inicial)
	if not abrir_modal(d):
		return null
	var r: Variant = await d.resolvido
	return r


## Retorna o caminho escolhido no VFS ou "" se cancelou.
func escolher_arquivo(modo: DialogoArquivo.Modo, pasta_inicial: String, nome_sugerido: String = "", extensoes: PackedStringArray = PackedStringArray()) -> String:
	var d := DialogoArquivo.criar(modo, pasta_inicial, nome_sugerido, extensoes)
	if not abrir_modal(d):
		return ""
	var r: Variant = await d.resolvido
	return str(r)


# ------------------------------------------------------------------ internos
func _carregar_catalogo() -> void:
	catalogo.clear()
	_por_id.clear()
	if not FileAccess.file_exists(ARQUIVO_CATALOGO):
		push_error("GerenciadorJanelas: catálogo de apps ausente (%s)." % ARQUIVO_CATALOGO)
		return
	var json: Variant = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO_CATALOGO))
	if not (json is Dictionary) or not (json.get("apps") is Array):
		push_error("GerenciadorJanelas: catálogo de apps inválido.")
		return
	for item in json["apps"]:
		if not (item is Dictionary):
			continue
		var app: Dictionary = item
		var id_app := str(app.get("id", ""))
		if id_app == "" or _por_id.has(id_app):
			push_warning("GerenciadorJanelas: app sem id ou duplicado ignorado.")
			continue
		if not app.has("nome"):
			app["nome"] = id_app
		catalogo.append(app)
		_por_id[id_app] = app


func _filtrar(campo: String) -> Array:
	var saida: Array = []
	for info in catalogo:
		if bool(info.get(campo, false)) and app_listado(str(info["id"])):
			saida.append(info)
	return saida


## Instancia a cena da janela (janela_base.tscn). Devolve null (e registra o erro) se a cena faltar ou estiver quebrada:
## a janela não existe mais "sem cena", porque sua estrutura visual mora no .tscn.
func _criar_janela() -> JanelaBase:
	if not ResourceLoader.exists(CENA_JANELA):
		push_error("GerenciadorJanelas: cena da janela ausente: %s" % CENA_JANELA)
		return null
	var cena := load(CENA_JANELA) as PackedScene
	var janela := cena.instantiate() as JanelaBase if cena != null else null   # ternario-ok: o outro ramo é um objeto
	if janela == null:
		push_error("GerenciadorJanelas: %s não é uma cena com raiz JanelaBase." % CENA_JANELA)
	return janela


func _vetor(valor: Variant, padrao: Vector2) -> Vector2:
	if valor is Array and valor.size() >= 2:
		return Vector2(float(valor[0]), float(valor[1]))
	return padrao


func _posicao_em_cascata(tamanho: Vector2) -> Vector2:
	var area := area_util()
	var base := Vector2(70.0 + 32.0 * float(_cascata), 36.0 + 28.0 * float(_cascata))
	_cascata = (_cascata + 1) % 8
	if base.x + tamanho.x > area.x or base.y + tamanho.y > area.y:
		_cascata = 0
		base = Vector2(maxf((area.x - tamanho.x) * 0.5, 0.0), maxf((area.y - tamanho.y) * 0.5, 0.0))
	return base


func _janela_do_app(app_id: String) -> JanelaBase:
	for j in _janelas:
		if is_instance_valid(j) and j.app_id == app_id:
			return j
	return null


## O monitor virtual registra (ou, com Callable() vazio, remove) a conversão tela física -> desktop usada para achar a janela clicada.
func definir_conversor_de_ponto(conversor: Callable) -> void:
	_conversor_de_ponto = conversor


func _ponto_do_desktop(ponto: Vector2) -> Vector2:
	if _conversor_de_ponto.is_valid():
		return _conversor_de_ponto.call(ponto)
	return ponto


func _janela_em(pos: Vector2) -> JanelaBase:
	if _camada_janelas == null:
		return null
	var filhos := _camada_janelas.get_children()
	for i in range(filhos.size() - 1, -1, -1):
		var j := filhos[i] as JanelaBase
		if j != null and j.visible and not j.minimizada and j.get_global_rect().has_point(pos):
			return j
	return null


func _ordem_z() -> Array:
	var saida: Array = []
	if _camada_janelas == null:
		return saida
	for filho in _camada_janelas.get_children():
		var j := filho as JanelaBase
		if j != null and _janelas.has(j):
			saida.append(j)
	return saida


func _focar_topo() -> void:
	var ordem := _ordem_z()
	for i in range(ordem.size() - 1, -1, -1):
		var j: JanelaBase = ordem[i]
		if not j.minimizada:
			focar(j)
			return


func _finalizar_fechamento(janela: JanelaBase) -> void:
	var app := janela.conteudo as AppBase
	var id_do_app := janela.app_id
	if app != null:
		app.ao_fechar()
	_janelas.erase(janela)
	if _ativa == janela:
		_ativa = null
	if janela.pedido_fechar.is_connected(_ao_pedido_fechar):
		janela.pedido_fechar.disconnect(_ao_pedido_fechar)
	if janela.pedido_minimizar.is_connected(_ao_pedido_minimizar):
		janela.pedido_minimizar.disconnect(_ao_pedido_minimizar)
	janela_fechada.emit(janela)
	janela.destruir()
	SistemaAudio.tocar_sfx("fechar")
	_focar_topo()
	janelas_alteradas.emit()
	GerenciadorNarrativa.notificar("janela_fechada:" + id_do_app)


func _falha_ao_abrir(info: Dictionary, motivo: String) -> void:
	push_warning("GerenciadorJanelas: falha ao abrir '%s': %s" % [str(info.get("id", "?")), motivo])
	SistemaAudio.tocar_sfx("erro")
	SistemaNotificacoes.notificar("Falha ao abrir", "%s não pôde ser iniciado. O restante do sistema continua funcionando." % str(info.get("nome", "O aplicativo")), "erro")


func _ao_pedido_fechar(janela: JanelaBase) -> void:
	fechar_janela(janela)


func _ao_pedido_minimizar(janela: JanelaBase) -> void:
	minimizar(janela)


func _ao_area_redimensionada() -> void:
	for j in _janelas:
		if is_instance_valid(j):
			j.reajustar()


## A visibilidade dos apps depende de flags (`app_oculto:<id>`, `desktop_reduzido`, `apps_pausados_pela_maya`): quando elas mudam, ícones, menu e barra se refazem.
func _ao_flag(nome: String, _valor: Variant) -> void:
	if nome.begins_with("app_oculto:") or nome == "desktop_reduzido" or nome == "apps_pausados_pela_maya" or nome == "apps_ocultos_pela_maya":
		catalogo_alterado.emit()
