process.env.NODE_ENV ?= 'dev'
debug = process.env.NODE_ENV isnt 'production'

util = require 'util'
express = require 'express'
fs = require 'fs'
jade = require 'jade'
stylus = require 'stylus'
coffeescript = require 'connect-coffee-script'
require 'colors'

version = "unknown"
gitsha = require 'gitsha'
gitsha __dirname, (error, output) ->
	if not error then version = output
	util.log "[#{process.pid}] env: #{process.env.NODE_ENV.magenta}, version: #{output.magenta}"

app = express.createServer()

app.set 'views', __dirname + '/views'
app.set 'view options', layout: false

accessLogStream = fs.createWriteStream './access.log',
	flags: 'a'
	encoding: 'utf8'
	mode: 0o0644

app.use express.logger
	format: if debug then 'dev' else 'default'
	stream: accessLogStream

app.configure 'production', ->
	app.use (req, res, next) ->
		if not res.getHeader 'Cache-Control'
			maxAge = 86400 # seconds in one day
			res.setHeader 'Cache-Control', 'public, max-age=' + maxAge
		next()

app.configure ->
	app.use express.responseTime()
	app.use coffeescript
		src: __dirname + '/client'
		dest: __dirname + '/public'
		bare: true
	app.use stylus.middleware
		src: __dirname + '/views'
		dest: __dirname + '/public'
	app.use express.static __dirname + '/public'

app.get '/', (req, res) ->
	res.render 'index.jade',
		version: version
		devMode: debug

app.listen process.env.PORT or 0, ->
	addr = app.address().address
	port = app.address().port
	util.log "[#{process.pid}] http://#{addr}:#{port}/"

module.exports = app

