// https://www.shadertoy.com/view/stXSzB
// by bogz 2021-07-10

// Subject to Shadertoy's Default License CC BY-NC-SA 3.0
// https://www.shadertoy.com/terms
// https://creativecommons.org/licenses/by-nc-sa/3.0/deed.en

// Converted for obs-shaderfilter by thades
// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions

uniform float4 CONTRAST_ANCHOR <
    string label = "base";
> = {.7, .7, .7, 1.};

uniform float4 BASE_COLOR <
    string label = "highlight";
> = {.45, .4, .6, 1.};

uniform float BRIGHTNESS <
    string label = "bright (0.6)";
    string widget_type = "slider";
    float minimum = 0;
    float maximum = 1;
    float step = .01;
> = .6;

uniform float ENERGY <
    string label = "speed (0.05)";
    string widget_type = "slider";
    float minimum = 0;
    float maximum = 10;
    float step = .01;
> = .05;


float rand(float2 coords)
{
	return frac(sin(dot(coords, float2(56.3456, 78.3456)) * 5.0) * 10000.0);
}

float noise(float2 coords)
{
	float2 i = floor(coords);
	float2 f = frac(coords);

	float a = rand(i);
	float b = rand(i + float2(1.0, 0.0));
	float c = rand(i + float2(0.0, 1.0));
	float d = rand(i + float2(1.0, 1.0));

	float2 cubic = f * f * (3.0 - 2.0 * f);

	return lerp(a, b, cubic.x) + (c - a) * cubic.y * (1.0 - cubic.x) + (d - b) * cubic.x * cubic.y;
}

float fbm(float2 coords)
{
	float value = 0.0;
	float scale = 0.5;

	for (int i = 0; i < 5; i++)
	{
		value += noise(coords) * scale;
		coords *= 4.0;
		scale *= 0.5;
	}

	return value;
}

float value(float2 uv)
{
    float pixels = 1024.0;
    float dx = 10.0 * (1.0 / pixels);
    float dy = 10.0 * (1.0 / pixels);
  

    float final = 0.0;
    
    float2 uvc = uv;
    
    float2 Coord = float2(dx * floor(uvc.x / dx),
                          dy * floor(uvc.y / dy));

    
    for (int i =0;i < 3; i++)
    {
        float q = fbm(Coord + elapsed_time * ENERGY + float2(i, i));
        float2 motion = float2(q, q);
        final += fbm(Coord + motion + float2(i, i));
    }

	return final / 3.0;
}

float2 transform_and_normalize_uv(float2 pos) {
    // pass this v_in.pos
    // Moves origin to screen center, normalizes [-1., 1.] and  flip y-axis to behave like GLSL
    float2 fragCoord = float2(pos.x, uv_size.y - pos.y); // flip y-axis
    float2 uv = fragCoord / uv_size.xy; // normalize coordinates to [0,1].
    uv = uv * 2.0 - 1.0; // map to -1, 1
    uv.x *= uv_size.x / uv_size.y; // stretch aspect ratio for x to compensate
    return uv;
}

float4 mainImage( VertData v_in ) : TARGET
{
    float2 uv = transform_and_normalize_uv(v_in.pos);
    
    float3 contrast_value = mul(-1, float3(1. - CONTRAST_ANCHOR.r, 1. - CONTRAST_ANCHOR.g, 1. - CONTRAST_ANCHOR.b));
    float3 brightness = float3(BRIGHTNESS, BRIGHTNESS, BRIGHTNESS);

    float3 target_color = BASE_COLOR + BRIGHTNESS;
    float total = target_color.r + target_color.g + target_color.b;
    if (total > 1.0) {
        // preserve brightness / color blance and scale down proportionally.
        target_color /= total;
    }

    return float4(lerp(contrast_value, BASE_COLOR + BRIGHTNESS, value(uv)), 1);
}