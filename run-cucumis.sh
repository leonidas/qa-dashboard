#!/bin/sh -x
./node_modules/coffee-script/bin/coffee -c ./features/step_definitions/login.coffee
NODE_ENV=test node_modules/cucumis/bin/cucumis -t 15000
