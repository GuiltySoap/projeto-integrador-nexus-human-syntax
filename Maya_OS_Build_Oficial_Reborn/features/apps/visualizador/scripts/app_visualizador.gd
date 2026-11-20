class_name AppVisualizador
extends AppBase
## Galeria / Visualizador de mídia: imagens e áudios do VFS, com navegação entre irmãos da pasta e painel de METADADOS.
## A pista do Dia 3 (banda + ano do show) está nos metadados de Show_Antigo.jpg: abrir o painel define
## `metadados_vistos:<nome sem extensão>`. Se existir res://shared/assets/textures/<nome em minúsculas>.png|jpg|webp a imagem
## real é usada; senão ela é gerada por código (ImagemProcedural). A legenda (texto alternativo) vem do metadado "Descrição".
## Args: {"caminho": "/home/usuario/imagens/show_antigo.jpg"}.
##
## A interface (navegação, imagem, controles de áudio, legenda, painel de metadados, Tocador e Temporizador) vive em
## app_visualizador.tscn. Dinâmico: as células nome/valor do painel de metadados, instanciadas em %GradeMeta.

const PASTA_PADRAO := "/home/usuario/imagens"

@export var cena_meta_chave: PackedScene
@export var cena_meta_valor: PackedScene

var _pronta: bool = false
var _caminho: String = ""
var _irmaos: Array = []
var _indice: int = 0
var _meta_visivel: bool = false
var _cache_texturas: Dictionary = {}

@onready var _rot_nome: Label = %RotuloNome
@onready var _rot_legenda: Label = %RotuloLegenda
@onready var _imagem: TextureRect = %Imagem
@onready var _caixa_audio: VBoxContainer = %CaixaAudio
@onready var _btn_tocar: Button = %BotaoTocar
@onready var _barra_audio: ProgressBar = %BarraAudio
@onready var _rot_audio: Label = %RotuloAudio
@onready var _btn_meta: Button = %BotaoMeta
@onready var _painel_meta: PanelContainer = %PainelMeta
@onready var _grade_meta: GridContainer = %GradeMeta
@onready var _btn_anterior: Button = %BotaoAnterior
@onready var _btn_proximo: Button = %BotaoProximo
@onready var _player: AudioStreamPlayer = %Tocador
@onready var _timer: Timer = %Temporizador


func _ready() -> void:
	super()
	_pronta = UiKit.refs_ok(self, {
		"RotuloNome": _rot_nome, "RotuloLegenda": _rot_legenda, "Imagem": _imagem, "CaixaAudio": _caixa_audio, "BotaoTocar": _btn_tocar,
		"BarraAudio": _barra_audio, "RotuloAudio": _rot_audio, "BotaoMeta": _btn_meta, "PainelMeta": _painel_meta, "GradeMeta": _grade_meta,
		"BotaoAnterior": _btn_anterior, "BotaoProximo": _btn_proximo, "Tocador": _player, "Temporizador": _timer,
	})
	if cena_meta_chave == null or cena_meta_valor == null:
		push_error("AppVisualizador: cena_meta_chave e cena_meta_valor precisam ser definidas no Inspetor.")
		_pronta = false


func iniciar(args: Dictionary = {}) -> void:
	if not _pronta:
		return
	var alvo := str(args.get("caminho", ""))
	if alvo == "":
		alvo = _primeira_midia_da_pasta()
	if alvo == "":
		_mostrar_vazio("Abra uma imagem ou áudio pelo Explorador de Arquivos.")
		return
	_abrir(alvo)


func receber_args(args: Dictionary) -> void:
	iniciar(args)


func ao_fechar() -> void:
	_parar_audio()


# ------------------------------------------------------------------ arquivos
func _eh_midia(no: Dictionary) -> bool:
	if str(no.get("tipo", "")) != "arquivo" or SistemaArquivosVirtual.esta_criptografado(no) or SistemaArquivosVirtual.bloqueado_narrativamente(no):
		return false
	var tipo := AbridorArquivos.tipo_do_arquivo(no)
	return tipo == "imagem" or tipo == "audio"


