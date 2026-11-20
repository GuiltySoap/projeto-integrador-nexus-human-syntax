class_name InstalacaoHumaxOS
extends RefCounted
## Núcleo técnico do registro de entrada do HumaxOS, SEM interface. A cena de boot (TelaBoot: BIOS -> registro -> saudação) só desenha e
## repassa; os testes chamam estas funções direto.
##
## Roteiro v2.0: o registro só captura NOME + PRONOME e valida (`validar_perfil`). Nenhuma permissão é mostrada nem concedida aqui:
## as cinco permissões começam todas desativadas e a Maya as pede, uma a uma, na Task 2 (cartões). A saudação do registro está em
## core/data/narrativa/instalacao_humaxos.json (a abertura do jogo, T1.1, é outra: "Bem-vindo(a) de volta, [NOME].").

const ARQUIVO := "res://core/data/narrativa/instalacao_humaxos.json"
const PLACEHOLDER_SAUDACAO := "[SAUDACAO_DA_MAYA]"
const MSG_NOME_VAZIO := "Digite um nome para continuar (ou use \"Usar nome padrão\")."
const MSG_NOME_INVALIDO := "O nome não pode ter { } [ ] < > \\ / | ` $ nem caracteres de controle."

static var _saudacao: String = ""
static var _carregado: bool = false


static func _carregar() -> void:
	_carregado = true
	_saudacao = ""
	if FileAccess.file_exists(ARQUIVO):
		var lido: Variant = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO))
		if lido is Dictionary and (lido as Dictionary).get("saudacao") is Dictionary:
			_saudacao = str(((lido as Dictionary)["saudacao"] as Dictionary).get("texto", ""))


## Valida o que o jogador digitou/escolheu. Devolve {ok, nome, pronome, motivo, mensagem}:
##   - `nome`: o nome seguro (limpo e limitado a 24 caracteres); `pronome`: o id canônico (desconhecido vira "neutro");
##   - ok = false para nome vazio ("vazio") ou com caracteres proibidos ("caracteres_invalidos": nada é alterado em silêncio);
##   - nome longo demais é cortado e continua ok (motivo "muito_longo").
static func validar_perfil(nome: Variant, pronome: Variant) -> Dictionary:
	var v: Dictionary = PerfilJogador.validar_nome(nome)
	var motivo := str(v["motivo"])
	var resultado: Dictionary = {"ok": true, "nome": str(v["nome"]), "pronome": PerfilJogador.validar_pronome(pronome), "motivo": motivo, "mensagem": ""}
	if motivo == "vazio":
		resultado["ok"] = false
		resultado["mensagem"] = MSG_NOME_VAZIO
	elif motivo == "caracteres_invalidos":
		resultado["ok"] = false
		resultado["mensagem"] = MSG_NOME_INVALIDO
	return resultado


## Opções do seletor de pronome, na ordem: [{id, rotulo}].
static func opcoes_de_pronome() -> Array:
	var saida: Array = []
	for id_pronome in PerfilJogador.ids_de_pronomes():
		saida.append({"id": str(id_pronome), "rotulo": str(PerfilJogador.dados_do_pronome(id_pronome)["rotulo"])})
	return saida


## Fala depois do registro, com as tags do perfil resolvidas. Texto vazio vira [SAUDACAO_DA_MAYA].
static func texto_saudacao(nome: Variant, pronome: Variant) -> String:
	if not _carregado:
		_carregar()
	var texto := _saudacao if _saudacao.strip_edges() != "" else PLACEHOLDER_SAUDACAO
	return PerfilJogador.processar_texto(texto, PerfilJogador.contexto(nome, pronome))
