module vxlgen.terrain;

import std.stdio;
import std.math;

import dplug.core.math;
import vxlgen.block;
import dplug.math.vector;
import vxlgen.aosmap;
import vxlgen.randutils;
import vxlgen.simplexnoise;

final class Tree : IBlockStructure
{
public:
    vec3i pos;
    int height;
    vec3f trunkColor;
    vec3f foliageColor;
    float conifere;

    this(vec3i pos, int height, vec3f foliageColor, vec3f trunkColor, float conifere)
    {
        this.pos = pos;
        this.height = height;
        this.foliageColor = foliageColor;
        this.trunkColor = trunkColor;
        this.conifere = conifere;
    }

    void buildBlocks(ref Random rng, AOSMap map)
    {
        int trunkSize = height / 2;
        if (trunkSize > 3)
            trunkSize = 3;

        double maxRadius = 1.0 + (height - trunkSize) * 0.33;
        double minRadius = 0.2;
        double skewNess = 0.8 + randUniform(rng) * 0.4;

        // cast shadow
        // trunk
        for (int i = -3; i < height; ++i)
        {
            int iradius = cast(int)(maxRadius) + 1;
            for (int x = -iradius; x <= iradius; ++x)
            {
                for (int y = -iradius; y <= iradius; ++y)
                {
                    double dist = cast(double)(x * x + y * y);
                    if (dist < maxRadius * maxRadius)
                    if (map.contains(vec3i(pos.x + x, pos.y + y, pos.z + i)))
                    {
                        Block* bl = &map.block(pos.x + x, pos.y + y, pos.z + i);
                        bl.r = cast(ubyte)(bl.r * 0.7f);
                        bl.g = cast(ubyte)(bl.g * 0.7f);
                        bl.b = cast(ubyte)(bl.b * 0.7f);
                    }
                }
            }        
        }

        // trunk
        for (int i = 0; i < trunkSize; ++i)
        {
            map.block(pos.x, pos.y, pos.z + i).setf(trunkColor);
        }



        for (int i = trunkSize; i < height; ++i)
        {
            double t = (i - trunkSize) / cast(double)(height - 1 - trunkSize);
            t = clampd(t, 0.0, 1.0);
            double radius = 1.4 * lerp(maxRadius, minRadius, t ^^ skewNess);
            int iradius = cast(int)(radius) + 1;
            for (int x = -iradius; x <= iradius; ++x)
                for (int y = -iradius; y <= iradius; ++y)
                {
                    vec3i pp = vec3i(pos.x + x, pos.y + y, pos.z + i);
                    double dist = sqrt(cast(double)(x * x + y * y));
                    dist *= (0.8 + 0.4 * randUniform(rng));
                    if (map.contains(pp) && dist < radius)
                        map.block(pp).setf(foliageColor);
                }
        }
    }

}


class Terrain : IBlockStructure
{
public:

    float[] height; // height map
    float[] vegetation; // amount of trees map
    Tree[] trees;
    vec2i mapDim;

    this(vec2i mapDim, ref Random rng)
    {
        this.mapDim = mapDim;
        makeHeightMap(rng);
        makeVegetation(rng);
    }

    void makeHeightMap(ref Random rng)
    {
        writefln("Make height map...");
        int NUM_OCT = 8;
        SimplexNoise!Random[] noises = new SimplexNoise!Random[NUM_OCT];
        for (int oct = 0; oct < NUM_OCT; ++oct)
        {
            noises[oct] = new SimplexNoise!Random(rng);        
        }

        height.length = mapDim.x * mapDim.y;
        height[] = 0;

        for (int y = 0; y < mapDim.y; ++y)
        {
            for (int x = 0; x < mapDim.x; ++x)
            {  
                double fx = x / cast(double)mapDim.x;
                double fy = y / cast(double)mapDim.y;
                double z = 3;

                for (int oct = 0; oct < NUM_OCT; ++oct)
                {
                    double freq = 2.0 ^^ oct;
                    double zo = (noises[oct].noise(fx * freq, fy * freq));
                    double amplitude = 44 * 2.0 ^^ (-oct);
                    z += zo * amplitude;
                }

                if (z > 62) 
                    z = 62;
                if (z >= 1) 
                {
                    z = 1 + (((z - 1) / 62.0) ^^ 2.0) * 62.0;
                }
                if (z > 54) 
                    z = 54 + log2(z - 53);

                double distanceToCenter = vec2f(x, y).distanceTo(vec2f(255,255));
                double heightIdeal = 7;
                z = lerp(z, heightIdeal, clampd(2 - distanceToCenter * 0.012, 0, 1));
                height[y * mapDim.x + x] = z;          
            }
        }
    }

