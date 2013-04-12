#!/usr/bin/env coffee

# Simple script for creating local user accounts. Does not currently handle
# remote servers etc.

program = require 'commander'
auth    = require 'authentication'
fs      = require 'fs'
mongodb = require 'mongodb'

settings = JSON.parse fs.readFileSync("settings.json")
env      = process.env.NODE_ENV || 'development'

program.prompt 'Username: ', (username) ->
  program.password 'Password: ', (pwd1) ->
    program.password 'Retype password: ', (pwd2) ->
      if pwd1 != pwd2
        console.log "ERROR: Passwords do not match"
        process.exit(1)

      new mongodb.Db("qadash-#{env}", new mongodb.Server(settings.db.host, settings.db.port), w: 1).open (err, db) ->
        if err?
          console.log "ERROR: Failed to connect to database: #{err}"
          process.exit(1)

        auth.create_user db, username, pwd1, (err) ->
          if err?
            console.log "ERROR: Failed to create account: #{err}"
            process.exit(1)

          console.log "Account created"
          db.close()
