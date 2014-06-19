
  // Reload the contents of a frame.
  // subFrameId is the id of the subframe of "contentFrame" to target.
  // If it is left blank, contentFrame itself is reloaded.
  function reloadFrame(subFrameId) {
    if (subFrameId === undefined) {
      if( this.window.opener === null ) { // a popup or not?
        jQuery(top.frames[1]).attr('location', jQuery(top.frames[1]).attr('location'));
      }
      else {
        jQuery(this.window.opener.frames[1]).attr('location', jQuery(this.window.opener.frames[1]).attr('location'));
      }
    }
    else {
      var contentFrame;
      if( this.window.opener === null ) { // a popup or not?
        contentFrame = top.jQuery('iframe#contentFrame');
      }
      else {
        contentFrame = this.window.opener.jQuery('iframe#contentFrame');
      }
      var targetFrameName = 'iframe#' + subFrameId;
      contentFrame.contents().find(targetFrameName).attr('src', contentFrame.contents().find(targetFrameName).attr('src'));
    }
  }

  // Load the contents of a frame.
  // subFrameId is the id of the subframe of "contentFrame" to target.
  // If it is left blank, contentFrame itself is loaded.
  function loadFrame(newLocation, subFrameId) {
    if (subFrameId === undefined) {
      if( this.window.opener === null ) { // a popup or not?
        jQuery(top.frames[1]).attr('location', newLocation);
      }
      else {
        jQuery(this.window.opener.frames[1]).attr('location', newLocation);
      }
    }
    else {
      var contentFrame;
      if( this.window.opener === null ) { // a popup or not?
        contentFrame = top.jQuery('iframe#contentFrame');
      }
      else {
        contentFrame = this.window.opener.jQuery('iframe#contentFrame');
      }
      var targetFrameName = 'iframe#' + subFrameId;
      contentFrame.contents().find(targetFrameName).attr('src', newLocation);
    }
  }

  // Replace the options in a select tag.
  // new_options is an array of arrays or of strings:
  //     [['<empty>',nil],['First',1],['Second',2]]
  // or
  //     ['<empty>', 'First', 'Second']
  // selectId is the id of a select tag to have its options replaced.
  replace_select_options = function(new_options, selectId) {
    var sel = jQuery('#'+selectId);
    jQuery('option', sel).remove();
    new_options.each( function(e) {
      if(jQuery.isArray(e)) {
        jQuery('<option/>').attr('value', e[1]).text(e[0]).appendTo(sel);
      }
      else {
        jQuery('<option/>').attr('value', e).text(e).appendTo(sel);
      }
    });
  };

  // Product Setup: Display ItemPackProduct and FgProduct codes.
  show_item_pack_and_fg = function(item_pack_product_code, fg_product_code) {
    jQuery('#item_pack_product_code').text(item_pack_product_code);
    jQuery('#fg_product_code').text(fg_product_code);
  };

  // Populate a hidden "#re_ordered_list" input with a sequence of id attributes from a "#list_to_re_order" list.
  function reCalculateListSequence() {
    var s = [];
    jQuery('#list_to_re_order').children('li').each(function(i) {
      s[i] = jQuery(this).attr('data_field_id');
    });
    jQuery('#re_ordered_list').attr('value', s.join(','));
  }

  // On document ready...
  jQuery(document).ready(function() {
    // Product Setup: watch variety code select changing.
    // If it changes, the Size Count selection becomes invalid.
    // (Make <empty> the selected option.
    jQuery('#fruit_packing_fg_setup_variety_code').change(function() {
      jQuery('#fruit_packing_fg_setup_size_count_code').prop('selectedIndex',0);
      show_item_pack_and_fg('', '');
    });
    // Product Setup: watch grade code select changing.
    // If it changes, the Size Count selection becomes invalid.
    // (Make <empty> the selected option.
    jQuery('#fruit_packing_fg_setup_grade_code').change(function() {
      jQuery('#fruit_packing_fg_setup_size_count_code').prop('selectedIndex',0);
      show_item_pack_and_fg('', '');
    });

    // Make a re-order list sortable:
    jQuery('#list_to_re_order').sortable({ revert: true, cursor: 'move', stop: function(event, ui) { reCalculateListSequence(); } });
    jQuery('#list_to_re_order').disableSelection();
    // Remove a line item from a re-order list.
    jQuery('.removeReOrderItem').live('click', function() {
      var target   = jQuery(this).parent();
      //var val      = target.attr('data_field_id');
      target.remove();
      reCalculateListSequence();
    });

    // Datepickers
    // ------------------------------------------------------------------------
    // General settings for all DatePickers.
      jQuery.datepicker.setDefaults( {
        showOn: "button",
        buttonImage: "/images/popup_date_selector.png",
        buttonImageOnly: true,
        changeMonth: true,
        changeYear: true,
        dateFormat: 'yy-mm-dd'
      } );

    // Attach to date pickers.
      jQuery('input.datepicker').datepicker();
    // Attach to dateTime pickers.
      jQuery('input.datetimepicker').datetimepicker();
    // Attach to datetime range pickers - FROM.
      jQuery('input.datepicker_from').datetimepicker( {
        onSelect: function( selectedDate ) {
          var from_id = this.id;
          var regex1  = new RegExp("_datefrom");
          var regex2  = new RegExp("_date2from");
          var regex3  = new RegExp("\\.");
          var to_id   = from_id.replace(regex1, '_dateto').replace(regex2, '_date2to').replace(regex3, '\\.');
          jQuery( '#'+to_id ).datepicker( "option", "minDate", selectedDate );
        }
      } );
    // Attach to datetime range pickers - TO.
      jQuery('input.datepicker_to').datetimepicker( {
        numberOfMonths: 3,
        onSelect: function( selectedDate ) {
          var from_id = this.id;
          var regex1  = new RegExp("_dateto");
          var regex2  = new RegExp("_date2to");
          var regex3  = new RegExp("\\.");
          var to_id   = from_id.replace(regex1, '_datefrom').replace(regex2, '_date2from').replace(regex3, '\\.');
          jQuery( '#'+to_id ).datepicker( "option", "maxDate", selectedDate );
        }
      } );
    // ------------------------------------------------------------------------

    // ---
    // Place an observer on every select with "select_observable" class in every form.
    // ---
    //
    // An example:
    // <%= f.select :name, @names, {:prompt => '&lt;empty&gt;'},
    //      :class        => 'select_observable',
    //      'data-url'    => 'http://localhost/controller/action',
    //      'data-params' => 'combo1_id:dom_id_of_combo1,combo2_id:dom_id_of_combo2' %>
    //
    // If combo1's selected value is 12 and combo2's selected value is 999 and this selects value is 101:
    // This will make a GET request to http://localhost/controller/action?id=101&combo1_id=12&combo2_id=999
    // Which will provide the following in action:
    //     params[:id]        #=> 101
    //     params[:combo1_id] #=> 12
    //     params[:combo2_id] #=> 999
    //
    // The action should return javascript.
    // e.g. render :text => "replace_select_options(#{['a','b','c'].to_json}, 'the_dom_id_to_update');", :layout => false
    //
    jQuery('form').on('change', '.select_observable', function(e) {
      var target = jQuery(e.target);
      var url = target.attr('data-url') + '?id=' + target.val();
      var params, mod_url = '';
      if(target.attr('data-params')) {
        params = target.attr('data-params').split(',');
        params.each( function(e,i) {
          mod_url += '&' + e.split(':')[0] + '=' + jQuery('#'+e.split(':')[1]).val();
        });
      }
      // AJAX call to do what needs to be done:
      jQuery.ajax({
        type: 'get',
        url: url + mod_url,
        dataType: "script"
      });
    });

    // On click of link, expand all collapsed elements.
    jQuery('a.expand_all_collapses').on('click', function(e) {
      jQuery('h3:not(.active)').each(function(n,e) { e.click(); });
      return false;
    });

    // On click of link, collapse all expanded elements.
    jQuery('a.collapse_all_collapses').on('click', function(e) {
      jQuery('h3.active').each(function(n,e) { e.click(); });
      return false;
    });
  }); // End of document ready.

  // Prompt with text that can be copied to clipboard.
  function copyToClipboard (heading, text) {
    window.prompt (heading + "To copy to clipboard: press Ctrl+C and then Enter to close this prompt.", text);
  }
  //-----------------------------------------------------
  //This method takes a list of id-text pairs as a list
  //For each item, the following is done:
  //1) The combo's list is cleared:
  //2) An option is added with the text of form:
  //   'Select a value from <combo> to populate this list'
  //3) The background color is set to grey
  //-----------------------------------------------------
  function clear_combos(combos_to_clear_defs)
  {
    for (i = 0; i < combos_to_clear_defs.length; i ++)
    {
      combo = document.getElementById(combos_to_clear_defs[i][0]);

      if (combo !== null)
      {
        combo.innerHTML = "";
        select_text = "select a value from: '" + combos_to_clear_defs[i][1] + "' to populate this list";
        htm = "<option selelected='selected'>" + select_text + "</option>";

        combo.innerHTML = htm; 

        combo.style.backgroundColor = "whiteSmoke";
      }
    }
  }

