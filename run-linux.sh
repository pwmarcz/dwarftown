#!/bin/sh

LD_LIBRARY_PATH="$LD_LIBRARY_PATH:wrapper/linux/" lua -e "package.cpath = package.cpath .. ';wrapper/linux/?.so'" src/main.lua