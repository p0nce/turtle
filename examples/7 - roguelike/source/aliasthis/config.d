module aliasthis.config;

// bump version number to make the save files incompatible
enum ALIASTHIS_MAJOR_VERSION = 0,
     ALIASTHIS_MINOR_VERSION = 1;


// should probably not be changed at this point
enum CONSOLE_WIDTH = 91,
     CONSOLE_HEIGHT = 32;

class AliasthisException : Exception
{
    pure this(string message)
    {
        super(message);
    }
}

enum GRID_NUM_CELLS = GRID_WIDTH * GRID_HEIGHT * GRID_DEPTH;

enum GRID_WIDTH = 60;
enum GRID_HEIGHT = 29;
enum GRID_DEPTH = 20;
