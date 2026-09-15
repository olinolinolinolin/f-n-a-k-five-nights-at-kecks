shader_type spatial;
render_mode blend_add, cull_back, depth_draw_never, shadows_disabled, unshaded;

// === Color gradient (bottom -> tip), like real fire ===
uniform vec4 color_base : source_color = vec4(0.1, 0.3, 1.0, 1.0);   // hot core near body
uniform vec4 color_mid  : source_color = vec4(0.4, 0.7, 1.0, 1.0);   // mid-flame
uniform vec4 color_tip  : source_color = vec4(1.0, 1.0, 1.0, 1.0);   // wispy tip, near-white/fades out

uniform float intensity : hint_range(0.0, 5.0) = 2.0;
uniform float fresnel_power : hint_range(0.1, 8.0) = 1.8;

// === Flame shaping ===
uniform sampler2D noise_texture : hint_default_black; // tileable noise, e.g. NoiseTexture2D w/ FastNoiseLite
uniform float rise_speed : hint_range(0.0, 5.0) = 1.5;       // how fast flame licks travel upward
uniform float turbulence_scale : hint_range(0.1, 10.0) = 4.0;
uniform float flame_height : hint_range(0.5, 10.0) = 2.0;    // world-space height the flame tapers over
uniform float taper_sharpness : hint_range(0.5, 6.0) = 2.5;  // higher = flame pinches to a point faster
uniform float flicker_speed : hint_range(0.0, 15.0) = 8.0;
uniform float tip_break_up : hint_range(0.0, 2.0) = 0.8;     // how much noise fragments the tips into separate tongues

// === Vertex shaping: pulls verts inward as they go up + adds flicker wobble ===
uniform float tip_pinch : hint_range(0.0, 1.0) = 0.4; // shrinks silhouette toward top so it reads as tapering flame
uniform float wobble_amount : hint_range(0.0, 0.3) = 0.05;

varying float height_ratio; // 0 at base, 1 at top of flame_height
varying vec3 obj_vertex;

void vertex() {
	obj_vertex = VERTEX;
	float h = clamp(VERTEX.y / flame_height, 0.0, 1.0);
	height_ratio = h;

	// Pinch the silhouette inward as it rises so the mesh itself reads as flame-shaped
	float pinch = 1.0 - (pow(h, taper_sharpness) * tip_pinch);
	VERTEX.xz *= pinch;

	// Flicker wobble, stronger higher up (tips waver more than the base)
	float t = TIME * flicker_speed;
	float wobble = sin(VERTEX.y * 6.0 + t + VERTEX.x * 3.0) * wobble_amount * h;
	VERTEX.x += wobble;
	VERTEX.z += cos(VERTEX.y * 5.0 + t * 0.8) * wobble_amount * h;
}

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), fresnel_power);

	// Turbulent noise scrolling upward, sampled at increasing frequency near the tip
	// so tongues look thin/wispy up top and broad/solid at the base
	vec2 uv = UV * turbulence_scale + vec2(0.0, -TIME * rise_speed);
	vec2 uv2 = UV * turbulence_scale * 2.3 + vec2(0.15, -TIME * rise_speed * 1.8);
	float n1 = texture(noise_texture, fract(uv)).r;
	float n2 = texture(noise_texture, fract(uv2)).r;
	float turbulence = mix(n1, n2, 0.5 + 0.5 * height_ratio);

	// Break the shape apart near the tip so it looks like separate flame tongues,
	// rather than a uniform glowing outline
	float tip_mask = smoothstep(0.0, 1.0, height_ratio);
	float break_up = mix(1.0, turbulence, tip_mask * tip_break_up);
	float shape = clamp(1.0 - tip_mask * (1.0 - turbulence * 1.3), 0.0, 1.0) * break_up;

	float flicker = 0.85 + 0.15 * sin(TIME * flicker_speed + turbulence * 6.28 + height_ratio * 10.0);

	float mask = fresnel * shape * flicker;
	mask = clamp(mask, 0.0, 1.0);

	// Color ramps base -> mid -> tip along height, like real fire cooling as it rises
	vec3 color = mix(color_base.rgb, color_mid.rgb, clamp(height_ratio * 2.0, 0.0, 1.0));
	color = mix(color, color_tip.rgb, clamp((height_ratio - 0.5) * 2.0, 0.0, 1.0) * turbulence);

	ALBEDO = color;
	EMISSION = color * intensity * mask;
	// Fade alpha out near the very top so tongues dissipate instead of cutting off hard
	ALPHA = mask * (1.0 - smoothstep(0.85, 1.0, height_ratio) * 0.6);
}