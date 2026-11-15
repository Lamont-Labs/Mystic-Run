shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_prepass_alpha, shadows_disabled;
uniform sampler2D art : source_color, filter_linear;
uniform sampler2D previous_art : source_color, filter_linear;
uniform vec4 region = vec4(0,0,1,1);
uniform vec4 previous_region = vec4(0,0,1,1);
uniform float transition = 1.0;
uniform float phase = 0.0;
uniform float locomotion = 0.0;
uniform float action_energy = 0.0;
uniform float character_kind = 0.0;
uniform vec4 tint : source_color = vec4(1.0);

vec2 rotate_joint(vec2 p, vec2 pivot, float angle) {
	float c=cos(angle); float s=sin(angle);
	return pivot+mat2(vec2(c,s),vec2(-s,c))*(p-pivot);
}
void vertex() {
	vec2 p=VERTEX.xy;
	vec2 rest=p;
	float side=sign(p.x);
	float stride=sin(phase+step(0.0,p.x)*3.14159265);
	// Smooth joint weights: torso stays intact; hips, knees and shoulders articulate.
	float legs=1.0-smoothstep(-0.22,-0.01,rest.y);
	float knees=1.0-smoothstep(-0.38,-0.20,rest.y);
	float narrow=1.0-smoothstep(0.24,0.41,abs(rest.x));
	vec2 hip=vec2(side*0.105,-0.08);
	vec2 knee=vec2(side*0.11,-0.29);
	p=mix(p,rotate_joint(p,hip,stride*0.24),legs*narrow*locomotion);
	p=mix(p,rotate_joint(p,knee,max(0.0,-stride)*side*0.32),knees*narrow*locomotion);
	p.y+=max(0.0,-stride)*0.035*legs*locomotion;
	float arms=smoothstep(0.18,0.34,abs(rest.x))*(1.0-smoothstep(0.23,0.40,rest.y));
	p=mix(p,rotate_joint(p,vec2(side*0.19,0.19),-stride*0.14),arms*locomotion);
	// Secondary motion remains continuous between generated action poses.
	float cloth=(1.0-smoothstep(-0.24,0.18,rest.y))*(1.0-legs*0.75);
	p.x+=sin(phase-2.5*rest.y)*cloth*0.012*(locomotion+action_energy);
	if(character_kind>0.5 && character_kind<1.5) {
		float wings=smoothstep(0.22,0.48,abs(rest.x))*smoothstep(-0.12,0.22,rest.y);
		p.x+=side*sin(phase*0.5-0.8)*0.025*wings*locomotion;
		p.y+=cos(phase*0.5)*0.012*wings*locomotion;
	}
	VERTEX.xy=p;
	// Billboard while retaining character scale, without a rotating paper edge.
	mat4 billboard=mat4(INV_VIEW_MATRIX[0],INV_VIEW_MATRIX[1],INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);
	billboard[0].xyz*=length(MODEL_MATRIX[0].xyz);
	billboard[1].xyz*=length(MODEL_MATRIX[1].xyz);
	billboard[2].xyz*=length(MODEL_MATRIX[2].xyz);
	MODELVIEW_MATRIX=VIEW_MATRIX*billboard;
}
void fragment() {
	vec4 a=texture(previous_art,previous_region.xy+UV*previous_region.zw);
	vec4 b=texture(art,region.xy+UV*region.zw);
	float alpha=mix(a.a,b.a,transition);
	vec3 premult=mix(a.rgb*a.a,b.rgb*b.a,transition);
	ALBEDO=premult/max(alpha,0.001)*tint.rgb;
	ALPHA=alpha*tint.a;
}
