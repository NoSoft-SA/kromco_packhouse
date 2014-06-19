// JScript File
// VERSION 1 27/06/2008
//=======================================================================
//global variables or settings
//========================================================================
var images_root = "/images/";
var current_outer_tab;
var outer_tabs_container = "outerTabsContainer";
var inner_tabs_container = "innerTabsContainer";
var level3_tabs_container = "l3_menus_container";
var level3_tab_selected_color = "#d8d8d8";
var level3_tab_unselected_color = "white";
var level3_tab_hover_color = "whiteSmoke";
var current_inner_tab;
var active_l3_menu_image = null; 
var static_l3_image = images_root + "spinner_static.bmp";
var active_l3_image = images_root + "spinner.gif";
var login_state = false;
var content_header_caption = null;


var l3menus_hidden =false;

//level 1 menu images
var l1_menu_left_td_image = images_root + "tlo_menu_active_3.gif";
var l1_menu_left_img_image = images_root + "_.gif";
var l1_menu_spacer_image = images_root + "spacer_menu_3.gif";
var l1_menu_remainder_image = images_root + "tlo_menu_active_3.gif";
var l1_menu_tab_image = images_root + "tlo_menu_active_3.gif";
var l1_menu_tab_open_hidden_programs = images_root+"open16.png";
//level 2 menu images
var l2_menu_left_td_image = images_root + "tlo_podmenu.gif";
var l2_menu_left_img_image = images_root + "_.gif";
var l2_menu_tab_image = images_root + "tlo_podmenu.gif";
var l2_menu_spacer_td_image = images_root + "tlo_podmenu.gif";
var l2_menu_spacer_img_image = images_root + "spacer_podmenu.gif";
var l2_menu_remainder_image = images_root + "tlo_podmenu.gif";


var trace = false;


var outer_tabs_background = "url(" + images_root + "tlo_menu_active_3.gif)";
var level2_tab_background = "url(" + images_root + "tlo_podmenu.gif)";
var level2_tab_selected_color = "white";

var outer_tab_selected_color = "#d8d8d8";
//****************************************

//******************************************************
var menu_list = new Array;
var  nawtylist = new Array();
var  gudlist_programs = new Array();
//******************************************************
var  goodlist_inner_tabs = new Array();
var goodlist_inner_names = new Array();
badlist_inner_tabs = new Array();
outer_tab_inuse ="";
  
//========================================================================
// lsiding panels values
var count_resize_div =0; 
var outside_int  ;
//========================================================================
// level3 arrays
var goodlist_l3_names = new Array();
var  l3_menu_calc = false; 
var l3_nawty_list = new Array();
var l3_tab_all ;
var from_bad_list = false;
//*=*=*=*=*=*=**=*=*=*=*=*=**=*=*=*=*=*=**=*=*=*=*=*=**=*=*=*=*=*=**=*=*
//=======================================================================
// menu data structure definitions:
//=======================================================================
//object to hold second and n level tabs
var  distinct_values_array = new Array (0);
var  filter_array =  new Array(0);
var filter_rules_tested = new Array();
var column_names_cco = new Array(0);
var hideshowcolumnnames = new Array(0);
var filter_array_grid_length = new Array(0);
var mcsColumnArrays = new Array();
var mcs_array =  new Array ();
var closed_window_filter = false;
function keepValuesAlive()
{
//  distinct_values_array = new Array (0);
//  filter_array =  new Array(0);
}

function InnerTab(display_text,url,image)
{

    this.Tabs = [];
    this.DisplayText = display_text;
    this.Url = url;
    this.AddTab = add_tab;
    this.Image = image;
}

//object to hold first level tabs
function OuterTab(display_text,url,image)
{

    this.Tabs = [];
    this.DisplayText = display_text;
    this.Url = url;
    this.AddTab = add_tab;
    this.LastTabIndex = '';
    this.Image = image;
    this.line_number = 1;

}

function add_tab(display_text,url,image)
{

    this.Tabs[display_text] = new InnerTab(display_text,url,image);

    if(trace)
    {
        alert(this.Tabs[display_text].DisplayText);
        alert('Added inner tab: ' + display_text + ' for tab: ' + this.DisplayText + ' current items are: ' +  this.Tabs.length);
        alert(this.Tabs[display_text].DisplayText);
       
    }
    
}

//this method performs a find on the first two levels of menus
function find_tab(id)
{

    found = false;
    tab = null;

        done:
        for(outer_tab_key in menu_structure.OuterTabs)
        {
          if (menu_structure.OuterTabs.hasOwnProperty(outer_tab_key))
          {
            outer_tab = menu_structure.OuterTabs[outer_tab_key];
            for(inner_tab_key in outer_tab.Tabs)
            {
              if (outer_tab.Tabs.hasOwnProperty(inner_tab_key))
              {
                if(inner_tab_key === id)
                {
               
                    tab = outer_tab.Tabs[id];
                    found = true;
                    break done;
                }
              }
            }
          }
        }
    
    if(found)
        return tab;
    else
        return null;
}



function MenuStructure()
{
    this.OuterTabs = [];
    this.AddTab = add_main_tab;
    this.FindTab = find_tab;
}


function add_main_tab(display_text,url,image)
{

    this.OuterTabs[display_text] = new OuterTab(display_text,url,image);
   
}

//-----------------------------------------------------------------------------
//sample code to create a 3 -level menu data structure
//-----------------------------------------------------------------------------
var menu_structure = null;
//var menu_structure = new MenuStructure();
//menu_structure.AddTab("Home","page1.html");
//menu_structure.OuterTabs["Home"].AddTab("home subpage 1","page1sub1.html");
//menu_structure.OuterTabs["Home"].AddTab("home subpage 2","page1sub2.html");

//menu_structure.AddTab("PackHouse","page1.html");
//menu_structure.OuterTabs["PackHouse"].AddTab("Packhouse subpage 1","page1sub1.html");
//menu_structure.OuterTabs["PackHouse"].AddTab("PackHouse subpage 2","page1sub2.html");
////3rd level menus
//menu_structure.OuterTabs["Home"].Tabs["home subpage 1"].AddTab("create user","http://www.alphaville.de");
//menu_structure.OuterTabs["Home"].Tabs["home subpage 1"].AddTab("delete user","HTMLPage4.htm");

if (menu_structure == null)
{
 
    menu_structure = new MenuStructure();
    menu_structure.AddTab("Login","page1.html","/images/password.png");


    
}

if(trace) 
{
    alert('tabs script loaded.');
    alert(menu_structure.OuterTabs["page 1"].Tabs.length);
    
}
  
//Now Build the outer tabs bar
 
