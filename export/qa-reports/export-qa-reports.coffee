# QA-Reports export daemon
require.paths.unshift './node_modules'

async   = require('async')
get     = require('get')
request = require('request')
fs      = require('fs')
_       = require('underscore')


SECONDS = 1000
MINUTES = 60*SECONDS
HOURS   = 60*MINUTES

launchDaemon = (basedir, cfg) ->

    SINCEFILE = "#{basedir}/last-report.txt"

    fmtDate = (date) ->
        "#{date.getFullYear()}-#{date.getMonth()}-#{date.getDay()} #{date.getHours()}:#{date.getMinutes()}:#{date.getSeconds()}"

    fetchReports = (since, callback) ->

        console.log "fetching next #{cfg.maxReportCount} reports since #{since}"
        url = "#{cfg.reportsUrl}/api/reports?limit_amount=#{cfg.maxReportCount}"
        if since?
            url += "&begin_time=#{fmtDate since}"
        console.log url
        request {uri: url, method:"GET"}, (err, res, body) ->
            console.log body
            return callback err if err?
            return callback res.statusCode if res.statusCode != 200
            return callback null, JSON.parse(body)

    pushReports  = (reports, callback) ->
        console.log "..received #{reports.length} reports"
        url = "#{cfg.dashboardUrl}/import/qa-reports/massupdate"
        request {
            uri:    cfg.dashboardUrl
            method: "POST"
            json:   {reports: reports, token: cfg.dashboardToken}
            }, (err, res, body) ->
                return callback err if err?
                return callback body.error if body.status == "error"
                return callback res.statusCode if res.statusCode != 200
                return callback null, reports

    readSinceFile = (callback) ->
        fs.readFile SINCEFILE, "utf-8", (err, s) ->
            return callback null, null if err?
            return callback null, Date.parse(s)

    writeSinceFile = (reports, callback) ->
        since = _.last(reports).updated_at
        fs.writeFile SINCEFILE, since.toString(), (err) ->
            callback null, reports

    scheduleNextPoll = (reports, callback) ->
        if reports.length < cfg.maxReportCount
            # There are no more reports for now
            waitTime = 1*HOURS
        else
            waitTime = 1*SECONDS

        setTimeout pollReports, waitTime
        callback null


    pollReports = (callback) ->
        tasks = [
            readSinceFile,
            fetchReports,
            pushReports,
            writeSinceFile,
            scheduleNextPoll ]

        async.waterfall tasks, (err) ->
            if err?
                console.log "ERROR: #{err}"
                setTimeout pollReports, 5*MINUTES

            callback err

    pollReports()

cfg = JSON.parse fs.readFileSync "config.json", "utf-8"
launchDaemon __dirname, cfg
