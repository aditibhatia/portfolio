window.GoogleAnalyticsObject = 'ga'
window.ga ?= ->
	window.ga.q ?= []
	window.ga.q.push(arguments)
window.ga.l = Date.now()

ga 'create', window.global.analyticsId, 'aditibhatia.com'
ga 'send', 'pageview'

