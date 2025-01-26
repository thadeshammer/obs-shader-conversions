// Interstellar
// Hazel Quantock
// This code is licensed under the CC0 license http://creativecommons.org/publicdomain/zero/1.0/

// https://www.shadertoy.com/view/Xdl3D2

// converted by thades - 2025.01.26
// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions


// Gamma correction
#define gamma_correct 2.2

uniform float density_threshold <
    string label = "Density";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 1.0;
    float step = 0.05;
> = 1.0;

uniform float star_tightness <
    string label = "Slimming";
    string widget_type = "slider";
    float minimum = 0.05;
    float maximum = 200.0;
    float step = 0.05;
> = 190.0;

uniform bool weird_mode <
    string label = "Weird";
> = false;


float3 to_gamma(float3 col) {
	// convert back into colour values, so the correct light will come out of the monitor
    float gc = 1.0/gamma_correct;
	return pow( col, float3(gc, gc, gc) );
}


// https://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
// A single iteration of Bob Jenkins' One-At-A-Time hashing algorithm.
uint hash(uint x) {
    // https://stackoverflow.com/a/17479300/19677371
    x += (x << 10u);
    x ^= (x >> 6u);
    x += (x << 3u);
    x ^= (x >> 11u);
    x += (x << 15u);
    return x;
}


float floatConstruct(uint m) {
    // https://stackoverflow.com/a/17479300/19677371
    // Construct a float with half-open range [0:1] using low 23 bits.
    // All zeroes yields 0.0, all ones yields the next smallest representable value below 1.0.
    const uint ieeeMantissa = 0x007FFFFF; // binary32 mantissa bitmask
    const uint ieeeOne      = 0x3F800000; // 1.0 in IEEE binary32

    m &= ieeeMantissa;                    // Keep only mantissa bits (fractional part)
    m |= ieeeOne;                         // Add fractional part to 1.0

    float f = asfloat(m);                 // Range [1:2] (HLSL equivalent of uintBitsToFloat)
    return f - 1.0;                       // Range [0:1]
}

float random(float x) { return floatConstruct(hash(asuint(x))); }


float gold_noise(float2 xy, float seed){
    // https://stackoverflow.com/a/28095165/19677371
    float phi = 1.61803398874989484820459;  // Φ = Golden Ratio   
    return frac(tan(distance(xy*phi, xy)*seed)*xy.x);
}


float4 mainImage(VertData v_in) : TARGET
{
    float3 zed3 = float3(0.,0.,0.);

	float3 ray;
	ray.xy = 2.0 * (v_in.pos.xy - uv_size.xy * .5) / uv_size.x;
	ray.z = 1.0;

	float offset = elapsed_time*.5;	
	float speed2 = (cos(offset)+1.0)*2.0;
	float speed = speed2+.1;
	offset += sin(offset)*.96;
	offset *= 2.0;
	
	float3 col = float3(0., 0., 0.);
	
	float3 stp = ray/max(abs(ray.x),abs(ray.y));
	
	float3 pos = 2.0*stp+.5;
	for ( int i=0; i < 20; i++ )
	{
        float seed = random(pos.x) * i;
        float z = gold_noise( float2(pos.xy), seed );

        if (z > density_threshold) continue;

		z = frac(z-offset);
		float d = 50.0*z-pos.z;

        float t_factor = star_tightness;
        if (weird_mode) t_factor = 1.0 / star_tightness;
		float weight = pow(
                            max(0.0,1.0- t_factor * length(frac(pos.xy)-.5)),
                            2.0
                        );

		float3 c = max(
                        zed3,
                        float3( 1.0-abs(d+speed2*.5)/speed,
                                1.0-abs(d)/speed,1.0-abs(d-speed2*.5)/speed
                        )
                    );

		col += (1.0-z) * c * weight;
		pos += stp;
	}
	
	return float4(to_gamma(col),1.0);
}