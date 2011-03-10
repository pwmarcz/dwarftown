#!/bin/sh

LD_LIBRARY_PATH="$LD_LIBRARY_PATH:wrapper/linux/" wrapper/linux/lua -e "package.cpath = package.cpath .. ';wrapper/linux/?.so'" src/main.lua $1

