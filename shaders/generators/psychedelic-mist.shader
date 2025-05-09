// License CC0: Flying through psychedelic mist
// Messing around with colors and FBM. 
// o.g. https://www.shadertoy.com/view/wl2yzt

// Converted for OBS by thades - 2024.04.20 the date is a coincidence but also appropriate
// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions

// The o.g. author recommends that you set BPM to that matches your music.
// I renamed this to strobe because of the obvious epilepsy risk.

uniform float SPEED <
  string label = "speed (0.5)";
  string widget_type = "slider";
  float minimum = 0.;
  float maximum = 5.;
  float step = 0.01;
> = 0.5;

uniform float FBM_MD <
  string label = "basic fbm loops (1.0)";
  string widget_type = "slider";
  float minimum = 1.;
  float maximum = 5.;
  float step = 1.;
> = 1.;

uniform float FBM_MX <
  string label = "warped fbm loops (4.0)";
  string widget_type = "slider";
  float minimum = 1.;
  float maximum = 15.;
  float step = 1.;
> = 4.;

uniform bool GAMMAWEIRDNESS <
  string label = "gamma weirdness";
> = false;
        
uniform bool QUINTIC <
  string label = "quintic";
> = true;

// this is the interesting one
uniform float FORWARD_OFFSET <
  string label = "forward offset (3.0)";
  string widget_type = "slider";
  float minimum = 0.;
  float maximum = 15.;
  float step = .1;
> = 3.;

// this one is 1.0 or not there
uniform float FORWARD_BIAS <
  string label = "forward bias (1.0)";
  string widget_type = "slider";
  float minimum = -1.;
  float maximum = 1.;
  float step = .1;
> = 0.;

uniform float BPM <
  string label = "strobe";
  string widget_type = "slider";
  float minimum = 0.0;
  float maximum = 300.0;
  float step = 1.0;
> = 0.0;

#define PI              3.141592654
#define TAU             2.0 * PI
#define RESOLUTION      uv_size.xy

#define mod(x,y) ((x) - (y) * floor((x)/(y)))

float time() {
  // handle long-term running OBS precision loss
  // 15mn wrap cycle
  float fixed = mod(elapsed_time, 900.);
  return fixed * SPEED;
}

float2x2 mrot(float a) {
  return float2x2(cos(a), sin(a), -sin(a), cos(a));
}

