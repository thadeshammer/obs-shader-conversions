// https://www.shadertoy.com/view/MscXD7
// Original by bleedingtiger2

// Adapted by thades - 2025.01.30
// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions

uniform string NOTE<
    string label = "NOTE";
    string widget_type = "info";
> = "Make a scene with only this in it and load it as a source into another scene.";

uniform int SNOWFLAKE_COUNT <
    string label = "Snowflakes (200)";
    string widget_type = "slider";
    int minimum = 1;
    int maximum = 1000;
    int step = 1;
> = 200;

uniform float SNOW_INTENSITY <
    string label = "Intensity (.2)";
    string widget_type = "slider";
    float minimum = 0.;
    float maximum = 10.;
    float step = .1;
> = .2;

#define mod(x,y) ((x) - (y) * floor((x)/(y)))

#define time elapsed_time

float rnd(float x)
{
    return frac( sin( dot( float2(x+47.49, 38.2467/(x+2.3)),
                           float2(12.9898, 78.233))
                 ) * (43758.5453));
}

float drawCircle(float2 center, float radius, float2 flake_uv)
{
    return 1.0 - smoothstep(0.0, radius, length(flake_uv - center));
}

float4 mainImage(VertData v_in) : TARGET
{
    float2 fragCoord = float2(v_in.pos.x, uv_size.y - v_in.pos.y);
    float2 uv = fragCoord.xy / uv_size.x;
    float4 fragColor = float4(0., 0., 0., 0.); // transparent bg
    float j;
    
    for(int i=0; i<SNOWFLAKE_COUNT; i++)
    {
        j = float(i);

        float noise = rnd(cos(j));
        float speed = 0.3 + noise * (0.7+0.5*cos(j/(float(SNOWFLAKE_COUNT)*0.25)));
        float2 center = 
            float2(
                (0.25-uv.y)*SNOW_INTENSITY+rnd(j)+0.1*cos(time+sin(j)),
                mod(sin(j)-speed*(time*1.5*(0.1+SNOW_INTENSITY)), 0.65)
            );
        float col = 0.9 * drawCircle(center, 0.001+speed*0.012, uv);
        fragColor += float4(col, col, col, col);
    }

    return fragColor;
}