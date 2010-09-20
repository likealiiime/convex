stopService = function(event) {
	var a = event.target;
	if (a.hasClass('working')) return;
	
	var service = a.get('data-service');
	a.set({ html: 'Stopping...' }).addClass('working');
	new Request.JSON({
		url: '/service/' + service + '/stop',
		method: 'POST',
		onSuccess: function() {
			a.removeClass('working');
		}
	}).send();
};

window.addEvent('domready', function() {
	$$('a.stopsService').each(function(a) { a.addEvent('click', stopService); });
});