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

  cookie = null
  token  = null

  before (cb) ->
    dbs = new mongodb.Server TEST_SETTINGS.db.host, TEST_SETTINGS.db.port
    new mongodb.Db("qadash-test", dbs, w: 1).open (err, dbo) ->
      return cb err if err?

      db  = dbo
      db.dropDatabase (err, done) ->
        return cb err if err?

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

  it 'should allow logging in', (cb) ->
    request(app)
      .post('/auth/login')
      .send({username: 'guest', password: 'guest'})
      .expect(200)
      .end (err, res) ->
        should.not.exist err
        res.headers.should.include.keys 'set-cookie'
        cookie = res.headers['set-cookie']
        cb()

  it 'should return an api token', (cb) ->
    request(app)
      .get('/user/token')
      .set('Cookie', cookie)
      .expect(200)
      .expect('Content-Type', /json/)
      .end (err, res) ->
        should.not.exist err
        res.body.should.include.keys ['status', 'token']
        res.body.status.should.equal 'ok'
        token = res.body.token
        cb()
