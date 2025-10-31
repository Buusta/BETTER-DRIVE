shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled;
stencil_mode read, 1, compare_equal;

void vertex() { 
	POSITION = vec4(VERTEX, 1.0); 
}

void fragment() {
    ALBEDO = vec3(1.0); // White
}
