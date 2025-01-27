// Remnant X
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// by David Hoskins.
// Thanks to boxplorer and the folks at 'Fractalforums.com'
// HD Video:- https://www.youtube.com/watch?v=BjkK9fLXXo0

// https://www.shadertoy.com/view/4sjSW1

#define mix lerp
#define mod(x,y) ((x) - (y) * floor((x)/(y)))

#define SCALE 2.8
#define MINRAD2 .25

float3 sunDir = {0.35, 0.1,  0.3};  // was previously in a normalize() call
float3 sunColour = {1.0, .95, .8};
float3 surfaceColour1 = {.8, .0, 0.};
float3 surfaceColour2 = {.4, .4, 0.5};
float3 surfaceColour3 = {.5, 0.3, 0.00};
float3 fogCol = {0.4, 0.4, 0.4};


float minRad2() {
    return clamp(MINRAD2, 1.0e-9, 1.0);
}

float scale() {
    return SCALE / minRad2();
    // return (float4(SCALE, SCALE, SCALE, abs(SCALE)) / minRad2());
}

float absScalem1() {
    // return abs(SCALE - 1.0);
    return pow(abs(SCALE), 1.0 - 10.0);
}

float AbsScaleRaisedTo1mIters() {
    return pow(abs(SCALE), float(1-10));
}

//----------------------------------------------------------------------------------------
float gold_noise(float2 xy, float seed){
    // added this to replace iChannel-loaded noise texture
    // https://stackoverflow.com/a/28095165/19677371
    float phi = 1.61803398874989484820459;  // Φ = Golden Ratio   
    return frac(tan(distance(xy*phi, xy)*seed)*xy.x);
}

float gold_noise_normalized(float2 xy, float seed) {
    float phi = 1.61803398874989484820459;  // Golden ratio
    float raw = tan(distance(xy * phi, xy) * seed) * xy.x;

    // Normalize raw noise to [0.0, 1.0]
    float min_val = -10.0; // Pick reasonable bounds for tan behavior
    float max_val = 10.0;  // These depend on your specific use case
    raw = clamp(raw, min_val, max_val); // Avoid catastrophic tan explosions

    return (raw - min_val) / (max_val - min_val);
}

float Noise(float3 x)
{
    float3 p = floor(x);
    float3 f = frac(x);
	f = f*f*(3.0-2.0*f);
	
	float2 uv = (p.xy + float2(37.0,17.0)*p.z) + f.xy;
    float2 rg = float2(
        gold_noise_normalized(uv, p.x),
        gold_noise_normalized(uv, p.y)
    );

	// float2 rg = texture( iChannel0, (uv+ 0.5)/256.0, -99.0 ).yx;
	return mix( rg.x, rg.y, f.z );
}

//----------------------------------------------------------------------------------------
float Map(float3 pos) 
{
	
	float4 p = float4(pos,1);
	float4 p0 = p;  // p.w is the distance estimate

	for (int i = 0; i < 9; i++)
	{
		p.xyz = clamp(p.xyz, -1.0, 1.0) * 2.0 - p.xyz;

		float r2 = dot(p.xyz, p.xyz);
		p *= clamp(max(minRad2()/r2, minRad2()), 0.0, 1.0);

		// scale, translate
		p = p*scale() + p0;
	}
	return ((length(p.xyz) - absScalem1()) / p.w - AbsScaleRaisedTo1mIters());
}

//----------------------------------------------------------------------------------------
float3 Colour(float3 pos, float sphereR, float time, float3 surface_color1) 
{
	float3 p = pos;
	float3 p0 = p;
	float trap = 1.0;
    
	for (int i = 0; i < 6; i++)
	{
		p.xyz = clamp(p.xyz, -1.0, 1.0) * 2.0 - p.xyz;
		float r2 = dot(p.xyz, p.xyz);
		p *= clamp(max((minRad2())/r2, minRad2()), 0.0, 1.0);

        float3 scale3 = float3(scale(), scale(), scale());
		p = p*scale3.xyz + p0.xyz;
		trap = min(trap, r2);
	}
	// |c.x|: log final distance (fractional iteration count)
	// |c.y|: spherical orbit trap at (0,0,0)
	float2 c = clamp(float2( 0.3333*log(dot(p,p))-1.0, sqrt(trap) ), 0.0, 1.0);

    float t = mod(length(pos) - time*150., 16.0);
    surface_color1 = mix( surface_color1, float3(.4, 3.0, 5.), pow(smoothstep(0.0, .3, t) * smoothstep(0.6, .3, t), 10.0));
	return mix(mix(surface_color1, surfaceColour2, c.y), surfaceColour3, c.x);
}


