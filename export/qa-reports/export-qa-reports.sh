#!/bin/sh
coffee="node_modules/coffee-script/bin/coffee"
forever="node_modules/forever/bin/forever"
app="export-qa-reports.coffee"
usage="USAGE: "$0" start|stop|restart"
mkdir -p log
mkdir -p log/sock
if [ $# -eq 0 ]; then
    echo $usage
else
    run_cmd=$forever" "$1" -p log -c "$coffee" "$app
    $run_cmd
fi
