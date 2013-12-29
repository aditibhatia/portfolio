API_KEY = "AIzaSyBqmMVDizmBFhmiQwEblDkpEu-4nQAMHNY"
TABLE = "1aj96ZD5RpRDWKlO4r2rmaWfabTK7efaUG4zrdMA"
QUERY = encodeURIComponent "select * from #{TABLE}"
TABLE_URL = "https://www.googleapis.com/fusiontables/v1/query?key=#{API_KEY}&sql=#{QUERY}"

ABOUT_URL = "https://raw.github.com/aditibhatia/portfolio-content/master/about.md"
CONTACT_URL = "https://raw.github.com/aditibhatia/portfolio-content/master/contact.md"

$ ->
	$.fancybox.showLoading()

$ ->
	$(document).on 'click', 'a', (e) ->
		if e.target.host isnt document.location.host
			e.target.target = '_blank'

$ ->

	$('.navSection').not('#projects').hide()
	$('.btnTop').hide()

	$.getJSON '/md/' + encodeURIComponent(ABOUT_URL), (data) ->
		console.log data
		$('#about').html data.html

	$.getJSON '/md/' + encodeURIComponent(CONTACT_URL), (data) ->
		console.log data
		$('#contact').html data.html

	$.getJSON TABLE_URL, (data) ->

		$.fancybox.hideLoading()

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
			$img = $('<img>').attr('src', thumbnails[0]).addClass 'img-rounded img-responsive'
			$project.append $img
			$img.hide()

			$img.load (e) ->
				$(this).parent().appendTo $projects
				$(this).fadeIn()
				checkBtnTopOffset()

			$project.attr 'title', project.name

			fancyBoxOptions = {}

			switch project.type

				when 'design', 'art'
					$project.attr 'href', project.image or thumbnails[0]

				when 'web'
					$project.attr 'href', project.externalLink
					$project.addClass 'fancybox.iframe'
					fancyBoxOptions =
						width: '100%'

				when 'video'
					$project.attr 'href', "http://www.youtube.com/embed/#{project.video}?autoplay=1"
					$project.addClass 'fancybox.iframe'

			if project.comment
				fancyBoxOptions.afterLoad = ((comment) ->
					->
						$comment = $('<div>').addClass('comment').html(comment)
						this.outer.append $comment
						true
				)(project.comment)

			$project.fancybox fancyBoxOptions

	$('.filterButton').click (e) ->
		$button = $(e.target)
		filter = $button.attr('x-filter')
		$('.project').hide()
		$('.project').filter(".#{filter}").fadeIn(600)
		$('.filterButton').removeClass 'active'
		$button.addClass 'active'
		checkBtnTopOffset()

	$('.navButton').click (e) ->
		$button = $(e.target)
		section = $button.attr('x-section')
		$('.navButton').removeClass 'active'
		$button.addClass 'active'
		$('.navSection').hide()
		$("##{section}").fadeIn()
		checkBtnTopOffset()

	$('.btnTop').click ->
		$(document).scrollTop 0

	checkBtnTopOffset = ->
		if $(window).height() > $('.footer').offset().top
			$('.btnTop').hide()
		else
			$('.btnTop').show()

