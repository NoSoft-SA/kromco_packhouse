module LoadVehicleLists
  class PalletsList
    attr_accessor :vehicle_number
    
    def initialize(vehicle_number)
      @vehicle_number = vehicle_number
    end
     
    public
    
    def length
      the_length = LoadVehiclePallet.find_by_sql("select max(position) as max from load_vehicle_pallets where vehicle_number='#{vehicle_number}'").map{|l| l.max}[0]
      return (the_length.to_i + 1) if(the_length)
      return 0
    end

    def size
      length
    end

    def [](i)
      load_vehicle_pallet = LoadVehiclePallet.find_by_vehicle_number_and_position(vehicle_number,i)
      if(load_vehicle_pallet)
        return load_vehicle_pallet.pallet_number
      end
    end

    def []=(i,j)
      load_vehicle_pallet = LoadVehiclePallet.find_by_vehicle_number_and_position(vehicle_number,i)
      if(load_vehicle_pallet)
        return load_vehicle_pallet.update_attribute(:pallet_number,j)
      end
      load_vehicle_pallet = LoadVehiclePallet.new({:vehicle_number=>@vehicle_number,:pallet_number=>j,:position=>i})
      load_vehicle_pallet.save!
    end
    
    def each
#      list = LoadVehiclePallet.find_all_by_vehicle_number(vehicle_number)
      for i in 0..self.length() -1
       yield self[i]
      end
    end

    def include?(pallet_number)
      return true if(LoadVehiclePallet.find_by_vehicle_number_and_pallet_number(vehicle_number,pallet_number))
      return false
    end

    def clear
      LoadVehiclePallet.destroy_all("vehicle_number='#{vehicle_number}' ")
    end
#    public
#    def shift
#         #CLASSIC: Returns the first element(i.e. array[0]) of self and removes it (shifting all other elements down by one). Returns nil if the array is empty
#
#    #-----------
#    #OUR
#    #------------
#    #gets a deep_copy of  first(position 0) list_item(it's persisted_object field value) and then deletes its db record. Update the position value of each remaining list_item to be current_position -1
#    #return the deep_copy of list_items's persisted_object  to caller. If  persisted object is null, return nil
#    ActiveRecord::Base.transaction do
#      list = List.find_by_name_and_list_id(self.list_name,self.list_id,self.persisted_lists_folder)
#      if(list)
#        position = 0
#         list_item = ListItem.find_by_position_and_list_id_and_list_name(position, self.list_id,self.list_name,self.persisted_lists_folder)
#         copy = list_item.get_persisted_object
#         list_item.delete
#
#         position += 1
#        self.size.times do
#          list_item = ListItem.find_by_position_and_list_id_and_list_name(position, self.list_id,self.list_name,self.persisted_lists_folder)
#          list_item.rename((position-1).to_s)
#          position += 1
#         end
#
#        return copy
#      end
#    end
#    end
#
#    public
#    def unshift(object)
#    #CLASSIC: Prepends objects to the front of array. other elements up one
#
#    #------------
#    #OUR
#    #------------
#    #get all list_items for list, and update the position of each list_item to be current position + 1. Delete the list_item with biggest position value if it is now bigger than @amount
#    # create a new list_item for object(object is the 'persisted_object' of a class) and set its position value as 0
#     ActiveRecord::Base.transaction do
#        list = List.find_by_name_and_list_id(self.list_name,self.list_id,self.persisted_lists_folder)
#        if(list)
#          position = self.size - 1
#          self.size.times do
#            list_item = ListItem.find_by_position_and_list_id_and_list_name(position, self.list_id,self.list_name,self.persisted_lists_folder)
#            list_item.rename((position+1).to_s)
#            position -= 1
#          end
#
#          list_item = ListItem.new
#          list_item.list_id = self.list_id
#          list_item.list_name = self.list_name
#          list_item.position =  0
#          list_item.persisted_lists_folder = self.persisted_lists_folder
#          list_item.save
#          list_item.update_persisted_object(object)
#      end
#
#     end
#    end
#
#    public
#    def pop
#     #CLASSIC: Removes the last element from self and returns it, or nil if the array is empty
#
#     #--------
#     #OUR
#     #--------
#     # find the list_item with max position and return a deep_copy of its persisted object. Then delete the db record
#
#      list_item = ListItem.find_by_position_and_list_id_and_list_name((self.size-1), self.list_id,self.list_name,self.persisted_lists_folder)
#      if list_item
#        persisted_object = list_item.get_persisted_object
#       list_item.delete
#       return persisted_object
#     end
#    end

    def push(pallet_number)
      load_vehicle_pallet = LoadVehiclePallet.new({:vehicle_number=>@vehicle_number,:pallet_number=>pallet_number,:position=>length})
      load_vehicle_pallet.save!
    end
  end

    class CartonsList
    attr_accessor :vehicle_number

    def initialize(vehicle_number)
      @vehicle_number = vehicle_number
    end

    public

    def length
      the_length = LoadVehicleCarton.find_by_sql("select max(position) as max from load_vehicle_cartons where vehicle_number='#{vehicle_number}'").map{|l| l.max}[0]
      return (the_length.to_i + 1) if(the_length)
      return 0
    end

    def size
      length
    end

    def [](i)
      load_vehicle_carton = LoadVehicleCarton.find_by_vehicle_number_and_position(vehicle_number,i)
      if(load_vehicle_carton)
        return load_vehicle_carton.carton_number
      end
    end

    def []=(i,j)
      load_vehicle_carton = LoadVehicleCarton.find_by_vehicle_number_and_position(vehicle_number,i)
      if(load_vehicle_carton)
        return load_vehicle_carton.update_attribute(:carton_number,j)
      end
      load_vehicle_carton = LoadVehicleCarton.new({:vehicle_number=>vehicle_number,:carton_number=>j,:position=>i})
      load_vehicle_carton.save!
    end

    def each
      list = LoadVehicleCarton.find_all_by_vehicle_number(vehicle_number)
      for i in 0..self.length() -1
       yield self[i]
      end
    end

    def include?(carton_number)
      return true if(LoadVehicleCarton.find_by_vehicle_number_and_carton_number(vehicle_number,carton_number))
      return false
    end

    def push(carton_number)
      load_vehicle_carton = LoadVehicleCarton.new({:vehicle_number=>vehicle_number,:carton_number=>carton_number,:position=>length})
      load_vehicle_carton.save!
    end

    def clear
      LoadVehicleCarton.destroy_all("vehicle_number='#{vehicle_number}' ")
    end
  end


end