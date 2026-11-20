class_name PerfilJogador
extends RefCounted
## Perfil do jogador (nome e pronome) e as tags dinâmicas dos textos/diálogos JSON.
##
## TAGS (maiúsculas): {NOME_JOGADOR}, {PRONOME_JOGADOR} (obrigatória), {ARTIGO_JOGADOR}, {PRONOME_POSSESSIVO}.
## As tags legadas em minúsculas ({nome}, {dia}, {seguranca}, {corrupcao}) continuam funcionando: o GerenciadorEstado as passa no
## mesmo contexto, então tudo é resolvido em UMA passada (um nome digitado como "{dia}" nunca vira outra tag).
## Regras de `processar_texto`:
##   - só mexe no que está entre chaves; o resto do texto (acentos, emoji, BBCode, quebras de linha, `{` sem fechar) passa intacto;
##   - tag conhecida sem valor no contexto usa o padrão seguro (nome "Usuário", pronome "você");
##   - tag MAIÚSCULA desconhecida (ex.: {NOME_DO_RAFAEL}) fica literal no texto e é anotada em `desconhecidas` (nunca quebra a tela);
##   - IDs e chaves internas não são texto de jogo e nunca devem passar por aqui.
## O nome digitado é validado em `validar_nome` (sem chaves, colchetes, barras nem caracteres de controle, de 1 a 24 caracteres).

const NOME_PADRAO := "Usuário"
const PRONOME_PADRAO := "neutro"
const TAMANHO_MAX_NOME := 24
const TAMANHO_MAX_TAG := 40
const PROIBIDOS := "{}[]<>\\/|`$"
const TAGS_DO_PERFIL: PackedStringArray = ["NOME_JOGADOR", "PRONOME_JOGADOR", "ARTIGO_JOGADOR", "PRONOME_POSSESSIVO"]
## Dados extras da recepção (todos opcionais, locais): idade entre 1 e `IDADE_MAXIMA` (0 = não informada), e-mail simples, gênero de uma lista.
const IDADE_MAXIMA := 120
const TAMANHO_MAX_EMAIL := 80
const TAMANHO_MAX_GENERO := 24
const GENERO_NAO_INFORMADO := ""


## Identificadores dos pronomes disponíveis, na ordem em que aparecem no seletor.
static func ids_de_pronomes() -> PackedStringArray:
	var ids := PackedStringArray()
	for id_pronome in Regras.secao("pronomes"):
		ids.append(str(id_pronome))
	if ids.is_empty():
		ids.append(PRONOME_PADRAO)
	return ids


## Id canônico do pronome ("Ele" -> "ele"); o padrão seguro quando vier vazio, desconhecido ou de tipo errado.
static func validar_pronome(entrada: Variant) -> String:
	if typeof(entrada) != TYPE_STRING and typeof(entrada) != TYPE_STRING_NAME:
		return PRONOME_PADRAO
	var id_pronome := str(entrada).strip_edges().to_lower()
	return id_pronome if Regras.secao("pronomes").has(id_pronome) else PRONOME_PADRAO


## Dados de um pronome: {id, rotulo, pronome, artigo, possessivo}. Sempre completo (cai no padrão).
static func dados_do_pronome(entrada: Variant) -> Dictionary:
	var id_pronome := validar_pronome(entrada)
	var tabela: Dictionary = Regras.secao("pronomes")
	var d: Variant = tabela.get(id_pronome, {})
	var base: Dictionary = d if d is Dictionary else {}
	return {
		"id": id_pronome,
		"rotulo": str(base.get("rotulo", id_pronome)),
		"pronome": str(base.get("pronome", "você")),
		"artigo": str(base.get("artigo", "")),
		"possessivo": str(base.get("possessivo", "seu(sua)")),
	}