function set_content_header_caption(value)
{
 
 
 
    content_header_caption = value;
 
 
 
 
 
}
//****************************************************************
// Henry created building goodlist
//****************************************************************
function buildgoodlist()
{

    // This list is used to control which programs will be placed on the visible tab
    // var outer_tabs = menu_structure.OuterTabs;
    var count  = 0 ; 

    for ( outer_tab in menu_structure.OuterTabs)
    {
      if (menu_structure.OuterTabs.hasOwnProperty(outer_tab))
      {
        if ((nawtylist.indexOf(menu_structure.OuterTabs[outer_tab].DisplayText) == -1 )&&(menu_structure.OuterTabs[outer_tab].DisplayText != undefined))
        {
            gudlist_programs[count] = outer_tab;
            count ++;

        }
      }

    }

}
// Henry     
// This creates a button that will be added to the div
function build_hiddenprograms_button()
{
    var btnTable = document.createElement("table");
    document.getElementById("hidden_program_list_button").appendChild(btnTable);
    btnTable.id = "hidden_program_button";
   
   
    table =  document.getElementById("hidden_program_button");
    var oNewNode = document.createElement("tr");
    oNewNode.id="program_button_id";
  
    table.appendChild(oNewNode);
    oNewNode.innerHTML="<td id='badprograms_button_outer_tab'  onclick='program_button_clicked();' background='"+l1_menu_tab_image+"' ><img  src ='/images/1downarrow_level1.png'</img></td>";
  
}    
//Henry
// This creates a button that will reveal the hidden programs for the third level
function build_hidden_programs_button_l3()
{
   
    var btnTable = document.createElement("table"); // a table element is created
    document.getElementById("hidden_program_list_level3_button").appendChild(btnTable);// adds the new table to the div
    btnTable.id = "hidden_program_button_l3";// gives the table an id
   
   
    table =  document.getElementById("hidden_program_button_l3");// gets the table that was created
    var oNewNode = document.createElement("tr");//adds an tr element to the table
    oNewNode.id="program_button_id_l3";//gives an id to the new element
  
    table.appendChild(oNewNode);//appends the the tr too the table

  
    //inserts the button
    oNewNode.innerHTML="<td  id='level3_bad_programslist' onclick='hidden_program_list_level3_button_clicked(this);' background='" + l2_menu_tab_image + "'  > <img  src ='/images/bullet_arrow_up_level3.png'</img></td>";
}
//Henry
// This creates a button that will reveal the second level hidden programs
function build_hiddenprograms_button_l2()
{
    var btnTable = document.createElement("table");
    document.getElementById("hidden_program_list_level2_button").appendChild(btnTable);
    btnTable.id = "hidden_program_button_l2";
    
   
    table =  document.getElementById("hidden_program_button_l2");
    var oNewNode = document.createElement("tr");
    oNewNode.id="program_button_id_l2";
  
    table.appendChild(oNewNode);
 
    oNewNode.innerHTML="<td  id='level2_bad_programslist' onclick='program_button_clicked_l2(this);' background='" + l2_menu_tab_image + "'  > <img  src ='/images/bullet_arrow_down_level3.png'</img></td>";
 
  
}
// Henry  
// This method is called when an item is clicked on the the third hidden level div
function hidden_program_list_level3_button_clicked()
{

    // tests is the division is visible and if it is the according icon will be set
    if( document.getElementById("hidden_program_list_level3_div").style.visibility == "visible")
    {
     
        document.getElementById("level3_bad_programslist").innerHTML = "<img  src ='/images/bullet_arrow_up_level3.png'</img>";
    }
    else
    {
        document.getElementById("level3_bad_programslist").innerHTML = "<img  src ='/images/bullet_arrow_down_level3.png'</img>";
        
    }

    // hidden_program_list_level3_button_clicked
    status = document.getElementById("hidden_program_list_level3_div").style.visibility;
    // test if any of the other divisions are visible if so they wil be closed
    if(status == "hidden")
    {
       
        window.parent.document.getElementById("hidden_program_list_level3_div").style.visibility = "visible";
        
    }
    else
    {
        window.parent.document.getElementById("hidden_program_list_level3_div").style.visibility = "hidden";
       
    }
    //*************************************************************************************8
    //makes the div invisibile and reveals the level2 button if there is any programs on the
    // the  hiddenlist
    status_level1_btn = document.getElementById("hidden_program_list_div");
    if(status_level1_btn.style.visibility=="visible")
    {
       
        window.parent.document.getElementById("hidden_program_list_div").style.visibility = "hidden";
        document.getElementById("badprograms_button_outer_tab").innerHTML="<img  src ='/images/1downarrow_level1.png'</img> ";
        if(badlist_inner_tabs.length != 0)
        {
            document.getElementById("hidden_program_list_level2_button").style.visibility = "visible";
        }
    }
    //*************************************************************************************
    //tests if the level2 div is visible, if it is it will be made invisible and
    // the button will change
    status_level2_btn = document.getElementById("hidden_program_list_level2_div").style.visibility;
    if(status_level2_btn =="visible")
    {
        window.parent.document.getElementById("hidden_program_list_level2_div").style.visibility = "hidden";
        document.getElementById("level2_bad_programslist").innerHTML= "<img  src ='/images/bullet_arrow_down_level3.png'</img>";
    }
                
}
// Henry
//*-*-*-*-*-*-**-*-*-*-*-*-**-*-*-*-*-*-**-*-*-*-*-*-**-*-*-*-*-*-*
function program_button_clicked_l2 (button)
{
    document.getElementById("level3_bad_programslist").innerHTML = "<img  src ='/images/bullet_arrow_up_level3.png'</img>";
    var test =document.getElementById("hidden_program_list_level2_div").style.visibility;
          
    if(test  == "visible")
    {
        document.getElementById("level2_bad_programslist").innerHTML= "<img  src ='/images/bullet_arrow_down_level3.png'</img>";
    }
    else
    {
        document.getElementById("level2_bad_programslist").innerHTML = "<img  src ='/images/bullet_arrow_up_level3.png'</img>";
    }
      
  
    status = document.getElementById("hidden_program_list_level2_div").style.visibility;
     
    if(status == "hidden")
    {
        slide_down("hidden_program_list_level2_div");
    //   uncommnent the line below if you want to remove sliding effect and comment the line abbove
    //   window.parent.document.getElementById("hidden_program_list_level2_div").style.visibility = "visible";
    }
    else
    {
        slide_up("hidden_program_list_level2_div");
    //   uncommnent the line below if you want to remove sliding effect and comment the line abbove
    //    window.parent.document.getElementById("hidden_program_list_level2_div").style.visibility = "hidden";
    }
    status_foreighn = document.getElementById("hidden_program_list_div");
    if(status_foreighn ="vissible ")
    {
        window.parent.document.getElementById("hidden_program_list_div").style.visibility = "hidden";
    }
    status_foreighn_level3 = document.getElementById("hidden_program_list_level3_div").style.visibility;
    if(status_foreighn_level3="visible ")
    {
        window.parent.document.getElementById("hidden_program_list_level3_div").style.visibility = "hidden";
    }
}
function slide_down(div_name)
{

    if (div_name == "hidden_program_list_level2_div")
    {
        document.getElementById("hidden_program_list_button").style.visibility = "hidden";
    }
    count_resize_div = 1 ;
    window.parent.document.getElementById(div_name).style.visibility = "visible";
    document.getElementById(div_name).style.height = 0 ;
    try{
        var outside =   document.getElementById(div_name).style.height;
        outside_int  = 0;
        setTimeout("fires('"+div_name+"')",0);
    }
    catch(exception)
    {
        alert(exception);
    }

}

function fires(div_name)
{

    var rounded  = Math.round( outside_int/5);

    if (count_resize_div <20)
    {
        var x =   document.getElementById(div_name).style.height;
        var xx =  parseInt(x);
 

        count_resize_div++;
        document.getElementById(div_name).style.height =(xx+5)+"px";
        setTimeout("fires('"+div_name+"')",0);
    }
    else
    {
        window.parent.document.getElementById(div_name).style.visibility = "visible";
        document.getElementById("hidden_program_list_button").style.visibility = "visible";
        count =1;
    }
}

function slide_up(div_name)
{
    count_resize_div = 1 ;
    try
    {
        var outside =   document.getElementById(div_name).style.height;
        outside_int  =  150;

        setTimeout("firew('"+div_name+"')",0);
    }
    catch (exception)
    {
        alert(exception);
    }

}

function firew(div_name)
{
    var rounded  = Math.round( outside_int/6);
    if(count_resize_div <=rounded )
    {
        var x =   document.getElementById(div_name).style.height;
        var xx =  parseInt(x);

        count_resize_div++;
        document.getElementById(div_name).style.height =(xx-6)+"px";
        setTimeout("firew('"+div_name+"')",0);
    }
    else
    {
        window.parent.document.getElementById(div_name).style.visibility = "hidden";
        count =1;
    }
}

