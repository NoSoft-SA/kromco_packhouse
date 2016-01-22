// Utilities for SlickGrid usage


// Wrapper around browser storage (auto JSON stringify & parse).
var jmtStorage = {
  //storageAdaptor: sessionStorage,
  storageAdaptor: localStorage,

  // Thanks Angus! - http://goo.gl/GtvsU
  toType: function(obj) {
    return ({}).toString.call(obj).match(/\s([a-z|A-Z]+)/)[1].toLowerCase();
  },

  getItem: function(key) {
    var item = this.storageAdaptor.getItem(key);

    try {
      item = JSON.parse(item);
    } catch (e) {}

    return item;
  },

  setItem: function(key, value) {
    var type = this.toType(value);

    if (/object|array/.test(type)) {
      value = JSON.stringify(value);
    }

    this.storageAdaptor.setItem(key, value);
  },

  removeItem: function(key) {
    this.storageAdaptor.removeItem(key);
  },

  genStandardKey: function(suffix) {
    var rx  = new RegExp('/\\d+$');
    if (suffix === undefined) {
      return window.location.pathname.replace(rx,'');
    }
    else {
      return window.location.pathname.replace(rx,'') +'|'+ suffix;
    }
  }
};

// Save grid columns to local storage.
function saveLocSlickGridCols(gridid) {
    var key     = jmtStorage.genStandardKey(gridid) + '_cols';
    var grid     = jQuery('#'+gridid).data('slickgrid');
    var columns = [];
    jQuery.each(grid.getColumns(), function(i,val) {
      columns.push(val.id);
    });
    var fltr    = {columns: columns};
    jmtStorage.setItem(key, fltr);
    if(_.isEmpty(fltr)) {
      alert('Nothing to save');
    }
    else {
      alert('Saved columns');
    }
}

// Read local storage and apply saved columns.
function getLocSlickGridCols(gridid) {
  var key  = jmtStorage.genStandardKey(gridid) + '_cols';
  var fltr = jmtStorage.getItem(key) || 'Not Set';
  if(fltr === 'Not Set' || _.isEmpty(fltr)) {
    alert('There is no saved column setting to apply.');
    return;
  }

  var grid     = jQuery('#'+gridid).data('slickgrid');
  var ids      = JSON.parse(fltr.columns);
  var new_cols = [];
  for (var i = 0; i < ids.length; i++) {
    new_cols.push(grid.getColumns()[grid.getColumnIndex(ids[i])]);
  }
  grid.setColumns(new_cols);
}

// Save grid filters to local storage.
function saveLocSlickGrid(gridid, caption) {
    var key     = jmtStorage.genStandardKey(gridid);
    var grid    = jQuery('#'+gridid).data('slickgrid');
    var columns = grid.getColumns();
    var fltr    = {};
    for (var i = 0; i < columns.length; i++) {
        var col          = columns[i];
        var filterValues = col.filterValues;

        if (filterValues && filterValues.length > 0) {
          fltr[col.id] = filterValues;
        }
    }
    jmtStorage.setItem(key, fltr);
    if(_.isEmpty(fltr)) {
      alert('Nothing to save');
    }
    else {
      alert('Saved filter snapshot');
    }
}

// Read local storage and apply saved filter rules.
function getLocSlickGrid(gridid, caption) {
  var key  = jmtStorage.genStandardKey(gridid);
  var fltr = jmtStorage.getItem(key) || 'Not Set';
  if(fltr === 'Not Set' || _.isEmpty(fltr)) {
    alert('There is no saved snapshot to apply as a filter.');
    return; // TODO: clear filters?
  }

  var keys     = _.map(fltr, function(e,k) {return k});
  var grid     = jQuery('#'+gridid).data('slickgrid');
  var gridView = jQuery('#'+gridid).data('slickgridView');
  var cls      = jQuery('#'+gridid).prop('class').split(' ');
  var no       = _.find(cls, function(e) { return e.startsWith('slickgrid_') }).replace('slickgrid_', '');
  var columns  = grid.getColumns();
  for (var i = 0; i < columns.length; i++) {
    var col = columns[i];
    if (_.find(keys, function(k) { return k === col.id; })) {
      col.filterValues = JSON.parse(fltr[col.id]);
      if( _.isEmpty(col.filterValues)) {
        jQuery('.slick-header-menubutton', '#slickgrid_'+no+col.id.replace(/\./g,'\\.')).css("background-image", "url(/images/down.png)");
      }
      else {
        jQuery('.slick-header-menubutton', '#slickgrid_'+no+col.id.replace(/\./g,'\\.')).css("background-image", "url(/images/filter.png)");
      }
    }
  }
  gridView.refresh();
  showStatusCounts(gridid);
}

