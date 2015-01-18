API_KEY = "AIzaSyBqmMVDizmBFhmiQwEblDkpEu-4nQAMHNY"
TABLE = "1aj96ZD5RpRDWKlO4r2rmaWfabTK7efaUG4zrdMA"
QUERY = encodeURIComponent "select * from #{TABLE}"
TABLE_URL = "https://www.googleapis.com/fusiontables/v1/query?key=#{API_KEY}&sql=#{QUERY}"

$ ->
	$(document).on 'click', 'a', (e) ->
		if e.target.host isnt document.location.host
			e.target.target = '_blank'
		true

$ ->

	$('.navSection').not('#home').hide()

	$('.btnTop').hide()

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
			thumbnails = project.thumbnail.split ' '

			$project = $('<a>').addClass('project all').addClass(project.type)
			$project.data
				id: project.id

			if thumbnails.length > 1
				$carousel = $('<div>').addClass('carousel slide')
				$carouselInner = $('<div>').addClass('carousel-inner')
				$carousel.append $carouselInner
				for thumbnail in thumbnails
					$img = $('<img>').attr('src', thumbnail).addClass 'img-rounded img-responsive'
					$item = $('<div>').addClass('item')
					$carouselInner.append $item.append $img

				$carouselInner.children().first().addClass 'active'
				$projects.append $project.append $carousel
				$carousel.carousel
					interval: 3000

			else
				$img = $('<img>').attr('src', thumbnails[0]).addClass 'img-rounded img-responsive'
				$project.append $img

				$img.hide()

				$img.load (e) ->
					$(this).parent().appendTo $projects
					$(this).fadeIn()
					checkBtnTopOffset()
					layout()

			$project.attr 'title', project.name

			fancyBoxOptions =
				title: project.name
				helpers:
					title:
						type: 'outside'
						position: 'top'

			if project.comment
				fancyBoxOptions.afterLoad = ((comment) ->
					->
						$comment = $('<div>').addClass('comment').html(comment)
						this.outer.append $comment
						true
				)(project.comment)

			switch project.type

				when 'design', 'art'
					images = project.image.split ' '
					if images.length > 1
						fancyBoxOptions.helpers ?= {}
						fancyBoxOptions.helpers.thumbs =
							width: 100
							height: 100
						$project.click ((images, fancyBoxOptions) ->
							(e) ->
								$.fancybox.open images, fancyBoxOptions
								e.preventDefault()
						)(images, fancyBoxOptions)
					else
						$project.attr 'href', images.shift()
						$project.fancybox fancyBoxOptions

				when 'web'
					$project.attr 'href', project.externalLink
					$project.addClass 'fancybox.iframe'
					fancyBoxOptions.width = '100%'
					$project.fancybox fancyBoxOptions

				when 'video'
					$project.attr 'href', "http://www.youtube.com/embed/#{project.video}?autoplay=1"
					$project.addClass 'fancybox.iframe'
					$project.fancybox fancyBoxOptions

		checkBtnTopOffset()
		true

	$('.filterButton').click (e) ->
		$button = $(this)
		filter = $button.data().filter
		layout(filter)
		$('.filterButton').removeClass 'active'
		$button.addClass 'active'
		checkBtnTopOffset()
		true

	$('.navButton').click (e) ->
		$button = $(this)
		section = $button.data().section
		$section = $(".navSection##{section}")

		$('.navSection').not($section).slideUp(checkBtnTopOffset)
		$section.slideDown(checkBtnTopOffset)

		$('.navButton').not($button).removeClass('active')
		$("#nav a[data-section='#{section}']").addClass('active')

		if section is 'portfolio'
			layout()

		true

	$('.btnTop').click ->
		$(document).scrollTop 0
		true

	checkBtnTopOffset = ->
		if $(window).height() > $('.footer').offset().top
			$('.btnTop').hide()
		else
			$('.btnTop').show()

	$gridSizer = $('.gridSizer')
	currentColumns = Math.floor(window.innerWidth / $gridSizer.width())
	currentWidth = window.innerWidth
	$(window).resize (e) ->
		return if window.innerWidth is currentWidth
		currentWidth = window.innerWidth
		columns = Math.floor(window.innerWidth / $gridSizer.width())
		if currentColumns isnt columns
			currentColumns = columns
			layout()

	$projects = $('#projects')
	currentFilter = 'all'
	layout = (filter = currentFilter) ->

		console.log currentColumns, currentFilter
		currentFilter = filter

		$projectArr = $('.project').detach()
		$projectsToDisplay = $projectArr.filter(".#{filter}").sort (a, b) -> +$(a).data().id > +$(b).data().id
		$('#hidden').append $projectArr.not($projectsToDisplay)
		$('#projects').empty()
		i = 0
		columns = []
		while i < currentColumns
			$col = $('<div>').addClass('col-xs-12 col-sm-6 col-md-4 col-lg-3')
			$('#projects').append $col
			columns[i++] = $col

		$projectsToDisplay.each (index, $project) ->
			$shortestColumn = columns[0]
			for $column in columns
				if $shortestColumn.height() > $column.height()
					$shortestColumn = $column
			$shortestColumn.append $project

		checkBtnTopOffset()

		true

	true
