shader_type canvas_item;
render_mode unshaded;
uniform vec4 accent : source_color = vec4(0.2,0.8,0.7,1.0);
uniform float drift = 0.0;
#include "res://journey_atmosphere.gdshaderinc"
void fragment() { COLOR = vec4(atmosphere_color(UV,accent.rgb,drift),1.0); }
