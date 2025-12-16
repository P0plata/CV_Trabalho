shader_type spatial;

// Modos de Renderização:
// blend_add: Faz o efeito parecer "luz" ou energia pura (adiciona cores).
// cull_disabled: Vês a parte de trás e da frente do escudo.
// unshaded: Ignora luzes da sala (brilha sozinho).
render_mode blend_add, cull_disabled, unshaded, depth_draw_never;

// --- PARÂMETROS NO INSPECTOR ---
uniform vec4 cor_base : source_color = vec4(0.0, 0.5, 1.0, 1.0); // Cor do escudo (Azul)
uniform float fresnel_power : hint_range(0.1, 10.0) = 3.0;       // Quão transparente é o centro
uniform float edge_intensity : hint_range(0.0, 5.0) = 2.0;       // Brilho das bordas
uniform sampler2D textura_ruido;                                 // Textura para o efeito de "eletricidade"
uniform vec2 scroll_speed = vec2(0.1, 0.05);                     // Velocidade da animação
uniform float pulsacao_velocidade = 2.0;                         // Velocidade do "bater" da energia

void fragment() {
	// 1. CÁLCULO FRESNEL (O Efeito de Borda)
	// O dot product entre a Normal e a Visão diz-nos se estamos a olhar para o centro ou para a borda
	float fresnel = pow(1.0 - dot(NORMAL, VIEW), fresnel_power);
	
	// 2. TEXTURA ANIMADA
	// Movemos as coordenadas UV com o tempo
	vec2 uv_animado = UV + (TIME * scroll_speed);
	float ruido = texture(textura_ruido, uv_animado).r; // Lemos a textura
	
	// 3. PULSAÇÃO (Senoide)
	// Faz o escudo ficar mais forte e mais fraco ciclicamente
	float pulso = (sin(TIME * pulsacao_velocidade) + 1.0) * 0.5; // Normaliza entre 0 e 1
	
	// 4. COMBINAR TUDO
	// A opacidade (Alpha) depende do Fresnel (borda) + Ruído
	float alpha_final = (fresnel * edge_intensity) + (ruido * 0.2 * pulso);
	
	// Aplicar cor e alpha
	ALBEDO = cor_base.rgb;
	ALPHA = clamp(alpha_final, 0.0, 1.0); // Garante que não ultrapassa 1
}