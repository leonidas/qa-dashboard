# Bugzilla export daemon - fetch data from Bugzilla and deliver to QA Dashboard
request = require 'request'
Vow     = require 'vow'
fs      = require 'fs'
csv     = require 'csv'
winston = require 'winston'
util    = require 'util'

# Initialize logger
winston.remove winston.transports.Console
winston.add winston.transports.Console,
  timestamp:   true
  colorize:    true
  prettyPrint: true
  level:       'info'
winston.setLevels winston.config.syslog.levels

SECOND = 1000
MINUTE = 60 * SECOND
HOUR   = 60 * MINUTE

date_utils =
  # Bugzilla datetime string
  bugzilla_string_to_date: (str) ->
    unless str?.match /^\d{4}-\d{1,2}-\d{1,2} \d{1,2}:\d{1,2}:\d{1,2}$/
      winston.warning "Given string does not match date pattern", str
      return null
    # The given date is in UTC timezone, tell it to node as well
    d = new Date "#{str} UTC"
    d

  # Get year and week of given date. Week with Jan 1st is
  # the first week, and the days from prev December are included in
  # week 1 of that year.
  get_year_week: (d) ->
    jan1st     = new Date "#{d.getFullYear()}-01-01 00:00:00 UTC"
    nextjan1st = new Date "#{d.getFullYear() + 1}-01-01 00:00:00 UTC"

    # Less than a week from next Jan 1st, can mean that we actually need
    # to return 1 instead of what the other calculation would give
    if (nextjan1st - d) / 86400000 < 7
      # Day number of next Jan 1st is greater than that of the given date
      # which means that they're on the same Sun-Sat section, i.e. on the
      # same week -> return 1 for week number
      if nextjan1st.getDay() > d.getDay()
        return [nextjan1st.getFullYear(), 1]

    # This works for all except last week of year (could give e.g. 53
    # when it really should be 1 since 1st of Jan is on the same week)
    wk = Math.ceil ((d - jan1st) / 86400000 + jan1st.getDay() + 1) / 7
    [d.getFullYear(), wk]

