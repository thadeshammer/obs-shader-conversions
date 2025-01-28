// 'Warp Speed 2'
// David Hoskins 2015.
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Original:    https://www.shadertoy.com/view/4tjSDt
// Fork of:     https://www.shadertoy.com/view/Msl3WH
//----------------------------------------------------------------------------------------

// Adapted for obs-shaderfilter by thades
// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions


uniform int SPEED <
    string label = "Speed (100)";
    string widget_type = "slider";
    int minimum = 0;
    int maximum = 1000;
    int step = 1;
> = 100; // o.g. default was 58 -thades

uniform float RED_SHIFT <
    string label = "Red (0.2)";
    string widget_type = "slider";
    float minimum = 0.;
    float maximum = 1.0;
    float step = .01;
> = .2;

uniform float GREEN_SHIFT <
    string label = "Green (0.2)";
    string widget_type = "slider";
    float minimum = 0.;
    float maximum = 1.0;
    float step = .01;
> = .4;

uniform float BLUE_SHIFT <
    string label = "Blue (0.2)";
    string widget_type = "slider";
    float minimum = 0.;
    float maximum = 1.0;
    float step = .01;
> = 1.;

uniform float BRIGHT_ACCUM <
    string label = "Brightness Accumulation (0.06)";
    string widget_type = "slider";
    float minimum = .001;
    float maximum = .5;
    float step = .001;
> = .04;

uniform float CHAOS_OFFSET <
    string label = "Chaos Offset (.9)";
    string widget_type = "slider";
    float minimum = 0.;
    float maximum = 1.5;
    float step = .005;
> = .9;

uniform float DIALATION <
    string label = "Dialation (0.025)";
    string widget_type = "slider";
    float minimum = .001;
    float maximum = 5.;
    float step = .001;
> = .025;

uniform float ALPHA_VALUE <
    string label = "Alpha";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 1.0;
    float step = 0.05;
> = 1.0;

float4 mainImage(VertData v_in) : TARGET
{
	float s = 0.0, v = 0.0;
	float2 uv = (v_in.pos / uv_size.xy) * 2. - 1.;

    float time = (elapsed_time - 2.0) * SPEED;
	float3 col = float3(0., 0., 0.);
    float3 init = float3(sin(time * .0032)*.3, .35 - cos(time * .005)*.3, time * 0.002);
	for (int r = 0; r < 100; r++) 
	{
		float3 p = init + s * float3(uv, 0.05);
		p.z = frac(p.z);
        for (int i=0; i < 10; i++)	p = abs(p * 2.04) / dot(p, p) - CHAOS_OFFSET;
		v += pow(dot(p, p), .7) * BRIGHT_ACCUM;

		col +=  float3(
                        v * RED_SHIFT,
                        v * GREEN_SHIFT,
                        v * BLUE_SHIFT) * v * 0.00003;

		s += DIALATION;
	}

	return float4(clamp(col, 0.0, 1.0), ALPHA_VALUE);
}