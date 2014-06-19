var msg_personal_image_id = "img_personal_msg";
var msg_dept_image_id = "img_dept_msg";
var msg_company_image_id = "img_company_msg";
var images_root = "/images/messages/";
var active_image = null; //the clicked image

//form properties ids
var message_form_id = "message_form";
var msg_form_header_id = "message_type";
var msg_form_created_by_id = "created_by";
var msg_form_created_at_id = "created_at";
var msg_form_msg_body_id = "message_body";

var form_close_image_html = "<img onclick = 'close_message_form();' src= '/images/messages/close_form.png' style='left: 189px; position: relative; top: 0px'/>"
//this script assumes that the following datastructures have been created
//3 arrays: personal_msg_data,dept_msg_data and company_msg_data
//each array instance must have the following fields defeined:
// => 'message'
// => 'created_at'
// => 'created_by'
// => 'message_type'
//Note: even if no messages have been defined- these 3 variables must be declared, at least


function close_envelopes()
{
    var msg_personal = document.getElementById(msg_personal_image_id);
    if(msg_personal != null)
        msg_personal.src = images_root + "envelope.png";
    
    var msg_dept = document.getElementById(msg_dept_image_id);
    if(msg_dept != null)
        msg_dept.src = images_root + "envelope.png"; 
        
    var msg_company = document.getElementById(msg_company_image_id);
    if(msg_company != null)
        msg_company.src = images_root + "envelope.png";  

}


function populate_form(msg_type,created_at,created_by,message)
{
    
    window.parent.document.getElementById(msg_form_header_id).innerHTML = form_close_image_html + msg_type //+ ;
    if(created_at != null)
        window.parent.document.getElementById(msg_form_created_at_id).innerHTML = created_at;
    if(created_by != null)
        window.parent.document.getElementById(msg_form_created_by_id).innerHTML = created_by;
    if(message != null)
        window.parent.document.getElementById(msg_form_msg_body_id).innerHTML = message;
    

}


function envelope_clicked(envelope_img)
{
    
    close_envelopes();
    envelope_img.src = images_root + "opened_envelope.png"
   
    //get the correct message data structure
    msg_data = null;
    var type ="";
    
    if(envelope_img.id.indexOf("personal") > -1)
    {   type = "personal";
        msg_data = personal_msg_data;
    }
    else if(envelope_img.id.indexOf("dept")> -1)
    {
        type = "departmental";
        msg_data = dept_msg_data;
    }
    else if(envelope_img.id.indexOf("company")>-1)
    {
        type = "company";
        msg_data = company_msg_data;
     }
    else
        alert("The ids for the message images have been defined incorrectly");
        
    //populate and show form
    if(msg_data != null)
        if(msg_data['message']!= "null")
        {
            populate_form(msg_data['message_type'],msg_data['created_at'],msg_data['created_by'],msg_data['message']);
            window.parent.document.getElementById(message_form_id).style.visibility = "visible";
        
        }
        else
        {
            alert("There is no " + type + " message at this moment");
            close_envelopes();
        }
    else
    {
        close_envelopes();
         alert("There is no " + type + " message at this moment");
     }
    
    
     // active_image = envelope_img;
  
    

}


