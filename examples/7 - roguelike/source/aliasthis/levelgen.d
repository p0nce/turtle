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
}
