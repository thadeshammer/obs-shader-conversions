// Noise animation - Electric
// by nimitz (stormoid.com)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

//The domain is displaced by two fbm calls one for each axis.
//Turbulent fbm (aka ridged) is used for better effect.

// From: https://www.shadertoy.com/view/ldlXRS

// Converted by thades
//  Parameterized practically everything that seemed fun.
//  Replaced noise texture load with parameterized noise function.

// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions

#define time    elapsed_time * 0.15
#define tau     6.2831853
#define PI      3.1415926

#define mod(x,y) ((x) - (y) * floor((x)/(y)))

uniform float4 base_color <
    string label = "Color";
> = {0.2, 0.1, 0.4, 1.0};

uniform float alpha_value <
    string label = "Alpha";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 1.0;
    float step = 0.05;
> = 1.0;

uniform float amplitude <
    string label = "FBM Intensity (0.1)";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 100.0;
    float step = 0.05;
> = 0.1;

uniform float amplitude_scaling <
    string label = "FBM amp scaling (2.0)";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 1000.0;
    float step = 0.05;
> = 2.0;

uniform float frequency_scaling <
    string label = "FBM frequency scaling (2.0)";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 1000.0;
    float step = 0.05;
> = 2.0;

uniform float rate <
    string label = "Ring Rate (5.0)";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 100.0;
    float step = 0.05;
> = 5.0;

uniform float noise_rotation <
    string label = "Noise Rotation (0.2)";
    string widget_type = "slider";
    float minimum = -200.0;
    float maximum = 200.0;
    float step = 0.01;
> = 0.2;

uniform float noise_jitter <
    string label = "Noise Jitter (1.6)";
    string widget_type = "slider";
    float minimum = -200.0;
    float maximum = 200.0;
    float step = 0.1.;
> = 1.6;

uniform float noise_ripple <
    string label = "Noise Ripple (1.7)";
    string widget_type = "slider";
    float minimum = -200.0;
    float maximum = 200.0;
    float step = 0.1;
> = 1.7;

uniform float hash_seed_x <
    string label = "Noise Seed X (127.1)";
    string widget_type = "slider";
    float minimum = 1.0;
    float maximum = 500.0;
    float step = 1.0;
> = 127.1;

uniform float hash_seed_y <
    string label = "Noise Seed Y (311.7)";
    string widget_type = "slider";
    float minimum = 1.0;
    float maximum = 500.0;
    float step = 1.0;
> = 311.7;

uniform float chaos_factor <
    string label = "Chaos Factor (43758)";
    string widget_type = "slider";
    float minimum = 10000.0;
    float maximum = 100000.0;
    float step = 100.0;
> = 43758.0; // = 43758.5453;

uniform float interpolation_a <
    string label = "Interpolation A (3.0)";
    string widget_type = "slider";
    float minimum = 1.0;
    float maximum = 5.0;
    float step = 0.1;
> = 3.0;

uniform float interpolation_b <
    string label = "Interpolation B (2.0)";
    string widget_type = "slider";
    float minimum = 1.0;
    float maximum = 5.0;
    float step = 0.1;
> = 2.0;

uniform bool use_golden_ratio <
    string label = "Alternate Noise Function";
> = false;


float2x2 makem2(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return float2x2(c,-s,s,c);
}

float hash(float2 p) {
    float2 hash_seeds = float2(hash_seed_x, hash_seed_y);
    return frac(sin(dot(p, hash_seeds)) * chaos_factor);
}

float noise(float2 p) {
    // static noise function, the o.g. imports a texture image.

    float2 i = floor(p);       // Integer part of p
    float2 f = frac(p);        // Fractional part of p

    // Four corners of the grid
    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));

    // Interpolate between grid points
    float2 u = f * f * (interpolation_a - interpolation_b * f);
    return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
}

float gold_noise(float2 xy, float seed){
    // https://stackoverflow.com/a/28095165/19677371
    float phi = 1.61803398874989484820459;  // Φ = Golden Ratio
    return frac(tan(distance(xy*phi, xy)*seed)*xy.x);
}

/*
    Fractal Brownian Motion

    "FBM is a technique that combines multiple layers of noise (called octaves)
    at increasing frequencies and decreasing amplitudes. The result is visually
    richer and more natural than single-layer noise."
*/
float fbm(float2 p)
{	
	float z=amplitude;     // amplitude scaling
	float result_accum  = 0.;  // accumulator
	float2 bp = p;  // base position

	for (float i= 1.; i < 6.; i++) // each loop is an "octave" or layer of noise
	{
        if (use_golden_ratio) {
            result_accum += abs((gold_noise(p, noise(p))-0.5)*2.)/z;
        } else {
            result_accum += abs((noise(p)-0.5)*2.)/z;
        }

		z *= amplitude_scaling;
		p *= frequency_scaling;
	}
	return result_accum;
}

float dualfbm(float2 p)
{
    //get two rotated fbm calls and displace the domain
	float2 p2 = p*.7;
    float2 basis = float2(fbm(p2-time*noise_jitter),fbm(p2+time*noise_ripple));
	basis = (basis-.5)*.2;
	p += basis;
	
	//coloring
    return fbm(mul(p, makem2(time*noise_rotation)));
}

float circ(float2 p) 
{
	float r = length(p);
	r = log(sqrt(r));
	return abs(mod(r*4.,tau)-3.14)*3.+.2;
}

float4 mainImage(VertData v_in) : TARGET
{
	//setup system
	float2 p = v_in.pos.xy / uv_size.xy-0.5;
	p.x *= uv_size.x/uv_size.y;
	p*=4.;

    float rz = dualfbm(p);
	
	//rings
	p /= exp(mod(time * rate, PI));
	rz *= pow(abs((0.1-circ(p))),.9);
	
	//final color
	float4 col = base_color/rz;
    col = pow(abs(col), float4(0.99, 0.99, 0.99, 1.));
    col.a = alpha_value;
	return col;
}