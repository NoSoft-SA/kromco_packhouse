
// Module for handling DataMiner calculations and functions.
var dmCalcFunc = (function() {

  var first_time        = true;
  var numeric_cols      = [];
  var column_array      = [];

  var group_by_array    = [];
  var order_by_array    = [];

  var functions_applied = [];

  var remove_me = "<img src='/images/expanded.png' class='removeMe' style='cursor:pointer;'/>";

  // Remove a line item from a list.
  jQuery('.removeMe').live('click', function() {
		var target   = jQuery(this).parent();
    var col_type = target.attr('data-coltype');
    var val      = target.attr('data-id');
    switch(col_type) {
      case 'groupby':
        group_by_array.splice(group_by_array.indexOf(val), 1);
        break;
      case 'orderby':
        order_by_array.splice(order_by_array.indexOf(val), 1);
        break;
      case 'function':
        functions_applied.splice(functions_applied.indexOf(val), 1);
        break;
    }
    write_array_to_form(col_type);
    target.remove();
  });

  // START: Sortable via drag & drop.
  function reCalculateListSequence(col_type) {
    if(col_type === 'groupby') {
      group_by_array = [];
      jQuery('li', '#grpsol').map(function(){
        group_by_array.push(jQuery(this).attr('data-id'));
      });
    }
    else {
      order_by_array = [];
      jQuery('li', '#ordsol').map(function(){
        order_by_array.push(jQuery(this).attr('data-id'));
      });
    }
    write_array_to_form(col_type);
  }

  jQuery(document).ready(function() {

    jQuery('#grpsol').sortable({
      revert: true,
      cursor: 'move',
      stop: function(event, ui) {
        reCalculateListSequence('groupby');
      }
    }).disableSelection();

    jQuery('#ordsol').sortable({
      revert: true,
      cursor: 'move',
      stop: function(event, ui) {
        reCalculateListSequence('orderby');
      }
    }).disableSelection();
  });
  // END: Sortable via drag & drop.

  // Hidden fields in form:
  // group_by_hidden_field
  // apply_functions_hidden_field
  // apply_group_by_hidden_field
  // order_by_hidden_field
  //
  // numeric_cols_hidden_field
  // columns_dropdown_hidden_field
  //
  // This loads array values from the hidden fields in the form
  // and populates the lists with functions, group by and order by
  // settings if required.
  function initializeState() {
    if(numeric_cols.length === 0 && jQuery('#numeric_cols_hidden_field').val() !== '') {
      numeric_cols   = jQuery('#numeric_cols_hidden_field').val().split(',');
    }
    if(column_array.length === 0 && jQuery('#columns_dropdown_hidden_field').val() !== '')   {
      column_array   = jQuery('#columns_dropdown_hidden_field').val().split(',');
    }
    if(group_by_array.length === 0 && jQuery('#group_by_hidden_field').val() !== '') {
      group_by_array = jQuery('#group_by_hidden_field').val().split(',');
    }
    if(order_by_array.length === 0 && jQuery('#order_by_hidden_field').val() !== '') {
      order_by_array = jQuery('#order_by_hidden_field').val().split(',');
      add_all_order_by_columns(true);
    }
    if(first_time) {
      first_time = false;
      if(group_by_array.length > 0) {
        add_all_group_by_columns(true);
      }
      if(jQuery('#apply_functions_hidden_field').val() !== '') {
        var re = /,|\|/;
        functions_applied = jQuery('#apply_functions_hidden_field').val().split(re);
        add_applied_functions();
      }
    }
  }

  // Helper to get column names from function list.
  function columns_used_in_functions() {
    var cols = [];
    var i;
    for (i=0, n=functions_applied.length;i<n;i++) {
      var text = functions_applied[i];
      if(text !== 'COUNT(*)') {
        if(text.indexOf('SUM(') !== -1) { text = text.replace('SUM(','').replace(')',''); }
        if(text.indexOf('AVG(') !== -1) { text = text.replace('AVG(','').replace(')',''); }
        if(text.indexOf('MIN(') !== -1) { text = text.replace('MIN(','').replace(')',''); }
        if(text.indexOf('MAX(') !== -1) { text = text.replace('MAX(','').replace(')',''); }
        if(cols.indexOf(text) === -1) { cols.push(text); }
      }
    }
    return cols;
  }

  // Store an array as a string in a hidden form field.
  function write_array_to_form(col_type) {
    switch(col_type) {
      case 'groupby':
        jQuery('#group_by_hidden_field').val(group_by_array.join(','));
        break;
      case 'groupapply':
        jQuery('#apply_group_by_hidden_field').val(group_by_array.join(','));
        break;
      case 'orderby':
        jQuery('#order_by_hidden_field').val(order_by_array.join(','));
        break;
      case 'funcapply':
        jQuery('#apply_functions_hidden_field').val(functions_applied.join(','));
        break;
    }
  }

  // Main function. Checks state and displays a dialog.
  function showBox() {

    initializeState();

    jQuery('#calculations2').dialog( {
      autoOpen: true,
//      create: function(event) { jQuery(event.target).parent().css('position', 'fixed'); },
      width: 900,
      title: 'Calculations / Functions',
      modal: true,
      buttons: {
        "Apply Calculations": function() { 
          apply_calculations();
          jQuery( this ).dialog( "close" );
        },
        Cancel: function() {
          jQuery( this ).dialog( "close" );
        }
      }
    });
  }

  // Disable the column dropdown if COUNT is chosen.
  function function_dropdown_changed() {
    var func = jQuery('#function_dropdown').val();
    if(func === 'COUNT') {
      jQuery('#columns_dropdown').attr('disabled', 'disabled');
    }
    else {
      jQuery('#columns_dropdown').removeAttr('disabled');
    }
  }

  // Add chosen function to the page and array.
  function add_function() {
    var func = jQuery('#function_dropdown').val();
    if( func === '') {
      alert('No group by function chosen');
      return;
    }
    var col = jQuery('#columns_dropdown').val();
    var val;
    if(func === 'COUNT') {
      val = 'COUNT(*)';
    }
    else {
      if( col === '') {
        alert('Select a column for the function selected please');
        return;
      }
      val = func + '(' + col + ')';
    }
    if(functions_applied.indexOf(val) !== -1) {
      alert('This function has been already added');
      return;
    }

    functions_applied.push(val);
    var ul = jQuery('#calcfuncsul');
    jQuery( "<li data-id=\"" + val + "\" data-coltype=\"function\"></li>" )
              .html( remove_me + ' ' +val )
              .appendTo( ul );

  }

  // Populate functionlist from functions array.
  function add_applied_functions() {
    var ul = jQuery('#calcfuncsul');
    jQuery.each(functions_applied, function(i,e) {
      jQuery( "<li data-id=\"" + e + "\" data-coltype=\"function\"></li>" )
                .html( remove_me + ' ' +e )
                .appendTo( ul );
    });
  }

  // START: group_by handlers.
  function add_group_by_column() {
    var val = jQuery('#group_by_dropdown').val();
    if( val === '') {
      alert('No group by column chosen');
      return;
    }
    if(group_by_array.indexOf(val) !== -1) {
      alert('This group by column has already been included');
      return;
    }
    if(functions_applied.length === 0) {
      alert("You must add at least one function to add group by columns");
      return;
    }

    group_by_array.push(val);
    write_array_to_form('groupby');

    var ol = jQuery('#grpsol');
    jQuery( "<li class=\"draggable-groupby\" data-id=\"" + val + "\" data-coltype=\"groupby\"></li>" )
              .html( remove_me + ' ' +val )
              .appendTo( ol );
  }

  function add_all_group_by_columns(use_applied) {
    var ol = jQuery('#grpsol');
    var func_cols = columns_used_in_functions();
    var use_cols;
    if(use_applied && use_applied === true) {
      use_cols = group_by_array.slice(0);
    }
    else {
      use_cols = column_array;
    }
    ol.empty();
    group_by_array = [];
    jQuery.each(use_cols, function(i,e) {
      if(func_cols.indexOf(e) === -1) {
        group_by_array.push(e);
        jQuery( "<li class=\"draggable-groupby\" data-id=\"" + e + "\" data-coltype=\"groupby\"></li>" )
                  .html( remove_me + ' ' +e )
                  .appendTo( ol );
      }
    });

    write_array_to_form('groupby');
  }

  function clear_group_by_columns() {
    var ol = jQuery('#grpsol');
    ol.empty();
    group_by_array = [];
    write_array_to_form('groupby');
  }
  // END: group_by handlers.

  // START: order_by handlers.
  function add_order_by_column() {
    var val      = jQuery('#order_by_dropdown').val();
    var criteria = jQuery('#order_by_criteria').val();
    if( val === '') {
      alert('No order by column chosen');
      return;
    }
    if(group_by_array.length > 0) {
      if(group_by_array.indexOf(val) === -1) {
        alert('Select a column that is in the group by columns list please');
        return;
      }
    }
    if( criteria !== '') {
      val = val + ' ' + criteria;
    }
    if(order_by_array.indexOf(val) !== -1) {
      alert('This order by column has already been included');
      return;
    }

    order_by_array.push(val);
    write_array_to_form('orderby');

    var ol = jQuery('#ordsol');
    jQuery( "<li class=\"draggable-orderby\" data-id=\"" + val + "\" data-coltype=\"orderby\"></li>" )
              .html( remove_me + ' ' +val )
              .appendTo( ol );
  }

  function add_all_order_by_columns(use_applied) {
    var ol = jQuery('#ordsol');
    var func_cols = columns_used_in_functions();
    var use_cols;
    if(use_applied && use_applied === true) {
      use_cols = order_by_array.slice(0);
    }
    else {
      use_cols = column_array;
    }
    ol.empty();
    order_by_array = [];
    jQuery.each(use_cols, function(i,e) {
      if(func_cols.indexOf(e) === -1) {
        order_by_array.push(e);
        jQuery( "<li class=\"draggable-orderby\" data-id=\"" + e + "\" data-coltype=\"orderby\"></li>" )
                  .html( remove_me + ' ' +e )
                  .appendTo( ol );
      }
    });

    write_array_to_form('orderby');
  }

  function clear_order_by_columns() {
    var ol = jQuery('#ordsol');
    ol.empty();
    order_by_array = [];
    write_array_to_form('orderby');
  }
  // END: order_by handlers.

  // Store the final choices in the form.
  function apply_calculations() {
    if(functions_applied.length === 0 && group_by_array.length === 0 && order_by_array.length === 0) {
      alert('No function and/or Group by and/or Order by columns were selected.\nselect function or group by columns please');
      return;
    }
    write_array_to_form('groupapply');
    write_array_to_form('funcapply');
    alert('The selected function and/or group by columns have been applied');
  }

  // Public methods and properties:
  return {
    showBox: showBox,
    function_dropdown_changed: function_dropdown_changed,
    add_function: add_function,
    add_group_by_column: add_group_by_column,
    add_all_group_by_columns: add_all_group_by_columns,
    clear_group_by_columns: clear_group_by_columns,
    add_order_by_column: add_order_by_column,
    add_all_order_by_columns: add_all_order_by_columns,
    clear_order_by_columns: clear_order_by_columns,
    apply_calculations: apply_calculations
  };

}) ();

