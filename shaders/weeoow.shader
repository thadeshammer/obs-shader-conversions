// https://www.shadertoy.com/view/ldBSRd

uniform bool REDUCE_COLOR_SPACE <
    string label = "11-bit color mode";
> = false;

uniform float F2 <
    string label = "wee (0.366)";
    string widget_type = "slider";
    float minimum = -1.;
    float maximum = 1.;
    float step = .001;
> = 0.3660254;

uniform float G2 <
    string label = "oow (-0.211)";
    string widget_type = "slider";
    float minimum = -1.;
    float maximum = 1.;
    float step = .001;
> = -0.2113249;

uniform float SPEED <
    string label = "speed (1.0)";
    string widget_type = "slider";
    float minimum = .01;
    float maximum = 10.;
    float step = .01;
> = 1.;

#define PI 3.14159
#define mod(x,y) ((x) - (y) * floor((x)/(y)))

float2 random2(float2 c) { float j = 4906.0*sin(dot(c,float2(169.7, 5.8))); float2 r; r.x = frac(512.0*j); j *= .125; r.y = frac(512.0*j); return r-0.5;}

float simplex2d(float2 p) {
    float2 s = floor(p + (p.x+p.y)*F2), x = p - s - (s.x+s.y)*G2;
    float e = step(0.0, x.x-x.y);
    float2 i1 = float2(e, 1.0-e),  x1 = x - i1 - G2, x2 = x - 1.0 - 2.0*G2;
    float3 w, d; w.x = dot(x, x);
    w.y = dot(x1, x1);
    w.z = dot(x2, x2);
    w = max(0.5 - w, 0.0);
    d.x = dot(random2(s + 0.0), x);
    d.y = dot(random2(s +  i1), x1);
    d.z = dot(random2(s + 1.0), x2);
    w *= w;
    w *= w;
    d *= w;
    return dot(d, float3(70., 70., 70.));}

float3 rgb2yiq(float3 color) {
    return mul(float3x3(0.299,0.587,0.114,0.596,-0.274,-0.321,0.211,-0.523,0.311), color);
}

float3 yiq2rgb(float3 color) {
    return mul(float3x3(1.,0.956,0.621,1,-0.272,-0.647,1.,-1.107,1.705), color);
}

float3 convertRGB443quant(float3 color){ float3 out0 = mod(color,1./16.); out0.b = mod(color.b, 1./8.); return out0;}
float3 convertRGB443(float3 color){return color-convertRGB443quant(color);}

float2 sincos(float x) {
    return float2(sin(x), cos(x));
}

float2 rotate2d(float2 uv, float phi){float2 t = sincos(phi); return float2(uv.x*t.y-uv.y*t.x, uv.x*t.x+uv.y*t.y);}
float3 rotate3d(float3 p, float3 v, float phi) {
    v = normalize(v);
    float2 t = sincos(-phi);
    float s = t.x, c = t.y, x =-v.x, y =-v.y, z =-v.z;
    float4x4 M = float4x4(x*x*(1.-c)+c,x*y*(1.-c)-z*s,x*z*(1.-c)+y*s,0.,y*x*(1.-c)+z*s,y*y*(1.-c)+c,y*z*(1.-c)-x*s,0.,z*x*(1.-c)-y*s,z*y*(1.-c)+x*s,z*z*(1.-c)+c,0.,0.,0.,0.,1.);
    return mul(M, float4(p,1.)).xyz;
}

float varazslat(float2 position, float time){
	float color = 0.0;
	float t = 2.*time;
	color += sin(position.x*cos(t/10.0)*20.0 )+cos(position.x*cos(t/15.)*10.0 );
	color += sin(position.y*sin(t/ 5.0)*15.0 )+cos(position.x*sin(t/25.)*20.0 );
	color += sin(position.x*sin(t/10.0)*  .2 )+sin(position.y*sin(t/35.)*10.);
	color *= sin(t/10.)*.5;
	
	return color;
}

float4 mainImage( VertData v_in ) : TARGET
{
    float2 iResolution = uv_size * uv_scale;
    float2 fragCoord = float2(v_in.pos.x, uv_size.y - v_in.pos.y); // flip y-axis GLSL -> HLSL
    float iTime = elapsed_time * SPEED;

	float2 uv = fragCoord.xy / iResolution.xy; 
    uv = (uv-.5)*2.;
   
    float3 vlsd = float3(0,1,0);
    vlsd = rotate3d(vlsd, float3(1.,1.,0.), iTime);
    vlsd = rotate3d(vlsd, float3(1.,1.,0.), iTime);
    vlsd = rotate3d(vlsd, float3(1.,1.,0.), iTime);
     
    float2 v0 = .75 * sincos(.3457 * iTime + .3423) - simplex2d(uv * .917);
    float2 v1 = .75 * sincos(.7435 * iTime + .4565) - simplex2d(uv * .521);
    float2 v2 = .75 * sincos(.5345 * iTime + .3434) - simplex2d(uv * .759);
    
    float3 color = float3(dot(uv-v0, vlsd.xy),dot(uv-v1, vlsd.yz),dot(uv-v2, vlsd.zx));
    
    color *= .2 + 2.5*float3(
    	(16.*simplex2d(uv+v0) + 8.*simplex2d((uv+v0)*2.) + 4.*simplex2d((uv+v0)*4.) + 2.*simplex2d((uv+v0)*8.) + simplex2d((v0+uv)*16.))/32.,
        (16.*simplex2d(uv+v1) + 8.*simplex2d((uv+v1)*2.) + 4.*simplex2d((uv+v1)*4.) + 2.*simplex2d((uv+v1)*8.) + simplex2d((v1+uv)*16.))/32.,
        (16.*simplex2d(uv+v2) + 8.*simplex2d((uv+v2)*2.) + 4.*simplex2d((uv+v2)*4.) + 2.*simplex2d((uv+v2)*8.) + simplex2d((v2+uv)*16.))/32.
    );
    
    color = yiq2rgb(color);
    
    color *= 1.- .25* float3(
    	varazslat(uv *.25, iTime + .5),
        varazslat(uv * .7, iTime + .2),
        varazslat(uv * .4, iTime + .7)
    );
    
    if (REDUCE_COLOR_SPACE) {
        return float4(convertRGB443(color),1.0);
    } else {
        color = float3(pow(color.r, 0.45), pow(color.g, 0.45), pow(color.b, 0.45));
        return float4(color, 1.0);
    }
    
    // return float4(1,0,0,1);
}

