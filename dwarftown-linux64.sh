#!/bin/sh

LD_LIBRARY_PATH="$LD_LIBRARY_PATH:wrapper/linux64/" wrapper/linux64/lua -e "package.cpath = package.cpath .. ';wrapper/linux64/?.so'" src/main.lua