// -----------------------------------------------------------------------

// function ArrayList()
// {
//     this.aList = [];
// }
// 
// ArrayList.prototype.Count = function ()
// {
//     return this.aList.length;
// }
// 
// ArrayList.prototype.Add = function (object)
// {
//     //objects are placed at the end of array
//     this.aList.push(object);
// }
// 
// ArrayList.prototype.GetAt = function (index)
// {
//     if(index > -1 && index < this.aList.length)
//         return this.aList[index];
//     else
//         return undefined; //index out of bounds
// }
// 
// ArrayList.prototype.Clear = function ()
// {
//     this.aList = [];
// }
// 
// ArrayList.prototype.IndexOf = function (object, startIndex)
// {
//     var m_count   = this.aList.length;
//     var m_returnValue = -1;
//     if(startIndex > -1 && startIndex < m_count) {
//         var i = startIndex;
//         while(i < m_count) {
//             if(this.aList[i] == object) {
//                 m_returnValue = i;
//                 break;
//             }
//             i++;
//         }
//     }
//     return m_returnValue;
// }
// 
// ArrayList.prototype.Remove = function (object) //index must be a number
// {
//     var m_count = this.aList.length;
//     var m_returnValue = -1;
//     if(m_count > 0)
//     {
//         var i = 0;
//         while(i < m_count)
//         {
//             if(this.aList[i] == object)
//             {
//                 m_returnValue = i;
//                 break;
//             }
//             i++;
//         }
//         switch(m_returnValue)
//         {
//             case 0:
//                 this.aList.shift();
//                 break;
//             case m_count - 1:
//                 this.aList.pop();
//                 break;
//             default:
//                 var head = this.aList.slice(0, m_returnValue);
//                 var tail = this.aList.slice(m_returnValue + 1);
//                 this.aList = head.concat(tail);
//                 break;
//         }
//     }
//     /*if(m_count > 0 && index > -1 && index < this.aList.length) {
//         switch(index) {
//             case 0:
//                 this.aList.shift();
//                 break;
//             case m_count - 1:
//                 this.aList.pop();
//                 break;
//             default:
//                 var head = this.aList.slice(0, index);
//                 var tail = this.aList.slice(index + 1);
//                 this.aList = head.concat(tail);
//                 break;
//         }
//     } */
// }


