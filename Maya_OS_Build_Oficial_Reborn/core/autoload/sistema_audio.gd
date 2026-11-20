extends Node
## Áudio do jogo. Se existir res://shared/assets/audio/<nome>.ogg|wav|mp3, o arquivo tem prioridade sobre o som procedural
## (o projeto traz os 9 efeitos principais em .wav e as trilhas bgm_dia_1..5.ogg em laço). Qualquer arquivo ausente ou
## inválido cai no som gerado em código (AudioStreamWAV), então o jogo também roda sem nenhum arquivo de áudio.
## Os barramentos BGM e SFX são criados em código quando não existem; falhas de áudio nunca interrompem o jogo.

const TAXA := 22050
const BUS_MASTER := "Master"
const BUS_BGM := "BGM"
const BUS_SFX := "SFX"
const PASTA_AUDIO := "res://shared/assets/audio/"
const TOTAL_PLAYERS_SFX := 6
const VOLUME_BGM_DB := -6.0
## As trilhas de arquivo não têm a versão "suave" do drone procedural: com "Reduzir ruído" ligado elas tocam mais baixo.
const VOLUME_BGM_SUAVE_DB := -12.0
## Cada segmento: f (Hz inicial), f2 (Hz final), d (s), v (0..1), tipo (seno|quadrada|serra|ruido)
const SONS := {
	"clique": [{"f": 880.0, "f2": 660.0, "d": 0.035, "v": 0.35, "tipo": "seno"}],
	"tecla": [{"f": 1400.0, "f2": 1100.0, "d": 0.02, "v": 0.2, "tipo": "seno"}],
	"abrir": [{"f": 420.0, "f2": 640.0, "d": 0.09, "v": 0.35, "tipo": "seno"}, {"f": 640.0, "f2": 880.0, "d": 0.08, "v": 0.3, "tipo": "seno"}],
	"fechar": [{"f": 640.0, "f2": 420.0, "d": 0.08, "v": 0.3, "tipo": "seno"}, {"f": 420.0, "f2": 260.0, "d": 0.08, "v": 0.25, "tipo": "seno"}],
	"minimizar": [{"f": 520.0, "f2": 300.0, "d": 0.08, "v": 0.25, "tipo": "seno"}],
	"notificacao": [{"f": 784.0, "f2": 784.0, "d": 0.09, "v": 0.35, "tipo": "seno"}, {"f": 1175.0, "f2": 1175.0, "d": 0.16, "v": 0.3, "tipo": "seno"}],
	"mensagem": [{"f": 988.0, "f2": 988.0, "d": 0.06, "v": 0.3, "tipo": "seno"}, {"f": 1319.0, "f2": 1319.0, "d": 0.1, "v": 0.28, "tipo": "seno"}],
	"erro": [{"f": 220.0, "f2": 180.0, "d": 0.14, "v": 0.35, "tipo": "quadrada"}, {"f": 180.0, "f2": 140.0, "d": 0.18, "v": 0.3, "tipo": "quadrada"}],
	"alerta": [{"f": 740.0, "f2": 740.0, "d": 0.12, "v": 0.3, "tipo": "serra"}, {"f": 554.0, "f2": 554.0, "d": 0.18, "v": 0.3, "tipo": "serra"}],
	"sucesso": [{"f": 523.0, "f2": 523.0, "d": 0.08, "v": 0.3, "tipo": "seno"}, {"f": 659.0, "f2": 659.0, "d": 0.08, "v": 0.3, "tipo": "seno"}, {"f": 784.0, "f2": 784.0, "d": 0.16, "v": 0.3, "tipo": "seno"}],
	"glitch": [{"f": 0.0, "f2": 0.0, "d": 0.07, "v": 0.3, "tipo": "ruido"}, {"f": 90.0, "f2": 60.0, "d": 0.09, "v": 0.3, "tipo": "quadrada"}],
	"boot": [{"f": 330.0, "f2": 330.0, "d": 0.18, "v": 0.3, "tipo": "seno"}, {"f": 494.0, "f2": 494.0, "d": 0.18, "v": 0.3, "tipo": "seno"}, {"f": 660.0, "f2": 660.0, "d": 0.34, "v": 0.3, "tipo": "seno"}],
	"final_bom": [{"f": 392.0, "f2": 392.0, "d": 0.2, "v": 0.3, "tipo": "seno"}, {"f": 523.0, "f2": 523.0, "d": 0.2, "v": 0.3, "tipo": "seno"}, {"f": 659.0, "f2": 659.0, "d": 0.2, "v": 0.3, "tipo": "seno"}, {"f": 784.0, "f2": 784.0, "d": 0.5, "v": 0.3, "tipo": "seno"}],
	"final_mau": [{"f": 220.0, "f2": 196.0, "d": 0.3, "v": 0.3, "tipo": "serra"}, {"f": 196.0, "f2": 147.0, "d": 0.5, "v": 0.3, "tipo": "serra"}],
}
## Drones de fundo por dia: frequências múltiplas de 0.25 Hz para o laço de 4 s ficar sem emenda.
const DRONES := {
	1: [110.0, 165.0, 220.0],
	2: [98.0, 147.0, 196.5],
	3: [87.5, 131.25, 88.0],
	4: [82.5, 123.75, 165.5],
	5: [73.5, 110.25, 74.0],
}

