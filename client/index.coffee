msnry = false

$ ->

	$.getJSON "/projects.json", (data) ->
		console.log data

		$projects = $('#projects')

		for project in data.projects
			$item = $('<div>').addClass('project').addClass(project.type)
			$img = $('<img>').attr('src', project.thumbnail).addClass 'img-rounded img-responsive'
			$item.append $img
			$projects.append $item
			$img.load ->
				msnry.layout() if msnry

		$projects.masonry
			isFitWidth: true
			columnWidth: '.grid-sizer'
			gutter: 10
			itemSelector: '.project'

		msnry = Masonry.data $projects.get(0)

