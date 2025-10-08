shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float strength : hint_range(0.0, 1.0) = 0.6;
uniform float speed = 1.2;
uniform float scale = 35.0;
uniform vec2 flow_dir = vec2(0.0, -1.0);
uniform float offset_px = 0.0;

void fragment() {
	// Coordonnées écran
	vec2 suv = SCREEN_UV;

	// Bruit ondulant simple (rapide & cheap)
	float t = TIME * speed;
	float n1 = sin((UV.y + t) * scale);
	float n2 = cos((UV.x - t * 0.8) * scale * 0.7);
	float n = (n1 + n2) * 0.5;

	// Déplacement (valeur en UV ~ quelques millièmes)
	vec2 dir = normalize(flow_dir);
	vec2 offset = dir * n * (0.003 * strength);

	// Échantillonnage écran avec décalage (refraction)
	vec4 refracted = texture(SCREEN_TEXTURE, suv + offset);

	// Utilise l'alpha du sprite comme MASQUE
	float mask = texture(TEXTURE, UV).a;

	COLOR = refracted;
	COLOR.a *= mask;
}