var _bgm: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}
var _proximo: int = 0
var _dia_bgm: int = 0
var _bgm_de_arquivo: bool = false
var _habilitado: bool = true


func _ready() -> void:
	_garantir_barramentos()
	_bgm = AudioStreamPlayer.new()
	_bgm.bus = BUS_BGM
	add_child(_bgm)
	for i in TOTAL_PLAYERS_SFX:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		# Os efeitos (cliques dos menus, avisos) continuam tocando com a árvore pausada; só a trilha (_bgm) pausa junto com o jogo.
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_sfx.append(p)
	aplicar_volumes()
	GerenciadorConfiguracoes.configuracao_alterada.connect(_ao_configuracao_alterada)


func _exit_tree() -> void:
	if GerenciadorConfiguracoes.configuracao_alterada.is_connected(_ao_configuracao_alterada):
		GerenciadorConfiguracoes.configuracao_alterada.disconnect(_ao_configuracao_alterada)


func tocar_sfx(nome: String, volume_db: float = 0.0) -> void:
	if not _habilitado or _sfx.is_empty():
		return
	if (nome == "glitch") and bool(GerenciadorConfiguracoes.obter("reduzir_ruido")):
		return
	var stream := _obter_stream(nome)
	if stream == null:
		return
	var p: AudioStreamPlayer = _sfx[_proximo]
	_proximo = (_proximo + 1) % _sfx.size()
	p.stream = stream
	p.volume_db = volume_db
	p.play()


func tocar_bgm(dia: int) -> void:
	if not _habilitado or _bgm == null:
		return
	var d := clampi(dia, 1, 5)
	if d == _dia_bgm and _bgm.playing:
		return
	_dia_bgm = d
	var stream: AudioStream = _carregar_arquivo("bgm_dia_%d" % d)
	_bgm_de_arquivo = stream != null
	if stream == null:
		stream = _drone(d)
	else:
		_com_laco(stream)
	_bgm.stream = stream
	_bgm.volume_db = _volume_bgm_db()
	_bgm.play()


func parar_bgm() -> void:
	_dia_bgm = 0
	if _bgm != null:
		_bgm.stop()


func _volume_bgm_db() -> float:
	if _bgm_de_arquivo and bool(GerenciadorConfiguracoes.obter("reduzir_ruido")):
		return VOLUME_BGM_SUAVE_DB
	return VOLUME_BGM_DB


## Garante o laço de uma trilha vinda de arquivo mesmo que a importação não tenha "Loop" marcado (.ogg/.mp3/.wav de 16 bits).
func _com_laco(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		if wav.loop_mode == AudioStreamWAV.LOOP_DISABLED and wav.format == AudioStreamWAV.FORMAT_16_BITS:
			var quadros := int(float(wav.data.size()) / (4.0 if wav.stereo else 2.0))
			wav.loop_begin = 0
			wav.loop_end = quadros
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD


## Stream usado por apps (ex.: Galeria toca "gravacao_01"). Retorna null quando o id é desconhecido.
func stream_gravacao(id_audio: String) -> AudioStream:
	var arquivo := _carregar_arquivo(id_audio)
	if arquivo != null:
		return arquivo
	var chave := "rec_" + id_audio
	if _cache.has(chave):
		return _cache[chave]
	if id_audio != "gravacao_01":
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var n := int(3.0 * TAXA)
	var dados := PackedByteArray()
	dados.resize(n * 2)
	var passa_baixa := 0.0
	for i in n:
		var t := float(i) / float(TAXA)
		var ruido := rng.randf_range(-1.0, 1.0)
		passa_baixa = passa_baixa * 0.92 + ruido * 0.08
		var respiracao := 0.5 + 0.5 * sin(TAU * 0.6 * t)
		var tom := sin(TAU * 61.0 * t) * 0.25
		var v := (passa_baixa * 2.4 * respiracao + tom * 0.5) * 0.55
		dados.encode_s16(i * 2, clampi(int(v * 32767.0), -32768, 32767))
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = TAXA
	st.stereo = false
	st.data = dados
	_cache[chave] = st
	return st


func aplicar_volumes() -> void:
	_definir_volume(BUS_MASTER, float(GerenciadorConfiguracoes.obter("volume_master")))
	_definir_volume(BUS_BGM, float(GerenciadorConfiguracoes.obter("volume_bgm")))
	_definir_volume(BUS_SFX, float(GerenciadorConfiguracoes.obter("volume_sfx")))


func _ao_configuracao_alterada(chave: String, _valor: Variant) -> void:
	if chave.begins_with("volume_"):
		aplicar_volumes()
	elif chave == "reduzir_ruido":
		_reaplicar_bgm()


## Aplica o ajuste "reduzir ruído" à trilha em andamento. Com o jogo pausado (o Menu de Pausa abre as Opções) a trilha está pausada, e um
## AudioStreamPlayer pausado deixa de contar como `playing`: sem esta checagem o ajuste só valeria na próxima troca de trilha.
func _reaplicar_bgm() -> void:
	if _bgm == null:
		return
	var pausada: bool = _bgm.stream_paused and _bgm.stream != null and _dia_bgm != 0
	if not _bgm.playing and not pausada:
		_dia_bgm = 0
		return
	if _bgm_de_arquivo:
		_bgm.volume_db = _volume_bgm_db()
		return
	_dia_bgm = 0
	tocar_bgm(clampi(ceili(GerenciadorEstado.etapa_atual / 2.0), 1, 5))
	if pausada:
		# A trilha nova nasce tocando. O jogo continua pausado: ela volta a ficar pausada até o jogo seguir (sem som durante a pausa).
		_bgm.stream_paused = false
		_bgm.stream_paused = true


func _definir_volume(bus: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return
	var v := clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_mute(idx, v <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.001)))


