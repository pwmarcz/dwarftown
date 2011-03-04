#include "bresenham.hpp"
#include "path.hpp"

class LuaCallback {
protected:
    // Because ITCODPathCallback's method must be const
    const SWIGLUA_REF fn;
    LuaCallback(SWIGLUA_REF fn): fn(fn) {}
    LuaCallback(const LuaCallback&);
public:   
    virtual ~LuaCallback() {
        swiglua_ref_clear((SWIGLUA_REF*)&fn);
    }
};

class LuaLineListener: public TCODLineListener, public LuaCallback {
public :
    LuaLineListener(SWIGLUA_REF fn): LuaCallback(fn) {}
	bool putPoint(int x, int y) {
        swiglua_ref_get((SWIGLUA_REF*)&fn);
        lua_pushnumber(fn.L, x);
        lua_pushnumber(fn.L, y);
        lua_call(fn.L, 2, 1);
        bool result = lua_toboolean(fn.L,-1);
        lua_pop(fn.L, 1);
        return result;       
    }
};

class LuaPathCallback: public ITCODPathCallback, public LuaCallback {
public :
    LuaPathCallback(SWIGLUA_REF fn): LuaCallback(fn) {}
    float getWalkCost( int xFrom, int yFrom, int xTo, int yTo, void *userData) const {
        swiglua_ref_get((SWIGLUA_REF*)&fn);
        lua_pushnumber(fn.L, xFrom);
        lua_pushnumber(fn.L, yFrom);
        lua_pushnumber(fn.L, xTo);
        lua_pushnumber(fn.L, yTo);
        lua_call(fn.L, 4, 1);
        float result = lua_tonumber(fn.L,-1);
        lua_pop(fn.L, 1);
        return result;       
    }
};