//----------------------------------------------------------------------------------------
float3 GetNormal(float3 pos, float distance)
{
    distance *= 0.001+.0001;
	float2 eps = float2(distance, 0.0);
	float3 nor = float3(
	    Map(pos+eps.xyy) - Map(pos-eps.xyy),
	    Map(pos+eps.yxy) - Map(pos-eps.yxy),
	    Map(pos+eps.yyx) - Map(pos-eps.yyx));
	return normalize(nor);
}

//----------------------------------------------------------------------------------------
float GetSky(float3 pos)
{
    pos *= 2.3;
	float t = Noise(pos);
    t += Noise(pos * 2.1) * .5;
    t += Noise(pos * 4.3) * .25;
    t += Noise(pos * 7.9) * .125;
	return t;
}

//----------------------------------------------------------------------------------------
float BinarySubdivision(float3 rO, float3 rD, float2 t)
{
    float halfwayT;
  
    for (int i = 0; i < 6; i++)
    {

        halfwayT = dot(t, float2(.5, .5));
        float d = Map(rO + halfwayT*rD); 
        //if (abs(d) < 0.001) break;
        t = mix(float2(t.x, halfwayT), float2(halfwayT, t.y), step(0.0005, d));

    }

	return halfwayT;
}

//----------------------------------------------------------------------------------------
float2 Scene(float3 rO, float3 rD, float2 fragCoord, float fragColor)
{
	// float t = .05 + 0.05 * texture(iChannel0, fragCoord.xy / iChannelResolution[0].xy).y;
    float t = .05 + 0.05 * gold_noise_normalized(fragColor, 1.); // artibrary seed pick

	float3 p = float3(0., 0., 0.);
    float oldT = 0.0;
    bool hit = false;
    float glow = 0.0;
    float2 dist;
	for( int j=0; j < 100; j++ )
	{
		if (t > 12.0) break;
        p = rO + t*rD;
       
		float h = Map(p);
        
		if(h  <0.0005)
		{
            dist = float2(oldT, t);
            hit = true;
            break;
        }
       	glow += clamp(.05-h, 0.0, .4);
        oldT = t;
      	t +=  h + t*0.001;
 	}
    if (!hit) {
        t = 1000.0;
    } else {
        t = BinarySubdivision(rO, rD, dist);
    }
    return float2(t, clamp(glow*.25, 0.0, 1.0));
}

//----------------------------------------------------------------------------------------
float Hash(float2 p)
{
	return frac(sin(dot(p, float2(12.9898, 78.233))) * 33758.5453)-.5;
} 

//----------------------------------------------------------------------------------------
float3 PostEffects(float3 rgb, float2 xy)
{
	// Gamma first...
	
	// Then...
	#define CONTRAST 1.08
	#define SATURATION 1.5
	#define BRIGHTNESS 1.5

    float3 base_color = float3(  // glsl makes some things much prettier
                            dot(float3(.2125, .7154, .0721), rgb*BRIGHTNESS),
                            dot(float3(.2125, .7154, .0721), rgb*BRIGHTNESS),
                            dot(float3(.2125, .7154, .0721), rgb*BRIGHTNESS));

	rgb = mix(float3(.5,.5,.5), mix(base_color, rgb*BRIGHTNESS, SATURATION), CONTRAST);
	// Noise...
	//rgb = clamp(rgb+Hash(xy*iTime)*.1, 0.0, 1.0);
	// Vignette...
	rgb *= .5 + 0.5*pow(20.0*xy.x*xy.y*(1.0-xy.x)*(1.0-xy.y), 0.2);	

    rgb = pow(rgb, float3(0.47 , 0.47, 0.47));
	return rgb;
}

//----------------------------------------------------------------------------------------
float Shadow( in float3 ro, in float3 rd)
{
	float res = 1.0;
    float t = 0.05;
	float h;
	
    for (int i = 0; i < 8; i++)
	{
		h = Map( ro + rd*t );
		res = min(6.0*h / t, res);
		t += h;
	}
    return max(res, 0.0);
}

//----------------------------------------------------------------------------------------
float3x3 RotationMatrix(float3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    // This might present issues with ordering. -thades
    return float3x3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
                    oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
                    oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c);
}

//----------------------------------------------------------------------------------------
float3 LightSource(float3 spotLight, float3 dir, float dis)
{
    float g = 0.0;
    if (length(spotLight) < dis)
    {
        float a = max(dot(normalize(spotLight), dir), 0.0);
		g = pow(a, 500.0);
        g +=  pow(a, 5000.0)*.2;
    }
   
    return float3(.6, .6, .6) * g;
}

