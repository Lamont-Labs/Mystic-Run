shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, shadows_disabled;
// Sculpted gradients and direct lighting keep the face readable. The instance
// still casts a ground shadow; tiny hair/eyelid shadows do not dirty the face.
// glTF vertex colors are linear. Blender exports UV V as 1-V.
uniform bool sentinel_palette=false;
uniform float paint_gain=1.0;
uniform int character_kind=0; // Knight 0, Gargoyle 1, Witch 2.
uniform sampler2D finish_detail:filter_linear_mipmap,repeat_enable;
uniform float finish_strength:hint_range(0.0,1.0)=1.0;
void fragment(){
 vec3 paint=COLOR.rgb;
 if(OUTPUT_IS_SRGB){
  paint=mix(12.92*paint,1.055*pow(paint,vec3(1.0/2.4))-0.055,step(vec3(0.0031308),paint));
 }
 if(sentinel_palette && UV2.x>0.26 && UV2.x<0.30){
  float value=max(paint.r,max(paint.g,paint.b));
  paint=vec3(0.38,0.16,0.62)*value*1.35;
 }
 // The imported secondary UV contains the source metallic and roughness pair.
 // Classify only known authored regions; skin, eyes and facial details retain
 // their clean paint. No coordinate noise can drift with world movement.
 float metal=UV2.x;
 float rough=1.0-UV2.y;
 float stone=0.0;
 float cloth=0.0;
 float leather=0.0;
 float hair=0.0;
 float membrane=0.0;
 float enamel=0.0;
 float crystal=0.0;
 if(character_kind==0){
  cloth=float(abs(rough-0.93)<0.012 || abs(rough-0.80)<0.009);
  leather=float(abs(rough-0.90)<0.009);
  hair=float(abs(rough-0.87)<0.009);
  enamel=float(abs(metal-0.28)<0.012);
  crystal=float(abs(metal-0.24)<0.012);
 }else if(character_kind==1){
  // Recess stone and the purple sash share a roughness value; their authored
  // green/purple pigments disambiguate them without changing the GLB or rig.
  stone=float(metal<0.01 && rough>0.875 && paint.g>paint.r*1.05);
  cloth=float(abs(rough-0.96)<0.012 && paint.r>paint.g*1.05);
  membrane=float(abs(rough-0.87)<0.009 || abs(rough-0.94)<0.009);
 }else{
  cloth=float(abs(rough-0.90)<0.009 || abs(rough-0.83)<0.009 || (abs(rough-0.86)<0.009 && paint.b>paint.r*1.1));
  leather=float(abs(rough-0.86)<0.009 && paint.b<=paint.r*1.1);
  hair=float(abs(metal-0.06)<0.009 || abs(metal-0.02)<0.009);
  crystal=float(abs(metal-0.10)<0.009 || abs(metal-0.18)<0.009);
 }
 vec2 detail_uv=UV*2.0;
 // Fade fine paint before a texture period is smaller than two screen pixels.
 float footprint=max(length(dFdx(detail_uv)),length(dFdy(detail_uv)));
 // Explicit finite LOD also handles the constant UVs on authored trim plates.
 float detail_lod=clamp(log2(max(footprint*256.0,1.0)),0.0,8.0);
 vec4 detail=textureLod(finish_detail,detail_uv,detail_lod)*2.0-1.0;
 float fine=1.0-smoothstep(0.012,0.045,footprint);
 float strength=finish_strength;
 float paint_detail=stone*detail.r*0.075+cloth*detail.g*0.052*fine+leather*detail.b*0.05*fine+hair*detail.a*0.085*fine+membrane*detail.r*0.035;
 paint*=1.0+paint_detail*strength;
 // Broad directional sheen reads from the chase camera, while fine weave
 // stays deliberately restrained. Metal gets a tighter satin highlight.
 float brushed=metal>0.40 ? 1.0 : 0.0;
 float sheen=hair*(0.035+0.025*cos(UV.x*6.2831853))+enamel*0.018;
 ALBEDO=paint*paint_gain;
 METALLIC=clamp(metal*mix(0.7,1.05,strength),0.0,0.65);
 ROUGHNESS=clamp(rough-brushed*0.10*strength+paint_detail*0.16*strength,mix(0.44,0.26,strength),mix(0.96,0.98,strength));
 SPECULAR=mix(0.20,0.34,(brushed+crystal*0.65)*strength);
 EMISSION=paint*sheen*strength;
}
