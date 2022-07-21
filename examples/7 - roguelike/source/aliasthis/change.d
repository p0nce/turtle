module aliasthis.change;

import dplug.math;

import aliasthis.worldstate;

// WorldState changes


// A change must be a small, reversible change.
// - cannot fail else unrecoverable error
// - reversible
struct Change
{
    enum Type
    {
        MOVE,
   //     PICK_DROP,
   //     HP_CHANGE
    }

    Type type;
    vec3i sourcePosition;
    vec3i destPosition;

    static Change createMovement(vec3i source, vec3i dest)
    {
        Change res;
        res.type = Type.MOVE;
        res.sourcePosition = source;
        res.destPosition = dest;
        return res;
    }
}

void applyChange(WorldState worldState, Change change)
{
    final switch (change.type)
    {
        case Change.Type.MOVE:
            worldState._human.position = change.destPosition;
            break;
    }
}

void revertChange(WorldState worldState, Change change)
{
    final switch (change.type)
    {
        case Change.Type.MOVE:
            worldState._human.position = change.sourcePosition;
            break;
    }
}

void applyChangeSet(WorldState worldState, Change[] changeSet)
{
    foreach (ref Change change ; changeSet)
        applyChange(worldState, change);
}

void revertChangeSet(WorldState worldState, Change[] changeSet)
{
    foreach_reverse (ref Change change ; changeSet)
        revertChange(worldState, change);
}

