extends Node
## Salvamento, carregamento, autosave e checkpoints. Só escreve dentro de user://nexus_os/.
## Nunca apaga arquivos: um salvamento ilegível é renomeado para ".corrompido" e o jogo segue com um novo.
## Depende da narrativa apenas por sinais/propriedades (a narrativa não conhece este autoload).

signal salvo(arquivo: String)
signal falha_ao_carregar(motivo: String)

const PASTA := "user://nexus_os"
const ARQUIVO := "user://nexus_os/salvamento.json"
## Versão do formato do salvamento. 2 = rebranding Maya Human Syntax: o formato é o mesmo da versão 1 (mesma pasta, mesmo
## arquivo, mesmos IDs e flags); a versão só marca quais salvamentos ainda trazem textos, nomes de processo e caminhos
## de arquivo da marca antiga, que _carregar_de() atualiza ao ler um salvamento da versão 1.
## 3 = Story Nodes, métricas AUT/CON/DEP, perfil (pronome), eventos únicos, apps instalados, falso boot, ajuda e reações de NPC.
## Os saves das versões 1 e 2 continuam válidos: os campos novos ausentes recebem valores iniciais seguros em
## GerenciadorEstado.de_dicionario.
## 5 = ROTEIRO v2.0 (sem dias): Task atual, nó do roteiro, Dependência/Autonomia, cinco permissões, flags de Rafael e do Mensageiro,
## tentativas de revogação, puzzles e escolhas. Um save das versões 1 a 4 (modelo de dias) continua LEGÍVEL e é MIGRADO: perfil, nome,
## configurações e apps instalados são mantidos; o progresso recomeça na Task 1 com os arquivos iniciais (o antigo modelo de dias não tem
## equivalente no roteiro). Nada é apagado: o arquivo antigo só é sobrescrito no próximo salvamento.
const VERSAO := 5
const INTERVALO_AUTOSAVE := 12.0
## Campos do estado salvo e o tipo que cada um precisa ter. O carregamento atribui esses valores a variáveis tipadas do
## GerenciadorEstado; um arquivo legível mas com o tipo errado (ex.: "flags": 5) o derrubaria NO MEIO da aplicação, deixando
## estado novo misturado com o antigo. validar_arquivo() recusa esse arquivo ANTES de aplicar qualquer coisa.
const CAMPOS_NUMERICOS: Array = ["seguranca", "corrupcao", "inicio_unix", "tempo_do_dia", "schema_roteiro", "dependencia_maya", "autonomia_jogador", "tentativas_revogacao_task_9"]
const CAMPOS_DICIONARIO: Array = ["flags", "objetivos_concluidos", "permissoes", "chat", "bloqueios_fechar", "metricas", "nos", "falso_boot", "perfil_extra", "tentativas_revogacao", "puzzles_resolvidos", "progresso_puzzles", "escolhas_realizadas", "roteiro_aux", "investigacao_rafael", "mensageiro"]
const CAMPOS_LISTA: Array = ["objetivos_obrigatorios", "apps_desbloqueados", "processos_maliciosos", "contatos_bloqueados", "eventos_disparados", "acoes_pendentes", "eventos_unicos", "apps_instalados", "ajuda_usos", "reacoes_npc", "dialogos_maya", "atos_de_resistencia", "historico_roteiro"]
const CAMPOS_TEXTO: Array = ["nome_jogador", "pronome_jogador", "no_atual", "perfil_final", "final_id", "story_node_atual"]

var habilitado: bool = true
## Pasta onde o salvamento e os checkpoints são gravados. Só os testes automáticos trocam isto (por uma subpasta própria de
## user:// criada a cada execução, que eles nunca apagam), para nunca encostarem no salvamento real do jogador. Fora de user://
## nada é gravado.
var pasta: String = PASTA
var _sujo: bool = false
var _espera: float = 0.0