## Valida o nome digitado. Devolve {ok, nome, motivo}: `nome` é sempre uma versão segura (limpa e limitada, ou o padrão);
## `ok` só é true se NADA precisou ser alterado. motivo: "" | "vazio" | "muito_longo" | "caracteres_invalidos".
static func validar_nome(entrada: Variant) -> Dictionary:
	if typeof(entrada) != TYPE_STRING and typeof(entrada) != TYPE_STRING_NAME:
		return {"ok": false, "nome": NOME_PADRAO, "motivo": "vazio"}
	var bruto := str(entrada)
	var limpo := ""
	var invalido := false
	for i in bruto.length():
		var c: String = bruto[i]
		var codigo := c.unicode_at(0)
		if codigo < 32 or codigo == 127:
			if c == "\t":
				limpo += " "
			else:
				invalido = true
			continue
		if PROIBIDOS.contains(c):
			invalido = true
			continue
		limpo += c
	var colapsado := ""
	var anterior_espaco := false
	for i in limpo.length():
		var c2: String = limpo[i]
		if c2 == " ":
			if anterior_espaco:
				continue
			anterior_espaco = true
		else:
			anterior_espaco = false
		colapsado += c2
	colapsado = colapsado.strip_edges()
	if colapsado == "":
		return {"ok": false, "nome": NOME_PADRAO, "motivo": "caracteres_invalidos" if invalido else "vazio"}
	if colapsado.length() > TAMANHO_MAX_NOME:
		return {"ok": false, "nome": colapsado.substr(0, TAMANHO_MAX_NOME).strip_edges(), "motivo": "muito_longo"}
	return {"ok": not invalido and colapsado == bruto, "nome": colapsado, "motivo": "caracteres_invalidos" if invalido else ""}


## Atalho: o nome seguro (padrão "Usuário" quando não houver nada aproveitável).
static func nome_seguro(entrada: Variant) -> String:
	return str(validar_nome(entrada)["nome"])


## Contexto de tags para `processar_texto`: as quatro tags do perfil (nas duas grafias, maiúscula e a chave curta).
static func contexto(nome: Variant, pronome: Variant) -> Dictionary:
	var dados := dados_do_pronome(pronome)
	var nome_ok := nome_seguro(nome)
	return {
		"NOME_JOGADOR": nome_ok, "PRONOME_JOGADOR": str(dados["pronome"]), "ARTIGO_JOGADOR": str(dados["artigo"]),
		"PRONOME_POSSESSIVO": str(dados["possessivo"]), "nome": nome_ok,
	}


## Substitui as tags de `texto` usando `contexto` (chave -> valor), numa única passada. `desconhecidas` (opcional) recebe as
## tags MAIÚSCULAS sem valor, que ficam literais no resultado.
static func processar_texto(texto: String, contexto_tags: Dictionary, desconhecidas: Array = []) -> String:
	if texto == "" or not texto.contains("{"):
		return texto
	var saida := ""
	var inicio := 0
	var tamanho := texto.length()
	while inicio < tamanho:
		var abre := texto.find("{", inicio)
		if abre < 0:
			saida += texto.substr(inicio)
			break
		saida += texto.substr(inicio, abre - inicio)
		var fecha := texto.find("}", abre + 1)
		if fecha < 0:
			saida += texto.substr(abre)
			break
		var chave := texto.substr(abre + 1, fecha - abre - 1)
		if chave.length() > 0 and chave.length() <= TAMANHO_MAX_TAG and _eh_nome_de_tag(chave):
			if contexto_tags.has(chave):
				saida += str(contexto_tags[chave])
				inicio = fecha + 1
				continue
			if TAGS_DO_PERFIL.has(chave):
				saida += _padrao_da_tag(chave)
				inicio = fecha + 1
				continue
			var parece_tag_do_jogo := chave == chave.to_upper() and (chave.contains("_") or chave.length() > 2)
			if parece_tag_do_jogo and not desconhecidas.has(chave):
				desconhecidas.append(chave)
		# Não era uma tag substituível: a chave fica no texto e a leitura continua logo depois dela.
		saida += texto.substr(abre, 1)
		inicio = abre + 1
	return saida


