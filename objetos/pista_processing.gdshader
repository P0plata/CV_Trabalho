shader_type spatial;
render_mode unshaded;

uniform sampler2D tex;
uniform int zona_correta = 0;
uniform int modo = 0;
uniform float intensidade = 0.5;

void fragment() {
	vec2 uv = UV;
	vec2 uv2 = uv;
	float t = TIME;

	// -------------------------
	// ZONA ATIVA (A CORRETA)
	// -------------------------
	bool ativa = false;
	if (zona_correta == 0 && uv.x < 0.33) ativa = true;
	if (zona_correta == 1 && uv.x >= 0.33 && uv.x < 0.66) ativa = true;
	if (zona_correta == 2 && uv.x >= 0.66) ativa = true;

	// -------------------------
	// EFEITOS UV (Movimento)
	// -------------------------
	if (modo == 1 && !ativa) {
		// Distorção forte para se notar bem que está errado
		uv2.x += sin(uv.y * 30.0 + t * 5.0) * 0.01;
		uv2.y += cos(uv.x * 30.0 + t * 4.0) * 0.01;
	}

	vec4 c = texture(tex, uv2);
	vec3 cor_final = c.rgb;

	// -------------------------
	// VISUALIZAÇÃO DO ERRO
	// -------------------------
	if (!ativa) {

		if (modo == 0) {
			// MODO CONTRASTE (Sala 1)
			// Preto e Branco simples.
			float cinza = (c.r + c.g + c.b) / 3.0;
			cor_final = vec3(cinza);
			// Boost leve para não ficar cinzento escuro demais
			cor_final = max(cor_final, vec3(0.2));
		}
		else if (modo == 1) {
			// MODO DISTORÇÃO (Sala 2 - O PROBLEMA DA IMAGEM)
			// Em vez de só distorcer a cor escura, misturamos com VERMELHO.
			// Isto impede que fique preto.
			vec3 vermelho_aviso = vec3(0.5, 0.1, 0.1);
			cor_final = mix(c.rgb, vermelho_aviso, 0.4); // 40% Vermelho, 60% Textura
		}
		else if (modo == 2) {
			// MODO SCANLINES (Sala 3)
			// Ruído de TV
			float ruido = fract(sin(dot(uv, vec2(12.9898, 78.233) * t)) * 43758.5453);
			// Mistura a textura com ruído cinzento (não preto!)
			cor_final = mix(c.rgb, vec3(0.4), 0.3 * ruido);
		}

		// SEGURANÇA FINAL: Impedir pretos totais
		// Se a cor for muito escura, aumentamos o brilho à força
		if (length(cor_final) < 0.2) {
			cor_final += 0.15;
		}

	} else {
		// -------------------------
		// PARTE CORRETA
		// -------------------------
		// Apenas baixamos um pouco o brilho para o Glow do ambiente não estourar
		cor_final *= 0.9;
	}

	ALBEDO = cor_final;

	// -------------------------
	// EMISSÃO (Brilho no Escuro)
	// -------------------------
	// Apenas na parte errada, para ela "furar" a escuridão da sala
	if (!ativa) {
		// Valor baixo (0.15) é suficiente para ver, mas não ilumina a sala
		EMISSION = cor_final * 0.15;
	}
}