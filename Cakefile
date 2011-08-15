{spawn} = require 'child_process'

run_cmd = (cmd, args, cb) ->
    console.log "#{cmd} #{args.join(' ')}"
    cmd_process = spawn cmd, args

    cmd_process.stdout.on 'data', (data) -> console.log data.toString()
    cmd_process.stderr.on 'data', (data) -> console.log data.toString()

    cmd_process.on 'exit', (code) ->
        return cb? "ERROR: #{cmd} process exited with code: #{code}" if code != 0
        cb? null

dump2db = (filename, cb) ->
    #Extract dump
    console.log "\x1b[33mExtracting...\x1b[0m"
    run_cmd 'tar',['-xzf',filename], (err) ->
        return cb? err if err?
        #Import dump to database
        console.log "\x1b[33mImporting...\x1b[0m"
        run_cmd 'mongorestore',['--db','qadash-development','dump/qadash-production'], (err) ->
            return cb? err if err?
            cb? null

# Import production database to development environment
option '-f', '--file [FILENAME]', 'import from file (tarball of production database dump)'
task 'db:import', 'Import production database to development environment', (options) ->

    #Import from file - option
    if options.file?
        dump2db options.file, (err) ->
            throw err if err?
            console.log "\x1b[33mDone!\x1b[0m"
        return

    # Get database dump
    console.log "\x1b[33mGetting database dump... (this may take a while)\x1b[0m"
    run_cmd 'cap', ['production','db:dump'], (err) ->
        throw err if err?
        # Extract and import
        dump2db 'qadash-production.tar.gz', (err) ->
            throw err if err?
            #Cleanup
            console.log "\x1b[33mCleanup...\x1b[0m"
            run_cmd 'rm',['qadash-production.tar.gz'], (err) ->
                throw err if err?
                console.log "\x1b[33mDone!\x1b[0m"
