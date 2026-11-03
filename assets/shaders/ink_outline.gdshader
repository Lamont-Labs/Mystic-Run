shader_type spatial;
render_mode unshaded, cull_front;
uniform float thickness = 0.007;
void vertex(){VERTEX+=NORMAL*thickness;}
void fragment(){ALBEDO=vec3(0.055,0.035,0.13);}
