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
fs   = require('fs')
exec = require('child_process').exec

LDAP_SERVER_FILE = "/ldap_server.json"


ldap_server = ""
exports.init_ldap_shellauth = (basedir) ->
    ldap_server = JSON.parse fs.readFileSync(basedir + LDAP_SERVER_FILE)

exports.ldap_shellauth = (username, password) -> (callback) ->

    fulldn = "uid=" + username + "," + ldap_server.dn_base #full unique DN

    ldapcmd = "ldapsearch -xLLL -H " + ldap_server.ldapuri + " -b " + fulldn + " -D " + fulldn + " -w " + password + " " + ldap_server.filters + " dn" 
    #console.log(ldapcmd)
    exec ldapcmd, (error,stdout,stderr) ->
        #console.log("stdout: " + stdout)
        #console.log("stderr: " + stderr)
        #console.log(error)
        callback? error, (error == null && stdout != "")






