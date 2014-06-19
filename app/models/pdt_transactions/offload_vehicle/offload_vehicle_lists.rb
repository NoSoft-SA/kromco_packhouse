module OffloadVehicleLists
  class PalletsList < PersistedList
    attr_accessor :tripsheet_number

    def initialize(size,list_id,list_name,persisted_lists_folder)
      super(size,list_id,list_name,persisted_lists_folder)
      @tripsheet_number = list_id
    end

    public

    def pallet_locked?(pallet_number)
      if(pallet_number.is_a?(PalletValidation))
        pallet_number = pallet_number.pallet_no
      end
      
      if(tripsheet_pallet = TripsheetPallet.find_by_tripsheet_number_and_pallet_number(tripsheet_number,pallet_number))
        return true if(tripsheet_pallet.user_name)
      end
      return false
    end

    def get_pallet_user(pallet_number)
      if(tripsheet_pallet = TripsheetPallet.find_by_tripsheet_number_and_pallet_number(tripsheet_number,pallet_number))
        return tripsheet_pallet.user_name
      end
    end

    def [](i)
      if((pallet_validation = super(i)).is_a?(PalletValidation))
        return pallet_validation
      end
      if(tripsheet_pallet = TripsheetPallet.find_by_tripsheet_number_and_position(tripsheet_number,i))
        return tripsheet_pallet.pallet_number
      end
    end

    def []=(i,j)
      tripsheet_pallet = TripsheetPallet.find_by_tripsheet_number_and_position(tripsheet_number,i)
      if(tripsheet_pallet)
        return tripsheet_pallet.update_attribute(:pallet_number,j)
      end
      tripsheet_pallet = TripsheetPallet.new({:tripsheet_number=>@tripsheet_number,:pallet_number=>j,:position=>i})
      tripsheet_pallet.save!
    end

    def each
      for i in 0..self.length() -1
       yield self[i]
      end
    end

    def include?(pallet_number)
      return true if(TripsheetPallet.find_by_tripsheet_number_and_pallet_number(tripsheet_number,pallet_number))
      return false
    end

    def clear
      clear_list
      TripsheetPallet.destroy_all("tripsheet_number='#{tripsheet_number}' ")
    end

    def push(pallet_number,pallet_validation=nil,user_name=nil)
      pallet_validation.parent.clear_pdt_environment if(pallet_validation)
      super(pallet_validation) #*****EXTENSION*******
      tripsheet_pallet = TripsheetPallet.new({:tripsheet_number=>@tripsheet_number,:pallet_number=>pallet_number,:position=>length-1,:user_name=>user_name})#,:pallet_validation=>Marshal.dump(pallet_validation)
      tripsheet_pallet.save!
    end

    def index(pallet_number)
      if(pallet_number.kind_of?(PalletValidation))
        pallet_number = pallet_number.pallet_no
      end
      tripsheet_pallet = TripsheetPallet.find_by_tripsheet_number_and_pallet_number(tripsheet_number,pallet_number)
      return tripsheet_pallet.position
    end

    def update_pallet_validation(pallet_number,pallet_validation)
      tripsheet_pallet = TripsheetPallet.find_by_tripsheet_number_and_pallet_number(tripsheet_number,pallet_number)
      if(tripsheet_pallet)
        pallet_validation.parent.clear_pdt_environment
  #      tripsheet_pallet.update_attribute(:pallet_validation,Marshal.dump(pallet_validation)) if(tripsheet_pallet)

        begin
         list_item = ListItem.find_by_position_and_list_id_and_list_name(tripsheet_pallet.position, self.list_id,self.list_name,self.persisted_lists_folder)
         if(list_item)
          list_item.update_persisted_object(pallet_validation)
         end
        rescue
          raise $!
        end
      end
    end

    def lock_pallet(pallet_number,user)
      tripsheet_pallet = TripsheetPallet.find_by_tripsheet_number_and_pallet_number(tripsheet_number,pallet_number)
      if(tripsheet_pallet)
        tripsheet_pallet.update_attribute(:user_name,user)
      end

