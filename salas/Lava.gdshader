shader_type spatial;
render_mode shadows_disabled;

// --- UNIFORMS BLINDADOS ---
uniform vec4 dark_lava_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 light_lava_color : source_color = vec4(1.0, 0.5, 0.0, 1.0);
uniform float speed : hint_range(0.0, 5.0) = 0.5;
uniform float scale : hint_range(0.1, 40.0) = 10.0;
uniform float sharpness : hint_range(1.0, 100.0) = 15.0; 
uniform float emission_intensity : hint_range(0.0, 10.0) = 2.0;
uniform float height_scale : hint_range(0.0, 8.0) = 0.2; 

// NOVO: Controla o tamanho da borda fixa (0.1 = 10% da borda fica fixa)
uniform float border_size : hint_range(0.0, 0.5) = 0.1;

vec2 random2D(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

float voronoiIQ(vec2 _pos) {
    float _time = TIME * speed;
    _pos.y += _time;
    _pos.x += sin(_time);

    vec2 p = floor(_pos);
    vec2 f = fract(_pos);
    float res = 0.0;
    
    float sharp = max(sharpness, 0.001); 
    
    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            vec2 b = vec2(float(i), float(j));
            vec2 pnt = random2D(p + b);
            pnt = 0.5 + 0.5 * sin(_time + 6.2831 * pnt);
            vec2 r = vec2(b) - f + pnt;
            float d = dot(r, r);
            res += exp(-sharp * d);
        }
    }
    
    res = max(res, 0.00001);
    float result = -(1.0 / sharp) * log(res);
    return clamp(result, 0.0, 1.0);
}

void vertex() {
    float current_scale = scale > 0.001 ? scale : 10.0;
    vec2 uv = UV * current_scale;
    float height = voronoiIQ(uv);
    
    // --- LÓGICA DA BORDA FIXA ---
    // 1. Calcula a distância até a borda mais próxima (X ou Y)
    // UV vai de 0 a 1. Logo, "min(UV.x, 1.0 - UV.x)" diz quão longe estamos da borda.
    float dist_borda_x = min(UV.x, 1.0 - UV.x);
    float dist_borda_y = min(UV.y, 1.0 - UV.y);
    float dist_minima = min(dist_borda_x, dist_borda_y);
    
    // 2. Cria uma máscara suave.
    // Se a distância for 0 (borda), o multiplicador é 0.
    // Se a distância for maior que border_size, o multiplicador vira 1.
    float border_mask = smoothstep(0.0, border_size, dist_minima);
    
    // 3. Aplica a máscara à altura
    VERTEX.y += height * height_scale * border_mask;
}

void fragment() {
    float current_scale = scale > 0.001 ? scale : 10.0;
    vec2 uv = UV * current_scale;
    float voronoi_value = voronoiIQ(uv);

    vec4 final_color = mix(dark_lava_color, light_lava_color, voronoi_value);
    
    ALBEDO = final_color.rgb;
    EMISSION = final_color.rgb * emission_intensity;
}