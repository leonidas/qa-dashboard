
This readme is work in progress.

*NOTICE:* If you have set up QA Dashboard back in the day and are now considering upgrading, it is worth to notice that current version is *not* compatible with the previous one. You should either keep your current installation or set up from scratch. Notice also that old QA Reports installations are *not* compatible with new QA Dashboard.

## Development environment

* Install Node.js:

```bash
$ git clone git://github.com/creationix/nvm.git ~/nvm
$ . ~/nvm/nvm.sh
$ echo ". ~/nvm/nvm.sh" >> ~/.bashrc
$ nvm install v0.10
$ nvm alias default 0.10
```

* Clone and setup:

```bash
$ git clone git@github.com:leonidas/qa-dashboard.git
$ cd qa-dashboard
$ npm install
$ npm run bower
```

* Run: `npm run dev-start` in one shell, and `npm run watch` in other.

* Login at [http://localhost:3030/](http://localhost:3030/)
  * Username: `guest`
  * Password: `guest`


### Get development data

QA Dashboard does not currently have any data to put to database for development purposes. One option to get some is to use QA Reports exporter in `export/qa-reports`. It will fetch reports from [http://qa-reports.qa.leonidasoy.fi](http://qa-reports.qa.leonidasoy.fi) and send them to your local QA Dashboard.

* Get a token for the guest user by opening [http://localhost:3030/user/token](http://localhost:3030/user/token)
* Put the token in `export/qa-reports/config.json`
* Install and run:

```bash
$ cd export/qa-reports
$ npm install
$ npm start
```

* Hit `Ctrl-C` once you have enough reports. The script fetches reports in batches of 20 and it starts from the oldest report found.
