shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;

uniform float metallic;
uniform sampler2D texture_metallic : hint_white;
uniform vec4 metallic_texture_channel;

uniform float roughness : hint_range(0, 1);
uniform sampler2D texture_roughness : hint_white;
uniform vec4 roughness_texture_channel;

uniform float specular;

uniform sampler2D texture_normal : hint_normal;
uniform float normal_scale : hint_range(-16, 16);

uniform vec3 uv_scale;

uniform float speed = 1;
uniform float delta_time = 0; // Updated inside '_process()' in "hurdle_game.gd"

void vertex() {
	UV = UV*uv_scale.xy - vec2(delta_time * speed, 0);
}

void fragment() {
	ALBEDO = albedo.rgb * texture(texture_albedo, UV).rgb;
	METALLIC = dot(texture(texture_metallic, UV), metallic_texture_channel) * metallic;
	ROUGHNESS = dot(texture(texture_roughness, UV), roughness_texture_channel) * roughness;
	SPECULAR = specular;

	NORMALMAP = texture(texture_normal, UV).rgb;
	NORMALMAP_DEPTH = normal_scale;
}