// Convert commas to semicolons for including in CSV.
function scrubCommas(dataArray) {
  var newArray = [];
  dataArray.forEach(function(data, index){
    newArray[index] = data.replace(/,/g, ";");
  });
  return newArray;
}
// Convert html entities to plain text for including in CSV.
function scrubHtmlEntities(dataArray) {
  var newArray = [];
  dataArray.forEach(function(data, index){
    newArray[index] = data.replace(/&amp;/g, "&").replace(/&gt;/g, ">").replace(/&#x2F;/g, "/").replace(/&lt;/g, "<");
  });
  return newArray;
}

// Download an array as a csv file.
// data must be an array of arrays, filename must not include the extension.
function saveArrayToCsv(data, filename) {
  var csvContent = ''; //"data:text/csv;charset=utf-8,";
  data.forEach(function(infoArray, index){
    dataString = scrubHtmlEntities(scrubCommas(infoArray)).join(",");
    csvContent += index < data.length ? dataString+ "\n" : dataString;
  });
  // var encodedUri = encodeURI(csvContent);
  // ...This change implemented because Chrome started saving all files named "download"...
  // See: https://code.google.com/p/chromium/issues/detail?id=373182
  var blob = new Blob([csvContent],{type: 'text/csv;charset=utf-8;'});
  var encodedUri =  URL.createObjectURL(blob);
  // ...end of change...
  // window.open(encodedUri); //... This will work in Firefox, below only in Chrome...
  var link = document.createElement("a");
  link.setAttribute("href", encodedUri);
  link.setAttribute("download", filename+".csv"); // From Chrome 35.0.1916.114, the filename is no longer honoured.
  link.click();
}

  // Download the contents of a grid as a csv file.
  function downloadSlickGrid(gridid,filename) {
    var columnNms   = [];
    var columnHeads = [];
    var i,j;
    var grid     = jQuery('#'+gridid).data('slickgrid');
    var gridView = jQuery('#'+gridid).data('slickgridView');
    var colModel = grid.getColumns();

    // Only choose sortable columns - this will ignore rownumbers, multiselect checkboxes and links columns.
    // Build up a list of columns and of column headings.
    jQuery.each(colModel, function(i,e){ if(e.sortable || e.dynlink) {columnNms.push(e.id); columnHeads.push(e.name); } });

    var data = [];
    data.push(columnHeads);

    var cols,row, indent, k, colval, test_str;
    for(i=0;i<gridView.getLength();i++) {
      row = gridView.getItem(i);
      cols =[];
      for(j=0;j<columnNms.length;j++) {
        if (row.__group) {
          if (j === 0) {
            indent = '';
            for(k=0;k<row.level;k++) {indent += ' '; }
            cols.push(_.escape(indent + row.value + ' (' + row.count+ ')'));
          }
          else {
            cols.push(_.escape(''));
          }
        }
        else {
          if (row.__groupTotals === true) {
            colval = '';
            if (row.sum && row.sum[columnNms[j]]) {
              colval = row.sum[columnNms[j]];
            }
            if (row.avg && row.avg[columnNms[j]]) {
              colval = 'avg: '+row.avg[columnNms[j]];
            }
            if (row.min && row.min[columnNms[j]]) {
              colval = 'min: '+row.min[columnNms[j]];
            }
            if (row.max && row.max[columnNms[j]]) {
              colval = 'max: '+row.max[columnNms[j]];
            }
            cols.push(_.escape(colval));
          }
          else {
            no_escape = false;
            // Get the text out of a link:
            if (_.isString(row[columnNms[j]]) && row[columnNms[j]].indexOf('"href":') > 0) {
              colval = jQuery.parseJSON( row[columnNms[j]] ).text;
            } else {
              // if the value is numeric and more than 12 digits long,
              // and does not include a decimal point,
              // place a single quote at the start - so a spreadsheet will treat it as text.
              test_str = ''+row[columnNms[j]];
              if (test_str.length > 12 && !isNaN(test_str) && !test_str.includes('.')) {
                colval = "'"+test_str;
                no_escape = true; // Cannot escape the quote!
              }
              else {
                colval = row[columnNms[j]];
              }
            }
            cols.push(no_escape ? colval : _.escape(colval));
          }
        }
      }
      data.push(cols);
    }
    saveArrayToCsv(data, filename);
  }

  // Display the number of rows after search/filter.
  function showStatusCounts(gridid) {
      var dataView = jQuery('#'+gridid).data('slickgridView');
      var statusText;
      var totLength = dataView.getItems().length;
      var grpLength = dataView.getGroups().length;
      if (grpLength > 0) {
        jQuery.each(dataView.getGroups(), function(i,val) {
          if (val.totals !== null && val.totals.__groupTotals) { grpLength += 1; }
        });
      }
      var displayLength = dataView.getLength() - grpLength;
      if (displayLength === totLength) {
        if (totLength === 0) {
          statusText = 'There are no rows to display';
        }
        else {
          statusText = 'Showing all rows (' + displayLength + ')';
        }
      } else {
          statusText = 'Showing ' + displayLength + ' of ' + totLength + ' rows';
      }
      jQuery('#'+gridid+'status-label').text(statusText);
  }

  // On success of AJAX call, load results into dialog.
  function dialogLoadSuccessHandler(data, textStatus, jqXHR) {
    jQuery('#dialog-modal').html(data);
  }
  // On failure of AJAX call, show an alert.
  function errorHandler(jqXHR, textStatus, errorThrown) {
    alert("Something went wrong: " + textStatus + ": " + errorThrown);
  }

  // Popup a JQ UI dialog.
  function jmtPopupDialog(new_width, new_height, title, text, href) {
    if (new_width) {jQuery('#dialog-modal').dialog('option', 'width', new_width);}
    if (new_height) {jQuery('#dialog-modal').dialog('option', 'height', new_height);}
    jQuery('#dialog-modal').html('');
    jQuery('#dialog-modal').dialog('option', 'title', title || text);
    jQuery('#dialog-modal').dialog('open');
    jQuery.ajax({
      type: 'get',
      url: href,
      //          dataType: "script",
      success: dialogLoadSuccessHandler//,
      //error: errorHandler
    });
  }

  function makeColSafeOrNull(val) {
    if (val === null || val === undefined || val === '') {
      return 'nil';
    }
    else {
      if (typeof val === 'string') {
        return "'" +val.replace(/'/g, "%27").replace(/"/g,'%22')+ "'";
      }
      else {
        return "'" +val+ "'";
      }
    }
  }

  // Submit ids and editable values from grid.
  function returnChangesFromGrid(gridid, action) {
    var grid     = jQuery('#'+gridid).data('slickgrid');
    var dataView = jQuery('#'+gridid).data('slickgridView'),
        columns = [],
        res = [];
    // Map editable column ids
    jQuery.each(grid.getColumns(), function(i,val) {
      if(val.editor) { columns.push(val.id); }
    });

    var i,j,row, colval,rowval;
    for(i=0;i<dataView.getLength();i++) {
      row = dataView.getItem(i);
      if (!row.__group) {
        rowval = "{:id=>"+row['id'];
        for(j=0;j<columns.length;j++) {
          rowval += (',:'+columns[j]+"=>"+makeColSafeOrNull(row[columns[j]]));
        }
        res.push(rowval+'}');
      }
    }
    if(confirm('Are you sure you want to save these changes?')) {
      var fn = window[gridid+'ValidateEditedRows'] // Turn the function name string into a callable function ref (avoid using eval).
      //var isOk = eval(gridid+'ValidateEditedRows').call(null,res);
      var isOk = fn( res );
      if (isOk) {
        var newform = jQuery( document.createElement('form') );
        newform.attr('method', 'post')
        .attr('action', action)
        .append('<input type=\"hidden\" name=\"grid_values\" value=\"['+res.join(',')+']\" />')
        .appendTo('body') // Required for Firefox to work.
        .submit();
      }
    }
  }

  // Submit multiselect choice
  function returnMultiSelectIdsFromGrid(gridid, action, can_be_cleared) {
    var gridSel  = jQuery('#'+gridid).data('slickgridSelectedIds');
    var ids      = gridSel.ids;
    var msg;
    if(!can_be_cleared && ids.length === 0) {
      alert("You have not selected any items to submit!");
    }
    else {
      if(ids.length === 0) {
        msg = 'Are you sure you want to submit an empty selection?'
      }
      else {
        msg = 'Are you sure you want to submit this selection?(' + ids.length.toString() + ' items)'
      }
      if(confirm(msg)) {
        var newform = jQuery( document.createElement('form') );
        newform.attr('method', 'post')
          .attr('action', action)
          .append('<input type=\"hidden\" name=\"selection[list]\" value=\"['+ids.join(',')+']\" />')
          .appendTo('body') // Required for Firefox to work.
          .submit();
      }
    }
  }

  // Build up the content for the view row table (in grid column order or in alphabetical column name order)
  function buildRowsForViewRowTable(gridid, sorted) {
    var grid     = jQuery('#'+gridid).data('slickgrid');
    var dataView = jQuery('#'+gridid).data('slickgridView');
    var columns = [];
    jQuery.each(grid.getColumns(), function(i,val) {
      if(!val.unfiltered || val.dynlink) { columns.push(val); }
    });
    if(sorted === true) {
      columns.sort(function(a,b){return a.name.toLowerCase() > b.name.toLowerCase() ? 1 : -1;});
    }
    var item     = dataView.getItem(grid.getActiveCell().row);
    var i, cls, strBod = '', rowCls = item.row_colour, colCls = '';
    for (i=0; i < columns.length; i++) {
        var col = columns[i], val;
        if(i % 2 === 0) {cls = rowCls+' roweven'; } else { cls = rowCls+' rowodd'; }
        if(col.formatter === undefined) {
          val = item[col.field];
          val = _.escape(val);
        }
        else {
          val = col.formatter(dataView.getIdxById(item.id),grid.getColumnIndex(col.id), item[col.field], col, item);
          if (!col.dynlink && col.formatter !== slickBooleanFormatter ) {
            val = _.escape(val);
          }
        }
        if (col.cssClass === undefined) {colCls = ' class="slick-view-cell"'; } else { colCls = ' class="'+col.cssClass+' slick-view-cell"'; }
        //strBod += '<tr class="hover-row '+cls+'"><td>'+col.name+'</td><td'+colCls+'>'+_.escape(val)+'</td></tr>';
        strBod += '<tr class="hover-row '+cls+'"><td>'+col.name+'</td><td'+colCls+'>'+val+'</td></tr>';
    }
    return strBod;
  }

  // Expand/collapse all groups
  function expandCollapseGrid(gridid,expand) {
    var dataView = jQuery('#'+gridid).data('slickgridView');
    if( expand ) {
      dataView.expandAllGroups();
    }
    else {
      dataView.collapseAllGroups();
    }
  }

  // Toggle to show only selected rows of multiselect grid.
  function filterSelectedIds(gridid,filter) {
    var dataView = jQuery('#'+gridid).data('slickgridView');
    if (filter) {
      dataView.setFilterArgs({ selectedIds:true });
      dataView.refresh();
      showStatusCounts(gridid);
    }
    else {
      dataView.setFilterArgs({ searchString:'' });
      jQuery('#'+gridid+'search').keyup();
    }
  }

  // Toggle to invert selection in a multiselect grid.
  function invertSelectedIds(gridid) {
    var grid             = jQuery('#'+gridid).data('slickgrid');
    var dataView         = jQuery('#'+gridid).data('slickgridView');
    var multiSelectStore = jQuery('#'+gridid).data('slickgridSelectedIds');
    var rows = [];

    // Alert and prevent if any filter is in place...
    var totLength = dataView.getItems().length;
    var grpLength = dataView.getGroups().length;
    if (grpLength > 0) {
      jQuery.each(dataView.getGroups(), function(i,val) {
        if (val.totals !== null && val.totals.__groupTotals) { grpLength += 1; }
      });
    }
    var displayLength = dataView.getLength() - grpLength;
    if (displayLength !== totLength) {
      alert('Please clear all filters before inverting your selection');
      return;
    }

    // Invert...
    for (var i = 0; i < totLength; i++) { rows[i] = i; }
    var newSelection = _.reject(dataView.mapRowsToIds(rows), function(row_id) {
      return _.contains(multiSelectStore.ids, row_id)
    });
    grid.setSelectedRows(dataView.mapIdsToRows(newSelection))
  }

  function navGrid(gridid, forward) {
    var grid     = jQuery('#'+gridid).data('slickgrid');
    if (forward) {
      grid.navigateDown();
    }
    else {
      grid.navigateUp();
    }
  }

  // View fields of a grid row in a dialog.
  function viewRowGridButtonClick(gridid,caption) {
    var grid     = jQuery('#'+gridid).data('slickgrid');
    if(grid.getActiveCell() === null) {
      alert('Please select a row.');
      return;
    }
    var sorted = jQuery('#dialog-modal').data('viewRowSorted');
     var strSortBtn = "";
     if (sorted) {
      strSortBtn = "<button disabled=true>Sort</button>";
     }
     else {
      strSortBtn = "<button onclick=\"jQuery('#dialog-modal').data('viewRowSorted',true);jQuery('#"+gridid+"vrBod').html(buildRowsForViewRowTable('"+gridid+"', true));this.disabled=true;\">Sort</button>";
     }
    var strPrevBtn = "<button onclick=\"navGrid('"+gridid+"', false);jQuery('#"+gridid+"vrBod').html(buildRowsForViewRowTable('"+gridid+"', jQuery('#dialog-modal').data('viewRowSorted')));\">Prev</button>";
    var strNextBtn = "<button onclick=\"navGrid('"+gridid+"', true);jQuery('#"+gridid+"vrBod').html(buildRowsForViewRowTable('"+gridid+"', jQuery('#dialog-modal').data('viewRowSorted')));\">Next</button>";

    jQuery('#dialog-modal').html(strSortBtn+strPrevBtn+strNextBtn+'<div style="position:absolute;overflow-y:auto;top:40px;bottom:10px;left:10px;right:10px;min-height:200px;">'+
                                 '<table class="thinbordertable">'+
                                 '<thead><tr><th>Column</th><th>Value</th></tr></thead>'+
                                 '<tbody id="'+gridid+'vrBod">'+buildRowsForViewRowTable(gridid, sorted)+'</tbody></table></div>');
    jQuery('#dialog-modal').dialog('option', 'title', 'Selected row from '+caption);
    jQuery('#dialog-modal').dialog('option', 'height', 300);
    jQuery("#dialog-modal button:first" ).button({
        icons: {
          primary: "ui-icon-arrowthick-2-n-s"
        }
      }).next().button({icons: {primary: "ui-icon-seek-prev" }}).next().button({icons: {secondary: "ui-icon-seek-next" }});
    jQuery('#dialog-modal').dialog('open');
    jQuery("#dialog-modal button:first" ).blur();
  }

  // Return a number with thousand separator and at least 2 digits after the decimal.
  function numberWithCommas2(x) {
    if (typeof x === 'string') { x = parseFloat(x); }
    x = Math.round((x + 0.00001) * 100) / 100 // Round to 2 digits if longer.
    var parts = x.toString().split(".");
    parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    if(parts[1] === undefined || parts[1].length === 0) {parts[1] = '00'; }
    if(parts[1].length === 1) {parts[1] += '0'; }
    return parts.join(".");
  }

  // Return a number with thousand separator and at least 4 digits after the decimal.
  function numberWithCommas4(x) {
    if (typeof x === 'string') { x = parseFloat(x); }
    x = Math.round((x + 0.0000001) * 10000) / 10000 // Round to 4 digits if longer.
    var parts = x.toString().split(".");
    parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    if(parts[1] === undefined || parts[1].length === 0) {parts[1] = '0000'; }
    while(parts[1].length < 4) {parts[1] += '0'; }
    return parts.join(".");
  }
  // Formatters

  // Format a text cell with classes for colour/bold/italic...
  function slickTextFormatter(row, cell, value, columnDef, dataContext) {
    if(value === ''){ return ''; }
    if(dataContext.cell_format_rules === ''){ return value; }
    var colFmtRule = jQuery.parseJSON( dataContext.cell_format_rules );
    var cls = colFmtRule[columnDef.id];
    if( cls === undefined ) { return value; }
    return "<span class='"+cls+"'>"+value+"</span>";
  }

  // Format a numeric text cell with thousands separator.
  function slickDelimitedFormatter(row, cell, value, columnDef, dataContext) {
    if(value === ''){ return ''; }
    return numberWithCommas2(value); // 10,000,000.00
  }

  // Format a numeric text cell with thousands separator. 4 decimals.
  function slickDelimitedFormatter4(row, cell, value, columnDef, dataContext) {
    if(value === ''){ return ''; }
    return numberWithCommas4(value); // 10,000,000.0000
  }

  // Format a numeric text cell with thousands separator and "R" for currency.
  function slickCurrencyFormatter(row, cell, value, columnDef, dataContext) {
    if(value === ''){ return ''; }
    return 'R'+numberWithCommas2(value); // R10,000,000.00
  }

  // Format a numeric text cell with thousands separator and "R" for currency. 4 decimals.
  function slickCurrencyFormatter4(row, cell, value, columnDef, dataContext) {
    if(value === ''){ return ''; }
    return 'R'+numberWithCommas4(value); // R10,000,000.0000
  }

  // Format a boolean with a checkbox image.
  function slickBooleanFormatter(row, cell, value, columnDef, dataContext) {
    if(value === ''){ return ''; }
    if(value == 't' || value == 'true' || value == 'y' || value == 1) {
      return "<span class='ac_icon ac_icon_check'>&nbsp;</span>";
    }
    else {
      return "<span class='ac_icon ac_icon_uncheck'>&nbsp;</span>";
    }
  }

  // TODO: spinner...
  function slickLinkFormatter(row, cell, value, columnDef, dataContext) {
    if(value === '' || jQuery.isEmptyObject(value)){ return ''; }
    var linkConfig, prompt_action;
    if(typeof(value) == "string") {linkConfig= jQuery.parseJSON( value ); } else {linkConfig = value;}
    if(linkConfig === null || linkConfig === undefined) { return ''; }
    if(linkConfig.prompt_text !== '') { prompt_action = ' onclick="if(!confirm(\''+linkConfig.prompt_text+'\')) {return false;}" '; } else {prompt_action = ''; }
    if(linkConfig.icon === undefined || linkConfig.icon === '') {
      return "<a href='"+linkConfig.href+"' "+prompt_action+"class='"+linkConfig.cls+"'>"+linkConfig.text+"</a>";
    } else {
      var img = linkConfig.icon;
      if(img.indexOf('.') === -1) { img += '.png'; }
      return "<a href='"+linkConfig.href+"' "+prompt_action+"class='"+linkConfig.cls+"'><img src='/images/"+img+"' border='0' height='16' width='16' /></a>";
    }
  }

  function slickLinkPopUpFormatter(row, cell, value, columnDef, dataContext) {
    if(value === '' || jQuery.isEmptyObject(value)){ return ''; }
    var linkConfig;
    if(typeof(value) == "string") {linkConfig= jQuery.parseJSON( value ); } else {linkConfig = value;}
    if(linkConfig === null || linkConfig === undefined) { return ''; }
    if(linkConfig.icon === undefined || linkConfig.icon === '') {
      return "<a style='text-decoration: underline;' id='"+linkConfig.href+"' href='#' onclick='javascript:parent.call_open_window(this);'>"+linkConfig.text+"</a>";
    } else {
      var img = linkConfig.icon;
      if(img.indexOf('.') === -1) { img += '.png'; }
      return "<a style='text-decoration: underline;' id='"+linkConfig.href+"' href='#' onclick='javascript:parent.call_open_window(this);'><img src='/images/"+img+"' border='0' height='16' width='16' /></a>";
    }
  }

  // Formatter for Action Collection.
  // Presents a button which when clicked launches a contextMenu.
  function slickActionCollectionFormatter(row, cell, value, columnDef, dataContext) {
    if(value === ''){ return ''; }
    return '<button class="slickGridContextMenu" data-row="'+row+'">list</button>';
  }

// Process an Action type link.
  function slickProcessAction(body) {
    if(body.prompt_text !== '') {
      if(!confirm(body.prompt_text)) {return false;}
    }
    if(body.cls.indexOf('popupjs') > -1) { // Load page in a UI dialog
      var parsed_opts = JSON.parse(body.opts);
      jmtPopupDialog(parsed_opts['data-dlg-width'], parsed_opts['data-dlg-height'], parsed_opts['data-dlg-title'], body.text, body.href);
    }
    else {
      window.location.href = body.href;
    }
  }
  function slickProcessLinkWindow(body) {
    open_window_link(body.href);
  }

  // Handles printing the grid as a table when the navigation bar button is clicked.
  function printSlickGrid(gridid,pgTitle) {
     var disp_setting =  "toolbar=yes,location=no,directories=yes,menubar=yes,";
         disp_setting += "scrollbars=yes,width=650, height=600, left=100, top=25";

    var columnNms   = [];
    var columnHeads = [];
    var i,j;
    var grid     = jQuery('#'+gridid).data('slickgrid');
    var gridView = jQuery('#'+gridid).data('slickgridView');
    var colModel = grid.getColumns();

    // Only choose sortable columns - this will ignore rownumbers, multiselect checkboxes and links columns.
    // Build up a list of columns and of column headings.
    jQuery.each(colModel, function(i,e){ if(e.sortable || e.dynlink) {columnNms.push(e.id); columnHeads.push(e.name); } });

    // Build up the print table.
    var printTable = '<table><thead><tr>';
    for(i=0;i<columnNms.length;i++) { printTable += '<th>'+columnHeads[i]+'</th>'; }
    printTable += '</tr></thead><tbody>';

    var cls,row, colval;
    for(i=0;i<gridView.getLength();i++) {
      row = gridView.getItem(i);
      cls = row.row_colour;
      if(cls !== '') {
        cls = ' class="'+cls+'"';
      }
      printTable += '<tr'+cls+'>';
      //for(j=0;j<columnNms.length;j++) { printTable += '<td>'+_.escape(row[columnNms[j]])+'</td>'; }
      for(j=0;j<columnNms.length;j++) {
        if (row.__group) {
          if (j === 0) {
            printTable += '<td><div class="slick-group-title" level="'+row.level+'">'+row.title+'</div></td>';
          }
          else {
            printTable += '<td>'+_.escape('')+'</td>';
          }
        }
        else {
          if (row.__groupTotals === true) {
            colval = '';
            if (row.sum && row.sum[columnNms[j]]) {
              colval = row.sum[columnNms[j]];
            }
            if (row.avg && row.avg[columnNms[j]]) {
              colval = 'avg: '+row.avg[columnNms[j]];
            }
            if (row.min && row.min[columnNms[j]]) {
              colval = 'min: '+row.min[columnNms[j]];
            }
            if (row.max && row.max[columnNms[j]]) {
              colval = 'max: '+row.max[columnNms[j]];
            }
            printTable += '<td>'+_.escape(colval)+'</td>';
          }
          else {
            // Get the text out of a link:
            if (_.isString(row[columnNms[j]]) && row[columnNms[j]].indexOf('"href":') > 0) {
              colval = jQuery.parseJSON( row[columnNms[j]] ).text;
            } else {
              colval = row[columnNms[j]];
            }
            printTable += '<td>'+_.escape(colval)+'</td>';
          }
        }
      }
      printTable += '</tr>\n';
    }
    printTable += '</tbody></table>';

    // Open a new window to display the table and call print on it.
    var docprint = window.open("", "", disp_setting);
    docprint.document.open();
    docprint.document.write('<html><head><title>Print '+pgTitle+'</title>');
    docprint.document.write('<style type="text/css">#prt-container table { border-collapse:collapse; }'+ ' .slick_row_black td { color: black; } .slick_row_blue td { color: blue; } .slick_row_brown td { color: brown; } .slick_row_green td { color: green; } .slick_row_gray td { color: gray; } .slick_row_maroon td { color: maroon; } .slick_row_orange td { color: orange; } .slick_row_purple td { color: purple; } .slick_row_red td { color: red; } .slick_row_light_green td { color: lightgreen; } .slick_row_dark_green td  { color: darkgreen; } #prt-container th, #prt-container td { border:1px solid gray; padding: 3px; } .slick-group-title[level="0"] { font-weight: bold; } .slick-group-title[level="1"] { text-decoration: underline; text-indent: 10px; } .slick-group-title[level="2"] { font-style: italic; text-indent: 20px; } </style>');
    docprint.document.write('</head><body onLoad="self.print()"><h1>'+pgTitle+'</h1><div id="prt-container" class="prt-hide">');
    docprint.document.write(printTable);
    docprint.document.write('</div></body></html>');
    docprint.document.close();
    docprint.focus();
  }

  // Zoom the grid to full page and back.
  function zoomGridButtonClick() {
     var cf = jQuery('#contentFrame', top.document);
     // var td = null;
     // if (cf.length === 0) {
     //   cf = top.document;
     //   td = top.document;
     // }
     // else {
     //   td = top.frames[1].document;
     // }
     var isSub = ('contentFrame' !== self.name);
     var sf = null;
     if(isSub) {sf = jQuery('#'+self.name, top.frames[1].document);}
     //if(isSub) {sf = jQuery('#'+self.name, td);}
     if(jQuery(cf).hasClass('zoomout')) {
       jQuery(cf).removeClass('zoomout');
       if(isSub) {jQuery(sf).removeClass('zoomoutsub'); }
       jQuery('#jqgridminimize').css('visibility', 'hidden');
     }
     else {
       jQuery(cf).addClass('zoomout');
       if(isSub) {jQuery(sf).addClass('zoomoutsub'); }
       jQuery('#jqgridminimize').css('visibility', 'visible');
     }
   }

  //TODO: if invalidate passed, repaint grid... (for when was hidden - EDI grids)....
  function resizeSlickGrid(id, grid) {
     jQuery('#'+id+'_caption').width(jQuery('#'+id).width());
     grid.resizeCanvas();
  }

  // Build menu items for ActionCollection.
  function build_ac_context_sub_menu(linkConfig,level) {
    var items            = {};
    var ky = ''+level;

    linkConfig.forEach(function(element,i) {
      var k = level.slice();
      k.push(i);
      if(element.type==='separator')   {items[k.join('|')] = "---------"; }
      if(element.type==='action')      {items[k.join('|')] = {name: element.body.text, icon: element.body.icon}; }
      if(element.type==='text')        {items[k.join('|')] = {name: element.body, disabled: true}; }
      if(element.type==='link_window') {items[k.join('|')] = {name: element.body.text, icon: element.body.icon}; }
      if(element.type==='sub_menu')    {items[k.join('|')] = {name: element.caption, items: build_ac_context_sub_menu(element.body,k)}; }
    });
    return items;
  }

  // Return data object (at correct level for submenu).
  function linkConfigCurrentAt(linkConfig,levels) {
    var nl = levels;
    var i, currObj;
    nl.shift(); // Remove level 0
    currObj = linkConfig[nl.shift()]; // Get level 0 object
    for (i=0; i < nl.length; i++) {
      currObj = currObj.body[nl[i]];
    }
    return currObj;
  }

  // Change grouping
  function changeGridGrouping(gridid, groupable_fields) {
    var grid = jQuery('#'+gridid).data('slickgrid');
    var dataView = jQuery('#'+gridid).data('slickgridView');
    var columns = []; //
    var opts;
    var sp_col = {id:'colSpacer', name:'', field: 'cs', width:0, cannotTriggerInsert:true, resizable:false, selectable:false, sortable:false, unfiltered:true};
    var nr_col = {id:'rowNumber', name:'&nbsp;', field: 'rn', formatter:function(row, cell, value, columnDef, dataContext) { return row + 1 + ' '; }, behavior:'select', cssClass:'cell-selection', width:40, cannotTriggerInsert:true, resizable:false, unselectable:true, sortable:false, unfiltered:true, cssClass: 'ui-state-default jqgrid-rownum slk_cell_right_align'};


    var already_grouped = _.map(dataView.getGrouping(), function(e,k) {return e.getter});
    jQuery.each(already_grouped, function(index, value) {
      opts += '<option selected="selected">'+value+'</option>';
    });
    jQuery.each(groupable_fields, function(index, value) {
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
        if(choice === null) {
          columns.push(nr_col);
          jQuery.each(grid.getColumns(), function (i, e) {
            if (e.id !== 'rowNumber' && e.id !== 'colSpacer') {
              columns.push(e);
            }
          });
          grid.setColumns(columns);
          dataView.setGrouping([]);
        }
        else {
          columns.push(sp_col);
          jQuery.each(grid.getColumns(), function (i, e) {
            if (e.id !== 'rowNumber' && e.id !== 'colSpacer') {
              columns.push(e);
            }
          });
          grid.setColumns(columns);
          changeGroupingTo(gridid, choice);
        }
        jQuery(this).dialog("close");
        jQuery('#changeGroupColDlg').remove();
      },
      "Cancel": function() {jQuery(this).dialog("close");
        jQuery('#changeGroupColDlg').remove();
      }}
    });
    jQuery('#changeGroupCol').multiselect();

  }

  function changeGroupingTo(gridid, selected_fields) {
    var dataView = jQuery('#'+gridid).data('slickgridView');
    var aggregators = jQuery('#'+gridid).data('groupAggregators');
    var grpArray = [];
    var colours  = ['green', 'blue', 'orange', 'purple', 'red'];
    var obj = {};
    jQuery.each(selected_fields, function(i,val) {
      obj = {};
      obj.getter = val;
      obj.formatter = function (g) { return g.value + '  <span style="color:'+colours[i]+'">(' + g.count + ')</span>'; };
      obj.aggregators = aggregators;
      grpArray.push(obj);
    });
    dataView.setGrouping(grpArray);
  }

