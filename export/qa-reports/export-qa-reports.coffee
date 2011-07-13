# QA-Reports export daemon

async   = require('async')
get     = require('get')
request = require('request')

launchDaemon = (basedir, cfg) ->

    SINCEFILE = "#{basedir}/last-report.txt"

    fetchReports = (since, callback) ->
        new get(cfg.reportsUrl).asString (err, s) ->
            return callback err if err?
            callback null, JSON.parse(s)

    pushReports  = (reports, callback) ->
        request {
            uri:    cfg.dashboardUrl
            method: "POST"
            json:   reports
            }, (err, res, body) ->
                return callback err if err?
                return callback body.error if body.status == "error"
                return callback res.statusCode if res.statusCode != 200
                callback null, reports

    readSinceFile = (callback) -> callback null

    writeSinceFile = (since, callback) -> callback null


    pollReports = (callback) ->
        tasks = [readSinceFile,fetchReports,pushReports,writeSinceFile]
        async.waterfall tasks, (err) ->
            # TODO

