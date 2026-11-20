class_name Marca
extends RefCounted
## Marca visual do jogo (§22): onde moram os logos oficiais, como achá-los e o que mostrar quando um deles faltar.
## É o ÚNICO lugar que conhece os caminhos dos logos: as cenas pedem a marca por id (`LogoMarca`, no Menu Principal, na barra de tarefas,
## no boot...) e recebem a imagem ou, sem imagem, nada: cada tela já tem o NOME da marca em texto ("Maya Human Syntax", "◆ HumaxOS", "MAYA"),
## então um arquivo ausente, renomeado ou inválido nunca deixa a tela vazia nem derruba o jogo (o mesmo contrato das mídias opcionais).
##
## Logos (identificadores internos NÃO mudam por causa da marca: `logo_maya_neon.png`, `mayaos_intro_logo.png`, `TemaNexus`... ficam):
##   - MAYA_MARCA    o "M" neon da Maya, PNG RGBA (transparência de verdade; sem fundo): Menu Principal e ícone do jogo.
##   - MAYA_COMPLETA a logo completa "MAYA / HUMAN SYNTAX", PNG RGB sobre fundo preto (sem transparência): Splash Screen e Créditos.
##   - ICONE_JOGO    o ícone do jogo (janela, barra de tarefas do Windows e projeto): o "M" neon sobre um quadrado escuro de cantos arredondados,
##                   PNG 256x256 (o fundo sólido o torna legível em qualquer tema do sistema; os cantos são transparentes).
##   - HUMAXOS       a logo do sistema operacional. O arquivo oficial AINDA NÃO FOI FORNECIDO: enquanto ele não existir, o HumaxOS aparece só
##                   como texto. Para ativar, coloque o arquivo em um dos caminhos de `REGISTRO[HUMAXOS].caminhos` e abra o projeto no editor
##                   (a importação cria o `.import`); nenhuma cena nem script precisa mudar.

const MAYA_MARCA := "maya_marca"
const MAYA_COMPLETA := "maya_completa"
const HUMAXOS := "humaxos"
const ICONE_JOGO := "icone_jogo"

## Tamanho mínimo aceito para um logo (abaixo disso o arquivo é tratado como inválido: provável ícone de 16 px ou imagem quebrada).
const LADO_MINIMO := 32
## Tolerância, em fração, para dizer que a proporção do arquivo é a de referência (evita logo esticado por troca de arquivo).
const PROPORCAO_MAX := 4.0

## Registro: caminhos candidatos (o primeiro que existir vence), nomes e o que o arquivo precisa ter.
##   "nome"          texto alternativo (dica de ferramenta) e texto de reserva
##   "transparente"  o arquivo DEVE ter canal alfa de verdade (sem retângulo de fundo)
##   "oficial"       arte oficial fornecida pelo usuário
const REGISTRO := {
	MAYA_MARCA: {
		"caminhos": ["res://shared/assets/textures/logo_maya_neon.png"],
		"nome": "Maya",
		"transparente": true,
		"oficial": true,
	},
	MAYA_COMPLETA: {
		"caminhos": ["res://features/splash_screen/assets/mayaos_intro_logo.png"],
		"nome": "Maya Human Syntax",
		"transparente": false,
		"oficial": true,
	},
	ICONE_JOGO: {
		"caminhos": ["res://shared/assets/icons/icone_maya.png"],
		"nome": "Maya Human Syntax",
		"transparente": true,
		"oficial": true,
	},
	HUMAXOS: {
		"caminhos": ["res://shared/assets/branding/humaxos_logo.png", "res://shared/assets/branding/humaxos_logo.svg", "res://shared/assets/branding/humaxos_logo.webp"],
		"nome": "HumaxOS",
		"transparente": true,
		"oficial": true,
	},
}


static func ids() -> PackedStringArray:
	return PackedStringArray(REGISTRO.keys())


static func conhecida(id: String) -> bool:
	return REGISTRO.has(id)


## Nome da marca para dica de ferramenta e texto alternativo ("" para um id desconhecido).
static func nome(id: String) -> String:
	return str((REGISTRO[id] as Dictionary).get("nome", "")) if REGISTRO.has(id) else ""


static func caminhos(id: String) -> PackedStringArray:
	var saida := PackedStringArray()
	if not REGISTRO.has(id):
		return saida
	for c in (REGISTRO[id] as Dictionary)["caminhos"]:
		saida.append(str(c))
	return saida


## O primeiro caminho candidato que existe como recurso importado ("" se nenhum).
static func caminho_existente(id: String) -> String:
	for c in caminhos(id):
		if ResourceLoader.exists(c):
			return c
	return ""


