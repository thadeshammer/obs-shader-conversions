// https://www.shadertoy.com/view/MdyGzR
// by ehj1 2016.01.16

// converted for obs-shaderfilter by thades
// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions

#define mod289(x) ((x) - floor((x) * (1.0 / 289.0)) * 289.0)

float4 permute(float4 x) {
     return mod289(((x*34.0)+1.0)*x);
}

float4 taylorInvSqrt(float4 r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(float3 v)
{
    float2  C = float2(1.0/6.0, 1.0/3.0) ;
    float4  D = float4(0.0, 0.5, 1.0, 2.0);

    // First corner
    float3 i  = floor(v + dot(v, C.yyy) );
    float3 x0 =   v - i + dot(i, C.xxx) ;

    // Other corners
    float3 g = step(x0.yzx, x0.xyz);
    float3 l = 1.0 - g;
    float3 i1 = min( g.xyz, l.zxy );
    float3 i2 = max( g.xyz, l.zxy );

    //   x0 = x0 - 0.0 + 0.0 * C.xxx;
    //   x1 = x0 - i1  + 1.0 * C.xxx;
    //   x2 = x0 - i2  + 2.0 * C.xxx;
    //   x3 = x0 - 1.0 + 3.0 * C.xxx;
    float3 x1 = x0 - i1 + C.xxx;
    float3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
    float3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

    // Permutations
    i = mod289(i); 
    // float4 p = permute( permute( permute( 
    //             float4(i.z, i.z, i.z, i.z) + float4(0.0, i1.z, i2.z, 1.0 ))
    //           + float4(i.y, i.y, i.y, i.y) + float4(0.0, i1.y, i2.y, 1.0 )) 
    //           + float4(i.x, i.x, i.x, i.x) + float4(0.0, i1.x, i2.x, 1.0 ));

    float4 field1 = float4(i.z, i.z, i.z, i.z) + float4(0.0, i1.z, i2.z, 1.0 );
    float4 field2 = float4(i.y, i.y, i.y, i.y) + float4(0.0, i1.y, i2.y, 1.0 );
    float4 field3 = float4(i.x, i.x, i.x, i.x) + float4(0.0, i1.x, i2.x, 1.0 );

    float4 p = permute( permute (permute(field1 + field2 + field3) ) );

    // Gradients: 7x7 points over a square, mapped onto an octahedron.
    // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
    float n_ = 0.142857142857; // 1.0/7.0
    float3  ns = n_ * D.wyz - D.xzx;

    float4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

    float4 x_ = floor(j * ns.z);
    float4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

    float4 x = x_ *ns.x + ns.yyyy;
    float4 y = y_ *ns.x + ns.yyyy;
    float4 h = 1.0 - abs(x) - abs(y);

    float4 b0 = float4( x.xy, y.xy );
    float4 b1 = float4( x.zw, y.zw );

    //float4 s0 = float4(lessThan(b0,0.0))*2.0 - 1.0;
    //float4 s1 = float4(lessThan(b1,0.0))*2.0 - 1.0;
    float4 s0 = floor(b0)*2.0 + 1.0;
    float4 s1 = floor(b1)*2.0 + 1.0;
    float4 sh = -step(h, float4(0., 0., 0., 0.));

    float4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
    float4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

    float3 p0 = float3(a0.xy,h.x);
    float3 p1 = float3(a0.zw,h.y);
    float3 p2 = float3(a1.xy,h.z);
    float3 p3 = float3(a1.zw,h.w);

    //Normalise gradients
    float4 norm = taylorInvSqrt(float4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;

    // Mix final noise value
    float4 o_six4 = float4(.6, .6, .6, .6);
    float4 zero4 = float4(0., 0., 0., 0.);
    float4 m = max(o_six4 - float4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), zero4);
    m = m * m;
    return 42.0 * dot( m*m, float4( dot(p0,x0), dot(p1,x1), 
                                    dot(p2,x2), dot(p3,x3) ) );
}

float normnoise(float noise) {
	return 0.5*(noise+1.0);
}

float clouds(float2 uv, float time) {
    uv += float2(time*0.05, + time*0.01);
    
    float2 off1 = float2(50.0,33.0);
    float2 off2 = float2(0.0, 0.0);
    float2 off3 = float2(-300.0, 50.0);
    float2 off4 = float2(-100.0, 200.0);
    float2 off5 = float2(400.0, -200.0);
    float2 off6 = float2(100.0, -1000.0);
	float scale1 = 3.0;
    float scale2 = 6.0;
    float scale3 = 12.0;
    float scale4 = 24.0;
    float scale5 = 48.0;
    float scale6 = 96.0;
    return normnoise(snoise(float3((uv+off1)*scale1,time*0.5))*0.8 + 
                     snoise(float3((uv+off2)*scale2,time*0.4))*0.4 +
                     snoise(float3((uv+off3)*scale3,time*0.1))*0.2 +
                     snoise(float3((uv+off4)*scale4,time*0.7))*0.1 +
                     snoise(float3((uv+off5)*scale5,time*0.2))*0.05 +
                     snoise(float3((uv+off6)*scale6,time*0.3))*0.025);
}


float4 mainImage(VertData v_in) : TARGET
{
    float2 fragCoord = float2(v_in.pos.x, uv_size.y - v_in.pos.y);
	float2 uv =  fragCoord.xy/uv_size.x;
    
    float2 center = float2(0.5,0.5*(uv_size.y/uv_size.x));
    
    float time = elapsed_time;
    
    float2 light1 = float2(sin(time*1.2+50.0)*1.0 + cos(time*0.4+10.0)*0.6,sin(time*1.2+100.0)*0.8 + cos(time*0.2+20.0)*-0.2)*0.2+center;
    float3 lightColor1 = float3(1.0, 0.3, 0.3);
    
    float2 light2 = float2(sin(time+3.0)*-2.0,cos(time+7.0)*1.0)*0.2+center;
    float3 lightColor2 = float3(0.3, 1.0, 0.3);
    
    float2 light3 = float2(sin(time+3.0)*2.0,cos(time+14.0)*-1.0)*0.2+center;
    float3 lightColor3 = float3(0.3, 0.3, 1.0);

    float cloudIntensity1 = 0.7*(1.0-(2.5*distance(uv, light1)));
    float lighIntensity1 = 1.0/(100.0*distance(uv,light1));

    float cloudIntensity2 = 0.7*(1.0-(2.5*distance(uv, light2)));
    float lighIntensity2 = 1.0/(100.0*distance(uv,light2));
    
    float cloudIntensity3 = 0.7*(1.0-(2.5*distance(uv, light3)));
    float lighIntensity3 = 1.0/(100.0*distance(uv,light3));
    
    float clouds1 = cloudIntensity1 * clouds(uv, time);
    float clouds2 = cloudIntensity2 * clouds(uv, time);
    float clouds3 = cloudIntensity3 * clouds(uv, time);

    float3 col = float3(clouds1, clouds1, clouds1) * lightColor1 + lighIntensity1 * lightColor1 +
                 float3(clouds2, clouds2, clouds2) * lightColor2 + lighIntensity2 * lightColor2 +
                 float3(clouds3, clouds3, clouds3) * lightColor3 + lighIntensity3 * lightColor3;

	return float4(col, 1.0);
}