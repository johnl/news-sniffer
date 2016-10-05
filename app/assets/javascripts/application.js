( function( $ ) {

	$(document).on('click', '.toggle-nav', function(){
		var navigation = $('.navigation');

		if( navigation.hasClass('nav-open')) {
			navigation.removeClass('nav-open');
		} else {
			navigation.addClass('nav-open');
		}

	});

	$(document).on('click', '.versions tbody tr', function() {
		console.log('clicked');
		var newsLink = $(this).find('a:first').attr('href');
		window.location.href = newsLink;
	});


} )( jQuery );