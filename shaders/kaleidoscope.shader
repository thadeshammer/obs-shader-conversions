// Kaleidoscope CC BY-SA 4.0
// Adapted for obs-shaderfilter by thades
// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions

// Based on tutorial by Kishimisu
// https://www.shadertoy.com/view/mtyGWy
// https://youtu.be/f4s1h2YETNY


uniform float4 COLOR_A <
    string label = "Color 1";
> = {0.141, 0.306, .373, 1.0};

uniform float4 COLOR_B <
    string label = "Color 2";
> = {1., 1., .337, 1.0};

uniform float4 COLOR_D <
    string label = "Color 3";
> = {1., .33, 1., 1.0};

uniform int MODE_A <
    string label = "Major Mode (1)";
    string widget_type = "slider";
    int minimum = 1;
    int maximum = 4;
    int step = 1;
> = 1;

uniform int MODE_B <
    string label = "Minor Mode (2)";
    string widget_type = "slider";
    int minimum = 1;
    int maximum = 4;
    int step = 1;
> = 2;

uniform float GLOW <
    string label = "Glow (8.0)";
    string widget_type = "slider";
    float minimum = 0.1;
    float maximum = 50.0;
    float step = 0.1;
> = 8.;

uniform float ZOOM <
    string label = "Zone Size (1.5)";
    string widget_type = "slider";
    float minimum = 0.1;
    float maximum = 10.0;
    float step = 0.1;
> = 1.5;

uniform float WHIMSY <
    string label = "Whimsy (8.0)";
    string widget_type = "slider";
    float minimum = 0.1;
    float maximum = 50.0;
    float step = 0.1;
> = 8.;

uniform int ITERATIONS <
    string label = "Density (4)";
    string widget_type = "slider";
    int minimum = 1;
    int maximum = 50;
    int step = 1;
> = 4;

uniform float BURST <
    string label = "Burst (1.)";
    string widget_type = "slider";
    float minimum = -50.0;
    float maximum = 50.0;
    float step = 0.1;
> = 1.;

uniform float WONK <
    string label = "Wonk (0.5)";
    string widget_type = "slider";
    float minimum = -5.0;
    float maximum = 5.0;
    float step = 0.01;
> = .5;

uniform float GAMMA <
    string label = "Gamma (0.4)";
    string widget_type = "slider";
    float minimum = 0.1;
    float maximum = 5.0;
    float step = 0.1;
> = .4;

uniform float CONTRAST <
    string label = "Contrast (1.1)";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 3.0;
    float step = 0.1;
> = 1.1;

uniform float BRIGHTNESS <
    string label = "Brightness (1.0)";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 10.0;
    float step = 0.1;
> = 1.0;

uniform float ALPHA_VALUE <
    string label = "Alpha";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 1.0;
    float step = 0.1;
> = 1.0;

// Palette handling from https://iquilezles.org/articles/palettes/
float3 palette( float t ) {
    float3 a = COLOR_A;
    float3 b = COLOR_B;
    float3 c = float3(1., 1., 1.);
    float3 d = COLOR_D;

    float tau = 6.2831853071;
    return a + b*cos(tau * (c*t+d));
}

float gold_noise(float2 xy, float seed){
    // https://stackoverflow.com/a/28095165/19677371
    float phi = 1.61803398874989484820459;  // Φ = Golden Ratio
    return frac(tan(distance(xy*phi, xy)*seed)*xy.x);
}

float length_calculation(float2 uv) {
    if (MODE_A == 1) {
        return length(uv); // length from center, o.g.
    } else if (MODE_A == 2) {
        return abs(uv.x); // horizontal
    } else if (MODE_A == 3) {
        return abs(uv.y); // vertical
    } else if (MODE_A == 4) {
        return uv.x * uv.y; // crosshatch
    } else {
        return length(uv) + gold_noise(uv, 1.) * 10; // irregularity
    }
}

float fade_calculation(float uv0) {
    if (MODE_B == 1) {
        return exp(-length(uv0) * BURST); // exponential fade (o.g.)
    } else if (MODE_B == 2) {
        return 1 / (1.0 + length(uv0) * BURST); // Inverse-linear decay
    } else if (MODE_B == 3) {
        return 1 / (1.0 + length(uv0) * length(uv0) * BURST); // Quadratic decay
    } else if (MODE_B == 4) {
        float decayFactor = sin(elapsed_time * 0.5) * 0.5 + 1.0; // Dynamic decay
        return exp(-length(uv0) * BURST * decayFactor);
    } else {
        return exp(-length(uv0) * BURST); // exponential fade (o.g.)
    }
}

float4 mainImage(VertData v_in) : TARGET {
    float2 uv = (v_in.pos * 2.0 - uv_size.xy) / uv_size.y;
    float2 uv0 = uv; // o.g. uv, uv will be changing over the loop
    float3 fragColor = float3(0., 0., 0.);
    
    for (int i = 0; i < ITERATIONS; i++) {
        uv = frac(uv * ZOOM) - WONK;
        float d = length_calculation(uv) * fade_calculation(uv0);
        float3 col = palette(length(uv0) + i*.4 + elapsed_time*.4);

        d = abs( sin(d* WHIMSY + elapsed_time) / GLOW );
        d = pow(0.01 / d, 1.2);
        fragColor += col * d * BRIGHTNESS;
    }

    fragColor = (fragColor - 0.5) * CONTRAST + 0.5;
    fragColor = pow(fragColor, float3(1.0 / GAMMA, 1.0 / GAMMA, 1.0 / GAMMA));        
    return float4(fragColor, ALPHA_VALUE);
}