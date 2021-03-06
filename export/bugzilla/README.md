# Bugzilla Export daemon

This "daemon" fetches bug information from Bugzilla and uploads them to QA Dashboard. It will check the latest changed date of bugs from QA Dashboard and use that as "changed from" value when querying. The initial execution does not have such information and will fetch all bugs.

Fetching from multiple Bugzilla servers is supported. For each server you *must* define a prefix that *must* be the same that is used in QA Reports (see [External Services](https://github.com/leonidas/qa-reports/wiki/External-Services)).

## Configuration

Daemon is configured in `config.json` and has the following options:

* `update_interval`: How often to poll for bugs (in hours)
* `fetch_days`: How many days' bugs to fetch at once? This is really meaningful only for the initial run because `update_interval` is likely less than this anyways. You need to define `start_date` for Bugzilla for this to have effect - if no `start_date` is defined all bugs are fetched on the initial run in single query, but if `start_date` is defined then the bugs are fetched in batches of `fetch_days` days.
* `bugzillas`: Array of Bugzilla configuration objects. Configuration for each object is:
    * `url`: Base URL to Bugzilla
    * `prefix`: The Bugzilla service prefix used in QA Reports. This *must* be the same as in QA Reports for bug linking to work!
    * `query_uri`: URI template to `buglist.cgi`. `%s` is replaced with defined columns to fetch.
    * `show_uri`: URI template to `show_bug.cgi`. `%s` is replaced with bug ID
    * `columns`: An array of column names from Bugzilla to fetch
    * `basicAuth`: HTTP Basic Authentication settings
    * `bzAuth`: Bugzilla authentication settings. These credentials are passed as query string parameters (supported from Bugzilla 3.6). In order to keep them safe Bugzilla should be accessed over HTTPS
    * `proxy`: HTTP proxy server
    * `start_date`: From which date (dddd-mm-yy) onwards to fetch bugs. Good candidate is to get the reported date of bug #1, most likely that is the oldest date in Bugzilla. By setting this and `fetch_days` the initial run will be less stressful on the Bugzilla server (consider a server with 100k bugs).
* `dashboard`:
  * `url`: Base URL to QA Dashboard
  * `token`: Authentication token (from `/user/token` URI in QA Dashboard)
  * `basicAuth`: Same as in `bugzilla`
  * `proxy`: Same as in `bugzilla`

## Execute

To execute manually run:

* `npm install`
* `npm start`

## TODO

* Upstart configuration generation, config file symlinking, etc. when deployed.
