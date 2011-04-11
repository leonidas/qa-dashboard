#!/bin/sh
mkdir -p ./server/js
./node_modules/coffee-script/bin/coffee -c qadash.coffee
./node_modules/coffee-script/bin/coffee -c -o ./server/js server/*.coffee