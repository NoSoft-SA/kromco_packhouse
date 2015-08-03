

// document.captureEvents(Event.MOUSEDOWN);
 document.onmousedown = MouseDown;
 var Context_Menu_definitions = new Array;

  var X = 0;
  var Y = 0;
  
  var active_spinner = null;

  var HIDE_MENU_ON_LOAD_COMPLETE = true;
  
  function MouseDown(e)
  {
      //X = e.clientX + document.body.scrollLeft; //e.clientX;
      //X = e.clientX + document.documentElement.scrollLeft; //e.clientX;
      X = e.clientX + ((document.body.scrollLeft) ?  document.body.scrollLeft : document.documentElement.scrollLeft); //e.clientX;
      pX = e.pageX;
      pY = e.pageY;
      //Y = e.clientY + document.body.scrollTop;//e.clientY;
      //Y = e.clientY + document.documentElement.scrollTop;//e.clientY;
      Y = e.clientY + ((document.body.scrollTop) ?  document.body.scrollTop : document.documentElement.scrollTop);//e.clientY;
      
    }
  
   var clicked_node_id = null;
   var divs_for_nodes = new Array;
  
  //sample code to create a context menu definition;
   // var Context_Menu_definitions = new Array;
    //menu1 = new Array;
    //menu1["node_type"] = "Actors";
    //menu1["commands"] = new Array;
    //menu1["commands"][0]= new Array;
    //menu1["commands"][0]["caption"] = "hire expensive actor";
    //menu1["commands"][0]["target_action"] = "www.google.com";
    //menu1["commands"][1]= new Array;
    //menu1["commands"][1]["caption"] = "hire cheap actor";
    //menu1["commands"][1]["target_action"] = "www.google.com";
    //Context_Menu_definitions["Actors"]= menu1;
    
    //menu2 = new Array;
    //menu2["node_type"] = "Actor";
    //menu2["commands"] = new Array;
    //menu2["commands"][0]= new Array;
    //menu2["commands"][0]["caption"] = "fire actor";
    //menu2["commands"][0]["target_action"] = "www.google.com";
    //menu2["commands"][1]= new Array;
    //menu2["commands"][1]["caption"] = "fire actor spectacularly";
    //menu2["commands"][1]["target_action"] = "www.google.com";
    //Context_Menu_definitions["Actor"]= menu2;
    
    //alert('contexts defined');
    
  //============================================================================
  //Context_Menu_definitions[]:
  //it's an array of context menu objects- each context menu object
  //has two properties or keys:
  //['node_type']  => the node type associated with the context menu
  //['commands']=> a list of commands for the context menu. Each command
  //            is a map containing the following keys:
  //    ['caption']: caption => the display text of the link
  //    ['target_action']: target_action => the url to load in the content frame
  //                      this url will be the same for all nodes
  //                      of a given type
  //
  //note: when a context menu has been loaded, and a link on the
  //      menu is clicked, the 'id' associated with the tree node
  //      (from which the context menu has been loaded) will be appended
  //      to the url defined in 'target_action'. This 'id' is
  //      stored in a global variable on every node_click event.
  //=============================================================================

//This method relies on the existence of the object: Context_Menu_definitions[]
//From each definition object, it will build a context menu with visibility set
//to false



function build_context_menus()
{  
   //alert('enter build context menus()');
   var i = 0;
   
   if(window.parent.menu_list ==null)
    window.parent.menu_list = new Array;
    
   for(menu_id in Context_Menu_definitions)
   {
     if(menu_id.indexOf('menu') > -1){
        var context_menu_definition = Context_Menu_definitions[menu_id];
        div =build_context_menu(context_menu_definition);
        document.body.appendChild(div);
        window.parent.menu_list[i]= div.id
        i++;
        //alert(menu_id);
     }
    }
    //alert('exit build context menus()');
}

function build_context_menu(context_menu_definition)
{
    //alert('enter build context menu()');
    div = document.createElement("div");
    div.id = "menu_" + context_menu_definition["node_type"];
    //alert('context menu id: ' + div.id);
    div.style.visibility = "hidden";
    div.style.position = "absolute";
    div.style.backgroundColor = "whitesmoke";
    //now build the table and rows for each command inside
    //the div
    
    table = document.createElement("table");
    table.style.borderRight = "green thin solid"; 
    table.style.borderTop = "green thin solid";
    table.style.borderLeft = "green thin solid";
    table.style.borderBottom = "green thin solid";
    
    div.appendChild(table);
    for(command in context_menu_definition["commands"])
    { 
        i = context_menu_definition["commands"][command].toString().indexOf("function");
        //alert(i.toString());
        if(i == -1)
        { row = create_menu_command(context_menu_definition["commands"][command],null);
          //alert(row.innerHTML);
         table.appendChild(row);
        }
    }
    
    //create the exit command- the one to hide the menu
     row = create_menu_command(null,true,div.id);
     table.appendChild(row);
     //alert('exit build context menu()');
     
     return div;
     
}

