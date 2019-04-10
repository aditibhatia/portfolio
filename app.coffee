process.env.NODE_ENV ?= 'development'
debug = process.env.NODE_ENV isnt 'production'

chalk = require 'chalk'
express = require 'express'
pagedown = require 'pagedown'
request = require 'request'
cache = require 'memory-cache'
fs = require 'fs'
stylus = require 'stylus'
favicon = require 'serve-favicon'
morgan = require 'morgan'
moment = require 'moment'
connectCoffeeScript = require 'connect-coffee-script'

HOME_URL = "https://raw.github.com/aditibhatia/portfolio-content/master/home.md"
ABOUT_URL = "https://raw.github.com/aditibhatia/portfolio-content/master/about.md"
CONTACT_URL = "https://raw.github.com/aditibhatia/portfolio-content/master/contact.md"

logger =
	log: (message) => console.log moment().format('YYYY-MM-DD HH:mm:ss ZZ') + " " + message
	error: (message) => console.error chalk.red moment().format('YYYY-MM-DD HH:mm:ss ZZ') + " " + message

version = "unknown"
gitsha = require 'gitsha'
gitsha __dirname, (error, output) ->
	if not error then version = output
	logger.log "[#{process.pid}] env: #{chalk.magenta process.env.NODE_ENV}, version: #{chalk.magenta version}"

app = express()
app.use favicon __dirname + '/public/img/icon.png'
app.use morgan(if debug then 'dev' else 'short')
app.use connectCoffeeScript
	src: __dirname + '/client'
	dest: __dirname + '/public'
	bare: true
app.use stylus.middleware
	src: __dirname + '/views'
	dest: __dirname + '/public'
app.use express.static __dirname + '/public',
	immutable: !debug
	maxAge: if debug then 0 else '1y'

app.set 'trust proxy', 'loopback'
app.locals.pretty = debug

app.get '/', (req, res) ->
	res.setHeader 'Cache-Control', 'public, max-age=' + 86400 # seconds in one day
	Promise
	.all [getHtml(HOME_URL), getHtml(ABOUT_URL), getHtml(CONTACT_URL)]
	.then (values) ->
		res.render 'index.pug',
			version: version
			devMode: debug
			content:
				home: values[0]
				about: values[1]
				contact: values[2]
	.catch (err) ->
		logger.error "Unable to render: #{err}"

getHtml = (url) ->
	new Promise (resolve, reject) ->
		if cache.get url
			return resolve cache.get url

		logger.log "Cache miss. Fetching: #{url}"
		request url, (err, resp, body) ->
			if not err and resp.statusCode is 200
				safeConverter = pagedown.getSanitizingConverter()
				html = safeConverter.makeHtml body
				logger.log "status: #{resp.statusCode}, length: #{resp.headers['content-length']}, #{url}"
				cache.put url, html, 86400000
			else
				html = '<em>An unexpected error has occured.</em>'
				logger.error "HTTP #{resp.statusCode}, Error: #{err}"
				cache.put url, html, 10000
			resolve(html)

server = app.listen process.env.PORT or 0, ->
	serverInfo = server.address()
	if serverInfo.family is 'IPv6' then serverInfo.address = "[#{serverInfo.address}]"
	logger.log "[#{process.pid}] http://#{serverInfo.address}:#{serverInfo.port}/"

process.on 'SIGINT', (signal) ->
	logger.log "[#{process.pid}] Caught signal: #{signal}; closing server connections."
	server.close process.exit

module.exports = app
