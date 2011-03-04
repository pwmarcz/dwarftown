swig -c++ -lua -I../include -DTCODLIB_API ../swig/libtcod.i
g++ -s -O2 -I../include ../swig/libtcod_wrap.cxx -L.. -llibtcod-mingw -llua51 -lstdc++ -shared -o libtcodlua.dll
