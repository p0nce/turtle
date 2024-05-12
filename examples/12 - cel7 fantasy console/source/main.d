import turtle;
import fe;
import std.stdio;
import std.file;
import api;

// A reimplementation of cel7 from rxi
// Find runnables here: https://rxi.itch.io/cel7
// A lot of the implementation comes from cel7 
// Community Edition and is hence GPL-v3
// Reference: https://github.com/kiedtl/cel7ce
int main(string[] args)
{
    ubyte[] rom = null;
    if (args.length == 2)
    {
        rom = cast(ubyte[]) std.file.read(args[1]);
    }
    runGame(new Cel7Run(rom));
    return 0;
}

class Cel7Run : TurtleGame
{
    this(ubyte[] rom)
    {
        this.rom = rom;

        // Create interpreter and eval whole file.
        vm = new Cel7;
        if (rom) vm.load(rom);
    }

    ubyte[] rom;

    override void load()
    {
        setBackgroundColor( color("#000000") );
        vm.callInit();
        dtDebt = 0;
    }

    override void keyPressed(KeyConstant key)
    {
        // Note: turtle happens to give zero-terminated key constants.
        vm.callKeydown(key.ptr);
    }

    override void update(double dt)
    {
        if (keyboard.isDown("escape")) exitGame;

        // run at fixed FPS
        dtDebt += dt;
        if (dtDebt > 1.0)
            dtDebt = 1.0;

        double FRAME_TIME = 1.0 / 30;

        while (dtDebt >= FRAME_TIME)
        {
            vm.callStep();
            dtDebt -= FRAME_TIME;
        }
    }

    override void draw()
    {
        ImageRef!RGBA image = framebuffer();
        vm.render(image.w, image.h, cast(ubyte*) image.pixels, image.pitch);
    }

    int screenWidth;
    int screenHeight;
    Cel7 vm;

    double dtDebt;
}
