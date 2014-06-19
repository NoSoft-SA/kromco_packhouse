class Tools::PdtSimulatorController < ApplicationController
 
 def program_name?
    "pdt_simulator"
 end
 
 def bypass_generic_security?
   true
 end
#    MENUSELECT  = 0;                    # Menu select/reconfig mode
#    ENTERDATA   = 1;                    # Submit button mode
#    IDLE        = 2;                    # Enter button
#    ENTER       = 3;                    # Normal transaction button
#    BUTTON1     = 4;                    # Yes button clicked mode
#    BUTTON2     = 5;                    # No button clicked mode
#    BUTTON3     = 6;                    # Cancel button mode
#    CANCEL      = 7;                    # Cancel special command mode
#    REFRESH     = 8;                    # Refresh special command mode
#    UNDO        = 9;                    # Undo special command mode
#    CHOICE      = 10;
     
 #format example: http://localhost:3000/services/symbol_pdt6800/process_request?trans_type=Quality_Control&mode=1&scancode1=53
 
 def build_pdt_simulator
   @pdt_simulator_client = Globals.pdt_simulator_client_server + "/PDTSimulator/index.jsp?"
   #puts "(((((((((((((((((((((((((((((((((((((((   URL  = " + @pdt_simulator_client.to_s
   #redirect_to(pdt_simulator_client)
   render :inline=>%{
                      <script>
                        window.open("<%= @pdt_simulator_client %>","PdtSimulator","width=320,height=550,top=200,left=200,toolbar=0,menubar=0,status=0,scrollbars=0,resizable=0");
                      </script>
                    },:layout=>'content'
 end

end