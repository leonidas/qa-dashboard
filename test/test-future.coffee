# Unit Tests for Future

require.paths.unshift __dirname + '/../node_modules'
require.paths.push(__dirname + "/../server")

testCase = require('nodeunit').testCase

exports["future module can be imported"] = (test) ->
    test.expect(2)

    future = require('future')
    test.ok future?, "module was undefined or null"

    Future = future.Future
    test.ok Future?, "Future class was not found in module"

    test.done()


#exports["value is propagated from future"] = (test) ->
