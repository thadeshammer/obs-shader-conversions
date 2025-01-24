// Created by anatole duprat - XT95/2013
// https://www.shadertoy.com/view/MdX3zr
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Converted for OBS by thadeshammer - 2025.01.24
// https://twitch.tv/thadeshammer

#define mix lerp

uniform float fovX = 1.6;   // Horizontal field of view
uniform float tiltZ = -1.5; // Forward tilt of the rays

// best guesses about epsilon or epsilon usage in the raymarch() function:
// epsilon is used to adjust distance for marching, ensuring raymarch doesn't stop too early by
// slightly inflating the distance returned by scene()
// also used to stop the raymarch: once distance d is smaller than epsilon, the ray is
// "close enough" to the surface or "inside" the scene geometry
uniform float epsilon = 0.02;

// Camera position
uniform float cameraX = 0.0;
uniform float cameraY = -2.0;
uniform float cameraZ = 4.0;

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
	float d = 0.0; // distance tracking
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
	
    float3 org = float3(cameraX, cameraY, cameraZ);

    float3 dir = normalize(float3(v.x * fovX, -v.y, tiltZ));
	
	float4 p = raymarch(org, dir);
	float glow = p.w;
	
	float4 col = mix(float4(1.,.5,.1,1.), float4(0.1,.5,1.,1.), p.y*.02+.4);
	
    float val = pow(glow*2.,4.);
    float4 zed = float4(0., 0., 0., 0.);
    float4 ret = mix(zed, col, val);

    return ret;

    // original return
	// return mix(float4(0.), col, pow(glow*2.,4.));

    // an alternate return that was commented out in original code
	//fragColor = mix(float4(1.), mix(float4(1.,.5,.1,1.),float4(0.1,.5,1.,1.),p.y*.02+.4), pow(glow*2.,4.));
}
