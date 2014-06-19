document.onmousemove = mouseMove;
    
     var mousePos = 0;
     var moveCount = 0;
    
     
     var min_size = 10;
     var max_size = 90;
     var speed = 3;
     var size = 0;
     
     //array to hold list of cells to take part in resizing
     var sizing_cells = new Array;
     var active_cell = null;
     var rightmost_cell_id = "";
     var dragging = false;
     
     function add_sizing_cell(cell_id,is_rightmost)
     {
        var cell = document.getElementById(cell_id);
        cell.setAttribute("onclick","set_sizing_cell('" + cell_id + "');");
        cell.setAttribute("onmousedown","start_drag('" + cell_id + "');");
        cell.setAttribute("onclick","end_drag('" + cell_id + "');");
        cell.setAttribute("onmouseout","end_drag('" + cell_id + "');");
        
        
        if(is_rightmost)
            rightmost_cell_id = cell_id;
            
        sizing_cells[cell_id] = cell;
       
        size = sizing_cells.length -1;
        
        
     }
     
 
     function set_sizing_cell(cell_id)
     {
       
        active_cell = sizing_cells[cell_id];
     }
     
     
     function adjust_width(amount,cell)
     {
        
         
          var val_str = cell.width.substring(0,cell.width.length -1);
          var new_width_val = parseInt(val_str) + amount
          
          if(amount > 0 && new_width_val > max_size)
            return;
           
           if(amount < 0 && new_width_val < min_size)
               return;
          
          var new_width_str = new_width_val.toString() + "%";
          cell.width = new_width_str;
         
     
     }
     
     
     function resize(bigger)
     {   
     
         if (active_cell == null)
            return;
            
         moveCount++;
         if (moveCount < speed)
            return;
            
        
         if(!bigger)
         {
            
            adjust_width(size,active_cell);
            for(i = 0; i< sizing_cells.length;i++)
            {   
                if(sizing_cells[i].id != active_cell.id)
                    adjust_width(-1);
            
            }
            
              
         }
         
         else
         {
           
            adjust_width((-1*size),active_cell);
            for(i = 0; i< sizing_cells.length;i++)
            {   
                if(sizing_cells[i].id != active_cell.id)
                    adjust_width(1);
            
            }
         
         }
         
         moveCount = 0;
     }
     
     
    function mouseMove(ev){
        
        
        
        if(!dragging)
            return;
            
	    ev           = ev || window.event;
	    
	    
	    curr_mousePos = mouseCoords(ev);
	    
	    if (mousePos == 0)
	    {
	        mousePos = curr_mousePos
	       
	    }
	    else
	    {
	        if (rightmost_cell_id == active_cell.id)
	        {
	            if(curr_mousePos > mousePos)
	                resize(false);
	            else
	                resize(true);
	         }
	        else if(curr_mousePos > mousePos)
	            resize(true);
	        else
	            resize(false);
	    }
	    
	     mousePos = curr_mousePos;
	    
    }

    function mouseCoords(ev){
	    if(ev.pageX || ev.pageY){
		    return ev.pageX
	    }
	    return 
		    ev.clientX + document.body.scrollLeft - document.body.clientLeft;
		    
	    
    }
    
    
    function start_drag(cell_id)
    {
      dragging = true;
      
      mousePos = 0;
      active_cell = sizing_cells[cell_id];
      active_cell.style.cursor = "e-resize"
      moveCount = 0;
    }
    
    
    function end_drag(cell_id)
    {
        dragging = false;
        
        endpos = mousePos;
        active_cell = sizing_cells[cell_id];
        active_cell.style.cursor = "default"
        dragging = false;
         moveCount = 0;
    }

