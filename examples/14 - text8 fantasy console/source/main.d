import turtle;
import std.stdio;
import std.file;

import text8;

int main(string[] args)
{
    ubyte[] rom = null;
    if (args.length == 2)
    {
        rom = cast(ubyte[]) std.file.read(args[1]);
    }
    runGame(new Text8Run(rom));
    return 0;
}

class Text8Run : TurtleGame
{
    this(ubyte[] rom)
    {
        this.rom = rom;

        // Create interpreter and eval whole file.
        vm = new Text8VM;
        if (rom) vm.load(rom);
    }

    ubyte[] rom;

    override void load()
    {
        setBackgroundColor( color("#444") );
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

        double FRAME_TIME = 1.0 / 60;

        while (dtDebt >= FRAME_TIME)
        {
            vm.callStep();
            dtDebt -= FRAME_TIME;
        }
    }

    override void draw()
    {
        vm.render(console());
    }

    int screenWidth;
    int screenHeight;
    Text8VM vm;

    double dtDebt;
}
