var MWJ_progBar = 0;
var prog_bar_container = "mpanel";

 //----------
 //HOW TO USE
 //----------
 
  //Once the page has loaded, you can then contol the progress bar using:
  //set the progress bar to indicate a progress of 50%
  //myProgBar.setBar(0.1,true);  //add 10% to the progress bar's progress
  //myProgBar.setBar(0.1,false); //subtract 10% from the progress bar's progress
  //myProgBar.setCol('#ff0000'); //change the colour of the progress bar
  //alert( 'Current progress is ' + myProgBar.amt ) // read current progress
  
  
 function create_prog(){
		var myProgBar = new progressBar(
			1,         //border thickness
			'#000000', //border colour
			'#a5f3b1', //background colour
			'#043db2', //bar colour
			400,       //width of bar (excluding border)
			20,        //height of bar (excluding border)
			1          //direction of progress: 1 = right, 2 = down, 3 = left, 4 = up
		);
		
 }

function getRefToDivNest( divID, oDoc ) {
	if( !oDoc ) { oDoc = document; }
	if( document.layers ) {
		if( oDoc.layers[divID] ) { return oDoc.layers[divID]; } else {
			for( var x = 0, y; !y && x < oDoc.layers.length; x++ ) {
				y = getRefToDivNest(divID,oDoc.layers[x].document); }
			return y; } }
	if( document.getElementById ) { return document.getElementById(divID); }
	if( document.all ) { return document.all[divID]; }
	return document[divID];
}

function progressBar( oBt, oBc, oBg, oBa, oWi, oHi, oDr ) {
    doc = document.getElementById(prog_bar_container);
    text = ""
	MWJ_progBar++; this.id = 'MWJ_progBar' + MWJ_progBar; this.dir = oDr; this.width = oWi; this.height = oHi; this.amt = 0;
	//write the bar as a layer in an ilayer in two tables giving the border
	text = '<table border="0" id = "tbl_prog_bar" cellspacing="0" cellpadding="'+oBt+'"><tr><td bgcolor="'+oBc+'" >'+
		'<table border="0" cellspacing="0" cellpadding="0"><tr><td height="'+oHi+'" width="'+oWi+'" bgcolor="'+oBg+'">';
	if( document.layers ) {
		text += '<ilayer height="'+oHi+'" width="'+oWi+'"><layer bgcolor="'+oBa+'" name="MWJ_progBar'+MWJ_progBar+'"></layer></ilayer>' ;
	} else {
		text +=  '<div style="position:relative;top:0px;left:0px;height:'+oHi+'px;width:'+oWi+'px;">'+
			'<div style="position:absolute;top:0px;left:0px;height:0px;width:0;font-size:1px;background-color:'+oBa+';" id="MWJ_progBar'+MWJ_progBar+'"></div></div>';
	}
	text += '</td></tr></table></td></tr></table>\n' ;
	doc.innerHTML = text
	this.setBar = resetBar; //doing this inline causes unexpected bugs in early NS4
	this.setCol = setColour;
}
function resetBar( a, b ) {
	//work out the required size and use various methods to enforce it
	this.amt = ( typeof( b ) == 'undefined' ) ? a : b ? ( this.amt + a ) : ( this.amt - a );
	if( isNaN( this.amt ) ) { this.amt = 0; } if( this.amt > 1 ) { this.amt = 1; } if( this.amt < 0 ) { this.amt = 0; }
	var theWidth = Math.round( this.width * ( ( this.dir % 2 ) ? this.amt : 1 ) );
	var theHeight = Math.round( this.height * ( ( this.dir % 2 ) ? 1 : this.amt ) );
	var theDiv = getRefToDivNest( this.id ); if( !theDiv ) { window.status = 'Progress: ' + Math.round( 100 * this.amt ) + '%'; return; }
	if( theDiv.style ) { theDiv = theDiv.style; theDiv.clip = 'rect(0px '+theWidth+'px '+theHeight+'px 0px)'; }
	var oPix = document.childNodes ? 'px' : 0;
	theDiv.width = theWidth + oPix; theDiv.pixelWidth = theWidth; theDiv.height = theHeight + oPix; theDiv.pixelHeight = theHeight;
	if( theDiv.resizeTo ) { theDiv.resizeTo( theWidth, theHeight ); }
	theDiv.left = ( ( this.dir != 3 ) ? 0 : this.width - theWidth ) + oPix; theDiv.top = ( ( this.dir != 4 ) ? 0 : this.height - theHeight ) + oPix;
}
function setColour( a ) {
	//change all the different colour styles
	var theDiv = getRefToDivNest( this.id ); if( theDiv.style ) { theDiv = theDiv.style; }
	theDiv.bgColor = a; theDiv.backgroundColor = a; theDiv.background = a;
}