#      #>>>>>>>>>>>>>>>>>>>>>>
#      locked_tripsheet_pallet = ValidatedTripsheetPallet.find_by_tripsheet_number_and_pallet_number(tripsheet_number,pallet_number)
#      locked_tripsheet_pallet.destroy if(locked_tripsheet_pallet)
#
##      However,must now take it back to InvalidatedTripsheetPallets i.e. parent.not_yet_validated_pallets.push(pallet_number)
#      #>>>>>>>>>>>>>>>>>>>>>>
      return nil
    end

    def unlock_pallet(pallet_number)
      lock_pallet(pallet_number,nil)
    end

    def assign(list)                            #***
      clear
      list.each do |item|
        if(item.kind_of?(PalletValidation))
          push(item.pallet_no,item)
        else
          push(item[:pallet_number],item[:pallet_validation],item[:user_name])#Marshal.load(item.pallet_validation)
        end
      end
    end                                         #***

    def slice(*args)                            #***
      if(args.length == 1)
        if(args[0].kind_of?(Range))
          list = []
          args[0].each do |posi|
            if(tripsheet_pallet = TripsheetPallet.find_by_tripsheet_number_and_position(tripsheet_number,posi))
#              list.push(tripsheet_pallet.get_tripsheet_pallet)
#              list.push(tripsheet_pallet)
              if(!(plt_validation = self[tripsheet_pallet.position]).kind_of?(PalletValidation))
                plt_validation = nil
              end
              list.push({:pallet_number=>tripsheet_pallet.pallet_number,:pallet_validation=>plt_validation,:user_name=>tripsheet_pallet.user_name})
            end
          end
          return list
        else                                    #***
          if(tripsheet_pallet = TripsheetPallet.find_by_tripsheet_number_and_position(tripsheet_number,args[0]))
#            arra = [tripsheet_pallet.get_tripsheet_pallet]
#            arra = [tripsheet_pallet]
            if(!(plt_validation = self[tripsheet_pallet.position]).kind_of?(PalletValidation))
              plt_validation = nil
            end
            arra = [{:pallet_number=>tripsheet_pallet.pallet_number,:pallet_validation=>plt_validation,:user_name=>tripsheet_pallet.user_name}]
            return arra
          end
        end
      else                                      #***
        list = []
        (args[0]..args[1]).each do |posi|
          if(tripsheet_pallet = TripsheetPallet.find_by_tripsheet_number_and_position(tripsheet_number,posi))
#            list.push(tripsheet_pallet.pallet_number)
#            list.push(tripsheet_pallet)
            if(!(plt_validation = self[tripsheet_pallet.position]).kind_of?(PalletValidation))
              plt_validation = nil
            end
            list.push({:pallet_number=>tripsheet_pallet.pallet_number,:pallet_validation=>plt_validation,:user_name=>tripsheet_pallet.user_name})
          end
        end
        return list if(list.length>0)
      end
      return nil
    end
  end

#  class TempTrisheetPallet
#    attr_accessor :pallet_number, :pallet_validation, :user_name
#
#    def initialize(pallet_number,pallet_validation,user_name)
#      @pallet_number = pallet_number
#      pallet_validation
#      user_name
#    end
#  end

  class ValidatedPalletsList
    attr_accessor :tripsheet_number

    def initialize(tripsheet_number)
      @tripsheet_number = tripsheet_number
    end

    public

    def length
      the_length = ValidatedTripsheetPallet.find_by_sql("select max(position) as max from validated_tripsheet_pallets where tripsheet_number='#{tripsheet_number}'").map{|l| l.max}[0]
      return (the_length.to_i + 1) if(the_length)
      return 0
    end

    def size
      length
    end

    def [](i)
      tripsheet_pallet = ValidatedTripsheetPallet.find_by_tripsheet_number_and_position(tripsheet_number,i)
      if(tripsheet_pallet)
        return tripsheet_pallet.pallet_number
      end
    end

    def []=(i,j)
      tripsheet_pallet = ValidatedTripsheetPallet.find_by_tripsheet_number_and_position(tripsheet_number,i)
      if(tripsheet_pallet)
        return tripsheet_pallet.update_attribute(:pallet_number,j)
      end
      tripsheet_pallet = ValidatedTripsheetPallet.new({:tripsheet_number=>@tripsheet_number,:pallet_number=>j,:position=>i})
      tripsheet_pallet.save!
    end

    def each
