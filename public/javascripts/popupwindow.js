

function update_form()
{


   try
   {
    var frames = window.opener.frames;
    var input_values_changed = this.document.getElementById("applet_container");
    var selection_values =  input_values_changed.getElementsByTagName("option");
    var input_length =    input_values_changed.getElementsByTagName("input");
    var popupwindow_obj =  document.getElementById("popupwindow_kromco_1");
    var select_length =    input_values_changed.getElementsByTagName("select");
   
    for(select = 0 ; select < select_length.length ; select++)
     {
      var option = select_length[select].getElementsByTagName("option");
      for(i =0 ; i < option.length ; i++)
        {
         if(option[i].selected == true )
            {
              try
              {
             
             //option[i].selected == true;
             //option[i].value == 
            
          if(document.getElementById(select_length[select].id).value.length > 0 )
          {
              frames[1].document.getElementById(select_length[select].id).value = document.getElementById(select_length[select].id).value;
           }  
          
            //   addeditem.name = "load_values_for_fields["+changed_name+"]";
            //   addeditem.value = option[i].value;
             
              }
              catch(error_mesg)
             {
               alert(error_mesg+" error_loc_1");
             }  
          }
       }
     } 
       
    for(itemsadded = 0 ; itemsadded < input_length.length ;itemsadded++ )
    {
      if((input_length[itemsadded].type  == "text") & (document.getElementById(input_length[itemsadded].id).value.length > 0 ) )
      {
       frames[1].document.getElementById(input_length[itemsadded].id).value = document.getElementById(input_length[itemsadded].id).value;

     }
      if((input_length[itemsadded].type  == "checkbox" ) )
       {
       frames[1].document.getElementById(input_length[itemsadded].id).value = document.getElementById(input_length[itemsadded].id).value;
      
      //   var   addeditem = document.createElement("input");
      //   addeditem.id = "created_field_"+input_length[itemsadded].name;
      //   addeditem.type = "hidden";
      //    var changed_name =change_input_name(input_length[itemsadded].name);
      //    addeditem.name = "load_values_for_fields["+changed_name+"]";
      //    addeditem.value = input_length[itemsadded].value;
      //    popupwindow_obj.appendChild(addeditem);
         }
    }
   
   //var input_values_changed = this.document.getElementById("applet_container");
   //var input_length =    input_values_changed.getElementsByTagName("input");
   // headerstext_count =   frames[1].global_js_grid.getColumnCount();
    }
    catch(messageerror)
    {
    alert(messageerror+" error_loc_2");
    }


  //alert(document.getElementById("treatment_treatment_code").value )
 //  var frames = window.opener.frames
 //  frames[1].document.getElementById("treatment_treatment_code").value = document.getElementById("treatment_treatment_code").value 
//  alert("Here we can do the updating")
alert("The data have been moved");
window.close();
}

function get_data_for_form_update()
{
 
  var app_container =  document.getElementById("applet_container");
  form_innerhml = app_container.childNodes[1].innerHTML;
  app_container.innerHTML ="<form id='popupwindow_kromco_1'  onSubmit='javascript:update_form();'  method='post' >"+form_innerhml +"</form>";

}

