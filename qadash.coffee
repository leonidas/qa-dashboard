#
# This file is part of Meego-QA-Dashboard
#
# Copyright (C) 2011 Nokia Corporation and/or its subsidiary(-ies).
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# version 2.1 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA
#
APPROOT       = __dirname
SETTINGS_FILE = "#{APPROOT}/settings.json"

fs      = require('fs')
mongodb = require('mongodb')
http    = require('http')

settings          = JSON.parse fs.readFileSync(SETTINGS_FILE)
settings.app.root = APPROOT

env  = process.env.NODE_ENV || 'development'
port = process.env.PORT || settings.server.port

dbs = new mongodb.Server settings.db.host, settings.db.port
new mongodb.Db("qadash-#{env}", dbs, w: 1).open (err, db) ->
  app    = require('app').create_app settings, db
  server = http.createServer app

  console.log "Server listening on port #{port}"
  server.listen(port)
