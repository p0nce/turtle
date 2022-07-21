import turtle;
static import std.random;
import std.string;
import std.random;

import aliasthis.config;
import aliasthis.console;
import aliasthis.utils;
import aliasthis.lang;
import aliasthis.states;


int main(string[] args)
{
    runGame(new RoguelikeExample);
    return 0;
}

// TODO suggest this initial window size vec2i(1366, 768);

class RoguelikeExample : TurtleGame
{
    override void load()
    {
        _console = new Console(CONSOLE_WIDTH, CONSOLE_HEIGHT);
        _state = new StateMainMenu(_console, new LangEnglish);
        _accumulatedDelta = 0;
    }

    override void update(double dt)
    {
       
        _accumulatedDelta += dt;
    }

    override void resized(float width, float height)
    {
        _console.updateFont(cast(int)windowWidth, cast(int)windowHeight);       
    }

    override void keyPressed(KeyConstant key)
    {
        State newState = _state.handleKeypress(key);

        if (newState is null)
        {
            exitGame();
        }
        else
        {
            _state = newState;
        }
    }

    // Note: this use both the canvas and direct frame buffer access (for text)
    override void draw()
    {
        ImageRef!RGBA fb = framebuffer();

        // todo draw

        // clear the console
        _console.setForegroundColor(RGBA(0, 0, 0, 255));
        _console.setBackgroundColor(RGBA(7, 7, 12, 255));
        _console.clear();

        _state.draw(_accumulatedDelta);
        _accumulatedDelta = 0;

        _console.flush(fb, canvas());
    }

private:
    State _state;
    Console _console;
    double _accumulatedDelta;
}



void onDraw(ImageRef!RGBA framebuffer, ref Canvas canvas, double dt)
{

}
