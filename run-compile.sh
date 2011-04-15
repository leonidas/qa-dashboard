#!/bin/sh -x
mkdir -p ./server/js
./node_modules/coffee-script/bin/coffee -c qadash.coffee
./node_modules/coffee-script/bin/coffee -c -o ./server/js server/*.coffee
./node_modules/less/bin/lessc -x public/less/dashboard.less > public/css/dashboard.css
