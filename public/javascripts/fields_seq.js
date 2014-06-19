        var selected_label
        
        //----------------------------------------------------------------------
        //''Labels'' should be populated from the rails runtime app context
        //----------------------------------------------------------------------
        labels = new Array;
        //labels[0] = "commodity";
        //labels[1] = "variety";
        //labels[2] = "pc_code";
        
        function nothing()
        {
        }
        
        //----------------------------------------------------------------------------
        //'a' is the selected hyperlink which text holds the name of a label field
        //---------------------------------------------------------------------------
        
        function set_selected_style(e)
        {
             e.style.borderRight = "gray thin solid";
             e.style.borderLeft = "gray thin solid";
             e.style.borderTop = "gray thin solid";
             e.style.borderBottom = "gray thin solid"; 
             e.style.backgroundColor = "whitesmoke";
        
        }
        
        //-------------------------------------------------------
        //This method updates the hidden field ''label_sequences'
        //with the complete current sequence
        //-------------------------------------------------------
        function set_sequence()
        {
            hidden_field = document.getElementById("label_sequences_hidden_field");
            seq = "[";
            for(i = 0;i < labels.length ; i ++)
            {
              if(i == labels.length - 1)
                seq += "'" + labels[i] + "']";   
              else
                seq += "'" + labels[i] + "',"; 
              
              hidden_field.value = seq;
            }
        
        }
        
         function set_unselected_style(e)
        {
             e.style.borderRight = "none";
             e.style.borderLeft = "none";
             e.style.borderTop = "none";
             e.style.borderBottom = "none"; 
             e.style.backgroundColor = "white";
        
        }
        
        function select(a)
        {
        
           if(selected_label != null)
                //selected_label.parentNode.style.backgroundColor = "white";
                set_unselected_style(selected_label.parentNode)
                selected_label = a
                //a.parentNode.style.backgroundColor = "whitesmoke";
                set_selected_style(a.parentNode);
                
        
        }
       
       function find_label_index()
       {
            for(i = 0;i < labels.length;i++)
             {
                if(labels[i] == selected_label.innerHTML)
                    return i
             }
             
             alert('error: label not found in labels array');
       }
       
        function go_up()
        {
           //swap the selected label with one with one index lower
           curr_index = find_label_index();
           
            //1)find the 'a' with text of index one less than this one and
            //set its text to the label with 'curr_index'
            //2)Set the selected link to text
            //   of label with 'curr_index - 1'
            table = document.getElementById('label_fields');
            fields = table.getElementsByTagName("a");
            
            for(i = 0;i < fields.length;i ++)
            {
                if(fields[i].innerHTML == labels[curr_index - 1])
                {
                    fields[i].innerHTML = selected_label.innerHTML;
                    selected_label.innerHTML = labels[curr_index - 1]; 
                    //now swap the contents of the labels collection
                    temp = labels[curr_index - 1]
                    labels[curr_index - 1] = labels[curr_index]
                    labels[curr_index] = temp
                    //move the selection cursor with the moved label
                    //selected_label.parentNode.style.backgroundColor = "white";
                    set_unselected_style(selected_label.parentNode)
                    
                    //fields[i].parentNode.style.backgroundColor = "whitesmoke";
                    selected_label = fields[i];
                    set_selected_style(fields[i].parentNode)
                    set_sequence();
                 }   
            }        
        
        }
    
        function go_down()
        {
           //swap the selected label with one with one index lower
           curr_index = find_label_index();
           
            //1)find the 'a' with text of index one less than this one and
            //set its text to the label with 'curr_index'
            //2)Set the selected link to text
            //   of label with 'curr_index - 1'
            table = document.getElementById('label_fields');
            fields = table.getElementsByTagName("a");
            
            for(i = 0;i < fields.length;i ++)
            {
                if(fields[i].innerHTML == labels[curr_index + 1])
                {
                    fields[i].innerHTML = selected_label.innerHTML;
                    selected_label.innerHTML = labels[curr_index + 1]; 
                    //now swap the contents of the labels collection
                    temp = labels[curr_index + 1]
                    labels[curr_index + 1] = labels[curr_index]
                    labels[curr_index] = temp
                    //selected_label.parentNode.style.backgroundColor = "white";
                     set_unselected_style(selected_label.parentNode)
                    //fields[i].parentNode.style.backgroundColor = "whitesmoke";
                   
                    selected_label = fields[i];
                     set_selected_style(fields[i].parentNode)
                     set_sequence();
                    
                 }   
            }        
        
        }