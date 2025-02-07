module constants;

import std.random;

enum int
    BULLET_STATE_ALIVE = 1,
    BULLET_STATE_EXPLODING1 = 2,
    BULLET_STATE_EXPLODING2 = 3,
    BULLET_STATE_EXPLODING3 = 4,
    BULLET_STATE_DEAD = 5;

enum int
    GAME_SMALL = 6,
    GAME_MEDIUM = 7,
    GAME_LARGE = 8,
    GAME_HUGE = 9;

enum int
    SAMPLE_SHOOT = 0,
    SAMPLE_EXPLODE = 1,
    SAMPLE_DIE = 2,
    SAMPLE_TELEPORT = 3,
    SAMPLE_WEAPON_UPGRADE = 4,
    SAMPLE_INVINCIBLE = 5,
    SAMPLE_INTRO = 6,
    SAMPLE_NEW_GAME = 7;

enum int 
    TEXTURE_PLAYERS = 0,
    TEXTURE_OTHERTILES = 1,
    TEXTURE_EYES = 2,
    TEXTURE_BAR = 3,
    TEXTURE_GFM = 4,
    TEXTURE_MARS = 5,
    TEXTURE_HELP = 6,
    TEXTURE_LETTERS = 7;

enum int
    GAME_STATE_LOADING = 0,
    GAME_STATE_LOGO = 1,
    GAME_STATE_GAME = 2,
    GAME_STATE_HELP = 3,
    GAME_STATE_MAP  = 4;

enum int
    MAX_DIMENSION = 752,
    MIN_DIMENSION = 352;

enum int
    DIR_UP = 0,
    DIR_DOWN = 1,
    DIR_LEFT = 2,
    DIR_RIGHT = 3;

enum int
    COMMAND_NONE = -1,
    COMMAND_UP = 0,
    COMMAND_DOWN = 1,
    COMMAND_LEFT = 2,
    COMMAND_RIGHT = 3,
    COMMAND_TURN_LEFT = 4,
    COMMAND_TURN_RIGHT = 5,
    COMMAND_SHOOT = 6;

enum int
    COMMAND_QUEUE_LENGTH = 40;

enum int
    STATE_ALIVE = 1,
    STATE_EXPLODING1 = 2,
    STATE_EXPLODING2 = 3,
    STATE_EXPLODING3 = 4,
    STATE_EXPLODING4 = 5,
    STATE_DEAD = 6;

enum int
    BULLET_DELAY = 40;

enum int
    SIGHT = 8;

enum int
    INVINCIBILITY_DURATION = 52;


enum int
    PLAYERS_DO_EXPLODE = 0;

int directionX(int dir)
{
	switch(dir)
    {   
        case /* tron.DIR_LEFT */ 2:
            return -1;

        case /* tron.DIR_RIGHT */ 3:
			return 1;

            //case /* tron.DIR_UP */ 0:
            //case /*tron.DIR_DOWN */ 1:  
            //	return 0;
		default:
			return 0;
	}
};

int directionY(int dir)
{
	switch(dir)
    {
        case /* tron.DIR_UP */ 0: return -1;
        case /*tron.DIR_DOWN */ 1: return 1;
            //case /* tron.DIR_LEFT */ 2:
            //case /* tron.DIR_RIGHT */ 3: return 0;
		default: return 0;
	}
}
  
int min_int(int a, int b)
{
    return a < b ? a : b;
}

int abs_int(int x)
{
    if (x < 0) x = -x;
    return x;
}

int randInt(int a, int b)
{
    assert(b >= a);
    return uniform(a, b);
}

void fillArray(T)(T[] a, T e)
{
    a[] = e;
}
