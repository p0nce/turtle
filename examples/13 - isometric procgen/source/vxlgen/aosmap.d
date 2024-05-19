module vxlgen.aosmap;

import std.stdio;
import std.file;

import vxlgen.block;
import vxlgen.randutils;
import dplug.math.box;
import dplug.math.vector;
import dplug.core.math;

enum GROUND_LEVEL = 1;
enum WATER_LEVEL = 0;

interface IBlockStructure
{
    void buildBlocks(ref Random rng, AOSMap map);
}

final class AOSMap
{
public:

    this()
    {   
        _blocks.length = 512 * 512 * 64;
    }

    box3i worldBox()
    {
        return box3i(0, 0, 0, 512, 512, 62);
    }

    bool contains(vec3i v)
    {
        return contains(v.x, v.y, v.z);
    }

    bool contains(int x, int y, int z)
    {
        if (cast(uint)x >= 512)
            return false;
        if (cast(uint)y >= 512)
            return false;
        if (cast(uint)z >= 64)
            return false;
        return true;
    }

    ref Block block(int x, int y, int z)
    {
        assert(contains(x, y, z));
        z = 63 - z;       
        int index = z + y * 64 + x * 64 * 512;
        return _blocks[index];
    }

    ref Block block(vec3i v)
    {
        return block(v.x, v.y, v.z);
    }

    void writeMap(string filename)
    {
        ubyte[] buf = getBytes();
        std.file.write(filename, buf);
    }

    enum MAP_Z = 64;

    ubyte[] getBytes()
    {
        ubyte[] res;        

        int i,j,k;

        for (j=0; j < 512; ++j) {
            for (i=0; i < 512; ++i) {
                int written_colors = 0;
                int backpatch_address = -1;
                int previous_bottom_colors = 0;
                int current_bottom_colors = 0;
                int middle_start = 0;

                k = 0;
                while (k < MAP_Z) {
                    int z;

                    int air_start;
                    int top_colors_start;
                    int top_colors_end; // exclusive
                    int bottom_colors_start;
                    int bottom_colors_end; // exclusive
                    int top_colors_len;
                    int bottom_colors_len;
                    int colors;

                    // find the air region
                    air_start = k;
                    while (k < MAP_Z && !block(i, j, 63 - k).isSolid)
                        ++k;

                    // find the top region
                    top_colors_start = k;
                    while (k < MAP_Z && is_surface(i,j,k))
                        ++k;
                    top_colors_end = k;

                    // now skip past the solid voxels
                    while (k < MAP_Z && block(i, j, 63 - k).isSolid && !is_surface(i,j,k))
                        ++k;

                    // at the end of the solid voxels, we have colored voxels.
                    // in the "normal" case they're bottom colors; but it's
                    // possible to have air-color-solid-color-solid-color-air,
                    // which we encode as air-color-solid-0, 0-color-solid-air

                    // so figure out if we have any bottom colors at this point
                    bottom_colors_start = k;

                    z = k;
                    while (z < MAP_Z && is_surface(i,j,z))
                        ++z;

                    if (z == MAP_Z || 0)
                    {
                        // in this case, the bottom colors of this span are empty, because we'll emit as top colors
                    }
                    else {
                        // otherwise, these are real bottom colors so we can write them
                        while (is_surface(i,j,k))  
                            ++k;
                    }
                    bottom_colors_end = k;

                    // now we're ready to write a span
                    top_colors_len    = top_colors_end    - top_colors_start;
                    bottom_colors_len = bottom_colors_end - bottom_colors_start;

                    colors = top_colors_len + bottom_colors_len;

                    void outputByte(ubyte c)
                    {
                        res ~= c;                        
                    }

                    if (k == MAP_Z)                        
                        outputByte(0);
                    else
                        outputByte(cast(ubyte)(colors+1));

                    outputByte(cast(ubyte)top_colors_start);
                    outputByte(cast(ubyte)(top_colors_end-1));
                    outputByte(cast(ubyte)air_start);

                    void write_color(int i, int j, int k)
                    {
                        Block b = block(i, j, 63 - k);

                        // assume color is ARGB native, but endianness is unknown

                        ubyte[4] c;
                        c[0] = b.b;
                        c[1] = b.g;
                        c[2] = b.r;

                        // never store R = G = B = 0 since it would be invisible
                        if ((c[0] == 0) && (c[1] == 0) && (c[2] == 0))
                            c[0] = 1;

                        c[3] = 255; // always store 255 for alpha

                        // file format endianness is ARGB little endian, i.e. B,G,R,A
                        for (int l = 0; l < 4; ++l)
                            res ~= c[l];
                    }

                    for (z=0; z < top_colors_len; ++z)
                        write_color(i, j, top_colors_start + z);
                    for (z=0; z < bottom_colors_len; ++z)
                        write_color(i, j, bottom_colors_start + z);
                }  
            }
        }
        return res;
    }

    void clearBox(box3i b)
    {
        for (int x = b.min.x; x < b.max.x; ++x)
            for (int y = b.min.y; y < b.max.y; ++y)
                for (int z = b.min.z; z < b.max.z; ++z)
                    block(x, y, z).empty();
    }

