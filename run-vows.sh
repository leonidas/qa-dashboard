#!/bin/sh
mkdir -p vows-js
rm -f vows-js/*
./node_modules/coffee-script/bin/coffee --compile --output vows-js vows
./node_modules/vows/bin/vows vows-js/* $1
