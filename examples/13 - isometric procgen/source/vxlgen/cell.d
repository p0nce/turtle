module vxlgen.cell;


enum CellType
{
    AIR,
    REGULAR,
    ROOM_FLOOR,
    FULL,
    STAIR_BODY,
    STAIR_END_HIGH,
    STAIR_END_LOW
}

enum BalconyType
{
    NONE,
    SIMPLE,
    BATTLEMENT 
}

struct Cell
{
    bool hasLeftWall; // is connected to X-1
    bool hasTopWall; // is connected to Y-1    
    bool hasFloor; // is connected to Z-1
    CellType type;
    BalconyType balcony;
    int color;
}

bool shouldBeConnected(CellType ct)
{
    final switch(ct)
    {
        case CellType.AIR: 
            return false;

        case CellType.REGULAR: 
            return true;

        case CellType.ROOM_FLOOR: 
            return true;

        case CellType.STAIR_BODY: 
        case CellType.FULL: 
           return false;

        case CellType.STAIR_END_HIGH: 
        case CellType.STAIR_END_LOW:         
            return true;
    }
}

bool availableForRoom(CellType ct)
{
    switch(ct)
    {
        case CellType.REGULAR: 
        case CellType.FULL:
        case CellType.STAIR_END_HIGH:
            return true;

        default:
            return false;
    }
}

bool availableForStair(CellType ct)
{
    switch(ct)
    {
        case CellType.REGULAR: 
            return true;

        default:
            return false;
    }
}

bool isStairPart(CellType ct)
{
    switch(ct)
    {
        case CellType.STAIR_BODY: 
        case CellType.STAIR_END_LOW: 
            return true;

        default:
            return false;
    }
}