func _garantir_barramentos() -> void:
	for nome in [BUS_BGM, BUS_SFX]:
		if AudioServer.get_bus_index(nome) >= 0:
			continue
		AudioServer.add_bus(AudioServer.bus_count)
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, nome)
		AudioServer.set_bus_send(idx, BUS_MASTER)


func _obter_stream(nome: String) -> AudioStream:
	if _cache.has(nome):
		return _cache[nome]
	var stream: AudioStream = _carregar_arquivo(nome)
	if stream == null and SONS.has(nome):
		stream = _stream_de_segmentos(SONS[nome])
	if stream != null:
		_cache[nome] = stream
	return stream


func _carregar_arquivo(nome: String) -> AudioStream:
	for ext in ["ogg", "wav", "mp3"]:
		var caminho := "%s%s.%s" % [PASTA_AUDIO, nome, ext]
		if ResourceLoader.exists(caminho):
			var recurso: Resource = load(caminho)
			if recurso is AudioStream:
				return recurso
	return null


func _stream_de_segmentos(segmentos: Array) -> AudioStreamWAV:
	var total := 0
	for s in segmentos:
		total += int(float(s["d"]) * TAXA)
	var dados := PackedByteArray()
	dados.resize(total * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var pos := 0
	var fase := 0.0
	for s in segmentos:
		var n := int(float(s["d"]) * TAXA)
		var f0 := float(s["f"])
		var f1 := float(s["f2"])
		var vol := float(s["v"])
		var tipo := str(s["tipo"])
		for i in n:
			var t := float(i) / float(maxi(n - 1, 1))
			fase += TAU * lerpf(f0, f1, t) / float(TAXA)
			var v := 0.0
			match tipo:
				"quadrada":
					v = 1.0 if sin(fase) >= 0.0 else -1.0
				"serra":
					v = fmod(fase / TAU, 1.0) * 2.0 - 1.0
				"ruido":
					v = rng.randf_range(-1.0, 1.0)
				_:
					v = sin(fase)
			var ataque := minf(1.0, float(i) / (0.004 * float(TAXA)))
			var envelope := ataque * (1.0 - t * 0.85)
			dados.encode_s16((pos + i) * 2, clampi(int(v * envelope * vol * 32767.0), -32768, 32767))
		pos += n
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = TAXA
	st.stereo = false
	st.data = dados
	return st


func _drone(dia: int) -> AudioStreamWAV:
	var chave := "drone_%d_%s" % [dia, str(bool(GerenciadorConfiguracoes.obter("reduzir_ruido")))]
	if _cache.has(chave):
		return _cache[chave]
	var freqs: Array = DRONES.get(dia, DRONES[1])
	var duracao := 4
	var n := duracao * TAXA
	var dados := PackedByteArray()
	dados.resize(n * 2)
	var suave := bool(GerenciadorConfiguracoes.obter("reduzir_ruido"))
	var peso := 1.0 / float(freqs.size())
	for i in n:
		var t := float(i) / float(TAXA)
		var v := 0.0
		for f in freqs:
			v += sin(TAU * float(f) * t) * peso
		# Pulso lento (2 ciclos em 4 s) deixa o drone "respirando" sem emenda no laço.
		var lfo := 0.75 + 0.25 * sin(TAU * 0.5 * t)
		var rugosidade := 0.0
		if dia >= 4 and not suave:
			rugosidade = sin(TAU * 7.0 * t) * 0.12 * float(dia - 3)
		v = (v * lfo + rugosidade) * 0.35
		dados.encode_s16(i * 2, clampi(int(v * 32767.0), -32768, 32767))
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = TAXA
	st.stereo = false
	st.data = dados
	st.loop_mode = AudioStreamWAV.LOOP_FORWARD
	st.loop_begin = 0
	st.loop_end = n
	_cache[chave] = st
	return st
