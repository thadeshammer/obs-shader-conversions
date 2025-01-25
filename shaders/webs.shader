// Original by Martijn Steinrucken aka BigWings 2018
// Email:countfrolic@gmail.com
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// https://www.shadertoy.com/view/lscczl

// Converted for OBS by thades - 2025.01.24
// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions


uniform float4 base_color <
    string label = "Background";
> = {1., 1., 1., 1.};

uniform float4 highlight_color <
    string label = "Webway";
> = {1., 1., 1., 1.};

uniform float alpha_value <
    string label = "Alpha";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 1.0;
    float step = 0.05;
> = 1.0;

uniform float density <
    string label = "Density (4)";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 100.0;
    float step = 0.01;
> = 4.;

uniform float line_opacity <
    string label = "Line Opacity";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 1.0;
    float step = 0.001;
> = 1.0;

uniform float sparkle_intensity <
    string label = "Sparkle";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 1.0;
    float step = 0.01;
> = 1.0;


uniform bool SIMPLE<
    string label = "Simple Mode";
>;

#define mix         lerp
#define mod(x,y)	((x) - (y) * floor((x)/(y)))


float N21(float2 p) {
	float3 a = frac(float3(p.xyx) * float3(213.897, 653.453, 253.098));
    a += dot(a, a.yzx + 79.76);
    return frac((a.x + a.y) * a.z);
}

float2 GetPos(float2 id, float2 offs, float t) {
    float n = N21(id+offs);
    float n1 = smoothstep(0.0, 1.0, frac(n * 10.0)); // Smooth out noise
    float n2 = smoothstep(0.0, 1.0, frac(n * 100.0)); // Smooth out noise
    float a = t+n;
    return offs + float2(sin(a*n1), cos(a*n2))*.4;
}

float df_line(float2 a, float2 b, float2 p) {
    float2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / (dot(ba, ba) + 1e-6), 0.0, 1.0); // Add epsilon to prevent 1/0
    return length(pa - ba * h);
}

float draw_line(float2 a, float2 b, float2 uv) {
    float r1 = .04;
    float r2 = .01;
    
    float d = df_line(a, b, uv);
    float d2 = length(a-b);
    float fade = smoothstep(1.5, .5, d2);
    
    fade += smoothstep(.05, .02, abs(d2-.75));
    return smoothstep(r1, r2, d) * fade * line_opacity;
}

float NetLayer(float2 st, float n, float t) {
    float2 id = floor(st )+ n;

    st = st - floor(st) - 0.5;
   
    float2 p[9];
    int c=0;
    for(float y=-1.; y<=1.; y++) {
    	for(float x=-1.; x<=1.; x++) {
            p[c++] = GetPos(id, float2(x,y), t);
    	}
    }
    
    float m = 0.;
    float sparkle = 0.;
    
    for(int i=0; i<9; i++) {
        m += draw_line(p[4], p[i], st);

        float d = length(st-p[i]);

        float s = (.005/(d*d));
        s *= smoothstep(1., .7, d);
        float pulse = sin((frac(p[i].x)+frac(p[i].y)+t)*5.)*.4+.6;
        pulse = pow(pulse, 20.);

        s *= pulse;
        sparkle += s;
    }
    
    m += draw_line(p[1], p[3], st);
	m += draw_line(p[1], p[5], st);
    m += draw_line(p[7], p[5], st);
    m += draw_line(p[7], p[3], st);
    
    float sPhase = (sin(t+n)+sin(t*.1))*.25+.5;
    sPhase += pow(sin(t*.1)*.5+.5, 50.)*5.;
    m += (sparkle * sparkle_intensity) * sPhase;
    
    return m;
}

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = (v_in.pos - uv_size.xy * .5)/uv_size.y;
    
    float t = elapsed_time*.1;
    
    float s = sin(t);
    float c = cos(t);

    float2x2 rot = float2x2(c, -s, s, c); // may need to transpose this, thades
    float2 st = mul(uv,rot);
    
    float m = 0.;
    for(float step=0.; step<1.; step+=1./density) {
        float z = frac(t+step);
        float size = mix(15., 1., z);
        float fade = smoothstep(0., .6, z)*smoothstep(1., .8, z);
        
        m += fade * NetLayer(st*size-z, step, elapsed_time);
    }

    float3 col = mix(base_color, highlight_color, clamp(m, 0.0, 1.0));

    float fft = image.Sample(textureSampler, v_in.uv).x;

    float glow = -uv.y * fft*2.;  // original
    col += mix(base_color, highlight_color, glow);

    // The original preserved colors on Shadertoy but not in OBS, not sure what I did wrong the
    // first time, but this significant overhaul seems to have done the trick.
    if (SIMPLE) {
        uv *= float2(10.0, 10.0); // Zoom in
        float layer_intensity = NetLayer(uv, 0.0, elapsed_time);
        col = mix(base_color, highlight_color, clamp(layer_intensity, 0.0, 1.0)); // Preserve color blending
    } else {
        float inv_uv_length_squared = 1.0 - dot(uv, uv); // Intensity fade based on distance
        float intensity = inv_uv_length_squared * smoothstep(0.0, 20.0, mod(elapsed_time, 230.0)) 
                                            * smoothstep(224.0, 200.0, mod(elapsed_time, 230.0));
        col *= intensity; // Apply intensity adjustment to the color
    }

    return float4(col, alpha_value);
}