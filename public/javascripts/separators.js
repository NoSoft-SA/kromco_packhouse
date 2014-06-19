
 var separators = new Array;
 var separator_states = new Array;
 var n_separators;
 var input_fields = new Array;


 function get_row_end_pos(text)
 {
   i = 5;
  
   found = false;
   while(!found)
   {
     
     if(text[i - 5] + text[i -4] + text[i - 3] + text[i - 2] + text[i - 1] == "</tr>")
        found = true;
     else
       i ++;
     
     
   }
   
   
   return i;
   
 }
 


  function get_start_pos(text,start_pos,matcher)
 {
   i = start_pos;
   found = false;
   chars = matcher.length
   
   while(!found)
   {
     word = "";
     for(c = chars ; c > 0; c--){
      word += text[i - c];
     }
     
      if(word == matcher)
        found = true;
     else
       i --;
     
   }
   
   return i;
   
 }
 
  
  function get_form_htm()
  {
     form = document.getElementById('applet_container').innerHTML;
    sep1_start = form.indexOf('separator1');
    
    sep1_clean_start = get_start_pos(form,sep1_start,"<tr>")
    //alert("form: " + form.substring(0,sep1_clean_start - 4));
    return form.substring(0,sep1_clean_start - 4);
  }
  
  function get_form_end_htm()
  {
    form = document.getElementById('applet_container').innerHTML;
    form_end_start = form.indexOf("submit_button");
    form_end_clean_start = get_start_pos(form,form_end_start,"</tr>")
    form_end_htm = form.substring(form_end_clean_start,form.length -1);
   
    return form_end_htm;
  
  }
  
  function get_collapsed_separator(separator_id)
  {
    form = document.getElementById('applet_container').innerHTML;
    this_sep_start = form.indexOf(separator_id);
    
    this_sep_clean_start = get_start_pos(form,this_sep_start,"<tr>") -4
    
     rest_htm = form.substring(this_sep_clean_start,form.length);
     
     
     this_sep_end = get_row_end_pos(rest_htm)
     
     return rest_htm.substring(0,this_sep_end) + "</tr>"
  
  
  }
  
  
  function get_separator_htm(separator_id)
  {
    //get start_pos - that is clean start pos (starting with <tr>)
    //get end pos: it is the clean starting pos of the next separator - 1
    //if the next separator does not exist, then this is the bottom one,
    // in which case the end is '<input type='submit''
    
    form = document.getElementById('applet_container').innerHTML;
    this_sep_start = form.indexOf(separator_id);
    
    this_sep_clean_start = get_start_pos(form,this_sep_start,"<tr>") -4
    
    next_sep_id = ""
    next_sep_val = parseInt(separator_id[separator_id.length -1]) + 1;
    next_sep_id = "separator" + next_sep_val.toString();
    
    next_sep_start = form.indexOf(next_sep_id);
    
    if(next_sep_start != -1)
    {
      next_sep_clean_start = get_start_pos(form,next_sep_start,"<tr>")
    
      this_sep_htm = form.substring(this_sep_clean_start, next_sep_clean_start - 4);
    }
    else
    {   
      
        form_end_start = form.indexOf("submit_button");
        
        form_end_clean_start = get_start_pos(form,form_end_start,"</tr>")
        this_sep_htm = form.substring(this_sep_clean_start, form_end_clean_start);
    }
    
    
    return this_sep_htm;
  
  
  }
  
  
 function collapse_all()
 {
    store_control_values();
    
     for(f = 1; f <= n_separators; f++)
    {
       id = "separator" + f.toString();
       //alert(id + ": " + separator_states[id]);
       if (separator_states[id] == null)
        separator_states[id]= true; //expanded
    }
    
    
    //write all seps to memory that you can
    for(b = 1; b <= n_separators; b++)
    {
       //alert("loop");
        id = "separator" + b.toString();
        
         
        el = document.getElementById(id);
       // alert("cid: " + id);
        if(separator_states[id] == true)
        {
           
            separators[id] = get_separator_htm(id);
            
         
        }
    }
    
    //set states to collapsed
     for(b = 1; b <= n_separators; b++)
    {
       id = "separator" + b.toString();
       //alert(id + ": " + separator_states[id]);
       separator_states[id] = false;
       
    }
    
    //rebuild form in collapsed state
    new_form = get_form_htm();
    
    for(d = 1; d <= n_separators; d++)
    {
        id = "separator" + d.toString();
       // alert(id);
        el = document.getElementById(id);
    
          if(separator_states[id] == true)
          {
            new_form += separators[id];
            //alert(separators[id]);
          }
          else
          {
            new_form += get_collapsed_separator(id)
          }
   
    }
    //alert(get_form_end_htm());
    new_form += get_form_end_htm();
    document.getElementById('applet_container').innerHTML = new_form;
    
    set_images();
    
    
 
 }
 
 function expand_all()
 {
     store_control_values();
     
     for(f = 1; f <= n_separators; f++)
    {
       id = "separator" + f.toString();
       //alert(id + ": " + separator_states[id]);
       if (separator_states[id] == null)
        separator_states[id]= true; //expanded
    }
    
    
    //write all seps to memory that you can
    for(b = 1; b <= n_separators; b++)
    {
       //alert("loop");
        id = "separator" + b.toString();
        
         
        el = document.getElementById(id);
       // alert("cid: " + id);
        if(separator_states[id] == true)
        {
           
            separators[id] = get_separator_htm(id);
            
         
        }
    }
    
    //set states to expanded
     for(b = 1; b <= n_separators; b++)
    {
       id = "separator" + b.toString();
       //alert(id + ": " + separator_states[id]);
       separator_states[id] = true;
       
    }
    
    //rebuild form in collapsed state
    new_form = get_form_htm();
    
    for(d = 1; d <= n_separators; d++)
    {
        id = "separator" + d.toString();
       // alert(id);
        el = document.getElementById(id);
    
          if(separator_states[id] == true)
          {
            new_form += separators[id];
            //alert(separators[id]);
          }
          else
          {
            new_form += get_collapsed_separator(id)
          }
   
    }
    //alert(get_form_end_htm());
    new_form += get_form_end_htm();
    document.getElementById('applet_container').innerHTML = new_form;
    
    set_images();
    
    restore_control_values();
    
    return true;
 
 }
 
 function set_images()
 {
    for(x = 1; x <= n_separators; x++)
    {
       id = "separator" + x.toString();
       img_id = id + "_img";
       //alert(id + ": " + separator_states[id]);
       if (separator_states[id]== true)
         document.getElementById(img_id).src = "/images/expanded.png";
       else
         document.getElementById(img_id).src = "/images/collapsed.png";
       
     
    }
    
   
 }
 
 function set_observer_for_reworks_carton_edit()
 {
 
  //el = document.getElementById("ajax_distributor_cell")
 
   //alert((el == null).toString());
  //-----------------------
   //CARTON EDIT FORM
   //-----------------------
   if(document.getElementById('carton_edit_carton_pack_product_code'))
   {
     new Form.Element.EventObserver('carton_edit_carton_pack_product_code', function(element, value) {new Ajax.Updater('calculated_mass_cell', '/production/reworks/cpc_changed', {asynchronous:true, evalScripts:true, onComplete:function(request){
     img = document.getElementById('img_carton_edit_carton_pack_product_code');
     if(img != null)img.style.display = 'none';}, onLoading:function(request){show_element('img_carton_edit_carton_pack_product_code');}, parameters:value})})
   }
   
   if(document.getElementById('carton_edit_item_pack_product_code'))
   {
    new Form.Element.EventObserver('carton_edit_item_pack_product_code', function(element, value) {new Ajax.Updater('calculated_mass_cell', '/production/reworks/ipc_changed', {asynchronous:true, evalScripts:true, onComplete:function(request){
    img = document.getElementById('img_carton_edit_item_pack_product_code');
    if(img != null)img.style.display = 'none';}, onLoading:function(request){show_element('img_carton_edit_item_pack_product_code');}, parameters:value})})
   }
   
   if(document.getElementById('carton_edit_items_per_unit'))
   {
      new Form.Element.EventObserver('carton_edit_items_per_unit', function(element, value) {new Ajax.Updater('calculated_mass_cell', '/production/reworks/items_per_unit_changed', {asynchronous:true, evalScripts:true, onComplete:function(request){
      img = document.getElementById('img_carton_edit_items_per_unit');
      if(img != null)img.style.display = 'none';}, onLoading:function(request){show_element('img_carton_edit_items_per_unit');}, parameters:value})})
   }
   
   if(document.getElementById('carton_edit_units_per_carton'))
   {
      new Form.Element.EventObserver('carton_edit_units_per_carton', function(element, value) {new Ajax.Updater('calculated_mass_cell', '/production/reworks/units_per_carton_changed', {asynchronous:true, evalScripts:true, onComplete:function(request){
      img = document.getElementById('img_carton_edit_units_per_carton');
      if(img != null)img.style.display = 'none';}, onLoading:function(request){show_element('img_carton_edit_units_per_carton');}, parameters:value})})
    }
    
   if(document.getElementById('carton_edit_organization_code'))
   { 
      new Form.Element.EventObserver('carton_edit_organization_code', function(element, value) {new Ajax.Updater('target_market_short_cell', '/production/reworks/marketer_org_combo_changed', {asynchronous:true, evalScripts:true, onComplete:function(request){
      img = document.getElementById('img_carton_edit_organization_code');
      if(img != null)img.style.display = 'none';}, onLoading:function(request){show_element('img_carton_edit_organization_code');}, parameters:value})})
  
   }
 }
 
 
 function set_observer()
 {
  
   
   //---------------------------------------
   //PACK MATERIALS FORM
   //---------------------------------------
   if(document.getElementById('pack_material_product_commodity_group_code'))
   {
     new Form.Element.EventObserver('pack_material_product_commodity_group_code', function(element, value) {new Ajax.Updater('commodity_code_cell', '/products/pack_material_product/pack_material_product_commodity_group_code_changed', {asynchronous:true, evalScripts:true, onComplete:function(request){to_clears = [['pack_material_product_marketing_variety_code','pack_material_product_commodity_code']];
     clear_combos(to_clears);
     img = document.getElementById('img_pack_material_product_commodity_group_code');
     if(img != null)img.style.display = 'none';}, onLoading:function(request){show_element('img_pack_material_product_commodity_group_code');}, parameters:value})});
     
     if(document.getElementById('pack_material_product_marketing_variety_code'))
     {
        new Form.Element.EventObserver('pack_material_product_commodity_code', function(element, value) {new Ajax.Updater('marketing_variety_code_cell', '/products/pack_material_product/pack_material_product_commodity_code_changed', {asynchronous:true, evalScripts:true, onComplete:function(request){
        img = document.getElementById('img_pack_material_product_commodity_code');
        if(img != null)img.style.display = 'none';}, onLoading:function(request){show_element('img_pack_material_product_commodity_code');}, parameters:value})});
    }
   }
  }
 
 function restore_control_values()
 {
  
   for(key in input_fields)
   {
     stored_control = input_fields[key];
    
    //if (!stored_control.id)alert(stored_control.name);
    
    if(stored_control.id )
      active_control = document.getElementById(stored_control.id);
    else{
      if(stored_control.name)
      {
        if(stored_control.type == "select-one")
        {
           active_control = document.getElementsByName(stored_control.name)[0] 
        }
        else
        {
            active_controls = document.getElementsByName(stored_control.name);
            if(active_controls.length > 1)
                active_control = active_controls[1];
         }
      }
    }
    
     if(active_control)
     {
        //active_control = stored_control;
       // alert (active_control.type);
        if(active_control.type == "select-one")
         {
            if(stored_control.options)
            {
              for(y = 0;y < stored_control.options.length;y++)
              {
              
                 active_control.options[y].selected = stored_control.options[y].selected;
                 active_control.options[y].value = stored_control.options[y].value;
                 active_control.options[y].text = stored_control.options[y].text;
             }
            }
          }
        else if(active_control.type == "text")
          active_control.value = stored_control.value;
          
        else if(active_control.type == "checkbox"){
          //alert(active_control.type);
          active_control.value = stored_control.value;
          active_control.checked = stored_control.checked;
          }
          
        else if(active_control.type == "textarea"){
           active_control.childNodes[0] = stored_control.childNodes[0];
           }
        
         else if(active_control.type == "hidden"){
           active_control.value = stored_control.value;
           }
          
      }
          
   }
    
   comm_group_dropdown = document.getElementById('pack_material_product_commodity_group_code');
   if(comm_group_dropdown)
    set_observer();
    
    //reworks_carton_code
    set_observer_for_reworks_carton_edit();
 
 }
 
  
 
 function store_control_values()
 {
   
   inputs = document.forms[0].getElementsByTagName("input");
  
   for(j = 0; j < inputs.length; j++)
   {
     if(inputs[j].id)
      input_fields[inputs[j].id]= inputs[j];
     
     else if(inputs[j].name)
       input_fields[inputs[j].name]= inputs[j];
     // alert(inputs[j].type + ":" + inputs[j].name);
      
     input_fields[inputs[j].id]= inputs[j];
      
   }
   
   inputs = document.forms[0].getElementsByTagName("select");
   
    for(j = 0; j < inputs.length; j++){
   //if(inputs[j].id)
   // alert("sel id " + inputs[j].id);
   //else
   // alert("sel name " + inputs[j].name);
   
     id = ""
     if(inputs[j].id)
      id = inputs[j].id
     else
      id = inputs[j].name
      
     input_fields[id]= inputs[j];  
   }
   
   inputs = document.forms[0].getElementsByTagName("textarea");
  
   for(j = 0; j < inputs.length; j++)
   {
     input_fields[inputs[j].id]= inputs[j];
     //alert(inputs[j].id);    
   }
   
  
 }
 
 
 
  //--------------------------------------------------------------------------------
  // This method has to toggle (show or hide) the clicked separator which represents
  // a group of fields.
  // processing:
  // 1) build a list of all separators: 
  //   --> see if you can find the separator id, if not, it means the separator is hidden
  //       and you can assume that it's htm is stored in memory (separators array)
  // 2) rebuild the entire form, if you get to the selected separator, see if you can
  //      find it in the form, If not, it means it is currently collapsed, o you must
  //      expand it by adding it to the building process- get it's htm from memory(stored when collapsed previously)
  //      If found, it means it is currently expanded, and you must collapse it by not
  //      adding it to the building process- BUT before doing so you must add it's
  //      htm to the separators collection
  //------------------------------------------------------------------------------
  
 
  
  function hide_separator(sep)
  {
     store_control_values();
     
    for(x = 1; x <= n_separators; x++)
    {
       id = "separator" + x.toString();
       //alert(id + ": " + separator_states[id]);
       if (separator_states[id] == null)
        separator_states[id]= true; //expanded
    }
    
    
    //write all seps to memory that you can
    for(b = 1; b <= n_separators; b++)
    {
       //alert("loop");
        id = "separator" + b.toString();
        
         
        el = document.getElementById(id);
       // alert("cid: " + id);
        if(separator_states[id] == true)
        {
           
            separators[id] = get_separator_htm(id);
         
        }
    }
    
   
    //alert("loop exited");
    //rebuild form
    new_form = get_form_htm();
    //alert("new form: " + new_form);
    for(d = 1; d <= n_separators; d++)
    {
        id = "separator" + d.toString();
       // alert(id);
        el = document.getElementById(id);
        
        if (id == sep.id)
        {
          //alert(" sep: " + separators[id]);
          if(separator_states[id] == false)//we need to add it to building process
          {
            
            new_form += separators[id];
             //alert(id + ":" + separators[id]);
          }
          else //we need to add just the ' collapsed separator'
          {
            new_form += get_collapsed_separator(id)
            //alert("collapsed: " + get_collapsed_separator(id));
          }
        }
        else
        {
          
          if(separator_states[id] == true)
          {
            new_form += separators[id];
            //alert(id + ":" + separators[id]);
          }
          else
          {
            new_form += get_collapsed_separator(id)
          }
   
        }
    }
    //alert(get_form_end_htm());
    new_form += get_form_end_htm();
    document.getElementById('applet_container').innerHTML = new_form;
    separator_states[sep.id] = !separator_states[sep.id];
    set_images();
    
    restore_control_values();
   
  }
