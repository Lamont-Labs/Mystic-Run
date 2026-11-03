shader_type spatial;
render_mode diffuse_burley, specular_disabled;
uniform vec4 base_color : source_color = vec4(0.2,0.5,0.8,1.0);
uniform vec4 highlight_color : source_color = vec4(0.5,0.95,1.0,1.0);
uniform vec4 skin_color : source_color = vec4(1.0,0.70,0.55,1.0);
uniform int character_kind = 0;
varying vec3 rest_vertex;
void vertex(){rest_vertex=VERTEX;}
void fragment(){
 vec3 color=base_color.rgb;
 if(character_kind==2){
  if(rest_vertex.y>1.46 || (abs(rest_vertex.x)>0.63 && rest_vertex.y>1.3)) color=skin_color.rgb;
  else if(rest_vertex.y<0.54) color=vec3(0.20,0.15,0.36);
 }
 // Broad painted shapes stay readable while the authored skeleton runs.
 if(character_kind==1){
  float spot=sin(rest_vertex.y*12.0+rest_vertex.x*8.0+rest_vertex.z*5.0);
  color=mix(color,color*vec3(0.82,0.92,1.0),smoothstep(0.80,0.94,spot)*0.25);
 }
 float rim=pow(1.0-max(dot(normalize(NORMAL),normalize(VIEW)),0.0),3.0);
 ALBEDO=color;
 ROUGHNESS=0.66;
 METALLIC=0.03;
 SPECULAR=0.22;
 EMISSION=highlight_color.rgb*rim*0.12;
}