## Quais tags do perfil aparecem em `texto` (para testes e diagnóstico).
static func tags_presentes(texto: String) -> PackedStringArray:
	var achadas := PackedStringArray()
	for tag in TAGS_DO_PERFIL:
		if texto.contains("{" + tag + "}"):
			achadas.append(tag)
	return achadas


static func _eh_nome_de_tag(chave: String) -> bool:
	for i in chave.length():
		var codigo := chave.unicode_at(i)
		var letra := (codigo >= 65 and codigo <= 90) or (codigo >= 97 and codigo <= 122)
		if not (letra or codigo == 95 or (codigo >= 48 and codigo <= 57)):
			return false
	return true


static func _padrao_da_tag(chave: String) -> String:
	match chave:
		"NOME_JOGADOR":
			return NOME_PADRAO
		"PRONOME_JOGADOR":
			return "você"
		"ARTIGO_JOGADOR":
			return "o(a)"
		"PRONOME_POSSESSIVO":
			return "seu(sua)"
	return ""


# ------------------------------------------------------------------ dados extras da recepção (§9.2)
## Identificadores de gênero disponíveis (regras.json -> generos), na ordem do seletor. O primeiro é sempre "não informar" ("").
static func ids_de_generos() -> PackedStringArray:
	var ids := PackedStringArray([GENERO_NAO_INFORMADO])
	for id_genero in Regras.secao("generos"):
		if str(id_genero) != "" and str(id_genero) != "comentario":
			ids.append(str(id_genero))
	return ids


static func rotulo_de_genero(id_genero: String) -> String:
	if id_genero == GENERO_NAO_INFORMADO:
		return "Prefiro não informar"
	var rotulo: Variant = Regras.secao("generos").get(id_genero, id_genero)
	return str(rotulo)


## Gênero opcional: devolve {ok, valor, motivo}. Vazio = não informado (ok). Fora da lista: recusado, valor "".
static func validar_genero(entrada: Variant) -> Dictionary:
	if typeof(entrada) != TYPE_STRING and typeof(entrada) != TYPE_STRING_NAME:
		return {"ok": entrada == null, "valor": GENERO_NAO_INFORMADO, "motivo": "" if entrada == null else "tipo_invalido"}
	var id_genero := str(entrada).strip_edges().to_lower()
	if id_genero == GENERO_NAO_INFORMADO:
		return {"ok": true, "valor": GENERO_NAO_INFORMADO, "motivo": ""}
	if ids_de_generos().has(id_genero):
		return {"ok": true, "valor": id_genero, "motivo": ""}
	return {"ok": false, "valor": GENERO_NAO_INFORMADO, "motivo": "genero_desconhecido"}


## Idade opcional: texto ou número. Vazio = não informada (0, ok). Devolve {ok, valor, motivo}: motivo "" | "nao_e_numero" | "fora_do_intervalo".
static func validar_idade(entrada: Variant) -> Dictionary:
	if entrada == null:
		return {"ok": true, "valor": 0, "motivo": ""}
	var texto := str(entrada).strip_edges()
	if texto == "":
		return {"ok": true, "valor": 0, "motivo": ""}
	if typeof(entrada) == TYPE_FLOAT:
		# O JSON do salvamento devolve todo número como float (45 vira 45.0): um inteiro disfarçado vale; fracionário, NaN e infinito não.
		var decimal: float = float(entrada)
		if is_nan(decimal) or is_inf(decimal) or decimal != floorf(decimal):
			return {"ok": false, "valor": 0, "motivo": "nao_e_numero"}
		texto = str(int(decimal))
	if not texto.is_valid_int():
		return {"ok": false, "valor": 0, "motivo": "nao_e_numero"}
	var idade := int(texto)
	if idade < 1 or idade > IDADE_MAXIMA:
		return {"ok": false, "valor": 0, "motivo": "fora_do_intervalo"}
	return {"ok": true, "valor": idade, "motivo": ""}


