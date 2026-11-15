shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled, shadows_disabled;
uniform sampler2D current_vista : source_color, filter_linear;
uniform sampler2D next_vista : source_color, filter_linear;
uniform float blend = 0.0;
uniform float drift = 0.0;
void fragment() {
	vec2 at=clamp(UV*0.96+vec2(.02+drift,.02),vec2(.001),vec2(.999));
	ALBEDO=mix(texture(current_vista,at).rgb,texture(next_vista,at).rgb,blend);
}
