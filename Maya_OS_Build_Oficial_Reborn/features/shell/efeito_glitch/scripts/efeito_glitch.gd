class_name EfeitoGlitch
extends Control
## Camada de efeitos de glitch e "corrupção" visual. Acessibilidade:
## - "Reduzir glitch" desliga o efeito visual por completo;
## - "Sem flashes" deixa o efeito estático e fraco (sem animação);
## - "Reduzir tremor" desliga o balanço das janelas;
## - a opacidade nunca passa de 0,4 e as barras ocupam uma fração pequena da tela (sem flashes de tela cheia).

## O retângulo com o ShaderMaterial está em efeito_glitch.tscn (shader em shared/assets/shaders/efeito_glitch.gdshader);
## aqui só entram a intensidade (corrupção do sistema e eventos da narrativa) e o tremor das janelas.

var _material: ShaderMaterial
var _alvo_tremor: Control = null
var _base: float = 0.0
var _extra: float = 0.0
var _pico: float = 0.0
var _duracao: float = 0.0
var _restante: float = 0.0
var _tween_tremor: Tween

@onready var _retangulo: ColorRect = %Retangulo


func _ready() -> void:
	if not UiKit.refs_ok(self, {"Retangulo": _retangulo}):
		return
	_material = _retangulo.material as ShaderMaterial
	if _material == null:
		push_error("EfeitoGlitch: o Retangulo precisa de um ShaderMaterial (veja efeito_glitch.tscn).")
		return
	set_process(false)
	atualizar_base()


func definir_alvo_tremor(alvo: Control) -> void:
	_alvo_tremor = alvo


## Efeito pontual (evento da narrativa).
func disparar(intensidade: float, duracao: float) -> void:
	if not GerenciadorConfiguracoes.glitch_permitido():
		return
	var forca := clampf(intensidade, 0.0, 1.0)
	if bool(GerenciadorConfiguracoes.obter("sem_flashes")):
		forca = minf(forca, 0.25)
	_pico = forca
	_extra = forca
	_duracao = maxf(duracao, 0.2)
	_restante = _duracao
	_aplicar()
	set_process(true)
	SistemaAudio.tocar_sfx("glitch", -4.0)
	GerenciadorJanelas.glitch_nas_janelas(_duracao)
	_tremer(forca)


## Corrupção permanente de fundo. O roteiro v2.0 não tem corrupção do sistema: não há estática de fundo.
func atualizar_base() -> void:
	if _material == null:
		return
	_base = 0.0
	_aplicar()


func _process(delta: float) -> void:
	if _restante > 0.0:
		_restante -= delta
		if _restante <= 0.0:
			_restante = 0.0
			_extra = 0.0
		else:
			_extra = _pico * clampf(_restante / _duracao, 0.0, 1.0)
	_aplicar()
	if _restante <= 0.0:
		set_process(false)


func _aplicar() -> void:
	if _material == null:
		return
	var total := clampf(_base + _extra, 0.0, 1.0)
	_material.set_shader_parameter("intensidade", total)
	_material.set_shader_parameter("animar", 0.0 if bool(GerenciadorConfiguracoes.obter("sem_flashes")) else 1.0)
	_retangulo.visible = total > 0.001


func _tremer(forca: float) -> void:
	if _alvo_tremor == null or not GerenciadorConfiguracoes.tremor_permitido():
		return
	if _tween_tremor != null and _tween_tremor.is_valid():
		_tween_tremor.kill()
	var origem := _alvo_tremor.position
	var amplitude := 5.0 * forca
	_tween_tremor = create_tween()
	for dx in [1.0, -1.0, 0.6, -0.6, 0.0]:
		_tween_tremor.tween_property(_alvo_tremor, "position:x", origem.x + amplitude * float(dx), 0.05)
