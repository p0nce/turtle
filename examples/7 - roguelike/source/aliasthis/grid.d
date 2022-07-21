module aliasthis.grid;

import turtle;

import aliasthis.config,
       aliasthis.utils,
       aliasthis.chartable,
       aliasthis.levelgen,
       aliasthis.cell;

// basically a big cube



enum Direction
{
    WEST,
    EAST,
    NORTH,
    SOUTH,
    NORTH_WEST,
    SOUTH_WEST,
    NORTH_EAST,
    SOUTH_EAST,
    BELOW,
    ABOVE
}

vec3i getDirection(Direction dir)
{
    final switch(dir)
    {
        case Direction.WEST: return vec3i(-1, 0, 0);
        case Direction.EAST: return vec3i(+1, 0, 0);
        case Direction.NORTH: return vec3i(0, -1, 0);
        case Direction.SOUTH: return vec3i(0, +1, 0);
        case Direction.NORTH_WEST: return vec3i(-1, -1, 0);
        case Direction.SOUTH_WEST: return vec3i(-1, +1, 0);
        case Direction.NORTH_EAST: return vec3i(+1, -1, 0);
        case Direction.SOUTH_EAST: return vec3i(+1, +1, 0);
        case Direction.BELOW: return vec3i(0, 0, -1);
        case Direction.ABOVE: return vec3i(0, 0, +1);
    }
}



struct LevelInfo
{
    int wallCharIndex;
    RGB wallColor()
    {
        return RGB(128, 128, 160);
    }
}


class Grid
{
    public
    {
        this(ref Xorshift rng)
        {
            _cells.length = GRID_NUM_CELLS;
            generateLevelParameters(rng);
        }

        Cell* cell(vec3i pos)
        {
            return &_cells[pos.x + GRID_WIDTH * pos.y + (GRID_WIDTH * GRID_HEIGHT) * pos.z];
        }

        Cell* cell(int x, int y, int z)
        {
            return &_cells[x + GRID_WIDTH * y + (GRID_WIDTH * GRID_HEIGHT) * z];
        }

        static bool contains(vec3i pos)
        {
            if (cast(uint)pos.x >= cast(uint)GRID_WIDTH) 
                return false;
            if (cast(uint)pos.y >= cast(uint)GRID_HEIGHT) 
                return false;
            if (cast(uint)pos.z >= cast(uint)GRID_DEPTH) 
                return false;
            return true;
        }

        void estheticUpdate(int visibleLevel, double dt)
        {
            // use an unimportant RNG for esthetic updates

            // change colors of water, lava, etc...
            for (int j = 0; j < GRID_HEIGHT; ++j)
                for (int i = 0; i < GRID_WIDTH; ++i)
                {
                    if (uniform(0.0f, 1.0f, _localRNG) < 0.2f)
                    {
                        Cell* c = cell(i, j, visibleLevel);
                        float dynVar = dynamicVariability(c.type) * dt;
                        if (dynVar > 1)
                            dynVar = 1;
                        if (dynVar > 0)
                            updateCellGraphics(_localRNG, c, visibleLevel, dynVar);
                    }
                }
        }


        // build 
        void updateCellGraphics(ref Xorshift rng, Cell* c, int level, float blend)
        {
            CellGraphics gr = defaultCellGraphics(c.type);

            if (c.type == CellType.WALL)
            {
                gr.charIndex = _levels[level].wallCharIndex;
                gr.backgroundColor = _levels[level].wallColor;
            }

            // perturb color
            CellVariability var = cellVariability(c.type);
            gr.foregroundColor = perturbColorSV(gr.foregroundColor, var.SNoise, var.VNoise, rng);
            gr.backgroundColor = perturbColorSV(gr.backgroundColor, var.SNoise, var.VNoise, rng);
            c.graphics.charIndex = gr.charIndex;
            c.graphics.foregroundColor = lerpColor(c.graphics.foregroundColor, gr.foregroundColor, blend);
            c.graphics.backgroundColor = lerpColor(c.graphics.backgroundColor, gr.backgroundColor, blend);

        }
    }

    private
    {
        // holds cell information
        Cell[] _cells;

        // information about levels
        LevelInfo[GRID_DEPTH] _levels;

        Xorshift _localRNG; // for unimportant stuff like color

        void generateLevelParameters(ref Xorshift rng)
        {
            import aliasthis.levelgen;

            // set level characterstics
            for (int k = 0; k < GRID_DEPTH; ++k)
            {
                immutable int[] wallTypes = [ctCharacter!'▪', ctCharacter!'♦'];
                _levels[k].wallCharIndex = wallTypes[uniform(0, wallTypes.length, rng)];
            }
        }

    }
}

