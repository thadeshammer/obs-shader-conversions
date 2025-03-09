// first line

#define mix lerp

float n21 (float3 uvw)
{
    return frac(sin(uvw.x*23.35661 + uvw.y*6560.65 + uvw.z*4624.165)*2459.452);
}

float smoothNoise (float3 uvw)
{
    float fbl = n21(floor(uvw));
    float fbr = n21(float3(1.0,0.0,0.0)+floor(uvw));
    float ful = n21(float3(0.0,1.0,0.0)+floor(uvw));
    float fur = n21(float3(1.0,1.0,0.0)+floor(uvw));
    
    float bbl = n21(float3(0.0,0.0,1.0)+floor(uvw));
    float bbr = n21(float3(1.0,0.0,1.0)+floor(uvw));
    float bul = n21(float3(0.0,1.0,1.0)+floor(uvw));
    float bur = n21(float3(1.0,1.0,1.0)+floor(uvw));
    
    uvw = frac(uvw);
    float3 blend = uvw;
    blend = smoothstep(0.0, 1.0, uvw);
    
    return mix(	mix(mix(fbl, fbr, blend.x), mix(ful, fur, blend.x), blend.y),
        		mix(mix(bbl, bbr, blend.x), mix(bul, bur, blend.x), blend.y),
               	blend.z);
}

float3 perlinNoise (float3 uvw)
{
    // float blended = 1.;
    float blended = smoothNoise(uvw*4.0);
    blended += smoothNoise(uvw*8.0)*0.5;
    blended += smoothNoise(uvw*16.0)*0.25;
    blended += smoothNoise(uvw*32.0)*0.125;
    blended += smoothNoise(uvw*64.0)*0.0625;
    
    blended /= 2.0;
    blended = frac(blended*2.0)*0.5+0.5;
    blended *= pow(0.8 - abs(uvw.y), 2.0);
    return float3(blended, blended, blended);
}

float4 mainImage( VertData v_in ) : TARGET
{
    float2 uv = v_in.pos.xy / uv_size.x-0.5*float2(1.0,(uv_size.y/uv_size.x));
    float3 uvw = float3(uv, elapsed_time*0.14);
    
    float3 result = float3(0., 0., 0.);
    float moreDepth = 0.0;
    
    for(int i=0;i<20;i++)
    {
        moreDepth += 0.008;
        float3 scale = float3(moreDepth * 12.0 + 1.0, moreDepth * 12.0 + 1.0, 1.0);
        float3 offset = float3(0.0, 0.0, moreDepth);
        result += perlinNoise(uvw * scale + offset);

    }
    result /= 14.0;
    
    result *= 2.4*(0.6-length(uvw.xy));
    
    return float4(result * float3(0.8,0.9,1.0)*1.0 + float3(0.2,0.3,0.4)*(0.9-abs(uv.y)), 1.0);
}