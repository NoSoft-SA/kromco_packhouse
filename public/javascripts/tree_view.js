// JavaScript Document
// <script language="JavaScript1.2" type="text/JavaScript">
// Copyright (c)2005 Rewritten Software.  http://www.rewrittensoftware.com
// This script is supplied "as is" witrhout any form of warranty. Rewritten Software 
// shall not be liable for any loss or damage to person or property as a result of using this script.
// Use this script at your own risk!
// You are licensed to use this script free of charge for commercial or non-commercial use providing you do not remove 
// the copyright notice or disclaimer.


//------------------------------------------------------------------------------------------------
//Hans additions: => context menus; Tree nodes no longer load documents directly;
//                   instead, a context menu from a list of pre-defined and pre-build context menus
//                   (associated with tree nodes with a 'node type' naming convention)
//                   is shown (popped-up). From there a user can load urls by clicking on the
//                   links of a context menu
//               =>  dynamic addition, removal and editing of nodes:
//                   Three methods have been added so that nodes can be manipulated ON THE CLIENT
//                   after the tree have been build initially. This has the great advantage that
//                   the tree can keep its state on the client, regardless of server side operations
//                   that affects the tree-state. Server side code can simply send a single java
//                   script command (add, edit or delete) to alter the tree-state. Server side code
//                   also need not keep track of the id of the affected tree node, since the id of
//                   the clicked(affected) node is stored on the client.
//               =>  tree-content pane: the tree-view assumes the following page structure:
//                   * The tree itself and its context menus are build on a window that has an
//                      internal frame. The content (page or form) for a given command on a context menu
//                      (loaded for a given tree node click) is loaded in the internal frame. When the
//                      content has loaded it should call the 'stop_spinner()' method on the parent
//                      frame to stop the 'spinning gif' inside the menu.
//------------------------------------------------------------------------------------------------

// document.captureEvents(Event.MOUSEDOWN);
 document.onmousedown = MouseDown;

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
   var divs_for_nodes = [];
  
  //sample code to create a context menu definition;
    //var Context_Menu_definitions = new Array;
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
   
   if(window.parent.menu_list === null)
   {
    window.parent.menu_list = [];
   }
    
   //for(menu_id in Context_Menu_definitions)
   for(m_id in Context_Menu_definitions)
   {
     //if (Context_Menu_definitions.hasOwnProperty(menu_id))
     if (Context_Menu_definitions.hasOwnProperty(m_id))
         {
      //var context_menu_definition = Context_Menu_definitions[menu_id];
      var context_menu_definition = Context_Menu_definitions[m_id];
      div =build_context_menu(context_menu_definition);
      document.body.appendChild(div);
      window.parent.menu_list[i]= div.id;
      i++;
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
      if (context_menu_definition["commands"].hasOwnProperty(command))
          {
     
        row = create_menu_command(context_menu_definition["commands"][command],null);
        table.appendChild(row);
          }
    }
    
    //create the exit command- the one to hide the menu
     row = create_menu_command(null,true,div.id);
     table.appendChild(row);
     //alert('exit build context menu()');
     //alert(div.innerHTML);
     return div;
}

