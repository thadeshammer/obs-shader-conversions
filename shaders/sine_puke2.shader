// Sine Puke II, by WAHa.06x36.
// Same as my original Sine Puke, but with more rainbow, and less "newp".
// "Was playing around with a physically reasonable rainbow palette function, so I decided to dump
// it into my classic Sine Puke, famous for being a five-minute test function endlessly copypasted
// on glsl.heroku.org. Please steal this and make lots of rainbows!"

// Based on code by Spektre posted at
// http://stackoverflow.com/questions/3407942/rgb-values-of-visible-spectrum

// Converted for obs-shaderfilter by thades


uniform float WARP_INTENSITY <
    string label = "Warp Intensity (0.6)";
    string widget_type = "slider";
    float minimum = .01;
    float maximum = 2.;
    float step = .01;
> = .6;

uniform float GAMMA <
    string label = "GAMMA (2.2)";
    string widget_type = "slider";
    float minimum = .005.;
    float maximum = 3.;
    float step = .001;
> = 2.2;


float3 spectral_colour(float l) // RGB <0,1> <- lambda l <400,700> [nm]
{
    // This function maps a wavelength (in nanometers) in the range [400, 700] to an approximate RGB
    // color. It's based on how the human eye perceives light. The constants represent transition
    // points in the visible spectrum.

	float r=0.0,g=0.0,b=0.0;
         if ((l>=400.0)&&(l<410.0)) { float t=(l-400.0)/(410.0-400.0); r=    +(0.33*t)-(0.20*t*t); }
    else if ((l>=410.0)&&(l<475.0)) { float t=(l-410.0)/(475.0-410.0); r=0.14         -(0.13*t*t); }
    else if ((l>=545.0)&&(l<595.0)) { float t=(l-545.0)/(595.0-545.0); r=    +(1.98*t)-(     t*t); }
    else if ((l>=595.0)&&(l<650.0)) { float t=(l-595.0)/(650.0-595.0); r=0.98+(0.06*t)-(0.40*t*t); }
    else if ((l>=650.0)&&(l<700.0)) { float t=(l-650.0)/(700.0-650.0); r=0.65-(0.84*t)+(0.20*t*t); }
         if ((l>=415.0)&&(l<475.0)) { float t=(l-415.0)/(475.0-415.0); g=             +(0.80*t*t); }
    else if ((l>=475.0)&&(l<590.0)) { float t=(l-475.0)/(590.0-475.0); g=0.8 +(0.76*t)-(0.80*t*t); }
    else if ((l>=585.0)&&(l<639.0)) { float t=(l-585.0)/(639.0-585.0); g=0.82-(0.80*t)           ; }
         if ((l>=400.0)&&(l<475.0)) { float t=(l-400.0)/(475.0-400.0); b=    +(2.20*t)-(1.50*t*t); }
    else if ((l>=475.0)&&(l<560.0)) { float t=(l-475.0)/(560.0-475.0); b=0.7 -(     t)+(0.30*t*t); }

	return float3(r,g,b);
}

float3 spectral_palette(float x) { return spectral_colour(x*300.0+400.0); }

float4 mainImage(VertData v_in) : TARGET
{
	float2 p=(2.0*v_in.pos.xy-uv_size.xy)/max(uv_size.x,uv_size.y);
    float t = elapsed_time;

	for(int i=1; i<50; i++)
	{
		p=p+float2(
			WARP_INTENSITY/float(i) * sin(float(i) * p.y+t+0.3 * float(i)) + 1.0,
			WARP_INTENSITY/float(i) * sin(float(i) * p.x+t+0.3 * float(i+10)) - 1.4
		);
	}
	float3 col = spectral_palette(p.x-48.5);

    float f = 1.0/GAMMA;
	return float4(pow(col, float3(f,f,f)), 1.0);
}
