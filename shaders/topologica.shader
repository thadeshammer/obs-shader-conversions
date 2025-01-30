// https://www.shadertoy.com/view/4djXzz
// ----------------------------------------------------------------------------------------
// License CC0 - http://creativecommons.org/publicdomain/zero/1.0/
// To the extent possible under law, the author(s) have dedicated all copyright and related and
// neighboring  rights to this software to the public domain worldwide. This software is distributed
// without any warranty.
// ----------------------------------------------------------------------------------------
// ^ This means do ANYTHING YOU WANT with this code. Because we are programmers, not lawyers.
// -Otavio Good

// adapted for obs-shaderfilter by thades - 2025.01.30
// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions

uniform float4 COLOR <
    string label = "Color";
> = {0.01, 0.1, 1., 1.};

uniform float SPEED <
    string label = "Speed (0.01)";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = .08;
    float step = .001;
> = .01;

uniform float POMP <
    string label = "Pomp (0.05)";
    string widget_type = "slider";
    float minimum = 0.001;
    float maximum = 5.0;
    float step = .001;
> = .05;

uniform float CIRCUMSTANCE <
    string label = "Circumstance (1.9)";
    string widget_type = "slider";
    float minimum = 0.001;
    float maximum = 10.0;
    float step = .001;
> = 1.9;

uniform string NOTE<
    string label = "NOTE";
    string widget_type = "info";
> = "Max Depth and Steps are best when near-ish one another, but you do you.";

uniform float MAX_DEPTH <
    string label = "Max Depth (70.)";
    string widget_type = "slider";
    float minimum = 1.0;
    float maximum = 200.;
    float step = .1;
> = 70.;

uniform int STEPS <
    string label = "Ray March Steps (37)";
    string widget_type = "slider";
    int minimum = 1;
    int maximum = 200.;
    int step = 1;
> = 37;

#define mix         lerp
#define PI          3.14159265
#define saturate(a) clamp(a, 0.0, 1.0)
#define zeroOne     float2(0.0, 1.0)

// various noise functions
float Hash3d(float3 uv)
{
    float f = uv.x + uv.y * 37.0 + uv.z * 521.0;
    return frac(cos(f*3.333)*100003.9);
}

float mixP(float f0, float f1, float a)
{
    return mix(f0, f1, a*a*(3.0-2.0*a));
}

float noise(float3 uv)
{
    float3 fr = frac(uv.xyz);
    float3 fl = floor(uv.xyz);
    float h000 = Hash3d(fl);
    float h100 = Hash3d(fl + zeroOne.yxx);
    float h010 = Hash3d(fl + zeroOne.xyx);
    float h110 = Hash3d(fl + zeroOne.yyx);
    float h001 = Hash3d(fl + zeroOne.xxy);
    float h101 = Hash3d(fl + zeroOne.yxy);
    float h011 = Hash3d(fl + zeroOne.xyy);
    float h111 = Hash3d(fl + zeroOne.yyy);
    return mixP(
        mixP(mixP(h000, h100, fr.x), mixP(h010, h110, fr.x), fr.y),
        mixP(mixP(h001, h101, fr.x), mixP(h011, h111, fr.x), fr.y)
        , fr.z);
}

float Density(float3 p)
{
    float final = noise(p*0.06125);
    float other = noise(p*0.06125 + 1234.567);
    other -= 0.5;
    final -= 0.5;
    final = 0.1/(abs(final*final*other));
    final += 0.5;
    return final*0.0001;
}

float4 mainImage(VertData v_in) : TARGET
{
	// ---------------- First, set up the camera rays for ray marching ----------------
    float2 fragCoord = float2(v_in.pos.x, uv_size.y - v_in.pos.y);
	float2 uv = fragCoord.xy/uv_size.xy * 2.0 - 1.0;

	// Camera up vector.
	float3 camUp=float3(0,1,0); // vuv

	// Camera lookat.
	float3 camLookat=float3(0,0.0,0);	// vrp

    float mx = elapsed_time * SPEED;
    float my = sin(elapsed_time * SPEED) * 0.2 + 0.2; // *PI/2.01;
    float3 camPos=float3(cos(my)*cos(mx),sin(my),cos(my)*sin(mx))*(200.2);

	// Camera setup.
	float3 camVec=normalize(camLookat - camPos);//vpn
	float3 sideNorm=normalize(cross(camUp, camVec));	// u
	float3 upNorm=cross(camVec, sideNorm);//v
	float3 worldFacing=(camPos + camVec);//vcv
	float3 worldPix = worldFacing + uv.x * sideNorm * (uv_size.x/uv_size.y) + uv.y * upNorm;//scrCoord
	float3 relVec = normalize(worldPix - camPos);//scp

	// --------------------------------------------------------------------------------
	float t = 0.0;
	float inc = 0.02;

	float3 pos = float3(0.,0.,0.);
    float density = 0.0;
	// ray marching time
    for (int i = 0; i < STEPS; i++)	// This is the count of how many times the ray actually marches.
    {
        if ((t > MAX_DEPTH)) break;
        pos = camPos + relVec * t;
        float temp = Density(pos);

        inc = CIRCUMSTANCE + temp*POMP;	// add temp because this makes it look extra crazy!
        density += temp * inc;
        t += inc;
    }

	// --------------------------------------------------------------------------------
	// Now that we have done our ray marching, let's put some color on this.
	// float3 finalColor = float3(0.01,0.1,1.0)* density*0.2;

    // If any of the RGB channels set by the user are too low, the effect looks like crap
    // so we maintain a very slight floor.
    float3 finalColor = max(COLOR.xyz, 0.0000001) * density * 0.2;

	// output the final color with sqrt for "gamma correction"
	return float4(sqrt(clamp(finalColor, 0.0, 1.0)),1.0);
}
