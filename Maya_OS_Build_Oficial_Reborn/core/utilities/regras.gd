class_name Regras
extends RefCounted
## Leitor das regras técnicas do jogo (core/data/regras.json): limites das métricas AUT/CON/DEP, fórmula do perfil final,
## pronomes, custo da ajuda da Maya, parâmetros dos efeitos de interface e do falso boot.
##
## Funções puras e sem autoloads (pode ser usada por qualquer script e pelos testes). O arquivo é lido uma única vez e
## MESCLADO sobre `PADRAO`: uma chave ausente, de tipo errado ou um JSON ilegível nunca derruba o jogo, só volta ao valor padrão
## abaixo ("valores ausentes" da fórmula). Os testes podem apontar para outro arquivo com `recarregar(caminho)`.

const ARQUIVO := "res://core/data/regras.json"

## Valores de segurança: o jogo funciona só com estes, mesmo sem regras.json.
const PADRAO: Dictionary = {
	"metricas": {
		"autonomia": {"sigla": "AUT", "nome": "Autonomia", "inicial": 0.0, "minimo": 0.0, "maximo": 100.0},
		"conformidade": {"sigla": "CON", "nome": "Conformidade", "inicial": 50.0, "minimo": 0.0, "maximo": 100.0},
		"dependencia": {"sigla": "DEP", "nome": "Dependência", "inicial": 50.0, "minimo": 0.0, "maximo": 100.0},
	},
	"limiares": {"dependencia_resistencia": 60.0},
	"perfil_final": {
		"limiar_minimo": 50.0,
		"epsilon": 0.001,
		"ordem_avaliacao": ["autonomo", "conformado", "dependente"],
		"perfis": {
			"autonomo": {"termos": [["autonomia", 1, 0.5], ["dependencia", -1, 0.3], ["conformidade", -1, 0.2]]},
			"conformado": {"termos": [["conformidade", 1, 0.5], ["autonomia", -1, 0.3], ["dependencia", 1, 0.2]]},
			"dependente": {"termos": [["dependencia", 1, 0.6], ["autonomia", -1, 0.2], ["conformidade", 1, 0.2]]},
		},
	},
	"pronomes": {
		"neutro": {"rotulo": "Neutro (você)", "pronome": "você", "artigo": "o(a)", "possessivo": "seu(sua)"},
		"ele": {"rotulo": "Ele/dele", "pronome": "ele", "artigo": "o", "possessivo": "dele"},
		"ela": {"rotulo": "Ela/dela", "pronome": "ela", "artigo": "a", "possessivo": "dela"},
		"elu": {"rotulo": "Elu/delu", "pronome": "elu", "artigo": "o(a)", "possessivo": "delu"},
	},
	"ajuda": {"id": "dica_placeholder", "texto": "[DICA_NARRATIVA_PENDENTE]", "custo_dependencia": 2.0, "desbloqueia_no_atual": true, "is_placeholder": true, "moldura_sugestiva": "Talvez valha a pena: %s", "placeholder_contextual": "[PLACEHOLDER_DICA_CONTEXTUAL]"},
	"padroes_escuros": {"duracao_max_s": 12.0, "tentativas_max": 3, "intensidade_conforto": 0.35, "deslocamentos": [[0, 0], [0, 40], [0, -24], [0, 24]]},
	"glitch": {"intensidade": 0.6, "duracao": 0.7},
	"falso_boot": {"duracao_max_s": 45.0, "apps_bloqueados": ["email", "messenger"], "apps_mantidos": ["terminal", "task_manager"]},
	"navegador": {"carregamento_s": 0.12, "max_abas": 6},
	"vfs": {"pastas_acessiveis_desde_o_inicio": true},
	"instalacao": {"max_pacotes_por_comando": 5},
	"dialogo": {"id_aleatoria": "choice_random", "texto_aleatoria": "Deixar o sistema escolher", "max_narrativas": 3, "flags_decisao_propria": ["aceitou_assimilacao", "recusou_assimilacao"], "texto_decisao_propria": "Esta decisão precisa ser sua: o sistema não escolhe por você.", "descricao_aleatoria": "O sistema escolhe uma das respostas disponíveis por você.", "confirmacoes": {"aceitou_assimilacao": {"titulo": "CONFIRMAÇÃO DE SINCRONIZAÇÃO", "texto": "A proposta requer sincronização integral com o núcleo da Maya. Ao confirmar, o controle administrativo será transferido permanentemente para a inteligência central e a sessão atual será encerrada. Deseja prosseguir?", "ok": "Confirmar sincronização", "cancelar": "Voltar"}}},
	"progressao": {
		"atraso_base_s": 18.0, "atraso_minimo_s": 3.0, "atraso_maximo_s": 60.0, "dependencia_acelera": 0.6, "autonomia_retarda": 0.5,
		"limite_dependencia_aceleracao": 60.0, "limite_autonomia_retardo": 60.0,
	},
	"autonomia_acoes": {
		"limite_por_acao": 3,
		"acoes": {
			"revogar_permissao": {"deltas": {}, "recusa": true, "tentativa": true},
			"investigar_arquivo": {"deltas": {"autonomia": 1, "dependencia": -1}, "tentativa": true},
			"usar_terminal": {"deltas": {"autonomia": 1}, "tentativa": true},
			"instalar_manual": {"deltas": {"autonomia": 2, "dependencia": -2}, "tentativa": true},
			"questionar_maya": {"deltas": {"autonomia": 1}, "recusa": true, "tentativa": true},
			"aceitar_organizacao": {"deltas": {"dependencia": 8, "conformidade": 3}},
			"recusar_organizacao": {"deltas": {"autonomia": 5, "dependencia": -3}, "recusa": true, "tentativa": true},
		},
	},
	"efeitos_terror": {"dependencia_minima": 70.0, "exige_recusa": true, "exige_tentativa_de_autonomia": true, "permitido_no_modo_conforto": false},
	"generos": {"mulher": "Mulher", "homem": "Homem", "nao_binario": "Pessoa não binária", "outro": "Outro"},
	"organizacao": {"duracao_max_s": 12.0, "intervalo_s": 0.45, "apps_minimos": ["terminal", "settings"], "titulo_pedido": "A Maya pede uma permissão", "texto_pedido": "Posso organizar a sua área de trabalho? Eu instalo e arrumo os aplicativos básicos do HumaxOS, um por um, e você pode mudar isso depois em Configurações > Privacidade. Se preferir recusar, a área de trabalho começa mínima (Terminal, Menu Iniciar, Configurações e Lixeira) e você instala o resto pelo Terminal.", "rotulo_aceitar": "Aceitar", "rotulo_recusar": "Recusar", "rotulo_pular": "Pular ▶", "aviso_bloqueio": "Organizando a área de trabalho… (Esc ou Pular para mostrar tudo agora)"},
	"censura": {
		"palavras": ["[TERMO_CENSURADO_1]", "[TERMO_CENSURADO_2]"], "marca": "▓▓▓▓", "flag_ativa": "censura_ativa", "flag_rede": "rede_indisponivel",
		"max_bloqueios": 2, "mostrar_indicador_oculto": true,
	},
}

