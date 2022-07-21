module aliasthis.levelgen;

import std.random;

import turtle;

import aliasthis.worldstate;
import aliasthis.grid;
import aliasthis.cell;
import aliasthis.config;

class LevelGenerator
{
    this()
    {
        // Load prefabs
        //_prefabs = loadPrefabs();
    }

    void generate(ref Xorshift rng, WorldState worldState)
    {
        // set cell types

        auto grid = worldState._grid;

        for (int k = 0; k < GRID_DEPTH; ++k)
        {
            for (int j = 0; j < GRID_HEIGHT; ++j)
            {
                for (int i = 0; i < GRID_WIDTH; ++i)
                {
                    Cell* c = grid.cell(vec3i(i, j, k));
                    c.type = CellType.FLOOR;

                    if (i == 0 || i == GRID_WIDTH - 1 || j == 0 || j == GRID_HEIGHT - 1)
                        c.type = CellType.WALL;

                    if (i >  4 && i < 10 && j > 4 && j < 20)
                        c.type = CellType.DEEP_WATER;

                    if (i >  14 && i < 28 && j > 4 && j < 20)
                        c.type = CellType.SHALLOW_WATER;

                    if (i == 0 && j == 15)
                        c.type = CellType.DOOR;

                    if (i >  30 && i < (32 + k) && j > 4 && j < 20)
                        c.type = CellType.HOLE;

                    if (i >  40 && i < 59 && j > 21 && j < 28)
                        c.type = CellType.LAVA;

                    if (i >=  50 && i < 51 && j >= 1 && j < 2)
                        c.type = CellType.STAIR_DOWN;
                    if (i >=  50 && i < 51 && j >= 2 && j < 3)
                        c.type = CellType.STAIR_UP;
                }
            }
        }

        for (int k = 0; k < GRID_DEPTH; ++k)
            for (int j = 0; j < GRID_HEIGHT; ++j)
                for (int i = 0; i < GRID_WIDTH; ++i)
                {
                    // first-time, use an important RNG
                    Cell* c = grid.cell(i, j, k);
                    grid.updateCellGraphics(rng, c, k, 1.0f);
                }
    }

   // Prefab[] _prefabs;

}
/+
class Prefab
{
    this(string[] lines)
    {
        _width = lines[0].width;

        foreach(i; 1..lines.length)
            assert(lines[i] == _width)

        _height = cast(int)lines.length;


        _data.length = _width * _height;
        
    }

    vec2i transformDirection(int x, int y, Direction dir)
    {
        final switch(dir) with (Direction)
        {

            case unchanged: return vec2i(x, y);
            case rotate90: return vec2i(height - 1 - y, x);
            case rotate180: return vec2i(width - 1 - x, height - 1 - y);
            case rotate270: return vec2i(y, width - 1 - x);
            case invertXY: return vec2i(y, x);
            case mirrorY: return vec2i(x, height - 1 - y);
            case mirrorXY: return vec2i(height - 1 - y, width - 1 - x);
            case mirrorX: return vec2i(width - 1 - x, y);
        }
    }

    vec2i transformSize(int width, int height, Direction dir)
    {
        final switch(dir) with (Direction)
        {
            case unchanged:
            case mirrorY:
            case rotate180:
            case mirrorX:
                return vec2i(width, height);

            case rotate90:            
            case rotate270:
            case invertXY:
            case mirrorXY:
                return vec2i(height, width);
        }        
    }

    void applyDirection(Direction dir)
    {
        VOX newVox;
        vec2i newSize = transformSize(width, height, depth, dir);
        newVox.width = newSize.x;
        newVox.height = newSize.y;
        newVox.depth = newSize.z;
        newVox.voxels.length = newVox.numVoxels();

        for (int z = 0; z < newVox.depth; ++z)
            for (int y = 0; y < newVox.height; ++y)
                for (int x = 0; x < newVox.width; ++x)
                {
                    vec2i source = transformDirection(x, y, z, dir);
                    newVox.voxel(x, y, z) = vox.voxel(source.x, source.y, source.z);                    
                }

        vox = newVox;
    }

    CellType[] data;
}


enum Direction
{
    unchanged,
    rotate90,
    rotate180,
    rotate270,
    invertXY,
    mirrorY,
    mirrorXY,
    mirrorX
}


Prefab[] loadPrefabs()
{
    Prefab[] list;

    void addPrefab(string[] s)
    {
        for (Direction dir = Direction.min; dir <= Direction.max; ++dir)
        {
            auto prefab = new Prefab(s);
            prefab.applyDirection(dir);
            list ~= prefab;                        
        }
    }
}+/