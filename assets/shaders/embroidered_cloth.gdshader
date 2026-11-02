shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform float half_width=0.44;
uniform float top=1.42;
uniform float bottom=0.38;
uniform vec4 cloth_color:source_color=vec4(0.26,0.11,0.40,1.0);
varying vec3 cloth_position;
void vertex(){
 cloth_position=VERTEX;
 float v=clamp((top-VERTEX.y)/(top-bottom),0.0,1.0);
 VERTEX.z+=v*v*(sin(TIME*8.0+VERTEX.x*12.0)*0.018+sin(TIME*5.3+VERTEX.x*18.0)*0.012);
}
void fragment(){
 float v=clamp((top-cloth_position.y)/(top-bottom),0.0,1.0);
 float spread=mix(0.60,1.18,v);
 float u=cloth_position.x/(half_width*spread);
 float weave=0.96+0.04*sin(cloth_position.x*420.0)*sin(cloth_position.y*420.0);
 float folds=0.92+0.08*cos(cloth_position.x*42.0+v*1.8);
 float edge=smoothstep(0.89,0.92,abs(u))-smoothstep(0.94,0.97,abs(u));
 float hem=1.0-smoothstep(0.009,0.018,abs(v-0.94));
 float diamond=abs(u)*0.58+abs(v-0.40)*2.1;
 float crest=(1.0-smoothstep(0.008,0.022,abs(diamond-0.28)))*step(0.20,v)*step(v,0.60);
 float stem=(1.0-smoothstep(0.014,0.029,abs(u)))*step(0.28,v)*step(v,0.68);
 float embroidery=clamp(edge+hem+crest+stem,0.0,1.0);
 ALBEDO=mix(cloth_color.rgb*weave*folds,vec3(0.72,0.49,0.22),embroidery);
 METALLIC=embroidery*0.58;
 ROUGHNESS=mix(0.80,0.44,embroidery);
 SPECULAR=0.28;
 EMISSION=cloth_color.rgb*0.055;
}