function program_button_clicked ()
{
    document.getElementById("level3_bad_programslist").innerHTML = "<img  src ='/images/bullet_arrow_up_level3.png'</img>";
    var test = document.getElementById("hidden_program_list_div").style.visibility;
    if (test == "visible")
    {
        document.getElementById("badprograms_button_outer_tab").innerHTML="<img  src ='/images/1downarrow_level1.png'</img> ";
  
    }
    else
    {
        document.getElementById("badprograms_button_outer_tab").innerHTML =" <img  src ='/images/1uparrow_level1.png'</img>";
        document.getElementById("level2_bad_programslist").innerHTML= "<img  src ='/images/bullet_arrow_down_level3.png'</img>";
    }
     
    status_btn_l2_bad = document.getElementById("hidden_program_list_level2_button").style.visibility;
    if (status_btn_l2_bad == "hidden")
    {
   
    }
    else
    { 
        document.getElementById("hidden_program_list_level2_button").style.visibility = "hidden";
    }
    
    status = document.getElementById("hidden_program_list_div").style.visibility;
     
    if (status== "hidden")
    {
        slide_down("hidden_program_list_div");
    //   uncommnent the line below if you want to remove sliding effect and comment the line abbove
    //  window.parent.document.getElementById("hidden_program_list_div").style.visibility = "visible";
    }
    else
    {
        slide_up("hidden_program_list_div");
        //   uncommnent the line below if you want to remove sliding effect and comment the line abbove
        //  window.parent.document.getElementById("hidden_program_list_div").style.visibility = "hidden";
        
        if(badlist_inner_tabs.length != 0)
        {
            document.getElementById("hidden_program_list_level2_button").style.visibility = "visible";
        }
    }
        
    status_2 = document.getElementById("hidden_program_list_level2_div");
    if(stutus_2 ="visible")
    {
          
        window.parent.document.getElementById("hidden_program_list_level2_div").style.visibility = "hidden";
    }
    else
    {
    }
        
    status_level3_btn = document.getElementById("hidden_program_list_level3_div");
    if(status_level3_btn.style.visibility ="visible ")
    {
        window.parent.document.getElementById("hidden_program_list_level3_div").style.visibility = "hidden";
    }
        
}
        
        
        
function build_menus()
{
    build_hiddenprograms_button();
    build_hiddenprograms_button_l2();
    build_hidden_programs_button_l3();
    buildgoodlist();
   
    if (menu_structure == null)
        alert ('No data structures for the menus have been defined!');
    else
    {
        build_outer_tabs();
        if(login_state)
        {  
           
            var tabCell = document.getElementById("Login");
            if(tabCell != null)
                outer_tab_clicked(tabCell,false);
        }
          
    }
}
  
//===============================
//utility functions
//===============================
function show_element(id)
{

    elt = document.getElementById(id);
    elt.style.display = "inline";
//elt.style.visibility = "visible"
  
}
  
//============================================================================
//Menu building and behaviours
//===========================================================================
 
 
//---------------------------------------------------------------------------------------
//This function is called when a link in a main tab is clicked:
//It has to:
//          1) Select or highlight the current tab and unselect other tabs
//          2) Rebuild the 2nd level tabs- with values from the children of the parent tab
//----------------------------------------------------------------------------------------
//******Done by Henry function close_hiddenprograms**********************
function close_hiddenprograms()
{
    // closes the first and second level and changes the images
    window.parent.document.getElementById("hidden_program_list_div").style.visibility = "hidden";
    document.getElementById("badprograms_button_outer_tab").innerHTML="<img  src ='/images/1downarrow_level1.png'</img> ";
    document.getElementById("hidden_program_list_level2_div").style.visibility = "hidden";
    document.getElementById("level2_bad_programslist").innerHTML= "<img  src ='/images/bullet_arrow_down_level3.png'</img>";
}
//****************************
function outer_tab_clicked(tab_cell,clear_notice)
{
    badlist_inner_tabs.length =0 ;
    close_hiddenprograms();// Henry
  
    if(trace)
        alert("outer_tab_clicked()" + " tab_cell = " + tab_cell.id);
    
    clear_content();
    try
    {
        buildgud_inner_tab_list(tab_cell.id);
    }
    catch(x)
    {
        alert(x);
    }
    outer_tab_inuse = tab_cell.id;
    build_inner_tabs(tab_cell.id);
    
    //select the selected tag and unselect all others
    select_outer_tab(tab_cell);
    if(clear_notice)
    {
        clear_flash();
    }
       
}

function clear_flash()
{
    if (window.frames.length > 1)
        var notice = window.frames[1].document.getElementById("notice");
   	 
    if(notice != null)
    {
        
        notice.innerHTML = "";
     
    }

}

function clear_content()
{
    active_l3_menu_image = null
    if (window.frames.length > 1)
    {
	    
        var content = window.frames[1].document.getElementById('maine');
        if (content != null)
        {
            content.innerHTML = "";
            if (menu_list != null)
                remove_tree_context_menus();
            var content_header = document.getElementById('content_header');
            if (content_header != null)
                content_header.innerHTML = "";
        }
    }

}

function remove_tree_context_menus()
{
    
    for(i=0;i< menu_list.length;i ++)
    {
        var ctx_menu = window.frames[1].document.getElementById(menu_list[i])
        if(ctx_menu != null)
            window.frames[1].document.body.removeChild(ctx_menu);
    
    }
    menu_list = null;

}

function toggle_content_border(show)
{
    var content_frame = document.getElementById('content_container');
    if(content_frame != null)
    {
        if(show)
        {
 		
 			
            content_frame.style.borderRight = "gray thin solid";
            content_frame.style.borderLeft = "gray thin solid";
            content_frame.style.borderTop = "gray thin solid";
            content_frame.style.borderBottom = "gray thin solid";
        }
        else
        {
			
            content_frame.style.border = "";
            toggle_content_header_border(false);
        }
    }
}


    
function hide_l3_menus(hider)
{
    // Test if the level3 div is visible if it is it will hide it and change the image
    if(document.getElementById("hidden_program_list_level3_div").style.visibility == "visible")
    {
        document.getElementById("hidden_program_list_level3_div").style.visibility = "hidden";
       
        document.getElementById("level3_bad_programslist").innerHTML = "<img  src ='/images/bullet_arrow_up_level3.png'</img>";
     
    }
    l3_container = document.getElementById("l3_menus_container");
    l3_container_parent = document.getElementById("l3_menus_container_parent");
    l3_content_container = document.getElementById("content_container");
    img_menu_hider = document.getElementById("img_menu_hider");
            
    if(! (l3menus_hidden))
    {
           
        l3_container.style.display = "none";
        l3_container_parent.width = "1%";
        document.getElementById("content_container").width = "98%";
        img_menu_hider.src = "/images/home/show.png";
    }
    else
    {
        l3_container.style.display="";
        l3_container_parent.width = "15%";
        document.getElementById("content_container").width = "83%";
        img_menu_hider.src = "/images/home/hide.png";
         
    }
    
    l3menus_hidden = ! (l3menus_hidden);
    if(l3menus_hidden)
    {
        hider.innerHTML = "show menus";
            
        if(window.frames[1].grid != null)
        {
            window.frames[1].grid.setSize(grid_max_width, current_grid_height);
            current_grid_width = grid_max_width ;
                 
        }
    }
    else
    {
        hider.innerHTML = "hide menus";
        if(window.frames[1].grid != null)
        {
          
            window.frames[1].grid.setSize(grid_min_width, current_grid_height);
            current_grid_width = grid_min_width;
        }
    }
    
}


function toggle_content_header_border(show)
{

    var header_show_border_background_style = "url(/images/tlo_podmenu.gif)"
    var content_header = document.getElementById('content_header');
		
    if(content_header != null)
    {
        if(show)
        {
            content_header.style.color = "green";
            content_header.style.background = header_show_border_background_style;
            content_header.innerHTML = content_header_caption
				
        //var img = document.createElement("img");
        //img.src ="/images/form_close.png";
        //img.align = "right";
        //img.valign = "top";
        //content_header.appendChild(img);
				
        }
        else
        {
            content_header.style.background = "";
            content_header.innerHTML ="";
            content_header_caption = null;
        }
    }

}


function contentFrame_loaded()
{


    user_action_ocurred();
    var loading_pic = document.getElementById("content_loading_gif");
    if (loading_pic != null)
        loading_pic.style.visibility = "hidden";
        
    //alert('loaded');
    if(active_l3_menu_image) {
      active_l3_menu_image.style.display = "none";
      //cell.style.backgroundColor = level3_tab_selected_color
      active_l3_menu_image.parentNode.style.backgroundColor = level3_tab_selected_color;
    }
    //If the status variable is not empty, set the caption of the
    //content_header frame to the caption
    if (window.frames.length > 1)
    {
   	  
        if(content_header_caption != null)
        {
            toggle_content_header_border(true);
        }
        else
        {
            toggle_content_header_border(false);
        }
    }
   	 
   	 
   	 
}