var selected_img = null;

var calculation_img = null;
var temp_numeric_cols_array;

//var function_map = null;

function ds_getLeft(el) {
    var temp = el.offsetLeft;
    el = el.offsetParent;
    while(el) {
       temp += el.offsetLeft;
       el = el.offsetParent;
    }
    return temp;
}
 
 function ds_getTop(el) {
    var temp = el.offsetTop;
    el = el.offsetParent;
    while(el) {
       temp += el.offsetTop;
       el = el.offsetParent;
    }
    return temp;
 }

 function ds_show(t, innerStr){
     selected_img = t;
     var ds_ce = document.getElementById('conClass');
     ds_ce.innerHTML = innerStr;
     ds_ce.style.display = '';
     
     the_left = ds_getLeft(t) + t.offsetWidth;
     the_top = ds_getTop(t) + t.offsetHeight;
     ds_ce.style.left = the_left + 'px';
     ds_ce.style.top = the_top + 'px';
     ds_ce.scrollIntoView(true);
     
     var orVals = document.getElementById('or_values');
     var hiddenId = "hidden-" + t.id.split("-")[1];
     //alert(hiddenId);
     
     orVals.value = document.getElementById(hiddenId).value;
}
 
function ds_hide() {
    var divToHide = document.getElementById('conClass');
    divToHide.style.display = 'none';
}