function stop_spinner()
{
     window.parent.user_action_ocurred();
     var old_htm = active_spinner.parentNode.innerHTML;
     var pattern = /<img[^<>]*id=\"spinner1.*>/;
     var new_htm = old_htm.replace(pattern, '');
//     var pos = old_htm.indexOf("<img id=\"spinner1\"");
//     var new_htm = old_htm.substring(0,pos);
     
     active_spinner.parentNode.innerHTML = new_htm;
     
     if(HIDE_MENU_ON_LOAD_COMPLETE)
     {
        mpos = clicked_node_id.indexOf("!");
        node_type = clicked_node_id.substr(0,mpos);
        menu_id = "menu_" + node_type;
        hide_menu(menu_id);
     }
     
     var loading_pic = window.parent.document.getElementById("content_loading_gif");
     if (loading_pic !== null) {
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
    
    var spinner = document.createElement("img");
    spinner.src = "/images/spinner.gif";
    spinner.id = "spinner1";
   
    spinner.valign = "center";
    a.parentNode.appendChild(spinner);
    active_spinner = spinner;
    
     var loading_pic = window.parent.document.getElementById("content_loading_gif");
     if (loading_pic !== null) {
       loading_pic.style.visibility = "visible";
     }
    
    window.frames[0].window.location.href = url;
}




function hide_menu(menu_id)
{
    //get ref to menu- which is the div
    div = document.getElementById(menu_id);
    if (div !== null)
    {
        div.style.visibility = "hidden";
    }

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
    
    if(is_exit_command !== null && is_exit_command === true)
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
   if (link !== null)
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
   if (link !== null)
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
    if(clicked_node_id !== null)
    {
        //alert('in hide');
        pos = clicked_node_id.indexOf("!");
        node_type = clicked_node_id.substr(0,pos);
        menu_id = "menu_" + node_type;
        hide_menu(menu_id);
    }
    
    set_unselect_node_style(clicked_node_id);
    
    clicked_node_id = clicked_node_link_id;
    //LINK SELECT FEATURE
    set_select_node_style(clicked_node_id);
    
    pos = clicked_node_id.indexOf("!");
    node_type = clicked_node_id.substr(0,pos);
    menu_id = "menu_" + node_type;
    //alert('menu_id is: ' + menu_id);
    menu = document.getElementById(menu_id);
    if(menu !== null)
    {
        
        menu.style.top = Y.toString() + "px";
        menu.style.left = X.toString() + "px";
        menu.style.visibility = "visible";
       
    }
    //alert('exit show_context_menu');
}

// Define the array that will contain the mapping table for ids to images.
var iconMap = new Array();
var iconList = new Array( iconMap );

function Toggle(item)
{
    
  var idx = -1;
  for( i = 0; i < iconList.length; i++ )
  {
    if( iconList[i][0] == item )
    {
      idx = i;
      break;
    }
  }
  
  if( idx < 0 ) {
    alert( "Could not find key in Icon List." );
  }
       
  var div=document.getElementById("D"+item);
  var visible=(div.style.display!="none");
  var key=document.getElementById("P"+item);
  
  
  // Check if the item clicked has any children. If it does not then remove the plus/minus icon
  // and replace it with a transaparent gif.
  var removeIcon = div.hasChildNodes() === false;
  
  if( key !== null )
  {
    if( !removeIcon )
    {
      if (visible)
      {
         div.style.display="none";
         key.innerHTML="<img src='/images/trees/plus.gif' width='16' height='16' hspace='0' vspace='0' border='0'>";
      }
      else
      {
          div.style.display="block";
        key.innerHTML="<img src='/images/trees/minus.gif' width='16' height='16' hspace='0' vspace='0' border='0'>";
      }
    }
    else {
      key.innerHTML="<img src='/images/trees/transparent.gif' width='16' height='16' hspace='0' vspace='0' border='0'>";
    }
  }

  // Toggle the icon for the tree item
  key=document.getElementById("I"+item);
  if( key !== null )
  {
    if (visible)
    {
       div.style.display="none";
       key.innerHTML="<img src='"+iconList[idx][1]+"' width='16' height='16' hspace='0' vspace='0' border='0'>";
    }
    else
    {
        div.style.display="block";
      key.innerHTML="<img src='"+iconList[idx][2]+"' width='16' height='16' hspace='0' vspace='0' border='0'>";
    }
  }  
}

function Expand() {
   divs=document.getElementsByTagName("DIV");
   for (i=0;i<divs.length;i++) {
   divs[i].style.display="block";
   key=document.getElementById("x" + divs[i].id);
   key.innerHTML="<img src='/images/trees/textfolder.gif' width='16' height='16' hspace='0' vspace='0' border='0'>";
   }
}

function Collapse() {
   divs=document.getElementsByTagName("DIV");
   for (i=0;i<divs.length;i++) {
   divs[i].style.display="none";
   key=document.getElementById("x" + divs[i].id);
   key.innerHTML="<img src='/images/trees/folder.gif' width='16' height='16' hspace='0' vspace='0' border='0'>";
   }
}

function AddImage( parent, imgFileName )
{
  img=document.createElement("IMG");
  img.setAttribute( "src", imgFileName );
  img.setAttribute( "width", 16 );
  img.setAttribute( "height", 16 );
  img.setAttribute( "hspace", 0 );
  img.setAttribute( "vspace", 0 );
  img.setAttribute( "border", 0 );
  parent.appendChild(img);
}

function CreateUniqueTagName( seed )
{
  var tagName = seed;
  var attempt = 0;
  
  if( tagName === "" || tagName === null )
  {
    tagName = "x";
  }

  while( document.getElementById(tagName) !== null )
  {
    tagName = "x" + tagName;
    if( attempt++ > 50 )
    {
      alert( "Cannot create unique tag name. Giving up. \nTag = " + tagName );
      break;
    }
  }
  
  return tagName;
}

//-----------------------------------------------------------------------------
//This method is used to add a tree-node dynamically; i.e. on the client
//------------------------------------------------------------------------------


function AddNode(parent_node_id, img1FileName, img2FileName, nodeName, node_type, node_id)
{
    
    if(parent_node_id === null)
    {
        parent_node_id = clicked_node_id;
    }
        
       div = document.getElementById(divs_for_nodes[parent_node_id]);
       table = document.getElementById("table_" + parent_node_id);
       img = table.getElementsByTagName("img")[0];
       
       CreateTreeItem(div, img1FileName, img2FileName, nodeName, node_type, node_id );
       
       //Add a plus sign to the parent's toggle image, if the current image is transparent
       table = document.getElementById("table_" + parent_node_id);
       img = table.getElementsByTagName("img")[0];
       if (img.src.indexOf("transparent")!= -1) {
        img.src = "/images/trees/plus.gif";
       }
        
}


//-----------------------------------------------------------------------------------
//This method is quite tricky, because of the way nodes are added to the tree. The create-
//tree_item method adds a node in the following way:
//-> A table is created to contain the actual visible stuff of a node (+- image, links, etc)
//-> The table is added to the passed-in parent node, which is a div- like the following one...
//-> A div is created for the node, which is then appended to the passed-in parent div, SO...
//=> A node is not contained inside a single parent container, but inside two containers:
//   1) The table for the visible stuff, and
//   2) A div to hold children of this node, each of which will also consist of these two things, SO
//    NB and bottomline: one has to delete both the div and the table to completely remove
//    any given node
//-----------------------------------------------------------------------------------
function RemoveNode(node_id)
{
    
    if(node_id === null)
    {
        node_id = clicked_node_id;
    }
       div = document.getElementById(divs_for_nodes[node_id]);
       table = document.getElementById("table_" + node_id);
       div.parentNode.removeChild(div);
       table.parentNode.removeChild(table);
       
        for( i=0; i < iconList.length; i++ )
        {
          if( iconList[i][0] == node_id )
          {
               iconList[i] = null;
    
          }
        }
        // iconList[iconList.length] = new Array( uniqueId, img1FileName, img2FileName );
       
       
       //remove the node from the element map
}

function EditNode(node_id,link_text)
{
    
    if(node_id === null)
    {
        node_id = clicked_node_id;
    }
        
       link = document.getElementById(node_id);
       link.innerHTML = link_text;

}
// Creates a new package under a parent. 
// Returns a TABLE tag to place child elements under.

//-----------------------------------------------------------------------------------
//     The 'id' follows the naming convention: <node type>_<id>
// ->  url and target can thus be replaced by parameters: 'node_type' and 'node_id'
// ->  A potentially tricky situation: we want to use a node id that is meaningful
//     to server side business logic, e.g. a record id in a database table. But the
//     tree demands unique id's'- because every node must be identifiable by a unique
//     id. The problem is that record ids aren't always unique, e.g  in a users tree
//     many users can have listed under them the same security per mission- so the server
//     side code need then to manage this situation by generating unique id's, by e.g.
//     a mapping mechanism
//-----------------------------------------------------------------------------------

function CreateTreeItem( parent, img1FileName, img2FileName, nodeName, node_type, node_id )
{
  var uniqueId = CreateUniqueTagName( nodeName );
  
  if (node_id !== null) {
     uniqueId = node_id + "_" + nodeName;
  }
  
  var delete_icon = false;
  for( i=0; i < iconList.length; i++ )
  {
    if( iconList[i][0] == uniqueId )
    {
         //iconList[i][0] = null
           //alert( "Non unique ID in Element Map. '" + uniqueId + "'" );
           //return;
           delete_icon = true;
    }
  }
    
    if (delete_icon) {
      new_icon_list =  [];
        for( i=0; i < iconList.length; i++ ){
      if( iconList[i][0] == uniqueId )
      {
         //iconList[i][0] = null
           //alert( "Non unique ID in Element Map. '" + uniqueId + "'" );
           //return;
        }
       else
       {
          new_icon_list[new_icon_list.length] =  iconList[i];
       
       }}
       iconList = new_icon_list; }
    
    
  iconList[iconList.length] = [ uniqueId, img1FileName, img2FileName ];

  table = document.createElement("TABLE");
  if( parent !== null )
  {
    parent.appendChild( table );
  }

  table.setAttribute( "border", 0 );
  table.setAttribute( "cellpadding", 1 );
  table.setAttribute( "cellspacing", 1 );
    
  tablebody = document.createElement("TBODY");
  table.appendChild(tablebody);
    
     row=document.createElement("TR");
     row.setAttribute('id','row_' + node_id);
  tablebody.appendChild( row );

  // Create the cell for the plus and minus.
  cell=document.createElement("TD");
  cell.setAttribute( "width", 16 );
  row.appendChild(cell);
  
    // Create the hyperlink for plus/minus the cell
  a=document.createElement("A");
  cell.appendChild( a );
  a.setAttribute( "id", "P"+uniqueId );
  a.setAttribute( "href", "javascript:Toggle(\""+uniqueId+"\");" );
  AddImage( a, "/images/trees/plus.gif" );
  
  // Create the cell for the image.
  cell=document.createElement("TD");
  cell.setAttribute( "width", 16 );
  row.appendChild(cell);
    
  // all the event to call when the icon is clicked.
  a=document.createElement("A");
  a.setAttribute( "id", "I"+uniqueId );
  a.setAttribute( "href", "javascript:Toggle(\""+uniqueId+"\");" );
  cell.appendChild(a);

  // Add the image to the cell
  AddImage( a, img1FileName );

  // Create the cell for the text
  cell=document.createElement("TD");
  cell.noWrap = true;
  a=document.createElement("A");
  a.setAttribute( "id", uniqueId );
  cell.appendChild( a );
  if( node_type !== null && node_id !== null )
  {
      a.setAttribute( "id", node_type + "!" + node_id ); 
      //hans changed: url replaced with javascript function
    a.setAttribute( "href", "javascript:show_context_menu(\"" + node_type + "!" + node_id + "\");" );
    //hans change: target property on url not needed anymore
    //alert("a.href is: " + a.href);
    text=document.createTextNode( nodeName);
    table.id = "table_" + node_type + "!" + node_id ;

    a.appendChild(text);
  }
  else
  {
    text=document.createTextNode( nodeName );
    cell.appendChild(text);
  }
  row.appendChild(cell);
   
    divs_for_nodes[node_type + "!" + node_id] = "D" + uniqueId;
  return CreateDiv( parent, uniqueId);
}

// Creates a new DIV tag and appends it to parent if parent is not null.
// Returns the new DIV tag.
function CreateDiv( parent, id )
{
  div=document.createElement("DIV");
  if( parent !== null )
  {
    parent.appendChild( div );
  }
    
  div.setAttribute( "id", "D"+id );
  div.style.display  = "none";
   div.style.marginLeft = "2em";
  
  return div;
}

// This is the root of the tree. It must be supplied as the parent for anything at the top level of the tree.
var rootCell = null;

// This is the entry method into the Tree View. It builds an initial single row, single cell table tat will 
// contain the tree. It initialises a global object "rootCell". This object must be used as the parent for all 
// top-level tree elements.
// There are two methods for creating tree elements: CreatePackage() and CreateNode(). The images for the 
// package are hard coded. CreateNode() allows you to supply your own image for each node element.
function Initialise()
{
   //alert('in init');
  body = document.getElementById("tree_container");
  //body.setAttribute( "leftmargin", 2 );
  //body.setAttribute( "topmargin", 0 );
  //body.setAttribute( "marginwidth", 0 );
  //body.setAttribute( "marginheight", 0 );
  
  table = document.createElement("TABLE");
  body.appendChild( table );

  table.setAttribute( "border", 0 );
  table.setAttribute( "cellpadding", 1 );
  table.setAttribute( "cellspacing", 1 );
    
  tablebody = document.createElement("TBODY");
  table.appendChild(tablebody);
    
  row=document.createElement("TR");
  tablebody.appendChild(row);
    
  cell=document.createElement("TD");
  row.appendChild(cell);   
  
  rootCell = cell;  // Initialise the root of the tree view.
  //added by Hans
  //build_context_menus();
}
