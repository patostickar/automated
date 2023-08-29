#!/bin/bash

shc -f dev.sh
mkdir -p bin
rm ./dev.sh.x.c
mv ./dev.sh.x ./bin/dev

echo "Built new binary! Check out the 'bin' directory"