function menu_styling(cell,selected,clicked)
{
  
  
    if(!clicked)
    {
        
        if (selected)
        {
            cell.style.backgroundColor = level3_tab_hover_color;
           
        }
            
        else
        {   
        	
            if(active_l3_menu_image != null)
            {
                if(cell.id === active_l3_menu_image.parentNode.id)
                    cell.style.backgroundColor = level3_tab_selected_color;
                else
                    cell.style.backgroundColor = level3_tab_unselected_color;
            }
            else
            {
               
                cell.style.backgroundColor = level3_tab_unselected_color;
            }
        }
    }  
    else
    {
       
        clear_flash();
        toggle_content_header_border(false);
        if(active_l3_menu_image != null)
        {
           
            if(cell.id != active_l3_menu_image.parentNode.id)
            {
                    
                active_l3_menu_image.parentNode.style.backgroundColor = level3_tab_unselected_color;
            }
        }
                    
        img = document.getElementById(cell.id + '_loading_img');
        img.style.display = "inline";
        active_l3_menu_image = img;
        //img.src = active_l3_image;
       
        var loading_pic = document.getElementById("content_loading_gif");
        if (loading_pic != null)
            loading_pic.style.visibility = "visible";
        
    }
    
 
}
// (Henry) Will change the positions  of the elements(outer and innertab and the level3 menu tab  ) when the header is hidden
function  adjust_menu(status)
{

    if(status == "hidden")
    {
        document.getElementById("tableOuter").style.top = "8.2%";
        document.getElementById("hidden_program_list_button").style.top = "8.0%";
        document.getElementById("hidden_program_list_div").style.top = "11.5%";

        document.getElementById("innerTabstable").style.top = "11.5%";
        document.getElementById("hidden_program_list_level2_div").style.top = "14.5%";
        document.getElementById("hidden_program_list_level2_button").style.top = "11.4%";

        //document.getElementById("content_container").style.top = "16%";
        document.getElementById("l3_menus_container").style.top = "16%";
        document.getElementById("l3menus_table").style.top="16%";
    }
    else
    {
        document.getElementById("tableOuter").style.top = "0%";
        document.getElementById("hidden_program_list_button").style.top = "-0.5%";
        document.getElementById("hidden_program_list_div").style.top = "3.4%";

        document.getElementById("innerTabstable").style.top = "3.9%";
        document.getElementById("hidden_program_list_level2_div").style.top = "6.8%";
        document.getElementById("hidden_program_list_level2_button").style.top = "3.8%";

        //document.getElementById("content_container").style.top = "10%";
        document.getElementById("l3_menus_container").style.top = "8%";
        document.getElementById("l3menus_table").style.top="8%";

    //hidden_program_list_level2_button
    }
}

function select_outer_tab(tab_cell)
{
    // if an outer tab is selected the level3 div style.visibility is then set to hidden
    document.getElementById("hidden_program_list_level3_button").style.visibility="hidden";
    document.getElementById("hidden_program_list_level3_div").style.visibility="hidden";
    l3_nawty_list.length=0;
    check_if_button_l3();

    delete_hidden_program_list_table_rows();
    create_new_table("hidden_program_list_div","hidden_program_list_table");
    populate_nawtyprogramslist("hidden_program_list_div");


    for (outer_tab_key in menu_structure.OuterTabs)
    {
      if (menu_structure.OuterTabs.hasOwnProperty(outer_tab_key))
      {
   
        var key = menu_structure.OuterTabs[outer_tab_key].DisplayText;
     
        var td = document.getElementById(key);//.parentNode.parentNode;

        if(tab_cell.id === outer_tab_key)
        {
            td.style.background = outer_tab_selected_color;
        }
        else
        {
            td.style.backgroundImage = outer_tabs_background;
        }
      }  
    }
  
    //clear level 3 menus
    var l3 = document.getElementById(level3_tabs_container);
    if(l3 != null)
    {
        l3.innerHTML = "";
    }
  	
  
}

function select_inner_tab(tab_cell)
{
    document.getElementById("hidden_program_list_div").style.visibility ="hidden";
    document.getElementById("badprograms_button_outer_tab").innerHTML="<img  src ='/images/1downarrow_level1.png'</img> ";
    //hides and resets the level2 div and button
    document.getElementById("level2_bad_programslist").innerHTML= "<img  src ='/images/bullet_arrow_down_level3.png'</img>";
    document.getElementById("hidden_program_list_level2_div").style.visibility = "hidden";

    document.getElementById("level3_bad_programslist").innerHTML = "<img  src ='/images/bullet_arrow_up_level3.png'</img>";
    // hides the level level3 div if a new inner tab is clicked
    document.getElementById("hidden_program_list_level3_button").style.visibility="hidden";
    document.getElementById("hidden_program_list_level3_div").style.visibility="hidden";

    //Resets the values for the badlist_l3 and goodlist_l3
    l3_nawty_list.length = 0 ;
    goodlist_l3_names.length= 0;

    try
    {
        if(from_bad_list == false)
        {
            var tds = tab_cell.parentNode.parentNode.parentNode.getElementsByTagName("td");

        }
        else
        {
            var tds =   document.getElementById(tab_cell.id).parentNode.parentNode.getElementsByTagName("td");
        }
    }
    catch(x)
    {

        var tds =   document.getElementById(tab_cell.id).parentNode.parentNode.getElementsByTagName("td");

    }
    try
    {
        if(from_bad_list == false)
        {
            var  id = tab_cell.parentNode.parentNode.id;
  
        }
        else
        {
            var  id = tab_cell.id;
        }
    }
    catch(x)
    {

        var  id = tab_cell.id;

    }

    clear_content()
    
    for (i = 0; i < tds.length; i ++)
    {
         
        if(tds[i].id === id)
        {
             
            tds[i].style.background = level2_tab_selected_color;
            tds[i].style.fontWeight = "bold";
            tab_cell.backgroundColor = "grey";
            
            
        }
        else if (tds[i].id.length > 0)
        {
            
            tds[i].style.backgroundImage = level2_tab_background;
            tds[i].style.fontWeight = "normal";
             
             
        }
         
    }
   
    //now build the third level menu structure
    // alert("Before my own stuff"+tab_cell.parentNode.parentNode.id);
    try
    {
        //Test from where the action is coming, the different sources has different ways of sening the data
        if( from_bad_list == false)
        {
            //Creates a list of the good names
            level3_good_names_list(tab_cell.parentNode.parentNode);
            build_level3_menus(tab_cell.parentNode.parentNode);
   
        }
        else
        {
            //Creates a list of the good names
            level3_good_names_list(tab_cell);
            build_level3_menus(tab_cell);
        }
    }
    catch(x)
    {
        //Creates a list of the good names
        level3_good_names_list(tab_cell);
        build_level3_menus(tab_cell);
    }
    clear_flash();
    document.getElementById("hidden_program_list_level2_div").style.visibility = "hidden";
}



function build_outer_tabs()
{
    badlist_inner_tabs.length =0 ;
    //The following build process is followed here:
    //1) Find the appropriate data strucure from the passed-in id
    //2) Build the empty left cell
    //3) For each outer tab in the menu data structure:
    //   --> Build the outer tab
    //   --> If more tabs are left --> build a spacer to the right of the tab
    //   --> Else: build the remainder tab area
    //note: the entire html string is built and then set to the inner html
    //property of the inner tab container row
    var count = 0;
    var outer_tabs = menu_structure.OuterTabs;
    if(trace)
    {
        alert('outer tabs data defined: ' + (outer_tabs != null));
        
    }
    var tabs_html = null;

    tabs_html = build_left_outer_tab();
    tabs_html += build_outer_spacer();




    try
    {
        //runs through goodlist
          
        for(goodprogram = 0 ; goodprogram < gudlist_programs.length ; goodprogram++)
        {
            //test if the name is on the bad list if it  isnt then it  will be added to the  visible menu
          
            if ((nawtylist.indexOf(gudlist_programs[goodprogram]) == -1)&&(outer_tabs[gudlist_programs[goodprogram]].DisplayText != undefined) )
            {

                 
                tabs_html += build_outer_tab(outer_tabs[gudlist_programs[goodprogram]].DisplayText,outer_tabs[gudlist_programs[goodprogram]].Url,outer_tabs[gudlist_programs[goodprogram]].Image);
                    
                if (trace)
                {
                    alert('html for outer tab: ' + outer_tabs[gudlist_programs[goodprogram]].DisplayText + '<br>' +  tabs_html);
                }
   
                tabs_html += build_outer_spacer();
     
            }
        }
    }
    catch(x)
    {
        alert(x);
    }
    tabs_html += build_outer_tab_remainder();
  
    //now add the build-up html to the row containing the inner tabs
   
    document.getElementById(outer_tabs_container).innerHTML = tabs_html;
  
    // does tests to calculate howmuch space have been used
    menu_bar_usage(gudlist_programs,nawtylist,"tableOuter");
    //if there is programs added to the badlist the icon  will be made visible
    if(nawtylist.length > 0 )
    {
        document.getElementById("hidden_program_list_button").style.visibility ="visible";
    }
    var div_name ="hidden_program_list_div";
    populate_nawtyprogramslist(div_name,"hidden_program_list_table");

}

