process.env.NODE_ENV ?= 'dev'
debug = process.env.NODE_ENV isnt 'production'

util = require 'util'
express = require 'express'
pagedown = require 'pagedown'
request = require 'request'
Promise = require 'promise'
cache = require 'memory-cache'
fs = require 'fs'
jade = require 'jade'
stylus = require 'stylus'
coffeescript = require 'connect-coffee-script'
require 'colors'

HOME_URL = "https://raw.github.com/aditibhatia/portfolio-content/master/home.md"
ABOUT_URL = "https://raw.github.com/aditibhatia/portfolio-content/master/about.md"
CONTACT_URL = "https://raw.github.com/aditibhatia/portfolio-content/master/contact.md"

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
	promise = Promise.all getHtml(HOME_URL), getHtml(ABOUT_URL), getHtml(CONTACT_URL)
	promise.then (values) ->
		res.render 'index.jade',
			version: version
			devMode: debug
			analyticsId: process.env.ANALYTICS_ID or 'UA-46698987-2'
			content:
				home: values[0]
				about: values[1]
				contact: values[2]

getHtml = (url) ->
	promise = Promise (resolve, reject) ->
		if cache.get url
			return resolve cache.get url

		util.log "Cache miss. Fetching: #{url}"
		request url, (err, resp, body) ->
			if not err and resp.statusCode is 200
				safeConverter = pagedown.getSanitizingConverter()
				html = safeConverter.makeHtml body
				util.log resp.headers['status'] + " - " + resp.headers['etag']
				cache.put url, html, 86400000
			else
				html = '<em>An unexpected error has occured.</em>'
				console.error "HTTP #{resp.statusCode}, Error:", err
				cache.put url, html, 10000
			resolve(html)

app.listen process.env.PORT or 0, ->
	addr = app.address().address
	port = app.address().port
	util.log "[#{process.pid}] http://#{addr}:#{port}/"

exit = (signal) ->
	util.log "[#{process.pid}] Caught #{signal}; closing server connections."
	app.close()

process.on 'SIGINT', ->
	exit('SIGINT')

process.on 'SIGTERM', ->
	exit('SIGTERM')
	setTimeout((-> process.exit(128+15)), 1000)

module.exports = app

