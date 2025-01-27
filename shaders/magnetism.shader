//Magnetismic by nimitz (twitter: @stormoid)
// https://www.shadertoy.com/view/XlB3zV
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

// converted for obs-shaderfilter by thades
// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions

uniform float4 BASE_COLOR <
    string label = "Seed Color";
> = {0.5, 1.7, 0.5, 0.96};

uniform float RED_SHIFT <
    string label = "Red Shift (-0.5)";
    string widget_type = "slider";
    float minimum = -1.;
    float maximum = 1.;
    float step = 0.05;
> = -.5;

uniform float GREEN_SHIFT <
    string label = "Green Shift (1.0)";
    string widget_type = "slider";
    float minimum = -1.;
    float maximum = 1.;
    float step = 0.05;
> = 1.;

uniform float BLUE_SHIFT <
    string label = "Blue Shift (0.6)";
    string widget_type = "slider";
    float minimum = -1.;
    float maximum = 1.;
    float step = 0.05;
> = .6;

uniform float SPEED <
    string label = "Speed";
    string widget_type = "slider";
    float minimum = 0.1;
    float maximum = 5.0;
    float step = 0.05;
> = 1.0;

uniform float X_SHIFT <
    string label = "X Shift (1.0)";
    string widget_type = "slider";
    float minimum = -10.;
    float maximum = 10.;
    float step = .05;
> = 1.0;

uniform float Y_SHIFT <
    string label = "Y Shift (1.0)";
    string widget_type = "slider";
    float minimum = -10.;
    float maximum = 10.;
    float step = .05;
> = 1.0;

uniform int STEPS <
    string label = "Steps (300)";
    string widget_type = "slider";
    int minimum = 50;
    int maximum = 1000;
    int step = 1;
> = 300;

uniform float ALPHA_SHIFT <
    string label = "Alpha Weight (0.015)";
    string widget_type = "slider";
    float minimum = 0.00;
    float maximum = 20.00;
    float step = .005;
> = .015;

uniform float BASE_STEP <
    string label = "Base Step (.025)";
    string widget_type = "slider";
    float minimum = 0.;
    float maximum = 1.;
    float step = .005;
> = .025;

uniform float OPACITY <
    string label = "Opacity (1.0)";
    string widget_type = "slider";
    float minimum = 0.00;
    float maximum = 1.00;
    float step = .005;
> = 1.0;

#define time elapsed_time * SPEED

float2 rot(float2 p, float a) {
    float c = cos(a), s = sin(a);
    return mul(p, float2x2(c,s,-s,c));
}

float hash21(float2 n){ return frac(sin(dot(n, float2(12.9898, 4.1414))) * 43758.5453); }

float gold_noise(float2 xy, float seed){
    // https://stackoverflow.com/a/28095165/19677371
    float phi = 1.61803398874989484820459;  // Φ = Golden Ratio
    return frac(tan(distance(xy*phi, xy)*seed)*xy.x);
}

float noise(float3 p)
{
	float3 ip = floor(p), fp = frac(p);

    fp = fp*fp*(3.0-2.0*fp);
	float2 tap = (ip.xy + float2(37.0,17.0) *ip.z ) + fp.xy;

    float2 cl = float2(
        gold_noise((tap + 0.5)/256.0, 1.),
        gold_noise((tap + 0.5)/256.0, 1.)
    );

	return lerp(cl.x, cl.y, fp.z);
}

float fbm(float3 p, float sr)
{
    p *= 3.5;
    float rz = 0., z = 1.;
    for(int i=0;i<4;i++)
    {
        float n = noise(p- (time*.6) );
        rz += (sin(n*4.4)-.45)*z;
        z *= .47;
        p *= 3.5;
    }
    return rz;
}

float4 map(float3 p, float2 mo)
{
    float dtp = dot(p,p);
	p = .5*p/(dtp + .2);
    p.xz = rot(p.xz, p.y*2.5);
    p.xy = rot(p.xz, p.y*2.);
    
    float dtp2 = dot(p, p);
    p = (mo.y + .6)*3.*p/(dtp2 - 5.);
    float r = clamp(fbm(p, dtp*0.1)*1.5-dtp*(.35-sin(time*0.3)*0.15), 0. ,1.);

    float4 col = mul(r, BASE_COLOR);
    
    float grd = clamp((dtp+.7)*0.4,0.,1.);
    col.r += grd * RED_SHIFT;
    col.b += grd * BLUE_SHIFT;
    col.g += grd * GREEN_SHIFT;

    float3 lv = lerp(p,float3(.3, .3, .3),2.);
    grd = clamp((col.w - fbm(p+lv*.05,1.))*2., 0.01, 1.5 );
    col.rgb *= float3(.5, 0.4, .6)*grd + float3(4.,0.,.4);
    col.a *= clamp(dtp*2.-1.,0.,1.)*0.07+0.87;
    
    return col;
}

float4 vmarch(float3 ro, float3 rd, float2 fragCoord, float2 mo)
{
	float4 rz = float4(0., 0., 0., 0.);
	float t = 2.5;
    t += 0.03*hash21(fragCoord.xy);
	for(int i=0; i<STEPS; i++)
	{
		if(rz.a > 0.99 || t > 6.)break;
		float3 pos = ro + mul(t, rd);
        float4 col = map(pos, mo);
        float den = col.a;
        col.a *= ALPHA_SHIFT;
		col.rgb *= col.a*1.7;
		rz += col*(1. - rz.a);
        t += BASE_STEP - den*(BASE_STEP-BASE_STEP*0.015);
	}
    return rz;
}

float4 mainImage(VertData v_in) : TARGET
{
	float2 p = (v_in.pos.xy / uv_size.xy) * 2. - 1.;
	p.x *= uv_size.x/uv_size.y*.85;
    p *= 1.1;

    float2 mo = float2(X_SHIFT, Y_SHIFT);
    
	float3 ro = 4. * normalize(float3(cos(2.75-2.0*(mo.x+time*0.05)), sin(time*0.22)*0.2, sin(2.75-2.0*(mo.x+time*0.05))));
	float3 eye = normalize(float3(0., 0., 0.) - ro);
	float3 rgt = normalize(cross(float3(0,1,0), eye));
	float3 up = cross(eye,rgt);
	float3 rd = normalize(p.x*rgt + p.y*up + (3.3-sin(time*0.3)*.7)*eye);
	
	float4 col = clamp(vmarch(ro, rd, v_in.pos, mo),0.,1.);

    col.rgb = pow(col.rgb, float3(.9, .9, .9));

    // col.rb = rot(col.rg, 0.35);
    // col.gb = rot(col.gb, -0.1);

    // col.rb = rot(col.rg, gold_noise(col.rg, 1.));
    // col.gb = rot(col.gb, gold_noise(col.gb, 1.));
    
    return float4(col.rgb, OPACITY);
}