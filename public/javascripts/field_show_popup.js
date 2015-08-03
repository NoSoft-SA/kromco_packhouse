
function getLeft(el) {
    var tmp = el.offsetLeft;
    el = el.offsetParent;
    while(el) {
       tmp += el.offsetLeft;
       el = el.offsetParent;
    }
    return tmp;
 }

function getTop(el) {
   var tmp = el.offsetTop;
   el = el.offsetParent;
   while(el) {
     tmp += el.offsetTop;
     el = el.offsetParent;
   }
   return tmp;
}


function show_column_detail(row_col_id)
{
   
    var recordDiv = document.getElementById("record_div");
   recordDiv.style.display = '';
   recordDiv.style.left = "60px"; //the_left + 'px';
   recordDiv.style.top =  "50px"; //the_top + 'px'; 

   recordDiv.style.width = "445px";
   recordDiv.style.height = "250px";
   recordDiv.style.paddingLeft = "7px";
   var innHtml = "<div id=\"record_caption\" style=\"height:20px; width:100%; background-color:#D8D6D4;\"><table border=\"0\" width=\"100%\" style=\"font-size:12pt; font-weight:bold;\"><tr><td style=\"text-align:right; height:15px;\"><img id=\"read_msg_img\" alt=\"close\" src=\"/images/form_close.PNG\" onclick=\"hide_div();\" /></td></tr></table></div><br />";
   innHtml += "<textarea id=\"record_field\" readonly=\"readonly\" style=\"width:435; height:200px;\" wrap=\"virtual\"></textarea>";
   
   recordDiv.innerHTML = innHtml;
   
   recordDiv.style.border = "1px black solid";

   recordDiv.scrollIntoView();
     
    new Ajax.Updater('record_field', '/development_tools/data/show_column_detail/' + row_col_id, {asynchronous:true, evalScripts:true});
}
  
function hide_div() {
   document.getElementById("record_div").style.display = "none";
}
