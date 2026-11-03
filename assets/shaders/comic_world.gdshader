shader_type spatial;
render_mode world_vertex_coords, diffuse_burley, specular_disabled;
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
 // Broad painted surfaces replace the weathered dark-fantasy texture.
 vec3 color=paint.rgb;
 if(pavement){
  vec2 p=vec2((stone_position.x+4.5)/1.5,stone_position.z/3.0);
  p.x+=mod(floor(p.y),2.0)*0.5;
  vec2 cell=floor(p);vec2 local=fract(p);
  vec2 edges=min(local,1.0-local);
  float seam=1.0-smoothstep(0.006,0.020,min(edges.x,edges.y));
  float tile=hash(vec3(cell,1.0));
  color*=mix(0.96,1.04,tile)*(1.0-seam*0.18);
 }
 // Compatibility rendering has a narrow output range. Reserve the brightest
 // values for collectibles, windows and action cues instead of broad walls.
 ALBEDO=color*0.70;
 ROUGHNESS=0.68;
 METALLIC=metal*0.15;SPECULAR=0.22;
 EMISSION=paint.rgb*glow*0.30;
}
