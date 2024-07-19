module text8;


import bindbc.lua;
import textmode;

class Text8VM
{
    this()
    {
        LuaSupport support = loadLua();
        _luaState = luaL_newstate();
        luaL_openlibs(_luaState);


        // TODO  initialize builtins

        // TODO load default cartridge
    }

    string message = "OK";

    ~this()
    {
        lua_close(_luaState);
    }

    void load(const(ubyte)[] source)
    {
        // Here we load the string and use lua_pcall for run the code
        if (luaL_loadstring(_luaState, cast(char*)(source.ptr)) == 0) 
        {
            if (lua_pcall(_luaState, 0, 0, 0) == 0) 
            {
                // If it was executed successfuly we 
                // remove the code from the stack
                lua_pop(_luaState, lua_gettop(_luaState));
            }
        }
    }

    void callInit()
    {
        // TODO
    }

    void callKeydown(const(char)* keyZ)
    {
        // TODO
    }

    void callStep()
    {
    }

    void render(TM_Console* console)
    {
        
    }

private:
    lua_State *_luaState;
	
}