function open_window_link(url)
{

  refined_url  = [];
  count = 0;


  //code to split out width and height from url string- width and height are enclosed with !..!
    dimension_parts = ["800","380"];
    url_parts =   url.split("!");
    if(url_parts.length > 1)
    {
        url_parts.each( function(u) {
          if (u.indexOf(':') > -1) {
            dimension_parts = u.split(":");
          }
        });
    }

  url = url_parts[0];

  currentstring ="";
  for( i = 0 ; i < url.length ; i++)
  {

    if(url[i] == '%' | i == url.length-1)
    {
      if(i == url.length-1)
      {
        currentstring += url[i];
      }
      refined_url[count] = currentstring;
      currentstring ="";
      count ++;
    }
    else
    {
      currentstring += url[i];
    }
  }

  if (refined_url[1] !== undefined)
  {

    window_created = window.parent.open("http://"+refined_url[0]+"/"+refined_url[1]+"", "",
        "menubar=0,location=0,resizable=1,scrollbars=1,status=0,width=" + dimension_parts[0] + ",height=" + dimension_parts[1]);

    //    netscape.security.PrivilegeManager.
    //   enablePrivilege("UniversalBrowserWrite");
    //window_created.locationbar.visible=
    //    !window_created.locationbar.visible;
    //  alert(window_created.locationbar.visible = 'false');

    //sleep(1);
      setTimeout(function() {
    window_created.resizeTo (dimension_parts[0], dimension_parts[1]); // Chrome doesn't always respect width & height parameters...
    window_created.moveTo (225,225);
      }, 100);
    // window.parent.id = "parent_window_id";
    // this.window.id ="popup_1"
  }
  else
  {
    //    "menubar=yes,location=yes,resizable=yes,scrollbars=yes,status=yes"
    // "menubar=yes,location=yes,resizable=yes,scrollbars=yes,status=yes,width=800,height=380"
    //window_created = window.parent.open('http://'+refined_url[0]+'', '',
    window_created = window.parent.open('http://'+refined_url[0], '',
        'menubar=1,resizable=1,scrollbars=1,status=1,width=' + dimension_parts[0] + ',height=' + dimension_parts[1]); // Chrome seems to work if location not mentioned....
        //'menubar=yes,location=no,resizable=yes,scrollbars=yes,status=yes,width=800,height=380'); // Chrome seems to need location=no !!!!!
        //'menubar=yes,location=yes,resizable=yes,scrollbars=yes,status=yes,width=800,height=380,left=0,top=0');
    //window.open(filename,"","width="+winwidth+",height="+winheight+",scrollbars=yes ,menubar=no,location=no,left=0,top=0");

    //sleep(1);
      setTimeout(function() {
    window_created.resizeTo (dimension_parts[0], dimension_parts[1]); // Chrome doesn't always respect width & height parameters...
    window_created.moveTo (225,225);
      }, 100);
    //FIRE_window_id
    // window.parent.id = "parent_window_id";
    //  this.window.id ="popup_1"
  }

}
//***************************************************
function imdone()
{
  var app_container =  window.self.document.getElementById("applet_container");
  form_innerhml = app_container.childNodes[1].innerHTML;
  app_container.innerHTML ="<form id='popupwindow_kromco_1' action= /raw_materials/treatment/update_treatment method='post' onSubmit='javascript:yay();' >"+form_innerhml +"</form>";


}
//***************************************************
function change_input_name(name)
{
  var new_name ="";
  for(char_index = 0 ; char_index < name.length ; char_index++)
    {
     if(name[char_index]  == "[" | name[char_index] == "]")
      {
       if(name[char_index] == "[")
         {
           new_name += "$";
         }
         else
          {
            new_name += "?";
          }
       }
       else
       {
        new_name += name[char_index];
       }
  }

return new_name;
}
//************************************************************
function yay()
{

   try
   {
      var frames = window.opener.frames;
    var input_values_changed = this.document.getElementById("applet_container");
    var selection_values =  input_values_changed.getElementsByTagName("option");
    var input_length =    input_values_changed.getElementsByTagName("input");
    var popupwindow_obj =  document.getElementById("popupwindow_kromco_1");
    var select_length =    input_values_changed.getElementsByTagName("select");
   
    for(select = 0 ; select < select_length.length ; select++)
     {
      var option = select_length[select].getElementsByTagName("option");
      for(i =0 ; i < option.length ; i++)
        {
         if(option[i].selected == true )
            {
              try
              {
               var   addeditem = document.createElement("input");
               addeditem.id = "created_field_"+option[i].value;
               addeditem.type = "hidden";
               var changed_name =change_input_name(select_length[select].name);
               addeditem.name = "load_values_for_fields["+changed_name+"]";
               addeditem.value = option[i].value;
               popupwindow_obj.appendChild(addeditem);
              }
              catch(error_mesg)
             {
               alert(error_msg+" error_loc_1"); 
             }  
          }
       }
     } 
       
    for(itemsadded = 0 ; itemsadded < input_length.length ;itemsadded++ )
    {
    
       if(input_length[itemsadded].type  == "text")
         {
          var   addeditem = document.createElement("input");
          addeditem.id = "created_field_"+input_length[itemsadded].name;
          addeditem.type = "hidden";
          var changed_name =change_input_name(input_length[itemsadded].name);
          addeditem.name = "load_values_for_fields["+changed_name+"]";
          addeditem.value = input_length[itemsadded].value;
          popupwindow_obj.appendChild(addeditem);
         }
          if(input_length[itemsadded].type  == "checkbox")
            {
             var   addeditem = document.createElement("input");
             addeditem.id = "created_field_"+input_length[itemsadded].name;
             addeditem.type = "hidden";
             var changed_name =change_input_name(input_length[itemsadded].name);
             addeditem.name = "load_values_for_fields["+changed_name+"]";
             addeditem.value = input_length[itemsadded].value;
             popupwindow_obj.appendChild(addeditem);
            }
    }
   
    var input_values_changed = this.document.getElementById("applet_container");
    var input_length =    input_values_changed.getElementsByTagName("input");
    headerstext_count =   frames[1].global_js_grid.getColumnCount();
    }
    catch(messageerror)
    {
    alert(messageerror+" error_loc_2");
    }
}
//**************************************************************************************
function get_table_row(ruby_id)
{
// to get the row number it will run through the column headings and search for the with 
// the name 'id' , when it has founded the 'id' column it will start running throught 
// the rows insearch of the ruby id that it received

 try
 {
  var frames = window.opener.frames;
  //Gets the number of columns
  var column_count =   parseInt(frames[1].global_js_grid.getColumnCount());
  for(column_nr  = 0 ;column_nr < column_count ; column_nr++ )
  {
  // tests if it id
   if(frames[1].global_js_grid.getHeaderText(column_nr) == "id")
   {
   // iterates through the  rows
   for(row_nr =  0 ; row_nr <  parseInt(frames[1].global_js_grid.getRowCount());row_nr++)
   {
     try
     {
      var text_in_selected_cell =  frames[1].global_js_grid.getCellText(column_nr,row_nr );
      var x = parseInt(text_in_selected_cell);
     }
     catch(x)
         {
           alert(x+" error_loc_3");
         }
     try
     {
     //tests if the id's are the same'
      if((x) == (parseInt(ruby_id)) )
        {
         return  row_nr;
        }
     }
      catch(x)
      {
       alert(x+" error_loc_4");
      }
   }
}

}
}
catch(x)
{
alert(x+ "error_loc_5");
}
}
// receives the updated data with the ruby id
function get_ruby_id(new_values)
{

    try
    {
        var  array_update = new_values.split(",");

        for(updated_item = 0 ; updated_item < array_update.length ;updated_item++ )
           {
            var update_array_detail = array_update[updated_item].split("#");
            var update_key = update_array_detail[0];
            var update_value = update_array_detail[1];
            if (update_key == "id")
              {
                return  update_value;
              }
           }
    }
    catch(x)
    {
        alert(x);
    }
}
//************************************************************************************
// updates the grid 
// 

