function expandDropDown(element) {
    var event;
    event = document.createEvent('MouseEvents');
    event.initMouseEvent('mousedown', true, true, window);
    element.dispatchEvent(event);
}

function startWebPdtBusySpinner() {
    var busy_spinner = document.getElementById('web_pdt_screen_busy_spinner');
    busy_spinner.style.visibility = "visible";
}

function stopWebPdtBusySpinner() {
    var busy_spinner = parent.document.getElementById('web_pdt_screen_busy_spinner');
    busy_spinner.style.visibility = "hidden";
}

function submitWebPdtScreen(submit_type) {
    var content_frame=document.getElementById('content_frame');
    startWebPdtBusySpinner();
    if(submit_type != 'menu' && validateScreen(content_frame) == false){
        return;
    }

    content_frame.contentDocument.getElementsByTagName('form')[0].submit();
}

function validateScreen(content_frame) {
    var required_fields = content_frame.contentWindow.required_fields;

    if(required_fields == null) {
        return true;
    }

    var error_fields = [];
    var messages = document.getElementById('messages');
    var msg = "";

    for(req in required_fields) {
        if( required_fields.hasOwnProperty( req ) ) {
            var required_field = content_frame.contentDocument.getElementById(required_fields[req]);
            if(required_field.value == "") {
                error_fields.push(required_field);
            }
        }
    }

    for(req in required_fields) {
        if( required_fields.hasOwnProperty( req ) ) {
            var required_field = content_frame.contentDocument.getElementById(required_fields[req]);
            if(required_field.value != "") {
                required_field.style.border = "1px solid grey";
            }
        }
    }

    if(error_fields.length > 0) {
        for(error_field in error_fields) {
            if( error_fields.hasOwnProperty( error_field ) ) {
                error_fields[error_field].style.border = "3px solid red";
                msg = msg + error_fields[error_field].id + " is a required field.   ";
            }
        }
        stopWebPdtBusySpinner()
        messages.value = msg;
        return false;
    }

    messages.value = msg;
    return true;
}

function setMessage(msg) {
    var messages = parent.document.getElementById('messages');
    messages.value = msg;
}

function onSubmitButtonClicked(mode,logged_on_user) {
    var content_frame=document.getElementById('content_frame');

    var logged_on_user_submit_value = content_frame.contentDocument.getElementById('web_pdt_screen_logged_on_user_submit_value');
    logged_on_user_submit_value.value = logged_on_user;

    var mode_submit_value = content_frame.contentDocument.getElementById('web_pdt_screen_mode_submit_value');
    mode_submit_value.value = mode;

    submitWebPdtScreen('button');
}

function onMenuSelectedScreenSubmit(content_frame,logged_on_user,menu_submit_value) {
    var mode_submit_value = content_frame.contentDocument.getElementById('web_pdt_screen_mode_submit_value');
    mode_submit_value.value = 0;

    var logged_on_user_submit_value = content_frame.contentDocument.getElementById('web_pdt_screen_logged_on_user_submit_value');
    logged_on_user_submit_value.value = logged_on_user;

    var current_menu_item = content_frame.contentDocument.getElementById('web_pdt_screen_web_pdt_current_menu_item_submit_value');
    current_menu_item.value= menu_submit_value;
}

function onPdtSpecialMenuClicked(content_frame, logged_on_user,special_menu_submit_value) {
    if(special_menu_submit_value.value=='1a') {
        mode_submit_value.value = 8;
    }else if(special_menu_submit_value.value=='1b') {
        mode_submit_value.value = 9;
    }else if(special_menu_submit_value.value=='1c') {
        mode_submit_value.value = 7;
    }else if(special_menu_submit_value.value=='1d') {
        mode_submit_value.value = 12;
    }else if(special_menu_submit_value.value=='1e') {
        mode_submit_value.value = 11;
    }else if(special_menu_submit_value.value=='1f') {
        mode_submit_value.value = 13;
    }else if(special_menu_submit_value.value=='1g') {
        mode_submit_value.value = 14;
    }

    var logged_on_user_submit_value = content_frame.contentDocument.getElementById('web_pdt_screen_logged_on_user_submit_value');
    logged_on_user_submit_value.value = logged_on_user;

    var current_menu_item = content_frame.contentDocument.getElementById('web_pdt_screen_web_pdt_current_menu_item_submit_value');
    current_menu_item.value= special_menu_submit_value;

}