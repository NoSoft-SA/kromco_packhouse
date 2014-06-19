// Utilities for jqGrid usage

  // On success of AJAX call, load results into dialog.
  function dialogLoadSuccessHandler(data, textStatus, jqXHR) {
    jQuery('#dialog-modal').html(data);
  }
  // On failure of AJAX call, show an alert.
  function errorHandler(jqXHR, textStatus, errorThrown) {
    alert("Something went wrong: " + textStatus + ": " + errorThrown);
  }

// Simple change of grouping column in a grid.
var jq_grid_select_grouping = function(grid_id, group_fields) {
  var opts;
  var already_grouped = jQuery("#"+grid_id).jqGrid('getGridParam', 'groupingView').groupField;
	if( jQuery("#"+grid_id).jqGrid('getGridParam', 'grouping') === false) {
		already_grouped = [];
	}
  jQuery.each(already_grouped, function(index, value) {
    opts += '<option selected="selected">'+value+'</option>';
  });
  jQuery.each(group_fields, function(index, value) {
		if( already_grouped.indexOf(value) == -1) {
			opts += '<option>'+value+'</option>';
		}
  });

  var dlg = jQuery('<div id="changeGroupColDlg">' +
			'Group by one or more columns:<br /> <select id="changeGroupCol" multiple="multiple" class="multiselect" style="width:420px;">'+
      opts+
      '</select></div>');

  dlg.dialog({title: 'Select grouping column',
    modal: true,
		width: 450,
    buttons: { "Ok": function() { 
      var choice = jQuery('#changeGroupCol').val();
      var do_remove = jQuery('#remove_grp').attr('checked') !== undefined;
      if(choice === null) {
        jQuery("#"+grid_id).jqGrid('groupingRemove',true);
      }
      else {
        jQuery("#"+grid_id).jqGrid('groupingGroupBy', choice);
      }
  jQuery(this).dialog("close");
  jQuery('#changeGroupColDlg').remove();
    },
    "Cancel": function() {jQuery(this).dialog("close");
      jQuery('#changeGroupColDlg').remove();
    }}
  });
	jQuery('#changeGroupCol').multiselect();
};


// For a Multiselect grid, Toggle all checkboxes in the grid.
var checkJqGridBoxes = function(e, str) 
{
  var checkstate = jQuery(e.target).prop('checked');
  var mygrid     = jQuery('#' + str);
  jQuery('#' + str + '_frozen [aria-describedby="' + str + '_cm"] > input').prop('checked', checkstate);
  var currIds    = mygrid.jqGrid('getDataIDs');
  var setstate   = checkstate ? 1 : 0;
  for (i = 0, selCount = currIds.length; i < selCount; i++) {
    mygrid.jqGrid('setCell', currIds[i], 'cm', setstate, '', '', false);
  }
  jQuery('#' + str +' tbody tr').toggleClass('grid_checked_row', checkstate);
  jQuery('#' + str +'_frozen tbody tr').toggleClass('grid_checked_row', checkstate);
  //e = e||event;
  //e.stopPropagation? e.stopPropagation() : e.cancelBubble = true;
  e.stopPropagation();
};

// Show the animated gif in grid cell when loading a popup link
// from the anchor in the cell.
function show_action_image_in_grid(clicked_cell)
{
  jQuery(clicked_cell).next().show(); 
}

