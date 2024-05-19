module vxlgen.randutils;


import std.random;
import std.math;

public alias Random = Xorshift64;


float clampf(float x, float min, float max)
{
    if (x < min) x = min;
    if (x > max) x = max;
    return x;
}

double clampd(double x, double min, double max)
{
    if (x < min) x = min;
    if (x > max) x = max;
    return x;
}

//public import gfm.math.simplerng;
import dplug.math.vector;
import dplug.core.math;

int rdice(ref Random rng, int min, int max)
{
    assert(max > min);
    int res = uniform(min, max, rng);
    assert(res >= min && res < max);
    return res;
}

double randNormal(ref Random rng, double mean = 0.0, double standardDeviation = 1.0)
{
    assert(standardDeviation > 0);
    double u1;

    do
    {
        u1 = uniform01(rng);
    } while (u1 == 0); // u1 must not be zero
    double u2 = uniform01(rng);
    double r = sqrt(-2.0 * log(u1));
    double theta = 2.0 * double(PI) * u2;
    return mean + standardDeviation * r * sin(theta);
}

vec3f randomPerturbation(ref Random rng)
{
    return vec3f(rng.randNormal(0, 1), rng.randNormal(0, 1), rng.randNormal(0, 1));
}

vec3f randomColor(ref Random rng)
{
    return vec3f(rng.randUniform(), rng.randUniform(), rng.randUniform());
}

bool randBool(ref Random rng)
{
    return uniform(0, 2, rng) != 0;
}

double randUniform(ref Random rng)
{
    return uniform(0.0, 1.0, rng);    
}

vec2i randomDirection(ref Random rng)
{
    int dir = rdice(rng, 0, 4);
    if (dir == 0)
        return vec2i(1, 0);
    if (dir == 1)
        return vec2i(-1, 0);
    if (dir == 2)
        return vec2i(0, 1);
    if (dir == 3)
        return vec2i(0, -1);
    assert(false);
}

// only 2D rotation along z axis
vec3i rotate(vec3i v, vec3i direction)
{
    if (direction == vec3i(1, 0, 0))
    {
        return v;
    }
    else if (direction == vec3i(-1, 0, 0))
    {
        return vec3i (-v.x, -v.y, v.z);
    }
    else if (direction == vec3i(0, 1, 0))
    {
        return vec3i( -v.y, v.x, v.z);
    }
    else if (direction == vec3i(0, -1, 0))
    {
        return vec3i( v.y, -v.x, v.z);
    }
    else 
        assert(false);
}

vec3f grey(vec3f color, float fraction)
{
    float g = (color.x + color.y + color.z) / 3;
    return lerp(color, vec3f(g, g, g), fraction);
}