module aliasthis.utils;

public import std.random;

import std.algorithm,
       std.math;

import turtle;

RGB lerpColor(RGB a, RGB b, float t) pure nothrow
{
    vec3f af = vec3f(a.r, a.g, a.b);
    vec3f bf = vec3f(b.r, b.g, b.b);
    vec3f of = af * (1 - t) + bf * t;
    return RGB( cast(ubyte)(0.5f + of.r), cast(ubyte)(0.5f + of.g), cast(ubyte)(0.5f + of.b) );
}


RGBA lerpColor(RGBA a, RGBA b, float t) pure nothrow
{
    vec4f af = vec4f(a.r, a.g, a.b, a.a);
    vec4f bf = vec4f(b.r, b.g, b.b, b.a);
    vec4f of = af * (1 - t) + bf * t;
    return RGBA( cast(ubyte)(0.5f + of.r), cast(ubyte)(0.5f + of.g), cast(ubyte)(0.5f + of.b), cast(ubyte)(0.5f + of.a) );
}

RGB colorFog(RGB color, int levelDifference) pure nothrow
{
    assert(levelDifference >= 0);
    if (levelDifference == 0)
        return color;

    vec3f fcolor = vec3f(color.r, color.g, color.b) / 255.0f;

    fcolor *= 0.3f; // darken

    vec3f hsv = rgb2hsv(fcolor);

    hsv.y *= (1.5f ^^ (-levelDifference));

    vec3f beforeFog = hsv2rgb(hsv);
    vec3f fog = vec3f(0.0f,0.0f,0.02f);

    float t = levelDifference / 2.5f;
    if (t < 0) t = 0;
    if (t > 1) t = 1;

    vec3f foggy = beforeFog * (1 - t) + t * fog;
    return RGB(cast(ubyte)(0.5f + foggy.r * 255.0f),
               cast(ubyte)(0.5f + foggy.g * 255.0f),
               cast(ubyte)(0.5f + foggy.b * 255.0f));
}

RGBA colorFog(RGBA color, int levelDifference) pure nothrow
{
    RGB rgb = colorFog(RGB(color.r, color.g, color.b), levelDifference);
    return RGBA(rgb.r, rgb.g, rgb.b, color.a);
}

// gaussian color SV perturbation
RGB perturbColorSV(RGB color, float Samount, float Vamount, ref Xorshift rng)
{
    vec3f fcolor = vec3f(color.r, color.g, color.b) / 255.0f;
    vec3f hsv = rgb2hsv(fcolor);

    hsv.y += randNormal() * Samount;
    hsv.z += randNormal() * Vamount;

    if (hsv.y < 0) hsv.y = 0; 
    if (hsv.y > 1) hsv.y = 1;
    if (hsv.z < 0) hsv.z = 0; 
    if (hsv.z > 1) hsv.z = 1;

    vec3f rgb = hsv2rgb(hsv);
    return RGB(cast(ubyte)(0.5f + rgb.x * 255.0f),
               cast(ubyte)(0.5f + rgb.y * 255.0f),
               cast(ubyte)(0.5f + rgb.z * 255.0f));
}

RGBA perturbColorSV(RGBA color, float Samount, float Vamount, ref Xorshift rng)
{
    RGB rgb = perturbColorSV(RGB(color.r, color.g, color.b), Samount, Vamount, rng);
    return RGBA(rgb.r, rgb.g, rgb.b, color.a);
}

/**
  This module defines RGB <-> HSV conversions.
*/

// RGB <-> HSV conversions.

/// Converts a RGB triplet to HSV.
/// Authors: Sam Hocevar 
/// See_also: $(WEB http://lolengine.net/blog/2013/01/13/fast-rgb-to-hsv)
vec3f rgb2hsv(vec3f rgb) pure nothrow
{
    float K = 0.0f;

    if (rgb.y < rgb.z)
    {
        swap(rgb.y, rgb.z);
        K = -1.0f;
    }

    if (rgb.x < rgb.y)
    {
        swap(rgb.x, rgb.y);
        K = -2.0f / 6.0f - K;
    }

    float chroma = rgb.x - (rgb.y < rgb.z ? rgb.y : rgb.z);
    float h = abs(K + (rgb.y - rgb.z) / (6.0f * chroma + 1e-20f));
    float s = chroma / (rgb.x + 1e-20f);
    float v = rgb.x;

    return vec3f(h, s, v);
}

/// Convert a HSV triplet to RGB.
/// Authors: Sam Hocevar.
/// See_also: $(WEB http://lolengine.net/blog/2013/01/13/fast-rgb-to-hsv).
vec3f hsv2rgb(vec3f hsv) pure nothrow
{
    float S = hsv.y;
    float H = hsv.x;
    float V = hsv.z;

    vec3f rgb;

    if ( S == 0.0 ) 
    {
        rgb.x = V;
        rgb.y = V;
        rgb.z = V;
    } 
    else 
    {        
        if (H >= 1.0) 
        {
            H = 0.0;
        } 
        else 
        {
            H = H * 6;
        }
        int I = cast(int)H;
        assert(I >= 0 && I < 6);
        float F = H - I;     /* fractional part */

        float M = V * (1 - S);
        float N = V * (1 - S * F);
        float K = V * (1 - S * (1 - F));

        if (I == 0) { rgb.x = V; rgb.y = K; rgb.z = M; }
        if (I == 1) { rgb.x = N; rgb.y = V; rgb.z = M; }
        if (I == 2) { rgb.x = M; rgb.y = V; rgb.z = K; }
        if (I == 3) { rgb.x = M; rgb.y = N; rgb.z = V; }
        if (I == 4) { rgb.x = K; rgb.y = M; rgb.z = V; }
        if (I == 5) { rgb.x = V; rgb.y = M; rgb.z = N; }
    }
    return rgb;
}
