# Bugzilla Export daemon

This "daemon" fetches bug information from Bugzilla and uploads them to QA Dashboard. It will check the latest changed date of bugs from QA Dashboard and use that as "changed from" value when querying. The initial execution does not have such information and will fetch all bugs.

## Configuration

Daemon is configured in `config.json` and has the following options:

* `update_interval`: How often to poll for bugs (in hours)
* `bugzilla`:
    * `url`: Base URL to Bugzilla
    * `query_uri`: URI template to `buglist.cgi`. `%s` is replaced with defined columns to fetch.
    * `columns`: An array of column names from Bugzilla to fetch
    * `basicAuth`: HTTP Basic Authentication settings
    * `bzAuth`: Bugzilla authentication settings. These credentials are passed as query string parameters (supported from Bugzilla 3.6). In order to keep them safe Bugzilla should be accessed over HTTPS
    * `proxy`: HTTP proxy server
* `dashboard`:
  * `url`: Base URL to QA Dashboard
  * `token`: Authentication token (from `/user/token` URI in QA Dashboard)
  * `basicAuth`: Same as in Bugzilla
  * `proxy`: Same as in Bugzilla

## Execute

To execute manually run:

* `npm install`
* `npm start`

## TODO

* Upstart configuration generation, config file symlinking, etc. when deployed.
* Support multiple Bugzilla servers (needs QA Dashboard support first)
* Initial export in batches instead of fetching all bugs at once

