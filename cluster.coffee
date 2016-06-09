cluster = require 'cluster'

if not cluster.isMaster then return require './app'

util = require 'util'
express = require 'express'
gitpull = require 'git-pull'
gitsha = require 'gitsha'
require 'colors'
pkg = require __dirname + '/package.json'
util.log "#{pkg.name} (#{pkg.version}) - #{pkg.description}".green.bold

numCPUs = require('os').cpus().length
forkCount = 0
forkTokenCount = numCPUs
intervalObject = setInterval (-> forkTokenCount++ unless forkTokenCount >= numCPUs * 2), 1200000

cluster.fork() for i in [0...numCPUs]

cluster.on 'fork', -> forkCount++

cluster.on 'exit', (worker, code, signal) ->
	forkCount--
	if worker.exitedAfterDisconnect
		util.log "Worker disconnected: pid: #{worker.process.pid}, code #{code}, signal #{signal}"
	else
		util.log "Worker died: pid: #{worker.process.pid}, code #{code}, signal #{signal}".red
		if forkTokenCount > 0
			forkTokenCount--
			util.log "Forking again. Tokens left: #{forkTokenCount}".yellow
			setTimeout (-> cluster.fork()), 1000
		else
			util.log "Too many crashes. Giving up.".red
			util.log "Forks left: #{forkCount}".yellow
			if not forkCount then process.exit(2)

controller = express.createServer()

controller.post '/update', (req, res) ->
	gitsha '.', (error, output) ->
		if error then return util.error output
		initChecksum = output
		util.log "gitpull'ing...".cyan
		util.log "initial checksum: #{output}"
		gitpull '.', (error, output) ->
			if error then return util.error output
			util.log "gitpull success"
			gitsha '.', (error, output) ->
				if error then return util.error output
				util.log "final checksum: #{output}"
				if output is initChecksum
					return util.log "No updates found!".red
				util.log "Update found, restarting workers!".green
				worker.disconnect() for id, worker of cluster.workers
				cluster.fork() for i in [0...numCPUs]
	res.send 'roger'

controller.get '*', (req, res) ->
	res.send '404 Not Found', 404

controller.post '*', (req, res) ->
	res.send '404 Not Found', 404

controller.listen process.env.CONTROLLER_PORT or 0, ->
	addr = controller.address().address
	port = controller.address().port
	util.log "[#{process.pid}] Controller: http://#{addr}:#{port}/"

exit = (signal) ->
	util.log "[#{process.pid}] Caught #{signal}"
	controller.close()
	util.log "[#{process.pid}] Closing server connections."
	cluster.disconnect()
	util.log "[#{process.pid}] Disconnecting child processes."
	clearInterval intervalObject

process.on 'SIGINT', ->
	exit('SIGINT')
	setTimeout((-> process.exit(128+2)), 1000)

process.on 'SIGTERM', ->
	exit('SIGTERM')
	setTimeout((-> process.exit(128+15)), 500)
