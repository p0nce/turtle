module aliasthis.command;

import aliasthis.utils;
public import aliasthis.grid;

enum CommandType 
{
    MOVE,
    WAIT
}

// Command are a high-level overview of instructions.
// They map to actually different effects (eg: MOVE can move, dig or attack).
// Considering a WorldState, a Command executes into a ChangeSet.
// A successful ChangeSet can be applied or not to the WorldState.
// A command SHOULD be able to be asked to any Entity.
// Need to be small and serializable.
struct Command
{
    CommandType type;

    union Params
    {
        CommandParamsMove move;
        CommandParamsWait wait;
    } 

    Params params;


    static Command createMovement(Direction dir)
    {
        Command res;
        res.type = CommandType.MOVE;
        res.params.move.direction = dir;
        return res;
    }

    static Command createWait()
    {
        Command res;
        res.type = CommandType.WAIT;
        return res;
    }
}

struct CommandParamsMove
{
    Direction direction;
}

struct CommandParamsWait
{
}

