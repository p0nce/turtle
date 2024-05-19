module vxlgen.room;

import std.stdio;

import vxlgen.randutils;
import vxlgen.grid;
import vxlgen.cell;
import dplug.math.vector;
import vxlgen.aosmap;
import dplug.math.box;

final class Room : ICellStructure
{   
    box3i pos;
    bool isEntrance;
    vec3i cellSize;

    this(box3i p, bool isEntrance, vec3i cellSize)
    {
        pos = p;
        this.isEntrance = isEntrance;
        this.cellSize = cellSize;
    }

    vec3i getCellPosition()
    {
        return pos.min;
    }

    void buildCells(ref Random rng, Grid grid)
    {
        for (int x = pos.min.x; x < pos.max.x; ++x)
            for (int y = pos.min.y; y < pos.max.y; ++y)
                for (int z = pos.min.z; z < pos.max.z; ++z)
                {                    
                    vec3i posi = vec3i(x, y, z);

                    grid.cell(posi).type = (z == pos.min.z) ? CellType.ROOM_FLOOR : CellType.AIR;

                    // balcony for floor
                    if (z == pos.min.z && grid.isExternal(posi) && !isEntrance)
                        grid.cell(posi).balcony = BalconyType.SIMPLE;


                    // ensure floor
                    if (isEntrance)
                        if (z == pos.min.z)
                            grid.cell(posi).hasFloor = true;

                    // ensure space                    
                    if (x + 1 < pos.max.x)
                        grid.connectWith(posi, vec3i(1, 0, 0));

                    if (y + 1 < pos.max.y)
                        grid.connectWith(posi, vec3i(0, 1, 0));

                    if (z + 1 < pos.max.z)
                        grid.connectWith(posi, vec3i(0, 0, 1));
                }

        // balcony
        for (int z = pos.min.z + 1; z < pos.max.z; ++z)
            for (int x = pos.min.x - 1; x < pos.max.x + 1; ++x)
                for (int y = pos.min.y - 1; y < pos.max.y + 1; ++y)
                    if (grid.contains(x, y, z))
                    {
                        Cell* cell = &grid.cell(x, y, z);
                        //if (cell.type == CellType.REGULAR)
                        cell.balcony = BalconyType.SIMPLE;
                    }
    }

    void buildBlocks(ref Random rng, Grid grid, vec3i base, AOSMap map)
    {
        // red carpet for entrance
        /+if (isEntrance)
        {
            vec3f redCarpet = vec3f(1, 0, 0);
            for (int x = 0; x < pos.width(); ++x)
                for (int y = 0; y < pos.height(); ++y)
                {
                    int z = 0;
                    vec3i cellPos = pos.a + vec3i(x, y, z);
                    
                    Cell* cell = &grid.cell(cellPos);
                    if (cell.type == CellType.ROOM_FLOOR)
                    {
                        for (int j = 0; j < cellSize.y; ++j)
                        {
                            for (int i = 0; i < cellSize.x; ++i)
                            {
                                map.block(vec3i(i, j, 0) + cellPos * cellSize).setf(redCarpet);
                            }
                        }
                    }                    
                }

        }
        +/
    }
}