launch_daemon = (settings) ->
  __format_date = (date) -> encodeURIComponent "#{date.getUTCFullYear()}-#{date.getUTCMonth() + 1}-#{date.getUTCDate()}"

  # Get request options (basic auth, proxy)
  __get_opts = (service) ->
    opts = {}
    if service.proxy?.enabled
      opts['proxy'] = service.proxy.url
    if service.basicAuth?.enabled
      opts['auth'] =
        user: service.basicAuth.username
        pass: service.basicAuth.password
    opts

  # Add login parameters to Bugzilla query URI.
  __login_info = (uri) ->
    if settings.bugzilla.bzAuth?.enabled
      "#{uri}&Bugzilla_login=#{encodeURIComponent(settings.bugzilla.bzAuth.username)}&Bugzilla_password=#{encodeURIComponent(settings.bugzilla.bzAuth.username)}"
    else
      uri

  # Get the latest changed date of bugs from QA Dashboard
  get_start_date = ->
    winston.info "Get the latest change date from QA Dashboard"
    promise = Vow.promise()

    opts         = __get_opts(settings.dashboard)
    opts['uri']  = "#{settings.dashboard.url}/import/bugs/latest"
    opts['qs']   = token: settings.dashboard.token
    opts['json'] = true

    request.get opts, (err, res, data) ->
      return promise.reject err if err?
      return promise.reject "HTTP #{res.statusCode}. Is the token correct?" unless res.statusCode == 200
      cd = data?.changeddate || settings.bugzilla.start_date
      return promise.fulfill null unless cd? && cd != ""
      # Start a day earlier than the latest in DB - it seems it is possible
      # to miss some bugs if using the same date
      d = new Date(cd)
      d.setDate(d.getDate() - 1)
      return promise.fulfill d

    promise

  # Fetch bugs from Bugzilla
  fetch_bugs = (start_time) ->
    winston.warning "No start date defined, fetching all bugs!" unless start_time?
    promise = Vow.promise()

    opts        = __get_opts(settings.bugzilla)
    opts['uri'] = __login_info("#{settings.bugzilla.url}#{settings.bugzilla.query_uri}")

    if start_time?
      st = __format_date(start_time)
      start_time.setDate(start_time.getDate() + settings.fetch_days)
      et = __format_date(start_time)
      opts['uri'] += "&chfieldfrom=" + st
      opts['uri'] += "&chfieldto="   + et

      winston.info "Fetch bugs from #{st} to #{et}"

    request.get opts, (err, res, body) ->
      return promise.reject err if err?
      return promise.reject "Empty response" if body == ""
      # HTML response, something went wrong
      if res.headers['content-type'].match /text\/html/i
        if res.body.match /The username or password you entered is not valid/
          return promise.reject "Failed to login to Bugzilla"
        else
          return promise.reject 'HTML response received, something is wrong'
      # CSV response, parse it
      else if res.headers['content-type'].match /text\/csv/
        csv().from.string(body, columns: true).transform (record) ->
          if record.bug_id?
            # QA Reports now returns a prefix for all bugs since it supports
            # multiple Bugzilla services. So store store the bugs with prefixes
            # to bugs DB as well
            record.bug_id = "#{settings.bugzilla.prefix}##{record.bug_id}"
            record.url    = "#{settings.bugzilla.url}#{util.format(settings.bugzilla.show_uri, record.bug_id)}"

            [y, w] = date_utils.get_year_week(date_utils.bugzilla_string_to_date(record['opendate']))
            record.weeknum = w
            record.year    = y
          record
        .to.array (data) -> promise.fulfill bugs: data, end_time: et
      # Something else, don't know what to do
      else
        return promise.reject "Did not receive CSV but #{res.headers['content-type']}"

    promise

  # Send bugs to QA Dashboard
  push_bugs = (data) ->
    winston.info "Received #{data?.bugs?.length} bugs, uploading"
    promise = Vow.promise()

    opts         = __get_opts(settings.dashboard)
    opts['uri']  = "#{settings.dashboard.url}/import/bugs/update"
    opts['json'] =
      bugs:  data.bugs
      token: settings.dashboard.token

    request.post opts, (err, res, body) ->
      return promise.reject err if err?
      return promise.reject body.error if body.status == 'error'
      return promise.reject "HTTP #{res.statusCode}" if res.statusCode != 200
      return promise.fulfill data?.end_time

    promise

  # Schedule next polling round
  schedule_next_poll = (end_time) ->
    et = new Date("#{end_time} 00:00:00 UTC") if end_time?
    # Keep going until end time is at least "tomorrow" so we get "todays" bugs
    if et? and et.getTime() < new Date(new Date().getTime() + 24 * HOUR)
      1 * SECOND
    # No end time (all bugs fetched) or end_time is in future -> run again
    # in configured interval
    else
      winston.info "Next poll in #{settings.update_interval} hours"
      settings.update_interval * HOUR

  poll_bugs = ->
    winston.info "Start fetching bugs"

    get_start_date()
      .then(fetch_bugs)
      .then(push_bugs)
      .then(schedule_next_poll)
      .then (interval) ->
        setTimeout poll_bugs, interval
      .fail (err) ->
        winston.error "Error when polling bugs, trying again in 5 minutes.", err
        setTimeout poll_bugs, 5 * MINUTE

  poll_bugs()

# Bugzilla dates do not contain timezone information so they're either in the
# server default timezone (if not authenticated) or in the timezone defined
# in the user preferences of the account being used.
console.log '\u001b[34m' +
  "This service expects dates from Bugzilla to be in UTC. If this is not the\n" +
  "default for the Bugzilla server in question, you should create a user\n" +
  "account, set it's timezone to UTC, and then set the login info to bzAuth\n" +
  "in config.json\n" +
  '\u001b[0m'

settings = JSON.parse fs.readFileSync "config.json", "utf-8"
settings.bugzilla.query_uri = util.format settings.bugzilla.query_uri, encodeURIComponent(settings.bugzilla.columns.join(','))
launch_daemon settings