    void makeVegetation(ref Random rng)
    {
        writefln("Make vegetation layer...");
        int NUM_OCT = 4;
        SimplexNoise!Random[] noises = new SimplexNoise!Random[NUM_OCT];
        for (int oct = 0; oct < NUM_OCT; ++oct)
        {
            noises[oct] = new SimplexNoise!Random(rng);        
        }

        vegetation.length = mapDim.x * mapDim.y;
        for (int y = 0; y < mapDim.y; ++y)
        {
            for (int x = 0; x < mapDim.x; ++x)
            {  
                double fx = x / cast(double)mapDim.x;
                double fy = y / cast(double)mapDim.y;
                double veg = 0.0;

                for (int oct = 0; oct < NUM_OCT; ++oct)
                {
                    double freq = 2.0 ^^ oct;
                    double amplitude = 1 * 2.0 ^^ (-oct);
                    double noise = (noises[oct].noise(fx * freq, fy * freq));
                    veg += noise * amplitude;
                }

                double h =height[y * mapDim.x + x];
                if (h < 1) 
                    veg = 0;
                if (h > 24)
                    veg *= clampd(1.0 - (veg - 24.0) / 24.0, 0.0, 1.0);

                double distanceToCenter = vec2f(x, y).distanceTo(vec2f(255, 255));
                double vegIdeal = 0;
                veg = lerp(veg, vegIdeal, clampd(2 - distanceToCenter * 0.012, 0, 1));

                vegetation[y * mapDim.x + x] = clampd(veg, 0.0, 1.0);
            }
        }

        // add trees
        for (int y = 0; y < mapDim.y; ++y)
        {
            for (int x = 0; x < mapDim.x; ++x)
            {
                int h = cast(int)(0.5 + height[y * mapDim.x + x]);
                if (h < 1) 
                    h = 0;
                if (h > 62) 
                    h = 62;

                if (h > 1 && randUniform(rng) < vegetation[y * mapDim.x + x] * 0.05)
                {
                    int height = rdice(rng, 5, 10);// cast(int)(0.5 + 3 + (randUniform(rng) ^^ 2.2) * 5);
                    if (h + height < 62)
                    {
                        vec3f trunkColor = vec3f(116, 84, 52) / 255.0f;
                        vec3f green = vec3f(81, 137, 56) / 255.0f;
                        vec3f yellow = vec3f(175, 171, 3) / 255.0f;
                        vec3f darkGreen = vec3f(54, 103, 37) / 255.0f;
                        
                        trunkColor = lerp(trunkColor, vec3f(60, 0, 17) / 255.0f, randUniform(rng));                        

                        float a = randUniform(rng) + 0.1f;
                        float b = randUniform(rng);
                        float c = randUniform(rng);

                        vec3f foliageColor = (green * a + yellow * b + darkGreen * c) / (a + b + c);

                        trunkColor += randomPerturbation(rng) * 0.02;
                        foliageColor += randomPerturbation(rng) * 0.04;

                        if (h > 40)
                        {
                            vec3f white = vec3f(1,1,1);
                            float t = clampf((h - 40.0f) / (48.0f - 32.0f), 0.0f, 1.0f);
                            trunkColor = lerp(trunkColor, white, t);
                            foliageColor = lerp(foliageColor, white, t);
                        }

                        trees ~= new Tree(vec3i(x, y, h + 1), height, foliageColor, trunkColor, 0);

                        // remove trees arounds (TODO relaxation?)
                        for (int i = -4; i < 5; ++i)
                            for (int j = -4; j < 5; ++j)
                            {
                                int ix = (y + j + mapDim.y) % mapDim.y;
                                int iy = (x + i + mapDim.x) % mapDim.x;
                                vegetation[iy * mapDim.x + ix] = 0;
                            }
                    }
                }
            }
        }
    }

    void buildBlocks(ref Random rng, AOSMap map)
    {
        writefln("Render terrain...");
        // render height
        for (int y = 0; y < mapDim.y; ++y)
        {
            for (int x = 0; x < mapDim.x; ++x)
            {       
                float z = height[y * mapDim.x + x];

                int h = cast(int)(0.5 + z);
                if (h < 1) 
                    h = 0;
                if (h > 62) 
                    h = 62;

                for (int k = 0; k <= h; ++k)
                {
                    vec3f color = void;

                    // water color
                    if (k == 0)
                    {
                        vec3f lightBlue = vec3f(90 / 255.0f, 148 / 255.0f, 237 / 255.0f);
                        vec3f darkBlue = vec3f(32, 38, 119) / 255.0f;
                        float t = clampf(-(z-0.5f) * 0.1f, 0.0f, 1.0f);
                        color = lerp(lightBlue, darkBlue, t);
                    }
                    else if (k == 1)
                    {
                        color = vec3f(0.9, 0.9, 0.9);
                        color += randomPerturbation(rng) * 0.015f;
                    }
                    else if (k == 2)
                    {
                        vec3f sand = color = vec3f(0.9, 0.9, 0.9);
                        vec3f green = vec3f(168 / 255.0f, 194 / 255.0f, 75 / 255.0f);
                        color = (sand + green) / 2;
                        color += randomPerturbation(rng) * 0.015f;
                    }
                    else if (k < 16)
                    {
                        vec3f green = vec3f(168 / 255.0f, 194 / 255.0f, 75 / 255.0f);
                        vec3f marron = vec3f(118 / 255.0f, 97 / 255.0f, 56 / 255.0f);
                        color = lerp(green, marron, (k - 2.0f) / (16.0f - 2.0f));
                        color += randomPerturbation(rng) * 0.025f;
                    }
                    else if (k < 32)
                    {
                        vec3f marron = vec3f(118 / 255.0f, 97 / 255.0f, 56 / 255.0f);
                        vec3f grey = vec3f(0.6f, 0.6f, 0.6f);
                        float t = (k - 16.0f) / (32.0f - 16.0f);
                        color = lerp(marron, grey, (k - 16.0f) / (32.0f - 16.0f));
                        color += randomPerturbation(rng) * (0.02f - t * 0.01f);
                    }
                    else if (k < 48)
                    {
                        vec3f grey = vec3f(0.6f, 0.6f, 0.6f);
                        vec3f white = vec3f(1,1,1);
                        color = lerp(grey, white, (k - 32.0f) / (48.0f - 32.0f));
                        color += randomPerturbation(rng) * 0.01f;
                    }
                    else
                    {
                        color = vec3f(1,1,1);
                        color += randomPerturbation(rng) * 0.01f;
                    }

                    map.block(x, y, k).setf(color);
                }            
            }
        }

        // render trees
        foreach(ref tree; trees)
        {
            tree.buildBlocks(rng, map);
        }
    }
}

