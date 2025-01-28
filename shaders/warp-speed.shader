// 'Warp Speed 2'
// David Hoskins 2015.
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Fork of:-   https://www.shadertoy.com/view/Msl3WH
//----------------------------------------------------------------------------------------

// converted for obs-shaderfilter by thades
// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions

float4 mainImage(VertData v_in) : TARGET
{
	float s = 0.0, v = 0.0;

	float2 uv = (v_in.pos / uv_size.xy) * 2.0 - 1.;

    float time = (elapsed_time - 2.0) * 58.0;
	float3 col = float3(0., 0., 0.);
    float3 init = float3(sin(time * .0032)*.3, .35 - cos(time * .005)*.3, time * 0.002);
	for (int r = 0; r < 100; r++) 
	{
		float3 p = init + s * float3(uv, 0.05);
		p.z = frac(p.z);
        // Thanks to Kali's little chaotic loop...
		for (int i=0; i < 10; i++)	p = abs(p * 2.04) / dot(p, p) - .9;
		v += pow(dot(p, p), .7) * .06;
		col +=  float3(v * 0.2+.4, 12.-s*2., .1 + v * 1.) * v * 0.00003;
		s += .025;
	}
	return float4(clamp(col, 0.0, 1.0), 1.0);
}