func _ready() -> void:
	GerenciadorEstado.flag_alterada.connect(_ao_flag_alterada)
	GerenciadorEstado.mensagem_recebida.connect(_ao_mensagem)
	GerenciadorEstado.permissao_alterada.connect(_ao_permissao)
	GerenciadorEstado.contato_bloqueado.connect(_ao_contato)
	GerenciadorEstado.metrica_mudou.connect(_ao_metrica)
	GerenciadorEstado.perfil_alterado.connect(_ao_perfil)
	GerenciadorEstado.apps_instalados_mudou.connect(_ao_app_instalado)
	GerenciadorEstado.falso_boot_mudou.connect(_ao_falso_boot)
	GerenciadorNos.progresso_atualizado.connect(_ao_no)
	SistemaArquivosVirtual.arvore_alterada.connect(_ao_vfs)
	SistemaArquivosVirtual.arquivo_alterado.connect(_ao_vfs)
	GerenciadorNarrativa.etapa_iniciada.connect(_ao_etapa_iniciada)
	GerenciadorEstado.roteiro_alterado.connect(_ao_roteiro)
	GerenciadorNarrativa.jogo_finalizado.connect(_ao_final)


func _exit_tree() -> void:
	_desconectar(GerenciadorEstado.flag_alterada, _ao_flag_alterada)
	_desconectar(GerenciadorEstado.mensagem_recebida, _ao_mensagem)
	_desconectar(GerenciadorEstado.permissao_alterada, _ao_permissao)
	_desconectar(GerenciadorEstado.contato_bloqueado, _ao_contato)
	_desconectar(GerenciadorEstado.metrica_mudou, _ao_metrica)
	_desconectar(GerenciadorEstado.perfil_alterado, _ao_perfil)
	_desconectar(GerenciadorEstado.apps_instalados_mudou, _ao_app_instalado)
	_desconectar(GerenciadorEstado.falso_boot_mudou, _ao_falso_boot)
	_desconectar(GerenciadorNos.progresso_atualizado, _ao_no)
	_desconectar(SistemaArquivosVirtual.arvore_alterada, _ao_vfs)
	_desconectar(SistemaArquivosVirtual.arquivo_alterado, _ao_vfs)
	_desconectar(GerenciadorNarrativa.etapa_iniciada, _ao_etapa_iniciada)
	_desconectar(GerenciadorEstado.roteiro_alterado, _ao_roteiro)
	_desconectar(GerenciadorNarrativa.jogo_finalizado, _ao_final)


func _process(delta: float) -> void:
	if not _sujo:
		return
	if not habilitado or not GerenciadorNarrativa.jogo_ativo:
		_sujo = false
		return
	_espera += delta
	if _espera >= INTERVALO_AUTOSAVE:
		salvar()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and habilitado and GerenciadorNarrativa.jogo_ativo:
		salvar()


# ------------------------------------------------------------------ API
func salvar() -> bool:
	return _escrever(_arquivo_principal())


## Um checkpoint por Task (1 a 9), gravado quando a Task começa.
func salvar_checkpoint(etapa: int) -> bool:
	return _escrever(_caminho_checkpoint(etapa))


func existe_salvamento() -> bool:
	return FileAccess.file_exists(_arquivo_principal())


func existe_checkpoint(etapa: int) -> bool:
	return FileAccess.file_exists(_caminho_checkpoint(etapa))


func carregar() -> bool:
	return _carregar_de(_arquivo_principal())


func carregar_checkpoint(etapa: int) -> bool:
	return _carregar_de(_caminho_checkpoint(etapa))


## Resumo para a tela de boot: {existe, nome, dia, salvo_em, final}.
func metadados() -> Dictionary:
	var vazio := {"existe": false, "nome": "", "etapa": 1, "salvo_em": "", "final": ""}
	var dados := _ler(_arquivo_principal())
	if dados.is_empty():
		return vazio
	var estado: Variant = dados.get("estado")
	if not (estado is Dictionary):
		return vazio
	return {
		"existe": true,
		"nome": str(estado.get("nome_jogador", "")),
		"etapa": _etapa_do_estado(estado),
		"salvo_em": str(dados.get("salvo_em", "")),
		"final": str(estado.get("final_id", "")),
	}


# ------------------------------------------------------------------ conferência e pontos de carga
# Usados pelo Menu Principal, pela Pausa e pela Tela de Fim de Jogo (todos pedem o carregamento pela fachada `Sessao`, que
# usa SÓ estas funções: não existe um segundo sistema de carga). Nada aqui renomeia, grava ou apaga arquivos, exceto
# preservar_se_invalido(), que só renomeia (nunca apaga) um salvamento principal ilegível.