#      list = TripsheetPallet.find_all_by_tripsheet_number(tripsheet_number)
      for i in 0..self.length() -1
       yield self[i]
      end
    end

    def include?(pallet_number)
      if(pallet_number.is_a?(PalletValidation))
        pallet_number = pallet_number.pallet_no
      end

      return true if(ValidatedTripsheetPallet.find_by_tripsheet_number_and_pallet_number(tripsheet_number,pallet_number))
      return false
    end

    def clear
      ValidatedTripsheetPallet.destroy_all("tripsheet_number='#{tripsheet_number}' ")
    end

    def push(pallet_number)
      tripsheet_pallet = ValidatedTripsheetPallet.new({:tripsheet_number=>@tripsheet_number,:pallet_number=>pallet_number,:position=>length})
      tripsheet_pallet.save!
    end

    def index(pallet_number)
      tripsheet_pallet = ValidatedTripsheetPallet.find_by_tripsheet_number_and_pallet_number(tripsheet_number,pallet_number)
      return tripsheet_pallet.position
    end

    def clear
      ValidatedTripsheetPallet.destroy_all("tripsheet_number='#{tripsheet_number}' ")
    end
  end

  class InvalidatedPalletsList
    attr_accessor :tripsheet_number

    def initialize(tripsheet_number)
      @tripsheet_number = tripsheet_number
    end

    public

    def length
      the_length = InvalidatedTripsheetPallet.find_by_sql("select max(position) as max from invalidated_tripsheet_pallets where tripsheet_number='#{tripsheet_number}'").map{|l| l.max}[0]
      return (the_length.to_i + 1) if(the_length)
      return 0
    end

    def size
      length
    end

    def [](i)
      tripsheet_pallet = InvalidatedTripsheetPallet.find_by_tripsheet_number_and_position(tripsheet_number,i)
      if(tripsheet_pallet)
        return tripsheet_pallet.pallet_number
      end
    end

    def []=(i,j)
      tripsheet_pallet = InvalidatedTripsheetPallet.find_by_tripsheet_number_and_position(tripsheet_number,i)
      if(tripsheet_pallet)
        return tripsheet_pallet.update_attribute(:pallet_number,j)
      end
      tripsheet_pallet = InvalidatedTripsheetPallet.new({:tripsheet_number=>@tripsheet_number,:pallet_number=>j,:position=>i})
      tripsheet_pallet.save!
    end

    def each
      for i in 0..self.length() -1
       yield self[i]
      end
    end

    def include?(pallet_number)
      return true if(InvalidatedTripsheetPallet.find_by_tripsheet_number_and_pallet_number(tripsheet_number,pallet_number))
      return false
    end

    def clear
      InvalidatedTripsheetPallet.destroy_all("tripsheet_number='#{tripsheet_number}' ")
    end

    def push(pallet_number)
      tripsheet_pallet = InvalidatedTripsheetPallet.new({:tripsheet_number=>@tripsheet_number,:pallet_number=>pallet_number,:position=>length})
      tripsheet_pallet.save!
    end

    def index(pallet_number)
      tripsheet_pallet = InvalidatedTripsheetPallet.find_by_tripsheet_number_and_pallet_number(tripsheet_number,pallet_number)
      return tripsheet_pallet.position
    end

    def delete(pallet_number)
      tripsheet_pallet = InvalidatedTripsheetPallet.find_by_tripsheet_number_and_pallet_number(tripsheet_number,pallet_number)
      return nil if(!tripsheet_pallet)
      position = tripsheet_pallet.position
      tripsheet_pallet.destroy

      InvalidatedTripsheetPallet.update_all(ActiveRecord::Base.extend_set_sql_with_request("position = (position-1)","invalidated_tripsheet_pallets"), " tripsheet_number='#{tripsheet_number}' and position > #{position}")
      return pallet_number
    end
  end

end