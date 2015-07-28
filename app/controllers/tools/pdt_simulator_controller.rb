class Tools::PdtSimulatorController < ApplicationController
 
 def program_name?
    "pdt_simulator"
 end
 
 def bypass_generic_security?
   true
 end

 def build_pdt_simulator
   @pdt_simulator_client = Globals.pdt_simulator_client_server + "/web_pdt_login/pdt_login"

   render :inline=>%{
                      <script>
                        window.open("<%= @pdt_simulator_client %>","PdtSimulator","width=120,height=250,top=200,left=200,toolbar=0,menubar=0,status=0,scrollbars=0,resizable=0");
                      </script>
                    },:layout => 'content'

   return

 end


end