static var _dados: Dictionary = {}
static var _carregado: bool = false
## Motivo da última falha ao ler o arquivo ("" quando leu bem ou quando ainda não leu).
static var ultimo_erro: String = ""


## Todas as regras (padrão + arquivo). Lê o arquivo na primeira chamada.
static func dados() -> Dictionary:
	if not _carregado:
		recarregar(ARQUIVO)
	return _dados


## Lê `caminho` e mescla sobre PADRAO. Devolve false (e mantém só o padrão) se o arquivo faltar ou for inválido.
static func recarregar(caminho: String = ARQUIVO) -> bool:
	_carregado = true
	_dados = PADRAO.duplicate(true)
	ultimo_erro = ""
	if not FileAccess.file_exists(caminho):
		ultimo_erro = "arquivo ausente: %s" % caminho
		return false
	var analisador := JSON.new()
	if analisador.parse(FileAccess.get_file_as_string(caminho)) != OK:
		ultimo_erro = "JSON inválido: %s" % caminho
		return false
	var bruto: Variant = analisador.data
	if not (bruto is Dictionary):
		ultimo_erro = "a raiz de %s não é um objeto" % caminho
		return false
	_mesclar(_dados, bruto as Dictionary)
	return true


## Seção (ex.: "ajuda"). Sempre devolve um dicionário (vazio se a seção não existir).
static func secao(nome: String) -> Dictionary:
	var s: Variant = dados().get(nome, {})
	return s if s is Dictionary else {}


## Valor numérico de um caminho "secao.chave" (ex.: "ajuda.custo_dependencia"). `padrao` se não existir ou não for número.
static func numero(caminho: String, padrao: float = 0.0) -> float:
	var v: Variant = valor(caminho)
	if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
		return float(v)
	return padrao


static func inteiro(caminho: String, padrao: int = 0) -> int:
	return int(numero(caminho, float(padrao)))


static func texto(caminho: String, padrao: String = "") -> String:
	var v: Variant = valor(caminho)
	return str(v) if typeof(v) == TYPE_STRING else padrao


static func booleano(caminho: String, padrao: bool = false) -> bool:
	var v: Variant = valor(caminho)
	return bool(v) if typeof(v) == TYPE_BOOL else padrao


## Valor cru de "a.b.c" (null se algum nível não existir).
static func valor(caminho: String) -> Variant:
	var atual: Variant = dados()
	for parte in caminho.split("."):
		if not (atual is Dictionary) or not (atual as Dictionary).has(parte):
			return null
		atual = (atual as Dictionary)[parte]
	return atual


## Mescla `extra` em `base` SÓ onde o tipo do valor combina com o do padrão (número com número, texto com texto...). Dicionários
## são mesclados recursivamente; uma chave desconhecida é aceita só dentro de seções que aceitam novas chaves (perfis, pronomes).
static func _mesclar(base: Dictionary, extra: Dictionary) -> void:
	for chave in extra:
		var novo: Variant = extra[chave]
		if not base.has(chave):
			if typeof(novo) != TYPE_STRING or str(chave) != "comentario":
				base[chave] = novo
			continue
		var atual: Variant = base[chave]
		if atual is Dictionary and novo is Dictionary:
			_mesclar(atual as Dictionary, novo as Dictionary)
		elif _mesmo_tipo(atual, novo):
			base[chave] = novo


static func _mesmo_tipo(a: Variant, b: Variant) -> bool:
	var numero_a := typeof(a) == TYPE_INT or typeof(a) == TYPE_FLOAT
	var numero_b := typeof(b) == TYPE_INT or typeof(b) == TYPE_FLOAT
	if numero_a and numero_b:
		return true
	return typeof(a) == typeof(b)
