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
    Game _game;

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
    }

    override void update(double dt)
    {
        console.update(dt);
        if (keyboard.isDownOnce("escape")) exitGame();
        
    }

    override void draw()
    {
        ImageRef!RGBA fb = framebuffer();
        _game.render(fb);
    }

    void newGame()
    {
        _game = new Game(_textures, _audio, 6, 1);
    }

}

int main(string[] args)
{
    runGame(new SnakeExample());
    return 0;
}