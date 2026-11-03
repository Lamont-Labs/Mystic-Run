shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;
uniform float half_width=0.44;
uniform float top=1.42;
uniform float bottom=0.38;
uniform float motion_amount=1.0;
uniform vec4 cloth_color:source_color=vec4(1.0,0.35,0.25,1.0);
varying vec3 cloth_position;
void vertex(){
 cloth_position=VERTEX;
 float v=clamp((top-VERTEX.y)/(top-bottom),0.0,1.0);
 VERTEX.z+=motion_amount*v*v*(sin(TIME*8.0+VERTEX.x*10.0)*0.045+sin(TIME*5.3+VERTEX.x*16.0)*0.022);
}
void fragment(){
 float v=clamp((top-cloth_position.y)/(top-bottom),0.0,1.0);
 float spread=mix(0.60,1.18,v);
 float u=cloth_position.x/(half_width*spread);
 float folds=0.96+0.04*cos(cloth_position.x*32.0+v*1.8);
 float edge=smoothstep(0.86,0.89,abs(u))-smoothstep(0.94,0.97,abs(u));
 float hem=1.0-smoothstep(0.012,0.022,abs(v-0.94));
 vec2 p=vec2(u,(v-0.44)*2.3);
 float angle=atan(p.x,-p.y);
 float sector=3.14159265/5.0;
 float a=mod(angle+6.28318530,6.28318530);
 float index=floor(a/sector);
 float local_angle=a-index*sector;
 float r0=mix(0.40,0.18,mod(index,2.0));
 float r1=mix(0.18,0.40,mod(index,2.0));
 float star_radius=r0*r1*sin(sector)/(r1*sin(sector-local_angle)+r0*sin(local_angle));
 float star=1.0-smoothstep(star_radius,star_radius+0.018,length(p));
 float trim=clamp(edge+hem+star,0.0,1.0);
 ALBEDO=mix(cloth_color.rgb*folds,vec3(1.0,0.83,0.29),trim)*0.82;
 METALLIC=0.0;
 ROUGHNESS=0.78;
 SPECULAR=0.18;
 EMISSION=cloth_color.rgb*0.04;
}