/*function removefrombadlist()
{
alert("1");
}*/
//Henry
// this creates a new table to add the hidden programs to 
function create_new_table(div_name,table_id)
{

    var divObject = document.getElementById(div_name);
    var oNewNodeTable = document.createElement("table");
    divObject.appendChild(oNewNodeTable);
    oNewNodeTable.id = table_id;
    oNewNodeTable.style.width="150px";

}
//removes the table from the div so that a new div can be created
function delete_hidden_program_list_table_rows()
{
    try
    {
        var d = document.getElementById('hidden_program_list_div');
        var olddiv = document.getElementById("hidden_program_list_table");
        d.removeChild(olddiv);

    }
    catch(x)
    {
        alert(x);
    }

}

function searchforindex(name)
{
    var index = 0 ;
    for(names in nawtylist)
    {
      if (nawtylist.hasOwnProperty(names))
      {
        if(nawtylist[names] == name)
        {
            index  = names;
        }
      }
    }
    return index;
}
// When   a program is clicked from the hidden programs list this method is called
function badprogramclicked(a)
{
    try
    {
        var nr= nawtylist.indexOf(a.id);
        // removes the clicked program from the badlist and adds it to  the beginning of  goodlist
        nawtylist.splice(nr,1);
        gudlist_programs.unshift(a.id);

        //removes the current table and then creates a new table
        delete_hidden_program_list_table_rows();
        populate_nawtyprogramslist("hidden_program_list_div","hidden_program_list_table");
        build_outer_tabs();

        delete_hidden_program_list_table_rows();
        populate_nawtyprogramslist("hidden_program_list_div","hidden_program_list_table");
        //sets the selected badprogram as the selected goodprogram
        tabcell = document.getElementById(a.id);
        outer_tab_clicked(tabcell,true);

    }
    catch(x)
    {
        alert(x);
    }
}
// Creates the td's that will be added to the innerHTML of the table
function icons_hidden_programs(program_name)
{
    var tab = "";
    var outer_tabs = menu_structure.OuterTabs;
    try
    {
        for(outer_tab in outer_tabs)
        {
          if (outer_tabs.hasOwnProperty(outer_tab))
          {
            if(outer_tab ==  program_name )
            {
 
                tab +="<td  background = '" + l1_menu_tab_image + "' id='"+program_name+"' onclick='badprogramclicked(this);' ><nobr><img src ='"+ outer_tabs[outer_tab].Image+"' height='16' width='16'</img><a  href='javascript:nothing();'>" + program_name + "</a></td>";
            }
          }
        }
    }
    catch(x)
    {
        alert(x);
    }
    return tab;
}
//-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
function populate_nawtyprogramslist(div_name,table_id)
{
    create_new_table(div_name,table_id);

    //for(index in nawtylist)
    for(var index = 0; index < nawtylist.length; index++)
    {

        try
        {
            var table =  document.getElementById("hidden_program_list_table");
  
            var oNewNode = document.createElement("tr");
            oNewNode.id=nawtylist[index];
  
            table.appendChild(oNewNode);

            var tab = icons_hidden_programs(nawtylist[index]);
  
            oNewNode.innerHTML=tab;

        }
        catch(x)
        {
            alert(x);
        }
    
    }

}

//calcultates how much space has ben used 
function menu_bar_usage(goodlist_received,nawtylist_received,table_name)
{
   // alert(goodlist_received.toSource()+"Hello this hell 4 today");
    var table_name = table_name;

  
    var count_top = 0;      
    var count = 0 ; 
    try
    {
        // runs through the goodlist array
        for(gud =0 ; gud < goodlist_received.length ; gud++)
        {
            try
     
            {
                // the inner and outer tab are horisontal  and the level three is vertical so it uses a different method
                if (l3_menu_calc == false)
                {

                    name_px = document.getElementById(goodlist_received[gud]).offsetWidth; // gets the amount of pixels being used by the program
                    name_value = goodlist_received[gud]; // sets the name that is being used

                }
                else
                {

                    name_px = document.getElementById(goodlist_received[gud]).offsetHeight; // gets the amount of pixels being used by the program
                    name_value = goodlist_received[gud];// sets the name being used
                }
            }
            catch(x)
            {

                if (l3_menu_calc == false)
                {
                    name_px = document.getElementById(goodlist_received[gud].DisplayText).offsetWidth;
                    name_value = goodlist_received[gud].DisplayText;
                }
                else
                {
                    try
                    {
                        name_value = goodlist_received[gud];
                        name_px = parseInt( document.getElementById("l3_"+goodlist_received[gud]).style.height);
                    }
                    catch(x)
                    {
                        alert(x);
                    }
                }
            }

            count += name_px; // the total amount of pixels used
            // sets the limit of the amount of pixels that can be used
            if(l3_menu_calc == false)
            {
                //var menu_limit =850;
                var menu_limit =1000;
            }
            else
            {
                //248
                //var menu_limit = 600;
                var menu_limit =1000;
                //var menu_limit = 248;
            }

            if (count > menu_limit )
            {
                try
                {
                    if ( name_value)
                    {
                        nawtylist_received.unshift( name_value);// adds a new program to the bad list
       
                    }
                }
                catch (x)
                {
                    alert(x);
                }
            }
        }

        //runs through the bad list array and tests if any of the names in the badlist is the goodlist
        // if it is, then it will be removed
        for (bad  in nawtylist_received)
        {
          if (nawtylist_received.hasOwnProperty(bad))
          {
            // test if the name appears in the goodlist if it doesnt then it returns -1
            // which will remove the first element in the array
            var index_nr = goodlist_received.indexOf(nawtylist_received[bad]);
            if (index_nr  != -1)
            {
                goodlist_received.splice(goodlist_received.indexOf(nawtylist_received[bad]),1);
            }
          }
       
        }
        show_array_of_elements(nawtylist_received,table_name);
        var div_name ="hidden_program_list_div";
    }
    catch (x)
    {
        alert(x);
    }
  
}
// returns the number of cells in a row
function getlength_row(table_name)
{
    if(l3_menu_calc == false)
    {
        return document.getElementById(table_name).rows[0].cells.length-1;
    }
    else
    {
        return document.getElementById(table_name).rows.length;
    }
}

// removes the the cells that appears in the bad list
function show_array_of_elements(nawtylist_received,table_name)
{


    try
    {

        for(outer_tab in nawtylist_received)// runs through the list of programs that will be removed
        {
          if (nawtylist_received.hasOwnProperty(outer_tab))
          {
   
            for(i = 0; i < getlength_row(table_name) ;i++)
            {
                // test if the rows are from the level3 menus
                if (l3_menu_calc == true)
                {
                    var element_to_compare =document.getElementById(table_name).rows[i].cells[0].id;
                    var first_element =     "l3_"+nawtylist_received[outer_tab];
                }
                else
                {
                    var element_to_compare =document.getElementById(table_name).rows[0].cells[i].id;
                    var first_element =     nawtylist_received[outer_tab];
                }

                if(first_element == element_to_compare )
                {
          
                     
                    try
                    {
                
                        if (l3_menu_calc == true)
                        {
                            // On the level3 menu an entire row is deleted
                            document.getElementById(table_name).deleteRow(i);
                     
                        }
                        else
                        {
                            // removes the program and the item before  it
                            document.getElementById(table_name).rows[0].deleteCell([i]) ;
                            document.getElementById(table_name).rows[0].deleteCell([i-1]);
                        }
                
                    }
                    catch(x)
                    {
                        alert(x);
                    }
                        
                }
            }
          }
        }
           
    }

    catch(x)
    {
        alert(x);
    }

}

