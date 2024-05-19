module vxlgen.stair;

import std.stdio;
import std.conv;
import std.math;

import dplug.math.vector;
import vxlgen.grid;
import vxlgen.aosmap;
import vxlgen.cell;
import vxlgen.randutils;

final class Stair : ICellStructure
{
    vec3i start;
    vec3i direction;
    vec3f color1;
    vec3f color2;

    this(vec3i start, vec3i direction, vec3f color1, vec3f color2)
    {
        this.start = start;
        this.direction = direction;
        this.color1 = color1;
        this.color2 = color2;
    }

    vec3i getCellPosition()
    {
        return start;
    }

    void buildBlocks(ref Random rng, Grid grid, vec3i base, AOSMap map)
    {
        vec3i centerA = base + vec3i(2, 2, 0) + 0 * direction;
        vec3i centerB = base + vec3i(2, 2, 0) + 4 * direction;

        vec3i remapCenter(vec3i centerRel, vec3i input)
        {
            vec3i diff = input - centerRel;
            return centerRel + rotate(diff, direction);
        }

        for (int j = 1; j < 4; ++j)
        {
            for (int i = 2; i < 8; ++i)
            {
                int height = i - 1;

                for (int k = 1; k <= 6; ++k)
                {
                    vec3i p = remapCenter(centerA, base + vec3i(i, j, k));
                    if (k <= height)
                        map.block(p).setf(k & 1 ? color1 : color2);
                    else
                        map.block(p).empty();
                }
            }
        }
    }
    
    void buildCells(ref Random rng, Grid grid)
    {
        //  C   A   B
        //           _
        //        _ /
        //      _/
        // ___ / 
        assert(grid.contains(start));
        assert(grid.contains(start + direction));

        Cell* a = &grid.cell(start);
        vec3i bpos = start + direction;
        Cell* b = &grid.cell(start + direction);
        vec3i cpos = start - direction;
        Cell* c = &grid.cell(start - direction);

        a.type = CellType.STAIR_BODY; 
        b.type = CellType.STAIR_BODY;
        c.type = CellType.STAIR_END_LOW;

        // ensure floor
        a.hasFloor = true;
        b.hasFloor = true;
        c.hasFloor = true;

        // ensure no wall in middle of stair
        grid.connectWith(start, direction);
        grid.connectWith(start, -direction);

        // ensure wall at one end
        if (grid.contains(bpos + direction))
            grid.disconnectWith(bpos, direction);

        // walls around A and B
        vec3i dirSide1 = vec3i(direction.y, -direction.x, 0);
        vec3i dirSide2 = vec3i(-direction.y, direction.x, 0);
        grid.tryDisconnectWith(start, dirSide1);
        grid.tryDisconnectWith(start, dirSide2);
        grid.tryDisconnectWith(bpos, dirSide1);
        grid.tryDisconnectWith(bpos, dirSide2);

        // ensure no roof
        vec3i aboveA = start + vec3i(0, 0, 1);
        vec3i aboveB = bpos + vec3i(0, 0, 1);
        vec3i aboveC = cpos + vec3i(0, 0, 1);
        {            
            assert(grid.contains(aboveA));
            
            grid.cell(aboveA).type = CellType.AIR;
            grid.connectWith(start, vec3i(0, 0, 1));
            
            assert(grid.contains(aboveB));

            grid.connectWith(aboveA, aboveB - aboveA);            
            grid.cell(aboveB).type = CellType.AIR;
            grid.connectWith(bpos, vec3i(0, 0, 1));

            // ensure no wall at the end of the stair
            // ensure floor too
            vec3i aboveD = aboveB + direction;
            assert(grid.contains(aboveD));
            {
                grid.cell(aboveD).type = CellType.STAIR_END_HIGH;
                grid.connectWith(aboveB, direction);
                grid.disconnectWith(aboveD, vec3i(0, 0, -1));
            }
        }    

        // balcony
        if (grid.contains(aboveA + dirSide1))
            grid.cell(aboveA + dirSide1).balcony = BalconyType.SIMPLE;
        if (grid.contains(aboveA + dirSide2))
            grid.cell(aboveA + dirSide2).balcony = BalconyType.SIMPLE;
        if (grid.contains(aboveB + dirSide1))
            grid.cell(aboveB + dirSide1).balcony = BalconyType.SIMPLE;
        if (grid.contains(aboveB + dirSide2))
            grid.cell(aboveB + dirSide2).balcony = BalconyType.SIMPLE;
        if (grid.contains(aboveC))
            grid.cell(aboveC).balcony = BalconyType.SIMPLE;
    }
}