// Setup grid print capability.  Add print button to navigation bar and bind to click.
function setPrintGrid(gid,pid,pgTitle){
  // print button title.
  var btnTitle = 'Print Grid';

  // setup print button in the grid bottom navigation bar.
  jQuery('#'+gid).jqGrid('navSeparatorAdd', '#'+pid, { sepclass : "ui-separator" });
  jQuery('#'+gid).jqGrid('navButtonAdd', '#'+pid, {
    caption:       '',
    title:         btnTitle,
    position:      'last',
    buttonicon:    'ui-icon-print',
    onClickButton: function() { PrintGrid(); }
  });

  // Handles printing the grid as a table when the navigation bar button is clicked.
  function PrintGrid(){
    var disp_setting =  "toolbar=yes,location=no,directories=yes,menubar=yes,"; 
        disp_setting += "scrollbars=yes,width=650, height=600, left=100, top=25"; 

    var columnNms   = [];
    var columnHeads = [];
    var nonCols     = [];
    var i,j;
    var gridHeads   = jQuery('#'+gid).jqGrid('getGridParam','colNames');
    var colModel    = jQuery('#'+gid).jqGrid('getGridParam','colModel');
    var data        = jQuery('#'+gid).jqGrid('getRowData');
    var row1        = data[0];

    // Only choose columns with an index - this will ignore rownumbers if present.
    // Build up a list of columns and of column headings.
    jQuery.each(colModel, function(i,e){ if(e.index !== undefined && e.index !== 'cm') {columnNms.push(e.index); columnHeads.push(gridHeads[i]); } });

    // Look for columns in the first data row that contain links and remove them from the column list.
    jQuery.each(row1, function(i,e) { if(e.indexOf('href') != -1) {nonCols.unshift(columnNms.indexOf(i));} } );
    for(i=0;i<nonCols.length;i++) {
      columnNms.splice(nonCols[i],1);
      columnHeads.splice(nonCols[i],1);
    }

    // Build up the print table.
    var printTable = '<table><thead><tr>';
    for(i=0;i<columnNms.length;i++) { printTable += '<th>'+columnHeads[i]+'</th>'; }
    printTable += '</tr></thead><tbody>';

    for(i=0;i<data.length;i++) {
      printTable += '<tr>';
      for(j=0;j<columnNms.length;j++) { printTable += '<td>'+data[i][columnNms[j]]+'</td>'; }
      printTable += '</tr>';
    }
    printTable += '</tbody></table>';

    // Open a new window to display the table and call print on it.
    var docprint = window.open("", "", disp_setting);
    docprint.document.open();
    docprint.document.write('<html><head><title>Print '+pgTitle+'</title>');
    docprint.document.write('<style type="text/css">#prt-container table { border-collapse:collapse; } #prt-container th, #prt-container td { border:1px solid gray; padding: 3px; } </style>');
    docprint.document.write('</head><body onLoad="self.print()"><h1>'+pgTitle+'</h1><div id="prt-container" class="prt-hide">');
    docprint.document.write(printTable);
    docprint.document.write('</div></body></html>');
    docprint.document.close();
    docprint.focus();
  }
}

// Document READY -------------------------------------------------------------
jQuery(document).ready(function () {

  // Set the error handler for all AJAX calls.
  jQuery.ajaxSetup({error: errorHandler });

  // Convert a div into a modal dialog.
  jQuery( "#dialog-modal" ).dialog({
    autoOpen: false,
    width: 500,
    //height: 140,
    modal: true
  });

  // Load a form into a modal dialog.
  //jQuery('a.popupjs').live('click', function() {
  jQuery(document).on('click', 'a.popupjs', function() {
    var $a    = jQuery(this);
    // Check if the anchor has been set to no longer popup the dialog.
    if ($a.data().checks && $a.data().checks.doPopup === false) {return false;}

    var new_width  = $a.attr('data-dlg-width');
    var new_height = $a.attr('data-dlg-height');
		if (new_width) {jQuery('#dialog-modal').dialog('option', 'width', new_width);}
		if (new_height) {jQuery('#dialog-modal').dialog('option', 'height', new_height);}

    var title = $a.attr('data-dlg-title');
    jQuery('#dialog-modal').html('');
    jQuery('#dialog-modal').dialog('option', 'title', title || $a.text());
    jQuery('#dialog-modal').dialog('open');
    jQuery.ajax({
      type: 'get',
      url: $a.attr('href'),
      //          dataType: "script",
      success: dialogLoadSuccessHandler//,
      //error: errorHandler
    });
    return false;
  });

  // Load a form into a modal dialog with parameter from a select box.
  jQuery('a.popupjs-sel').live('click', function() {
    var $a      = jQuery(this);
    // Check if the anchor has been set to no longer popup the dialog.
    if ($a.data().checks && $a.data().checks.doPopup === false) {return false;}

    var new_width  = $a.attr('data-dlg-width');
    var new_height = $a.attr('data-dlg-height');
		if (new_width) {jQuery('#dialog-modal').dialog('option', 'width', new_width);}
		if (new_height) {jQuery('#dialog-modal').dialog('option', 'height', new_height);}

    var title   = $a.attr('data-dlg-title');
    var sel_id  = $a.attr('data-sel');
    var sel_val = jQuery('#' + sel_id).val();
    jQuery('#dialog-modal').html('');
    jQuery('#dialog-modal').dialog('option', 'title', title || $a.text());
    jQuery('#dialog-modal').dialog('open');
    jQuery.ajax({
      type: 'get',
      url: $a.attr('href') + '/' + sel_val, // + '.js',
      //          dataType: "script",
      success: dialogLoadSuccessHandler//,
      //error: errorHandler
    });
    return false;
  });

});

