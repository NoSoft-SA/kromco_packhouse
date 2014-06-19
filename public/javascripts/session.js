var counter = 0;
var noSession = false;
var minutes_to_expiration = 60;
var elapsed_minutes = 0;
var timer;
var is_session_alive =false;
var logout_url = logout_url;
var session_check_timer = null;

function start_new_session()
{
  if (noSession === undefined || noSession === false) // switch off
  {
    is_session_alive = true;
    var timefunc = function()
    {
      elapsed_minutes ++;
      if(elapsed_minutes > minutes_to_expiration)
      {
        is_session_alive = false;
        alert("Your session has expired. To continue, please login again");
        clearInterval(timer);
        window.location.href = logout_url;
      }
    };
    timer = setInterval(timefunc, 60000);
    if(session_check_timer !== null) {
      clearInterval("session_check_event()");
    }
  }
}

function user_action_ocurred()
{
  elapsed_minutes = 0;
}

function session_check_event()
{
  if(! is_session_alive)
  {
    alert("You have to login first- pressing the 'back' button on the brower wont help!");
    window.location.href = logout_url;
  }
}

