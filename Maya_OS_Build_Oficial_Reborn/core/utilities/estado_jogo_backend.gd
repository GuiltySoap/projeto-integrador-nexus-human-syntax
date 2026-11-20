class_name EstadoJogoBackend
extends RefCounted
## Contrato de arquivo entre o jogo (Godot) e o backend em C (§25/§26): `estado_jogo.json`.
##
## COMO O BACKEND É EXECUTADO: é uma FERRAMENTA AUXILIAR de linha de comando (backend/, compilada à parte com o Makefile), não um módulo, uma
## biblioteca nem uma extensão da Godot. O jogo NUNCA a executa (o projeto não executa programas externos: `make check-shell` confere). A integração é este
## ARQUIVO: a ferramenta (`maya_backend --choice <id>`) grava o estado e o jogo o lê e o valida; o jogo também grava o MESMO formato, e a
## ferramenta aceita o arquivo do jogo como ponto de partida. Os dois lados seguem as mesmas regras (backend/bk_estado.h).
##
## FORMATO (versão 1; todos os campos são obrigatórios na leitura, campos desconhecidos são ignorados):
##   { "schema_version": 1, "choice_id": "ok", "status": "ok",
##     "metrics": {"autonomia": 47, "conformidade": 52, "dependencia": 4},
##     "timestamp": "2026-11-17T21:00:00Z", "is_placeholder": false }
##   - choice_id: "" (nenhuma escolha aplicada) ou 1 a 48 caracteres, letra minúscula e depois [a-z0-9_].
##   - status: 1 a 32 caracteres [a-z_].   - metrics: números finitos de 0 a 100 (as mesmas métricas AUT/CON/DEP do jogo).
##   - timestamp: UTC, "YYYY-MM-DDTHH:MM:SSZ".   - is_placeholder: a escolha ainda usa texto/narrativa provisórios.
##
## ONDE: `user://nexus_os/estado_jogo.json`, junto do salvamento e SEPARADO dele e das configurações (outro arquivo, outro esquema). Nunca em
## res:// (somente leitura numa build distribuída): gravar em res:// é recusado sempre. Caminhos absolutos fora de user:// só com
## `permitir_absoluto` (testes e ferramentas de desenvolvimento).
##
## GRAVAÇÃO: validada ANTES (nunca escreve um estado fora do esquema), em UTF-8, com .tmp conferido por releitura e depois renomeado por cima
## do destino; o arquivo anterior vira `.bak` durante a troca, então uma falha no meio (energia, disco cheio, o renomear por cima falha no
## Windows) deixa o último estado bom recuperável: `ler()` cai para o `.bak` quando o principal falta ou está inválido. O jogo não apaga
## arquivos: um .tmp de gravação que falhou fica até a próxima gravação o sobrescrever.
##
## PONTE OPCIONAL: `usar_backend_json` (Configurações, desligada por padrão) liga a gravação automática depois de cada escolha do Mensageiro
## (`registrar_escolha`). Aplicar o conteúdo do arquivo às métricas do jogo (`aplicar_ao_jogo`) é sempre uma chamada EXPLÍCITA: o arquivo
## nunca sobrescreve o progresso do jogador sozinho, e as métricas só mudam pelo GerenciadorEstado (a regra central, com os limites).

const VERSAO_ESQUEMA := 1
const NOME_ARQUIVO := "estado_jogo.json"
const CAMINHO := "user://nexus_os/estado_jogo.json"
const TAMANHO_MAX_BYTES := 1048576
const ID_MAX := 48
const STATUS_MAX := 32
const STATUS_INICIAL := "inicial"
const STATUS_OK := "ok"
const METRICA_MIN := 0.0
const METRICA_MAX := 100.0
const METRICAS: PackedStringArray = ["autonomia", "conformidade", "dependencia"]
const SUFIXO_TEMP := ".tmp"
const SUFIXO_BACKUP := ".bak"

## Onde o jogo lê e grava quando nenhum caminho é passado. Só os testes mudam isto (para não tocar no arquivo real do jogador); restaure depois.
static var caminho_ativo: String = CAMINHO


static func _caminho(caminho: String) -> String:
	return caminho_ativo if caminho == "" else caminho


