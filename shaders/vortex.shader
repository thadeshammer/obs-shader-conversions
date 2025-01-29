// https://www.shadertoy.com/view/DsGyWm

// Subject to Shadertoy's Default License CC BY-NC-SA 3.0
// https://www.shadertoy.com/terms
// https://creativecommons.org/licenses/by-nc-sa/3.0/deed.en

// Adapted for obs-shaderfilter by thades
// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions

uniform float SPEED <
    string label = "speed";
    string widget_type = "slider";
    float minimum = 0.01;
    float maximum = 10.0;
    float step = 0.01;
> = 0.3;

uniform int HORZ_LINES <
    string label = "horiz";
    string widget_type = "slider";
    int minimum = 1;
    int maximum = 100;
    int step = 1;
> = 15;

uniform int VERT_LINES <
    string label = "vert";
    string widget_type = "slider";
    int minimum = 1;
    int maximum = 100;
    int step = 1;
> = 25;

uniform float LW <
    string label = "girth";
    string widget_type = "slider";
    float minimum = 0.01;
    float maximum = 1.0;
    float step = 0.01;
> = 0.05;

uniform float FOG <
    string label = "depth";
    string widget_type = "slider";
    float minimum = 2.01;
    float maximum = 6.0;
    float step = 0.01;
> = 4.;


float sdf_heart(float2 p) {
    p.x = abs(p.x);
    if (p.y + p.x > 1.0)
        return sqrt(dot(p - float2(0.25, 0.75), p - float2(0.25, 0.75))) - sqrt(2.0) / 4.0;
    return sqrt(min(dot(p - float2(0.00, 1.00), p - float2(0.00, 1.00)),
                    dot(p - 0.5 * max(p.x + p.y, 0.0), p - 0.5 * max(p.x + p.y, 0.0))))
            * sign(p.x - p.y);
}


float estimateDistance(float3 p0) {
    float2 p = float2( length(p0.xz) , -p0.y);
    float d = sqrt(pow(p.x + p.y, 2.) - 4. * (p.x * p.y - .5)) + .5;
    return (-p.x - p.y + d);
}

float4 mainImage(VertData v_in) : TARGET {
    // camera
    float2 pos = float2(v_in.pos.x, uv_size.y - v_in.pos.y);
    pos = (pos - uv_size.xy / 2.4) / uv_size.y;

    float3 d = float3(pos * 1.2, 1.);
    d.yz = mul(d.yz, 
        float2x2(cos(-1.), -sin(-1.), sin(-1.), cos(-1.)));
    // raymarch
    float3 r = float3(-0.5, 0., -1.);       
    for (int i = 0; i <= 100; ++i) {
        r += d * estimateDistance(r);
    }
    // lines
    float ld = 1. - LW;
    float lv = smoothstep(ld, ld, 
        fmod(atan2(r.x, r.z) / 3.1415 * VERT_LINES / 2. + elapsed_time * SPEED, 1.)
    );
    float lh = smoothstep(ld, ld, 
        fmod((length(r.xz) + elapsed_time * SPEED + r.y) * HORZ_LINES / 3., 1.)
    );
    float lines = min(lv + lh, 2. + lv - lh);
    // fog of war
    float fogDepth = FOG;
    // float fog = log(r.y + fogDepth) / log(-1. + fogDepth);
    float fog = log(r.y + fogDepth) / (log(abs(-1.0 + fogDepth)) + 0.0001);

    // render
    float c = lines * fog;
    return float4(c,c,c,1.);
}
