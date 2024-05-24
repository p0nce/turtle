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
        this.map = map;
    }

    override void load()
    {
        setBackgroundColor( color("black") );
        camera = map.goodSpawnPosition;
        _mouseX = 100;
        _mouseY = 100;
    }

    /// Callback function triggered when the mouse is moved.
    override void mouseMoved(float x, float y, float dx, float dy)
    {
        _mouseX = x;
        _mouseY = y;
    }

    bool validPlayerPosition(float x, float y, float z)
    {
        return map.emptyAt(x - 0.5, y - 0.5, z - 0.5)
            && map.emptyAt(x + 0.5, y - 0.5, z - 0.5)
            && map.emptyAt(x + 0.5, y + 0.5, z - 0.5)
            && map.emptyAt(x - 0.5, y + 0.5, z - 0.5)
            && map.emptyAt(x + 0.5, y + 0.5, z + 0.5)
            && map.emptyAt(x - 0.5, y + 0.5, z + 0.5)
            && map.emptyAt(x - 0.5, y - 0.5, z + 0.5)
            && map.emptyAt(x + 0.5, y - 0.5, z + 0.5)

            &&  map.emptyAt(x, y, z + 1.5);
    }

    override void update(double dt)
    {
        if (keyboard.isDown("escape")) exitGame;

       // assert(validPlayerPosition(camera.x, camera.y, camera.z));

        if (dt > 1)
            return;

        enum GRAVITY = 12;

        // Gravity
        for (int t = 0; t < 10; ++t)
        {
            float newZ = camera.z - dt * GRAVITY/10.0;
            if (validPlayerPosition(camera.x, camera.y, newZ))
            {
                camera.z = newZ;
                assert(validPlayerPosition(camera.x, camera.y, camera.z));
            }
            else
                break;            
        }
     //   assert(validPlayerPosition(camera.x, camera.y, camera.z));

        // Attempt a move
        {
            vec2f directionXY = vec2f(0, 0);
            if (keyboard.isDown("up"))
                directionXY += vec2f(-1, -1);
            if (keyboard.isDown("down")) 
                directionXY += vec2f(+1, +1);
            if (keyboard.isDown("left")) 
                directionXY += vec2f(+1, -1);        
            if (keyboard.isDown("right")) 
                directionXY += vec2f(-1, +1);

            if (directionXY != vec2f(0,0))
            {
                directionXY.normalize();

                enum PLAYER_SPEED = 12;
                bool jumped = false;

                
                // Attempt the movement in 10 smaller steps
                for (int t = 1; t <= 10; ++t)
                {
                    float newX = camera.x + directionXY.x * PLAYER_SPEED * dt / 10.0;
                    float newY = camera.y + directionXY.y * PLAYER_SPEED * dt / 10.0;                    
                    float newZ = camera.z;

                    if (!validPlayerPosition(newX, newY, newZ))
                    {
                        // possible to go up one block?
                        if (!jumped && validPlayerPosition(newX, newY, newZ + 1))
                        {
                            jumped = true;
                            newZ += 1;
                        }

                        // slide
                        bool canMoveX = validPlayerPosition(newX, camera.y, newZ);
                        bool canMoveY = validPlayerPosition(camera.x, newY, newZ);
                        if (!canMoveX)
                            newX = camera.x;
                        if (!canMoveY)
                            newY = camera.y;
                    }

                    if (!validPlayerPosition(newX, newY, newZ))
                        break;

                    camera.x = newX;
                    camera.y = newY;
                    camera.z = newZ;
                }
            }
        }
    }

    float _mouseX, _mouseY;

    override void draw()
    {
        ImageRef!RGBA framebuf = framebuffer();
        int W = framebuf.w;
        int H = framebuf.h;

 
        // The isometric view is like this.
        // We draw with the painter algorithm, with growing X+Y+Z
        //
        //          ^ Z
        //          | 
        //          |
        //          |
        //          o (0,0,0) 
        //         / \
        // X    /       \
        //   /             \
        // <                > Y
        // 


        

        // Convert world coord to view
        vec2f transform(float x, float y, float z)
        {
            x -= camera.x;
            y -= camera.y;
            z -= camera.z;

            float vy = exp((_mouseY-H*0.5)/H);
            float vx1 = cos(PI/4 + (_mouseX-W*0.5)*PI*0.25/W);
            float vx2 = sqrt(1-vx1*vx1);


            float tx = x * -0.8*vx1 + y * 0.8*vx2;
            float ty = x * 0.6*vx2 * vy + y * 0.6*vx1 * vy - z * vy;

            // to screen space
            float ZOOM = H / 15.0f;
            tx = tx * ZOOM + W * 0.5;
            ty = ty * ZOOM + H * 0.5;

            return vec2f(tx, ty);
        }

        // Get local cube of data
        for (int x = -EXTENT; x <= EXTENT; ++x)
        {
            for (int y = -EXTENT; y <= EXTENT; ++y)
            {
                for (int z = -EXTENT; z <= EXTENT; ++z)
                {
                    int ix = x + cast(int)(camera.x);
                    int iy = y + cast(int)(camera.y);
                    int iz = z + cast(int)(camera.z);
                    if (map.contains(ix, iy, iz))
                    {
                        localBlocks[x + EXTENT][y + EXTENT][z + EXTENT] = map.block(ix, iy, iz);
                    }
                    else
                    {
                        localBlocks[x + EXTENT][y + EXTENT][z + EXTENT].isSolid = false;
                    }
                }
            }
        }

        int cc = 0;

        // Compute order of draw
        for (int x = 0; x < CUBELEN; ++x)
        {
            for (int y = 0; y < CUBELEN; ++y)
            {
                for (int z = 0; z < CUBELEN; ++z)
                { 
                    orderOfDraw[z + y*CUBELEN + x*CUBELEN*CUBELEN] = vec3i(x, y, z);
                }
            }
        }        
        timSort!vec3i(orderOfDraw[], tempSortBuf, (a, b) => (a.x+a.y+a.z - (b.x+b.y+b.z)));        

        vec3f playerPos = camera;
       
        void drawCube(float x, float y, float z, RGBA color, 
                      bool drawXFace, bool drawYFace, bool drawZFace)
        {
            canvas.fillStyle = color;    

            if (drawZFace)
            {
                canvas.beginPath();
                canvas.moveTo( transform(x,    y,  z+1) );
                canvas.lineTo( transform(x+1,  y,  z+1) );
                canvas.lineTo( transform(x+1, y+1, z+1) );
                canvas.lineTo( transform(x,   y+1, z+1) );
                canvas.closePath;
                canvas.fill();
            }

            if (drawXFace)
            {
                canvas.beginPath();
                canvas.moveTo( transform(x+1,  y,  z) );
                canvas.lineTo( transform(x+1,  y,  z+1) );
                canvas.lineTo( transform(x+1,  y+1, z+1) );
                canvas.lineTo( transform(x+1,  y+1, z) );
                canvas.closePath;
                canvas.fill();
            }

            if (drawYFace)
            {
                canvas.beginPath();
                canvas.moveTo( transform(x,  y+1,  z) );
                canvas.lineTo( transform(x+1,  y+1,  z) );
                canvas.lineTo( transform(x+1,  y+1, z+1) );
                canvas.lineTo( transform(x,  y+1, z+1) );
                canvas.closePath;
                canvas.fill();
            }
        }


        for (int ii = 0; ii < NUM_CUBES; ++ii)
        {
            int ix = orderOfDraw[ii].x;
            int iy = orderOfDraw[ii].y;
            int iz = orderOfDraw[ii].z;

            if (iz < EXTENT-6 || iz > EXTENT + 4)
                continue;
            
            Block bl = localBlocks[ix][iy][iz];

            bool canObstructPlayer = iz >= EXTENT;

            int world_ix = ix - EXTENT + cast(int)camera.x;
            int world_iy = iy - EXTENT + cast(int)camera.y;
            int world_iz = iz - EXTENT + cast(int)camera.z;

            // distance of center of drawn block
            float blockDist = distance(world_ix + 0.5f, world_iy + 0.5f, world_iz + 0.5f);



            // draw cube
            if (bl.isSolid) 
            {
                // Compute some occlusion stuff
                bool xHidden = (ix + 1 < CUBELEN) ? localBlocks[ix+1][iy][iz].isOpaque : false;
                bool yHidden = (iy + 1 < CUBELEN) ? localBlocks[ix][iy+1][iz].isOpaque : false;
                bool zHidden = (iz + 1 < EXTENT + 4) ? localBlocks[ix][iy][iz+1].isOpaque : false;
                int absZ = iz - EXTENT;
                if (absZ <= 2) zHidden = false;

                float light;

                // decreasing light from player
                {
                    float dx = fast_fabs(world_ix - playerPos.x);
                    float dy = fast_fabs(world_iy - playerPos.y);
                    float dz = fast_fabs(world_iz - playerPos.z);
                    float dist = fast_sqrt(dx*dx+dy*dy+dz*dz);
                    light = 1.4 * exp(-dist * 0.15);
                    if (light < 0) light = 0;

                    // shadow from player
                    float dx2 = fast_fabs(world_ix - playerPos.x+0.5);
                    float dy2 = fast_fabs(world_iy - playerPos.y+0.5);
                    float dz2 = fast_fabs(world_iz - playerPos.z+1);
                    float dist2 = fast_sqrt(dx2*dx2+dy2*dy2+dz2*dz2);
                    float shadow = 1 - 1.0 * exp(-dist2 * 1.0);
                    light *= shadow;
                }


                int red = cast(int)(bl.r * light);
                int green = cast(int)(bl.g * light);
                int blue = cast(int)(bl.b * light);
                if (red > 255) red = 255;
                if (green > 255) green = 255;
                if (blue > 255) blue = 255;
                drawCube(world_ix, world_iy, world_iz, RGBA(cast(ubyte)red, cast(ubyte)green, cast(ubyte)blue, 255), !xHidden, !yHidden, !zHidden);
            }

            RGBA playerColor = RGBA(200, 100, 100, 255);
            // draw player low cube
            if (ix == EXTENT+1 && iy == EXTENT+1 && iz == EXTENT)
            {
                
                drawCube(playerPos.x-0.5, playerPos.y-0.5, playerPos.z-0.5, playerColor, true, true, true);
            }

            // draw player high cube
            if (ix == EXTENT+1 && iy == EXTENT+1 && iz == EXTENT+1)
            {
                drawCube(playerPos.x-0.5, playerPos.y-0.5, playerPos.z+0.5, playerColor, true, true, true);
            }
        }

        RGBA playerColor2 = RGBA(200, 100, 100, 30);
        drawCube(playerPos.x-0.5, playerPos.y-0.5, playerPos.z-0.5, playerColor2, true, true, true);
        drawCube(playerPos.x-0.5, playerPos.y-0.5, playerPos.z+0.5, playerColor2, true, true, true);
    } 


private:

    // is also the player position, corresponding to its feet
    // Player is 2 blocks high, one block wide, like in AoS.
    vec3f camera;

    AOSMap map;

    // Order in which to draw the cubes
    vec3i[NUM_CUBES] orderOfDraw;
    Vec!vec3i tempSortBuf;

    // Local map content
    Block[CUBELEN][CUBELEN][CUBELEN] localBlocks; // index it by [x][y][z], add +EXTENT to each dim

    enum int EXTENT = 7;
    enum int CUBELEN = EXTENT+EXTENT+1;
    enum int NUM_CUBES = CUBELEN*CUBELEN*CUBELEN;
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

    map.blueSpawnArea = blueSpawnArea;
    map.greenSpawnArea = greenSpawnArea;
/*
    debug {} else
    {*/
        writefln("*** Color bleeding...");
        map.colorBleed();

        writefln("*** Compute omnidirectional Ambient Occlusion...");
        map.betterAO();

//        writefln("*** Reverse client Ambient Occlusion...");
  //      map.reverseClientAO();
    //}

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

float distance(float x, float y, float z)
{
    return x+y+z;
}