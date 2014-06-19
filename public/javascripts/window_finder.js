

function refresh_window(levels_down,window_name,message,close_window)
{
   
    frame = get_window(levels_down,window_name);


    if(frame != null)
    {

        //alert(frame.toString());
        if(message != null)
             alert(message);

            frame.location.reload(true);
    }
    else
        alert("window " + window_name + " not found");

  if(close_window != null && levels_down > 0)
  {
      
        window.close();
   }
    
}


function get_window(levels_down,name)
{
    base_frame = get_base_frame(levels_down);
    found_frame = find_local_frame(base_frame,name);
    return found_frame;
    


}


function find_local_frame(frame,frame_id)
{
    //alert("entered");
    // alert("name: " + frame.name);

    frames = frame.frames;
     //alert("outer LEN:" +  frames.length.toString());
    found_frame = null;

    if(frame.name == frame_id)
        return frame;


    //search through window.frames and their children
    if(frames != null && frames.length > 0)
    {
        for (i = 0;i < frames.length -1 ; i ++)
        {
            // alert("inner LEN:" +  frames[i].frames.length.toString());

            //search down
               
            found_frame = find_local_frame(frames[i],frame_id);
            if(found_frame != null)
               //  alert("returned1 : " + found_frame.toString());
                
                if(found_frame != null)
                    return found_frame;
        }
        
    }


}



function get_base_frame(level)
{
    //find the correct level in stack of popups
    frame = window;
    for(i = 0; i < level ;i ++)
    {
       // alert("iter: " + i.toString());
        if(frame.opener != null)
        {
            frame = frame.opener;
           // alert("opener id: " + frame.name);
        }
        
    }



    //now find the topmost frame at this level
    indexer = 0;
    if(levels > 0)
      current_frame = frame.frames[1];
     else
         current_frame = frame;
     
    not_done = true;

    while(not_done == true)
    {
       
        indexer ++;
        //alert(current_frame.name);
        if(current_frame.name == "contentFrame" ||indexer == 20)
            not_done = false;
        else
        {
            current_frame = current_frame.parent;
        }

    }

    return current_frame;

    

}
