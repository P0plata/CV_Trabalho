shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_prepass_alpha;

uniform sampler2D sprite_tex : source_color;

uniform float time_scale = 1.0;

// rotation speed (vertex)
uniform float rot_x = 1.5;
uniform float rot_y = 2.0;
uniform float rot_z = 0.5;

// glitch
uniform float glitch_strength = 0.6;   // aumenta para ser visível
uniform float rgb_shift = 0.05;        // separação RGB

// outline (screen-stable option comentada abaixo)
uniform float outline_size = 0.012;
uniform vec3 outline_color = vec3(0.1, 1.0, 1.0);

// emissive
uniform float emission_power = 1.6;


// ----------------------
// Rotação 3D (vertex)
mat3 rotX(float a) {
	return mat3(
		vec3(1.0, 0.0, 0.0),
		vec3(0.0, cos(a), -sin(a)),
		vec3(0.0, sin(a),  cos(a))
	);
}
mat3 rotY(float a) {
	return mat3(
		vec3( cos(a), 0.0, sin(a)),
		vec3( 0.0,    1.0, 0.0),
		vec3(-sin(a), 0.0, cos(a))
	);
}
mat3 rotZ(float a) {
	return mat3(
		vec3(cos(a), -sin(a), 0.0),
		vec3(sin(a),  cos(a), 0.0),
		vec3(0.0,     0.0,    1.0)
	);
}

void vertex() {
	float t = TIME * time_scale;
	mat3 R = rotZ(t * rot_z) * rotY(t * rot_y) * rotX(t * rot_x);
	VERTEX = R * VERTEX;
	NORMAL = R * NORMAL;
}


// ----------------------
// Fragment: glitch + outline + alpha
void fragment() {
	float t = TIME * time_scale;

	// base UV (não é alterada pela rotação do VERTEX)
	vec2 uv = UV;

	// ---------------------------
	// GLITCH UV distortion (visível)
	// ---------------------------
	uv.x += sin(uv.y * 25.0 + t * 6.5) * glitch_strength * 0.035;
	uv.y += cos(uv.x * 36.0 + t * 4.0) * glitch_strength * 0.02;

	// ---------------------------
	// RGB SPLIT (glitch)
	// ---------------------------
	vec4 r = texture(sprite_tex, uv + vec2(rgb_shift, 0.0));
	vec4 g = texture(sprite_tex, uv);
	vec4 b = texture(sprite_tex, uv - vec2(rgb_shift, 0.0));
	vec4 tex_final = vec4(r.r, g.g, b.b, g.a);

	// ---------------------------
	// OUTLINE (UV-based): este outline acompanha o sprite no ecrã
	// ---------------------------
	float alpha_center = g.a;

	// amostras em volta no espaço UV (mantém-se alinhado à textura, não ao mundo)
	float s = 0.0;
	s += texture(sprite_tex, UV + vec2( outline_size, 0.0)).a;
	s += texture(sprite_tex, UV + vec2(-outline_size, 0.0)).a;
	s += texture(sprite_tex, UV + vec2(0.0,  outline_size)).a;
	s += texture(sprite_tex, UV + vec2(0.0, -outline_size)).a;

	// se houver alguma amostra opaca nas vizinhanças e o centro for transparente -> outline
	float outline_mask = step(0.05, s) * (1.0 - alpha_center);

	// mistura cor + outline
	vec3 color = mix(tex_final.rgb, outline_color, outline_mask);

	ALBEDO = color;
	ALPHA = tex_final.a + outline_mask * 0.85;
	EMISSION = color * emission_power;
}
