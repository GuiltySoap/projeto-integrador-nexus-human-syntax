class_name TemaVariacoes
extends RefCounted
## Type variations do Theme geradas por tabela, para que as cenas (.tscn) escolham estilo e tamanho de texto sem código.
## Rótulos: cada combinação (estilo x tamanho x mono) vira uma variação de "Label". O tamanho respeita
## Configurações > Tamanho do texto, porque o Theme é recriado quando essa opção muda (TemaNexus.criar_tema).
## Nome da variação: <Estilo><Tamanho>[Mono]. Ex.: RotuloFraco14, RotuloTitulo52Mono, Rotulo13, RotuloMono11.
## tools/validar_projeto.py confere que toda variação usada em um .tscn existe aqui ou em TemaNexus.

## [estilo, tamanho em px, mono]. Estilos: "" (texto normal), "Fraco", "Titulo", "Acento", "Perigo", "Mono".
const ROTULOS: Array = [
	["", 13, false],
	["", 14, false],
	["", 15, false],
	["", 19, false],
	["", 20, false],
	["", 22, false],
	["Acento", 10, true],
	["Acento", 11, false],
	["Acento", 11, true],
	["Acento", 12, false],
	["Acento", 12, true],
	["Acento", 13, false],
	["Acento", 13, true],
	["Acento", 14, true],
	["Acento", 15, false],
	["Acento", 15, true],
	["Acento", 16, true],
	["Acento", 18, false],
	["Acento", 18, true],
	["Acento", 20, true],
	["Acento", 26, true],
	["Acento", 34, true],
	["Fraco", 11, false],
	["Fraco", 11, true],
	["Fraco", 12, false],
	["Fraco", 12, true],
	["Fraco", 13, false],
	["Fraco", 13, true],
	["Fraco", 14, false],
	["Fraco", 14, true],
	["Fraco", 15, false],
	["Fraco", 20, false],
	["Mono", 11, false],
	["Mono", 12, false],
	["Mono", 13, false],
	["Mono", 14, false],
	["Mono", 15, false],
	["Mono", 16, false],
	["Perigo", 11, false],
	["Perigo", 12, false],
	["Perigo", 14, true],
	["Perigo", 18, true],
	["Titulo", 16, false],
	["Titulo", 18, false],
	["Titulo", 20, false],
	["Titulo", 22, false],
	["Titulo", 24, false],
	["Titulo", 34, false],
	["Titulo", 36, false],
	["Titulo", 44, false],
	["Titulo", 52, true],
]


static func nome_rotulo(estilo: String, tamanho: int, mono: bool) -> String:
	var nome: String = "Rotulo" + estilo
	if tamanho > 0:
		nome += str(tamanho)
	if mono and estilo != "Mono":
		nome += "Mono"
	return nome


## Chamada por TemaNexus.criar_tema(): p = paleta efetiva, escala = Configurações > Tamanho do texto.
static func registrar(t: Theme, p: Dictionary, escala: float, fonte_mono: Font) -> void:
	_rotulos(t, p, escala, fonte_mono)
	_paineis(t, p)
	_outros(t, escala, fonte_mono)


static func _rotulos(t: Theme, p: Dictionary, escala: float, fonte_mono: Font) -> void:
	var cores: Dictionary = {
		"": p["texto"], "Fraco": p["texto_fraco"], "Titulo": p["texto"],
		"Acento": p["acento2"], "Perigo": p["perigo"], "Mono": p["texto"],
	}
	for r in ROTULOS:
		var estilo: String = r[0]
		var tamanho: int = r[1]
		var mono: bool = r[2]
		var nome: String = nome_rotulo(estilo, tamanho, mono)
		t.set_type_variation(nome, "Label")
		t.set_color("font_color", nome, cores[estilo])
		var px: int = tamanho
		if px <= 0 and estilo == "Titulo":
			px = 22
		if px > 0:
			t.set_font_size("font_size", nome, int(round(float(px) * escala)))
		if (mono or estilo == "Mono") and fonte_mono != null:
			t.set_font("font", nome, fonte_mono)


