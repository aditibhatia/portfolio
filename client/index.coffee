$ ->
	$.getJSON "/projects.json", (data) ->
		console.log data
		for project in data.projects
			item = $('<div>').addClass('item col-xs-12 col-sm-4 col-md-3 col-lg-2')
			item.append $('<img>').attr 'src', project.thumbnail
			$('.row.content').append item

