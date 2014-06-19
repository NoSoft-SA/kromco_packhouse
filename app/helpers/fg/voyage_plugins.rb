require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'

module ShippingPlugins
  class VoyageGridPlugin < ApplicationHelper::GridPlugin

    def initialize(env = nil, request = nil)
      @env = env
      @request = request

    end

    #---------------------------------------------------------------
    #This method allows the grid-client code to cancel the rendering
    #of a given cell
    #---------------------------------------------------------------
    def cancel_cell_rendering(column_name, cell_value, record)

      if column_name=="complete_voyage"
        if record['status']==nil || record['status'].upcase=="ACTIVE"
          return true
        else
          return false
        end
     end
    end

    #-------------------------------------------------------------------
    #This method allows a plugin to render the cell instead of the
    #grid column. To work, the same plugin must also implmement the
    #'cancel_cell_rendering' method and return true.
    #-------------------------------------------------------------------
    def render_cell(column_name, cell_value, record)

      if column_name=="complete_voyage"
        #{@env.img_tag('delete.png')}
        link_url = @env.link_to("complete", "http://" + @request.host_with_port + "/" + "fg/voyage/complete_voyage" + "/" + record['id'].to_s, {:class => 'action_link'})
        return link_url
      end

    end

    def before_cell_render_styling(column_name, cell_value, record)

    end

    def after_cell_render_styling(column_name, cell_value, record)
      ""

    end
  end
end
