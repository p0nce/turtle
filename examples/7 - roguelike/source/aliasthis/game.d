module aliasthis.game;

import std.random;

import turtle;

import aliasthis.console,
       aliasthis.command,
       aliasthis.config,
       aliasthis.change,
       aliasthis.worldstate;

// Holds the game state and how we got there.
// 
class Game
{
public:
    enum NUM_BUFFERED_MESSAGES = 100;

    // create a new game
    this(uint initialSeed)
    {
        rng.seed(initialSeed);
        _initialSeed = initialSeed;
        _worldState = WorldState.createNewWorld(rng);
        _changeLog = [];
        _commandLog = [];

        foreach (i ; 0..NUM_BUFFERED_MESSAGES)
            _messageLog ~= "";
    }

    // enqueue a game log message
    void message(string m)
    {
        _messageLog = [m] ~ _messageLog[0..$-1];
    }

    void draw(Console console, double dt)
    {
        _worldState.estheticUpdate(dt);
        _worldState.draw(console);

        // draw last 3 log line

        static immutable ubyte[3] transp = [255, 128, 64];
        for (int y = 0; y < 3; ++y)
        {
            console.setBackgroundColor(RGBA(7, 7, 12, 255));
            console.setForegroundColor(RGBA(255, 220, 220, transp[y]));

            for (int x = 0; x < GRID_WIDTH; ++x)
                console.putChar(x, console.height - 3 + y, 0);

            string msg = _messageLog[y];
            console.putText(1, console.height - 3 + y, msg);
        }
    }

    void executeCommand(Command command)
    {
        Change[] changes = _worldState.compileCommand(_worldState._human, command);

        if (changes !is null) // command is valid
        {
            applyChangeSet(_worldState, changes);

            // enqueue all changes
            foreach (ref Change c ; changes)
            {
                _changeLog ~= changes;
            }

            _commandLog ~= command;
        }
    }

    void undo()
    {
        // undo one change
        size_t n = _changeLog.length;
        if (n > 0)
        {
            revertChange(_worldState, _changeLog[n - 1]);
            _changeLog = _changeLog[0..n-1];
        }
    }

private:
    Xorshift rng;
    uint _initialSeed;
    WorldState _worldState;
    Change[] _changeLog;
    Command[] _commandLog;
    string[] _messageLog;   
}
