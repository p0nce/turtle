module aliasthis.worldstate;

import std.random;
import std.math;

import turtle;

import aliasthis.console,
       aliasthis.command,
       aliasthis.entity,
       aliasthis.chartable,
       aliasthis.config,
       aliasthis.utils,
       aliasthis.change,
       aliasthis.cell,
       aliasthis.levelgen,
       aliasthis.grid;

// Holds the whole game state
// SHOULD know nothing about Change and ChangeSet
class WorldState
{
    public
    {
        Grid _grid;
        Human _human;

        this(Grid grid, Human human)
        {
            _grid = grid;
            _human = human;
        }

        // generate a WorldState from a seed (new game)
        static WorldState createNewWorld(ref Xorshift rng)
        {
            auto grid = new Grid(rng);

            auto human = new Human();
            human.position = vec3i(10, 10, GRID_DEPTH - 1);

            auto worldState = new WorldState(grid, human);

            auto levelGen = new LevelGenerator();
            levelGen.generate(rng, worldState);

            return worldState;
        }

        void draw(Console console)
        {
            int offset_x = 0;
            int offset_y = 0;

            int levelToDisplay = _human.position.z;
            for (int y = 0; y < GRID_HEIGHT; ++y)
            {
                for (int x = 0; x < GRID_WIDTH; ++x)
                {
                    int lowest = levelToDisplay;

                    while (lowest > 0 && _grid.cell(vec3i(x, y, lowest)).type == CellType.HOLE)
                        lowest--;

                    // render bottom to up
                    for (int z = lowest; z <= levelToDisplay; ++z)
                    {
                        Cell* cell = _grid.cell(vec3i(x, y, z));

                        int cx = offset_x + x;
                        int cy = offset_y + y;

                        CellGraphics gr = cell.graphics;

                        // don't render holes except at level 0
                        if (cell.type != CellType.HOLE || z == 0)
                        {
                            int levelDiff = levelToDisplay - lowest;
                            console.setForegroundColor(colorFog(gr.foregroundColor, levelDiff));
                            RGB foggy = colorFog(gr.backgroundColor, levelDiff);
                            console.setBackgroundColor(RGBA(foggy.r, foggy.g, foggy.b, 255));
                            console.putChar(cx, cy, gr.charIndex);
                        }
                    }
                }   
            }

            // put players
            {
                int cx = _human.position.x + offset_x;
                int cy = _human.position.y + offset_y;
                console.setBackgroundColor(RGBA(0,0,0,0));
                console.setForegroundColor(RGB(223, 105, 71));
                console.putChar(cx, cy, ctCharacter!'Ѭ');
            }
        }

        // make things move
        void estheticUpdate(double dt)
        {
            int visibleLevel = _human.position.z;
            _grid.estheticUpdate(visibleLevel, dt);
        }


        // compile a Command to a ChangeSet
        // returns null is not a valid command
        Change[] compileCommand(Entity entity, Command command /*, out bool needConfirmation */ )
        {
            Change[] changes;
            final switch (command.type)
            {
                case CommandType.WAIT:
                    break; // no change

                case CommandType.MOVE:
                    
                    vec3i movement = getDirection(command.params.move.direction);
                    vec3i oldPos = _human.position;
                    vec3i newPos = _human.position + movement;

                    // going out of the map is not possible
                    if (!_grid.contains(newPos))
                        return null;

                    Cell* oldCell = _grid.cell(oldPos);
                    Cell* cell = _grid.cell(newPos);

                    int abs_x = std.math.abs(movement.x);
                    int abs_y = std.math.abs(movement.y);
                    int abs_z = std.math.abs(movement.z);
                    if (abs_z == 0)
                    {
                        if (abs_x > 1 || abs_y > 1)
                            return null; // too large movement
                    }
                    else 
                    {
                        if (abs_x != 0 || abs_y != 0)
                            return null; // too large movement

                        if (abs_z > 1)
                            return null;

                        if (movement.z == -1 && oldCell.type != CellType.STAIR_DOWN)
                            return null;
                        
                        if (movement.z == 1 && oldCell.type != CellType.STAIR_UP)
                            return null;
                    }
                    
                    if (canMoveInto(cell.type))
                        changes ~= Change.createMovement(oldPos, newPos);
                    else
                        return null;

                    // fall into holes
                    while (cell.type == CellType.HOLE)
                    {
                        vec3i belowPos = newPos - vec3i(0, 0, 1);
                        if (!_grid.contains(belowPos))
                            break;

                        Cell* below = _grid.cell(belowPos);
                        if (canMoveInto(below.type))
                        {
                            changes ~= Change.createMovement(newPos, belowPos);
                            newPos = belowPos;
                            cell = below;
                        }
                        else
                            break;
                    }
            }

            return changes;
        }
    }

  
}