# ------------------------------------------------------------------ validações pontuais (as mesmas regras do backend em C)
## 1 a 48 caracteres, letra minúscula e depois [a-z0-9_]. Texto vazio NÃO é um id válido (use "" só como "nenhuma escolha" no estado).
static func id_valido(id: Variant) -> bool:
	if typeof(id) != TYPE_STRING:
		return false
	var texto: String = id
	if texto.length() == 0 or texto.length() > ID_MAX:
		return false
	for i in texto.length():
		var c: int = texto.unicode_at(i)
		var minuscula: bool = c >= 97 and c <= 122
		var digito: bool = c >= 48 and c <= 57
		if i == 0 and not minuscula:
			return false
		if not (minuscula or digito or c == 95):
			return false
	return true


## 1 a 32 caracteres [a-z_].
static func status_valido(status: Variant) -> bool:
	if typeof(status) != TYPE_STRING:
		return false
	var texto: String = status
	if texto.length() == 0 or texto.length() > STATUS_MAX:
		return false
	for i in texto.length():
		var c: int = texto.unicode_at(i)
		if not ((c >= 97 and c <= 122) or c == 95):
			return false
	return true


## "YYYY-MM-DDTHH:MM:SSZ" com campos numericamente plausíveis (mesma regra do backend).
static func timestamp_valido(carimbo: Variant) -> bool:
	if typeof(carimbo) != TYPE_STRING:
		return false
	var t: String = carimbo
	if t.length() != 20:
		return false
	if t[4] != "-" or t[7] != "-" or t[10] != "T" or t[13] != ":" or t[16] != ":" or t[19] != "Z":
		return false
	for faixa in [[0, 4], [5, 2], [8, 2], [11, 2], [14, 2], [17, 2]]:
		var ini: int = faixa[0]
		for i in range(ini, ini + int(faixa[1])):
			var c: int = t.unicode_at(i)
			if c < 48 or c > 57:
				return false
	var mes: int = int(t.substr(5, 2))
	var dia: int = int(t.substr(8, 2))
	var hora: int = int(t.substr(11, 2))
	var minuto: int = int(t.substr(14, 2))
	var segundo: int = int(t.substr(17, 2))
	return mes >= 1 and mes <= 12 and dia >= 1 and dia <= 31 and hora <= 23 and minuto <= 59 and segundo <= 60


## Agora, em UTC, no formato do arquivo.
static func timestamp_agora() -> String:
	return Time.get_datetime_string_from_system(true) + "Z"


static func _numero_de_metrica(valor: Variant) -> bool:
	if typeof(valor) != TYPE_INT and typeof(valor) != TYPE_FLOAT:
		return false
	var v: float = float(valor)
	return not is_nan(v) and not is_inf(v) and v >= METRICA_MIN and v <= METRICA_MAX


# ------------------------------------------------------------------ montar, validar, serializar
## Monta um estado válido: métricas travadas em 0..100 (valor inválido vira o inicial da métrica), arredondadas a 2 casas como no backend.
## `metricas` pode trazer só algumas métricas; as que faltarem usam o valor inicial do jogo (Metricas.inicial).
static func criar(choice_id: String, status: String, metricas: Dictionary, is_placeholder: bool, carimbo: String = "") -> Dictionary:
	var saida_metricas: Dictionary = {}
	for nome in METRICAS:
		var bruto: Variant = metricas.get(nome, Metricas.inicial(nome))
		var valor: float = Metricas.inicial(nome)
		if typeof(bruto) == TYPE_INT or typeof(bruto) == TYPE_FLOAT:
			var f: float = float(bruto)
			if not is_nan(f) and not is_inf(f):
				valor = f
		saida_metricas[nome] = snappedf(clampf(valor, METRICA_MIN, METRICA_MAX), 0.01)
	return {
		"schema_version": VERSAO_ESQUEMA,
		"choice_id": choice_id,
		"status": status,
		"metrics": saida_metricas,
		"timestamp": carimbo if carimbo != "" else timestamp_agora(),
		"is_placeholder": is_placeholder,
	}


