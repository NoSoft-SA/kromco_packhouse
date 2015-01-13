 require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'

   module FgPlugins
   class OrderProductGridPlugin < ApplicationHelper::GridPlugin

     def initialize(env = nil, request = nil)
             @env     = env
             @request = request
         end
      #---------------------------------------------------------------
      #This method allows a user to customize the styling of a cell
      #The calling method will prepend the cell text with the styling
      #string returned by this method
      #---------------------------------------------------------------
     def cancel_cell_rendering(column_name, cell_value, record)
       if(column_name=="price_per_carton" || column_name=="price_per_kg" || column_name=="fob")
         return true
       end

        if column_name=="subtotal" && (!cell_value || cell_value == "false" || cell_value.to_s.strip == "")
          return true
        elsif column_name=="delete" && (!cell_value || cell_value == "false" || cell_value.to_s.strip == "")
          load_details =LoadDetail.find_by_sql("select * from load_details where order_product_id=#{record['id']}")
        if load_details.empty?
          return true
        else
          return false
        end
        elsif column_name=="price_histories" && (!cell_value || cell_value == "false" || cell_value.to_s.strip == "")
          return true
        elsif column_name=="get_historic_pricing" && (!cell_value || cell_value == "false" || cell_value.to_s.strip == "")
          return true
        else
          return false

        end



        end

        #-------------------------------------------------------------------
        #This method allows a plugin to render the cell instead of the
        #grid column. To work, the same plugin must also implmement the
        #'cancel_cell_rendering' method and return true.
        #-------------------------------------------------------------------
        def render_cell(column_name, cell_value, record)

          if column_name=="get_historic_pricing"
            column_config = {:id_value => record['id'],
                             :image => 'historic_pricing',
                             :host_and_port => @request.host_with_port.to_s,
                             :controller => @request.path_parameters['controller'].to_s,
                             :target_action => 'get_historic_pricing'}
            popup_link = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, @env)
            return popup_link.build_control
          end

          if !@env.session.data[:current_viewing_order]
            if(column_name=="price_per_carton" || column_name=="price_per_kg" || column_name=="fob")
              return @env.text_field('order_product', "#{record['id']}_#{column_name}", {:size=>5,:value=>record[column_name]})
            end
          else
           if column_name=="price_per_carton"
             return record['price_per_carton']
           elsif column_name=="price_per_kg"
             return record['price_per_kg']
           elsif   column_name=="fob"
             return record['fob']
           end
        end

          if column_name=="price_histories"
            column_config = {:id_value => record['id'],
                             :image => 'price_histories',
                             :host_and_port => @request.host_with_port.to_s,
                             :controller => @request.path_parameters['controller'].to_s,
                             :target_action => 'price_histories'}
            popup_link = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, @env)
                      return popup_link.build_control
          end


          if column_name=="subtotal"
            if record['price_per_carton']==nil
              subtotal=0
            else
              subtotal=record['price_per_carton'] * record['carton_count']
            end
            return subtotal
          end

          if column_name=="delete"
                link_url = @env.link_to('delete', "http://" + @request.host_with_port + "/" + "fg/order_product/delete_order_product" + "/" + record['id'].to_s , {:class=>'action_link'})
                return link_url
          end
          end


   def before_cell_render_styling(column_name,cell_value,record)
          if column_name=="id"
          else
            style = ""
            record['required_quantity']= "" if ! record['required_quantity']

          if record['required_quantity'] == nil
           style = "<font color = 'red'>"

          else
            style =  "<font color = 'black'>"
          end

          if column_name == "required_quantity"
            @strong_on = true
            style += "<strong>"
          end
            return style
        end
end

       def after_cell_render_styling(column_name,cell_value,record)


       end






end
    end
#=end
# =begin