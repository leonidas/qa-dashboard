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

auth = ""
init_ldap_shellauth = (settings) ->
    auth = settings.auth

ldap_shellauth = (username, password) -> (callback) ->
    # escape special characters in input
    username = username.replace(/([^\w\d])/g, "\\$1")
    password = password.replace(/([^\w\d])/g, "\\$1")

    # construct ldapsearch command
    fulldn = "uid=" + username + "," + auth.ldap.dn_base
    ldapcmd = "ldapsearch -xLLL -H " + auth.ldap.uri + " -b " + fulldn + " -D " + fulldn + " -w " + password + " " + auth.ldap.filters + " dn"

    exec ldapcmd, (error,stdout,stderr) ->
        error = error?.message
        callback? error, (!error? && stdout != "")

exports.init_ldap_shellauth = init_ldap_shellauth
exports.ldap_shellauth      = ldap_shellauth
