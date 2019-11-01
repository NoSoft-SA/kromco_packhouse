#-----------------------------------------------------------------
# This module contains the all classes that form the Inventory API
#-----------------------------------------------------------------
module Inventory


  class StockTransaction
    attr_accessor :stock_item, :inventory_transaction, :stock_item_before, :stock_item_after, :other

    def initialize(inventory_transaction, stock_item_after, other=nil)
      @inventory_transaction = inventory_transaction
#    @inventory_transaction.transaction_date_time = Time.now.to_formatted_s(:db)
      @inventory_transaction.validate
      @stock_item_after = stock_item_after
      @stock_item_after.validate
      @other = other
      if @stock_item_after.inventory_reference.to_s.is_numeric? #!@stock_item_after.new_record?
        @stock_item_before = StockItem.find_by_inventory_reference(self.stock_item_after.inventory_reference)
      end
    end

    def duplicate_transaction?
      #find most recent inventory transaction that occurred for this stock_item
      return false if !@stock_item_before
      duplicate = false

      most_recent_trans = InventoryTransaction.find_by_sql("select inventory_transactions.*,stock_items.inventory_reference from inventory_transactions
                                                         inner join inventory_transaction_stocks on inventory_transactions.id = inventory_transaction_stocks.inventory_transaction_id
                                                        inner join stock_items on stock_items.id =  inventory_transaction_stocks.stock_item_id
                                                        where stock_items.inventory_reference = '#{@stock_item_after.inventory_reference}' order by inventory_transaction_stocks desc limit 1 ")

      return false if most_recent_trans.empty?
      @most_recent_trans = most_recent_trans[0]

      if duplicate?
        RAILS_DEFAULT_LOGGER.error("DUPLICATE INVENTORY_TRANSACTION CANCELED at #{Time.now.to_s} FOR ITEM: #{@stock_item_after.inventory_reference}. trans_type: #{self.class.to_s}
                                  .Most recent trans_type: #{@most_recent_trans.transaction_type_code.to_s}. Most recent location_from: #{@most_recent_trans.location_from}
                                   .Most recent location_to: #{@most_recent_trans.location_to}. This trans location_from: #{@stock_item_before.location_code}
                                     .This trans location_to: #{@inventory_transaction.location_to}. Time of logged trans: #{@most_recent_trans.created_at.to_s}.
                                     .And finally: id of logged trans: #{@most_recent_trans.id.to_s}")

        duplicate = true
      end


      return duplicate



    end


    def process
      begin
        errors = validate
        if errors.to_s != ""
          raise "Transaction could not be created, reason: " + errors.to_s + $!.to_s
        elsif true #! duplicate_transaction?
          #ActiveRecord::Base.transaction do
          create_transaction
          log_transaction
          execute
          log_status
          move_asset_if_needed()

        end
      rescue
        raise $!
      end
    end

#========================================
# This method returns 'grouped asset type'
#========================================
    def get_stock_asset_type
      if (@stock_item_after.stock_type_code.to_s.upcase == "BINS"||@stock_item_after.stock_type_code.to_s.upcase == "BIN"||@stock_item_after.stock_type_code.to_s.upcase == "REBIN"||@stock_item_after.stock_type_code.to_s.upcase == "PRESORT")
        inventory_record = Bin.find_by_bin_number(@stock_item_after.inventory_reference)
      else
        return nil
      end
      pack_material_product_code = PackMaterialProduct.find(inventory_record.pack_material_product_id).pack_material_product_code
      asset_type = AssetType.find_by_pack_material_product_code(pack_material_product_code)
      return asset_type
    end

    def move_asset_if_needed()
      location_from = nil
      if @stock_item_before
        location_from = @stock_item_before.location_code
      elsif (@other[:farm_code])
        location_from = @other[:farm_code]
      end

      if(@other && @other[:asset_location_to])
        location_to = @other[:asset_location_to]
      else
        location_to = @stock_item_after.inventory_transaction.location_to
      end

      asset_type = get_stock_asset_type
      return if (!asset_type)
      #raise "no asset_type for stock:#{@stock_item_after.inventory_reference} : stock_type_code=#{@stock_item_after.stock_type_code.to_s.upcase}" if (!asset_type)
      raise "asset type[#{asset_type.asset_type_code.to_s.upcase}]not yet supported!" if(asset_type.asset_type_code.to_s.strip.upcase != "GROUPED")

      if(asset_location_changed?(asset_type))
        transaction_type = TransactionType.find_by_transaction_type_code('move_asset_quantity')

        asset_move_request = AssetMoveRequest.new({:pack_material_product_code=>asset_type.pack_material_product_code,:transaction_type_code => transaction_type.transaction_type_code,:transaction_type_id => transaction_type.id,
                                                   :location_from => location_from,:location_to => location_to,:transaction_business_name_code => @inventory_transaction.transaction_business_name_code,
                                                   :transaction_business_name_id => @inventory_transaction.transaction_business_name_id,
                                                   :reference_number => @stock_item_after.inventory_transaction.reference_number,
                                                   :parent_inventory_transaction_id => @inventory_transaction.id,:inventory_reference=>@stock_item_after.inventory_reference})
        asset_move_request.save!
      end
    end

    def get_asset_location(asset_item)
      if (@stock_item_before) #move stock
        asset_location = AssetLocation.find_by_asset_item_id_and_location_id(asset_item.id, @stock_item_before.location_id)
        return "asset_location[#{@stock_item_before.location_code}] for asset_item[#{asset_item.asset_number}] does not exist" if !asset_location
      else #create stock
        inventory_receipt = @stock_item_after.inventory_transaction.inventory_receipt
        location = Location.find_by_location_code(inventory_receipt.farm_code)
        asset_location = AssetLocation.find_by_asset_item_id_and_location_id(asset_item.id, location.id)
        return "asset_location[#{inventory_receipt.farm_code}] for asse_item[#{asset_item.asset_number}] does not exist" if !asset_location
      end
      return asset_location
    end

    def asset_location_changed?(asset_type)
      if asset_type.asset_type_code.to_s.upcase == "GROUPED"
        asset_item = AssetItem.find_by_asset_number(asset_type.pack_material_product_code)
        raise "asset_item[#{asset_item.asset_number}] does not exist" if !asset_item
        asset_location = get_asset_location(asset_item) #AssetLocation.find_by_asset_item_id(asset_item.id)#HANS - MANY LOCns???????
        raise asset_location if !asset_location.kind_of?(AssetLocation)
        location = Location.find(asset_location.location_id)
        if location && (location.location_code != @stock_item_after.location_code)
          return true
        end
      else
        asset_item = AssetItem.find_by_asset_number(@stock_item_after.inventory_transaction.reference_number)
        if asset_item && (asset_item.location_code != @stock_item_after.location_code)
          return true
        end
      end
      return false
    end

    def create_transaction
      if self.inventory_transaction.new_record?
        #puts "NEW RECORD PLEASE!"
        #HANS - added by Luks - otherwise @inventory_transaction.location_from will always be null
        if @stock_item_before
          @inventory_transaction.location_from = @stock_item_before.location_code
        elsif (@other[:farm_code])
          @inventory_transaction.location_from = @other[:farm_code]
        end
        self.inventory_transaction.save!
        @stock_item_after.inventory_transaction_id = self.inventory_transaction.id
        self.stock_item_after.inventory_transaction_id = self.inventory_transaction.id
        if self.inventory_transaction.inventory_receipt != nil
          if self.inventory_transaction.inventory_receipt.new_record?
            self.inventory_transaction.inventory_receipt.save!
          end
        end
        if self.inventory_transaction.inventory_issue != nil
          if self.inventory_transaction.inventory_issue.new_record?
            self.inventory_transaction.inventory_issue.save!
          end
        end
        #else
        # self.inventory_transaction.update
        #if self.inventory_transaction.inventory_receipt != nil
        #   if self.inventory_transaction.inventory_receipt.new_record?
        #     self.inventory_transaction.inventory_receipt.create()
        #   else
        #    self.inventory_transaction.inventory_receipt.update
        #  end
        #end
        #if self.inventory_transaction.inventory_issue != nil
        #  if self.inventory_transaction.inventory_issue.new_record?
        #    self.inventory_transaction.inventory_issue.create()
        # else
        #    self.inventory_transaction.inventory_issue.update
        # end
        # end
      else
        @stock_item_after.inventory_transaction_id = self.inventory_transaction.id
      end
    end

    def execute
    end

    def validate

    end


    def self.get_previous_location(stock_item_reference)
      previous_location = nil
      stock_item = StockItem.find_by_inventory_reference(stock_item_reference)
      inventory_transaction_stocks = InventoryTransactionStock.find_by_sql("select * from inventory_transaction_stocks where stock_item_id = '#{stock_item.id}' order by id DESC")
      if inventory_transaction_stocks.length != 0
        previous_location = inventory_transaction_stocks[0].current_location
      end
      return previous_location
    end

    def self.same_previous_locations?(previous_location, stock_item_references)
      flag = true
      for stock_item_ref in stock_item_references
        stock_item = StockItem.find_by_inventory_reference(stock_item_ref)
        inventory_transaction_stocks = InventoryTransactionStock.find_by_sql("select * from inventory_transaction_stocks where stock_item_id = '#{stock_item.id}' order by id DESC")
        if inventory_transaction_stocks.length != 0
          if previous_location != inventory_transaction_stocks[0].current_location
            flag = false
          end
        end
      end
      return flag
    end

    def self.same_transaction_type_codes?(stock_item_references)
      flag = true
      for stock_item_ref in stock_item_references
        stock_item = StockItem.find_by_inventory_reference(stock_item_ref)
        if stock_item && stock_item.inventory_transaction.transaction_type_code.to_s != "move_stock"
          flag = false
        end
      end
      return flag
    end

    def self.find_asset(inventory_reference)
      temp = nil
      asset_type = nil
      asset_item = nil
      bin = Bin.find_by_bin_number(inventory_reference)
      if bin != nil
        temp = bin
      else
        temp = Pallet.find_by_pallet_number(inventory_reference)
      end
      if temp
        pack_material_product_code = nil
        if temp.class.to_s == "Bin"
          pack_material_product = PackMaterialProduct.find(temp.pack_material_product_id)
          pack_material_product_code = pack_material_product.pack_material_product_code
        else
          pack_material_product_code = temp.pallet_format_product_code
        end
        if pack_material_product_code
          asset_type = AssetType.find_by_pack_material_product_code(pack_material_product_code)
        end
      end
      if asset_type
        if asset_type.asset_type_code.to_s.upcase == "GROUPED"
          asset_item = AssetItem.find_by_asset_number(asset_type.pack_material_product_code)
        end
      end
      return asset_item
    end

    private

    def log_transaction
      # if  @stock_item_before #!@stock_item_after.new_record?
        inventory_transaction_stock = InventoryTransactionStock.new
        raise "no existing inventory transaction" if  !@inventory_transaction
        inventory_transaction_stock.inventory_transaction_id = @inventory_transaction.id

        inventory_transaction_stock.stock_item = @stock_item_after
        inventory_transaction_stock.location_id = @stock_item_after.location_id
        inventory_transaction_stock.location_code = @stock_item_after.location_code
        if(@stock_item_before)
          inventory_transaction_stock.location_from = @stock_item_before.location_code
          inventory_transaction_stock.previous_trans_date_time = @stock_item_before.updated_at
        end

        inventory_transaction_stock.location_to = @inventory_transaction.location_to
        inventory_transaction_stock.transaction_type_code = @inventory_transaction.transaction_type_code
        inventory_transaction_stock.transaction_business_name = @inventory_transaction.transaction_business_name_code
        inventory_transaction_stock.transaction_quantity_plus = @inventory_transaction.transaction_quantity_plus
        inventory_transaction_stock.transaction_quantity_minus = @inventory_transaction.transaction_quantity_minus
        inventory_transaction_stock.reference_id = @stock_item_after.current_reference_id
        inventory_transaction_stock.reference_number = @inventory_transaction.reference_number
        inventory_transaction_stock.current_location = @stock_item_after.location_code
        inventory_transaction_stock.save!
      # end
    end

    def log_status
#    if @stock_item_before
#      if @stock_item_before.status_code != @stock_item_after.status_code
#         stock_item_status = StockItemStatus.new
#         status = Status.find_by_status_code(@stock_item_before.status_code)
#         stock_item_status.stock_item_id = @stock_item_before.id
#         stock_item_status.status_id = status.id
#         stock_item_status.created_on = Time.now.to_formatted_s(:db)
#         stock_item_status.save!
#      end
#    end
    end

    def generic_validate
      errors = ""
      if @inventory_transaction == nil
        errors += "'inventory_transaction' member variable can't be null!\n"
      else
        if @inventory_transaction.transaction_type_id == nil || @inventory_transaction.transaction_type_id == ""
          errors += "'transaction_type_id' is required!.\n"
        end
        if @inventory_transaction.transaction_date_time == nil || @inventory_transaction.transaction_date_time == ""
          @inventory_transaction.transaction_date_time = Time.now.to_formatted_s(:db)
#        errors += "'transaction_date_time' is required!\n"
        end
#      if @inventory_transaction.reference_number == nil || @inventory_transaction.reference_number == ""
#        errors += "reference_number is required!\n"
#      end
        if @inventory_transaction.transaction_type_code == nil || @inventory_transaction.transaction_type_code ==""
          errors += "'transaction_type_code' is required!.\n"
        end
      end

      if @stock_item_after == nil
        errors += "'stock_item_after' member variable can't be null"
      else
#      if @stock_item_after.stock_type_id == nil || @stock_item_after.stock_type_id == ""
#        errors += "stock_type_id is required!\n"
#      end
        if @stock_item_after.location_id == nil || @stock_item_after.location_id == ""
          errors += "location_id is required for stock[#{@stock_item_after.inventory_reference.to_s}]\n"

        end
        if @stock_item_after.location_code == nil || @stock_item_after.location_code == ""
          errors += "location_code is required  for stock[#{@stock_item_after.inventory_reference.to_s}]\n"
        end
#      if @stock_item_after.stock_type_code == nil || @stock_item_after.stock_type_code == "" || @stock_item_after.stock_type_code.index("<empty>") != nil
#        errors += "stock_type_code is required!\n"
#      end
        if @stock_item_after.inventory_reference == nil || @stock_item_after.inventory_reference == ""
          errors += "inventory_reference is required!\n"
        else
          if !@stock_item_after.inventory_reference.to_s.is_numeric?
            errors += "inventory_reference must be an integer value!\n"
          end
        end
#      if @stock_item_after.status_code == nil || @stock_item_after.status_code == "" || @stock_item_after.status_code.index("<empty>") != nil
#        errors += "status_code is required!\n"
#      end
      end

      return errors
    end

  end


  class CreateStock < StockTransaction

    def execute
      if @stock_item_after.new_record?
        @stock_item_after.save!
      end


      location = Location.find_by_location_code(@inventory_transaction.location_to)
      #======== Log stock_locations_history=================================
      stock_locations_history = StockLocationsHistory.new({:inventory_transaction_id => @inventory_transaction.id, :stock_item_id => @stock_item_after.id, :inventory_reference => @stock_item_after.inventory_reference,
                                                           :stock_type => @stock_item_after.stock_type_code, :location_id => location.id, :units_in_location_before => location.units_in_location, :location_code => location.location_code})
      location.units_in_location += 1
      if location.units_in_location && location.location_maximum_units && location.location_maximum_units < location.units_in_location
        raise "location: " + location.location_code + " cannot have " + location.units_in_location.to_s + " units. It exceeds the maximum allowed units(" + location.location_maximum_units.to_s + ")"
      end
     # location.update

      stock_locations_history.units_in_location_after = location.units_in_location
      stock_locations_history.save!
      #======== Log stock_locations_history=================================
    end

    def validate
      errors = generic_validate
      if @inventory_transaction != nil
        @inventory_transaction.transaction_quantity_plus = 1
#        if @inventory_transaction.inventory_receipt == nil
#          errors += "inventory transaction must have inventory receipt as it's property\n"
#        end
      end
      if @stock_item_after != nil
        if @stock_item_after.inventory_reference != nil && @stock_item_after.inventory_reference.to_s != ""
          if !@stock_item_after.inventory_reference.to_s.is_numeric?
            errors += "inventory_reference must be an integer value!\n"
          else
            stock_item = StockItem.find_by_inventory_reference(@stock_item_after.inventory_reference)
            if stock_item
              errors += "There exists a stock_item with reference: #{@stock_item_after.inventory_reference.to_s}. inventory_reference must be unique!\n"
            end
          end
        end
      end

#      location_from = Location.find_by_location_code(@inventory_transaction.location_from)
#      if(location_from == nil)
#        errors += "this location[#{@inventory_transaction.location_from}] does not exist. Please create it"
#        return errors
#      end

      return errors
    end

  end

  #----------------------------------------------------------------
  #
  #----------------------------------------------------------------
  class UpdateStock < StockTransaction

    def execute
      @stock_item_after.update
    end

    def validate
      errors = generic_validate
      return errors
    end
  end

  #----------------------------------------------------------------
  #
  #----------------------------------------------------------------
  class RemoveStock < StockTransaction

    def duplicate?
      return @most_recent_trans.transaction_type_code.to_s.upcase == "REMOVE_STOCK"

    end

    def execute
#    if(@stock_item_after.stock_type_code.to_s.upcase != "BINS" && @stock_item_after.stock_type_code.to_s.upcase != "BIN" && @stock_item_after.stock_type_code.to_s.upcase != "REBIN")
      location = Location.find_by_location_code(@stock_item_after.location_code)
      #======== Log stock_locations_history=================================
      stock_locations_history = StockLocationsHistory.new({:inventory_transaction_id => @inventory_transaction.id, :stock_item_id => @stock_item_after.id, :inventory_reference => @stock_item_after.inventory_reference,
                                                           :stock_type => @stock_item_after.stock_type_code, :location_id => location.id, :units_in_location_before => location.units_in_location, :location_code => location.location_code})
      location.units_in_location -= 1
      #location.update_attribute("units_in_location", (location.units_in_location - 1))
      #location.update

      stock_locations_history.units_in_location_after = location.units_in_location
      stock_locations_history.save!
      #======== Log stock_locations_history=================================

      #    end
      if(stock_item_location_to=Location.find_by_location_code(@other[:asset_location_to]))
        @stock_item_after.location_code = stock_item_location_to.location_code
        @stock_item_after.location_id = stock_item_location_to.id
      end
      @stock_item_after.destroyed = true
      @stock_item_after.update

##--------------------------------------------------------------
    end

    def validate
      errors = generic_validate
      if (@stock_item_after.destroyed)
        errors += "stock_item[#{@stock_item_after.inventory_reference} has already been destroyed\n"
      end

      if @inventory_transaction == nil
        errors += "inventory_transaction member variable is required!\n"
      else
        if @inventory_transaction.inventory_issue == nil
          errors += "inventory transaction must have inventory issue as it's property"
        end
      end

      location = Location.find_by_location_code(@stock_item_after.location_code)
      if (location.units_in_location == 0)
        errors += "there are no units to remove in this location[#{@stock_item_after.location_code}]"
      end

      if (!location.units_in_location)
        errors += "this location's[#{@stock_item_after.location_code}] units_in_location is null"
      end

      return errors
    end
  end

  #----------------------------------------------------------------
  #
  #----------------------------------------------------------------
  class MoveStock < UpdateStock

    #================================================
    # This method calls MoveAssetClass
    #================================================

    def duplicate?
      return @most_recent_trans.transaction_type_code.to_s.upcase == "MOVE_STOCK" &&
          @stock_item_after.location_code == @inventory_transaction.location_to


    end

    def create_transaction
      #@inventory_transaction.location_to = @stock_item_before.current_location
      #@stock_item_before.location_code = @inventory_transaction.location_from
      @stock_item_after.location_code = @inventory_transaction.location_to
#    #HANS - added by Luks - otherwise @stock_item_after.location_id remains as the old one
#    @stock_item_after.location_id = Location.find_by_location_code(@inventory_transaction.location_to).id
      @inventory_transaction.transaction_quantity_plus = 1 #@stock_item_after.inventory_quantity
      @inventory_transaction.transaction_quantity_minus = 1 #@stock_item_after.inventory_quantity
      if self.inventory_transaction.new_record?
        #HANS - added by Luks - otherwise @inventory_transaction.location_from will always be null
        @inventory_transaction.location_from = @stock_item_before.location_code if @stock_item_before
        if @inventory_transaction.save!
          @stock_item_after.inventory_transaction_id = @inventory_transaction.id
          self.stock_item_after.inventory_transaction_id = @inventory_transaction.id
          if @inventory_transaction.inventory_receipt != nil
            if @inventory_transaction.inventory_receipt.new_record?
              @inventory_transaction.inventory_receipt.save!
              #Luks - Does not update the @inventory_transaction.inventory_receipt_id - Why???
            end
          end
          if @inventory_transaction.inventory_issue != nil
            if @inventory_transaction.inventory_issue.new_record?
              @inventory_transaction.inventory_issue.save!
            end
          end
        end
      else
        @stock_item_after.inventory_transaction_id = @inventory_transaction.id
      end
    end

    def execute

      location_from = Location.find_by_location_code(@stock_item_before.location_code)
      #======== Log stock_locations_history=================================
      stock_locations_history = StockLocationsHistory.new({:inventory_transaction_id => @inventory_transaction.id, :stock_item_id => @stock_item_before.id, :inventory_reference => @stock_item_before.inventory_reference,
                                                           :stock_type => @stock_item_before.stock_type_code, :location_id => location_from.id, :units_in_location_before => location_from.units_in_location, :location_code => location_from.location_code})

      location_from.loading_out = true if (location_from.units_in_location.to_i - 1) > 1
      location_from.loading_out = nil  if (location_from.units_in_location.to_i - 1) == 0

      location_from.units_in_location = location_from.units_in_location.to_i - 1
      location_from.updated_at = Time.now
      location_from.update #:TODO this was commented out any particular reason

      stock_locations_history.units_in_location_after = location_from.units_in_location
      stock_locations_history.save!
      #======== Log stock_locations_history=================================

      #    #HANS - added by Luks - otherwise @stock_item_after.location_id remains as the old one
      @stock_item_after.location_id = Location.find_by_location_code(@stock_item_after.location_code).id
      @stock_item_after.previous_location_id = location_from.id


      location_to = Location.find_by_location_code(@stock_item_after.location_code)
      #======== Log stock_locations_history=================================
      stock_locations_history = StockLocationsHistory.new({:inventory_transaction_id => @inventory_transaction.id, :stock_item_id => @stock_item_after.id, :inventory_reference => @stock_item_after.inventory_reference,
                                                           :stock_type => @stock_item_after.stock_type_code, :location_id => location_to.id, :units_in_location_before => location_to.units_in_location, :location_code => location_to.location_code})
      location_to.units_in_location = location_to.units_in_location.to_i + 1
      if location_to.units_in_location && location_to.location_maximum_units && location_to.location_maximum_units < location_to.units_in_location
        raise "location: " + location_to.location_code + " cannot have " + location_to.units_in_location.to_s + " units. It exceeds the maximum allowed units(" + location_to.location_maximum_units.to_s + ")"
      end


     # location_to.update

      stock_locations_history.units_in_location_after = location_to.units_in_location
      stock_locations_history.save!
      #======== Log stock_locations_history=================================
      super
    end

#  def validate
#    super
#  end

    def validate
      errors = generic_validate
      if (@stock_item_after.destroyed)
        errors += "stock_item[#{@stock_item_after.inventory_reference} cannot be moved,it has been destroyed\n"
      end
      return errors
    end

  end

# ___________________
#|    BEGGINING      |
#| ASSET API CLASSES |
#|___________________|

#----------------------------------------------------------------
#
#----------------------------------------------------------------
  class GroupedAssetTransaction
    attr_accessor :asset_item_before, :asset_item_after, :inventory_transaction, :other

    def initialize(asset_item_after, inventory_transaction=nil, other=nil)
      @inventory_transaction = inventory_transaction
      @inventory_transaction.validate
      @asset_item_after = asset_item_after
      @asset_item_after.validate
      if !@asset_item_after.new_record?
        @asset_item_before = AssetItem.find(@asset_item_after.id)
      else
        @asset_item_before = nil
      end
      @other = other
    end

    def process
      begin
        errors = validate
        if errors != ""
          raise "Transaction could not be created, reason: " + errors.to_s + $!.to_s
        else
          ActiveRecord::Base.transaction do
          create_transaction
          execute
          log_transaction
          #log_status
          end
        end
      rescue
        raise $!
      end
    end

    def execute

    end

    def set_location(location, asset_item_quantity)
      the_location = Location.find_by_location_code(location)
      asset_location = AssetLocation.find_by_asset_item_id_and_location_id(self.asset_item_after.id, the_location.id)
      if asset_location ==nil
        asset_location = AssetLocation.new
        asset_location.location_id = the_location.id
        asset_location.asset_item_id = self.asset_item_after.id
#       asset_location.location_quantity = self.asset_item_after.quantity
        asset_location.location_quantity = 0 #[2011] HANS - Plus location.qty_in_location :. Should I the update location.qty_in_location when adding and removing stuff in this asset_locn??????
        asset_location.save!
      else
        asset_location.location_quantity = self.asset_item_after.quantity
        asset_location.update
      end
      asset_maintenance_log = AssetMaintenanceLog.new
      asset_maintenance_log.created_on = Time.now.to_formatted_s(:db)
      asset_maintenance_log.asset_item_id = self.asset_item_after.id
      asset_maintenance_log.quantity = 0 #[2011] HANS - Plus location.qty_in_location #self.asset_item_after.quantity
      asset_maintenance_log.save!
    end

    def create_transaction
      if self.inventory_transaction != nil
        if self.inventory_transaction.new_record?
          self.inventory_transaction.save!
          #puts "(asset)inventory_transaction: {" + self.inventory_transaction.attributes.map { |key, value| "[" + key.to_s + "=>" + value.to_s + "]," }.to_s + "}"
          self.asset_item_after.inventory_transaction_id = self.inventory_transaction.id
          if self.inventory_transaction.inventory_receipt != nil
            if self.inventory_transaction.inventory_receipt.new_record?
              self.inventory_transaction.inventory_receipt.save!
            end
          end
          if self.inventory_transaction.inventory_issue != nil
            if self.inventory_transaction.inventory_issue.new_record?
              self.inventory_transaction.inventory_issue.save!
            end
          end
        else
          self.asset_item_after.inventory_transaction_id = self.inventory_transaction.id
          #puts "NOT INV NEW RECORD!"
        end
      end
    end

    def validate
      errors = generic_validate
      return errors
    end

    private

    def log_status
      if self.asset_item_before
        if self.asset_item_after.current_status != self.asset_item_before.current_status
          asset_status = AssetStatus.new
          asset_status.created_on = Time.now.to_formatted_s(:db)
          status = Status.find_by_status_code(self.asset_item_before.current_status)
          asset_status.status_id = status.id
          asset_status.asset_item_id = self.asset_item_before.id
          asset_status.quantity_damaged = self.asset_item_before.quantity

          asset_status.save!
        end
      end
    end

    def log_transaction
      #puts "ASSET LOG TRANS ENTERED 11 @@@"
      if !@asset_item_after.new_record?
        @inventory_transaction_asset = InventoryTransactionAsset.new
        @inventory_transaction_asset.asset_number = @asset_item_after.asset_number
        @inventory_transaction_asset.acquisition_date = @asset_item_after.acquisition_date
        @inventory_transaction_asset.acquisition_price = @asset_item_after.acquisition_price
        @inventory_transaction_asset.depreciation_percentage = @asset_item_after.depreciation_percentage
        @inventory_transaction_asset.asset_type_id = @asset_item_after.asset_type_id
        @inventory_transaction_asset.quantity = @asset_item_after.quantity
        @inventory_transaction_asset.location_code = @asset_item_after.location_code
        @inventory_transaction_asset.owner_party_code = @asset_item_after.party_name
        @inventory_transaction_asset.party_role_id = @asset_item_after.parties_role_id
        @inventory_transaction_asset.inventory_transaction_id = self.inventory_transaction.id
        @inventory_transaction_asset.asset_item_id = @asset_item_after.id
        @inventory_transaction_asset.save!
        #puts "inventory_transaction_asset: {" + @inventory_transaction_asset.attributes.map { |key, value| "[" + key.to_s + "=>" + value.to_s + "]," }.to_s + "}"

        #--------------------------------------
        # Logging inventory transaction location
        #--------------------------------------
        if @inventory_transaction.location_from
          location_from = Location.find_by_location_code(@inventory_transaction.location_from)
          asset_location_from = AssetLocation.find_by_location_id_and_asset_item_id(location_from.id, @asset_item_after.id) if (location_from)
          if (asset_location_from)
            inventoryTransactionLocation = InventoryTransactionLocation.new
            inventoryTransactionLocation.inventoy_transaction_asset_id = @inventory_transaction_asset.id
            inventoryTransactionLocation.transaction_quantity = asset_location_from.location_quantity.to_i
            inventoryTransactionLocation.asset_location_id = asset_location_from.id
            inventoryTransactionLocation.save!

          end
        end
        if (@inventory_transaction.location_to)
          location_to = Location.find_by_location_code(@inventory_transaction.location_to)
          asset_location_to = AssetLocation.find_by_location_id_and_asset_item_id(location_to.id, @asset_item_after.id) if (location_to)
          if (asset_location_to)
            inventoryTransactionLocation = InventoryTransactionLocation.new
            inventoryTransactionLocation.inventoy_transaction_asset_id = @inventory_transaction_asset.id
            inventoryTransactionLocation.transaction_quantity = asset_location_to.location_quantity.to_i
            inventoryTransactionLocation.asset_location_id = asset_location_to.id
            inventoryTransactionLocation.save!
          end
        end
      end
    end

    def generic_validate
      errors = ""
      if @inventory_transaction != nil
        if @inventory_transaction.transaction_type_id == nil || @inventory_transaction.transaction_type_id == ""
          errors += "'transaction_type_id' is required!.\n"
        end
        if @inventory_transaction.transaction_type_code == nil || @inventory_transaction.transaction_type_code ==""
          errors += "'transaction_type_code' is required!.\n"
        end
        if @inventory_transaction.transaction_date_time == nil || @inventory_transaction.transaction_date_time == ""
          errors += "'transaction_date_time' is required!\n"
        end
#        if @inventory_transaction.reference_number == nil || @inventory_transaction.reference_number == ""
#          errors += "reference_number is required!\n"
#        end
      end

      if @asset_item_after == nil
        errors += "'asset_item_after' member variable can't be null\n"
      else
        if @asset_item_after.asset_number == nil || @asset_item_after.asset_number == ""
          errors += "asset_number is required!\n"
        end
        if @asset_item_after.asset_type_id == nil || @asset_item_after.asset_type_id == ""
          errors += "asset_type_id is required!\n"
        end
        if @asset_item_after.quantity != nil || @asset_item_after.quantity.to_s.strip != ""
          #errors += "quantity is required!\n"
          #else
          #  if @asset_item_after.quantity == 0
          #   errors += "asset quantity must be an integer value"
          #end
          begin
            int = Integer(@asset_item_after.quantity)
          rescue
            errors += "quantity must be an integer value"
          end
        else
          @asset_item_after.quantity = 0
        end
      end
      #if @asset_item_after.current_location == nil || @asset_item_after.current_location == ""  || @asset_item_after.current_location.index("<empty>") != nil
      # errors += "current_location is required!\n"
      #end
      return errors
    end

  end

  #------------------------------------------------------------------------
  #
  #
  # N.B. the 'Class' part of the derived class names means that here we are
  # dealing with the class/type of asset instead of an individual
  # asset!
  #-------------------------------------------------------------------------
  class CreateAssetClass < GroupedAssetTransaction

    def execute
      if @asset_item_after.new_record?
        @asset_item_after.save!
        if @asset_item_after.location_code != nil && @asset_item_after.location_code != ""
          location = Location.find_by_location_code(@asset_item_after.location_code)
          location_id = location.id if location
          if AssetLocation.find_by_location_id_and_asset_item_id(location_id, @asset_item_after.id) == nil
            begin
              asset_location = AssetLocation.new
              asset_location.location_id = location_id
              asset_location.asset_item_id = @asset_item_after.id
              asset_location.location_quantity = @asset_item_after.quantity
              asset_location.save!
            rescue
            end
          end
        end
      end
    end

    def validate
      errors = generic_validate
      if @asset_item_after != nil
        if @asset_item_after.asset_number != nil && @asset_item_after.asset_number.to_s.strip != ""
          asset_item = AssetItem.find_by_asset_number(@asset_item_after.asset_number)
          if asset_item
            errors += "There exists a record with specified 'asset_number'. asset_number must be unique!\n"
          end
        end
      end
      return errors
    end
  end

  class DeleteAssetLocation < GroupedAssetTransaction
    def validate
      errors = generic_validate
      the_location = Location.find_by_location_code(@asset_item_after.location_code)
      asset_location = AssetLocation.find_by_asset_item_id_and_location_id(@asset_item_after.id, the_location.id)
      if asset_location != nil
        if asset_location.location_quantity > 0
          errors += "Cannot delete asset location: There are bins in this location.\n"
        end
      else
        errors += "This asset location does not exist\n"
      end
      return errors
    end

    def log_transaction
    end

    def execute
      the_location = Location.find_by_location_code(@asset_item_after.location_code)
      asset_location = AssetLocation.find_by_asset_item_id_and_location_id(@asset_item_after.id, the_location.id)
      asset_location.destroy
    end
  end
  #------------------------------------------------------------------------
  #
  #
  # N.B. the 'Class' part of the derived class names means that here we are
  # dealing with the class/type of asset instead of an individual
  # asset!
  #-------------------------------------------------------------------------
  class AssetClassNewLocation < GroupedAssetTransaction

    def execute
      set_location(@asset_item_after.location_code, @asset_item_after.quantity)
#     if @asset_item_after.new_record?
#       @asset_item_after.save!
#       if @asset_item_after.location_code != nil && @asset_item_after.location_code != ""
#          location_id = Location.find_by_location_code(@asset_item_after.location_code).id
#          if AssetLocation.find_by_location_id_and_asset_item_id(location_id, @asset_item_after.id) == nil
#             asset_location = AssetLocation.new
#             asset_location.location_id = location_id
#             asset_location.asset_item_id = @asset_item_after.id
#             asset_location.location_quantity = @asset_item_after.quantity
#             asset_location.save!
#          end
#       end
#     end
    end

#   def log_transaction
#
#   end
#  def validate
#    errors = generic_validate
#    if @asset_item_after != nil
#      if @asset_item_after.asset_number != nil && @asset_item_after.asset_number.to_s.strip != "" && @asset_item_after.asset_number.index("<empty>") == nil
#        asset_item = AssetItem.find_by_asset_number(@asset_item_after.asset_number)
#        if asset_item
#          errors += "There exists a record with specified 'asset_number'. asset_number must be unique!\n"
#        end
#      end
#    end
#    return errors
#  end
  end

  #------------------------------------------------------------------------
  #
  #-------------------------------------------------------------------------
  class RemoveAssetClass < GroupedAssetTransaction
    #attr_accessor :issue

    #def initialize(asset_item,issue=nil)
    #  @asset_item_after = asset_item
    #  @issue = issue
    #end

    def execute
      @asset_item_after.destroy
    end
  end

  #------------------------------------------------------------------------
  #
  #-------------------------------------------------------------------------
  class UpdateAssetClass < GroupedAssetTransaction

    def validate
      errors = generic_validate
      return errors
    end

    def execute
      @asset_item_after.update
    end
  end

  #------------------------------------------------------------------------
  #
  #-------------------------------------------------------------------------
  class MoveAssetClass < UpdateAssetClass

    def validate
      errors = generic_validate
      if @inventory_transaction != nil
        if @inventory_transaction.transaction_quantity_plus == nil || @inventory_transaction.transaction_quantity_plus.to_s.strip == ""
          errors += "transaction_quantity_plus is required!"
        end
        if @inventory_transaction.location_from == nil || @inventory_transaction.location_from.to_s == ""
          errors += "location_from is required for asset[#{@asset_item_after.asset_number.to_s}]"
        end
        if @inventory_transaction.location_to == nil || @inventory_transaction.location_to.to_s == ""
          errors += "location_to is required for asset[#{@asset_item_after.asset_number.to_s}]"
        end
        if (@inventory_transaction.location_from != nil && @inventory_transaction.location_from.to_s != "" && @inventory_transaction.transaction_quantity_plus != nil && @inventory_transaction.transaction_quantity_plus.to_s.strip != "")
          location_from = Location.find_by_location_code(@inventory_transaction.location_from)
          if (location_from == nil)
            errors += "this location[#{@inventory_transaction.location_from}] does not exist. Please create it"
            return errors
          end
          location_from_id = location_from.id

          asset_location_from = AssetLocation.find_by_location_id_and_asset_item_id(location_from_id, @asset_item_after.id)
          if !asset_location_from
            errors += "Location from(" + location_from.location_code + ") for Grouped Asset( " + @asset_item_after.asset_number.to_s + ") does not exist! "
            return errors
          end
        end
      else
        errors += "inventory_transaction member var is required to do this transaction"
      end
      return errors
    end

    def execute
      if @inventory_transaction.location_from != nil && @inventory_transaction.location_to != nil && @inventory_transaction.location_from.to_s != "" && @inventory_transaction.location_to.to_s != "" && (@inventory_transaction.location_from != @inventory_transaction.location_to)
        location_from = Location.find_by_location_code(@inventory_transaction.location_from)
        asset_location_from = AssetLocation.find_by_location_id_and_asset_item_id(location_from.id, @asset_item_after.id)
        location_to = Location.find_by_location_code(@inventory_transaction.location_to)
        asset_location_to = AssetLocation.find_by_location_id_and_asset_item_id(location_to.id, @asset_item_after.id)

        if !asset_location_to
          @asset_item_after.location_code = @inventory_transaction.location_to
          Inventory::AssetClassNewLocation.new(@asset_item_after, @inventory_transaction).process
          asset_location_to = AssetLocation.find_by_location_id_and_asset_item_id(location_to.id, @asset_item_after.id)
        end

        asset_location_to.location_quantity = asset_location_to.location_quantity + @inventory_transaction.transaction_quantity_plus
        asset_location_to.update

#
        asset_location_from.location_quantity = asset_location_from.location_quantity - @inventory_transaction.transaction_quantity_plus
        asset_location_from.update
        @asset_item_after.update
        super
      end
    end
  end

  #------------------------------------------------------------------------
  #
  #-------------------------------------------------------------------------
  class ChangeAssetClassQuantity < UpdateAssetClass


    def validate

      errors = super
      location_code = @inventory_transaction.location_to.to_s
      location = Location.find_by_location_code(location_code)
      errors += "location: " + location_code + " does not exist" if !location
      return errors
    end


    def execute
      if @inventory_transaction != nil
        location_code = nil
        if @inventory_transaction.location_to != nil && @inventory_transaction.location_to.to_s.strip != ""
          location_code = @inventory_transaction.location_to
        end
        location = Location.find_by_location_code(location_code)
        if location

          location_id = location.id
          asset_location = AssetLocation.find_by_location_id_and_asset_item_id(location_id, @asset_item_after.id)

          if !asset_location
            @asset_item_after.location_code = @inventory_transaction.location_to
            Inventory::AssetClassNewLocation.new(@asset_item_after, @inventory_transaction).process
            asset_location = AssetLocation.find_by_location_id_and_asset_item_id(location.id, @asset_item_after.id)
          end
          if asset_location
            #--------------------------------------
            # Logging inventory transaction location
            #--------------------------------------
            #            if !(InventoryTransactionLocation.find_by_asset_location_id_and_inventoy_transaction_asset_id(asset_location.id,@inventory_transaction_asset.id))
            #            inventoryTransactionLocation = InventoryTransactionLocation.new
            #            inventoryTransactionLocation.inventoy_transaction_asset_id = @inventory_transaction_asset.id
            #            inventoryTransactionLocation.transaction_quantity = asset_location.location_quantity.to_i
            #            inventoryTransactionLocation.asset_location_id = asset_location.id
            #            inventoryTransactionLocation.save!
            #            end

            if @inventory_transaction.transaction_quantity_plus
#
              asset_location.location_quantity = asset_location.location_quantity.to_i + @inventory_transaction.transaction_quantity_plus.to_i
              @asset_item_after.quantity = @asset_item_after.quantity.to_i + @inventory_transaction.transaction_quantity_plus.to_i
              @asset_item_after.update
              asset_location.update
            elsif @inventory_transaction.transaction_quantity_minus
#
              asset_location.location_quantity = asset_location.location_quantity.to_i - @inventory_transaction.transaction_quantity_minus.to_i
              @asset_item_after.quantity = @asset_item_after.quantity.to_i - @inventory_transaction.transaction_quantity_minus.to_i
              @asset_item_after.update
              asset_location.update
            else

            end
            super
          end
        end
      else
        location = Location.find_by_location_code(@asset_item_after.current_location)
        location_id = location.id
        asset_location = AssetLocation.find_by_location_id_and_asset_item_id(location_id, @asset_item_after.id)
        if asset_location
          asset_location.location_quantity = self.asset_item_after.quantity
          self.asset_item_after.update
          asset_location.update
          super
        end
      end

    end
  end

  #----------------------------------------------------------------
  #
  #----------------------------------------------------------------
  class UndoRemoveStock < StockTransaction
    def validate
      super
      errors = generic_validate
      if @inventory_transaction.inventory_issue == nil
        errors = "inventory_issue does not extist for transaction"
      end
    end

    def duplicate?
      return @most_recent_trans.transaction_type_code.to_s.upcase == "UNDO_REMOVE_STOCK"

    end

    def execute
      @stock_item_after.destroyed = nil
      @stock_item_after.update
      @stock_item_after.location.units_in_location += 1
      #@stock_item_after.location.update

    end
  end

  #===============================
  #=== Inventory Model Facade  ===
  #===============================

  def self.create_stock(owner_party_role_id, stock_type, farm_code, truck_code, trans_name, trans_id, location_code, stock_ids)
    raise "Validation error: passed in stock_type must have a valid value" if !stock_type or stock_type.to_s.strip == ""
    raise "Validation error: passed in trans_name must have a valid value" if !trans_name or trans_name.to_s.strip == ""
    raise "Validation error: passed in location_code must have a valid value" if !location_code or location_code.to_s.strip == ""
    raise "Validation error: you must pass in atleast 1 stock id" if !stock_ids or stock_ids.length == 0
    #	----------------------
    #	 Define lookup fields
    #	----------------------
    if (farm_code)
      farm = Farm.find_by_farm_code(farm_code)
      farm_id = farm.id
    end
    inventory_receipt_type = InventoryReceiptType.find_by_inventory_receipt_type_code('intake_delivery') #HARD-CODED - Hans???
    if (owner_party_role_id && owner_party_role_id != 0 && owner_party_role_id.to_s.strip != "")
      party_role = PartiesRole.find(owner_party_role_id)
      party_role_role_name = party_role.role_name
    end
    location = Location.find_by_location_code(location_code)
    raise "Validation error: location[" + location_code.to_s + "] not found!" if !location

#    2. I added :party_role_name=>party_role.role_name
    inventory_receipt = InventoryReceipt.new({:receipt_date_time => Time.now.to_formatted_s(:db), :farm_code => farm_code,
                                              :farm_id => farm_id, :truck_code => truck_code, :parties_role_id => owner_party_role_id, :parties_role_name => party_role_role_name, :reference_number => trans_id,
                                              :inventory_receipt_type_id => inventory_receipt_type.id, :quantity_received => stock_ids.length})

    #	----------------------
    #	 Define lookup fields
    #	----------------------
    transaction_type = TransactionType.find_by_transaction_type_code('create_stock')
    raise "Validation error: transaction_type[" + transaction_type.to_s + "]  not found!" if !transaction_type
    transaction_business_name = TransactionBusinessName.find_by_transaction_business_name_code(trans_name.upcase)
    raise "Validation error: transaction business name[" + trans_name.upcase.to_s + "]  not found!" if !transaction_business_name

    stock_type_rec = StockType.find_by_stock_type_code(stock_type.upcase)
    raise "Validation error:stock type[" + stock_type.upcase.to_s + "] not found" if !stock_type_rec

    inventory_transaction = InventoryTransaction.new({:transaction_type_code => transaction_type.transaction_type_code,
                                                      :transaction_business_name_code => trans_name.upcase, :transaction_date_time => Time.now.to_formatted_s(:db),
                                                      #                          :location_from=>farm_code,#[2011]
                                                      :location_to => location_code, :transaction_type_id => transaction_type.id, :reference_number => trans_id,
                                                      :transaction_business_name_id => transaction_business_name.id,
                                                      :transaction_quantity_plus => stock_ids.length})
    inventory_transaction.inventory_receipt = inventory_receipt

    stock_ids.each do |stock_item_inventory_reference|
      stock_item = StockItem.new({:stock_type_code => stock_type.upcase, :stock_type_id => stock_type_rec.id, :location_code => location_code, :location_id => location.id,
                                  :inventory_quantity => 1, :status_code => 'available',
                                  :inventory_reference => stock_item_inventory_reference, :parties_role_id => owner_party_role_id})
      CreateStock.new(inventory_transaction, stock_item, {:farm_code => farm_code}).process

    end
    #Inventory.sync_units_in_location(stock_ids, "CREATE", trans_name, inventory_transaction.id,location_code)
  end

  def self.move_stock(trans_name, trans_id, location_to, stock_ids)
    raise "Validation error: passed in trans_name must have a valid value" if !trans_name or trans_name.to_s.strip == ""
    raise "Validation error: passed in location_to must have a valid value" if !location_to or location_to.to_s.strip == ""
    raise "Validation error: you must pass in atleast 1 stock id" if !stock_ids or stock_ids.length == 0
    raise "Validation error: location[" + location_to + "] does not exist" if !Location.find_by_location_code(location_to)
    #	----------------------
    #	 Define lookup fields
    #	----------------------
    #    inventory_receipt_type = InventoryReceiptType.find_by_inventory_receipt_type_code('intake_delivery')#HARD-CODED - Hans???
    #
    #    inventory_receipt = InventoryReceipt.new({:receipt_date_time=>Time.now.to_formatted_s(:db),:reference_number=>trans_id,
    #                        :inventory_receipt_type_id=>inventory_receipt_type.id,:quantity_received=>stock_ids.length})

    #	----------------------
    #	 Define lookup fields
    #	----------------------
    transaction_type = TransactionType.find_by_transaction_type_code('move_stock')
    raise "Validation error: transaction_type[move_stock]  not found!" if !transaction_type
    transaction_business_name = TransactionBusinessName.find_by_transaction_business_name_code(trans_name.upcase)
    raise "Validation error: transaction business name[" + trans_name.upcase + "] not found!" if !transaction_business_name

    inventory_transaction = InventoryTransaction.new({:transaction_type_code => transaction_type.transaction_type_code,
                                                      :transaction_business_name_code => trans_name.upcase, :transaction_date_time => Time.now.to_formatted_s(:db),
                                                      :location_to => location_to, :transaction_type_id => transaction_type.id, :reference_number => trans_id,
                                                      :transaction_business_name_id => transaction_business_name.id, #:inventory_receipt_id=>inventory_receipt.id,#Remove - Done internally
                                                      :transaction_quantity_plus => stock_ids.length})

    stock_ids.each do |stock_item_inventory_reference|
      #	----------------------
      #	 Define looku6p fields
      #	----------------------
      stock_item = StockItem.find_by_inventory_reference(stock_item_inventory_reference)
      raise "Validation error: stock_item[" + stock_item_inventory_reference + "] does not exist" if !stock_item
#      stock_item.status_code = "active" #Hans - ??????
      MoveStock.new(inventory_transaction, stock_item).process
    end

    #Inventory.sync_units_in_location(stock_ids, "MOVE", trans_name, inventory_transaction.id, location_to)

  end


  def self.sync_units_in_location(stock_ids, trans_type, bus_context, inventory_transaction_id, location_to = nil)

    location_ctx = "previous_location_id"
    location_ctx = "location_id" if trans_type == "REMOVE_STOCK"

    from_locations_sql = " select distinct #{location_ctx} from stock_items where  "

    for stock_id in stock_ids
      from_locations_sql += "inventory_reference = '" + stock_id.to_s + "'"
        from_locations_sql += " OR "
    end

    from_locations_sql.slice!( from_locations_sql.size() - 4,4)



    from_locations = ActiveRecord::Base.connection.select_all(from_locations_sql)

    from_locations.each do |from_location|
      if from_location['previous_location_id']
        location = Location.find(from_location['previous_location_id'].to_i)
        if result = location.sync_units_in_location(stock_ids, trans_type, bus_context, inventory_transaction_id)
          RAILS_DEFAULT_LOGGER.error "LOCATION UNITS ADJUSTMENT : location(FROM): #{location.location_code}. Was: #{result[0]}. Changed to: #{result[1]}"
        end
      end

    end

    if location_to
      to_location = location = Location.find_by_location_code(location_to)
      if result = to_location.sync_units_in_location(stock_ids, trans_type, bus_context, inventory_transaction_id)
        RAILS_DEFAULT_LOGGER.error "LOCATION UNITS ADJUSTMENT: location(TO): #{location_to}. Was: #{result[0]}. Changed to: #{result[1]}"
      end
    end

  end

  def self.undo_move_stock(stock_ids, transaction_business_name, reference_number)
    raise "Validation error: passed in transaction_business_name must have a valid value" if !transaction_business_name or transaction_business_name.to_s.strip == ""
    raise "Validation error: you must pass in atleast 1 stock id" if !stock_ids or stock_ids.length == 0

    stock_ids.each do |stock_item_inventory_reference|
      @inventory_transaction_stocks = InventoryTransactionStock.find_by_sql("select inventory_transaction_stocks.location_id from inventory_transaction_stocks
                    join stock_items on stock_items.id = inventory_transaction_stocks.stock_item_id
                    where stock_items.inventory_reference = '#{stock_item_inventory_reference}' 
                    order by inventory_transaction_stocks.id desc")
      if (@inventory_transaction_stocks.length > 0)
        @location_to = Location.find(@inventory_transaction_stocks[0].location_id).location_code
        self.move_stock(transaction_business_name.upcase, reference_number, @location_to, [stock_item_inventory_reference])
      end
    end
  end

  def self.remove_stock(truck_code, stock_type, trans_name, trans_id, location, stock_ids, asset_location_to=nil)
    raise "Validation error: passed in trans_name must have a valid value" if !trans_name or trans_name.to_s.strip == ""
    raise "Validation error: passed in location must have a valid value" if !location or location.to_s.strip == ""
    raise "Validation error: you must pass in atleast 1 stock id" if !stock_ids or stock_ids.length == 0
    raise "Validation error: You must provide a location" if !location

    location_rec = Location.find_by_location_code(location)
    raise "Validation error: location[" + location + "] does not exist" if !location_rec

    inventory_issue = InventoryIssue.new({:issue_date_time => Time.now.to_formatted_s(:db), :reference_number => trans_id,
                                          :quantity_issued => stock_ids.length, :truck_code => truck_code})

    #	----------------------
    #	 Define lookup fields
    #	----------------------
    transaction_type = TransactionType.find_by_transaction_type_code('remove_stock')
    raise "Validation error: transaction_type[remove_stock] not found!" if !transaction_type
    transaction_business_name = TransactionBusinessName.find_by_transaction_business_name_code(trans_name.upcase)

    raise "Validation error: transaction business name[" + trans_name.upcase + "] not found!" if !transaction_business_name


    inventory_transaction = InventoryTransaction.new({:transaction_type_code => transaction_type.transaction_type_code,
                                                      :transaction_business_name_code => trans_name.upcase, :transaction_date_time => Time.now.to_formatted_s(:db),
                                                      :location_to => location, :transaction_type_id => transaction_type.id, :reference_number => trans_id,
                                                      :transaction_business_name_id => transaction_business_name.id, #:inventory_receipt_id=>inventory_receipt.id,#Remove - Done internally
                                                      :transaction_quantity_plus => stock_ids.length})
    inventory_transaction.inventory_issue = inventory_issue

    stock_ids.each do |stock_item_inventory_reference|
      stock_item = StockItem.find_by_inventory_reference(stock_item_inventory_reference)
      raise "Validation error: stock_item[" + stock_item_inventory_reference + "] does not exist" if !stock_item

      RemoveStock.new(inventory_transaction, stock_item, {:asset_location_to => asset_location_to}).process
    end
   # Inventory.sync_units_in_location(stock_ids, "REMOVE", trans_name,inventory_transaction.id)           #(stock_ids, trans_type, bus_context, inventory_transaction_id, location_to = nil)
  end

  def self.undo_destroy_stock(stock_ids, transaction_business_name, reference_number)
    raise "Validation error: passed in trans_name must have a valid value" if !transaction_business_name or transaction_business_name.to_s.strip == ""
    raise "Validation error: you must pass in atleast 1 stock id" if !stock_ids or stock_ids.length == 0
    inventory_issue = InventoryIssue.new({:issue_date_time => Time.now.to_formatted_s(:db), :reference_number => reference_number,
                                          :quantity_issued => stock_ids.length})

    #	----------------------
    #	 Define lookup fields
    #	----------------------
    transaction_type = TransactionType.find_by_transaction_type_code('undo_remove_stock')
    raise "Validation error: transaction_type not found!" if !transaction_type
    transaction_name = TransactionBusinessName.find_by_transaction_business_name_code(transaction_business_name.upcase)
    raise "Validation error: transaction business name[" + transaction_business_name.upcase + "] not found!" if !transaction_name

    inventory_transaction = InventoryTransaction.new({:transaction_type_code => transaction_type.transaction_type_code,
                                                      :transaction_business_name_code => transaction_business_name.upcase, :transaction_date_time => Time.now.to_formatted_s(:db),
                                                      :transaction_type_id => transaction_type.id, :reference_number => reference_number,
                                                      :transaction_business_name_id => transaction_name.id, :transaction_quantity_plus => stock_ids.length})
    inventory_transaction.inventory_issue = inventory_issue

    stock_ids.each do |stock_item_inventory_reference|
      stock_item = StockItem.find_by_inventory_reference(stock_item_inventory_reference)
      UndoRemoveStock.new(inventory_transaction, stock_item).process
    end
   # Inventory.sync_units_in_location(stock_ids, "UNDO_REMOVE", transaction_business_name,inventory_transaction.id)
  end

end