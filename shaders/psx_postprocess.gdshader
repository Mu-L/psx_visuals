shader_type canvas_item;

#include "psx.gdshaderinc"

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture;

void fragment() {
	if (psx_bit_depth <= 0) {
		discard;
	} else {
		COLOR = vec4(dither(texture(SCREEN_TEXTURE, UV), FRAGCOORD.xy).rgb, 1.0);
	}
}
