
 var timer;
 var count = 0;
  
 function prog_test()
 {  
    timer = setInterval("timer_event()",2000);
    window.frames[1].window.location.href = '/login/progress_test'
 
 }
 
 function timer_event()
 {
    count += 1;
    if(count < 5)
      get_progress();
    else
        clearInterval(timer);
 
 }
 

 function get_progress()
 {
    request = new XMLHttpRequest();
    request.overrideMimeType('text/xml');
    request.onreadystatechange = function ()
    {
        if(request.readyState == 4)
        {
            if(request.status == 200)
            {
                var xmldoc = request.responseXML;
                var rootnode = xmldoc.getElementsByTagName('progress').item(0);
                alert(rootnode.firstChild.data);
            }
            else
            {
              alert('There was a problem with the request');
            }
        
        
        }
      
    
    }
    
    request.open('GET','/development_tools/progress',true);
    request.send(null);
 
 
 }
 
