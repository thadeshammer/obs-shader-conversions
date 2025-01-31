// Kaleidoscope CC BY-SA 4.0
// Adapted for obs-shaderfilter by thades
// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions

// Based on tutorial by Kishimisu
// https://www.shadertoy.com/view/mtyGWy
// https://youtu.be/f4s1h2YETNY


// Try:
// Length Calc 4, Fade Calc 2, UV Calc 2, Glow 13.9, Zone Size < 1.5, Whimsy 12.1, Burst 3

uniform float4 COLOR_A <
    string label = "Color 1";
> = {0.141, 0.306, .373, 1.0};

uniform float4 COLOR_B <
    string label = "Color 2";
> = {1., 1., .337, 1.0};

uniform float4 COLOR_D <
    string label = "Color 3";
> = {1., .33, 1., 1.0};

uniform int SELECT_LENGTH_CALC <
    string label = "Length Calculation";
    string widget_type = "select";
    int     option_0_value = 0;
    string  option_0_label = "Center";
    int     option_1_value = 1;
    string  option_1_label = "Horizontal";
    int     option_2_value = 2;
    string  option_2_label = "Vertical";
    int     option_3_value = 3;
    string  option_3_label = "Crosshatch";
    int     option_4_value = 4;
    string  option_4_label = "Irregular (Choose Noise Function)";
> = 0;

uniform int SELECT_FADE_CALC <
    string label = "Fade Calculation";
    string widget_type = "select";
    int     option_0_value = 0;
    string  option_0_label = "Exponential";
    int     option_1_value = 1;
    string  option_1_label = "Inverse-Linear Decay";
    int     option_2_value = 2;
    string  option_2_label = "Quadratic";
    int     option_3_value = 3;
    string  option_3_label = "Dynamic";
> = 0;

uniform int UV_CALC <
    string label = "Fade Calculation";
    string widget_type = "select";
    int     option_0_value = 0;
    string  option_0_label = "frac())";
    int     option_1_value = 1;
    string  option_1_label = "abs()";
    int     option_2_value = 2;
    string  option_2_label = "unleashed";
> = 0;

uniform int NOISE_FUNCTION <
    string label = "Noise Generator";
    string widget_type = "select";
    int     option_0_value = 0;
    string  option_0_label = "Golden Ratio indexing (for length calc)";
    int     option_1_value = 1;
    string  option_1_label = "obs-shaderfilter rand_f (for length calc)";
> = 0;

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

uniform float OOMPH <
    string label = "Oomph (0.4)";
    string widget_type = "slider";
    float minimum = -3.0;
    float maximum = 3.0;
    float step = 0.01;
> = .4;

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

float limited_time() {
    float target_fps = 60.0;
    float frame_time = 1.0 / target_fps;
    return floor(elapsed_time / frame_time) * frame_time;
}

#define time limited_time()

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

float random_range(float x, float y) {
    return rand_f * (y - x) + x;
}


float noise(float2 xy, float seed) {
    if (NOISE_FUNCTION == 0) {
        return gold_noise(xy, seed);
    } else if (NOISE_FUNCTION == 1) {
        return random_range(xy.x, xy.y);
    }

    return gold_noise(xy, seed);
}

float2 uv_adjustment(float2 uv) {
    if (UV_CALC == 0) {
        return frac(uv * ZOOM) - WONK;
    } else if (UV_CALC == 1) {
        return abs(uv * ZOOM) - WONK;
    } else if (UV_CALC == 2) {
        return (uv * ZOOM) - WONK;
    } else {
        return frac(uv * ZOOM) - WONK;  // fallback
    }
}

float length_calculation(float2 uv) {
    if (SELECT_LENGTH_CALC == 0) {
        return length(uv); // length from center, o.g.
    } else if (SELECT_LENGTH_CALC == 1) {
        return abs(uv.x); // horizontal
    } else if (SELECT_LENGTH_CALC == 2) {
        return abs(uv.y); // vertical
    } else if (SELECT_LENGTH_CALC == 3) {
        return uv.x * uv.y; // crosshatch
    } else if (SELECT_LENGTH_CALC == 4) {
        return length(uv) + noise(uv, 1.) * 10; // irregularity
    }

    return length(uv); // fallback
}

float fade_calculation(float uv0) {
    if (SELECT_FADE_CALC == 0) {
        return exp(-length(uv0) * BURST); // exponential fade (o.g.)
    } else if (SELECT_FADE_CALC == 1) {
        return 1 / (1.0 + length(uv0) * BURST); // Inverse-linear decay
    } else if (SELECT_FADE_CALC == 2) {
        return 1 / (1.0 + length(uv0) * length(uv0) * BURST); // Quadratic decay
    } else if (SELECT_FADE_CALC == 3) {
        float decayFactor = sin(time * 0.5) * 0.5 + 1.0; // Dynamic decay
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
        uv = uv_adjustment(uv);
        float d = length_calculation(uv) * fade_calculation(uv0);
        float3 col = palette(length(uv0) + i*.4 + time*OOMPH);

        d = abs( sin(d* WHIMSY + time) / GLOW );
        d = pow(0.01 / d, 1.2);
        fragColor += col * d * BRIGHTNESS;
    }

    fragColor = (fragColor - 0.5) * CONTRAST + 0.5;
    fragColor = pow(fragColor, float3(1.0 / GAMMA, 1.0 / GAMMA, 1.0 / GAMMA));        
    return float4(fragColor, ALPHA_VALUE);
}