function insertCell(display_text,image)
{
    var tab = "<td  background = '" + l1_menu_tab_image + "' id='"+display_text+"'  >";
    tab += "<nobr><img src ='/images/menu/security/security.png' />";
    tab += "<span id = '" + display_text + "' class = 'menu'> &nbsp;&nbsp; <a class= 'menu' href= 'javascript:empty();' onclick = 'outer_tab_clicked(this.parentNode,true);'";
    tab += ">" + display_text + "</a> &nbsp;&nbsp; </span></nobr></td>";
    return tab;
}
function build_left_outer_tab()
{
    var tab = "<td  background='" + l1_menu_left_td_image + "'";
    tab +=  "width='50'>";
    tab +=  "<img src='" + l1_menu_left_img_image + "' height='16' width='16' alt=''";
    tab +=  "border='0' height='25' width='50'></td>";

    return tab;

}

function build_outer_spacer()
{
    var spacer = "<td style='width: 1px'>";
    spacer += "<img src='" + l1_menu_spacer_image + "' alt=''";
    spacer += " border='0' height='25' width='1'></td>";
    return spacer;


}

function build_outer_tab_remainder()
{
    var tab = "<td  background='" + l1_menu_remainder_image + "'";
    tab += "width='100%'>&nbsp;</td>";
    return tab;
}


function build_outer_tab(display_text,url,image)
{
    var id_l1 ="l1_cell_";
    if(image == null) image = "";
    
    var tab = "<td  background = '" + l1_menu_tab_image + "' id='"+display_text+"'  >";
    tab += "<nobr><img src ='" + image + "' height='16' width='16'</img>";
    tab += "<span id = '" + display_text + "' class = 'menu'> &nbsp;&nbsp; <a class= 'menu' href= 'javascript:empty();' onclick = 'outer_tab_clicked(this.parentNode,true);'";
    tab += ">" + display_text + "</a> &nbsp;&nbsp; </span></nobr></td>";
     
   
    return tab;

}
// Henry
//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
function buildgud_inner_tab_list(outer_tab_id)
{
    //  for ( outer_tab in menu_structure.OuterTabs)
    //         {
    //
    //
    //          if ((nawtylist.indexOf(menu_structure.OuterTabs[outer_tab].DisplayText) == -1 )&&(menu_structure.OuterTabs[outer_tab].DisplayText != undefined))
    //            {

    // creates lists that will be used to controll which program will added to the different levels
   
    var count_good_tabs= 0 ;
    goodlist_inner_tabs.length = 0 ;
    var innertabs = menu_structure.OuterTabs[outer_tab_id].Tabs;
    try
    {
        for(innertab in innertabs )
        {
          if (innertabs.hasOwnProperty(innertab))
          {

            if(innertabs[innertab].DisplayText !=  undefined )
            {
                goodlist_inner_tabs[count_good_tabs]=innertabs[innertab];
                goodlist_inner_names[count_good_tabs]= innertabs[innertab].DisplayText;
                count_good_tabs++;
            }
          }
        }
    }
    catch(x)
    {
        alert(x);
    }
    /*for(good_inner_tabs_level2 in good_inner_tabs)
    {
        if(good_inner_tabs_level2.DisplayText != undefined)

            {
        alert(good_inner_tabs_level2.DisplayText);
            }
    }*/
    //   goodlist_inner_tabs[count_good_tabs]=inner_tabs[good_inner_tabs];
    //   goodlist_inner_names[count_good_tabs]= inner_tabs[good_inner_tabs].DisplayText;

    //  goodlist_inner_tabs[count_good_tabs]=menu_structure.InnerTabs[good_inner_tabs];
    //     goodlist_inner_names[count_good_tabs]=menu_structure.InnerTabs[good_inner_tabs].DisplayText;
    count_good_tabs++;
    
        
}

function build_inner_tabs(outer_tab_id)
{

   
    //The following build process is followed here:
    //1) Find the appropriate data strucure from the passed-in id
    //2) Build the empty left cell
    //3) For each inner tab in the menu data strcure:
    //   --> Build the inner tab
    //   --> If more tabs are left --> build a spacer to the right of the tab
    //   --> Else: build the remainder tab area
    //note: the entire html string is built and then set to the inner html
    //property of the inner tab container row
  
 
    var inner_tabs = menu_structure.OuterTabs[outer_tab_id].Tabs;
    if(trace)
    {
        alert('inner tabs data defined: ' + (inner_tabs != null));
        
    }
    var tabs_html = null;
 
    tabs_html = build_left_inner_tab();

    try
    {
        for ( good  in goodlist_inner_names)
        {
          if (goodlist_inner_names.hasOwnProperty(good))
          {

            // if the name isnt present on the bad list it  will be added to the menu structure
            if(badlist_inner_tabs.indexOf(goodlist_inner_tabs[good])== -1  )
            {
                tabs_html += build_inner_tab(inner_tabs[goodlist_inner_names[good]].DisplayText,inner_tabs[goodlist_inner_names[good]].Url,inner_tabs[goodlist_inner_names[good]].Image);
     
            }
   
            if(trace)
            {
                alert('html for inner tab: ' + inner_tabs[inner_tab].DisplayText + '<br>' +  tabs_html);
            }
            try
            {
                tabs_html += build_spacer();
            }
            catch(x)
            {
 
            }    
          }
    
        }

    }
    catch(x)
    {

    }
    tabs_html += build_remainder_area();

  

    try
    {
        if(	document.getElementById(inner_tabs_container).innerHTML = tabs_html)
        {
            document.getElementById(inner_tabs_container).innerHTML = tabs_html;
        }
        else
        {
            alert("");
        }
    }
    catch(x)
    {
        alert(x);
    }
    toggle_content_border(false);
    // calculates how many programs have to be removed and added to the bad list
    menu_bar_usage(goodlist_inner_names,badlist_inner_tabs,"innerTabstable");  
    // tests if the leve2 button should be revealed
    if(badlist_inner_tabs.length == 0)
    {
        btn_l2_bad = document.getElementById("hidden_program_list_level2_button");
        btn_l2_bad.style.visibility  = "hidden";

    }
    else
    {

        btn_l2_bad = document.getElementById("hidden_program_list_level2_button");
        btn_l2_bad.style.visibility  = "visible";
    }
    build_l2_hiddenprograms(badlist_inner_tabs,outer_tab_id);

}