## Valida um estado já interpretado. Devolve {ok, erros: Array[String], estado: Dictionary}; `estado` só tem os campos conhecidos,
## na ordem do arquivo, e só é preenchido quando ok. Cada erro diz o campo e o motivo.
static func validar(dados: Variant) -> Dictionary:
	var erros: Array = []
	if not (dados is Dictionary):
		return {"ok": false, "erros": ["a raiz do JSON deve ser um objeto"], "estado": {}}
	var d: Dictionary = dados
	var versao: Variant = d.get("schema_version")
	if (typeof(versao) != TYPE_INT and typeof(versao) != TYPE_FLOAT) or float(versao) != float(VERSAO_ESQUEMA):
		erros.append("schema_version ausente ou diferente de %d" % VERSAO_ESQUEMA)
	var escolha: Variant = d.get("choice_id")
	if typeof(escolha) != TYPE_STRING:
		erros.append("choice_id ausente ou não textual")
	elif String(escolha) != "" and not id_valido(escolha):
		erros.append("choice_id inválido (1 a %d caracteres: letra minúscula e depois [a-z0-9_])" % ID_MAX)
	var situacao: Variant = d.get("status")
	if not status_valido(situacao):
		erros.append("status ausente ou inválido (1 a %d caracteres [a-z_])" % STATUS_MAX)
	var metricas: Variant = d.get("metrics")
	if not (metricas is Dictionary):
		erros.append("metrics ausente ou não é um objeto")
	else:
		for nome in METRICAS:
			if not _numero_de_metrica((metricas as Dictionary).get(nome)):
				erros.append("metrics.%s ausente, não numérica ou fora de 0..100" % nome)
	var carimbo: Variant = d.get("timestamp")
	if typeof(carimbo) != TYPE_STRING:
		erros.append("timestamp ausente ou não textual")
	elif String(carimbo) != "" and not timestamp_valido(carimbo):
		erros.append("timestamp inválido (esperado YYYY-MM-DDTHH:MM:SSZ)")
	var provisorio: Variant = d.get("is_placeholder")
	if typeof(provisorio) != TYPE_BOOL:
		erros.append("is_placeholder ausente ou não booleano")
	if not erros.is_empty():
		return {"ok": false, "erros": erros, "estado": {}}
	var m: Dictionary = metricas
	var estado: Dictionary = {
		"schema_version": VERSAO_ESQUEMA,
		"choice_id": String(escolha),
		"status": String(situacao),
		"metrics": {"autonomia": float(m["autonomia"]), "conformidade": float(m["conformidade"]), "dependencia": float(m["dependencia"])},
		"timestamp": String(carimbo),
		"is_placeholder": bool(provisorio),
	}
	return {"ok": true, "erros": [], "estado": estado}


## O texto do arquivo: JSON com tabulações, UTF-8 (a Godot grava texto em UTF-8), quebra de linha final e números inteiros sem ".0".
static func serializar(estado: Dictionary) -> String:
	var m: Dictionary = estado.get("metrics", {})
	var metricas: Dictionary = {}
	for nome in METRICAS:
		var v: float = float(m.get(nome, 0.0))
		if is_equal_approx(v, roundf(v)):
			metricas[nome] = int(v)
		else:
			metricas[nome] = v
	var ordenado: Dictionary = {
		"schema_version": int(estado.get("schema_version", VERSAO_ESQUEMA)),
		"choice_id": str(estado.get("choice_id", "")),
		"status": str(estado.get("status", STATUS_INICIAL)),
		"metrics": metricas,
		"timestamp": str(estado.get("timestamp", "")),
		"is_placeholder": bool(estado.get("is_placeholder", false)),
	}
	return JSON.stringify(ordenado, "\t", false) + "\n"   # sort_keys = false: a ordem do contrato (a mesma do backend em C), não a alfabética


## Interpreta o texto de um arquivo: tamanho, BOM, JSON e esquema. Devolve {ok, erro, estado}.
static func interpretar(texto: String) -> Dictionary:
	if texto.to_utf8_buffer().size() > TAMANHO_MAX_BYTES:
		return {"ok": false, "erro": "arquivo acima do limite de %d bytes" % TAMANHO_MAX_BYTES, "estado": {}}
	var limpo: String = texto.trim_prefix("﻿")
	var json := JSON.new()
	if json.parse(limpo) != OK:
		return {"ok": false, "erro": "json malformado (linha %d: %s)" % [json.get_error_line(), json.get_error_message()], "estado": {}}
	var r: Dictionary = validar(json.data)
	if not bool(r["ok"]):
		return {"ok": false, "erro": "; ".join(PackedStringArray(r["erros"])), "estado": {}}
	return {"ok": true, "erro": "", "estado": r["estado"]}


