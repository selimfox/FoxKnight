shader_type canvas_item;
render_mode unshaded;

uniform sampler2D water_mask : filter_nearest, repeat_disable;
uniform vec2 mask_size = vec2(960.0, 540.0);

varying vec2 world_pixel;

void vertex() {
	world_pixel = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 mask = texture(water_mask, world_pixel / mask_size);
	COLOR = texture(TEXTURE, UV) * COLOR;
	COLOR.rgb = mix(COLOR.rgb, vec3(0.60, 0.76, 0.84), 0.30);
	COLOR.a *= mask.a * 0.24;
}
