// https://www.shadertoy.com/view/ltffzl

// Heartfelt - by Martijn Steinrucken aka BigWings - 2017
// Email:countfrolic@gmail.com Twitter:@The_ArtOfCode
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// A video of the original effect can be found here:
// https://www.youtube.com/watch?v=uiF5Tlw22PI&feature=youtu.be

// Converted for OBS by thades - 2025.01.30
// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions
// I removed heart mode which honesty pained me a bit, but it's more useful for more streams if
// it's simply constant rain. Go see the o.g. effect!

#define S(a, b, t) smoothstep(a, b, t)
#define mod(x,y) ((x) - (y) * floor((x)/(y)))

uniform float ZOOM_AMOUNT <
    string label = "Zoom (1.0)";
    string widget_type = "slider";
    float minimum = .01;
    float maximum = 5.0;
    float step = 0.01;
> = 1.;

uniform float SPEED <
    string label = "speed (1.0)";
    string widget_type = "slider";
    float minimum = .01;
    float maximum = 10.;
    float step = .01;
> = 1.;

uniform float BRIGHTNESS <
    string label = "Brightness (-0.33)";
    string widget_type = "slider";
    float minimum = -1.0;
    float maximum = 1.0;
    float step = 0.01;
> = -.33;

uniform float CONTRAST <
    string label = "Contrast (.51)";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 3.0;
    float step = 0.01;
> = .51;

uniform float GAMMA <
    string label = "Gamma (1.3)";
    string widget_type = "slider";
    float minimum = 0.1;
    float maximum = 5.0;
    float step = 0.1;
> = 1.3;

uniform bool FILM_NOIR <
    string label = "Film Noir (for the detective in you)";
> = true;

uniform bool CHEAP_NORMALS <
    string label = "Simple Mode (if this hurts your gpu)";
> = false;


