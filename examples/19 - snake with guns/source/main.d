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
        setBackgroundColor(color("#EAF5FF"));

        TM_Options opt;
        console.size(30, 22);
        console.palette(TM_paletteTango);

        _audio = new AudioManager(1337); // fake object

        _textures = new TextureManager(3);
        _textures.add("img/players4.png", 256, 128);
        _textures.add("img/otherstiles.png", 16, 304);    
        _textures.add("img/eyes.png", 16, 256);

        newGame();
        time = 0;
        needRender = true;
    }

    enum double FPS = 20;
    enum double TIME_PER_FRAME = 1.0 / FPS;
    double time;
    bool needRender;

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
        if (needRender) _game.render(fb);
        needRender = false;
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