/*function reveal_badlist_l2()
{

    if(badlist_inner_tabs.length == 0)
    {
        try
        {
            var btn_l2_bad = document.getElementById("hidden_program_list_level2_button");
var  btn_l2_bad.style.visibility  = "hidden";
}
catch(x)
{
alert(x);
}
}
else
{

 var btn_l2_bad = document.getElementById("hidden_program_list_level2_button");
 var btn_l2_bad.style.visibility  = "visible";
}

}
*/
// builds the level2 hidden programs menu
function populate_l2_hidden_programs(received_badlist_inner_tabs,outer_tab_id)
{

    try
    {

        //for(bad in received_badlist_inner_tabs)
        for(var bad = 0; bad < received_badlist_inner_tabs.length; bad++)
        {
            var  table =  document.getElementById("hiddenprograms_level2_table");

            var oNewNode = document.createElement("tr");
            oNewNode.id=received_badlist_inner_tabs[bad];
            table.appendChild(oNewNode);
            tab = icons_hidden_programs_l2(received_badlist_inner_tabs[bad],outer_tab_id);
            oNewNode.innerHTML=tab;
        }

    }
    catch(x)
    {
        alert(x);
    }
}
// called when a program is clicked on the badlist of level2
function badprogramclicked_l2(hiddenprogram)
{

    try
    {
        badlist_inner_tabs.splice(badlist_inner_tabs.indexOf(hiddenprogram.id),1);//removes the selected program from the badlist
        goodlist_inner_names.unshift(hiddenprogram.id);//adds the program to the beginning of the goodlist
        build_inner_tabs(outer_tab_inuse); // builds the inner tab
        from_bad_list =true;
        select_inner_tab(hiddenprogram);// selects the program clicked from the badlist
        from_bad_list =false;
    }
    catch(x)
    {
        alert(x);
    }

}
function icons_hidden_programs_l2(program_name,outer_tab_id)
{
    var tab = "";
    var innertabs = menu_structure.OuterTabs[outer_tab_id].Tabs;
    try
    {
        for(innertab in   innertabs )
        {
          if (innertabs.hasOwnProperty(innertab))
          {

            if(innertabs[innertab].DisplayText ==  program_name )
            {
                tab +="<td  background = '" + l1_menu_tab_image + "' id='"+program_name+"' onclick='badprogramclicked_l2(this);' ><nobr><img src ='"+ innertabs[innertab].Image+"' height='16' width='16'</img><a  href='javascript:nothing();'>" + program_name + "</a></td>";
            }
          }
        }
    }
    catch(x)
    {
        alert(x);
    }
    return tab;
}
//removes the level2 div contents
function delete_hidden_program_list_table_rows_l2()
{
    try
    {
        var d = document.getElementById('hidden_program_list_level2_div');
        var olddiv = document.getElementById("hiddenprograms_level2_table");
        d.removeChild(olddiv);

    }
    catch(x)
    {
        alert(x);
    }
}
// calls the needed methods to create the hidden programs list
function build_l2_hiddenprograms(badlist_inner_tabs,outer_tab_id)
{
    create_new_table("hidden_program_list_level2_div","hiddenprograms_level2_table");// creates a table for the programs
    delete_hidden_program_list_table_rows_l2();//deletes the rows of the table
    create_new_table("hidden_program_list_level2_div","hiddenprograms_level2_table");//creates a new table for the programs
    populate_l2_hidden_programs(badlist_inner_tabs,outer_tab_id);// adds the programs to the table
}


function build_left_inner_tab()
{
    var tab = "<td  background='" + l2_menu_left_td_image + "'"
    tab +=    "width='50' style='height: 20px'>"
    tab +=    "<img src='" + l2_menu_left_img_image + "' height='16' width='16' alt=''"
    tab +=    "border='0' height='20' width='50'></td>"
  
    return tab;

}

function build_inner_tab(link_text,url,image)
{
    var inner_tab_id ="l2_cell_";
    //if(image == null)image = "";
    var img_src;
    if(image === null) {img_src = "";} else {img_src = "<img src='" + image + "' height='16' width='16' />"; }
    var tab = "<td id = '"+link_text + "'  background='" + l2_menu_tab_image + "' ";
    tab += "style = 'height: 20px'>";
    //tab += "<nobr><img src = '" + image + "' height='16' width='16'</img>";
    tab += "<nobr>" + img_src ;
    tab += "&nbsp;&nbsp; <span class='podmenu'>";
    tab += "<a class='podmenu' href='javascript:nothing();' onclick = 'select_inner_tab(this.parentNode);'>";
    tab += link_text + "</a></span> &nbsp;&nbsp;</nobr></td>";

    return tab;
}

function build_spacer()
{
    var spacer =  "<td  background='" + l2_menu_spacer_td_image + "'";
    spacer += "valign='middle' width='1' style='height: 20px'>";
    spacer += "<img src='" + l2_menu_spacer_img_image + "' alt=''";
    spacer += "border='0' height='13' width='1'></td>";

    return spacer;

}

function build_remainder_area()
{
    var remainder =  "<td  background='" + l2_menu_remainder_image + "'";
    remainder += "width='100%' style='height: 20px'>";
    remainder += "&nbsp;</td>";

    return remainder;
}

    
//--------------------------
//3rd level tabs behaviours
//--------------------------



function nothing()
{

}
//*************************************************************
// Henry
// Creates a list that will control 
function level3_good_names_list(level2_selected_tab)
{
    build_level_tabs(level2_selected_tab);
    var count  = 0 ;
    try
    {
        try
        {
            var tab;
            if(level2_selected_tab.id)
            {

                 tab = menu_structure.FindTab(level2_selected_tab.id);
            }
        }
        catch(x)
        {
            tab = menu_structure.FindTab(level2_selected_tab);
        }


        for(names  in  tab.Tabs)
        {
          if (tab.Tabs.hasOwnProperty(names))
          {
            if(tab.Tabs[names].DisplayText != undefined)
            {
       
              goodlist_l3_names[count] = tab.Tabs[names].DisplayText;
              count++;
            }
          }
        }
    }
    catch(x)
    {
        alert(x);
    }
}
// *******************************************************************
// 
function build_level_tabs(level2_selected_tab)
{
    try
    {
        if(level2_selected_tab.id)
        {
            l3_tab_all =menu_structure.FindTab(level2_selected_tab.id);
        }
    }
    catch(x)
    {
        l3_tab_all =menu_structure.FindTab(level2_selected_tab);
    }

}
//**********************************************************************
function build_level3_menus(level2_selected_tab)
{
    var pass_on_level3 = level2_selected_tab;
    try
    {
        if(level2_selected_tab.id)
        {
            var level2_selected_name =level2_selected_tab.id;
            var pass_on_level3 = level2_selected_tab;
        }
        else
        {
            var level2_selected_name =level2_selected_tab;
            var pass_on_level3 = level2_selected_tab;
        }
    }
    catch(x)
    {
        alert(x);
    }

    var l3Html = "";
    var menu_count = 0;
    
    if(trace)
        alert(level2_selected_tab.innerHTML);

    var  inside_tab = menu_structure.FindTab(level2_selected_name);

    if(trace)
        alert("tab " + level2_selected_tab.id + " found: " + (l3_tab_all != null));
        
    if(l3_tab_all != null)
    {

        try
        {
  
            for(l3key = 0  ; l3key < goodlist_l3_names.length ; l3key++)
            {
                // if the name isnt on the badlist it will be added to the the tab
               
                if ((l3_nawty_list.indexOf(goodlist_l3_names[l3key]) == -1 )&& (l3_nawty_list.indexOf(goodlist_l3_names[l3key].DisplayText != undefined) ))
                {

                    l3Html += build_level3_menu_item(l3_tab_all.Tabs[goodlist_l3_names[l3key]].DisplayText,l3_tab_all.Tabs[goodlist_l3_names[l3key]].Url,l3_tab_all.Tabs[goodlist_l3_names[l3key]].Image);
                    menu_count ++;
          
                    if(trace)
                        alert(l3Html);
       
                }
            }
        }
        catch(x)
        {
            alert(x+" In catch2");
        }
    }

    document.getElementById(level3_tabs_container).innerHTML =  l3Html;
  
    if (menu_count > 0)
    {
        toggle_content_border(true);
    }
    else
    {
        toggle_content_border(false);
    }
    // tells the menu_bar_usage  to  get the height of the item and not thw width
    l3_menu_calc =true;
    menu_bar_usage(goodlist_l3_names,l3_nawty_list,"l3_menus_container");
    l3_menu_calc =false;
    // tests if the third  levels hidden programs button should be reveaveld
    if(l3_nawty_list.length > 0 )
    {
        if(document.getElementById("hidden_program_list_level3_div").style.visibility == "visible")
        {
        }
        else
        {
            document.getElementById("level3_bad_programslist").innerHTML = "<img  src ='/images/bullet_arrow_up_level3.png'</img>";
            document.getElementById("hidden_program_list_level3_div").style.visibility="hidden";
     	 
        }
    }
    if(l3_nawty_list.length == 0)
    {
     	 
    // document.getElementById("hidden_program_list_level3_div").style.visibility="hidden";
    }
     	  
    build_level3_hidden_programs(l3_nawty_list,pass_on_level3);
    if(l3_nawty_list.length >0)
    {
        correct_level3_position();
    }
    check_if_button_l3();
     	
}
// tests if the level3 button should be visible
function check_if_button_l3()
{
    if(l3_nawty_list.length  <1)
    {
        document.getElementById("hidden_program_list_level3_button").style.visibility="hidden";
    }
    else
    {
        document.getElementById("hidden_program_list_level3_button").style.visibility="visible";
    }
}


