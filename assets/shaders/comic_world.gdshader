shader_type spatial;
render_mode world_vertex_coords, diffuse_burley;
uniform vec4 paint : source_color = vec4(0.1,0.15,0.25,1.0);
uniform float glow = 0.0;
uniform float metal = 0.0;
uniform float bend = 0.0;
varying vec3 stone_position;
void vertex(){
 float ahead=clamp((-VERTEX.z-8.0)/70.0,0.0,2.6);
 VERTEX.x+=bend*ahead*ahead;
 stone_position=VERTEX;
}
void fragment(){
 float detail=0.96+0.04*sin(stone_position.x*2.7+sin(stone_position.z*1.3))*sin(stone_position.y*3.2+stone_position.z*0.4);
 ALBEDO=paint.rgb*detail;
 ROUGHNESS=0.77; METALLIC=metal; SPECULAR=0.20;
 EMISSION=paint.rgb*glow;
}
