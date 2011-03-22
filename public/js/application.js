less.env = "development";
//less.watch();

initialize_qa_dashboard = function() {

	jQuery.event.add(window, "load", equals);
	jQuery.event.add(window, "resize", equals);
	
	
	/* Widget bar actions */
	
	var newWidget;
			
	$('#widget_bar').hide();
	$('#add_widgets_btn').click(function() {
			$('#widget_bar').slideDown(300);
			return false;
	});
	$('#close_widget_bar').click(function() {
			$('#widget_bar').slideUp(300);
			return false;
	});
	
	/* Let's make the columns sortable */
	
	$('#left_column, #sidebar').sortable({
		'items' : '.widget', 
		'handle' : '.widget_move', 
		'opacity' : 0.9,
		'revert' : false,
		'start' : function(event, ui) {
			$('.ui-widget-sortable-placeholder').height($(ui.item).height());
			equals();
		},
		'stop' : function(event, ui) {
			$(ui.item).removeClass('move_mode');
			equals();
		},
		'over' : function(event, ui) {
			//$('.ui-widget-sortable-placeholder').height(widgetData[$(ui.item).data('widgetType')][$(this).attr('id')]['height']);
			$(this).sortable('refresh');
			equals();
		},
		'out' : function(event, ui) {
			equals();
		},
		'receive' : function(event, ui) {
                        $(this).find(".ui-draggable").remove();
			if(newWidget != null && newWidget.type != 'undefined') {
                            $(this).append(newWidget);
                            initWidgetEvents(newWidget);
                        }
//				newWidget.unwrap();
//				newWidget = null;
			equals();
		},
		'placeholder' : 'ui-widget-sortable-placeholder',
		'tolerance' : 'pointer'
	});

	
	/* Connect the sortable columns with each other */
	
	$('#left_column').sortable('option', 'connectWith', '#sidebar');
	$('#sidebar').sortable('option', 'connectWith', '#left_column');
	
	/* New widgets to be dragged'n'dropped */
	$('.widget_info').draggable({
		'helper' : function() {
			var helperSource = $(this).children('img');
			var helper = helperSource.clone();
			helper.css('width', helperSource.css('width'));
			helper.css('height', helperSource.css('height'));
			return helper;
		},
		'scroll' : false,
		'revert' : 'invalid',
		'revertDuration' : 100,
		'cursorAt' : { 'top' : 32, 'left' : 32 },
		'connectToSortable' : '#left_column, #sidebar',
		'scope' : 'widget',
		'start' : function(event, ui) {
			//newWidget = createWidget($(this).attr('id'));
                        var cls = $(this).data("widgetClass");
                        var dom = new cls().init_new(function(){
                            equals();
                        });
                        newWidget = dom;
		}
	});
	
	/* Columns to receive new widgets */
	
	$('#left_column, #sidebar').droppable({
		'accept' : '.widget_info',
		'scope' : 'widget',
		'greedy' : true,
		'tolerance' : 'pointer',
		'over' : function(event, ui) {
			//$('.ui-widget-sortable-placeholder').height(widgetData[newWidget.data('widgetType')][$(this).attr('id')]['height']);
			$('#left_column, #sidebar').sortable('refresh');
			equals();
		},
		'drop' : function(event, ui) {
			$(ui.draggable).children().remove();
                        //$(this).find(".placeholder").remove();
			//$(ui.draggable).append(newWidget);
                        //initWidgetEvents(newWidget);
			equals();
		}
	});
	
	
	/*selection boxes */
	$('.visualization_type_selection a').click(function(){
		var h = this.name;
		$(this).parent().addClass('active').siblings().removeClass('active');
	}); 
	
	
	/* Populate input text fields with example text */
	$('.fill_with_example').example(function() {
	return $(this).attr('title');
	}, {className: 'example'});

};

function equals() {
	$('#page_content').equalHeights();	
};


var createWidget = function(type) {
	// Initializing the widget
	var widget = $('#hidden_widget_container .' + type).clone(true);
	widget.data('widgetType', type);
	widget.find('.widget_edit_content').hide();
	widget.show();
	
	// Good to go!
	return widget;
}

var initWidgetEvents = function(widget) {
    // Binding the events
    widget.find('.widget_edit').bind('click', function() {
            widget.find('.widget_content').toggle();
            widget.find('.widget_edit_content').toggle();
            $('.widget_edit_columns_container').equalHeights();
            $('.shiftcb').shiftcheckbox();
            equals();
            $(this).toggleClass('active');
            return false;
    });
    widget.find('.widget_move').bind('mouseover', function() {
            $(this).addClass('move_mode');
    });
    widget.find('.widget_move').bind('mouseout', function() {
            $(this).removeClass('move_mode');
    });
    widget.find('.widget_close').bind('click', function() {
            widget.slideUp(200, function(){
                widget.remove();
                });
            return false;
    });
	
}

function getHeight(widget, column) {

		
}