// Document READY -------------------------------------------------------------
jQuery(document).ready(function () {

  // Context menu for ActionCollection in a grid.
  jQuery.contextMenu({
    selector: '.slickGridContextMenu',
    trigger: 'left',
    build: function($trigger, e) {
      // this callback is executed every time the menu is to be shown
      // its results are destroyed every time the menu is hidden
      // e is the original contextmenu event, containing e.pageX and e.pageY (amongst other data)
      var row              = jQuery(e.target).data('row');
      var gridView         = jQuery(jQuery(e.target).parents('.jmt_slick_grid')[0]).data('slickgridView');
      var rowdata          = gridView.getItem(row);
      var actionCollection = rowdata.actions;
      var linkConfig       = jQuery.parseJSON( actionCollection );
      var items            = {};
      items                = build_ac_context_sub_menu(linkConfig,[0]);

      return {
        callback: function(key, options) {
          var levels = key.split('|');
          var currObj = linkConfigCurrentAt(linkConfig,levels);
          if(currObj.type === 'action')      {slickProcessAction(currObj.body);}
          if(currObj.type === 'link_window') {slickProcessLinkWindow(currObj.body);}
        },
        items: items
      };
    }
  });

  // Set the error handler for all AJAX calls.
  jQuery.ajaxSetup({error: errorHandler });

  // Convert a div into a modal dialog.
  jQuery( "#dialog-modal" ).dialog({
    autoOpen: false,
    width: 500,
    //height: 140,
    modal: true
  });

  // Show a popup with a webquery URL to be copied to clipboard.
  jQuery(document).on('click', 'a.copy_webquery_link', function() {
    var link = jQuery(this);
    copyToClipboard('Paste this link in your spreadsheet. ', link.attr('href'));
    return false;
  });

  // Load a form into a modal dialog.
  //jQuery('a.popupjs').live('click', function() {
  jQuery(document).on('click', 'a.popupjs', function() {
    var $a    = jQuery(this);
    // Check if the anchor has been set to no longer popup the dialog.
    if ($a.data().checks && $a.data().checks.doPopup === false) {return false;}

    var new_width  = $a.attr('data-dlg-width');
    var new_height = $a.attr('data-dlg-height');
    // if (new_width) {jQuery('#dialog-modal').dialog('option', 'width', new_width);}
    // if (new_height) {jQuery('#dialog-modal').dialog('option', 'height', new_height);}

    var title = $a.attr('data-dlg-title');
    jmtPopupDialog(new_width, new_height, title, $a.text(), $a.attr('href'));
    // jQuery('#dialog-modal').html('');
    // jQuery('#dialog-modal').dialog('option', 'title', title || $a.text());
    // jQuery('#dialog-modal').dialog('open');
    // jQuery.ajax({
    //   type: 'get',
    //   url: $a.attr('href'),
    //   //          dataType: "script",
    //   success: dialogLoadSuccessHandler//,
    //   //error: errorHandler
    // });
    return false;
  });

  // Load a form into a modal dialog with parameter from a select box.
  //jQuery('a.popupjs-sel').live('click', function() {
  jQuery(document).on('click', 'a.popupjs-sel', function() {
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

  // Toggle display of list of links for an ActionCollection in a grid column.
  jQuery(document).on('click', '.action-collection-click', function() {
    var a   = jQuery(this);
    var pop = jQuery('div', a);
    if (pop.is(':hidden')) {
      jQuery('.action-collection-click div').hide(); // Make sure only one popup is showing at a time.
      pop.show();
    }
    else {
      pop.hide();
    }
  });

});


// Select Editor for SlickGrid.
(function ($) {
  // register namespace
  $.extend(true, window, {
    "Slick": {
      "Editors": {
        "Select": SelectEditor
      }
    }
  });

  function SelectEditor(args) {
    var $select;
    var defaultValue;
    var scope = this;

    this.init = function () {
      var opts = '';
      for (var i=0;i<args.column.select_vals.length; i++) {
        if(args.column.select_texts) {
          opts += "<OPTION value='"+args.column.select_vals[i]+"'>"+args.column.select_texts[i]+"</OPTION>"
        }
        else {
          opts += "<OPTION value='"+args.column.select_vals[i]+"'>"+args.column.select_vals[i]+"</OPTION>"
        }
      }
      $select = $("<SELECT tabIndex='0' class='editor-select'>"+opts+"</SELECT>");
      $select.appendTo(args.container);
      $select.focus();
    };

    this.destroy = function () {
      $select.remove();
    };

    this.focus = function () {
      $select.focus();
    };

    this.loadValue = function (item) {
      $select.val((defaultValue = item[args.column.field]));
      $select.select();
    };

    this.serializeValue = function () {
      return ($select.val());
    };

    this.applyValue = function (item, state) {
      item[args.column.field] = state;
    };

    this.isValueChanged = function () {
      return ($select.val() != defaultValue);
    };

    this.validate = function () {
      return {
        valid: true,
        msg: null
      };
    };

    this.init();
  }

})(jQuery);
