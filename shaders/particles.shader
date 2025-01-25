// Based on creation by Stephane Cuillerdier - Aiekick/2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Tuned via XShade (http://www.funparadigm.com/xshade/)

// https://www.shadertoy.com/view/MddGWN
// converted by thades - 2025.01.25
// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions

#define mix lerp

uniform float4 start_color <
    string label = "One";
> = {0.333, 0.0, 0.498, 1.0};

uniform float4 end_color <
    string label = "Two";
> = {1., 1., 1., 1.};

uniform int detail_factor <
    string label = "Detail Level (100)";
    string widget_type = "slider";
    int minimum = 1;
    int maximum = 150;
    int step = 1;
> = 100;

uniform float duration_min <
    string label = "Duration Min (16.2)";
    string widget_type = "slider";
    float minimum = 0.1;
    float maximum = 50.0;
    float step = .1;
> = 16.2;

uniform float duration_max <
    string label = "Duration Max (16.2)";
    string widget_type = "slider";
    float minimum = 0.1;
    float maximum = 50.0;
    float step = .1;
> = 16.2;

uniform float start_radius <
    string label = "Start Radius (16.4)";
    string widget_type = "slider";
    float minimum = 0.1;
    float maximum = 50.0;
    float step = .1;
> = 16.4;

uniform float end_radius <
    string label = "End Radius (16.5)";
    string widget_type = "slider";
    float minimum = 0.1;
    float maximum = 50.0;
    float step = .1;
> = 16.5;

uniform float compression_factor <
    string label = "Compress (8.2)";
    string widget_type = "slider";
    float minimum = 0.1;
    float maximum = 50.0;
    float step = .1;
> = 8.2;


float noise_in_range(float2 p, float a, float b) {
    // Hash function to generate pseudo-random values between 0 and 1
    float hashValue = frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);

    // Scale and shift to map hashValue to range [a, b]
    return lerp(a, b, hashValue);
}


float4 mainImage(VertData v_in) : TARGET
{
	float2 xy = v_in.pos.xy;

    float t = elapsed_time+5.;
    
	float velocity = .1; 
	float duration = noise_in_range(xy, duration_min, duration_max);

	float2 s = uv_size.xy;
	float2 v = float2(compression_factor * mad(2.,  v_in.pos.xy, - s)/s.y);
    
	float4 col = float4(0., 0., 0., 0.);

    float evo = (sin(elapsed_time*.01+400.)*.5+.5)*99.+1.;
	evo = noise_in_range(xy, 0.0, evo);
	
	float mb = 0.;
	float mbRadius = 0.;
	float sum = 0.;
	for(int i=0; i<detail_factor; i++) {
		float d = frac(t*velocity+48934.4238*sin(float(i/int(evo))*692.7398));

		float tt = 0.;			
        float a = 6.28*float(i)/float(detail_factor);

        float x = d*cos(a)*duration;
        float y = d*sin(a)*duration;
        
		float distRatio = d/duration;
		mbRadius = mix(start_radius, end_radius, distRatio); 
        
		float2 p = v - float2(x,y);//*float2(1,sin(a+3.14159/2.));
        
		mb = mbRadius/dot(p,p);
    	
		sum += mb;
        
		col = mix(col, mix(start_color, end_color, distRatio), mb/sum);
	}
    
	sum /= float(detail_factor);
    
	col = normalize(col) * sum;
	sum = clamp(sum, 0., .4);
    
	float4 tex = float4(1., 1., 1., 1.);
	col *= smoothstep(tex, float4(0., 0., 0., 0.), float4(sum, sum, sum, sum));
        
	return col;
}