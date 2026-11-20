shader_type canvas_item;
// Barras de glitch, ruído e linhas de varredura. Fraco e sem tela cheia: a opacidade nunca passa de 0,4.
// intensidade: 0 desliga o efeito; animar: 0 deixa estático (modo "sem flashes").

uniform float intensidade : hint_range(0.0, 1.0) = 0.0;
uniform float animar : hint_range(0.0, 1.0) = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float t = floor(TIME * 10.0) * animar;
	float linha = floor(UV.y * 80.0);
	float r = hash(vec2(linha, t));
	float barra = step(0.94, r) * intensidade;
	float ruido = hash(UV * vec2(900.0, 500.0) + t) * 0.10 * intensidade;
	float scan = (0.5 + 0.5 * sin(UV.y * 1100.0)) * 0.05 * intensidade;
	vec3 cor = mix(vec3(0.9, 0.2, 0.7), vec3(0.2, 0.9, 1.0), hash(vec2(linha, t + 1.0)));
	float a = clamp(barra * 0.30 + ruido + scan, 0.0, 0.40);
	COLOR = vec4(cor, a);
}
