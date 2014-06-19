var minRangeVal = 20;
var maxRangeVal = 90;
var ranges = null;


function reorder_range_controls()
{
    //go through all the rows in rows container and rename the
    //1)labels and 2)textbox and 3) row ids
       rows = document.getElementById("ranges_container").getElementsByTagName("tr");
       id = 1;
       
       for (i = 0; i < rows.length; i ++ )
       {
        row = rows[i];
        
         if(row.id.indexOf("rangetr")!= -1)
         {
           
           
           
            row.id = "rangetr_" + id.toString();
            //alert(row.innerHTML);
            label = row.getElementsByTagName("td")[0];
            label.removeChild(label.childNodes[0]);
            text = document.createTextNode("range " + id.toString());
            label.appendChild(text);
            
            textboxes = row.getElementsByTagName("input");
            txtFrom = textboxes[0];
            txtFrom.id =  "txtfromrange_" + id.toString();
            txtTo = textboxes[1];
            txtTo.id = "txttorange_" + id.toString();
            
            id ++;
       
         }
        }
}


//-------------------------------------------------------------
// This method makes sure that there are no overlapping ranges
// (i.e. every from-to-pair of values must be unique
//
//--------------------------------------------------------------
function check_ranges(ranges)
{
    err = "";
    for(i = 0; i < ranges.length; i++)
    {   
        curr_pair = ranges[i];
        if (curr_pair != null){
        for(z = 0; z < ranges.length; z++) 
        {
            if (z != i && ranges[z] != null)
            {
                //check from
                if (ranges[z][0] < curr_pair[0] && ranges[z][0] > curr_pair[1])
                    err += "\nranges " + (i-1).toString() + " and " + (z-1).toString() + " overlap";   
           
                else if (ranges[z][1] < curr_pair[0] && ranges[z][1] > curr_pair[1])
                    err += "\nranges " + (i-1).toString() + " and " + (z-1).toString() + " overlap"; 
            }
            
            if(err.length > 0)
             break;
        }}
    }

    return err;
}


function set_ranges()
{
  var err = "";
  id = 1;
  rows = document.getElementById("ranges_container").getElementsByTagName("tr");
  //find rows with id prepension of 'rangetr'
  //1)find the from and to textboxes and make sure that the from and to values fall within the
  //  base from ad to values
  //2)make sure that there are no overlapping values (check every from-to value pair against all other pairs)
  ranges = new Array;
  for (i = 0; i < rows.length; i ++ )
  {
    row = rows[i];
   
    if(row.id.indexOf("rangetr")!= -1)
    {
        id ++;
        textboxes = row.getElementsByTagName("input");
        txtFrom = textboxes[0];
        txtTo = textboxes[1];
        vals = new Array;
        vals[0] = parseInt(txtFrom.value);
        vals[1] = parseInt(txtTo.value);
        
        ranges[id] = vals
        if(vals[0] < maxRangeVal)
            err += "\nrange " + i.toString() + " is lower than the minimum value.";
        if(vals[1] > minRangeVal)
            err += "\nrange " + i.toString() + " is higher than the maximum value.";
            
        
    }
    
  
  }
  
  if (err.length == 0)
    err = check_ranges(ranges);
    
  if(err.length == 0)
    send_range_vals(ranges);
  
  return err;


}

function send_range_vals(ranges)
{
    str_ranges = "ranges = Array.new\n";
    index = 0;
    for(i = 0; i < ranges.length; i ++)
    {
       if(ranges[i]!= null)
       {
            if(!(isNaN(ranges[i][0])||isNaN(ranges[i][1])))
            {
                str_ranges += "range = Array.new\n";
                str_ranges += "range[0] = " + ranges[i][0] + "\n";
                str_ranges += "range[1] = " + ranges[i][1] + "\n";
                str_ranges += "ranges.push(range)\n"
            }
       }
    }
    
    document.getElementById("txtranges").value = str_ranges;
    alert(document.getElementById("txtranges").value);
}



function set_label_style(label)
{
  //"width: 100px; font-size: 12px; color: green; font-family: Arial;"
  label.style.width = "100px";
  label.style.fontSize = "12px";
  label.style.color = "green";
  label.style.fontFamily = "Arial";  


}

function remove_range(btn)
{
  
    //remove the entire row
    row = btn.parentNode.parentNode;
    document.getElementById("ranges_container").removeChild(row);
    reorder_range_controls();
}

function set_text_box_style(txtbox)
{
    //style="font-weight: bold; font-size: 12px; color: gray; font-family: Arial"
    txtbox.style.fontWeight = "bold";
    txtbox.style.fontSize = "12px";
    txtbox.style.color = "green";
    txtbox.style.fontFamily = "Arial";


}
function add_range_control()
{
    row = document.createElement("tr");
    id =  document.getElementById("ranges_container").childNodes.length;
    row.id = "rangetr_" + id.toString();
    
    label = document.createElement("td");
    set_label_style(label);
    text = document.createTextNode("range " + id.toString());
    label.appendChild(text);
    row.appendChild(label);
    
    //from cell
    cell = document.createElement("td");
    row.appendChild(cell);
    txtFrom = document.createElement("input");
    set_text_box_style(txtFrom);
    txtFrom.type = "text";
    txtFrom.id = "txtfromrange_" + id.toString();
    cell.appendChild(txtFrom);
    
    //to cell
    to_cell = document.createElement("td");
    row.appendChild(to_cell);
    txtTo = document.createElement("input");
    set_text_box_style(txtTo);
    txtTo.type = "text";
    txtTo.id = "txttorange_" + id.toString();
    to_cell.appendChild(txtTo);
    
    btn_cell = document.createElement("td");
    row.appendChild(btn_cell);
    delbtn = document.createElement("input");
    delbtn.type = "button";
    delbtn.id = "btndelrange_" + id.toString();
    delbtn.setAttribute("onclick","remove_range(this);");
    //style="background-image: url(del_range.png)" 
    delbtn.style.backgroundImage = "url(/images/del_range.png)";
    
    btn_cell.appendChild(delbtn);
    
    
    document.getElementById("ranges_container").appendChild(row);
}