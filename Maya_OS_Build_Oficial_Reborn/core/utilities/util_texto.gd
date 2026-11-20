class_name UtilTexto
extends RefCounted
## Funções puras de texto (sem dependência de autoloads).

const ACENTOS := {
	"á": "a", "à": "a", "â": "a", "ã": "a", "ä": "a", "é": "e", "è": "e", "ê": "e", "ë": "e",
	"í": "i", "ì": "i", "î": "i", "ï": "i", "ó": "o", "ò": "o", "ô": "o", "õ": "o", "ö": "o",
	"ú": "u", "ù": "u", "û": "u", "ü": "u", "ç": "c", "ñ": "n",
}


## Normaliza chaves de puzzle: minúsculas, sem acentos e só letras/números.
## Assim "Vertigem 99", "vertigem99" e "VERTIGEM-99" são equivalentes (puzzle justo).
static func normalizar_chave(texto: String) -> String:
	var minusculo := texto.to_lower()
	var saida := ""
	for i in minusculo.length():
		var c: String = minusculo[i]
		if ACENTOS.has(c):
			c = ACENTOS[c]
		var cod := c.unicode_at(0)
		if (cod >= 48 and cod <= 57) or (cod >= 97 and cod <= 122):
			saida += c
	return saida


static func hash_chave(texto: String) -> String:
	return normalizar_chave(texto).sha256_text()


## Escapa colchetes para exibir texto do jogador em um RichTextLabel com BBCode.
static func escapar_bbcode(texto: String) -> String:
	return texto.replace("[", "[lb]")


static func truncar(texto: String, maximo: int) -> String:
	var limpo := texto.replace("\n", " ")
	if limpo.length() <= maximo:
		return limpo
	return limpo.substr(0, maximo - 1) + "…"


## Corrompe parte dos caracteres (efeito narrativo do Dia 5). DETERMINÍSTICO: a mesma entrada (texto, intensidade, fase) dá sempre a
## mesma saída, sem sorteio nenhum (as regras do projeto proíbem efeito visual aleatório). `fase` faz o resultado mudar de um quadro
## para o outro (a animação do título passa o número do quadro).
static func corromper(texto: String, intensidade: float = 0.25, fase: int = 0) -> String:
	var simbolos := ["▒", "▓", "█", "░"]
	var saida := ""
	for i in texto.length():
		var c: String = texto[i]
		if c == " " or c == "\n":
			saida += c
			continue
		var h: int = _misturar(texto.unicode_at(i), i, fase)
		if float(h % 1000) / 1000.0 < intensidade:
			@warning_ignore("integer_division")
			var passo: int = h / 1000   # divisão inteira de propósito: o resto decide se o símbolo entra, o quociente escolhe qual
			saida += simbolos[passo % simbolos.size()]
		else:
			saida += c
	return saida


## Mistura três inteiros num número positivo (FNV-1a simplificado). Sempre o mesmo resultado para os mesmos valores.
static func _misturar(a: int, b: int, c: int) -> int:
	var h: int = 2166136261
	for v in [a, b, c]:
		h = ((h ^ (int(v) & 0xFFFFFFFF)) * 16777619) & 0x7FFFFFFF
	return h


## Extensão em minúsculas, sem o ponto ("Foto.JPG" -> "jpg"). Vazio se não houver.
static func extensao(nome: String) -> String:
	var i := nome.rfind(".")
	if i <= 0 or i == nome.length() - 1:
		return ""
	return nome.substr(i + 1).to_lower()


static func sem_extensao(nome: String) -> String:
	var i := nome.rfind(".")
	if i <= 0:
		return nome
	return nome.substr(0, i)


static func dois_digitos(n: int) -> String:
	return "%02d" % n
