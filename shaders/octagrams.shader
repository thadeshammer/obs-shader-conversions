// https://www.shadertoy.com/view/tlVGDt
// Octagrams by whiskey_shusuky

// Subject to Shadertoy's Default License CC BY-NC-SA 3.0
// https://www.shadertoy.com/terms
// https://creativecommons.org/licenses/by-nc-sa/3.0/deed.en

// Converted for obs-shaderfilter by thades
// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions

#define mod(x,y) ((x) - (y) * floor((x)/(y)))

float2x2 rot(float a) {
	float c = cos(a), s = sin(a);
	return float2x2(c,-s,s,c);
}

float sdBox( float3 p, float3 b )
{
	float3 q = abs(p) - b;
	return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float box(float3 pos, float scale) {
	pos *= scale;
	float base = sdBox(pos, float3(.4,.4,.1)) /1.5;
	pos.xy = mul(5., pos.xy);
	pos.y -= 3.5;
	pos.xy = mul(rot(.75), pos.xy);
	float result = -base;
	return result;
}

float box_set(float3 pos, float time) {
	float3 pos_origin = pos;

	pos = pos_origin;
	pos.y += sin(time * 0.4) * 2.5;
	pos.xy =   mul(rot(.8), pos.xy);
	float box1 = box(pos,2. - abs(sin(time * 0.4)) * 1.5);
	
    pos = pos_origin;
	pos.y -=sin(time * 0.4) * 2.5;
	pos.xy =   mul(rot(.8), pos.xy);
	float box2 = box(pos,2. - abs(sin(time * 0.4)) * 1.5);
	
    pos = pos_origin;
	pos.x +=sin(time * 0.4) * 2.5;
	pos.xy =   mul(rot(.8), pos.xy);
	float box3 = box(pos,2. - abs(sin(time * 0.4)) * 1.5);	
	
    pos = pos_origin;
	pos.x -=sin(time * 0.4) * 2.5;
	pos.xy =   mul(rot(.8), pos.xy);
	float box4 = box(pos,2. - abs(sin(time * 0.4)) * 1.5);	
	
    pos = pos_origin;
	pos.xy =   mul(rot(.8), pos.xy);
	float box5 = box(pos,.5) * 6.;	
	
    pos = pos_origin;
	float box6 = box(pos,.5) * 6.;	
	float result = max(max(max(max(max(box1,box2),box3),box4),box5),box6);
	return result;
}

float map(float3 pos, float time) {
    // does this need to still exist? just a pass thru
	float box_set1 = box_set(pos, time);
	return box_set1;
}


float4 mainImage( VertData v_in ) : TARGET {
    float time = elapsed_time;

	float2 p = ( mul(2., v_in.pos.xy) - uv_size.xy) / min(uv_size.x, uv_size.y);
	float3 ro = float3(0., -0.2 , time * 4.);
	float3 ray = normalize(float3(p, 1.5));
	ray.xy = mul(rot(sin(time * .03) * 5.), ray.xy);
	ray.yz = mul(rot(sin(time * .05) * .2), ray.yz);
	float t = 0.1;
	float3 col = float3(0., 0., 0.);
	float ac = 0.0;


	for (int i = 0; i < 99; i++){
		float3 pos = ro + mul(t, ray);
		pos = mod(pos-2., 4.) -2.;
		
		float d = map(pos, time);

		d = max(abs(d), 0.01);
		ac += exp(-d*23.);

		t += d* 0.55;
	}

	col = float3(ac * .02, ac * .02, ac * .02);
	col += float3(0., .2 * abs(sin(time)), .5 + sin(time) * .2);

	return float4(col, 1.0 - t * (0.02 + 0.02 * sin (time)));
}