static func _paineis(t: Theme, p: Dictionary) -> void:
	var acento: Color = p["acento"]
	# Toasts: um painel por nível (a cor da borda identifica o nível; o texto do nível também aparece no toast)
	var painel: Color = p["painel"]
	var niveis: Dictionary = {
		"PainelToastInfo": p["acento2"], "PainelToastIa": p["acento"], "PainelToastAviso": p["aviso"],
		"PainelToastErro": p["perigo"], "PainelToastSucesso": p["ok"],
	}
	for nome in niveis:
		var cor: Color = niveis[nome]
		t.set_type_variation(nome, "PanelContainer")
		t.set_stylebox("panel", nome, TemaNexus.caixa(Color(painel.r, painel.g, painel.b, 0.97), Color(cor.r, cor.g, cor.b, 0.9), 10, 1, 14, 12))
	# Balões do Mensageiro (BalaoChat escolhe a variação pelo tipo da mensagem)
	var perigo: Color = p["perigo"]
	t.set_type_variation("BolhaPropria", "PanelContainer")
	t.set_stylebox("panel", "BolhaPropria", TemaNexus.caixa(Color(acento.r, acento.g, acento.b, 0.26), Color(acento.r, acento.g, acento.b, 0.7), 12, 1, 12, 8))
	t.set_type_variation("BolhaSistema", "PanelContainer")
	t.set_stylebox("panel", "BolhaSistema", TemaNexus.caixa(Color(1, 1, 1, 0.05), Color(1, 1, 1, 0.12), 12, 1, 12, 6))
	t.set_type_variation("BolhaCorrompida", "PanelContainer")
	t.set_stylebox("panel", "BolhaCorrompida", TemaNexus.caixa(Color(perigo.r, perigo.g, perigo.b, 0.16), Color(perigo.r, perigo.g, perigo.b, 0.8), 12, 1, 12, 8))
	t.set_type_variation("BolhaPadrao", "PanelContainer")
	t.set_stylebox("panel", "BolhaPadrao", TemaNexus.caixa(painel, Color(1, 1, 1, 0.14), 12, 1, 12, 8))



static func _outros(t: Theme, escala: float, fonte_mono: Font) -> void:
	# RichTextLabel com fonte mono (listas técnicas, terminal etc.)
	t.set_type_variation("RichoMono", "RichTextLabel")
	if fonte_mono != null:
		t.set_font("normal_font", "RichoMono", fonte_mono)
	# Uma variação de tipo não enxerga os fontes de negrito/itálico do tema padrão da engine (a busca cai na fonte regular de
	# fallback e o [b] some). Repete-os aqui para o [b]/[i] funcionarem como num RichTextLabel comum.
	var tema_padrao: Theme = ThemeDB.get_default_theme()
	if tema_padrao != null:
		for chave in ["bold_font", "italics_font", "bold_italics_font"]:
			t.set_font(chave, "RichoMono", tema_padrao.get_font(chave, "RichTextLabel"))
	# Editor do Bloco de Notas: TextEdit mono em 15 px x escala (herda a fonte de TextoMono, definida em TemaNexus)
	t.set_type_variation("TextoMono15", "TextoMono")
	t.set_font_size("font_size", "TextoMono15", int(round(15.0 * escala)))
	# Teclas da Calculadora: botões com texto maior (20 px x escala). Cada uma herda o visual de uma variação de botão existente.
	var teclas: Dictionary = {"BotaoTecla": "Button", "BotaoTeclaPerigo": "BotaoPerigo", "BotaoTeclaPlano": "BotaoPlano", "BotaoTeclaPrimario": "BotaoPrimario"}
	for nome in teclas:
		t.set_type_variation(nome, teclas[nome])
		t.set_font_size("font_size", nome, int(round(20.0 * escala)))

