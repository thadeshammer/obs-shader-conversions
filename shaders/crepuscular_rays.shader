// Requested by PocoAgitato on Nutty's Discord
// EXPERIMENTAL

// CC-0

// Made for obs-shaderfilter by thades - 2025.01.31
// https://twitch.tv/thadeshammer
// https://bsky.app/profile/thadeshammer.bsky.social
// https://github.com/thadeshammer/obs-shader-conversions


uniform float START_FADE <
    string label = "Start Fade";
    string widget_type = "slider";
    float minimum = 0.01;
    float maximum = 2.0;
    float step = 0.01;
> = .1;

uniform float END_FADE <
    string label = "End Fade";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 50.0;
    float step = 0.01;
> = 0.;

uniform string INFO<
    string label = " ";
    string widget_type = "info";
> = "This shader Will make rays for anything that's bright white. Use supplementary FX and color correction if desired.";

uniform string ADDITIONL_INFO<
    string label = " ";
    string widget_type = "info";
> = "Edit the source file itself to make additional adjustments.";

// NOTE DISTANCE and STEPSIZE can't be uniforms because HLSL/OBS really REALLY want to unroll the
// loop.
#define DISTANCE 0.2

// NOTE beware making STEPSIZE any smaller, you can very easily freeze OBS. If you do that, task
// kill it.
#define STEPSIZE 0.01

float4 mainImage(VertData v_in) : TARGET {
    float2 fragCoord = float2(v_in.pos.x, v_in.pos.y);
    float2 uv = fragCoord / uv_size.xy;
    
    // Sample the current pixel's color from the input image
    float3 color = image.Sample(textureSampler, uv).rgb;

    // Determine if the pixel is full bright white (threshold for flexibility)
    bool isBrightWhite = (color.r > 0.99 && color.g > 0.99 && color.b > 0.99);

    // Starting point for the ray
    float2 rayOrigin = uv;

    // Direction for the ray (southeast / bottom-right direction)
    float2 rayDir = normalize(float2(-1.0, -1.0));

    // Ray-marching parameters
    float brightness = 0.0;

    // Ray-march along the direction

    for (float t = 0.0; t < DISTANCE; t += STEPSIZE) {
        float2 currentPos = rayOrigin + rayDir * t;

        // Check if the ray is still within bounds of the screen
        if (currentPos.x < 0.0 || currentPos.x > 1.0 || currentPos.y < 0.0 || currentPos.y > 1.0) {
            break;
        }

        // Sample the color at the current ray position
        // currentPos.y = 1.0 - currentPos.y;
        float3 sampleColor = image.Sample(textureSampler, currentPos).rgb;

        // Bright white pixels contribute to the ray
        if (sampleColor.r > 0.99 && sampleColor.g > 0.99 && sampleColor.b > 0.99) {
            // Increase brightness based on how far the ray has traveled
            float attenuatedBrightness = START_FADE * exp(-t * END_FADE);
            brightness += attenuatedBrightness;
        }
    }

    // Apply the brightness to the current pixel's color
    float3 finalColor = color + float3(brightness, brightness, brightness);

    // Clamp and output the final color
    return float4(saturate(finalColor), 1.0);
}