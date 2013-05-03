# QA-Reports export daemon
async   = require('async')
request = require('request')
fs      = require('fs')
_       = require('underscore')
winston = require('winston')

# Initialize logger
winston.remove winston.transports.Console
winston.add winston.transports.Console,
  timestamp:   true
  colorize:    true
  prettyPrint: true
  level:       'info'
winston.setLevels winston.config.syslog.levels

SECONDS = 1000
MINUTES = 60*SECONDS
HOURS   = 60*MINUTES

launchDaemon = (cfg) ->
    fetchCount = cfg.reports.fetchCount

    # Get request options (basic auth, proxy)
    __get_opts = (service) ->
        opts = json: true
        if service.proxy?.enabled
            opts['proxy'] = service.proxy.url
        if service.basicAuth?.enabled
            opts['auth'] =
            user: service.basicAuth.username
            pass: service.basicAuth.password
        opts

    fmtDate = (date) ->
        escape "#{date.getUTCFullYear()}-#{date.getUTCMonth()+1}-#{date.getUTCDate()} #{date.getUTCHours()}:#{date.getUTCMinutes()}:#{date.getUTCSeconds()}"

    fetchReports = (since, callback) ->
        winston.info "Fetching next #{fetchCount} reports since #{since?.toISOString()}"

        opts         = __get_opts(cfg.reports)
        opts['uri']  = "#{cfg.reports.url}/api/reports?limit_amount=#{fetchCount}"

        if since?
            opts['uri'] += "&begin_time=#{fmtDate since}"

        request.get opts, (err, res, body) ->
            # Mark the report being delivered using the exporter. We can
            # then return the latest report date for exported reports only.
            # Now if QA Reports exports n reports but only the last one
            # succeeds the exporter will find the remaining reports.
            reports = _.map body, (report) -> report.exported = true
            return callback err if err?
            return callback res.statusCode if res.statusCode != 200
            return callback null, body

    pushReports  = (reports, callback) ->
        winston.info "Received #{reports.length} reports"

        opts         = __get_opts(cfg.dashboard)
        opts['uri']  = "#{cfg.dashboard.url}/import/qa-reports/massupdate"
        opts['json'] = reports: reports, token: cfg.dashboard.token

        request.post opts, (err, res, body) ->
            return callback err if err?
            return callback body.error if body.status == "error"
            return callback res.statusCode if res.statusCode != 200
            return callback null, reports

    getStartDate = (callback) ->
        winston.info "Get the latest updated at date from QA Dashboard"

        opts        = __get_opts(cfg.dashboard)
        opts['uri'] = "#{cfg.dashboard.url}/import/qa-reports/latest"
        opts['qs']  = token: cfg.dashboard.token

        request.get opts, (err, res, data) ->
            return callback err if err?
            return callback null, null unless data?.updated_at?
            return callback null, new Date(data.updated_at)

    scheduleNextPoll = (reports, callback) ->
        if reports.length < fetchCount
            # There are no more reports for now
            winston.info "Next poll in #{cfg.reports.updateInterval} hours"
            waitTime = cfg.reports.updateInterval * HOURS
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
                winston.error "Error when fetching reports, trying again", err
                setTimeout pollReports, 5 * MINUTES

            callback? err

    pollReports()

cfg = JSON.parse fs.readFileSync "config.json", "utf-8"
launchDaemon cfg
