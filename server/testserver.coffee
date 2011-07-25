# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA
#

TEST_SETTINGS =
    "server":
        "host": "localhost",
        "port": 3130
    "app":
        "root": __dirname + "/.."
    "auth":
        "method": "dummy"

class TestServer
    constructor: () ->
        @settings   = TEST_SETTINGS
        @monmon     = require('monmon')
        @db         = @monmon.monmon.use('qadash').env('test')
        @server_app = require('app').create_app @settings, @db

    start: (callback) ->
        @server_app.listen @settings.server.port, callback

    close: (callback) ->
        @server_app.close()
        callback()

    db_drop: (callback) ->
        @db.dropDatabase().run (err) ->
            throw err if err?
            callback()

    db_closeAll: (callback) ->
        @monmon.closeAll (err, res) ->
            throw err if err?
            callback()

exports.createServer = new TestServer()