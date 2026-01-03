shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float intensidade : hint_range(0.0, 1.0) = 0.0;
uniform int modo : hint_range(0, 2) = 0; // 0=Normal, 1=Cores, 2=Distorção

void fragment() {
	vec2 uv = SCREEN_UV;
	vec4 color = texture(screen_texture, uv);

	if (modo == 1) {
		// MODO 1: Aberração Cromática (Cores a separar)
		float offset = intensidade * 0.02;
		color.r = texture(screen_texture, uv + vec2(offset, 0.0)).r;
		color.b = texture(screen_texture, uv - vec2(offset, 0.0)).b;
	}
	else if (modo == 2) {
		// MODO 2: Ondulação (Drogas)
		uv.x += sin(uv.y * 20.0 + TIME * 5.0) * (intensidade * 0.05);
		uv.y += cos(uv.x * 20.0 + TIME * 5.0) * (intensidade * 0.05);
		color = texture(screen_texture, uv);

		// Inverter cores se a intensidade for alta
		if (intensidade > 0.8) {
			color.rgb = 1.0 - color.rgb;
		}
	}

	COLOR = color;
}