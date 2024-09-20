module world;

import std.random;
import dplug.graphics;
import turtle;
import gamut;
import worldref;
import biomes;
import chunk;

import dplug.core.map;


// This has a chunk cache, but there is no serialization/deserialization,
// not is there entities.
class World
{
    this(uint seed)
    {
        _seed = seed;
        _worldRef = new WorldReference(seed);
    }

    BiomeType biomeAt(int x, int y)
    {
        int xDiv, yDiv, xRem, yRem;
        worldCoordToChunkCoord(x, y, xDiv, yDiv, xRem, yRem);
        return getChunk(xDiv, yDiv).biomeAt(xRem, yRem);
    }

    Chunk getChunk(int xDiv, int yDiv)
    {
        ChunkKey key = ChunkKey(xDiv, yDiv);

        Chunk* c = key in _chunkCache;
        if (c) 
            return *c;
        else
        {
            // lazy new chunk creation
            Chunk r = new Chunk(xDiv*CHUNK_WIDTH, yDiv*CHUNK_HEIGHT, _worldRef);
            import std;
            writefln("insert chunk %s %s", xDiv, yDiv);
            bool inserted = _chunkCache.insert(key, r);
            assert(inserted);
            return r;
        }
    }

private:
    WorldReference _worldRef;
    uint _seed;
    Map!(ChunkKey, Chunk) _chunkCache;
}
