// Script for Home layout.
// -----------------------

// Block use of $ for jQuery to avoid conflict with Prototype.
jQuery.noConflict();

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


function set_grid_text(text)
{

  if(text.indexOf("href=")== -1)
  {
    document.getElementById("awgrid_img").style.visibility = "visible";
    info_img = document.getElementById("info_img");
    info_text = document.getElementById("grid_cell_info_body");
    info_text.innerHTML = text;
  }


}

function show_grid_cell_info()
{
  info = document.getElementById("grid_form");
  info.style.visibility = "visible";
}

function close_grid_form()
{
  info = document.getElementById("grid_form");
  info.style.visibility = "hidden";

}


var info_timer;
var info_toggle_count = 0;



function info_img_toggle()
{

  info_toggle_count += 1;
  info_img = document.getElementById("info_img");
  if (info_img.style.visibility == "visible"){
    info_img.style.visibility = "hidden";
  }
  else {
    info_img.style.visibility = "visible";
  }

  if(info_toggle_count == 4){
    clearInterval(info_timer);
    info_toggle_count = 0;
      info_img.style.visibility = "visible";}  
}

function animate_info()
{
  info_timer = setInterval(info_img_toggle, 500);

}


var header_is_hidden = false;
var home_header_normal_position = null;
var home_header = null;
var grid = null;

function add_info_sticker(info)
{
  info_img = document.getElementById("info_sticker_img");
  info_text = document.getElementById("info_sticker_info");
  info_img.style.visibility = "visible";
  info_text.style.visibility = "visible";
  info_text.innerHTML = info;

}

function show_info()
{
  info = document.getElementById("info_form");
  info.style.visibility = "visible";
  clearInterval(info_timer);

}

function close_info_form()
{
  info = document.getElementById("info_form");
  info.style.visibility = "hidden";

}


function clear_info()
{
  info_img = document.getElementById("info_img");
  info_text = document.getElementById("info_body");
  info_img.style.visibility = "hidden";
  info_text.innerHTML = "";

}

function set_info(info)
{
  info_img = document.getElementById("info_img");
  info_text = document.getElementById("info_body");
  info_img.style.visibility = "visible";
  info_text.innerHTML = info;
  animate_info();

}


function clear_info_sticker()
{
  info_img = document.getElementById("info_sticker_img");
  info_text = document.getElementById("info_sticker_info");
  info_img.style.visibility = "hidden";
  info_text.style.visibility = "hidden";
  info_text.innerHTML = "";

}

function close_message_form()
{
  document.getElementById("message_form").style.visibility = "hidden";
  window.frames[0].window.close_envelopes();
}



function hide_home_header(hider)
{
  if(!header_is_hidden)
  {
    adjust_menu("visible");
    hider.innerHTML = "show header";
    header_is_hidden = true;
    document.getElementById("img_header_hider").src = "/images/home/show.png";
    home_header = document.getElementById("home_header");
    home_header_normal_pos_style = home_header.style.position;
    home_header.style.visibility = "hidden";
    home_header.style.position = "absolute";
    home_header.style.top = "0px";
    document.getElementById("l3menus_table").style.height = "500px";
    if(window.frames[1].grid !== null)
    {
      window.frames[1].grid.setSize(current_grid_width, grid_max_height); 
      current_grid_height = grid_max_height;
      var content_container = document.getElementById('content_container');
      if(content_container !== null) {
        content_container.style.height = "500px";
      }
    }
  }

  else
  {
    adjust_menu("hidden");
    hider.innerHTML = "hide header";
    header_is_hidden = false;
    document.getElementById("img_header_hider").src = "/images/home/hide.png";
    home_header.style.visibility = "visible";
    home_header.style.position = home_header_normal_pos_style;
    document.getElementById("l3menus_table").style.height = "388px";
    if(window.frames[1].grid !== null)
    {
      window.frames[1].grid.setSize(current_grid_width,grid_min_height);
      current_grid_height = grid_min_height;
      var content_container = document.getElementById('content_container');
      if(content_container !== null) {
        content_container.style.height = "388px";
      }
    }
  }


}



function add_sizing()
{
  // add_sizing_cell("l3_menus_container_parent",false);
  // add_sizing_cell("content_container",true);
}


  // Ensure the level 3 menu-containing div is at optimum height:
  var l3m_set_height = function() {
    var head = jQuery('#tableOuter').offset().top + (jQuery('#tableOuter').height() * 2);
    var foot = jQuery('#footer_table').offset().top;
    var nheight = (foot - head) - 30;
    jQuery('#l3_menus_container_parent div').height(nheight);
  };

  jQuery(document).ready(function() {

    // Set l3 menu height on a timeout - give browser time to construct page.
    setTimeout(function() {
        l3m_set_height();
    }, 500);

    // Resize the l3 menu container on page resize.
    jQuery(window).bind('resize', function() {
      l3m_set_height();
    });
  });

