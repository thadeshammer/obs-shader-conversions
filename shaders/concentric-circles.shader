// A very simple example, lots of ones like it, this one is mine. And also yours.
// CC BY-SA 4.0
// Created for obs-shaderfilter by thades
// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions

uniform float4 BASE_COLOR <
    string label = "Base";
> = {1., 1., 1., 1.};

uniform float REGION <
    string label = "Region (8.0)";
    string widget_type = "slider";
    float minimum = .1;
    float maximum = 50.;
    float step = .01;
> = 8.;

uniform float THICKNESS <
    string label = "Thick (.08)";
    string widget_type = "slider";
    float minimum = .0001;
    float maximum = .7;
    float step = .0001;
> = .08;

uniform float BLEND <
    string label = "Blend (.0001)";
    string widget_type = "slider";
    float minimum = .0001;
    float maximum = .7;
    float step = .0001;
> = .0001;

uniform float ANIMATE <
    string label = "Animate (0.0)";
    string widget_type = "slider";
    float minimum = -100.;
    float maximum = 100.;
    float step = .001;
> = 0.0;

float2 transform_and_normalize_uv(float2 pos) {
    // pass this v_in.pos
    // Moves origin to screen center, normalizes [-1., 1.] and  flip y-axis to behave like GLSL
    float2 fragCoord = float2(pos.x, uv_size.y - pos.y); // flip y-axis
    float2 uv = fragCoord / uv_size.xy; // normalize coordinates to [0,1].
    uv = uv * 2.0 - 1.0; // map to -1, 1
    uv.x *= uv_size.x / uv_size.y; // stretch aspect ratio for x to compensate
    return uv;
}

float4 mainImage(VertData v_in): TARGET {
    float2 uv = transform_and_normalize_uv(v_in.pos);

    float d = length(uv);
    float t = elapsed_time * ANIMATE;
    d = sin(d * REGION + t) / REGION;
    d = abs(d);

    d = smoothstep(THICKNESS - BLEND, THICKNESS +  BLEND, d);

    float4 col = BASE_COLOR * d;

    return float4(col.xyz, 1.);
}