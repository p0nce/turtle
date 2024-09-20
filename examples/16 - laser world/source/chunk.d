module chunk;

import biomes;
import worldref;

enum CHUNK_WIDTH = 16;
enum CHUNK_HEIGHT = 16;
struct ChunkKey
{
    int xDiv;  // x coord divided by CHUNK_WIDTH, rounded down
    int yDiv;  // y coord divided by CHUNK_HEIGHT, rounded down

    int opCmp(const(ChunkKey) other) const nothrow @nogc
    {
        if (xDiv == other.xDiv)
            return yDiv - other.yDiv;
        else
            return xDiv - other.xDiv;
    }
}

void worldCoordToChunkCoord(int world_x, int world_y,
                            out int xDiv, out int yDiv,
                            out int xRem, out int yRem)
{
    // This needs integer floor rounding, so was separated to own function
    // We need to round DOWN, while in C++ division rounds towards ZERO.

    if (world_x >= 0)
    {
        xDiv = world_x / CHUNK_WIDTH;
        xRem = world_x % CHUNK_WIDTH;
    }
    else
    {
        xDiv = (world_x - (CHUNK_WIDTH-1)) / CHUNK_WIDTH;
        xRem = world_x - (xDiv * CHUNK_WIDTH);
    }

    if (world_y >= 0)
    {
        yDiv = world_y / CHUNK_WIDTH;
        yRem = world_y % CHUNK_WIDTH;
    }
    else
    {
        yDiv = (world_y - (CHUNK_WIDTH-1)) / CHUNK_WIDTH;
        yRem = world_y - (yDiv * CHUNK_WIDTH);
    }
    assert(xRem >= 0 && xRem < CHUNK_WIDTH);
    assert(yRem >= 0 && yRem < CHUNK_WIDTH);
}

// Should store cached biome + objects in there.
// Chunk have CHUNK_WIDTH x CHUNK_HEIGHT biome data.
// TODO: add objects
class Chunk
{
    // Position in world
    int x, y;

    BiomeType[CHUNK_WIDTH*CHUNK_HEIGHT] biome;

    this(int x, int y, WorldReference worldRef)
    {
        this.x = x;
        this.y = y;
        worldRef.generateBiomeData(x, y, CHUNK_WIDTH, CHUNK_HEIGHT, biome[]);
    }

    BiomeType biomeAt(int local_x, int local_y)
    {
        return biome[ local_x + local_y * CHUNK_WIDTH ];
    }
}