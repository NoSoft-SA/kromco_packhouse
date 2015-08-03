// Script for Content layout.
// --------------------------

// Block use of $ for jQuery to avoid conflict with Prototype.
jQuery.noConflict();

// Are we in a sub-frame of contentframe?
function inSubFrame() {
  var isSub = ('contentFrame' !== self.name && '' !== self.name);
  if (top.frames.length === 1) {
    return false;
  }
  else {
    return isSub;
  }
}

// Called on click of jqgridminimize div. Zooms the page back to normal.
function jqGridMinimize() {
  var cf = jQuery('#contentFrame', top.document);
  var isSub = ('contentFrame' !== self.name);
  var sf = null;
  if(isSub) {sf = jQuery('#'+self.name, top.frames[1].document);}
  jQuery(cf).removeClass('zoomout');
  if(isSub) {jQuery(sf).removeClass('zoomoutsub'); }
  document.getElementById("jqgridminimize").style.visibility = "hidden";
}

// If this subframe has been zoomed out make sure the minimise button is available.
function jqGridMinButtonRequired() {
  if(self.name == '') { return false; }
  if(top.frames.length > 1) {
    var sf;
    if('contentFrame' == self.name) {
      sf = jQuery('#'+self.name, top.document);
    }
    else {
      sf = jQuery('#'+self.name, top.frames[1].document);
    }
    if(!jQuery('#contentFrame').fullScreen()) {
      if('0px' == sf.css('top')) {document.getElementById("jqgridminimize").style.visibility = "visible";}
    }
  }
}

// Show and fade a flash notice
function show_and_fade_flash( text ) {
  jQuery('#notice').remove();
  jQuery('<div id="notice">').text(text).prependTo('#maine');
  jQuery('#notice').delay(10000).fadeOut(1500, function() { jQuery('#notice').remove(); });
}

// Turn the jqgridminimize div into a jQuery UI button.
// Check if this page needs the minimise button to be visible.
jQuery(document).ready(function() {
  jQuery('#jqgridminimize').button({ icons: { primary: "ui-icon-zoomin" } });
  jqGridMinButtonRequired();
  jQuery(".multiselect").multiselect();
  jQuery(".chosen-select").chosen({disable_search_threshold: 10, allow_single_deselect: true, search_contains: true});
});

function send_fields_to_popup_window(link,send_fields) {
  var split_send_fields = send_fields.split(",");
  var send_fields_params = "";

  for(j=0; j < split_send_fields.length; j++) {
    var form_send_field = null;
    if(window.parent.frames[1] !== undefined) {
      form_send_field = window.parent.frames[1].document.getElementById(split_send_fields[j]);
    }

    if(form_send_field === null) {
      form_send_field = document.getElementById(split_send_fields[j]);
    }

    if(form_send_field === null) {
      form_send_field = window.parent.document.getElementById(split_send_fields[j]);
    }

    if(form_send_field !== null) {
      send_fields_params += "&" + split_send_fields[j] + "=" + form_send_field.value;
    }
  }
  var url = link.id + send_fields_params;
  open_window_link(url);
}

function call_open_window(id)
{
  open_window_link(id.id);
}

function set_child_form_caption(form_id,caption)
{
  //alert(caption);
  val = document.getElementById(form_id);
  if(val !== null) {
    val.innerHTML = caption;
  }
}

function is_outer_form()
{
  if(window.parent.document.getElementById('home_header'))
  {
    return true;
  }
  else
  {
    return false;
  }
}

function clear_info()
{
  //         info_img = document.getElementById("info_img");
  //         info_text = document.getElementById("info_body");
  //         info_img.style.visibility = "hidden";
  //         info_text.innerHTML = "";

}


function show_element(id)
{
  elt = document.getElementById(id);
  elt.style.display = "inline";

}

function make_element_visible(id)
{
  elt = document.getElementById(id);
  elt.style.visibility = "visible";

}


function show_action_image(clicked_cell)
{

  var action_images = clicked_cell.parentNode.getElementsByTagName("img");
  if (action_images !== null && action_images.length > 0)
  {
    action_images[action_images.length - 1].style.visibility = "visible";
  }

}