# ------------------------------------------------------------------ arquivo
## Lê e valida. Se o arquivo principal faltar ou estiver inválido e houver um `.bak` válido, usa o `.bak` (`origem: "backup"`).
## Devolve {ok, erro, estado, origem ("arquivo" | "backup" | "")}.
static func ler(caminho: String = "") -> Dictionary:
	var alvo: String = _caminho(caminho)
	var principal: Dictionary = _ler_um(alvo)
	if bool(principal["ok"]):
		principal["origem"] = "arquivo"
		return principal
	var reserva: Dictionary = _ler_um(alvo + SUFIXO_BACKUP)
	if bool(reserva["ok"]):
		reserva["origem"] = "backup"
		return reserva
	principal["origem"] = ""
	return principal


static func _ler_um(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		return {"ok": false, "erro": "arquivo não encontrado: %s" % caminho, "estado": {}}
	var arquivo := FileAccess.open(caminho, FileAccess.READ)
	if arquivo == null:
		return {"ok": false, "erro": "não foi possível abrir %s (erro %d)" % [caminho, FileAccess.get_open_error()], "estado": {}}
	if arquivo.get_length() > TAMANHO_MAX_BYTES:
		arquivo.close()
		return {"ok": false, "erro": "arquivo acima do limite de %d bytes" % TAMANHO_MAX_BYTES, "estado": {}}
	var texto: String = arquivo.get_as_text()
	arquivo.close()
	return interpretar(texto)


## O caminho pode receber o estado? Nunca res://; user:// sempre; outros caminhos absolutos só com `permitir_absoluto`.
static func caminho_gravavel(caminho: String, permitir_absoluto: bool = false) -> bool:
	if caminho.strip_edges() == "" or caminho.begins_with("res://"):
		return false
	if caminho.get_file() == "" or caminho.contains(".."):
		return false
	if caminho.begins_with("user://"):
		return true
	return permitir_absoluto and caminho.is_absolute_path()


## Grava de forma validada, em UTF-8 e resistente a falha parcial (ver o cabeçalho). Devolve {ok, erro}.
static func gravar(estado: Dictionary, destino: String = "", permitir_absoluto: bool = false) -> Dictionary:
	var caminho: String = _caminho(destino)
	if not caminho_gravavel(caminho, permitir_absoluto):
		return {"ok": false, "erro": "caminho recusado (res:// nunca; fora de user:// só em desenvolvimento): %s" % caminho}
	var r: Dictionary = validar(estado)
	if not bool(r["ok"]):
		return {"ok": false, "erro": "estado inválido: " + "; ".join(PackedStringArray(r["erros"]))}
	var texto: String = serializar(r["estado"])
	var pasta: String = caminho.get_base_dir()
	if not DirAccess.dir_exists_absolute(pasta):
		var criada: Error = DirAccess.make_dir_recursive_absolute(pasta)
		if criada != OK:
			return {"ok": false, "erro": "não foi possível criar a pasta %s (erro %d)" % [pasta, criada]}
	var temporario: String = caminho + SUFIXO_TEMP
	var arquivo := FileAccess.open(temporario, FileAccess.WRITE)
	if arquivo == null:
		return {"ok": false, "erro": "não foi possível criar %s (erro %d)" % [temporario, FileAccess.get_open_error()]}
	arquivo.store_string(texto)
	arquivo.flush()
	var erro_escrita: Error = arquivo.get_error()
	arquivo.close()
	if erro_escrita != OK or not _conferir_temporario(temporario, texto):
		return {"ok": false, "erro": "a escrita de %s não foi conferida; o arquivo anterior foi mantido" % temporario}
	# O jogo não apaga arquivos (regra do projeto): o .bak anterior é sobrescrito pelo renomear e o .tmp de uma gravação que falhou fica no
	# disco até a próxima gravação o sobrescrever (ninguém lê o .tmp).
	var reserva: String = caminho + SUFIXO_BACKUP
	var havia_anterior: bool = FileAccess.file_exists(caminho)
	if havia_anterior and DirAccess.rename_absolute(caminho, reserva) != OK:
		return {"ok": false, "erro": "não foi possível guardar o arquivo anterior em %s; nada foi alterado" % reserva}
	if DirAccess.rename_absolute(temporario, caminho) != OK:
		if havia_anterior:
			DirAccess.rename_absolute(reserva, caminho)
		return {"ok": false, "erro": "não foi possível colocar o novo estado em %s; o arquivo anterior foi restaurado" % caminho}
	return {"ok": true, "erro": ""}


static func _conferir_temporario(caminho: String, esperado: String) -> bool:
	var arquivo := FileAccess.open(caminho, FileAccess.READ)
	if arquivo == null:
		return false
	var lido: String = arquivo.get_as_text()
	arquivo.close()
	return lido == esperado


# ------------------------------------------------------------------ ponte com o jogo
## A ponte opcional está ligada? (Configurações: usar_backend_json; padrão desligada.)
static func ativo() -> bool:
	return bool(GerenciadorConfiguracoes.obter("usar_backend_json"))


## Estado do jogo agora, no formato do arquivo (métricas lidas do GerenciadorEstado, a única fonte delas).
static func estado_atual(choice_id: String, is_placeholder: bool, status: String = STATUS_OK) -> Dictionary:
	return criar(choice_id, status, GerenciadorEstado.copia_das_metricas(), is_placeholder)


## Chamado depois de cada escolha do Mensageiro. Com a ponte desligada não faz nada ({ok: false, motivo: "ponte_desligada"}); com ela ligada
## grava `estado_jogo.json`. Escolha de id fora do formato (não deve acontecer) não é gravada. Nunca derruba o jogo: devolve o resultado.
static func registrar_escolha(id_escolha: String, is_placeholder: bool, caminho: String = "") -> Dictionary:
	if not ativo():
		return {"ok": false, "erro": "", "motivo": "ponte_desligada"}
	if not id_valido(id_escolha):
		return {"ok": false, "erro": "id de escolha fora do formato: %s" % id_escolha, "motivo": "id_invalido"}
	var r: Dictionary = gravar(estado_atual(id_escolha, is_placeholder), caminho)
	if not bool(r["ok"]):
		push_warning("EstadoJogoBackend: %s" % str(r["erro"]))
	r["motivo"] = "gravado" if bool(r["ok"]) else "falha_ao_gravar"
	return r


## Aplica as métricas de um estado VÁLIDO às métricas do jogo, pela regra central (GerenciadorEstado.definir_metrica: limites e validação).
## É uma ação explícita: nada chama isto sozinho. Devolve {ok, erro, aplicadas: {nome: valor}}.
static func aplicar_ao_jogo(estado: Dictionary) -> Dictionary:
	var r: Dictionary = validar(estado)
	if not bool(r["ok"]):
		return {"ok": false, "erro": "estado inválido: " + "; ".join(PackedStringArray(r["erros"])), "aplicadas": {}}
	var aplicadas: Dictionary = {}
	var metricas: Dictionary = (r["estado"] as Dictionary)["metrics"]
	for nome in METRICAS:
		if GerenciadorEstado.definir_metrica(nome, metricas[nome], "backend_c"):
			aplicadas[nome] = GerenciadorEstado.obter_metrica(nome)
	return {"ok": aplicadas.size() == METRICAS.size(), "erro": "", "aplicadas": aplicadas}


## Lê o arquivo, valida e aplica às métricas do jogo. Devolve {ok, erro, origem, estado, aplicadas}. Ação explícita (ver o cabeçalho).
static func sincronizar_do_arquivo(caminho: String = "") -> Dictionary:
	var lido: Dictionary = ler(caminho)
	if not bool(lido["ok"]):
		return {"ok": false, "erro": lido["erro"], "origem": lido.get("origem", ""), "estado": {}, "aplicadas": {}}
	var aplicado: Dictionary = aplicar_ao_jogo(lido["estado"])
	return {"ok": bool(aplicado["ok"]), "erro": aplicado["erro"], "origem": lido["origem"], "estado": lido["estado"], "aplicadas": aplicado["aplicadas"]}
