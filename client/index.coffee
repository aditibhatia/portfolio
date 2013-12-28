msnry = false

API_KEY = "AIzaSyBqmMVDizmBFhmiQwEblDkpEu-4nQAMHNY"
TABLE = "1aj96ZD5RpRDWKlO4r2rmaWfabTK7efaUG4zrdMA"
QUERY = encodeURIComponent "select * from #{TABLE}"
TABLE_URL = "https://www.googleapis.com/fusiontables/v1/query?key=#{API_KEY}&sql=#{QUERY}"

$ ->

	$.getJSON TABLE_URL, (data) ->
		console.log "Data:", data
		
		numColumns = data.columns.length
		projects = []

		for row in data.rows
			project = {}
			c = 0
			while c < numColumns
				project[data.columns[c]] = row[c] unless not row[c]
				c++
			projects.push project

		console.log "Projects:", projects

		$projects = $('#projects')
		$projects.empty()

		for project in projects
			continue unless project.thumbnail
			$project = $('<a>').addClass('project all').addClass(project.type)
			$img = $('<img>').attr('src', project.thumbnail).addClass 'img-rounded img-responsive'
			$project.append $img
			$img.hide()

			$img.load (e) ->
				$(this).parent().appendTo $projects
				$(this).fadeIn()

			$project.attr 'title', project.name
			$project.attr 'href', project.image or project.externalLink

			$project.fancybox()

	$('.filterButton').click (e) ->
		$button = $(e.target)
		filter = $button.attr('x-filter')
		$('.project').hide()
		$('.project').filter(".#{filter}").fadeIn(600)
