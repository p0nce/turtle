module vxlgen.block;

import dplug.math.vector;


struct Block
{
    this(bool solid) // empty block
    {
        isSolid = solid ? 1 : 0;
        r = 0;
        g = 0;
        b = 0;
    }

    this(float fr, float fg, float fb)
    {
        setf(fr, fg, fb);
    }

    this(ubyte pr, ubyte pg, ubyte pb)
    {
        seti(pr, pg, pb);
    }

    ubyte isSolid; // 0 or 1
    ubyte r;
    ubyte g;
    ubyte b;

    void empty() 
    { 
        isSolid = 0; 
    }

    bool isOpaque() // for occlusion
    {
        return isSolid != 0;
    }

    void setf(vec3f v) 
    { 
        setf(v.x, v.y, v.z);
    }

    void seti(ubyte pr, ubyte pg, ubyte pb)
    { 
        r = pr;
        g = pg;
        b = pb;
        isSolid = 1;
    }

    void setf(float fr, float fg, float fb) 
    { 
        if (fr < 0) fr = 0;
        if (fr > 1) fr = 1;
        if (fg < 0) fg = 0;
        if (fg > 1) fg = 1;
        if (fb < 0) fb = 0;
        if (fb > 1) fb = 1;

        r = cast(ubyte)(0.5f + fr * 255.0f);
        g = cast(ubyte)(0.5f + fg * 255.0f);
        b = cast(ubyte)(0.5f + fb * 255.0f);

        isSolid = 1;
    }
}

