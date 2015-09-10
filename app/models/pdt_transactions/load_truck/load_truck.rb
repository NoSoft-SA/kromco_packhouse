class LoadTruck < PDTTransaction

 attr_accessor :vehicle_number,:load_order_id,:scanned_pallets,:load_vehicle_id,:pick_list_pallets ,:current_index,:load_number

 def initialize
   @current_pallets_index = 0
  end

  def build_default_screen
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"text_box",:name=>"truck_number",:is_required=>"true"}
    field_configs[field_configs.length] = {:type=>"text_box",:name=>"scan_pick_list",:is_required=>"true"}

    screen_attributes = {:auto_submit=>"true",:auto_submit_to=>"load_truck_submit",:content_header_caption=>"scan_pick_list"}
    buttons = {"B3Label"=>"" ,"B2Label"=>"","B1Submit"=>"load_truck_submit","B1Label"=>"submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
    return result_screen_def
  end

 def load_truck
   build_default_screen
 end

  def load_truck_submit
    @load_order_id = @pdt_screen_def.get_control_value("scan_pick_list")
    load_order = LoadOrder.find_by_sql("select * from load_orders where id = '#{@load_order_id}' order by id desc ")[0]

    if load_order == nil
     return PDTTransaction.build_msg_screen_definition("load_order['#{@load_order_id}'] doesn't exist",nil,nil,nil)
    end

    load_vehicle = LoadVehicle.find_by_vehicle_number_and_load_id(self.pdt_screen_def.get_control_value("truck_number").strip,load_order.load_id)

     if load_vehicle == nil
      return PDTTransaction.build_msg_screen_definition("load vehicle record not found ",nil,nil,nil)
     else
       @vehicle_number = load_vehicle.vehicle_number
       @load_vehicle_id =   load_vehicle.id
     end


     load = Load.find(load_order.load_id)
    if(load.load_status.upcase != "TRUCK_ARRIVED")
      return PDTTransaction.build_msg_screen_definition("Cannot proceed current load status is '#{load.load_status}' !!!",nil,nil)
    else
      @load_number = load.load_number
      @pick_list_pallets = Pallet.find_by_sql("select pallet_number from pallets inner join load_details on (pallets.load_detail_id = load_details.id ) inner join loads on (load_details.load_id = loads.id) inner join load_orders on (load_orders.load_id = loads.id) where load_orders.id = '#{@load_order_id}' ORDER BY pallets.id DESC ").map{|s| s.pallet_number}
      @scanned_pallets = Array.new

      next_state = ScanLoadPallet.new(self)
      self.set_active_state(next_state)
      return next_state.build_default_screen
    end
  end

  def load_truck_trans()


    ActiveRecord::Base.transaction do
      Inventory.move_stock('fg_load_truck',@load_vehicle_id.to_s,'IN_TRANSIT',self.scanned_pallets)

      load_order = LoadOrder.find(@load_order_id.to_i)
      load = Load.find(load_order.load_id)
      load.set_status("TRUCK_LOADED")


       self.scanned_pallets.each do |pallet_number|

          load_vehicle_unit = LoadVehicleUnit.new
          load_vehicle_unit.unit_id = pallet_number
          load_vehicle_unit.load_vehicle_id = @load_vehicle_id
          load_vehicle_unit.date_time_loaded = Time.now()
          load_vehicle_unit.create
        end

      set_repeat_process_flag
#    result = [" '#{self.scanned_pallets.length}' pallets have been loaded on truck :'#{self.vehicle_number}' for load number :'#{self.load_number}' "]
#    result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,result)
#    return result_screen
   end
  end
end