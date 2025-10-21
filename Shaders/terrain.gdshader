shader_type spatial;

uniform int resolution;
uniform float spacing;
uniform float amplitude;
uniform float heights[1089];
uniform int normals[1089];

vec3 unpack_normal(int normal_i) {
    // const float PI = 3.14159265359;
    const float MAX_INT = 65535.0; // 16-bit max

    // Extract lower and upper 16 bits
    int pitch_i = normal_i & 0xFFFF;
    int yaw_i   = (normal_i >> 16) & 0xFFFF;

    // Convert back to radians
    float pitch = (float(pitch_i) / MAX_INT) * PI - PI/2.0;
    float yaw   = (float(yaw_i) / MAX_INT) * 2.0*PI - PI;

    // Convert spherical to Cartesian
    float cos_pitch = cos(pitch);
    vec3 normal;
    normal.x = sin(yaw) * cos_pitch;
    normal.y = sin(pitch);
    normal.z = cos(yaw) * cos_pitch;

    return normalize(normal);
}

void vertex() {
	// Called for every vertex the material is visible on.
	int vid = int(VERTEX_ID);
	int x = vid % (resolution + 1);
	int z = vid / (resolution + 1);
	
	vec3 pos = vec3(float(x) * spacing, 0.0, float(z) * spacing);
	
	pos.y = heights[vid]; //* amplitude;

	//pos.x += INSTANCE_CUSTOM.x;
	//pos.y += INSTANCE_CUSTOM.y;
	
	vec3 normal = unpack_normal(normals[vid]);
	
	VERTEX = pos;
	NORMAL = normal;
}

void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = vec3(0.45, 0.354, 0.257);
}


//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