float3 N13(float p) {
    //  from DAVE HOSKINS
   float3 p3 = frac(float3(p,p,p) * float3(.1031,.11369,.13787));
   p3 += dot(p3, p3.yzx + 19.19);
   return frac(float3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}

float4 N14(float t) {
	return frac(sin(t*float4(123., 1024., 1456., 264.))*float4(6547., 345., 8799., 1564.));
}
float N(float t) {
    return frac(sin(t*12345.564)*7658.76);
}

float Saw(float b, float t) {
	return S(0., b, t)*S(1., b, t);
}


float2 DropLayer2(float2 uv, float t) {
    float2 UV = uv;
    
    uv.y += t*0.75;
    float2 a = float2(6., 1.);
    float2 grid = a*2.;
    float2 id = floor(uv*grid);
    
    float colShift = N(id.x); 
    uv.y += colShift;
    
    id = floor(uv*grid);
    float3 n = N13(id.x*35.2+id.y*2376.1);
    float2 st = frac(uv*grid)-float2(.5, 0);
    
    float x = n.x-.5;
    
    float y = UV.y*20.;
    float wiggle = sin(y+sin(y));
    x += wiggle*(.5-abs(x))*(n.z-.5);
    x *= .7;
    float ti = frac(t+n.z);
    y = (Saw(.85, ti)-.5)*.9+.5;
    float2 p = float2(x, y);
    
    float d = length((st-p)*a.yx);
    
    float mainDrop = S(.4, .0, d);
    
    float r = sqrt(S(1., y, st.y));
    float cd = abs(st.x-x);
    float trail = S(.23*r, .15*r*r, cd);
    float trailFront = S(-.02, .02, st.y-y);
    trail *= trailFront*r*r;
    
    y = UV.y;
    float trail2 = S(.2*r, .0, cd);
    float droplets = max(0., (sin(y*(1.-y)*120.)-st.y))*trail2*trailFront*n.z;
    y = frac(y*10.)+(st.y-.5);
    float dd = length(st-float2(x, y));
    droplets = S(.3, 0., dd);
    float m = mainDrop+droplets*r*trailFront;
    
    //m += st.x>a.y*.45 || st.y>a.x*.165 ? 1.2 : 0.;
    return float2(m, trail);
}

float StaticDrops(float2 uv, float t) {
	uv *= 40.;
    
    float2 id = floor(uv);
    uv = frac(uv)-.5;
    float3 n = N13(id.x*107.45+id.y*3543.654);
    float2 p = (n.xy-.5)*.7;
    float d = length(uv-p);
    
    float fade = Saw(.025, frac(t+n.z));
    float c = S(.3, 0., d)*frac(n.z*10.)*fade;
    return c;
}

float2 Drops(float2 uv, float t, float l0, float l1, float l2) {
    float s = StaticDrops(uv, t)*l0; 
    float2 m1 = DropLayer2(uv, t)*l1;
    float2 m2 = DropLayer2(uv*1.85, t)*l2;
    
    float c = s+m1.x+m2.x;
    c = S(.3, 1., c);
    
    return float2(c, max(m1.y*l0, m2.y*l1));
}

float4 mainImage( VertData v_in ) : TARGET {
    float2 fragCoord = float2(v_in.pos.x, uv_size.y - v_in.pos.y);

	float2 uv = (fragCoord.xy-.5*uv_size.xy) / uv_size.y;
    float2 UV = fragCoord.xy/uv_size.xy;

    // similar to glitch.shader pre-patch, this shader also degrades overtime as OBS remains up.
    // After two days up, this shader was extremely obviously periodic (one uniform surge of drops
    // racing down the window per second, roughly) but the fix eludes me still.
    float time = elapsed_time * SPEED;    
    float t = time *.2;
    
    float rainAmount = sin(time * .05) *.3 + .7;
    
    float maxBlur = lerp(3., 6., rainAmount);
    float minBlur = 2.;
    
    float story = 1.;
    float zoom = 1.;

    uv /= ZOOM_AMOUNT;
    
    float staticDrops = S(-.5, 1., rainAmount)*2.;
    float layer1 = S(.25, .75, rainAmount);
    float layer2 = S(.0, .5, rainAmount);
    
    float2 n = float2(1., 1.);
    float2 c = Drops(uv, t, staticDrops, layer1, layer2);
    if (CHEAP_NORMALS) {
    	n = float2(ddx(c.x), ddy(c.x)); // cheap normals (3x cheaper, but 2 times shittier ;))
    } else {
    	float2 e = float2(.001, 0.);
    	float cx = Drops(uv+e, t, staticDrops, layer1, layer2).x;
    	float cy = Drops(uv+e.yx, t, staticDrops, layer1, layer2).x;
    	n = float2(cx-c.x, cy-c.x);		// expensive normals
    }
    
    float focus = lerp(maxBlur-c.y, minBlur, S(.1, .2, c.x));
    // GLSL textureLod -> SampleLevel to sample at mipmap level; focus is level of detail
    // have to y-flip texture so it's oriented correctly
    float2 flippedUV = float2(UV.x, 1.0 - UV.y);
    float3 col = image.SampleLevel(textureSampler, flippedUV + n, focus).rgb;
    
    if (FILM_NOIR) {
        // Note the lightning and vignette only work with the greyscale and is very noir, so I
        // ultimately didn't tease them apart.
        t = (time + 3.) * .5;										// make time sync with first lightnoing
        float colFade = sin(t*.2)*.5+.5+story;
        col = mul(lerp(float3(1., 1., 1.), float3(.8, .9, 1.3), colFade), col);	// subtle color shift
        float fade = S(0., 10., time);							            // fade in at the start
        float lightning = sin(t*sin(t*10.));				            // lighting flicker
        lightning *= pow(max(0., sin(t+sin(t))), 10.);		            // lightning flash
        col = mul(1.+lightning*fade*lerp(1., .1, story*story), col);	// composite lightning

        col = mul(1.-dot(UV-=.5, UV), col);							    // vignette

        col *= fade;										            // composite start and end fade
    }

    // **Apply Brightness, Contrast, and Gamma**
    col = (col - 0.5) * CONTRAST + 0.5;   // Apply contrast
    col += BRIGHTNESS;                    // Apply brightness
    float gamma = 1.0 / GAMMA;
    col = pow(col, float3(gamma, gamma, gamma));  // Apply gamma correction
    
    return float4(col, 1.);
}