## E-mail opcional (verificação simples e local: nada é enviado). Vazio = não informado (ok). motivo: "" | "formato_invalido" | "muito_longo" | "caracteres_invalidos".
static func validar_email(entrada: Variant) -> Dictionary:
	if entrada == null:
		return {"ok": true, "valor": "", "motivo": ""}
	if typeof(entrada) != TYPE_STRING and typeof(entrada) != TYPE_STRING_NAME:
		return {"ok": false, "valor": "", "motivo": "formato_invalido"}
	var email := str(entrada).strip_edges()
	if email == "":
		return {"ok": true, "valor": "", "motivo": ""}
	if email.length() > TAMANHO_MAX_EMAIL:
		return {"ok": false, "valor": "", "motivo": "muito_longo"}
	for i in email.length():
		var c: String = email[i]
		if c.unicode_at(0) <= 32 or c.unicode_at(0) == 127 or PROIBIDOS.contains(c) or c == "," or c == ";" or c == "\"" or c == "'":
			return {"ok": false, "valor": "", "motivo": "caracteres_invalidos"}
	var partes := email.split("@")
	if partes.size() != 2 or partes[0] == "" or partes[1] == "":
		return {"ok": false, "valor": "", "motivo": "formato_invalido"}
	var dominio: String = partes[1]
	var rotulos := dominio.split(".")
	if rotulos.size() < 2 or dominio.begins_with(".") or dominio.ends_with(".") or dominio.contains(".."):
		return {"ok": false, "valor": "", "motivo": "formato_invalido"}
	if (rotulos[rotulos.size() - 1] as String).length() < 2:
		return {"ok": false, "valor": "", "motivo": "formato_invalido"}
	return {"ok": true, "valor": email, "motivo": ""}


## Valida os três campos de uma vez. Devolve {ok, extra: {genero, idade, email} (sempre saneado), erros: {campo: motivo}}.
static func validar_extra(genero: Variant, idade: Variant, email: Variant) -> Dictionary:
	var g := validar_genero(genero)
	var i := validar_idade(idade)
	var e := validar_email(email)
	var erros := {}
	if not bool(g["ok"]):
		erros["genero"] = str(g["motivo"])
	if not bool(i["ok"]):
		erros["idade"] = str(i["motivo"])
	if not bool(e["ok"]):
		erros["email"] = str(e["motivo"])
	return {"ok": erros.is_empty(), "extra": {"genero": g["valor"], "idade": i["valor"], "email": e["valor"]}, "erros": erros}


## Dados extras vindos de um salvamento (ou de qualquer lugar): sempre um dicionário saneado; campo ausente ou inválido vira "não informado".
static func extra_seguro(bruto: Variant) -> Dictionary:
	var origem: Dictionary = bruto if bruto is Dictionary else {}
	return validar_extra(origem.get("genero"), origem.get("idade"), origem.get("email"))["extra"]


## Mensagem para o jogador de um erro de validação dos dados extras: `campo` = "genero" | "idade" | "email", `motivo` = o que a função de validação devolveu.
static func mensagem_de_erro(campo: String, motivo: String) -> String:
	match campo:
		"idade":
			if motivo == "fora_do_intervalo":
				return "A idade precisa estar entre 1 e %d." % IDADE_MAXIMA
			return "A idade precisa ser um número inteiro."
		"email":
			match motivo:
				"muito_longo":
					return "O e-mail passa de %d caracteres." % TAMANHO_MAX_EMAIL
				"caracteres_invalidos":
					return "O e-mail tem caracteres que não são aceitos."
			return "Digite um e-mail no formato nome@dominio.com (ou deixe em branco)."
		"genero":
			return "Escolha uma das opções da lista (ou deixe como está)."
	return "Dado inválido."
