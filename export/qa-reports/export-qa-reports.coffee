# QA-Reports export daemon
async   = require('async')
request = require('request')
fs      = require('fs')
_       = require('underscore')


SECONDS = 1000
MINUTES = 60*SECONDS
HOURS   = 60*MINUTES

launchDaemon = (basedir, cfg) ->

    SINCEFILE = "#{basedir}/last-report.txt"
    fetchCount = cfg.reports.fetchCount

    fmtDate = (date) ->
        escape "#{date.getUTCFullYear()}-#{date.getUTCMonth()+1}-#{date.getUTCDate()} #{date.getUTCHours()}:#{date.getUTCMinutes()}:#{date.getUTCSeconds()}"

    fetchReports = (since, callback) ->

        console.log "fetching next #{fetchCount} reports since #{since?.toISOString()}"
        url = "#{cfg.reports.url}/api/reports?limit_amount=#{fetchCount}"
        if since?
            url += "&begin_time=#{fmtDate since}"
        opts =
            uri:    url
            method: "GET"
        console.log "GET: #{url}"
        proxy = cfg.reports.proxy
        auth = proxy.basicAuth
        opts.auth = auth if auth? and auth != ""
        if proxy.enabled
            opts.proxy = proxy.url
            auth = proxy.basicAuth
            opts.proxy.auth = auth if auth? and auth != ""
        request opts, (err, res, body) ->
            return callback err if err?
            return callback res.statusCode if res.statusCode != 200
            return callback null, JSON.parse(body)

    pushReports  = (reports, callback) ->
        console.log "..received #{reports.length} reports"
        url = "#{cfg.dashboard.url}/import/qa-reports/massupdate"
        request {
            uri:    url
            method: "POST"
            json:   {reports: reports, token: cfg.dashboard.token}
            }, (err, res, body) ->
                return callback err if err?
                return callback body.error if body.status == "error"
                return callback res.statusCode if res.statusCode != 200
                return callback null, reports

    getStartDate = (callback) ->
        request.get {
            uri:    "#{cfg.dashboard.url}/import/qa-reports/latest",
            qs:     {token: cfg.dashboard.token},
            json:   true
        }, (err, res, data) ->
            return callback err if err?
            return callback null, null unless data?.updated_at?
            return callback null, new Date(data.updated_at)

    scheduleNextPoll = (reports, callback) ->
        if reports.length < fetchCount
            # There are no more reports for now
            waitTime = 1*HOURS
        else
            waitTime = 1*SECONDS

        setTimeout pollReports, waitTime
        callback null


    pollReports = (callback) ->
        tasks = [
            getStartDate,
            fetchReports,
            pushReports,
            scheduleNextPoll ]

        async.waterfall tasks, (err) ->
            if err?
                console.log "ERROR: #{err}"
                setTimeout pollReports, 5*MINUTES

            callback? err

    pollReports()

cfg = JSON.parse fs.readFileSync "config.json", "utf-8"
launchDaemon __dirname, cfg
