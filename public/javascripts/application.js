// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

( function( $ ) {

	$(document).on('click', '.toggle-nav', function(){
		var navigation = $('.navigation');

		if( navigation.hasClass('nav-open')) {
			navigation.removeClass('nav-open');
		} else {
			navigation.addClass('nav-open');
		}

	});

	$(document).on('click', '.versions tbody tr td', function() {
		console.log('clicked');
		var newsLink = $(this).parent().find('a:first').attr('href');
		window.location.href = newsLink;
	});


} )( jQuery );