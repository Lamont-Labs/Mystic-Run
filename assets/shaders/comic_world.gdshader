shader_type spatial;
render_mode world_vertex_coords, diffuse_burley;
uniform vec4 paint : source_color = vec4(0.1,0.15,0.25,1.0);
uniform float glow = 0.0;
uniform float metal = 0.0;
uniform float bend = 0.0;
uniform float course_distance = 0.0;
uniform bool flat_course = false;
uniform bool pavement = false;
uniform vec4 gaps[12];
uniform int gap_count=0;
varying vec3 stone_position;
varying vec3 logical_position;
float height_at(float s){
 float d=mod(max(s,0.0),640.0);
 return 11.0*smoothstep(36.0,116.0,d)-17.0*smoothstep(150.0,238.0,d)+13.0*smoothstep(282.0,354.0,d)-10.0*smoothstep(405.0,500.0,d)+3.0*smoothstep(558.0,620.0,d);
}
float curve(float s){return sin(s/92.0)*6.0+sin(s/211.0)*3.0;}
float hash(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
float noise(vec3 p){
 vec3 i=floor(p);vec3 f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex(){
 logical_position=VERTEX;
 float s=max(0.0,course_distance-VERTEX.z);
 if(!flat_course){
  float tangent=(curve(course_distance+0.1)-curve(course_distance-0.1))/0.2;
  VERTEX.x+=curve(s)-curve(course_distance)-tangent*(s-course_distance);
  VERTEX.y+=height_at(s);
  float grade=(height_at(s+0.1)-height_at(s-0.1))/0.2;
  NORMAL=normalize(vec3(NORMAL.x,NORMAL.y-grade*NORMAL.z,NORMAL.z+grade*NORMAL.y));
 }
 stone_position=vec3(logical_position.x,logical_position.y,s);
}
void fragment(){
 if(logical_position.y<0.15 && logical_position.y> -2.0){
  for(int i=0;i<12;i++){
   if(i>=gap_count)break;
   if(abs(logical_position.x-gaps[i].x)<gaps[i].z && abs(logical_position.z-gaps[i].y)<gaps[i].w)discard;
  }
 }
 float grain=noise(stone_position*4.0);
 float cloud=noise(stone_position*0.68);
 float fine=noise(stone_position*25.0);
 float texture_value=0.72+cloud*0.28+grain*0.12+fine*0.055;
 vec3 color=paint.rgb*texture_value;
 float weather=smoothstep(0.48,0.80,noise(stone_position*0.22));
 color=mix(color,color*vec3(0.74,0.94,0.92),weather*0.32*(1.0-metal));
 if(pavement){
  vec2 p=vec2((stone_position.x+4.5)/1.5,stone_position.z/3.0);
  p.x+=mod(floor(p.y),2.0)*0.5;
  vec2 cell=floor(p);vec2 local=fract(p);
  vec2 edges=min(local,1.0-local);
  float seam=1.0-smoothstep(0.008,0.026,min(edges.x,edges.y));
  float tile=hash(vec3(cell,1.0));
  color*=mix(0.87,1.10,tile)*(1.0-seam*0.48);
  color=mix(color,color*vec3(1.10,1.02,0.90),tile*0.25);
 }
 ALBEDO=color;
 ROUGHNESS=clamp(0.80-grain*0.13-metal*0.36,0.22,0.95);
 METALLIC=metal;SPECULAR=0.32;
 EMISSION=paint.rgb*glow;
}
