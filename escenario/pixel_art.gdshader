shader_type canvas_item;

// Shader de Pixel Art estilo Blasphemous / Retro
// Pixelación del espacio de pantalla con posterización y reducción sutil de colores.
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

// Tamaño del píxel: 2.0 (sutil), 3.0 (estilo 32-bit / Blasphemous ideal), 4.0 (marcado retro 16-bit)
uniform float tamano_pixel : hint_range(1.0, 8.0, 0.5) = 3.0;

// Profundidad de color para posterización: 0 desactiva, 16 a 32 da la paleta clásica de pixel art
uniform int niveles_color : hint_range(0, 64) = 32;

// Realce de contraste para oscuridad gótica
uniform float contraste : hint_range(0.8, 1.5) = 1.1;

void fragment() {
	// 1. Pixelación por grilla
	vec2 grid = SCREEN_UV - mod(SCREEN_UV, SCREEN_PIXEL_SIZE * tamano_pixel);
	vec4 color = texture(screen_texture, grid);

	// 2. Ajuste de contraste sutil
	vec3 rgb = (color.rgb - vec3(0.5)) * contraste + vec3(0.5);

	// 3. Posterización de paleta (bandas de color características de pixel art)
	if (niveles_color > 0) {
		float n = float(niveles_color);
		rgb = floor(rgb * n + 0.5) / n;
	}

	COLOR = vec4(clamp(rgb, 0.0, 1.0), color.a);
}
