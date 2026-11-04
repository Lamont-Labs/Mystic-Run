shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
void fragment() {
    // One shared publisher atlas, with the same broad matte response as the road.
    ALBEDO = texture(atlas, UV).rgb * 0.78;
    ROUGHNESS = 0.86;
    SPECULAR = 0.18;
}
