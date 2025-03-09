// ASCII shader for use with obs-shaderfilter 7/2020 v1.0

// https://github.com/Oncorporation/obs-shaderfilter
// Based on the following shaders:
// https://www.shadertoy.com/view/3dtXD8 - Created by DSWebber in 2019-10-24
// https://www.shadertoy.com/view/lssGDj - Created by movAX13h in 2013-09-22

// Modifications of original shaders include:
//  - Porting from GLSL to HLSL
//  - Combining characters sets from both source shaders
//  - Adding support for parameters from OBS for monochrome rendering, scaling and dynamic character set
//
// Add Additional Characters with this tool: http://thrill-project.com/archiv/coding/bitmap/
// converts a bitmap into int then decodes it to look like text

// thades added movAX13h's o.g. full character set 2025-02-27
// https://twitch.tv/thadeshammer
// https://github.com/thadeshammer/obs-shader-conversions

uniform int scale<
    string label = "Scale";
    string widget_type = "slider";
    int minimum = 1;
    int maximum = 20;
    int step = 1;
> = 1; // Size of characters

uniform float4 base_color<
    string label = "Monochrome Mode Color";
> = {0.0,1.0,0.0,1.0}; // Monochrome base color

uniform bool monochrome<
    string label = "Monochrome";
> = false;

uniform int character_set<
    string label = "Character set";
    string widget_type = "select";
    int    option_0_value = 0;
    string option_0_label = "Large set of non-letters";
    int    option_1_value = 1;
    string option_1_label = "Small set of capital letters";
    int    option_2_value = 2;
    string option_2_label = "Full alphabet";
    int    option_3_value = 3;
    string option_3_label = "thades mode - simple";
    int    option_4_value = 4;
    string option_4_label = "thades mode - extra";
> = 0;

uniform string note<
    string widget_type = "info";
> = "Base color is used as monochrome base color.";

float character(int n, float2 p)
{
    // n (int): packed bitmap representing a character in an int; the bitmap is 5x5; see
    //          http://thrill-project.com/archiv/coding/bitmap/
    //          https://blog.thrill-project.com/ascii-art-shader/
    // p (float2): the pixel's position on the quad

    // scale and align the pixel coordinates to match the 5x5 grid
    p = floor(p*float2(4.0, 4.0) + 2.5);

    if (clamp(p.x, 0.0, 4.0) == p.x)
    {
        if (clamp(p.y, 0.0, 4.0) == p.y)	
        {
            // Convert (x, y) grid coordinates into a bit position (0 to 24).
	        int a = int(round(p.x) + 5.0 * round(p.y));
            // ((n >> a) & 1) extracts bit as position a
            // n >> a shifts bits of n right by a positions
            // & 1 isolates the least significant bit
            // if it's 1 return 1.0, else fall out and return 0.0
            if (((n >> a) & 1) == 1) return 1.0;
        }	
    }
    return 0.0;
}

float2 mod(float2 x, float2 y)
{
    return x - y * floor(x/y);
}

