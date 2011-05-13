
{exec} = require 'child_process'

# Import production database to development environment
task 'db:import', 'Import production database to development environment', ->
    console.log "getting database dump from production..."
    exec "cap production db:dump", (err,stdout,stderr) ->
        console.log stderr
        throw err if err
        console.log stdout

        console.log "extracting and importing..."
        exec "tar -xzf qadash-production.tar.gz && mongorestore --db qadash-development dump/qadash-production && rm qadash-production.tar.gz", (err,stdout,stderr) ->
            console.log stderr
            throw err if err
            console.log stdout
            console.log "done!"
