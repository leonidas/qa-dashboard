/*
 * Copyright (c) 2011 Arron Bailiss <arron@arronbailiss.com>
 * Based on John Sutherland's <john@sneeu.com> jQuery Checkbox Shift-click Plugin
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */


(function($) {
	$.fn.shiftClick = function() {
		var clickedClass = 'clicked';
		
		var lastSelected;
		var tableRows = $(this);

		this.each(function() {
			$(this).children('td').attr('unselectable', 'on');
			$(this).click(function(ev) {
				if (ev.shiftKey) {
					var last = tableRows.index(lastSelected);
					var first = tableRows.index(this);

					var start = Math.min(first, last);
					var end = Math.max(first, last);

					for (var i = start; i < end; i++) {
						if (tableRows[i].children[0].tagName.toLowerCase() == 'td') {
							tableRows[i].setAttribute('class', clickedClass);
						}
					}
				}
				else {
					if (this.className.search(clickedClass) > -1) {
						this.removeAttribute('class', clickedClass);
					}
					
					lastSelected = this;
				}
			});
		});
	};
})(jQuery);