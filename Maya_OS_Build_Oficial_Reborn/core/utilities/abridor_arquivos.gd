class_name AbridorArquivos
extends RefCounted
## Decide qual aplicativo abre cada arquivo/pasta do VFS (Explorador, busca do menu, terminal e Galeria usam isto).
## Executáveis são simulados: nada é executado de verdade.

## "maya" é a extensão dos arquivos do núcleo da IA. "nexus" era o nome antigo (antes do rebranding) e continua abrindo como texto
## para os arquivos criados com ele em salvamentos antigos.
const TEXTO: Array = ["txt", "log", "md", "maya", "nexus", "cfg", "ini", "csv", "json"]   # marca-legada
const IMAGEM: Array = ["jpg", "jpeg", "png", "webp", "bmp"]
const AUDIO: Array = ["wav", "ogg", "mp3"]


static func icone(no: Dictionary) -> String:
	var tipo := str(no.get("tipo", ""))
	var caminho := str(no.get("caminho", ""))
	if tipo == "pasta":
		if caminho.to_lower() == SistemaArquivosVirtual.PASTA_LIXEIRA:
			return "🗑"
		return "🔒" if SistemaArquivosVirtual.bloqueada(no) else "📁"
	var ext := UtilTexto.extensao(SistemaArquivosVirtual.nome_do_caminho(caminho))
	if SistemaArquivosVirtual.bloqueado_narrativamente(no):
		return "⏳"
	if SistemaArquivosVirtual.esta_corrompido(no):
		return "⚠"
	if IMAGEM.has(ext):
		return "🖼"
	if AUDIO.has(ext):
		return "🔊"
	if ext == "zip":
		return "📦"
	if ext == "exe":
		return "⚙"
	if ext == "maya" or ext == "nexus":   # marca-legada
		return "🧠"
	return "📄"


## Tipo de apresentação: "imagem", "audio", "texto", "zip", "exe" ou "outro".
static func tipo_do_arquivo(no: Dictionary) -> String:
	var ext := UtilTexto.extensao(SistemaArquivosVirtual.nome_do_caminho(str(no.get("caminho", ""))))
	var proc: Variant = no.get("proc")
	if proc is Dictionary:
		return str(proc.get("tipo", "outro"))
	if IMAGEM.has(ext):
		return "imagem"
	if AUDIO.has(ext):
		return "audio"
	if ext == "zip":
		return "zip"
	if SistemaArquivosVirtual.eh_executavel(no) or ext == "exe":
		return "exe"
	if TEXTO.has(ext):
		return "texto"
	return "outro"


## Abre um arquivo ou pasta. Pode demorar (diálogo de chave), então é uma corrotina "dispare e esqueça".
static func abrir(caminho: String) -> void:
	var c := SistemaArquivosVirtual.resolver(caminho)
	if c == "" or not SistemaArquivosVirtual.acessivel(c, true):
		SistemaNotificacoes.notificar("Arquivos", "Não foi possível encontrar esse item.", "erro", 4.0)
		return
	var no: Dictionary = SistemaArquivosVirtual.obter_no(c)
	if str(no.get("tipo", "")) == "pasta":
		GerenciadorJanelas.abrir_app("explorer", {"caminho": c})
		return
	if str(no.get("abre_app", "")) != "":
		GerenciadorJanelas.abrir_app(str(no["abre_app"]))   # atalho (Arquivos > Sistema, Ocultos pela Maya)
		return
	var acao: Dictionary = SistemaArquivosVirtual.ao_abrir(c)
	if str(acao.get("minigame", "")) != "":
		GerenciadorJanelas.abrir_app("minigame_logica", {"minigame": str(acao["minigame"]), "origem": "arquivo"})
		return
	if SistemaArquivosVirtual.bloqueado_narrativamente(no):
		SistemaAudio.tocar_sfx("erro")
		SistemaNotificacoes.notificar("Arquivos", "%s ainda está bloqueado e não pode ser aberto agora." % SistemaArquivosVirtual.nome_do_caminho(c), "aviso", 4.0)
		return
	if SistemaArquivosVirtual.esta_corrompido(no):
		SistemaNotificacoes.notificar("Arquivos", "%s está corrompido: só parte do conteúdo pode ser lida." % SistemaArquivosVirtual.nome_do_caminho(c), "aviso", 5.0)
	var tipo := tipo_do_arquivo(no)
	match tipo:
		"exe":
			await GerenciadorJanelas.alerta("Programa simulado", "Este sistema é uma simulação: executáveis não rodam de verdade.\n\n%s" % SistemaArquivosVirtual.nome_do_caminho(c))
			return
		"zip":
			var destino := SistemaArquivosVirtual.normalizar(str(no.get("pasta_destino", "")))
			if destino != "" and SistemaArquivosVirtual.existe(destino):
				GerenciadorJanelas.abrir_app("explorer", {"caminho": destino})
				_registrar_abertura(c)
			return
		"imagem", "audio":
			GerenciadorJanelas.abrir_app("media_viewer", {"caminho": c})
		_:
			var somente_leitura := bool(no.get("somente_leitura", false)) or SistemaArquivosVirtual.esta_corrompido(no)
			GerenciadorJanelas.abrir_app("text_reader" if somente_leitura else "text_editor", {"caminho": c})
	_registrar_abertura(c)


## Marca o arquivo como aberto (usado pelos objetivos: "arquivo_aberto:<caminho em minúsculas>") e emite o evento `arquivo_aberto`
## (o efeito do evento grava a flag; se o evento for recusado, a flag é gravada aqui mesmo, para os objetivos nunca dependerem dele).
static func _registrar_abertura(caminho: String) -> void:
	var chave: String = SistemaArquivosVirtual.chave(caminho)
	var no: Dictionary = SistemaArquivosVirtual.obter_no(caminho)
	GerenciadorEstado.set_flag("arquivo_aberto:" + chave, true)
	GerenciadorNarrativa.notificar("arquivo_aberto:" + chave, {"caminho": caminho, "tipo": tipo_do_arquivo(no) if not no.is_empty() else "desconhecido"})


static func registrar_abertura(caminho: String) -> void:
	_registrar_abertura(caminho)
