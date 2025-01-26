# Shaders for the obs-shaderfilter plug-in

I'm a big fan of OBS and I really enjoy using the [obs-shaderfilter
plugin](https://obsproject.com/forum/resources/obs-shaderfilter.1736/) and really wanted more
shaders, as well as the ability to play with the ones I had. So, why not share my efforts?

Everything under `shaders/` is under variations of the Creative Commons licensure, so feel free to
pull any or all of them down as you like and load them into your own production. Enjoy!

## On Converting GLSL Shaders to OBS's implementation of HLSL

This guide is intended to serve as a light reference for converting existing Shadertoy or GLSL
shaders into OBS's implementation of HLSL, for use with the [obs-shaderfilter
plugin](https://obsproject.com/forum/resources/obs-shaderfilter.1736/) v2.4.1+.

If you found a really cool shader on Shadertoy.com or in StreamFX or elsewhere and you'd like to use
it in your OBS production, these notes may help you do that. I'll keep uploading examples (which
you're free to download and use if you like!) as I do conversions myself, as well as updating this
guide as I learn more.

This is not a guide to teach you how to write shaders or even to ease the passage into learing any
of the shader langauges. This is, at best, a quick reference for folks who are familiar with the
space, or at least, unafraid. Be not afraid! You can do this!

### Put a comment at the top

Start every source with a comment of some kind; OBS will crash if the first line is a preprocessor
directive, and this will work around it.

### mainImage entry point

In GLSL the definition for `mainImage` takes two parameters and returns nothing; the return value is
effectively packaged in the `fragColor` parameter. It looks like this:

```glsl
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // sick shader code goes here
    fragColor = the_cool_color_you_made_for_this_specific_pixel;
}
```

Here in OBS's HLSL, fragCoord is replaced with v_in (see next section) and the fragColor is simply
the return value, so you can just return it after creating and assigning it.

```cpp
float4 mainImage(VertData v_in) : TARGET
{
    // sick shader code goes here
    return the_cool_color_you_made_for_this_specific_pixel;
}
```

### fragCoord and OBS's UV origin

OBS's HLSL implementation has the origin at the bottom-left, as opposed to GLSL's top-left origin.
To account for this, if y-axis orientation matters for your shader, you'll need to handle that axis inversion.

In general, `fragCoord` is replaced with `v_in.pos`.

To invert the y-axis, you can replace `v_in.pos.xy` thus:

```cpp
float2(v_in.pos.x, uv_size.y - v_in.pos.y)
```

### Handy pre-defines

If the file contains any of these functions, use the associated `#define` or replace each GLSL
method reference with its HLSL equivalent.

```hlsl
#ifndef OPENGL
#define mat2 float2x2
#define mat3 float3x3
#define fract frac
#define mix lerp
#endif
```

### vecN is floatN

In general, if you encounter vector constructions, replace it with float like this:

```cpp
vec3(1.0, 2.0, 3.0);
// becomes
float3(1.0, 2.0, 3.0);
```

Note that the convenience definition `vec3(0.0) == vec3(0.0, 0.0, 0.0)` does not work in OBS and
will beget you the following error message:

```text
"Incorrect number of arguments to numeric-type constructor."
```

You just need to explicitly add all of the values to fix this.

### There is no const

Replace `const` with `#define` preprocessor directives, or you can use `uniform<>` if you want to
surface it in the OBS UI for user adjustment.

#### const becomes define

```cpp
const int STEPS = 8;
// becomes
#define STEPS 8
// note the #define doesn't take a type, operator, or semi-colon.
// it's effectively just string replacement in the code that follows it.
```

### Use uniform so the end-user can make fun adjustments

Surface constants to the OBS UI using the `uniform` keyword and angle brackets syntax. Examples follow.

#### Single number field with default value.

```cpp
uniform float value = 0.0;
```

#### Color selection dialog

```hlsl
// Note the {} braces.
uniform float4 primary_color<
    string label = "Primary";
> = {0.0, 0.0, 0.0, 0.0};
```

#### Slider

```hlsl
uniform float glow_scale<
    string label = "Glow Scale";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 10.0;
    float step = 0.01;
> = 2.0;
```

### modulo calculations

HLSL doesn't have `mod()` but it does have `fmod()` which is probably not what you want to GLSL's replace
`mod()` with. `fmod()` uses `trunc()` under the hood which ignores the sign of the divisor, which
boils down to not getting the kind of wraparound behavior you're probably expectding when using
`mod()` in GLSL. Use a `#define` or proper function or otherwise do it yourself thus:

```
#define mod(x,y) ((x) - (y) \* floor((x)/(y)))
```

### Arrays can't be function parameters

Arrays can't be passed into functions in OBS's implemenation of HLSL. If you encounter code doing
this, make the array global in scope or otherwise avoid passing it at all by refactoring the code.

### Matrix maths

In GLSL, matrices are row-major by default for multiplication. In HLSL, they're column-major by
default. Because the default multiplication and storage order differ, you'll often need to make
adjustments by hand to account for these differences. (You may have to transpose the matrix.)

```glsl
// In GLSL
vec4 result = vec4 * mat4;
```

```cpp
// In HLSL, use mul() instead of * and order the matrix before the vector
float4 result = mul(mat4, vec4); // Matrix is on the left in HLSL
```

NOTE that HLSL allows the programmer to explicitly set matrix storage order with the `row_major` and
`column_major` keywords, however it's not known to me whether this is supported in OBS's
implementation. (I haven't tried it. Let me know if you do.)

### iChannelN and texelFetch

In GLSL, iChannelN (where N is 0, 1, 2, etc.) represents an input texture or buffer, which is
ShaderToy specific, I believe. I _think_ I've seen shaders that essentially do this but will need to
find them to clarify this section and my understanding.

One example I saw recently is shown in `constellations-lscczl.shader` here in this repo. I was able
to replace specificaly this:

```glsl
float fft  = texelFetch( iChannel0, float2(.7,0.), 0 ).x;
```

with this:

```cpp
float fft = image.Sample(textureSampler, v_in.uv).x;
```

- `image` is a Texture2D object bound to the shader in OBS.
- `.Sample()` performs filtered sampling on the given texture at the given UV coordinates.
- `textureSampler` is a SamplerState object which defines how textures are sampled. This handles
  _how_ `image` is sampled.
- `image.Sample(textureSampler, v_in.uv)` is the current input texture being processed by the
  shader. If applied as a filter to a source (image, capture) then `image` refers to that source; if
  applied to the entire scene, `image` represents the full composited scene before the shader runs.

As I learn more, I'll add more here.

### Noise Generation

Many Shadertoy shaders I've seen use a pregenerated noise image that they reference. This can be
done with obs-shaderfilter (via a `uniform texture2d`) but for simplicity I've taken to using simple
in-shader noise generation. By nature this is inferior to the image technique, but it works well
enough in my experience. I've taken to using a Golden Ratio indexer, adapted from [this
StackOverflow post](https://stackoverflow.com/a/28095165/19677371).

```
// Gold Noise ©2015 dcerisano@standard3d.com
// - based on the Golden Ratio
// - uniform normalized distribution
// - fastest static noise generator function (also runs at low precision)
// - use with indicated fractional seeding method.

float gold_noise(float2 xy, float seed){
    float phi = 1.61803398874989484820459; // Φ = Golden Ratio
    return frac(tan(distance(xy*phi, xy)*seed)*xy.x);
}
```

You can see this in-use in `space-travel.shader`, where I also use a somewhat more complicated hash
method from that same StackOverflow page as the seed. (You could also use `elapsed_time` for a seed,
or the color value of the screen, or whatever you like.)

### Quick Reference

When you encounter the following keywords or operators in a GLSL shader you're trying to convert, replace them thus:

| replace               | with                           | notes                                                           |
| --------------------- | ------------------------------ | --------------------------------------------------------------- |
| `matrix_a * matrix_b` | `mul(matrix_a,matrix_b)`       | Use `mul()` for matrix multiplication. Mind row vs col major.   |
| `atan(y,x)`           | `atan(x,y)`                    | The arguments are reversed here in HLSL.                        |
| `fract()`             | `frac()`                       |                                                                 |
| `matN`                | `floatNxN`                     |                                                                 |
| `mix()`               | `lerp()`                       |                                                                 |
| `fragCoord`           | `v_in.pos`                     | The y-axis is inverted here from GLSL, see associated section.  |
| `gl_fragCoord`        | `v_in.pos`                     |                                                                 |
| `iResolution`         | `uv_size`                      | The y-axis is inverted here from GLSL, see `fragCoord` section. |
| `iTime`               | `elapsed_time`                 |                                                                 |
| `texelFetch(t, v, m)` | `image.Sample(textureSampler)` | See associated section.                                         |
| `vecN`                | `floatN`                       | `float4(0.,)` must be replaced with `float(0.0, 0.0, 0.0, 0.0)` |

## Acknowledgements

Special thanks to SkeletonBow. Withtout their overwhelming contributions, this guide wouldn't have
been possible. Find them [on Twitch](https://twitch.tv/skelzinator).

Shaders in OBS wouldn't really be accessible to most of us without the mighty plugin author
[Exeldro](https://github.com/exeldro).
