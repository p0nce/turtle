module aliasthis.cell;

import turtle;

import aliasthis.utils,
       aliasthis.chartable;

enum CellType
{
    STAIR_UP = '<',
    STAIR_DOWN = '>',
    SHALLOW_WATER = '-',
    DEEP_WATER = '~',
    LAVA = '%',
    HOLE = ' ',  
    WALL = 'X',
    FLOOR = '.',
    DOOR = '|',
    //ANYTHING = '?', // only in prefabs for matching
    //LINK = '*'
}



struct Cell
{
    CellType type;
    CellGraphics graphics;
}

// is it blocking?
bool canMoveInto(CellType type)
{
    switch(type)
    {
        case CellType.WALL:
            return false;

        default:
            return true;
    }
}

// can an entity move into it, or at least try?
bool canTryToMoveIntoSafely(CellType type)
{
    switch(type)
    {
        case CellType.STAIR_UP:
        case CellType.STAIR_DOWN:
        case CellType.WALL:
        case CellType.FLOOR:
        case CellType.DOOR:
            return true;

        case CellType.SHALLOW_WATER:
        case CellType.DEEP_WATER:
        case CellType.LAVA:
        case CellType.HOLE:        
            return false;

        default:
            assert(false);
    }
}

struct CellGraphics
{
    int charIndex; // index in font
    RGBA foregroundColor;
    RGB backgroundColor;
}

CellGraphics defaultCellGraphics(CellType type) pure nothrow
{
    final switch(type)
    {
        case CellType.STAIR_UP:      return CellGraphics(ctCharacter!'<', RGBA(170, 170, 40, 255), RGB(30, 30, 40));
        case CellType.STAIR_DOWN:    return CellGraphics(ctCharacter!'>', RGBA(170, 170, 40, 255), RGB(30, 30, 40));
        case CellType.SHALLOW_WATER: return CellGraphics(ctCharacter!'~', RGBA(170, 170, 200, 150), RGB(101, 116, 193));
        case CellType.DEEP_WATER:    return CellGraphics(ctCharacter!'~', RGBA(120, 140, 200, 150), RGB(63, 78, 157));
        case CellType.LAVA:          return CellGraphics(ctCharacter!'~', RGBA(205, 140, 0, 160), RGB(148, 82, 0));
        case CellType.HOLE:          return CellGraphics(ctCharacter!' ', RGBA(47, 47, 87, 255), RGB(0, 0, 0));
        case CellType.WALL:          return CellGraphics(/* dummy */ctCharacter!'▪', RGBA(128, 128, 138, 255), /* dummy */RGB(20, 32, 64));
        case CellType.FLOOR:         return CellGraphics(ctCharacter!'ˑ', RGBA(70, 70, 80, 255), RGB(30, 30, 40));
        case CellType.DOOR:          return CellGraphics(ctCharacter!'Π', RGBA(200, 200, 200, 255), RGB(35, 12, 12));
    }
}

struct CellVariability
{
    float SNoise;
    float VNoise;
}

CellVariability cellVariability(CellType type) pure nothrow
{
    final switch(type)
    {
        case CellType.STAIR_UP:      return CellVariability(0.018f, 0.009f);
        case CellType.STAIR_DOWN:    return CellVariability(0.018f, 0.009f);
        case CellType.SHALLOW_WATER: return CellVariability(0.018f* 2.0f, 0.009f* 1.1f);
        case CellType.DEEP_WATER:    return CellVariability(0.018f * 2.0f, 0.009f* 1.1f);
        case CellType.LAVA:          return CellVariability(0.018f * 3.0f, 0.009f * 3.0f);
        case CellType.HOLE:          return CellVariability(0.018f, 0.009f);
        case CellType.WALL:          return CellVariability(0.018f, 0.009f);
        case CellType.FLOOR:         return CellVariability(0.009f * 0.25f, 0.009f * 0.25f);
        case CellType.DOOR:          return CellVariability(0.018f, 0.009f);
    }
}


// 0 never change color over time
// 1 change color over time
float dynamicVariability(CellType type) pure nothrow
{
    switch(type)
    {
        case CellType.SHALLOW_WATER: return 4;
        case CellType.DEEP_WATER:    return 4;
        case CellType.LAVA:          return 6;
        default:
            return 0;
    }
}
