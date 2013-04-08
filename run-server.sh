#!/bin/sh
coffee="node_modules/coffee-script/bin/coffee"
supervisor="node_modules/supervisor/lib/cli-wrapper.js"
forever="node_modules/forever/bin/forever"
app="qadash.coffee"

run_cmd=$supervisor" -w qadash.coffee,server,plugins/query,plugins/import,settings.json -x "$coffee" "$app

usage=$0" <options>\n
Default:\n
\tRun server with node-supervisor (development mode)\n
Options:\n
\t--forever start\tRun continuously and automatically restart (daemonize).\n
\t--forever stop\tStop daemonized process\n"

if [ $# -eq 0 ]; then
    NODE_PATH=server $run_cmd
elif [ $# -eq 2 ] && [ "$1" = "--forever" ]; then
    [ -d log ] || mkdir log
    sleep 6
    run_cmd=$forever" "$2" -p log -c "$coffee" "$app
    NODE_PATH=server $run_cmd
    sleep 6
else
    echo $usage
fi
