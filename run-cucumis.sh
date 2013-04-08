#!/bin/sh

# Handle stopselenium command
if [ "$1" = "--stopselenium" ]; then
    echo "Shutting down selenium server..."
    curl 'http://localhost:4444/selenium-server/driver/?cmd=shutDownSeleniumServer'
    echo ""
    exit
fi

if [ ! -d log ]; then
    mkdir log
fi

# Check if Selenium server is already running
sel=$(curl --silent 'http://localhost:4444/wd/hub/status' | grep -c 'selenium')
if [ $sel -eq 0 ]; then

    # Check if Selenium server jar can be found
    if [ ! -e selenium-server-standalone-2.2.0.jar ]; then
        echo "selenium rc server not found -> downloading"
        curl -O 'http://selenium.googlecode.com/files/selenium-server-standalone-2.2.0.jar'
    fi

    # Start Selenium server
    echo "selenium rc server not running -> starting"
    java -jar selenium-server-standalone-2.2.0.jar > log/selenium.log&
    sleep 5
fi

# Run tests
./node_modules/coffee-script/bin/coffee -c ./features/step_definitions
NODE_PATH=server NODE_ENV=test node_modules/.bin/cucumis -t 15000
