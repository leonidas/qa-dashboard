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

current_user = null

$p = {}

submit_login_form = () ->
    $form = $(this)
    field = (name) -> $form.find("input[name=\"#{name}\"]").val()

    $form.find('.error').hide()

    req =
        username: field "username"
        password: field "password"

    $form.attr 'disabled', 'disabled'

    $.post "/auth/login", req, (data) ->
        $form.removeAttr 'disabled'
        if data.status == "error"
            # show error message
            $form.find('.error').show()
            balance_columns()
        else
            load_dashboard (data) ->
                current_user = data
                init_user_dashboard(data.dashboard)

    return false

submit_user_logout = () ->
    $.post "/auth/logout", (data) ->
        window.location.reload()

    return false

initialize_application = () ->
    load_dashboard (data) ->
        if data.username?
            current_user = data
            # render dashboard
            init_user_dashboard(data.dashboard)
        else
            # show login form
            $p.form_container.show()
            balance_columns()


load_dashboard = (callback) ->
    $.getJSON "/user", (data) ->
        callback? data

init_user_dashboard = (dashboard) ->
    $p.form_container.hide()
    $p.widget_container.show()
    $p.toolbar_container.show()
    balance_columns()

balance_columns = () ->
    $('#page_content').equalHeights()

$ () ->
    $(window).load   balance_columns
    $(window).resize balance_columns

    $p.login_form        = $('.login_form')
    $p.form_container    = $('.form_container')
    $p.widget_container  = $('.widget_container')
    $p.toolbar_container = $('.toolbar_container')

    $p.login_form.appendTo('.form_container')
    $p.login_form.find('form').submit submit_login_form

    $('#logout_btn').click submit_user_logout

    initialize_application()
