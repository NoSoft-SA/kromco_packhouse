require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'

module FgPlugins
  class SignedIntakeDocs < ApplicationHelper::GridPlugin
    def cancel_cell_rendering(column_name, cell_value, record)
      if ((column_name=="view" || column_name=="print") && (!File.exists?(File.dirname(__FILE__) + "/../../../public/downloads/signed_intake_docs/#{record['consignment_note_number']}.pdf")))
        return true
      end
    end
  end

  class LoadPalletsGridPlugin < ApplicationHelper::GridPlugin
    def initialize(env = nil, request = nil)
      @env     = env
      @request = request
    end

    def cancel_cell_rendering(column_name, cell_value, record)
      if(column_name=="remarks1" || column_name=="remarks2" || column_name=="remarks3" || column_name=="remarks4" || column_name=="remarks5")
        return true
      end
      false
    end

    def render_cell(column_name, cell_value, record)
      if !@env.session.data[:current_viewing_order]
        if(column_name=="remarks1" || column_name=="remarks2" || column_name=="remarks3" || column_name=="remarks4" || column_name=="remarks5")
          return @env.text_field('load_pallet', "#{record['id']}_#{column_name}", {:size=>30,:value=>record[column_name]})
        end
      else
        if column_name=="remarks1"
          return record['remarks1']
        elsif column_name=="remarks2"
          return record['remarks2']
        elsif column_name=="remarks3"
          return record['remarks3']
        elsif column_name=="remarks4"
          return record['remarks4']
        elsif column_name=="remarks5"
          return record['remarks5']
        end
      end
    end
  end

  class LoadDetailGridPlugin < ApplicationHelper::GridPlugin
    def initialize(env = nil, request = nil)
      @env     = env
      @request = request
      calc_queries
    end

    def calc_queries

      @load_alloc_pallets =Pallet.find_by_sql("select distinct count(pallets.*) as count,loads.id as load_id
                                                   from pallets
                                                   inner join load_details on pallets.load_detail_id=load_details.id
                                                   inner join load_orders on load_details.load_order_id=load_orders.id
                                                   inner join  loads on load_orders.load_id=loads.id
                                                  where pallets.load_detail_id IS NOT NULL and load_orders.order_id=#{@env.session.data[:active_doc]['order']} group by loads.id")

      @order_types        =OrderType.find_by_sql("select order_types.order_type_code,load_orders.load_id
                                       from orders
                                       join order_types on orders.order_type_id=order_types.id
                                       join load_orders on load_orders.order_id=orders.id
                                        where load_orders.order_id=#{@env.session.data[:active_doc]['order']}")
      #@load_pallets = Pallet.find_by_sql("select pallets.*,load_orders.load_id  from pallets
      #                                         join load_details on (pallets.load_detail_id = load_details.id)
      #                                         join loads on (loads.id = load_details.load_id)
      #                                         join load_orders on (loads.id = load_orders.load_id)
      #                                         ")


    end

    def cancel_cell_rendering(column_name, cell_value, record)
      if column_name=="load_status" && (!cell_value || cell_value == "false" || cell_value.to_s.strip == "")
        return true
      elsif column_name == "pallets" && (!cell_value || cell_value == "false" || cell_value.to_s.strip == "")
        return true
      elsif column_name == "print_pick_list" && (!cell_value || cell_value == "false" || cell_value.to_s.strip == "")
        load_pallets = Pallet.find_by_sql("select pallets.*,load_orders.load_id  from pallets
                         join load_details on (pallets.load_detail_id = load_details.id)
                         join loads on (loads.id = load_details.load_id)
                         join load_orders on (loads.id = load_orders.load_id)
                         where load_orders.load_id=#{record['id']}")
            if !load_pallets.empty?
              return true
              else
              return false
            end
     elsif column_name == "complete_load" && (!cell_value || cell_value == "false" || cell_value.to_s.strip == "")
        order_type= @order_types.find_all { |p| p.load_id.to_i==record['id'].to_i }
          if !order_type.empty?
            if order_type[0].order_type_code=="MO" || order_type[0].order_type_code=="MQ"
                return false
              else
                load_status=Load.find(record['id'].to_i).load_status
                if load_status.upcase.strip=="SHIPPED"
                  return true
                else
                  return false
                end
            end
          end
      elsif column_name == "edit_container" && (!cell_value || cell_value == "false" || cell_value.to_s.strip == "")
        order_type= @order_types.find_all { |p| p.load_id.to_i==record['id'].to_i }
        if !order_type.empty?
          if order_type[0].order_type_code.strip=="MO" || order_type[0].order_type_code.strip=="MQ"
            return false
          else
            return true
          end
        end
      elsif column_name == "edit_vehicle" && (!cell_value || cell_value == "false" || cell_value.to_s.strip == "")
        order_type= @order_types.find_all { |p| p.load_id.to_i==record['id'].to_i }
        if !order_type.empty?
          if order_type[0].order_type_code.strip=="MO" || order_type[0].order_type_code.strip=="MQ"
            return false
          else
            return true
          end
        end
      elsif column_name == "link_edit_voyage" && (!cell_value || cell_value == "false" || cell_value.to_s.strip == "")
        order_type= @order_types.find_all { |p| p.load_id.to_i==record['id'].to_i }
        if !order_type.empty?
          if order_type[0].order_type_code.strip=="MO" || order_type[0].order_type_code.strip=="MQ"
            return false
          else
            return true
          end
        end
      elsif column_name == "reports" && (!cell_value || cell_value == "false" || cell_value.to_s.strip == "")
        order_type= @order_types.find_all { |p| p.load_id.to_i==record['id'].to_i }
        if !order_type.empty?
          if order_type[0].order_type_code.strip=="MO" || order_type[0].order_type_code.strip=="MQ"
            return false
          else
            return true
          end
        end
      elsif column_name == "delete_load" && (!cell_value || cell_value == "false" || cell_value.to_s.strip == "")
        pallets=@load_alloc_pallets.find_all { |u| u.load_id.to_i==record['id'].to_i }
        if pallets.empty?
          return true
        else
          return false
        end
      else
        return false
      end

    end

    def render_cell(column_name, cell_value, record)
      if column_name=="delete_load"
        column_config = {:id_value      => record['id'],
                         :image         => 'delete',
                         :host_and_port => @request.host_with_port.to_s,
                         :controller    => @request.path_parameters['controller'].to_s,
                         :target_action => "delete_load"}
        popup_link    = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, @env)
        return popup_link.build_control
      end

      if column_name=="reports"
        column_config = {:id_value      => record['id'],
                         :image         => 'reports_and_edis',
                         :host_and_port => @request.host_with_port.to_s,
                         :controller    => @request.path_parameters['controller'].to_s,
                         :target_action => "reports_and_edis"}
        popup_link    = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, @env)
        return popup_link.build_control
      end

      if column_name=="edit_vehicle"
        column_config = {:id_value      => record['id'],
                         :image         => 'edit_vehicle',
                         :host_and_port => @request.host_with_port.to_s,
                         :controller    => @request.path_parameters['controller'].to_s,
                         :target_action => "edit_vehicle"}
        popup_link    = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, @env)
        return popup_link.build_control
      end

      if column_name=="edit_container"
        column_config = {:id_value      => record['id'],
                         :image         => 'edit_container',
                         :host_and_port => @request.host_with_port.to_s,
                         :controller    => @request.path_parameters['controller'].to_s,
                         :target_action => "edit_container"}
        popup_link    = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, @env)
        return popup_link.build_control
      end

      if column_name=="complete_load"
        column_config = {:id_value      => record['id'],
                         :image         => 'complete_load',
                         :host_and_port => @request.host_with_port.to_s,
                         :controller    => @request.path_parameters['controller'].to_s,
                         :target_action => "complete_load"}
        popup_link    = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, @env)
        return popup_link.build_control
      end


      if column_name=="print_pick_list"
        column_config = {:id_value      => record['id'],
                         :image         => 'print_pick_list',
                         :host_and_port => @request.host_with_port.to_s,
                         :controller    => @request.path_parameters['controller'].to_s,
                         :target_action => "print_pick_list"}
        popup_link    = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, @env)
        return popup_link.build_control
      end

      if column_name=="pallets"
        palletsi =Pallet.find_by_sql("select distinct pallets.*
                                                           from pallets
                                                           inner join load_details on pallets.load_detail_id=load_details.id
                                                           inner join load_orders on load_details.load_order_id=load_orders.id
                                                           inner join  loads on load_orders.load_id=loads.id
                                                where pallets.load_detail_id IS NOT NULL and loads.id=#{record['id']}   ")
        pallets  =Array.new
        plts     ={}
        plt_nums =[]
        if !palletsi.empty?
          for plt in palletsi
            if plts.has_value?(plt['pallet_number'])
            else
              pallets << plt
              plts[plt['pallet_number']]=plt['pallet_number']
              plt_nums << "pallets.pallet_number=" + "'#{plt['pallet_number']}'"
            end
          end
          if pallets.empty?
            count =0
          else
            count=pallets.length
          end
        else
          count =0
        end

        column_config = {:id_value      => record['id'],
                         :link_text     => count,
                         :host_and_port => @request.host_with_port.to_s,
                         :controller    => @request.path_parameters['controller'].to_s,
                         :window_height => 550,
                         :target_action => 'view_load_pallets'}
        popup_link    = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, @env)
        return popup_link.build_control
      end


      if column_name=="load_status"
        column_config = {:id_value      => record['id'],
                         :link_text     => record['load_status'],
                         :host_and_port => @request.host_with_port.to_s,
                         :controller    => @request.path_parameters['controller'].to_s,
                         :target_action => 'load_status'}
        popup_link    = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, @env)
        return popup_link.build_control
      end

      if column_name=="link_edit_voyage"
        load_voyage=LoadVoyage.find_by_load_id(record['id'])
        if load_voyage
          column_config = {:id_value      => record['id'],
                           :image         => "link_voyage",
                           :host_and_port => @request.host_with_port.to_s,
                           :controller    => @request.path_parameters['controller'].to_s,
                           :target_action => 'edit_voyage'}
          popup_link    = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, @env)
          return popup_link.build_control
        else
          column_config = {:id_value      => record['id'],
                           :image         => "link_voyage",
                           :host_and_port => @request.host_with_port.to_s,
                           :controller    => @request.path_parameters['controller'].to_s,
                           :target_action => 'link_to_voyage'}
          popup_link    = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, @env)
          return popup_link.build_control
        end
      end


    end


    def before_cell_render_styling(column_name, cell_value, record)

      style = ""

      #record['hold_over_quantity']= "" if ! record['hold_over_quantity']
      if record['holdover_quantity'] !=nil
        if record['holdover_quantity'] > 0
          style = "<font color = 'orange'>"

          if record['actual_quantity'] == record['required_quantity']
            style = "<font color = 'green'>"
          end


        else
          style = "<font color = 'red'>"
        end
      end

      return style
    end

    def after_cell_render_styling(column_name, cell_value, record)

      "</strong></font>"

    end


  end
end

# =begin