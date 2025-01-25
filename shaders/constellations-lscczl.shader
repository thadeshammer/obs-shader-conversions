// The Universe Within - by Martijn Steinrucken aka BigWings 2018
// Email:countfrolic@gmail.com
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Converted for OBS by thades - 2025.01.24
// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions

// NOTE if this doesn't have "User Shader Time" checked, it will run itself down to black and stop

uniform float num_layers<
    string label = "Layers (4)";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 100.0;
    float step = 0.01;
> = 4.;

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
    float n1 = frac(n*10.);
    float n2 = frac(n*100.);
    float a = t+n;
    return offs + float2(sin(a*n1), cos(a*n2))*.4;
}

float df_line(float2 a,float2 b,float2 p)
{
    float2 pa = p - a, ba = b - a;
	float h = clamp(dot(pa,ba) / dot(ba,ba), 0., 1.);	
	return length(pa - ba * h);
}

float draw_line(float2 a, float2 b, float2 uv) {
    float r1 = .04;
    float r2 = .01;
    
    float d = df_line(a, b, uv);
    float d2 = length(a-b);
    float fade = smoothstep(1.5, .5, d2);
    
    fade += smoothstep(.05, .02, abs(d2-.75));
    return smoothstep(r1, r2, d)*fade;
}

float NetLayer(float2 st, float n, float t) {
    float2 id = floor(st)+n;

    st = frac(st)-.5;
   
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
    m += sparkle * sPhase;
    
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

    // float2 M = iMouse.xy/uv_size.xy-.5;
    float2 M = float2(1.0, 1.0); // for now just don't transform / scale with this, thades
	M *= mul(rot, float2(2., 2.));
    
    float m = 0.;
    for(float step=0.; step<1.; step+=1./num_layers) {
        float z = frac(t+step);
        float size = mix(15., 1., z);
        float fade = smoothstep(0., .6, z)*smoothstep(1., .8, z);
        
        m += fade * NetLayer(st*size-M*z, step, elapsed_time);
    }
    
    // original calculation
    // float3 baseCol = float3(s, cos(t*.4), -sin(t*.24))*.4+.6;

    // more pronounced brightess differences
    float3 baseCol = float3(
        0.5 + 0.5 * sin(t),
        0.5 + 0.5 * cos(t * .7),
        0.5 + 0.5 * sin(t * 1.3)
    ) * .4 + .6;

    float3 col = baseCol*m;

    float fft = image.Sample(textureSampler, v_in.uv).x;

    // original
    float glow = -uv.y * fft*2.;  // original
    col += baseCol * glow;

    // more sparkly
    // float3 glowCol = float3(fft, fft * 0.8, fft * 1.2);   
    // col += baseCol * glowCol;
    
    if (SIMPLE) {
        uv *= float2(10., 10.);
        col = float3(1., 1., 1.) * NetLayer(uv, 0., elapsed_time);
    } else {
        float inv_uv_length_squared = 1.-dot(uv,uv);
        float3 result = float3(inv_uv_length_squared, inv_uv_length_squared, inv_uv_length_squared);

        col = mul(col, result);
        t = mod(elapsed_time, 230.);
        col *= smoothstep(0., 20., t) * smoothstep(224., 200., t);
    }
    return float4(col,1.);
}