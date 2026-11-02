shader_type spatial;
render_mode diffuse_burley;
uniform vec4 base_color : source_color = vec4(0.1,0.2,0.3,1.0);
uniform vec4 highlight_color : source_color = vec4(0.2,0.4,0.5,1.0);
uniform vec4 skin_color : source_color = vec4(0.64,0.36,0.25,1.0);
uniform int character_kind = 0;
varying vec3 rest_vertex;
vec2 hash2(vec2 p){return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);}
void vertex(){rest_vertex=VERTEX;}
void fragment(){
 vec3 color=base_color.rgb;
 float rim=pow(1.0-max(dot(normalize(NORMAL),normalize(VIEW)),0.0),3.0);
 float direction=dot(normalize(NORMAL),normalize(vec3(-0.4,0.7,0.6)));
 float shade=direction>0.45?1.0:(direction>0.0?0.72:0.48);
 if(character_kind==2){
  if(rest_vertex.y>1.46 || (abs(rest_vertex.x)>0.63 && rest_vertex.y>1.3)) color=skin_color.rgb;
  else if(rest_vertex.y<0.54) color=vec3(0.025,0.035,0.08);
  else if(rest_vertex.y>0.98) color=mix(color,vec3(0.21,0.08,0.34),0.45);
 }
 vec3 cracks=vec3(0.0);
 if(character_kind==1){
  vec2 p=vec2(rest_vertex.x+rest_vertex.z*0.37,rest_vertex.y)*8.0;
  vec2 cell=floor(p);vec2 uv=fract(p);float first=9.0;float second=9.0;
  for(int y=-1;y<=1;y++)for(int x=-1;x<=1;x++){
   vec2 neighbor=vec2(float(x),float(y));float d=length(neighbor+hash2(cell+neighbor)-uv);
   if(d<first){second=first;first=d;}else if(d<second){second=d;}
  }
  float seam=1.0-smoothstep(0.008,0.025,second-first);
  color*=1.0-seam*0.35;
  cracks=vec3(0.08,0.5,0.57)*seam*0.48;
 }
 ALBEDO=color*(0.88+shade*0.12);
 ROUGHNESS=character_kind==1?0.78:0.40;
 METALLIC=character_kind==0?0.42:0.06;
 SPECULAR=0.45;
 EMISSION=highlight_color.rgb*rim*0.12+cracks;
}
