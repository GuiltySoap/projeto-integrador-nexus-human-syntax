shader_type canvas_item;
// Desfoque leve do que foi desenhado ANTES deste retângulo (o fundo físico atrás do monitor virtual).
// `raio` é o nível de mipmap da textura da tela: 0 = nítido; ~2 = levemente desfocado. `escurecer` escurece o fundo para o monitor se destacar.
uniform sampler2D tela : hint_screen_texture, filter_linear_mipmap;
uniform float raio : hint_range(0.0, 6.0) = 2.0;
uniform float escurecer : hint_range(0.0, 1.0) = 0.25;

void fragment() {
	vec3 cor = textureLod(tela, SCREEN_UV, raio).rgb;
	COLOR = vec4(cor * (1.0 - escurecer), 1.0);
}