function stop_spinner()
{
     window.parent.user_action_ocurred();
     var old_htm = active_spinner.parentNode.innerHTML;
     var pattern = /<img[^<>]*id=\"spinner1.*>/;
     var new_htm = old_htm.replace(pattern, '');
     // var pos = old_htm.indexOf("<img id=\"spinner1\"");
     // var new_htm = old_htm.substring(0,pos);
     
     active_spinner.parentNode.innerHTML = new_htm;
     
     if(HIDE_MENU_ON_LOAD_COMPLETE)
     {
        mpos = clicked_node_id.indexOf("!");
        node_type = clicked_node_id.substr(0,mpos);
        menu_id = "menu_" + node_type;
        hide_menu(menu_id);
     }
     
     var loading_pic = window.parent.document.getElementById("content_loading_gif");
     if (loading_pic !== null)
     {
       loading_pic.style.visibility = "hidden";
     }
    
}
//This function takes the passed-in url and uses the specified internal frames' window
//to navigate to the url- just before this, however, it has to append to the passed-in
//url an id- held in the global variable called 'clicked_node_id'
function link_to(url)
{
   //extract the id portion from the stored id- necessary since the
   //id also contains a 'type' indication that messes up the id from the
   //server's point of view
   //alert("in link to()");
    id = url;
    
    pos = clicked_node_id.indexOf("!");
    server_id = clicked_node_id.substr(pos + 1,clicked_node_id.length);
    //alert(server_id);
    url += "/" + server_id;
    //alert(url);
    //alert((window.frames.length))
    var a = document.getElementById(id);
    
    
    //**********Henry******************** 
  var   node_type = clicked_node_id.substr(0,pos);
  var    menu_id = 'menu_' + node_type;
    
    //**********Henry********************
    //var spinner = document.createElement("img");
    //spinner.src = "/images/spinner.gif";
    //spinner.id = "spinner1";
   
    //spinner.valign = "center";
   // a.parentNode.appendChild(spinner);
    //active_spinner = spinner;
    //active_spinner.style.visibility = "visible";
    
     var loading_pic = document.getElementById("content_loading_gif");
     if (loading_pic != null)
     loading_pic.style.visibility = "visible";
     clicked_node_id = "";
     if(popup_commands)
     {
   

       
          try
          {
              setTimeout(function() {
          context_popupwindow = window.parent.open(url, "context_popupwindow","location=1,status=1,scrollbars=1,width=800,height=380");
          context_popupwindow.moveTo (225,225);
          hide_menu(menu_id);
              },100);
            
          }
          catch(e)
          {
          alert(e);
          }
          
     }
     else
     {
     window.location.href = url;
     }
     try
     {

     }
     catch(error)
     {
     alert(error);
     }
}




function hide_menu(menu_id)
{
    //get ref to menu- which is the div
    div = document.getElementById(menu_id);
    if (div != null)
        div.style.visibility = "hidden";

}

function create_menu_command(command,is_exit_command,div_id)
{
    //alert('enter create_menu_command()');
    text = "";
    tr = document.createElement("tr");
    //img = command["image"];
    //alert(img);
    //image = document.createElement("img");
    //image.setAttribute("src", command["image"]);
    td = document.createElement("td");
    td.style.borderBottom = "gray thin dashed";
    tr.appendChild(td);
    a = document.createElement("a");
    
    if(is_exit_command != null && is_exit_command == true)
    {
        a.setAttribute( "href", "javascript:hide_menu('" + div_id + "');" ); 
        td.style.backgroundColor = "lightgray";
        text = "hide";
        td.setAttribute("align","center");
    }
    else
    {   
       
        a.setAttribute( "href", "javascript:link_to(\"" + command["target_action"]+ "\");" );
        a.setAttribute("id",  command["target_action"] );
       // alert(a.id);
        text = command["caption"];
        
        image = document.createElement("img");
        image.setAttribute("src", command["image"]);
        td.appendChild(image);
         
    }
    
    //alert(img);
    text=document.createTextNode(text);
    a.appendChild(text);
    //td.appendChild(image);
    td.appendChild(a);
    // alert('exit create_menu_command()');
   
    return tr;
   
}


//This function uses the id of the passed-in clicked link to
//derive the node_type (first part of the 'id' till the underscore).
//Then it stores the id in the
//global variable: 'clicked_node_id'. Then it finds a div with the
//id using naming convention: '<context_menu_><node_type>' and makes
//it visible

function set_select_node_style(link_id)
{  
  link = document.getElementById(link_id);
   if (link != null)
   {  
     link.style.boder = "dotted";
     link.style.borderRight = "gray thin solid";
     link.style.borderTop = "gray thin solid";
     link.style.borderBottom = "gray thin solid";
     link.style.borderLeft = "gray thin solid";
     link.style.backgroundColor = "whitesmoke";
    }
}

function set_unselect_node_style(link_id)
{  
   link = document.getElementById(link_id);
   if (link != null)
   {  
     link.style.borderRight = "white";
     link.style.borderTop = "white";
     link.style.borderBottom = "white";
     link.style.borderLeft = "white";
     link.style.backgroundColor = "white";
    }
}

function show_context_menu(clicked_node_link_id)
{
    //alert('enter show_context_menu');
    //alert('clicked_node_link_id: ' + clicked_node_link_id);
    if(clicked_node_id != null)
    {
        //alert('in hide');
        pos = clicked_node_id.indexOf("!");
        node_type = clicked_node_id.substr(0,pos);
        menu_id = "menu_" + node_type;
        hide_menu(menu_id);
    }
    
    set_unselect_node_style(clicked_node_id)
    
    clicked_node_id = clicked_node_link_id;
    //LINK SELECT FEATURE
    set_select_node_style(clicked_node_id)
    
    pos = clicked_node_id.indexOf("!");
    node_type = clicked_node_id.substr(0,pos);
    menu_id = "menu_" + node_type;
    //alert('menu_id is: ' + menu_id);
    menu = document.getElementById(menu_id);
    if(menu!=null)
    {
        
        menu.style.top = Y.toString() + "px";
        menu.style.left = X.toString() + "px";
        menu.style.visibility = "visible";
       
    }
    //alert('exit show_context_menu');
}


