shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, shadows_disabled;
// Sculpted gradients and direct lighting keep the face readable. The instance
// still casts a ground shadow; tiny hair/eyelid shadows do not dirty the face.
// glTF vertex colors are linear. Blender exports UV V as 1-V.
uniform bool sentinel_palette=false;
uniform float paint_gain=1.0;
void fragment(){
 vec3 paint=COLOR.rgb;
 if(OUTPUT_IS_SRGB){
  paint=mix(12.92*paint,1.055*pow(paint,vec3(1.0/2.4))-0.055,step(vec3(0.0031308),paint));
 }
 if(sentinel_palette && UV2.x>0.26 && UV2.x<0.30){
  float value=max(paint.r,max(paint.g,paint.b));
  paint=vec3(0.38,0.16,0.62)*value*1.35;
 }
 ALBEDO=paint*paint_gain;
 METALLIC=clamp(UV2.x*0.7,0.0,0.50);
 ROUGHNESS=clamp(1.0-UV2.y,0.44,0.96);
 SPECULAR=0.20;
}