function ds_hide_calc() {
    var divToHide = document.getElementById('calculations');
    divToHide.style.display = 'none';
}

function ds_add_value(){ 
    var select_id = selected_img.id.toString().split("-")[1];
    var select = document.getElementById(select_id);
    var orSelectedIndex = select.selectedIndex;
    var orSelectedValue = select[orSelectedIndex].value;
  
    var hiddenName = "hidden-" + select_id.toString();
    var hiddenField = document.getElementById(hiddenName);
    var hiddenValue = hiddenField.value;
    if(orSelectedValue=="" || orSelectedValue==null) {
        alert("Select a value to add please!");
    }else {
        if(hiddenValue=="" || hiddenValue==null) {
            hiddenField.value = orSelectedValue;
            document.getElementById('or_values').value = hiddenField.value;
        }
        else {
            if(hiddenValue.indexOf(orSelectedValue)== -1) {
                var hiddenStr = hiddenValue + "," + orSelectedValue;
                var instr = hiddenValue.replace(/,/g,",\n");
                instr += ",\n" + orSelectedValue;
                hiddenField.value = hiddenStr;
                document.getElementById('or_values').value = instr;
            }else {
                alert("The value has been already added!");
            }
        }
    }
}

function ds_remove_value() {
    var select_id = selected_img.id.toString().split("-")[1];
    var select = document.getElementById(select_id);
    var orSelectedIndex = select.selectedIndex;
    var orSelectedValue = select[orSelectedIndex].value;
    
    var hiddenName = "hidden-" + select_id.toString();
    var hiddenField = document.getElementById(hiddenName);
    var hiddenValue = hiddenField.value;
    
    var strVal = "";
    if(orSelectedValue=="" || orSelectedValue==null) {
        alert("select a value to be removed please!");
    }else {
        if((hiddenValue == "" || hiddenValue == null)) {
            alert("The OR values list is currently empty!");
        }else {
            if(hiddenValue.indexOf(orSelectedValue)!= -1) {
                if(hiddenValue.indexOf(",")!= -1) {
                    var strArray = hiddenValue.replace(/\n/g,'').split(",");
                    for(var i=0; i<strArray.length;i++) {
                        if(strArray[i]!=orSelectedValue){
                            if(strVal=="") {
                                strVal += strArray[i];
                            }else {
                                strVal += ",\n" + strArray[i];
                            }
                        }
                    }
                    document.getElementById(hiddenName).value = strVal.replace(/\n/g,'');
                    document.getElementById('or_values').value = strVal;
                }else {
                    document.getElementById(hiddenName).value = "";
                    document.getElementById('or_values').value = "";  
                }  
            }else {
                alert("Select a value that is in the current OR values list please!");
            }
        }
    }
}

//Functions and calculations

