# QA Reports Export daemon

This "daemon" fetches reports from QA Reports and uploads them to QA Dashboard. It will check the latest updated date of reports from QA Dashboard and use that as begin time. The initial execution does not have such information and will fetch all bugs in batches.

## Configuration

Daemon is configured in `config.json` and has the following options:

* `reports`:
    * `url`: Base URL to QA Reports
    * `basicAuth`: HTTP Basic Authentication settings
    * `proxy`: HTTP proxy server
    * `fetchCount`: How many reports are fetched in a single query? Notice: if you have been performing mass updates or just happen to have large amounts of reports with the exactly same `updated_at` date this number needs to be large enough to include all those reports in one query -- the next query will fetch bugs updated a second later and will thus miss those with the same `updated_at` date
    * `updateInterval`: How often to poll for reports (in hours)
* `dashboard`:
  * `url`: Base URL to QA Dashboard
  * `token`: Authentication token (from `/user/token` URI in QA Dashboard)
  * `basicAuth`: Same as in `reports`
  * `proxy`: Same as in `reports`

## Execute

To execute manually run:

* `npm install`
* `npm start`

## TODO

* Upstart configuration generation, config file symlinking, etc. when deployed.