## Lê e confere um arquivo de salvamento SEM aplicar nada. Devolve
## {ok, motivo, caminho, versao, nome, dia, salvo_em, final_id, inicio}; `ok` só é true se o arquivo é legível, tem versão
## conhecida e todos os campos presentes do estado têm o tipo certo. O estado atual do jogo não é tocado.
func validar_arquivo(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		var ausente := _resultado_vazio(caminho)
		ausente["motivo"] = "arquivo ausente"
		return ausente
	return _conferir(caminho, _ler(caminho))


## A conferência em si, sobre o conteúdo já lido (para não ler o arquivo duas vezes).
func _conferir(caminho: String, dados: Dictionary) -> Dictionary:
	var resultado := _resultado_vazio(caminho)
	if dados.is_empty():
		resultado["motivo"] = "arquivo ilegível"
		return resultado
	var versao_bruta: Variant = dados.get("versao", 0)
	if not _eh_numero(versao_bruta) or int(versao_bruta) < 1 or int(versao_bruta) > VERSAO:
		resultado["motivo"] = "versão de salvamento desconhecida"
		return resultado
	var estado_bruto: Variant = dados.get("estado")
	if not (estado_bruto is Dictionary):
		resultado["motivo"] = "estado ausente"
		return resultado
	var estado: Dictionary = estado_bruto
	for campo in CAMPOS_NUMERICOS:
		if estado.has(campo) and not _eh_numero(estado[campo]):
			resultado["motivo"] = "campo '%s' com tipo inválido" % campo
			return resultado
	for campo in CAMPOS_DICIONARIO:
		if estado.has(campo) and not (estado[campo] is Dictionary):
			resultado["motivo"] = "campo '%s' com tipo inválido" % campo
			return resultado
	for campo in CAMPOS_LISTA:
		if estado.has(campo) and not (estado[campo] is Array):
			resultado["motivo"] = "campo '%s' com tipo inválido" % campo
			return resultado
	for campo in CAMPOS_TEXTO:
		if estado.has(campo) and typeof(estado[campo]) != TYPE_STRING:
			resultado["motivo"] = "campo '%s' com tipo inválido" % campo
			return resultado
	if dados.has("vfs"):
		var vfs: Variant = dados["vfs"]
		if not (vfs is Dictionary) or ((vfs as Dictionary).has("operacoes") and not ((vfs as Dictionary)["operacoes"] is Array)):
			resultado["motivo"] = "arquivos virtuais com formato inválido"
			return resultado
	resultado["ok"] = true
	resultado["versao"] = int(versao_bruta)
	resultado["nome"] = str(estado.get("nome_jogador", ""))
	resultado["etapa"] = _etapa_do_estado(estado)
	resultado["salvo_em"] = str(dados.get("salvo_em", ""))
	resultado["final_id"] = str(estado.get("final_id", ""))
	resultado["inicio"] = int(estado.get("inicio_unix", 0))
	return resultado


## Escolhe de onde carregar: o salvamento principal, se for válido, ou o checkpoint válido mais recente.
## `somente_seguro` ignora salvamentos de uma história já concluída (com final): carregá-los reabriria o final, então a
## Pausa e o Fim de Jogo pedem só pontos seguros. Os checkpoints de OUTRA campanha (restos de um jogo anterior) são
## ignorados quando se sabe a campanha do salvamento principal; sem ele vale o checkpoint da campanha mais recente.
## Devolve {existe, tipo ("salvamento" | "checkpoint"), caminho, nome, etapa, salvo_em, final_id}.
func ponto_de_carga(somente_seguro: bool = false) -> Dictionary:
	var principal := validar_arquivo(_arquivo_principal())
	if bool(principal["ok"]) and not (somente_seguro and str(principal["final_id"]) != ""):
		return _como_ponto(principal, "salvamento")
	var campanha: int = int(principal["inicio"]) if bool(principal["ok"]) else -1
	var melhor: Dictionary = {}
	for etapa in range(9, 0, -1):
		var candidato := validar_arquivo(_caminho_checkpoint(etapa))
		if not bool(candidato["ok"]) or (somente_seguro and str(candidato["final_id"]) != ""):
			continue
		if campanha >= 0 and int(candidato["inicio"]) != campanha:
			continue
		# Varrendo da Task 9 à 1, o primeiro checkpoint de cada campanha é o da maior Task dela.
		if melhor.is_empty() or int(candidato["inicio"]) > int(melhor["inicio"]):
			melhor = candidato
	if melhor.is_empty():
		return {"existe": false, "tipo": "", "caminho": "", "nome": "", "etapa": 1, "salvo_em": "", "final_id": ""}
	return _como_ponto(melhor, "checkpoint")


## Há algum ponto de carga válido (salvamento principal ou checkpoint)?
func existe_ponto_de_carga() -> bool:
	return bool(ponto_de_carga(false)["existe"])


## Lê e confere `caminho` e devolve o conteúdo pronto para aplicar, ou {} se o arquivo não passar na conferência.
## Não altera o estado do jogo nem os arquivos. O que foi lido aqui é exatamente o que `aplicar_dados` vai aplicar.
func ler_conferido(caminho: String) -> Dictionary:
	var dados := _ler(caminho)
	if not bool(_conferir(caminho, dados)["ok"]):
		return {}
	return dados


## Aplica um conteúdo já conferido por `ler_conferido`: estado, arquivos virtuais e migração de saves antigos. Quem chama
## deve ainda chamar GerenciadorNarrativa.retomar(). Não escreve nada em disco.
func aplicar_dados(dados: Dictionary) -> void:
	var estado: Dictionary = dados["estado"]
	if int(dados.get("versao", 0)) < 2:
		estado = GerenciadorEstado.migrar_marca_antiga(estado)
	GerenciadorEstado.de_dicionario(estado)
	var vfs: Variant = dados.get("vfs")
	if int(dados.get("versao", 0)) < 5:
		SistemaArquivosVirtual.carregar_inicial()   # arquivos do modelo antigo não existem no roteiro v2.0 (migração)
	elif vfs is Dictionary:
		SistemaArquivosVirtual.desserializar(vfs)
	else:
		SistemaArquivosVirtual.carregar_inicial()
	_sujo = false
	_espera = 0.0


## Antes de um novo jogo sobrescrever o salvamento principal: se ele existe mas não passa na conferência, é preservado
## (renomeado com sufixo, sem apagar nada) para não ser perdido em silêncio. Devolve true se preservou um arquivo.
func preservar_se_invalido() -> bool:
	var caminho := _arquivo_principal()
	if not FileAccess.file_exists(caminho) or bool(validar_arquivo(caminho)["ok"]):
		return false
	var destino := "%s.corrompido_%d" % [caminho, int(Time.get_unix_time_from_system())]
	if FileAccess.file_exists(destino):
		return false
	var erro := DirAccess.rename_absolute(caminho, destino)
	if erro != OK:
		push_warning("SistemaPersistencia: não foi possível preservar o salvamento ilegível (erro %d)." % erro)
		return false
	push_warning("SistemaPersistencia: salvamento ilegível preservado em %s." % destino)
	return true


# ------------------------------------------------------------------ internos
func _arquivo_principal() -> String:
	return ARQUIVO if pasta == PASTA else pasta + "/salvamento.json"


func _caminho_checkpoint(etapa: int) -> String:
	return "%s/checkpoint_task_%d.json" % [pasta, clampi(etapa, 1, 9)]


## Índice 1..9 da Task gravada no estado salvo. Saves antigos (sem `no_atual` de Task) valem 1.
func _etapa_do_estado(estado: Dictionary) -> int:
	return GerenciadorEstado.etapa_da_task(str(estado.get("no_atual", "")))


## Caminho do arquivo do checkpoint da Task (para quem lê e confere o arquivo antes de aplicá-lo; ver Sessao.carregar_checkpoint).
func caminho_do_checkpoint(etapa: int) -> String:
	return _caminho_checkpoint(etapa)


func _montar() -> Dictionary:
	return {
		"versao": VERSAO,
		"salvo_em": Time.get_datetime_string_from_system(false, true),
		"estado": GerenciadorEstado.para_dicionario(),
		"vfs": SistemaArquivosVirtual.serializar(),
	}


func _escrever(caminho: String) -> bool:
	if not pasta.begins_with("user://"):
		push_warning("SistemaPersistencia: a pasta de gravação precisa ficar em user:// (veio %s); nada foi gravado." % pasta)
		return false
	DirAccess.make_dir_recursive_absolute(pasta)
	var texto := JSON.stringify(_montar())
	var temporario := caminho + ".tmp"
	var f := FileAccess.open(temporario, FileAccess.WRITE)
	if f == null:
		push_warning("SistemaPersistencia: não foi possível gravar %s (erro %d)." % [caminho, FileAccess.get_open_error()])
		return false
	f.store_string(texto)
	f.close()
	if DirAccess.rename_absolute(temporario, caminho) != OK:
		# Alguns sistemas não substituem arquivos existentes: grava direto como alternativa.
		var direto := FileAccess.open(caminho, FileAccess.WRITE)
		if direto == null:
			push_warning("SistemaPersistencia: falha ao finalizar o salvamento.")
			return false
		direto.store_string(texto)
		direto.close()
	_sujo = false
	_espera = 0.0
	salvo.emit(caminho)
	return true


func _ler(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		return {}
	# JSON.new().parse() devolve só um código de erro; JSON.parse_string() também
	# escreveria "Parse JSON failed" no Depurador a cada arquivo ilegível, além do
	# aviso de "salvamento inválido" que _carregar_de() já emite.
	var analisador := JSON.new()
	if analisador.parse(FileAccess.get_file_as_string(caminho)) != OK:
		return {}
	var json: Variant = analisador.data
	if not (json is Dictionary):
		return {}
	return json


func _carregar_de(caminho: String) -> bool:
	if not FileAccess.file_exists(caminho):
		return false
	var dados := _ler(caminho)
	if not bool(_conferir(caminho, dados)["ok"]):
		push_warning("SistemaPersistencia: salvamento inválido; preservado como .corrompido.")
		DirAccess.rename_absolute(caminho, caminho + ".corrompido")
		falha_ao_carregar.emit("salvamento inválido")
		return false
	aplicar_dados(dados)
	return true


func _resultado_vazio(caminho: String) -> Dictionary:
	return {"ok": false, "motivo": "", "caminho": caminho, "versao": 0, "nome": "", "etapa": 1, "salvo_em": "", "final_id": "", "inicio": 0}


func _como_ponto(conferencia: Dictionary, tipo: String) -> Dictionary:
	return {
		"existe": true, "tipo": tipo, "caminho": str(conferencia["caminho"]), "nome": str(conferencia["nome"]),
		"etapa": int(conferencia["etapa"]), "salvo_em": str(conferencia["salvo_em"]), "final_id": str(conferencia["final_id"]),
	}


func _eh_numero(valor: Variant) -> bool:
	return typeof(valor) == TYPE_INT or typeof(valor) == TYPE_FLOAT


func _marcar_sujo() -> void:
	_sujo = true


func _desconectar(sinal: Signal, alvo: Callable) -> void:
	if sinal.is_connected(alvo):
		sinal.disconnect(alvo)


func _ao_flag_alterada(_nome: String, _valor: Variant) -> void:
	_marcar_sujo()


func _ao_mensagem(_contato: String, _entrada: Dictionary) -> void:
	_marcar_sujo()


func _ao_permissao(_nome: String, _ativa: bool) -> void:
	_marcar_sujo()


func _ao_contato(_id: String) -> void:
	_marcar_sujo()


func _ao_metrica(_nome: String, _valor: float, _delta: float) -> void:
	_marcar_sujo()


func _ao_perfil(_nome: String, _pronome: String) -> void:
	_marcar_sujo()


func _ao_app_instalado(_app_id: String, _instalado: bool) -> void:
	_marcar_sujo()


func _ao_falso_boot(_ativo: bool) -> void:
	_marcar_sujo()


func _ao_no(_id: String) -> void:
	_marcar_sujo()


func _ao_vfs(_caminho: String) -> void:
	_marcar_sujo()


## Início de cada Task: grava o checkpoint da Task (a avaliação final "av" não sobrescreve o da Task 9) e o salvamento principal.
func _ao_etapa_iniciada(etapa: int) -> void:
	if not habilitado:
		return
	if GerenciadorEstado.task_atual != "av":
		salvar_checkpoint(etapa)
	salvar()


## Cada nó numerado do roteiro é um ponto de salvamento: o autosave grava na próxima janela.
func _ao_roteiro(_id_no: String) -> void:
	_marcar_sujo()


func _ao_final(_id_final: String) -> void:
	if habilitado:
		salvar()
