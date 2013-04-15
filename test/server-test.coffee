request = require('supertest')
should  = require('chai').Should()
mongodb = require('mongodb')

TEST_SETTINGS =
  db:
    host: 'localhost'
    port: 27017
  app:
    root: __dirname + '/..'
  'qa-reports':
    url:  'http://localhost:3000'
  auth:
    method: 'dummy'

describe 'QA Dashboard', ->
  app = null
  db  = null

  before (cb) ->
    dbs = new mongodb.Server TEST_SETTINGS.db.host, TEST_SETTINGS.db.port
    new mongodb.Db("qadash-test", dbs, w: 1).open (err, dbo) ->
      db  = dbo
      app = require('app').create_app TEST_SETTINGS, db
      cb()

  after (cb) ->
    db.close()
    cb()

  it 'should return an index page', (cb) ->
    request(app)
      .get('/')
      .expect(200)
      .expect(/<title>Meego QA Dashboard<\/title>/)
      .end cb
