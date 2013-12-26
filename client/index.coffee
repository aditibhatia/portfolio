msnry = false

$ ->

	$.getJSON "/projects.json", (data) ->
		console.log data

		$projects = $('#projects')
		$projects.empty()

		for project in data.projects
			$item = $('<div>').addClass('project all').addClass(project.type)
			$img = $('<img>').attr('src', project.thumbnail).addClass 'img-rounded img-responsive'
			$item.append $img
			$projects.append $item

	$('.filterButton').click (e) ->
		$button = $(e.target)
		filter = $button.attr('x-filter')
		$('.project').hide()
		$('.project').filter(".#{filter}").fadeIn(600)
