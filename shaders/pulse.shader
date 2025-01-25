// Noise animation - Electric
// by nimitz (stormoid.com)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

//The domain is displaced by two fbm calls one for each axis.
//Turbulent fbm (aka ridged) is used for better effect.

// From: https://www.shadertoy.com/view/ldlXRS
// Converted by thades
// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions

#define time    elapsed_time * 0.15
#define tau     6.2831853
#define PI      3.1415926

#define mod(x,y) ((x) - (y) * floor((x)/(y)))

uniform float rate<
    string label = "Ring Rate (5.0)";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 100.0;
    float step = 0.05;
> = 5.0;

uniform float noise_rotation<
    string label = "Noise Rotation (0.2)";
    string widget_type = "slider";
    float minimum = -200.0;
    float maximum = 200.0;
    float step = 0.01;
> = 0.2;

uniform float noise_jitter<
    string label = "Noise Jitter (1.6)";
    string widget_type = "slider";
    float minimum = -200.0;
    float maximum = 200.0;
    float step = 0.1.;
> = 1.6;

uniform float noise_ripple<
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

float fbm(float2 p)
{	
	float z=2.;
	float rz = 0.;
	float2 bp = p;
	for (float i= 1.; i < 6.; i++)
	{
		rz+= abs((noise(p)-0.5)*2.)/z;
		z = z*2.;
		p = p*2.;
	}
	return rz;
}

float dualfbm(float2 p)
{
    //get two rotated fbm calls and displace the domain
	float2 p2 = p*.7;
	//float2 basis = float2(fbm(p2-time*1.6),fbm(p2+time*1.7));
                                    // jitter         ripple
    float2 basis = float2(fbm(p2-time*noise_jitter),fbm(p2+time*noise_ripple));
	basis = (basis-.5)*.2;
	p += basis;
	
	//coloring
	// return fbm(mul(p, makem2(time*0.2)));
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
	float3 col = float3(.2, 0.1, 0.4)/rz;
	col=pow(abs(col),float3(.99, .99, .99));
	return float4(col,1.);
}