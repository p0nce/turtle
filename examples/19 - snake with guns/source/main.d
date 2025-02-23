import turtle;
import textmode;
import std;

import game;
import texture;
import audiomanager;

class SnakeExample : TurtleGame
{
    TextureManager _textures;
    AudioManager _audio;
    SnakeGame _game;

    override void load()
    {
        // Do not erase background on new frame
        setBackgroundColor(color("transparent"));

        TM_Options opt;
        console.size(30, 22);
        console.palette(TM_paletteTango);

        _audio = new AudioManager(1337); // fake object

        _textures = new TextureManager(3);
        _textures.add("img/players4.png");
        _textures.add("img/otherstiles.png");
        _textures.add("img/eyes.png");

        newGame();
        time = 0;
        needRender = true;
        needRenderBackground = true;
    }

    enum double FPS = 7;
    enum double TIME_PER_FRAME = 1.0 / FPS;
    double time;
    bool needRender;
    bool needRenderBackground;

    override void resized(float width, float height)
    {
        needRenderBackground = true;
    }

    override void update(double dt)
    {
        console.update(dt);
        if (keyboard.isDownOnce("escape")) exitGame();

        // original game work with fixed physics
        if (dt > 1)
            dt = 1;

        time += dt;
        while(time > TIME_PER_FRAME)
        {
            time -= TIME_PER_FRAME;
            _game.update();
            needRender = true;
        }        
    }

    override void draw()
    {
        ImageRef!RGBA fb = framebuffer();

        if (needRenderBackground)
        {
            RGBA bg = RGBA(255, 255, 255, 255);
            framebuffer.fillAll(bg);
            needRenderBackground = false;
        }

        if (needRender)
        {
            _game.render(framebuffer);
            needRender = false;
        } 
    }

    void newGame()
    {
        _game = new SnakeGame(_textures, _audio, 6, 1);
    }

    override void keyPressed(KeyConstant key)
    {
        _game.keydown(key);
    }
}

int main(string[] args)
{
    runGame(new SnakeExample());
    return 0;
}