// creates the level3 badlist menu 
function create_level3_badlist_menu_items(received_badlist_inner_tabs,outer_tab_id)
{
    try
    {
        for(bad in received_badlist_inner_tabs)
        {
          if (received_badlist_inner_tabs.hasOwnProperty(bad))
          {
            table =  document.getElementById("hiddenprograms_level3_table");// the table that will hold the programs

            var oNewNode = document.createElement("tr");
            oNewNode.id=received_badlist_inner_tabs[bad];
     
            table.appendChild(oNewNode);// adds the the row to the table

            tab = icons_hidden_programs_l3(received_badlist_inner_tabs[bad],outer_tab_id);// generates  the code that will represent the buttons
  
            oNewNode.innerHTML=tab;
          }
        }

    }
    catch(x)
    {
        alert(x);
    }
 
}
//****************************************************************************
function icons_hidden_programs_l3(badlist_inner_tabs,progname)
{

    for(bad in badlist_inner_tabs)
    {
      if (badlist_inner_tabs.hasOwnProperty(bad))
      {

        for(tabs in  l3_tab_all.Tabs)
        {
          if (l3_tab_all.Tabs.hasOwnProperty(tabs))
          {
            image  = l3_tab_all.Tabs[tabs].Image;
            if(image == null)image = "";

            if(l3_tab_all.Tabs[tabs].DisplayText == badlist_inner_tabs)
            {
                var image  = l3_tab_all.Tabs[tabs].Image;
                if(progname.id)
                {
                    parent_node= progname.id;
                }
                else
                {

                    parent_node= progname;
                }
    
                var tab ="";
      
                var tab = "";
                tab += "<td  id = 'l3_"+l3_tab_all.Tabs[tabs].DisplayText+"' onclick = 'level3_bad_programs_clicked(this,parent_node);' onmouseover = 'menu_styling(this,true,false);' onmouseout = 'menu_styling(this,false,false);' class='menu'style='border-right: green thin dotted; border-top: green thin dotted; border-left: green thin dotted; border-bottom: green thin dotted;' >";
                tab += "<img src = '" + image + "' height='16' width='16'/> &nbsp;";
                tab += "<a href='javascript:nothing();'>" + l3_tab_all.Tabs[tabs].DisplayText  +  "</a>";
                tab += "<img style = 'display:none;' id = 'l3_" + l3_tab_all.Tabs[tabs].DisplayText + "_loading_img' src = '" + active_l3_image + "' height='16' width='16' /></td>";
    
         
            }
          } 
        }
      }

    }


    return tab;

}
// methods that are needed to create the third level hidden programs
function build_level3_hidden_programs(l3_nawty_list,level2_selected_tab)
{
    create_new_table("hidden_program_list_level3_div","hiddenprograms_level3_table");
    remove_table_level3_hidden_programs();
    create_new_table("hidden_program_list_level3_div","hiddenprograms_level3_table");
    create_level3_badlist_menu_items(l3_nawty_list,level2_selected_tab);
		
}

function remove_table_level3_hidden_programs()
{
    try
    {
        var d = document.getElementById('hidden_program_list_level3_div');
        var olddiv = document.getElementById("hiddenprograms_level3_table");
        d.removeChild(olddiv);

    }
    catch(x)
    {
        alert(x);
    }
}
// function build_level3_menu_item(display_text,url,image)
// {
//     if(image == null)image = "";
//     
//     var tab = "<tr>";
//     tab += "<td id = 'l3_"+display_text+"'  onmouseover = 'menu_styling(this,true,false);' onmouseout = 'menu_styling(this,false,false);' class='menu' style='border-right: green thin dotted;height:24px; border-top: green thin dotted; border-left: green thin dotted; border-bottom: green thin dotted;' >";
//     tab += "<img src = '" + image + "' height='16' width='16'/> &nbsp;";
//     tab += "<a onclick = 'menu_styling(this.parentNode,true,true);'class = 'podmenu' href = '" + url + "' target = 'contentFrame'>" + display_text +  "</a>";
//     tab += "<img style = 'display:none;' id = 'l3_" + display_text + "_loading_img' src = '" + active_l3_image + "' height='16' width='16' /></td></tr>";
//     
//     return tab;
// }

function build_level3_menu_item(display_text,url,image)
{
    var tab = "<li id='l3_" + display_text +
              "'  onmouseover='menu_styling(this,true,false);' onmouseout='menu_styling(this,false,false);' class='menu l3_menu' >";
    if(image != null) {
      tab += "<img src='" + image + "' height='16' width='16' class='l3_icon'/>";
    }
    tab += "<a onclick='menu_styling(this.parentNode,true,true);' class='podmenu' href='" + url + "' target='contentFrame'>" + display_text +  "</a>";
    tab += "<img style='display:none;' class='l3_loading' id='l3_" + display_text + "_loading_img' src='" + active_l3_image + "' height='16' width='16' /></li>";

    return tab;
}

function empty(){};

//*************************************************************
// Henry
function level3_bad_programs_clicked(a,progname)
{
    var good_name =  a.id.substring(3,a.id.length);//extraxt the name of the program without its 'l3_'
    l3_nawty_list.splice(l3_nawty_list.indexOf(good_name),1);//removes the selected program from the bad list
    goodlist_l3_names.unshift(good_name);//add the selected program to the beginning of the good list
    build_level3_menus(progname);
    change_l3_div_visibility();// hides the div
}
//************************************************************
//Henry
// Checks if the div is visible if it is it will be hidden
function change_l3_div_visibility()
{
    var status = document.getElementById("hidden_program_list_level3_div").style.visibility;
    if(status == "visible")
    {
        status = document.getElementById("hidden_program_list_level3_div").style.visibility = "hidden";
        document.getElementById("level3_bad_programslist").innerHTML = "<img  src ='/images/bullet_arrow_up_level3.png'</img>";
    }
}
//*************************************************************
// kan delete word
function percentage_extra()
{
    var constant =1;
    var count  =2;

    count  += l3_nawty_list.length-1;
    return (count*constant);

}
//*************************************************************
function get_percentage(children)
{
    amount_used  = 0 ; 
    last_node =   children.childNodes.length;
    amount_used +=  children.childNodes[last_node-1].offsetTop;

    amount_used +=  children.childNodes[last_node-1].offsetHeight;
    height_level3 =  document.getElementById("hidden_program_list_level3_div").style.height;

    var new_height_without_unit =  remove_sign(height_level3);



    return new_div_level3_height =amount_used+2;


}
//***************************************************************
function remove_sign(height_with_sign)
{
    var use_me  = height_with_sign;
    var new_height = "";
    for(i = 0 ; i < height_with_sign.length ;i++ )
    {
        if(i < height_with_sign.length-2)
        {
            new_height += height_with_sign[i];
        }

    }

    return new_height;
}
//******************************************************************
// removes the % sign
function remove_percentage(percentage)
{
    var new_percentage = "";
    for(i= 0 ; i <percentage.length;i++)
    {
        if(i < percentage.length-1 )
        {
            new_percentage += percentage[i];
        }

    }
    return new_percentage;
}
//******************************************************************
// Henry
// Calculates the level 3 div position as it changes in size depending on how many programs are on the badlist
function correct_level3_position()
{

    var table =document.getElementById("hiddenprograms_level3_table");
    var new_div3_height =  get_percentage(table);// gets the amount of pixels needed for the div
    var amount_lost = 150 - new_div3_height;
    var percent_change = ((amount_lost/window.innerHeight)*100);// howmuch percentage the div has changed with

    document.getElementById("hidden_program_list_level3_div").style.height = new_div3_height;
    //  var old_top  = document.getElementById("hidden_program_list_level3_div").style.top;

    //   var old_top_without_percentage = remove_percentage(old_top);


    if(new_div3_height <150)
    {
        var screen_height =  window.innerHeight;
        var screen_base = (95/100*screen_height);
        var change =(percent_change/100*screen_height);

        document.getElementById("hidden_program_list_level3_div").style.top= (screen_base-new_div3_height)+"px";
    }
    else
    {
        var screen_height = window.innerHeight;
        var new_pos = screen_height-152-(5/100*screen_height);
        document.getElementById("hidden_program_list_level3_div").style.height = "152px";
        document.getElementById("hidden_program_list_level3_div").style.top=new_pos+"px";
    }

}