    // try to reverse ugly AO from AoS client
    void reverseClientAO()
    {
        for (int y=0; y < 512; ++y) 
        {
            for (int x=0; x < 512; ++x) 
            {
                for (int z = 1; z < 63; ++z)
                {
                    Block* fb = &block(x, y, z);
                    if (fb.isSolid)
                    {
                        // compute AO length
                        vec3i AOdirection = vec3i(0, -1, 1);
                        int obstruction = 0;
                        for (int i = 1; i <= 9; ++i)
                        {
                            vec3i p = vec3i(x, y, z) + AOdirection * i;
                            if (contains(p) && block(p).isSolid)
                                obstruction++;          
                        }
                        float fact = 1.0f - 0.5f * obstruction / 9.0f;
                        float invFact = 1.0f / fact;
                        ubyte newR = cast(ubyte)(0.5f + clampf(fb.r * invFact, 0.0f, 255.0f));
                        ubyte newG = cast(ubyte)(0.5f + clampf(fb.g * invFact, 0.0f, 255.0f));
                        ubyte newB = cast(ubyte)(0.5f + clampf(fb.b * invFact, 0.0f, 255.0f));
                        
/*
                        float add = -10.0f * obstruction;
                        //float invFact = 1.0f / fact;
                        ubyte newR = cast(ubyte)(0.5f + clamp(fb.r - add, 0.0f, 255.0f));
                        ubyte newG = cast(ubyte)(0.5f + clamp(fb.g - add, 0.0f, 255.0f));
                        ubyte newB = cast(ubyte)(0.5f + clamp(fb.b - add, 0.0f, 255.0f));
                        */
fb.r = newR;
                        fb.g = newG;
                        fb.b = newB;
                    }
                }
            }
        }
    }

    void colorBleed()
    {
        for (int y=0; y < 512; ++y) 
        {
            for (int x=0; x < 512; ++x) 
            {
                for (int z = 1; z < 63; ++z)
                {
                    Block* fb = &block(x, y, z);
                    if (fb.isSolid)
                    {
                        float count = 0;
                        float r = 0;
                        float g = 0;
                        float b = 0;
                        void tryBlock(int i, int j, int k, int weight = 1)
                        {
                            if (contains(i, j, k))
                            {
                                Block bl = block(i, j, k);
                                if (bl.isSolid)
                                {
                                    r += bl.r * weight;
                                    g += bl.g * weight;
                                    b += bl.b * weight;
                                    count += weight;
                                }
                            }
                        }
                        tryBlock(x, y, z, 20);
                        // compute luminance
                        float Y = 0.6f * fb.g + 0.3f * fb.r + 0.1f * fb.b;
                        tryBlock(x - 1, y, z);
                        tryBlock(x + 1, y, z);
                        tryBlock(x, y - 1, z);
                        tryBlock(x, y + 1, z);
                        tryBlock(x, y, z - 1);
                        tryBlock(x, y, z + 1);

                        if (count > 0)
                        {
                            float invCount = 1.0f / count;
                            float beforeR = r * invCount;
                            float beforeG = g * invCount;
                            float beforeB = b * invCount;
                            float Y2 = 0.6f * beforeG + 0.1f * beforeB + 0.3f * beforeR;
                            float scale = Y / (Y2 + 0.01f);
                            ubyte finalR = cast(ubyte)(0.5 + clampf(beforeR * scale, 0, 255));
                            ubyte finalG = cast(ubyte)(0.5 + clampf(beforeG * scale, 0, 255));
                            ubyte finalB = cast(ubyte)(0.5 + clampf(beforeB * scale, 0, 255));                        
                            fb.r = finalR;
                            fb.g = finalG;
                            fb.b = finalB;
                        }
                    }
                }
            }
        }
    }

    void betterAO()
    {
        for (int y=0; y < 512; ++y) 
        {
            for (int x=0; x < 512; ++x) 
            {
                for (int z = 1; z < 63; ++z)
                {
                    Block* fb = &block(x, y, z);
                    if (fb.isSolid)
                    {
                        int occlusion = 0;
                        void tryBlock(int i, int j, int k) // return true if not occluding
                        {
                            if (contains(i, j, k))
                            {
                                Block bl = block(i, j, k);
                                if (bl.isSolid)
                                {
                                    occlusion++;
                                }
                            }
                        }

                        for (int i = -1; i <= 1; ++i)
                            for (int j = -1; j <= 1; ++j)
                                for (int k = 0; k <= 1; ++k)
                                {
                                    tryBlock(x + j, y + i, z + k);
                                }

                        float occluded = clampf(occlusion / 18.0f, 0.0f, 1.0f);
                        float scale = 1.4f - occluded * 0.8f;
                        ubyte finalR = cast(ubyte)(0.5 + clampf(fb.r * scale, 0, 255));
                        ubyte finalG = cast(ubyte)(0.5 + clampf(fb.g * scale, 0, 255));
                        ubyte finalB = cast(ubyte)(0.5 + clampf(fb.b * scale, 0, 255));     
                        fb.r = finalR;
                        fb.g = finalG;
                        fb.b = finalB;
                    }
                }
            }
        }
    }

private:
    Block[] _blocks;

    Block _nilBlock;

    bool is_surface(int x, int y, int z)
    {
        z = 63 - z;
        if (!block(x, y, z).isSolid) return false;
        if (x   >   0 && !block(x-1, y, z).isSolid) return true;
        if (x+1 < 512 && !block(x+1, y, z).isSolid) return true;
        if (y   >   0 && !block(x, y-1, z).isSolid) return true;
        if (y+1 < 512 && !block(x, y+1, z).isSolid) return true;
        if (z   >   0 && !block(x, y, z-1).isSolid) return true;
        if (z+1 <  64 && !block(x, y, z+1).isSolid) return true;
        return false;
    }
}