func _primeira_midia_da_pasta() -> String:
	var pasta := SistemaArquivosVirtual.resolver(PASTA_PADRAO)
	if pasta == "" or not SistemaArquivosVirtual.eh_pasta(pasta):
		return ""
	for no in SistemaArquivosVirtual.listar(pasta, false):
		if _eh_midia(no):
			return str(no["caminho"])
	return ""


func _listar_irmaos() -> void:
	_irmaos.clear()
	var pasta := SistemaArquivosVirtual.caminho_pai(_caminho)
	for no in SistemaArquivosVirtual.listar(pasta, false):
		if _eh_midia(no):
			_irmaos.append(str(no["caminho"]))
	_indice = maxi(_irmaos.find(_caminho), 0)
	var varios: bool = _irmaos.size() > 1
	_btn_anterior.disabled = not varios
	_btn_proximo.disabled = not varios


func _abrir(caminho: String) -> void:
	var c := SistemaArquivosVirtual.resolver(caminho)
	if c == "" or not SistemaArquivosVirtual.acessivel(c, true) or not SistemaArquivosVirtual.eh_arquivo(c):
		_mostrar_vazio("Arquivo não encontrado.")
		return
	var no: Dictionary = SistemaArquivosVirtual.obter_no(c)
	if SistemaArquivosVirtual.bloqueado_narrativamente(no):
		_mostrar_vazio("Este arquivo ainda está bloqueado e não pode ser aberto agora.")
		return
	if SistemaArquivosVirtual.esta_criptografado(no):
		_mostrar_vazio("Este arquivo está criptografado. Abra-o pelo Explorador de Arquivos para informar a chave.")
		return
	var tipo := AbridorArquivos.tipo_do_arquivo(no)
	if tipo != "imagem" and tipo != "audio":
		_mostrar_vazio("Formato não suportado por este visualizador.")
		return
	_parar_audio()
	_caminho = c
	_listar_irmaos()
	_meta_visivel = false
	_painel_meta.visible = false
	_btn_meta.disabled = false
	var nome := SistemaArquivosVirtual.nome_do_caminho(c)
	_rot_nome.text = nome
	definir_titulo("Galeria — " + nome)
	var meta: Variant = no.get("meta", {})
	var descricao := ""
	if meta is Dictionary:
		descricao = str(meta.get("Descrição", ""))
	_rot_legenda.text = ("Descrição: " + descricao) if descricao != "" else ""
	if tipo == "imagem":
		_mostrar_imagem(no, c)
	else:
		_mostrar_audio(no)
	AbridorArquivos.registrar_abertura(c)


func _mostrar_vazio(mensagem: String) -> void:
	_parar_audio()
	_caminho = ""
	_irmaos.clear()
	_imagem.texture = null
	_imagem.visible = true
	_caixa_audio.visible = false
	_rot_nome.text = "Galeria"
	_rot_legenda.text = mensagem
	_painel_meta.visible = false
	_btn_meta.disabled = true
	_btn_anterior.disabled = true
	_btn_proximo.disabled = true


func _mostrar_imagem(no: Dictionary, c: String) -> void:
	_caixa_audio.visible = false
	_imagem.visible = true
	var textura: Texture2D = _cache_texturas.get(c)
	if textura == null:
		textura = _textura_real(c)
	if textura == null:
		var proc: Variant = no.get("proc")
		if proc is Dictionary:
			textura = ImagemProcedural.textura(proc)
		else:
			textura = ImagemProcedural.textura({"semente": absi(hash(c)) % 100000, "estilo": "abstrato"})
	_cache_texturas[c] = textura
	_imagem.texture = textura


## Imagem de verdade, se existir: res://shared/assets/textures/<nome do arquivo sem extensão, em minúsculas>.png|jpg|jpeg|webp
## (ex.: "Show_Antigo.jpg" -> show_antigo.png). Sem o arquivo, a imagem procedural é usada; o puzzle não depende dela.
func _textura_real(caminho: String) -> Texture2D:
	var base: String = SistemaArquivosVirtual.nome_do_caminho(caminho).get_basename().to_lower()
	if base == "":
		return null
	for ext in ["png", "jpg", "jpeg", "webp"]:
		var arquivo: String = "res://shared/assets/textures/%s.%s" % [base, ext]
		if ResourceLoader.exists(arquivo):
			var recurso: Resource = load(arquivo)
			if recurso is Texture2D:
				return recurso
	return null


