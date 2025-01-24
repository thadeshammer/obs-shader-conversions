// Created by anatole duprat - XT95/2013
// https://www.shadertoy.com/view/MdX3zr
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Converted for OBS by thades - 2025.01.24
// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions

#define mix lerp

uniform float4 primary_color<
    string label = "Primary";
> = {0.0, 0.0, 0.0, 0.0};

uniform float4 flame_tip_color<
    string label = "Flame Tip";
> = {1.0, 0.5, 0.1, 1.0};


uniform float4 inner_core_color<
    string label = "Inner Core";
> = {0.1, 0.5, 1.0, 1.0};

uniform float glow_scale<
    string label = "Glow Scale";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 10.0;
    float step = 0.01;
> = 2.0;

uniform float glow_exponent<
    string label = "Glow Exponent";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 10.0;
    float step = 0.1;
> = 4.0;

uniform float intensity<
    string label = "Mix Intensity";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 0.5;
    float step = 0.001;
> = .02;

uniform float bias<
    string label = "Mix Bias";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 10.0;
    float step = 0.001;
> = .4;

uniform float fovX<
    string label = "Squeeze";
    string widget_type = "slider";
    float minimum = -20.0;
    float maximum = 20.0;
    float step = 0.1;
> = 1.6;   // Horizontal field of view

uniform float tiltZ<
    string label = "Zoom";
    string widget_type = "slider";
    float minimum = -20.0;
    float maximum = 20.0;
    float step = 0.1;
> = -1.5; // Forward "tilt" of the rays

// best guesses about epsilon or epsilon usage in the raymarch() function:
// epsilon is used to adjust distance for marching, ensuring raymarch doesn't stop too early by
// slightly inflating the distance returned by scene()
// also used to stop the raymarch: once distance d is smaller than epsilon, the ray is
// "close enough" to the surface or "inside" the scene geometry
uniform float epsilon<
    string label = "Epsilon";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 0.3;
    float step = 0.001;
> = 0.02;

// The origin of the ray, i.e. the camera position
uniform float cameraX<
    string label = "Origin X";
    string widget_type = "slider";
    float minimum = -20.0;
    float maximum = 20.0;
    float step = 0.1;
> = 0.0;

uniform float cameraY<
    string label = "Origin Y";
    string widget_type = "slider";
    float minimum = -20.0;
    float maximum = 20.0;
    float step = 0.1;
> = -2.0;

uniform float cameraZ<
    string label = "Origin Z";
    string widget_type = "slider";
    float minimum = -20.0;
    float maximum = 20.0;
    float step = 0.1;
> = 4.0;

float noise(float3 p) //Thx to Las^Mercury
{
	float3 i = floor(p);
	float4 a = dot(i, float3(1., 57., 21.)) + float4(0., 57., 21., 78.);
	float3 f = cos((p-i)*acos(-1.))*(-.5)+.5;
	a = mix(sin(cos(a)*a),sin(cos(1.+a)*(1.+a)), f.x);
	a.xy = mix(a.xz, a.yw, f.y);
	return mix(a.x, a.y, f.z);
}

float sphere(float3 p, float4 spr)
{
	return length(spr.xyz-p) - spr.w;
}

float flame(float3 p)
{
	float d = sphere(p*float3(1.,.5,1.), float4(.0,-1.,.0,1.));
	return d + (noise(p+float3(.0,elapsed_time*2.,.0)) + noise(p*3.)*.5)*.25*(p.y) ;
}

float scene(float3 p)
{
	return min(100.-length(p) , abs(flame(p)) );
}

float4 raymarch(float3 org, float3 dir)
{
	float d = 0.0; // ray distance tracking
    float glow = 0.0;

	float3  p = org;
	bool glowed = false;
	
	for(int i=0; i<64; i++)
	{
		d = scene(p) + epsilon;
		p += d * dir;
		if( d>epsilon )
		{
			if(flame(p) < .0)
				glowed=true;
			if(glowed)
       			glow = float(i)/64.;
		}
	}
	return float4(p,glow);
}

float4 mainImage( VertData v_in ) : TARGET
{
	float2 v = -1.0 + 2.0 * float2(v_in.pos.x, uv_size.y - v_in.pos.y) / uv_size.xy;
	v.x *= uv_size.x/uv_size.y;
	
    // ray origin
    float3 org = float3(cameraX, cameraY, cameraZ);

    // ray direction from origin ("camera") to the scene
    float3 dir = normalize(float3(v.x * fovX, -v.y, tiltZ));
	
	float4 p = raymarch(org, dir);
	float glow = p.w;
	
    // mix() here interpolates between two colors to create the visual glow effect
    // factor determines the mix:
    // - when factor is 0.0, result is 100% base color
    // - when factor is 1.0, result is 100% inner_core_color
    float factor = p.y * intensity + bias;
	float4 color_blend = mix(flame_tip_color, inner_core_color, factor);
	
    float glow_amp = pow(glow*glow_scale,glow_exponent); // amplify the glow effect

    float4 ret = mix(primary_color, color_blend, glow_amp);

    return ret;
}
