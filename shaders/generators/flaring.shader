// Flaring by nimitz (twitter: @stormoid)
// https://www.shadertoy.com/view/lsSGzy
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

// converted for obs-shaderfilter by thades
// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions

// sample settings below, courtesy of nimitz

// lone star / hi speed
// 	 brightness 2.
// 	 ray_brightness 5.
// 	 gamma 5.
// 	 spot_brightness 1.7
// 	 ray_density 30.
// 	 curvature 1.
// 	 red   1.
// 	 green 4.0
// 	 blue  4.9
// 	 noisetype 2
// 	 sin_freq 5. //for type
//	yo dawg unchecked (or checked for "hi speed")

// red star
//   brightness 1.
//   ray_brightness 11.
//   gamma 5.
//   spot_brightness 4.
//   ray_density 1.5
//   curvature .1
//   red   7.
//   green 1.3
//   blue  1.
// 	//1 -> ridged, 2 -> sinfbm, 3 -> pure fbm // what are these in reference to?? -thades
//   noisetype 2
//   sin_freq 50. //for type 2

// redder star
// 	 brightness 1.5
// 	 ray_brightness 10.
// 	 gamma 8.
// 	 spot_brightness 15.
// 	 ray_density 3.5
// 	 curvature 15.
// 	 red   4.
// 	 green 1.
// 	 blue  .1
// 	 noisetype 1
// 	 sin_freq 13.

// purple flare (goo with Yo Dawg)
// 	 brightness 1.5
// 	 ray_brightness 20.
// 	 gamma 4.
// 	 spot_brightness .95
// 	 ray_density 3.14
// 	 curvature 17.
// 	 red   2.9
// 	 green .7
// 	 blue  3.5
// 	 noisetype 2
// 	 sin_freq 15.

// green paint
//  brightness 3.
//  ray_brightness 5.
//  gamma 6.
//  spot_brightness 1.5
//  ray_density 6.
//  curvature 90.
//  red   1.8
//  green 3.
//  blue  .5
//  noisetype 1
//  sin_freq 6.
//  YO_DAWG

uniform float brightness <
    string label = "Brightness";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 10.0;
    float step = 0.1;
> = 3.0;

uniform float ray_brightness <
    string label = "Ray Brightness";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 50.0;
    float step = 0.1;
> = 5.0;

uniform float gamma <
    string label = "Gamma";
    string widget_type = "slider";
    float minimum = -50.0;
    float maximum = 50.0;
    float step = 0.1;
> = 6.0;

uniform float spot_brightness <
    string label = "Spot Brightness (2)";
    string widget_type = "slider";
    float minimum = -50.0;
    float maximum = 50.0;
    float step = 0.1;
> = 3;

uniform float ray_density <
    string label = "Ray Density (6)";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 120.0;
    float step = 0.1;
> = 6.0;

uniform float curvature <
    string label = "Curvature";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 180.0;
    float step = 1.0;
> = 90.0;

uniform float red <
    string label = "Red Channel";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 50.0;
    float step = 0.1;
> = 1.8;

uniform float green <
    string label = "Green Channel";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 50.0;
    float step = 0.1;
> = 3.0;

uniform float blue <
    string label = "Blue Channel";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 50.0;
    float step = 0.1;
> = 0.5;

uniform int noisetype <
    string label = "Noise Generator";
    string widget_type = "select";
    int     option_0_value = 0;
    string  option_0_label = "Type 1: abs(n)";
    int     option_1_value = 1;
    string  option_1_label = "Type 2: sin(n) * sin_frequency";
	int     option_2_value = 2;
    string  option_2_label = "Type 3: n";
> = 0;

uniform float sin_freq <
    string label = "Sin Frequency (Noise Type 2)";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 100.0;
    float step = 0.1;
> = 6.0;

uniform bool YO_DAWG <
	string label = "yo dawg";
>;


float hash( float n ){return frac(sin(n)*43758.5453);}

float noise( in float2 x )
{

	x *= 1.75;
    float2 p = floor(x);
    float2 f = frac(x);

    f = f*f*(3.0-2.0*f);

    float n = p.x + p.y*57.0;

    float res = lerp(lerp( hash(n+  0.0), hash(n+  1.0),f.x),
                    lerp( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y);
    return res;
}

float fbm( float2 p, float2x2 m2 )
{	
	float z = 2.;
	float rz = 0.;
	p = mul(p, 0.25);
	for (float i= 1.;i < 6.;i++ )
	{
		if (noisetype == 0) {
			rz+= abs((noise(p)-0.5)*2.)/z;
		} else if (noisetype == 1) {
			rz+= (sin(noise(p)*sin_freq)*0.5+0.5) /z;
		} else if (noisetype == 2) {
			rz+= noise(p)/z;
		}
		z = z*2.;
		p = mul(p * 2., m2);
	}
	return rz;
}

float4 mainImage( VertData v_in ) : TARGET
{
	float t = -elapsed_time * 0.03;
    float2 fragCoord = float2(v_in.pos.x, uv_size.y - v_in.pos.y);
	float2 uv = fragCoord.xy / uv_size.xy -0.5;
	uv.x *= uv_size.x/uv_size.y;
	uv*= curvature*.05+0.0001;
	
	float r  = sqrt(dot(uv,uv));
	float x = dot(normalize(uv), float2(.5,0.))+t;	
	float y = dot(normalize(uv), float2(.0,.5))+t;
	
	float2x2 m2 = float2x2( 0.80,  -0.60, 0.60,  0.80 );

	if (YO_DAWG) {
		x = fbm(float2(y*ray_density*0.5,r+x*ray_density*.2), m2);
		y = fbm(float2(r+y*ray_density*0.1,x*ray_density*.5), m2);
	}
	
    float val;
    val = fbm(float2(r+y*ray_density,r+x*ray_density-y), m2);
	val = smoothstep(gamma*.02-.1,ray_brightness+(gamma*0.02-.1)+.001,val);
	val = sqrt(val);
	
	float3 col = val/float3(red,green,blue);
	col = clamp(1.-col,0.,1.);
	col = lerp(col,float3(1,1,1),spot_brightness-r/0.1/curvature*200./brightness);
    col = clamp(col,0.,1.);
    col = pow(col,float3(1.7,1.7,1.7));
	
	return float4(col,1.0);
	
	return float4(1,0,0,1);
}