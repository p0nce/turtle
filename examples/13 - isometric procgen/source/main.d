import turtle;

import std.format;
import std.conv;
import std.random;
import std.stdio;

import dplug.core;
import dplug.graphics;
import dplug.math.box;
import dplug.math.vector;

import vxlgen.randutils;
import vxlgen.aosmap;
import vxlgen.block;
import vxlgen.tower;
import vxlgen.terrain;


int main(string[] args)
{
    uint seed = unpredictableSeed;

    for (int i = 0; i < args.length; ++i)
    {
        if (args[i] == "--seed")
        {
            ++i;
            seed = to!int(args[i]);
        }
    }
    
    runGame(new IsometricExample(createWorld(seed)));
    return 0;
}

class IsometricExample : TurtleGame
{
    this(AOSMap map)
    {
        _map = map;
    }

    override void load()
    {
        setBackgroundColor( color("black") );
    }

    override void update(double dt)
    {
        if (keyboard.isDown("escape")) exitGame;
    }

    override void draw()
    {
        ImageRef!RGBA framebuf = framebuffer();
        int W = framebuf.w;
        int H = framebuf.h;

    }        

private:
 
    AOSMap _map;
}




AOSMap createWorld(uint seed)
{
    Xorshift64 rng;
    rng.seed(seed);

    auto map = new AOSMap();    
    
    writefln("*** Generating seed %s...", seed);

    int floors = rdice(rng, 7, 11);
    int cellsX = rdice(rng, 21, 41);
    int cellsY = rdice(rng, 21, 41);

    makeTerrain(rng, map);

    vec3i cellSize = vec3i(4, 4, 6);    
    vec3i numCells = vec3i(cellsX, cellsY, floors);
    vec3i dimensions = numCells * cellSize + 1;
    vec3i towerPos = vec3i(254 - dimensions.x/2, 254 - dimensions.y/2, 1);    
    box3i blueSpawnArea;
    box3i greenSpawnArea;

    writefln("- cell size is %s", pythonTuple(cellSize));
    writefln("- num cells is %s", pythonTuple(numCells));

    makeTower(rng, map, towerPos, numCells, cellSize, blueSpawnArea, greenSpawnArea);
/*
    debug {} else
    {
        writefln("*** Color bleeding...");
        map.colorBleed();

        writefln("*** Compute omnidirectional Ambient Occlusion...");
        map.betterAO();

        writefln("*** Reverse client Ambient Occlusion...");
        map.reverseClientAO();
    }
    */

    return map;
}

void makeTower(ref Xorshift64 rng, AOSMap map, vec3i towerPos, vec3i numCells, vec3i cellSize, out box3i blueSpawnArea, out box3i greenSpawnArea)
{
    assert(cellSize == vec3i(4, 4, 6)); // TODO other cell size?
    writefln("*** Build tower...");
      
    auto tower = new Tower(towerPos, numCells);
    tower.buildBlocks(rng, map);

    blueSpawnArea = box3i(towerPos + tower.blueEntrance.min * cellSize, towerPos + tower.blueEntrance.max * cellSize);
    greenSpawnArea = box3i(towerPos + tower.greenEntrance.min * cellSize, towerPos + tower.greenEntrance.max * cellSize);
}

void makeTerrain(ref Xorshift64 rng, AOSMap map)
{
    writefln("*** Generate terrain...");
    auto terrain = new Terrain(vec2i(512, 512), rng);
    terrain.buildBlocks(rng, map);
}

string pythonTuple(vec3i v)
{
    return format("(%s, %s, %s)", v.x, v.y, v.z);
}

string pythonTuple(vec3f v)
{
    return format("(%s, %s, %s)", v.x, v.y, v.z);
}

