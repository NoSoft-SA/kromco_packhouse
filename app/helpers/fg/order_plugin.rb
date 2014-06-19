require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'

module FgPlugins
  class OrderGridPlugin < ApplicationHelper::GridPlugin


    #---------------------------------------------------------------
    #This method allows a user to customize the styling of a cell
    #The calling method will prepend the cell text with the styling
    #string returned by this method
    #---------------------------------------------------------------
    def initialize(env = nil, request = nil)
         @env = env
         @request = request
         #calc_queries
    end

    #def calc_queries
    #  @order_types=OrderType.find_by_sql("select order_types.order_type_code,orders.id as order_id
    #                                   from orders
    #                                   join order_types on orders.order_type_id=order_types.id
    #                                   ")
    #end

     def cancel_cell_rendering(column_name,cell_value,record)
       if column_name=="test_upgrade" &&  (!cell_value || cell_value == "false" || cell_value.to_s.strip == "")
         #order_type= @order_types.find_all { |p| p.order_id.to_i==record['id'].to_i }
         #if !order_type.empty?
           if @env.session.data[:mo_and_mq_orders_not_ready]==true &&(record.order_type_code.strip=="MO" || record.order_type_code.strip=="MQ")
             return true
            else
             return false
           end
         #end
        end
        if column_name=="upgrade_order" &&  (!cell_value || cell_value == "false" || cell_value.to_s.strip == "")
          #order_type= @order_types.find_all { |p| p.order_id.to_i==record['id'].to_i }
          #if !order_type.empty?
            if record.order_type_code.strip=="MO" || record.order_type_code.strip=="MQ"
              if record['not_all_pallets_is_stock']==nil || record['not_all_pallets_is_stock']==false || record['not_all_pallets_is_stock']=="f"
                return true
              else
                return false
              end
            else
              return false
            end
          #end

         end
     end
     def render_cell(column_name,cell_value,record)

       if column_name=="upgrade_order"
            column_config = {:id_value => record['id'],
                               :link_text => "upgrade_order",
                               :host_and_port => @request.host_with_port.to_s,
                               :controller => @request.path_parameters['controller'].to_s,
                               :target_action => 'upgrade_order'}
              popup_link = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, self)
              return popup_link.build_control
       end
       if column_name=="test_upgrade"
           link_url = @env.link_to('test_upgrade', "http://" + @request.host_with_port + "/" + "fg/order/test_upgrade_prelim_order" + "/" + record['id'].to_s, {:class => 'action_link'})
           return link_url
       end
       end

    def before_cell_render_styling(column_name, cell_value, record)
      style = ""
  
      return "<font color = 'purple'>" if record['order_type_code'] && record['order_type_code'].strip.upcase =='MO'
      return "<font color = 'blue'>" if record['order_type_code'] && record['order_type_code'].strip.upcase =='MQ'

       return "<font color = 'blue'>" if record['order_status'].upcase =='SHIPPED'
       return "<font color = 'brown'>" if record['order_status'].upcase =='RETURNED'
       return "<font color = 'magenta'>" if record['order_status'].upcase == Order::STATUS_DELETION_RECVD
      if record['load_status']!= nil
         if record['load_status'].upcase =='LOAD_CREATED'
          style = "<font color = 'red'>"
        elsif record['load_status'].upcase =='TRUCK_LOADED'
          style =  "<font color = 'green'>"
        else
          style =  "<font color = 'orange'>"
        end
        return style
      end

    end


    def after_cell_render_styling(column_name, cell_value, record)

      "</font>"

    end


  end

end


# =begin