//----------------------------------------------------------------------------------------
float3 CameraPath( float t )
{
    float3 p = float3(-.78 + 3. * sin(2.14*t),.05+2.5 * sin(.942*t+1.3),.05 + 3.5 * cos(3.594*t) );
	return p;
} 
    
//----------------------------------------------------------------------------------------
float4 mainImage(VertData v_in) : TARGET
{
	// float m = (iMouse.x/iResolution.x)*300.0;

    float2 fragCoord = v_in.pos.xy;
    float3 fragColor = image.Sample(textureSampler, v_in.uv);

    float3 surface_color1 = surfaceColour1; // globals are implicitly constant but this shader mucks em

	float time = (elapsed_time)*.01 + 15.00;
    float2 xy = fragCoord.xy / uv_size.xy;
	float2 uv = (-1.0 + 2.0 * xy) * float2(uv_size.x/uv_size.y, 1.0);
	
	// #ifdef STEREO
	// float isRed = mod(fragCoord.x + mod(fragCoord.y, 2.0),2.0);
	// #endif

	float3 cameraPos	= CameraPath(time);
    float3 camTar		= CameraPath(time + .01);

	float roll = 13.0*sin(time*.5+.4);
	float3 cw = normalize(camTar-cameraPos);

	float3 cp = float3(sin(roll), cos(roll),0.0);
	float3 cu = normalize(cross(cw,cp));

	float3 cv = normalize(cross(cu,cw));
    // cw = mul(RotationMatrix(cv, sin(-time * 20.0) * 0.7), cw);
    /// alt cw calculation to transpose matrix in the event major order is wrong post conversion
    cw = mul(transpose(RotationMatrix(cv, sin(-time * 20.0) * 0.7)), cw);

    // simple for debug
    float3 dir = normalize(uv.x * float3(1, 0, 0) + uv.y * float3(0, 1, 0) + float3(0, 0, 1));
	// float3 dir = normalize(uv.x*cu + uv.y*cv + 1.3*cw);

	// #ifdef STEREO
	// cameraPos += .008*cu*isRed; // move camera to the right
	// #endif

    float3 spotLight = CameraPath(time + .03) + float3(sin(time*18.4), cos(time*17.98), sin(time * 22.53))*.2;
	float3 col = float3(0., 0., 0.);
    float3 sky = float3(0.03, .04, .05); // * GetSky(dir);  // COMMENTED FOR DEBUG
	float2 ret = Scene(cameraPos, dir, fragCoord, fragColor);
    
    if (ret.x < 900.0)
    {
		float3 p = cameraPos + ret.x*dir; 
		float3 nor = GetNormal(p, ret.x);
        
       	float3 spot = spotLight - p;
		float atten = length(spot);

        spot /= atten;
        
        float3 sun_dir = normalize(sunDir);

        float shaSpot = Shadow(p, spot);
        float shaSun = Shadow(p, sun_dir);
        
       	float bri = max(dot(spot, nor), 0.0) / pow(atten, 1.5) * .25;
        float briSun = max(dot(sun_dir, nor), 0.0) * .2;
        
        col = Colour(p, ret.x, time, surface_color1);
        col = (col * bri * shaSpot) + (col * briSun* shaSun);
        
        float3 ref = reflect(dir, nor);
        col += pow(max(dot(spot,  ref), 0.0), 10.0) * 2.0 * shaSpot * bri;
        col += pow(max(dot(sun_dir, ref), 0.0), 10.0) * 2.0 * shaSun * briSun;
    }
    
    col = mix( sky, col, min(exp(-ret.x+1.5), 1.0));

    float3 whatarethis = float3(pow(abs(ret.y), 2.), pow(abs(ret.y), 2.), pow(abs(ret.y), 2.));
    col += whatarethis * float3(.02, .04, .1);

    col += LightSource(spotLight-cameraPos, dir, ret.x);
	// col = PostEffects(col, xy);

	// // #ifdef STEREO	
	// // col *= float3( isRed, 1.0-isRed, 1.0-isRed );	
	// // #endif
	
    // if (ret.x < 900.0) {
    //     return float4(1.0, 0.0, 0.0, 1.0); // Red for hits
    // }
    // return float4(0.0, 0.0, 1.0, 1.0); // Blue for misses


	return float4(col, 1.0);
}

//--------------------------------------------------------------------------