float4 mainImage( VertData v_in ) : TARGET
{
    float2 iResolution = uv_size*uv_scale;
    float2 pix = v_in.pos.xy;
    float4 c = image.Sample(textureSampler, floor(pix/float2(scale*8.0,scale*8.0))*float2(scale*8.0,scale*8.0)/iResolution.xy);

    float gray = 0.3 * c.r + 0.59 * c.g + 0.11 * c.b;
	
    int n;
    // int charset = clamp(character_set, 0, 2);

    if (character_set==0) {
        if (gray <= 0.2) n = 4096;     // .
        if (gray > 0.2)  n = 65600;    // :
        if (gray > 0.3)  n = 332772;   // *
        if (gray > 0.4)  n = 15255086; // o 
        if (gray > 0.5)  n = 23385164; // &
        if (gray > 0.6)  n = 15252014; // 8
        if (gray > 0.7)  n = 13199452; // @
        if (gray > 0.8)  n = 11512810; // #
    } else if (character_set==1) {
        if (gray <= 0.1) n = 0;
        if (gray > 0.1)  n = 9616687; // R
        if (gray > 0.3)  n = 32012382; // S
        if (gray > 0.5)  n = 16303663; // D
        if (gray > 0.7)  n = 15255086; // O
        if (gray > 0.8)  n = 16301615; // B
    } else if (character_set==2) {
        // full character set including A-Z and 0-9
        if (gray > 0.0233) n = 4096;
        if (gray > 0.0465) n = 131200;
        if (gray > 0.0698) n = 4329476;
        if (gray > 0.0930) n = 459200;
        if (gray > 0.1163) n = 4591748;
        if (gray > 0.1395) n = 12652620;
        if (gray > 0.1628) n = 14749828;
        if (gray > 0.1860) n = 18393220;
        if (gray > 0.2093) n = 15239300;
        if (gray > 0.2326) n = 17318431;
        if (gray > 0.2558) n = 32641156;
        if (gray > 0.2791) n = 18393412;
        if (gray > 0.3023) n = 18157905;
        if (gray > 0.3256) n = 17463428;
        if (gray > 0.3488) n = 14954572;
        if (gray > 0.3721) n = 13177118;
        if (gray > 0.3953) n = 6566222;
        if (gray > 0.4186) n = 16269839;
        if (gray > 0.4419) n = 18444881;
        if (gray > 0.4651) n = 18400814;
        if (gray > 0.4884) n = 33061392;
        if (gray > 0.5116) n = 15255086;
        if (gray > 0.5349) n = 32045584;
        if (gray > 0.5581) n = 18405034;
        if (gray > 0.5814) n = 15022158;
        if (gray > 0.6047) n = 15018318;
        if (gray > 0.6279) n = 16272942;
        if (gray > 0.6512) n = 18415153;
        if (gray > 0.6744) n = 32641183;
        if (gray > 0.6977) n = 32540207;
        if (gray > 0.7209) n = 18732593;
        if (gray > 0.7442) n = 18667121;
        if (gray > 0.7674) n = 16267326;
        if (gray > 0.7907) n = 32575775;
        if (gray > 0.8140) n = 15022414;
        if (gray > 0.8372) n = 15255537;
        if (gray > 0.8605) n = 32032318;
        if (gray > 0.8837) n = 32045617;
        if (gray > 0.9070) n = 33081316;
        if (gray > 0.9302) n = 32045630;
        if (gray > 0.9535) n = 33061407;
        if (gray > 0.9767) n = 11512810;
    } else if (character_set == 3) {
        // thades mode
        if (gray > 0.0)  n = 0;     // .
        if (gray > 0.12)  n = 131072;     // :
        if (gray > 0.25)  n = 19267584;     // o
        if (gray > 0.38)  n = 27398528;     // &
        if (gray > 0.5)  n = 11513856;     // #
        if (gray > 0.62)  n = 19286976;     // 8
        if (gray > 0.75)  n = 31045632;     // @
        if (gray > 0.88)  n = 5241984;     // *
    } else if (character_set == 4) {
        // thades mode extra
        if (gray > 0.0)  n = 0;     // .
        if (gray > 0.05)  n = 131072;     // :
        if (gray > 0.1)  n = 4325376;     // ¿
        if (gray > 0.14)  n = 19267584;     // o
        if (gray > 0.19)  n = 983040;     // ~
        if (gray > 0.24)  n = 2164768;     // \
        if (gray > 0.29)  n = 19464192;     // µ
        if (gray > 0.33)  n = 4329664;     // 1
        if (gray > 0.38)  n = 10944512;     // ¤
        if (gray > 0.43)  n = 11411456;     // ¢
        if (gray > 0.48)  n = 27398528;     // &
        if (gray > 0.52)  n = 10684608;     // §
        if (gray > 0.57)  n = 9741504;     // Ω
        if (gray > 0.62)  n = 11513856;     // #
        if (gray > 0.67)  n = 33488896;     // æ
        if (gray > 0.71)  n = 19286976;     // 8
        if (gray > 0.76)  n = 31045632;     // @
        if (gray > 0.81)  n = 5220896;     // ¥
        if (gray > 0.86)  n = 5241984;     // *
        if (gray > 0.9)  n = 10857952;     // ¶
        if (gray > 0.95)  n = 16371136;     // ☺
    }

    float2 p = mod(pix/float2(scale*4.0,scale*4.0),float2(2.0,2.0)) - float2(1.0,1.0);
	
    if (monochrome)
    {
        c.rgb = base_color.rgb;
    }
    c = c*character(n, p);
    
    return c;
}
