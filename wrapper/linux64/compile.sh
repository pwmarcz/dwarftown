#!/bin/sh

swig -c++ -lua -I../include -I/usr/include/lua5.1/ -DTCODLIB_API ../swig/libtcod.i
g++ -s -O2 -I../include -I/usr/include/lua5.1/ ../swig/libtcod_wrap.cxx -L. -ltcod -ltcodxx -llua5.1 -lstdc++ -shared -fPIC -o libtcodlua.so