function update_js_grid(array,new_values)
{


 var frames = window.opener.frames;
 var column_count =  parseInt(frames[1].global_js_grid.getColumnCount());
 parseInt(frames[1].global_js_grid.setColumnCount(column_count+1));
 var ruby_object_id = get_ruby_id(new_values);
 var table_row_nr =  get_table_row(ruby_object_id);

 try
 {
 // breaks the strings up into arrays 
  changed_values  = new Array();
  changed_values = new_values.split(",");
  load_values = new Array();
  load_values = array.split(",");
  
  for(load_item = 0 ; load_item < changed_values.length ; load_item ++)
  {
  // seperates the key from the value  'the new values, the updated values'
   var updated  = changed_values[load_item].split("#");
   var key_update  =  updated[0];
   var value_update =  updated[1];
    
    for(start_item = 0 ; start_item < load_values.length ; start_item ++  )
    {
    // seperates the key from the value 'values at load'
     var ini_values = load_values[start_item].split("?");
     var load_key  = ini_values[0].split("$");
     var load_value  = ini_values[1].split("_");
      //if the key of the new and old values are the same and the heading of the column corresond to the 
      // 'key_update value' then the cell wil be updated with the new values
     if(key_update == load_key[1])
       {
        for(column_nr = 0 ; column_nr  < column_count ;column_nr++)
         {
          if(frames[1].global_js_grid.getHeaderText(column_nr) == key_update )
           {

            frames[1].global_js_grid.setCellText(value_update,column_nr,table_row_nr  );
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
  alert("You have updated the grid");
 this.window.close();
}