static func existe(id: String) -> bool:
	return caminho_existente(id) != ""


## A textura do logo, ou null (arquivo ausente, não importado ou que não é imagem). Nunca registra erro: quem chama decide o fallback.
static func carregar(id: String) -> Texture2D:
	var caminho := caminho_existente(id)
	if caminho == "":
		return null
	return load(caminho) as Texture2D


## Tamanho do logo para uma altura desejada, mantendo a proporção do arquivo. Função pura (testável sem imagem): com `proporcao` <= 0 devolve
## um quadrado, que é a proporção da maioria dos logos do jogo.
static func tamanho_para_altura(altura: float, proporcao: float) -> Vector2:
	var h := maxf(altura, 0.0)
	var p := proporcao if proporcao > 0.0 else 1.0
	return Vector2(h * p, h)


## A proporção (largura/altura) é razoável para um logo? (Rejeita faixas finíssimas, que viram um risco na tela.)
static func proporcao_valida(proporcao: float) -> bool:
	return proporcao > 0.0 and proporcao <= PROPORCAO_MAX and proporcao >= 1.0 / PROPORCAO_MAX


## Confere um logo: existência, tamanho, proporção e transparência. Devolve {ok, existe, caminho, largura, altura, proporcao,
## transparencia ("real" | "opaca" | "nao_verificada"), erros: Array}. A transparência é lida do ARQUIVO-FONTE (precisa estar no disco,
## o que só vale no editor e nos testes: num build exportado só existe o recurso importado, e aí fica "nao_verificada").
## Um id sem arquivo NÃO é erro por si só para quem tem fallback: `ok` é falso e `existe` também; os testes decidem o que exigir.
static func validar(id: String) -> Dictionary:
	var r := {"ok": false, "existe": false, "caminho": "", "largura": 0, "altura": 0, "proporcao": 0.0, "transparencia": "nao_verificada", "erros": []}
	if not REGISTRO.has(id):
		(r["erros"] as Array).append("marca desconhecida: %s" % id)
		return r
	var caminho := caminho_existente(id)
	if caminho == "":
		(r["erros"] as Array).append("arquivo do logo ausente (%s): o jogo usa o nome em texto" % ", ".join(caminhos(id)))
		return r
	r["existe"] = true
	r["caminho"] = caminho
	var textura := load(caminho) as Texture2D
	if textura == null:
		(r["erros"] as Array).append("o arquivo existe mas não é uma imagem importável: %s" % caminho)
		return r
	r["largura"] = textura.get_width()
	r["altura"] = textura.get_height()
	if int(r["largura"]) < LADO_MINIMO or int(r["altura"]) < LADO_MINIMO:
		(r["erros"] as Array).append("logo pequeno demais (%dx%d, mínimo %d)" % [int(r["largura"]), int(r["altura"]), LADO_MINIMO])
	else:
		r["proporcao"] = float(r["largura"]) / float(r["altura"])
		if not proporcao_valida(float(r["proporcao"])):
			(r["erros"] as Array).append("proporção fora do razoável: %.2f" % float(r["proporcao"]))
	r["transparencia"] = _transparencia_do_arquivo(caminho)
	var exige: bool = bool((REGISTRO[id] as Dictionary).get("transparente", false))
	if exige and r["transparencia"] == "opaca":
		(r["erros"] as Array).append("o logo deveria ter transparência real (fundo recortado), mas o arquivo é opaco")
	r["ok"] = (r["erros"] as Array).is_empty()
	return r


## "real": o arquivo tem canal alfa e os quatro cantos são transparentes; "opaca": sem alfa ou cantos opacos; "nao_verificada": arquivo-fonte
## indisponível (build exportado) ou formato vetorial.
static func _transparencia_do_arquivo(caminho: String) -> String:
	if caminho.get_extension().to_lower() == "svg":
		return "nao_verificada"
	var disco := ProjectSettings.globalize_path(caminho)
	if not FileAccess.file_exists(disco):
		return "nao_verificada"
	var imagem := Image.new()
	if imagem.load(disco) != OK or imagem.is_empty():
		return "nao_verificada"
	if imagem.detect_alpha() != Image.ALPHA_NONE and _cantos_transparentes(imagem):
		return "real"
	return "opaca"


static func _cantos_transparentes(imagem: Image) -> bool:
	var w := imagem.get_width()
	var h := imagem.get_height()
	for ponto in [Vector2i(0, 0), Vector2i(w - 1, 0), Vector2i(0, h - 1), Vector2i(w - 1, h - 1)]:
		if imagem.get_pixelv(ponto).a > 0.02:
			return false
	return true
