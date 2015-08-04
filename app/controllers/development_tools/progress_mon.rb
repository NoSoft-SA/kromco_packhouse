class DevelopmentTools::ProgressMonController < ApplicationController

 
def progress

   progress = Progress.new
   progress.update("hello hans",34)
   @progress = progress.to_xml
   render :inline => %{<%= @progress %>
	}
   
  end

end