float3 hsv2rgb(float3 c) {
  float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float hash(in float2 co) {
  return frac(sin(dot(co, float2(12.9898,58.233))) * 13758.5453);
}

float psin(float a) {
  return 0.5 + 0.5*sin(a);
}

float vnoise(float2 x) {
  float2 i = floor(x);
  float2 w = frac(x);
  float2 u;
    
  if (QUINTIC) {
    // quintic interpolation
    u = w*w*w*(w*(w*6.0-15.0)+10.0);
  } else {
    // cubic interpolation
    u = w*w*(3.0-2.0*w);
  }

  float a = hash(i+float2(0.0,0.0));
  float b = hash(i+float2(1.0,0.0));
  float c = hash(i+float2(0.0,1.0));
  float d = hash(i+float2(1.0,1.0));
    
  float k0 =   a;
  float k1 =   b - a;
  float k2 =   c - a;
  float k3 =   d - c + a - b;

  float aa = lerp(a, b, u.x);
  float bb = lerp(c, d, u.x);
  float cc = lerp(aa, bb, u.y);
  
  return k0 + k1*u.x + k2*u.y + k3*u.x*u.y;
}

float3 alphaBlendGamma(float3 back, float4 front, float3 gamma) {
  float3 colb = max(back.xyz, 0.0);
  float3 colf = max(front.xyz, 0.0);;
  
  colb = pow(colb, gamma);
  colf = pow(colf, gamma);
  float3 xyz = lerp(colb, colf.xyz, front.w);
  return pow(xyz, 1.0/gamma);
}

float3 offset_0(float z) {
  float a = z;
  float2 p = float2(0.0);
  return float3(p, z);
}

float3 offset(float z) {
  float a = z/3.0;
  float2 p = -2.0*0.075*(float2(cos(a), sin(a*sqrt(2.0))) + float2(cos(a*sqrt(0.75)), sin(a*sqrt(0.5))));
  return float3(p, z);
}


float3 doffset(float z) {
  float eps = 0.1;
  float3 o = offset(z + eps) - offset(z - eps);
  return 0.5 * o / eps;
}

float3 ddoffset(float z) {
  float eps = 0.1;
  float3 o = doffset(z + eps) - doffset(z - eps);
  return 0.125*o/eps;
}

float3 skyColor(float3 ro, float3 rd) {
  return lerp(1.5*float3(0.75, 0.75, 1.0), float3(0., 0., 0.), length(2.0*rd.xy));
}

float height(float2 p, float n, out float2 diff, float2x2 rotSome) {
  // fractal Brownian motion
  // p: position
  // n: time or depth
  // diff: motion/direction
  // rotSome: rotation to swirl the noise

  float aan = 0.45;     // amplitude drop-off between layers
  float ppn = 2.0+0.2;  // frequency multiplier per layer
  float an = 1.0;       // initial amplitude
  
  float s = 0.0;
  float d = 0.0;
  float2 pn = 4.0*p + n*10.0;
  float2 opn = pn;

  int md = FBM_MD; // 1;
  int mx = FBM_MX; // 4;
  
  for (int i = 0; i < md; ++i) {
    s += an*(vnoise(pn)); 
    d += abs(an);
    pn = mul(pn * ppn, rotSome);
    an *= aan; 
  }

  for (int i = md; i < mx; ++i) {
    s += an*(vnoise(pn)); 
    d += abs(an);
    pn = mul(pn * ppn, rotSome);
    an *= aan; 
    pn += (3.0 * float(i + 1)) * s - time() * 5.5;     // Fake warp FBM
  }

  s /= d;
  diff = (pn - opn);

  return smoothstep(0., 1., s);
  // return s;
}

float4 plane(float3 ro, float3 rd, float3 pp, float aa, float n, float2x2 rotSome) {
  float2 p = pp.xy;
  float z = pp.z;
  float nz = pp.z-ro.z;
  
  float2 diff;
  float2 hp = p;
  hp -= nz*0.125*0.5*float2(1.0, -0.5);
  hp -= n;
  float h = height(hp, n, diff, rotSome);
  float gh = (vnoise(0.25*(p+float2(n,n))));
  h *= lerp(0.75, 1.0, gh);
  h = abs(h);
  
  float3 col = float3(0.,0.,0.);
  col = float3(h,h,h);
  float huen = (length(diff)/200.0);
  float satn = 1.0;
  float brin = h;
  col = hsv2rgb(float3(huen, satn, brin));
  
  float t = sqrt(h)*(smoothstep(0.0, 0.5, length(pp - ro)))*smoothstep(0.0, lerp(0.4, 0.75, pow(psin(time()*TAU*BPM/60.0), 4.0)), length(p));
  return float4(col, t);
}

float3 color(float3 ww, float3 uu, float3 vv, float3 ro, float2 p, float2x2 rotSome, float3 std_gamma) {
  float lp = length(p);

  // o.g. two modes, default vs. a previously commented out alternate.
  // I went with surfacing the offset and bias to sliders for OBS. -thades
  // float3 rd = normalize(p.x*uu + p.y*vv + (2.00+tanh(lp))*ww);
  // if (MODE == 1) {
  //   // alternate math, previously commented out; I haven't dug into why yet. -thades
  //   rd = normalize(p.x*uu + p.y*vv + (3.00-1.0*tanh(lp))*ww);
  // }

  float3 rd = normalize(p.x * uu + p.y * vv + ( FORWARD_OFFSET + FORWARD_BIAS * tanh(lp) ) * ww);

  float planeDist = 1.0-0.25;
  int furthest = 6;
  int fadeFrom = furthest-4;

  float nz = floor(ro.z / planeDist);

  float3 skyCol = skyColor(ro, rd);  
  
  float3 col = skyCol;

  for (int i = furthest; i >= 1 ; --i) {
    float pz = planeDist*nz + planeDist*float(i);
    
    float pd = (pz - ro.z)/rd.z;
    
    if (pd > 0.0) {
      float3 pp = ro + rd*pd;
   
      float aa = length(ddy(pp));

      float4 pcol = plane(ro, rd, pp, aa, nz+float(i), rotSome);
      float nz = pp.z-ro.z;
      float fadeIn = (1.0-smoothstep(planeDist*float(fadeFrom), planeDist*float(furthest), nz));
      float fadeOut = smoothstep(0.0, planeDist*0.1, nz);
      pcol.xyz = lerp(skyCol, pcol.xyz, (fadeIn));
      pcol.w *= fadeOut;

      float3 gamma = std_gamma;
      if (GAMMAWEIRDNESS) {
        float ga = pp.z;
        float3 gg = float3(psin(ga), psin(ga*sqrt(0.5)), psin(ga*2.0));
        gamma *= lerp(float3(.1,.1,.1), float3(10.,10.,10.), gg);
      }
      col = alphaBlendGamma(col, pcol, gamma);
    } else {
      break;
    }
    
  }
  
  return col;
}

float3 postProcess(float3 col, float2 q)  {
  col = pow(clamp(col,0.0,1.0),float3(.75,.75,.75)); 
  col = col * 0.6 + 0.4 * col * col * (3.0 - 2.0 * col);
  float dot_product = dot(col, float3(.33,.33,.33));
  col = lerp(col, float3(dot_product,dot_product,dot_product), -0.4);

  col *= 0.5+0.5*pow(19.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7);
  return col;
}

float3 effect(float2 p, float2 q, float2x2 rotSome, float3 std_gamma) {
  float tm = time();
  float3 ro   = offset(tm);
  float3 dro  = doffset(tm);
  float3 ddro = ddoffset(tm);

  float3 ww = normalize(dro);
  float3 uu = normalize(cross(normalize(float3(0.0,1.0,0.0)+ddro), ww));
  float3 vv = normalize(cross(ww, uu));
  
  float3 col = color(ww, uu, vv, ro, p, rotSome, std_gamma);
  col = postProcess(col, q);
  return col;
}

float4 mainImage(VertData v_in) : TARGET 
{
  float2x2 rotSome = mrot(1.0);
  float3 std_gamma = float3(2.2, 2.2, 2.2);

  float2 fragCoord = float2(v_in.pos.x, uv_size.y - v_in.pos.y); // Flip Y to match GLSL behavior

  float2 q = fragCoord / uv_size.xy;
  float2 p = -1.0 + 2.0 * q;
  p.x *= uv_size.x / uv_size.y;

  float3 col = effect(p, q, rotSome, std_gamma);
  
  return float4(col, 1.0);
}

