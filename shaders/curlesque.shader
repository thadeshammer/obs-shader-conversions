// https://www.shadertoy.com/view/lsKyWV
// Created by Alex Kluchikov (klk) 2018-04-11

// Subject to Shadertoy's Default License CC BY-NC-SA 3.0
// https://www.shadertoy.com/terms
// https://creativecommons.org/licenses/by-nc-sa/3.0/deed.en

// Converted for obs-shaderfilter by thades
// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions

uniform float SPEED <
    string label = "speed (1.0)";
    string widget_type = "slider";
    float minimum = .01;
    float maximum = 10.;
    float step = .01;
> = 1.;

uniform int FUNK_FACTOR<
    string label = "mood?";
    string widget_type = "select";
    int    option_0_value = 0;
    string option_0_label = "get groovy";
    int    option_1_value = 1;
    string option_1_label = "get funky";
    int    option_2_value = 2;
    string option_2_label = "hogwild";
> = 0;

uniform float4 SEED_COLOR<
    string label = "seed color";
> = {0.5, 0.3, 0.6, 1.0};

#define pi 3.14159265359

#define iTime elapsed_time * SPEED

float saw(float x)
{
    return abs(frac(x)-0.5)*2.0;
}

float dw(float2 p, float2 c, float t)
{
    return sin(length(p-c)-t);
}

float dw1(float2 uv)
{
    float v=0.0;
    float t= elapsed_time * 2.0;
    v+=dw(uv,float2(sin(t*0.07)*30.0,cos(t*0.04)*20.0),t*1.3);
    v+=dw(uv,float2(cos(t*0.13)*30.0,sin(t*0.14)*20.0),t*1.6+1.0);
    v+=dw(uv,float2( 18,-15),t*0.7+2.0);
    v+=dw(uv,float2(-18, 15),t*1.1-1.0);
    return v/4.0;
}

float fun(float x, float y)
{
	return dw1(float2(x-0.5,y-0.5)*80.0);
}

float3 duv(float2 uv)
{
    float x=uv.x;
    float y=uv.y;
    float v=fun(x,y);
    float d=1.0/400.0;
	float dx=(v-fun(x+d,y))/d;
	float dy=(v-fun(x,y+d))/d;
    float a=atan2(dx,dy)/pi/2.0;
    return float3(v,0,(v*4.0+a));
}

float4 mainImage( VertData v_in ) : TARGET
{
    float2 iResolution = uv_size * uv_scale;
    float2 fragCoord = float2(v_in.pos.x, uv_size.y - v_in.pos.y); // flip y-axis GLSL -> HLSL

	float2 uv = fragCoord.xy/iResolution.x;
    float3 h = duv(uv);
    float sp = saw(h.z + iTime * 1.3);

    if (FUNK_FACTOR == 0) {
        sp=clamp((sp-0.25)*2.0,0.5,1.0);
    } else if (FUNK_FACTOR == 1) { 
        sp=clamp((sp-0.25)*2.0,0.5,1.0);    
    } else if (FUNK_FACTOR == 2) {
        sp=(sp>0.5)?0.3:1.0;
        sp=clamp((sp-0.25)*2.0,0.5,1.0);
    }
    
    // return float4((h.x+0.5)*sp, (0.3+saw(h.x+0.5)*0.6)*sp, (0.6-h.x)*sp, 1.0);
    return float4(
                    (h.x + SEED_COLOR.r) * sp,
                    (SEED_COLOR.g + saw(h.x+0.5) *0.6) * sp,
                    (SEED_COLOR.b - h.x) * sp,
                    1.0
                );
}