func _mostrar_audio(no: Dictionary) -> void:
	_imagem.visible = false
	_caixa_audio.visible = true
	var proc: Variant = no.get("proc")
	var stream: AudioStream = null
	if proc is Dictionary:
		stream = SistemaAudio.stream_gravacao(str(proc.get("id", "")))
	_player.stream = stream
	if stream == null:
		_btn_tocar.disabled = true
		_rot_audio.text = "indisponível"
		_barra_audio.value = 0.0
		return
	_btn_tocar.disabled = false
	_barra_audio.max_value = maxf(stream.get_length(), 0.1)
	_barra_audio.value = 0.0
	_rot_audio.text = "0:00 / %s" % _formatar_tempo(stream.get_length())


# ------------------------------------------------------------------ navegação
func _ao_anterior() -> void:
	_navegar(-1)


func _ao_proximo() -> void:
	_navegar(1)


func _navegar(passo: int) -> void:
	if _irmaos.size() < 2:
		return
	var novo: int = posmod(_indice + passo, _irmaos.size())
	_abrir(str(_irmaos[novo]))


# ------------------------------------------------------------------ metadados
func _ao_alternar_meta() -> void:
	if _caminho == "":
		return
	_meta_visivel = not _meta_visivel
	_painel_meta.visible = _meta_visivel
	if not _meta_visivel:
		return
	UiKit.limpar_filhos(_grade_meta)
	var no: Dictionary = SistemaArquivosVirtual.obter_no(_caminho)
	var nome := SistemaArquivosVirtual.nome_do_caminho(_caminho)
	_linha_meta("Nome", nome)
	_linha_meta("Pasta", SistemaArquivosVirtual.caminho_pai(_caminho))
	_linha_meta("Tamanho", SistemaArquivosVirtual.tamanho_legivel(no))
	var meta: Variant = no.get("meta", {})
	if meta is Dictionary:
		for chave in meta:
			_linha_meta(str(chave), str(meta[chave]))
	GerenciadorEstado.set_flag("metadados_vistos:" + UtilTexto.sem_extensao(nome).to_lower(), true)


## Uma linha do painel de metadados = duas células da grade (nome do campo e valor), cada uma instanciada de uma cena.
func _linha_meta(chave: String, valor: String) -> void:
	var rot_chave := cena_meta_chave.instantiate() as Label
	_grade_meta.add_child(rot_chave)
	rot_chave.text = chave
	var rot_valor := cena_meta_valor.instantiate() as Label
	_grade_meta.add_child(rot_valor)
	rot_valor.text = valor


# ------------------------------------------------------------------ áudio
func _formatar_tempo(segundos: float) -> String:
	var total: int = int(floor(segundos))
	return "%d:%02d" % [floori(total / 60.0), total % 60]


func _ao_alternar_audio() -> void:
	if _player.stream == null:
		return
	if _player.playing:
		_parar_audio()
		return
	_player.volume_db = -12.0 if bool(GerenciadorConfiguracoes.obter("reduzir_ruido")) else 0.0
	_player.play()
	_btn_tocar.text = "■ Parar"
	_timer.start()


func _parar_audio() -> void:
	if not _pronta:
		return
	if _player.playing:
		_player.stop()
	_timer.stop()
	_btn_tocar.text = "▶ Reproduzir"
	_barra_audio.value = 0.0
	if _player.stream != null:
		_rot_audio.text = "0:00 / %s" % _formatar_tempo(_player.stream.get_length())


# Ligado ao sinal finished do Tocador na cena.
func _ao_audio_terminou() -> void:
	_parar_audio()


# Ligado ao sinal timeout do Temporizador na cena (intervalo 0,1 s).
func _atualizar_progresso() -> void:
	if not _pronta or not _player.playing or _player.stream == null:
		return
	var posicao: float = _player.get_playback_position()
	_barra_audio.value = posicao
	_rot_audio.text = "%s / %s" % [_formatar_tempo(posicao), _formatar_tempo(_player.stream.get_length())]
