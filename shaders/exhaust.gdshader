shader_type spatial;
uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D noise_texture;
uniform float speed : hint_range(0.02, 0.1, 0.01);

render_mode unshaded;

void fragment() {
	float noise = texture(noise_texture,UV+TIME).r;
	ALBEDO = texture(screen_texture,SCREEN_UV+noise*0.002).rgb;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
