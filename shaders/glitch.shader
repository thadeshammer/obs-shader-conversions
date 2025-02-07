//based on https://www.shadertoy.com/view/MtXBDs

// Added some sliders for funsies. -thades
// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions


uniform float glitch_amount <
    string label = "Offset Scaler";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 5.0;
    float step = 0.01;
> = 0.2;

uniform float vertical_offset <
    string label = "Vertical Offset";
    string widget_type = "slider";
    float minimum = 0.;
    float maximum = 5.;
    float step = .001;
> = 0.;

uniform float horizontal_offset <
    string label = "Horizontal Offset";
    string widget_type = "slider";
    float minimum = 0.;
    float maximum = 5.;
    float step = .001;
> = 1.;


uniform float glitch_speed <
    string label = "Speed";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 1.0;
    float step = 0.01;
> = 0.6;

uniform float slice_height <
    string label = "Slice Height";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 1.0;
    float step = 0.01;
> = 0.25;

//2D (returns 0 - 1)
float random2d(float2 n) { 
    return frac(sin(dot(n, float2(12.9898, 4.1414))) * 43758.5453);
}

float randomRange (in float2 seed, in float min, in float max) {
		return min + random2d(seed) * (max - min);
}

// return 1 if v inside 1d range
float insideRange(float v, float bottom, float top) {
   return step(bottom, v) - step(top, v);
}

float4 mainImage(VertData v_in) : TARGET
{
    // If elapsed_time gets very large, it starts losing precision (as it's a float) and then the
    // tiny variations it needs for the glitch will vanish; which is why it freezes up if OBS is
    // left running for a long time.    
    // float time = floor(elapsed_time * glitch_speed * 60.0);

    // We can essentially lock elapsed time to always be < 10000 seconds so as to avoid this.
    float time = floor(frac(elapsed_time * 0.0001) * 10000.0 * glitch_speed * 60.0);

	float2 uv = v_in.uv;
    
    //copy orig
    float4 outCol = image.Sample(textureSampler, uv);
    
    //randomly offset slices horizontally
    float maxOffset = glitch_amount/2.0;
    float maxHOffset = maxOffset * horizontal_offset;
    float maxVOffset = maxOffset * vertical_offset;
    for (float i = 0.0; i < 10.0 * glitch_amount; i += 1.0) {
        float sliceY = random2d(float2(time , 2345.0 + float(i)));
        float sliceH = random2d(float2(time , 9035.0 + float(i))) * slice_height;

        float hOffset = randomRange(float2(time , 9625.0 + float(i)), -maxHOffset, maxHOffset);
        float vOffset = randomRange(float2(time , 9625.0 + float(i)), -maxVOffset, maxVOffset);
        float2 uvOff = uv;
        uvOff.x += hOffset;
        uvOff.y += vOffset;
        if (insideRange(uv.y, sliceY, frac(sliceY+sliceH)) == 1.0 ){
        	outCol = image.Sample(textureSampler, uvOff);
        }
    }
    
    //do slight offset on one entire channel
    float maxColOffset = glitch_amount/6.0;
    float rnd = random2d(float2(time , 9545.0));
    float2 colOffset = float2(randomRange(float2(time , 9545.0),-maxColOffset,maxColOffset), 
                       randomRange(float2(time , 7205.0),-maxColOffset,maxColOffset));
    if (rnd < 0.33){
        outCol.r = image.Sample(textureSampler, uv + colOffset).r;
        
    }else if (rnd < 0.66){
        outCol.g = image.Sample(textureSampler, uv + colOffset).g;
        
    } else{
        outCol.b = image.Sample(textureSampler, uv + colOffset).b;  
    }
       
	return outCol;
}