// function show_calculations(t, str) {
//     calculation_img = t;
//     //alert(document.getElementById('order_by_hidden_field').value);
//     var ds_calc = document.getElementById('calculations');
//     ds_calc.innerHTML = str;
//     ds_calc.style.display = '';
//      
//     the_left = "50"; //ds_getLeft(t)- (40 + 'px'); //+ t.offsetWidth;
//     the_top = "30"; //ds_getTop(t) + t.offsetHeight;
//     ds_calc.style.left = the_left + 'px';
//     ds_calc.style.top = the_top + 'px';
//     ds_calc.style.height = "360px";
//     ds_calc.style.width = "910px";
//     ds_calc.scrollIntoView(true);
//     
//     document.getElementById('group_by_columns_field').value = document.getElementById('group_by_hidden_field').value;
//     document.getElementById('order_by_columns_field').value = document.getElementById('order_by_hidden_field').value;
//     var apply_func_hidden_value = document.getElementById('apply_functions_hidden_field').value;
//     
//     if(apply_func_hidden_value != "")
//     {
//         if(function_map.Count() == 0)
//         {
//             if(apply_func_hidden_value.indexOf("|") != -1)
//             {
//                 func_array = apply_func_hidden_value.split("|");
//                 for(var i = 0; i < func_array.length; i++)
//                 {
//                     function_map.Add(func_array[i]);
//                 }
//             }
//             else
//             {
//                 function_map.Add(apply_func_hidden_value);
//             }
//         }
//         
//         for(var k=0; k < function_map.Count(); k++)
//         {
//             var func_col_val = function_map.GetAt(k);
//             var function_table = document.getElementById('function_table');
//             
//             var function_row = document.createElement('tr');
//             var function_td = document.createElement('td');
//             function_td.id = func_col_val;
//             function_td.innerHTML = " <img src='/images/expanded.png' onclick='remove_function(this.parentNode)' style='cursor:pointer;'/>" + func_col_val;
//             function_row.appendChild(function_td);
//             function_table.appendChild(function_row);
//         }
//     }
// }
// 
// function add_group_by_column() {
//     var group_by_dropdown = document.getElementById('group_by_dropdown');
//     var selectedIndex = group_by_dropdown.selectedIndex;
//     var selectedValue = group_by_dropdown[selectedIndex].value;
//     
//     var hidden_group_by_field = document.getElementById('group_by_hidden_field');
//     var hidden_group_by_field_value = hidden_group_by_field.value;
//     var startReg = /^\s+/;
//     var endReg = /\s+$/;
//     var checkReg;
//      
//     if(group_by_dropdown.disabled == true) {
//         alert("Adding of columns to group by is not allowed, the source of columns is disabled!");
//     }else {
//         if(selectedValue == "" || selectedValue == null) {
//             alert("Select a column to add please!");
//         }else {
//             if(function_map.Count() == 0)
//             {
//                 alert("You must add at least one function to add group by columns!");
//                 return;
//             }
//             else
//             {
//                 if(hidden_group_by_field_value == "" || hidden_group_by_field_value == null) {
//                     hidden_group_by_field.value = selectedValue;
//                     document.getElementById('group_by_columns_field').value = hidden_group_by_field.value;
//                     //Check the order by columns list to see if it has columns other than this one
//                     var hidden_order_by_field = document.getElementById('order_by_hidden_field');
//                     var hidden_order_by_field_value = hidden_order_by_field.value;
//                     var order_by_columns_field = document.getElementById('order_by_columns_field');
//                     if(hidden_order_by_field_value != "") {
//                         if(hidden_order_by_field_value.indexOf(",") != -1) {
//                             //alert(hidden_order_by_field_value);
//                             var columnsArray = hidden_order_by_field_value.replace(/\n/g,'').split(",");
//                             var strColumns = "";
//                             //alert(columnsArray.length);
//                             for(var i = 0; i < columnsArray.length; i++) {
//                                 selectedValue = selectedValue.replace(startReg,'').replace(endReg,'');
//                                 var col = columnsArray[i].replace(startReg,'').replace(endReg,'');
//                                 if(col.indexOf(/\s/) != -1)
//                                     col = col.split(/\s/)[0].replace(startReg,'').replace(endReg,'');
//                                 if(selectedValue.indexOf(col) != -1) {
//                                     strColumns += columnsArray[i];
//                                 }
//                             }
//                             document.getElementById('order_by_hidden_field').value = strColumns.replace(/\n/g,'');
//                             document.getElementById('order_by_columns_field').value = strColumns;
//                         }else {
//                             selectedValue = selectedValue.replace(startReg,'').replace(endReg,'');
//                             hidden_order_by_field_value = hidden_order_by_field_value.replace(startReg,'').replace(endReg,'');
//                             if(hidden_order_by_field_value.indexOf(/\s/) != -1) 
//                                 hidden_order_by_field_value = hidden_order_by_field_value.split(/\s/)[0].replace(startReg,'').replace(endReg,'');
//                             if(selectedValue.indexOf(hidden_order_by_field_value) == -1) {
//                                 hidden_order_by_field.value = "";
//                                 order_by_columns_field.value = "";
//                             }
//                         }                        
//                     }
//                 }else {
//                     checkReg = new RegExp("\\b"+selectedValue+"\\b");
//                     if(!checkReg.match(hidden_group_by_field_value)) {
//                         var hidden_group_by_string = hidden_group_by_field_value + "," + selectedValue;
//                         var instr = hidden_group_by_field_value.replace(/,/g,",\n");
//                         instr += ",\n" + selectedValue;
//                         hidden_group_by_field.value = hidden_group_by_string;
//                         document.getElementById('group_by_columns_field').value = instr;
//                     }else {
//                         alert("The column has been added already!");
//                     }
//                 }
//             }
//         }
//     }
// }
// 
// function add_all_group_by_columns() {
//   var group_by_dropdown     = document.getElementById('group_by_dropdown');
//   var hidden_group_by_field = document.getElementById('group_by_hidden_field');
//   var texts                 = [];
// 
//   if(group_by_dropdown.disabled == true) {
//     alert("Adding of columns to group by is not allowed, the source of columns is disabled!");
//     return;
//   }
//   if(function_map.Count() === 0)
//   {
//     alert("You must add at least one function to add group by columns!");
//     return;
//   }
//   for (var i=0, n=group_by_dropdown.options.length;i<n;i++) {
//     if (group_by_dropdown.options[i].text &&
//         function_map.IndexOf("SUM("+group_by_dropdown.options[i].text+")", 0) === -1 &&
//         function_map.IndexOf("AVG("+group_by_dropdown.options[i].text+")", 0) === -1 &&
//         function_map.IndexOf("MIN("+group_by_dropdown.options[i].text+")", 0) === -1 &&
//         function_map.IndexOf("MAX("+group_by_dropdown.options[i].text+")", 0) === -1) {
//       texts.push(group_by_dropdown.options[i].text);
//     }
//   }
//   hidden_group_by_field.value = texts.join(",");
//   document.getElementById('group_by_columns_field').value = texts.join("\n");
// }
// 
// function add_all_order_by_columns() {
//   var order_by_dropdown     = document.getElementById("order_by_dropdown");
//   var hidden_order_by_field = document.getElementById("order_by_hidden_field");
//   var texts                 = [];
// 
//   for (var i=0, n=order_by_dropdown.options.length;i<n;i++) {
//     if (order_by_dropdown.options[i].text &&
//         function_map.IndexOf("SUM("+order_by_dropdown.options[i].text+")", 0) === -1 &&
//         function_map.IndexOf("AVG("+order_by_dropdown.options[i].text+")", 0) === -1 &&
//         function_map.IndexOf("MIN("+order_by_dropdown.options[i].text+")", 0) === -1 &&
//         function_map.IndexOf("MAX("+order_by_dropdown.options[i].text+")", 0) === -1) {
//       texts.push(order_by_dropdown.options[i].text);
//     }
//   }
//   hidden_order_by_field.value = texts.join(",");
//   document.getElementById('order_by_columns_field').value = texts.join("\n");
// }
// 
// function remove_group_by_column() {
//     var group_by_dropdown = document.getElementById('group_by_dropdown');
//     var selectedIndex = group_by_dropdown.selectedIndex;
//     var selectedValue = group_by_dropdown[selectedIndex].value;
//     
//     var hidden_group_by_field = document.getElementById('group_by_hidden_field');
//     var hidden_group_by_field_value = hidden_group_by_field.value;
//     //alert(hidden_group_by_field_value.replace(/\n/g,''));
//     
//     var startReg = /^\s+/;
//     var endReg = /\s+$/;
//     
//     var strColumns = ""
//     if(hidden_group_by_field_value == "" || hidden_group_by_field_value == null) {
//         alert("The group by columns list is empty!");
//     }else {
//         if(selectedValue == "" || selectedValue == null) {
//             alert("Select a column to be removed please!");
//         }else {
//             if(hidden_group_by_field_value.indexOf(selectedValue) == -1) {
//                 alert("Select a column that is in the group by columns list!");
//             }else {
//                 if(hidden_group_by_field_value.indexOf(",") != -1) {
//                     var columnsArray = hidden_group_by_field_value.replace(/\n/g,'').split(",");
//                     for(var i = 0; i < columnsArray.length; i++) {
//                         if(columnsArray[i] != selectedValue) {
//                             if(strColumns == "")
//                                 strColumns += columnsArray[i];
//                             else
//                                 strColumns += ",\n" + columnsArray[i];
//                         }
//                     }
//                     document.getElementById('group_by_hidden_field').value = strColumns.replace(/\n/g,'');
//                     document.getElementById('group_by_columns_field').value = strColumns;
//                 }else {
//                     document.getElementById('group_by_hidden_field').value = "";
//                     document.getElementById('group_by_columns_field').value = "";
//                 }
//                 //remove the corresponding order by column
//                 remove_order_by_column_from_group_by_column(selectedValue);
//             }
//         }
//     }
// }
// 
// function add_order_by_column() {
//     var order_by_dropdown = document.getElementById("order_by_dropdown");
//     var selectedValue = order_by_dropdown.options[order_by_dropdown.selectedIndex].value;
//     
//     var oder_by_criteria = document.getElementById("order_by_criteria");
//     var order_by_criteria_value = document.getElementById("order_by_criteria").options[document.getElementById("order_by_criteria").selectedIndex].value;
//     
//     var hidden_order_by_field = document.getElementById("order_by_hidden_field");
//     var hidden_order_by_field_value = hidden_order_by_field.value;
//     
//     //group by columns
//     var hidden_group_by_field = document.getElementById('group_by_hidden_field');
//     var hidden_group_by_field_value = hidden_group_by_field.value;
//     
//     if(selectedValue =="" || selectedValue == null) {
//         alert("Select a column to be added please!");
//     }else {
//         if(hidden_group_by_field_value == "" || hidden_group_by_field_value == null) {
//             if(hidden_order_by_field_value == "" || hidden_order_by_field_value == null) {
//                 if(order_by_criteria_value != "" || order_by_criteria_value != null) {
//                     hidden_order_by_field.value = selectedValue + " " + order_by_criteria_value;
//                 }else {
//                     hidden_order_by_field.value = selectedValue;
//                 }
//                 document.getElementById("order_by_columns_field").value = hidden_order_by_field.value;
//             }else {
//                 if(hidden_order_by_field_value.indexOf(selectedValue) == -1) {
//                     var hidden_order_by_string = hidden_order_by_field_value + "," + selectedValue + " " + order_by_criteria_value;
//                     var instr = "";
//                     if(order_by_criteria_value != "" ) {
//                         instr += hidden_order_by_field_value.replace(/,/g,",\n");
//                         instr += ",\n" + selectedValue + " " + order_by_criteria_value;
//                     }else {
//                         instr += hidden_order_by_field_value.replace(/,/g,",\n");
//                         instr += ",\n" + selectedValue;
//                     }
//                     hidden_order_by_field.value = hidden_order_by_string;    
//                     document.getElementById("order_by_columns_field").value = instr;
//                 }else {
//                     alert("The column has been already added!");
//                 }
//             }//
//         }else {
//             //Test if the order by column selected is in the group by columns list
//             if(hidden_group_by_field_value.indexOf(selectedValue) == -1) {
//                 alert("Select a column that is in the group by columns list please!")
//             }else {
//                 if(hidden_order_by_field_value == "" || hidden_order_by_field_value == null) {
//                     if(order_by_criteria_value != "" || order_by_criteria_value != null) {
//                         hidden_order_by_field.value = selectedValue + " " + order_by_criteria_value;
//                     }else {
//                         hidden_order_by_field.value = selectedValue;
//                     }
//                     document.getElementById("order_by_columns_field").value = hidden_order_by_field.value;
//                 }else {
//                     if(hidden_order_by_field_value.indexOf(selectedValue) == -1) {
//                         var hidden_order_by_string = hidden_order_by_field_value + "," + selectedValue + " " + order_by_criteria_value;
//                         var instr = "";
//                         if(order_by_criteria_value != "" ) {
//                             instr += hidden_order_by_field_value.replace(/,/g,",\n");
//                             instr += ",\n" + selectedValue + " " + order_by_criteria_value;
//                         }else {
//                             instr += hidden_order_by_field_value.replace(/,/g,",\n");
//                             instr += ",\n" + selectedValue;
//                         }
//                         hidden_order_by_field.value = hidden_order_by_string;    
//                         document.getElementById("order_by_columns_field").value = instr;
//                     }else {
//                         alert("The column has been already added!");
//                     }
//                 }//
//             }
//         }
//     }
// }
// 
// function remove_order_by_column() {
//     var order_by_dropdown = document.getElementById("order_by_dropdown");
//     var selectedValue = order_by_dropdown.options[order_by_dropdown.selectedIndex].value;
//     
//     var hidden_order_by_field = document.getElementById("order_by_hidden_field");
//     var hidden_order_by_field_value = hidden_order_by_field.value;
//     
//     var strColumns = ""
//     
//     if(hidden_order_by_field_value == "" || hidden_order_by_field_value == null) {
//         alert("The order by columns list is empty!");
//     }else {
//         if(selectedValue == "" || selectedValue == null) {
//             alert("Select a column to be removed please!");
//         }else {
//             if(hidden_order_by_field_value.indexOf(selectedValue) == -1) {
//                 alert("Select a column that is in the order by columns list!");
//             }else {
//                 if(hidden_order_by_field_value.indexOf(",") != -1) {
//                     var columnsArray = hidden_order_by_field_value.replace(/\n/g,'').split(",");
//                     for(var i = 0; i < columnsArray.length; i++) {
//                         if(columnsArray[i].indexOf(selectedValue)== -1) {
//                             if(strColumns == "")
//                                 strColumns += columnsArray[i];
//                             else
//                                 strColumns += ",\n" + columnsArray[i];
//                         }
//                     }
//                     document.getElementById('order_by_hidden_field').value = strColumns.replace(/\n/g,'');
//                     document.getElementById('order_by_columns_field').value = strColumns;
//                 }else {
//                     document.getElementById('order_by_hidden_field').value = "";
//                     document.getElementById('order_by_columns_field').value = "";
//                 }
//             }
//         }
//     }
// }
// 
// function remove_order_by_column_from_group_by_column(column_name) {
//     var selectedValue = column_name;
//     
//     var hidden_order_by_field = document.getElementById("order_by_hidden_field");
//     var hidden_order_by_field_value = hidden_order_by_field.value;
//     
//     var startReg = /^\s+/;
//     var endReg = /\s+$/;
//     
//     var strColumns = ""
//     if(hidden_order_by_field_value != "" || hidden_order_by_field_value != null) {
//         if(hidden_order_by_field_value.indexOf(selectedValue) != -1) {
//             if(hidden_order_by_field_value.indexOf(",") != -1) {
//                 var columnsArray = hidden_order_by_field_value.replace(/\n/g,'').split(",");
//                 for(var i = 0; i < columnsArray.length; i++) {
//                     selectedValue = selectedValue.replace(startReg,'').replace(endReg,'');
//                     var col = columnsArray[i].replace(startReg,'').replace(endReg,'');
//                     if(col.indexOf(" ASC") != -1 || col.indexOf(" DESC") != -1)
//                         col = col.split(/\s/)[0].replace(startReg,'').replace(endReg,'');
//                     if(selectedValue.indexOf(col)== -1) {
//                         if(strColumns == "")
//                             strColumns += columnsArray[i];
//                         else
//                             strColumns += ",\n" + columnsArray[i];
//                     }
//                 }
//                 document.getElementById('order_by_hidden_field').value = strColumns.replace(/\n/g,'');
//                 document.getElementById('order_by_columns_field').value = strColumns;
//             }else {
//                 document.getElementById('order_by_hidden_field').value = "";
//                 document.getElementById('order_by_columns_field').value = "";
//             }
//         }
//     }
// }
// 
// function function_dropdown_changed(obj) {
//     cols_drop = document.getElementById('columns_dropdown');
//     if(obj.options[obj.selectedIndex].value == "MAX" || obj.options[obj.selectedIndex].value == "MIN") {
//         removeOptions(cols_drop);
//         var str = document.getElementById('numeric_cols_hidden_field').value;
//         obj_cols_array = getArrayFromHiddenFieldValue(str);
//         //obj_cols_array[obj_cols_array.length] = "id";
//         addOptions(cols_drop, obj_cols_array);
//         
//         document.getElementById('group_by_dropdown').disabled = true;
//         document.getElementById('columns_dropdown').disabled = false;
//         
//     }else if(obj.options[obj.selectedIndex].value == "COUNT") {
//         document.getElementById('group_by_dropdown').disabled = false;
//         document.getElementById('columns_dropdown').disabled = true;
//     }else if(obj.options[obj.selectedIndex].value == "SUM" || obj.options[obj.selectedIndex].value == "AVG") {
//         removeOptions(cols_drop);
//         var str = document.getElementById('numeric_cols_hidden_field').value;
//         obj_cols_array = getArrayFromHiddenFieldValue(str);
//         addOptions(cols_drop, obj_cols_array);
//         document.getElementById('group_by_dropdown').disabled = false;
//         document.getElementById('columns_dropdown').disabled = false;
//     }
// }
// 
// function add_function() {
//     var func_value = document.getElementById('function_dropdown').options[document.getElementById('function_dropdown').selectedIndex].value;
//     if(func_value.toString() == "" || func_value == null) 
//     {
//         alert("select a function please!");
//     }
//     else 
//     {
//         var column_value = document.getElementById('columns_dropdown').options[document.getElementById('columns_dropdown').selectedIndex].value;
//         if(func_value.indexOf("COUNT") == -1 && (column_value.toString()=="" || column_value == null))
//         {
//             alert("select a column for the function selected please!");
//         }
//         else
//         {
//             var func_column_value = "";
//             if(func_value.indexOf("COUNT") != -1)
//                 func_column_value += "COUNT(*)";
//             else
//                 func_column_value += func_value + "(" + column_value + ")";
//             var function_table = document.getElementById('function_table');
//             if(function_map.IndexOf(func_column_value, 0) != -1)
//                 alert("The function has been already added!");
//             else 
//             {
//                 function_map.Add(func_column_value);
//                 var function_row = document.createElement('tr');
//                 var function_td = document.createElement('td');
//                 function_td.id = func_column_value;
//                 function_td.innerHTML = " <img src='/images/expanded.png' onclick='remove_function(this.parentNode)' style='cursor:pointer;'/>" + func_column_value;
//                 function_row.appendChild(function_td);
//                 function_table.appendChild(function_row);
//                 //alert(function_map.Count());
//             }
//         }
//     }
// }
// 
// function remove_function(td)
// {
//     var func_column_val = td.id;
//     function_map.Remove(func_column_val);
//     removeRow(document.getElementById(func_column_val).parentNode);
// }
// 
// function apply_calculations() {
//     var group_by_field_value = document.getElementById('group_by_columns_field').value;
//     var func_select =  document.getElementById('function_dropdown');
//     var func_select_value = func_select.options[func_select.selectedIndex].value;
//    
//     var order_by_cols = document.getElementById("order_by_columns_field").value;
//     
//     if(function_map.Count() == 0 && group_by_field_value == "" && order_by_cols == "")
//     {
//         alert("No function and/or Group by and/or Order by columns were selected.\nselect function or group by columns please");
//         return;
//     }
//     else
//     {
//         var str_cat = ""
//         for(var  i = 0; i< function_map.Count(); i++)
//         {
//             if(str_cat == "")
//                 str_cat += function_map.GetAt(i);
//             else
//                 str_cat += "|" + function_map.GetAt(i);
//         }
//         document.getElementById('apply_functions_hidden_field').value = str_cat;
//         
//         //set the apply group by hidden field value
//         document.getElementById('apply_group_by_hidden_field').value = document.getElementById('group_by_hidden_field').value;
//         alert("The selected function and/or group by columns have been applied");
//         ds_hide_calc();
//         
//     }
// }
// 
// function removeOptions(selectBox) {
//     var i;
//     for(i=selectBox.options.length-1;i>=0;i--) {
//         selectBox.remove(i);
//     }
// }
// 
// function getOptions(selectBox) {
//     var optionsArray = selectBox.options;
//     return optionsArray;
// }
// 
// function addOptions(selectBox, obj_array) {
//     var opt = document.createElement("OPTION");
//     opt.text = "";
//     opt.value = "";
//     selectBox.options.add(opt);
//     for(var i=0;i<obj_array.length;i++) {
//         var optn = document.createElement("OPTION");
//         optn.text = obj_array[i];
//         optn.value = obj_array[i];
//         selectBox.options.add(optn);
//     }
// }
// 
// function getArrayFromHiddenFieldValue(str) {
//     //var str = document.getElementById('numeric_cols_hidden_field').value;
//     var colsArray = str.split(",");
//     return colsArray;
// }
// 
// //method to remove all table rows
// function removeRow(tr)
// {
//     tr.parentNode.removeChild(tr);
// }
