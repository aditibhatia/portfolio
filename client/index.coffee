API_KEY = "AIzaSyBqmMVDizmBFhmiQwEblDkpEu-4nQAMHNY"
TABLE = "1aj96ZD5RpRDWKlO4r2rmaWfabTK7efaUG4zrdMA"
QUERY = encodeURIComponent "select * from #{TABLE}"
TABLE_URL = "https://www.googleapis.com/fusiontables/v1/query?key=#{API_KEY}&sql=#{QUERY}"

$ ->
	$.fancybox.showLoading()

$ ->
	$(document).on 'click', 'a', (e) ->
		if e.target.host isnt document.location.host
			e.target.target = '_blank'

$ ->

	$('.navSection').not('#projects').hide()
	$('.btnTop').hide()

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


	$('.filterButton').click (e) ->
		$button = $(e.target)
		filter = $button.attr('x-filter')
		$('.project').hide()
		$('.project').filter(".#{filter}").fadeIn(600)
		$('.filterButton').removeClass 'active'
		$button.addClass 'active'
		checkBtnTopOffset()

	$('.navButton#btnPortfolio').click (e) ->
		$('.navSection').not('#projects').slideUp()
		$('.navButton').not('#btnPortfolio').removeClass('active')
		checkBtnTopOffset()

	$('.navButton').not('#btnPortfolio').click (e) ->
		$button = $(e.target)
		section = $button.attr('x-section')
		$section = $("##{section}")
		if $section.is(":visible")
			$section.slideUp()
			$button.removeClass('active')
		else
			$('.navSection').not('#projects').slideUp()
			$('.navButton').not('#btnPortfolio').removeClass('active')
			$section.slideDown()
			$button.addClass('active')
		checkBtnTopOffset()

	$('.btnTop').click ->
		$(document).scrollTop 0

	checkBtnTopOffset = ->
		if $(window).height() > $('.footer').offset().top
			$('.btnTop').hide()
		else
			$('.btnTop').show()

