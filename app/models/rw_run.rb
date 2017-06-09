class RwRun < ActiveRecord::Base

  #require "outbox_processor.rb"

  has_many :rw_cartons, :dependent => :delete_all
  has_many :rw_active_cartons, :dependent => :delete_all
  has_many :rw_receipt_cartons, :dependent => :delete_all
  has_many :rw_scrap_cartons, :dependent => :delete_all
  has_many :rw_reclassed_cartons, :dependent => :delete_all
  has_many :rw_pallets, :dependent => :delete_all
  has_many :rw_active_pallets, :dependent => :delete_all
  has_many :rw_receipt_pallets, :dependent => :delete_all
  has_many :rw_scrap_pallets, :dependent => :delete_all
  has_many :rw_reclassed_pallets, :dependent => :delete_all
  has_many :rw_active_bins, :dependent => :delete_all
  has_many :rw_reclassed_bins, :dependent => :delete_all
  has_many :rw_scrap_bins, :dependent => :delete_all
  has_many :rw_receipt_bins, :dependent => :delete_all
  has_many :rw_receipt_intake_headers_productions, :dependent =>  :delete_all
  has_many :rw_reclassed_intake_headers_productions, :dependent => :delete_all


  has_many :rw_receipt_cartons_histories

  def add_quantity_to_location(bin, original_bin, transaction_type_code)

    stock_item = StockItem.find_by_inventory_reference(original_bin.bin_number)


    transaction_type = TransactionType.find_by_transaction_type_code(transaction_type_code)
    transaction_business_name = TransactionBusinessName.find_by_transaction_business_name_code("REWORKS_BIN_TYPE_CHANGE")

    inventory_transaction = InventoryTransaction.new({:transaction_type_code=>transaction_type.transaction_type_code, :transaction_type_id=>transaction_type.id,
                                                      :transaction_business_name_code=>transaction_business_name.transaction_business_name_code, :transaction_business_name_id=>transaction_business_name.id,
                                                      :transaction_date_time =>Time.now.to_formatted_s(:db), :reference_number=>bin.rw_run_id,
                                                      :location_to => stock_item.location_code
                                                     })

    bin_nr = nil
    if (transaction_type.transaction_type_code == "add_asset_quantity")
      bin_nr = bin.bin_number.to_s
      asset_number = PackMaterialProduct.find(bin.pack_material_product_id).pack_material_product_code #Plastic
      inventory_transaction.transaction_quantity_plus = 1
    else
      asset_number = PackMaterialProduct.find(original_bin.pack_material_product_id).pack_material_product_code
      bin_nr = original_bin.bin_number.to_s
      inventory_transaction.transaction_quantity_minus = 1 #if(transaction_type.transaction_type_code == "remove_asset_quantity")
    end


    asset_item = AssetItem.find_by_asset_number(asset_number)
    raise " Bin: #{bin_nr} has pack material of: #{asset_number} for which no asset item exists" if ! asset_item
    Inventory::ChangeAssetClassQuantity.new(asset_item, inventory_transaction).process
    # subtract_asset_quantity
  end


  def RwRun.get_object_nums(object_type, n_nums_required)
    result = nil
    require 'timeout'
    timeout(200) do
      result = RwRun.get_object_nums_internal(object_type, n_nums_required)
    end
    return result
  end

  def RwRun.get_object_nums_internal(object_type, n_nums_required)

    args = object_type + "," + n_nums_required.to_s
    command = "<RequestServer Mode=\"1\" PID=\"233\" Args=\"#{args}\" Op=\"111\" Su=\"222\" />"
    puts command
    require 'socket'

    puts "Connecting to num gen server"
    t = TCPSocket.new(Globals.get_mesware_ip(), '2023')
    begin
      t.puts command
      puts "connected."
      received = t.gets

      puts "Server returned: " + received.to_s

      #----------
      #VALIDAIONS
      #----------

      if received.index("failed")
        raise "A new " + object_type + " number could not be generated. The java server returned the following error: " + received
      end

      num_array = received.split(",")
      if num_array.length != n_nums_required
        raise "The amount of numbers received(" + num_array.length.to_s + ") does not match the requested amount(" + n_nums_required.to_s + ")"
      end


      #validate each number in received array
      num_array.each do |num|
        num.strip!
        gen_num = num.to_i
        raise "The java server returned an invalid number. " + num.to_s + " is not a valid number." if gen_num == 0
        # puts "iteration " + object_type.upcase

        if object_type.upcase == "CARTON" && num.length != 12
          raise "The received number for requested type: " + object_type + " is not valid. Received number was: " + num
        elsif object_type.upcase == "PALLET" && num.length != 17
          raise "The received number for requested type: " + object_type + " is not valid. Received number was: " + num
        end
      end

    ensure
      t.close
    end


    return num_array

  end


  def cancel_run
    busy?("cancel run")
    begin
      self.transaction do
        pallet_numbers_order_upgrade=nil
        if self.rw_active_pallets && self.rw_active_pallets.length > 0
           pallet_numbers_order_upgrade=self.rw_active_pallets.map{|p|p.pallet_number}
        end

        self.rw_active_cartons.delete_all
        self.rw_cartons.delete_all
        self.rw_scrap_cartons.delete_all
        self.rw_reclassed_cartons.delete_all
        self.rw_receipt_cartons.delete_all

        self.rw_active_pallets.delete_all
        self.rw_scrap_pallets.delete_all
        self.rw_reclassed_pallets.delete_all
        self.rw_pallets.delete_all
        self.rw_receipt_pallets.destroy_all

        self.rw_active_bins.delete_all
        self.rw_reclassed_bins.delete_all
        self.rw_receipt_bins.delete_all



        if pallet_numbers_order_upgrade
          Order.get_and_upgrade_prelim_orders(pallet_numbers_order_upgrade)
        end


      end
    rescue
      raise "The run could not be canceled: " + $!
    ensure
      done
    end
  end

  def carton_active_in_other_reworks_run?(carton_number)
    query = "SELECT public.rw_runs.*
             FROM
             public.rw_receipt_cartons
             INNER JOIN public.rw_runs ON (public.rw_receipt_cartons.rw_run_id = public.rw_runs.id)
             WHERE
            (public.rw_runs.rw_run_status_code = 'editing') AND 
            (public.rw_receipt_cartons.carton_number = '#{carton_number}')"

    runs = RwRun.find_by_sql(query)
    if runs.length == 0
      return nil
    else
      return "Carton:  #{carton_number} already received in another editing reworks run<BR>run:  #{runs[0].rw_run_name} <BR>user:  #{runs[0].username} "

    end

  end

  def not_yet_received_rebin?(rebin_number)
    query = "SELECT public.rw_runs.*
             FROM
             public.rw_receipt_rebins
             INNER JOIN public.rw_runs ON (public.rw_receipt_rebins.rw_run_id = public.rw_runs.id)
             WHERE
            (public.rw_runs.rw_run_status_code = 'editing') AND 
            (public.rw_receipt_rebins.rebin_number = '#{rebin_number}')"

    runs = RwRun.find_by_sql(query)
    return (runs.length == 0)

  end

  def pallet_active_in_other_run?(pallet_number)
    query = "SELECT public.rw_runs.*
             FROM
             public.rw_receipt_pallets
             INNER JOIN public.rw_runs ON (public.rw_receipt_pallets.rw_run_id = public.rw_runs.id)
             WHERE
            (public.rw_runs.rw_run_status_code = 'editing') AND 
            (public.rw_receipt_pallets.pallet_number = '#{pallet_number}')"

    runs = RwRun.find_by_sql(query)
    if runs.length == 0
      return nil
    else
      return "Pallet:  #{pallet_number} already received in another reworks run<BR>run:  #{runs[0].rw_run_name} <BR>user:  #{runs[0].username} "

    end

  end

  def set_build_status(pallet)

    if pallet.rw_active_cartons.length() == 0
      return
    end

    pallet.get_carton_count()

    status = "PARTIAL"
    cpp = nil
    if pallet.reworks_action == "new_pallet"
      cpp = CartonsPerPallet.find_all_by_carton_pack_product_code_and_pallet_format_product_code(pallet.carton_pack_product_code, pallet.pallet_format_product_code, :order => "id")
    else
      pallet.rw_active_cartons[0].decompose_fields if !pallet.rw_active_cartons[0].carton_pack_product_code
      carton_pack_product_code = pallet.rw_active_cartons[0].carton_pack_product_code
      cpp = CartonsPerPallet.find_all_by_carton_pack_product_code_and_pallet_format_product_code(carton_pack_product_code, pallet.pallet_format_product_code, :order => "id")
    end

    if cpp.length > 0
      if cpp[0].cartons_per_pallet > pallet.carton_quantity_actual||cpp[0].cartons_per_pallet < pallet.carton_quantity_actual
        status = "PARTIAL"
        pallet.cpp = cpp[0].cartons_per_pallet
      else
        status = "FULL"
        pallet.cpp = cpp[0].cartons_per_pallet
      end
    end

    pallet.build_status = status


  end


  def set_pallet_carton_quantities
    self.rw_active_pallets.each do |pallet|
      num = pallet.rw_active_cartons.find(:conditions => "exit_reference <> 'scrapped'").length
      pallet.carton_quantity_actual = num
    end

  end


  def busy?(action)
    this_run = RwRun.find(self.id)
    if this_run.busy
      raise "This run is already busy with a " + this_run.busy + " transaction"
    else
      this_run.busy = action
      this_run.update
    end

  end

  def done

    this_run = RwRun.find(self.id)
    this_run.busy = nil
    this_run.update
  end


  def set_inspection_status_for_built_up_pallets

    query = "select distinct rw_active_pallet_id from rw_active_cartons where rw_run_id = #{self.id.to_s} and (rw_active_pallet_id is not null and  (upper(rw_pallet_action) = 'ADDED' OR upper(rw_pallet_action) = 'REMOVED'))"
    puts query
    pallet_ids = self.connection.select_all(query)
    if pallet_ids.length() > 0
      pallet_ids.each do |record|
        #------------------------------------------------------------------------------
        #All cartons on pallet must have exact same qc_status_code and qc_result_status
        #------------------------------------------------------------------------------
        qc_test_query = "select distinct qc_status_code,qc_result_status from rw_active_cartons where rw_active_pallet_id = #{record['rw_active_pallet_id']} and public.rw_active_cartons.rw_run_id = #{self.id.to_s}"
        puts qc_test_query
        qc_list = self.connection.select_all(qc_test_query)
        if qc_list.length() > 1 #qc field values must be uniform- same for all cartons on pallet, else re-inspection needed
          puts "PALLET: " + record['rw_active_pallet_id'].to_s + "need re-inspection from build-up"
          #--------------------------------------------------------------------------------------------------------------
          #Update pallet and all it's cartons: qc_status_code to 'uninspected' and qc_result_status to null +
          #get most recent ppecb_nspection for the pallet and create a copy with cancelled set to true
          #--------------------------------------------------------------------------------------------------------------
          pallet = RwActivePallet.find(record['rw_active_pallet_id'])
          pallet.qc_status_code = 'UNINSPECTED'
          pallet.qc_result_status = nil
          pallet.update
          RwActiveCarton.update_all(ActiveRecord::Base.extend_set_sql_with_request("qc_status_code = 'UNINSPECTED',qc_result_status = null","rw_active_cartons"), "rw_active_pallet_id = #{record['rw_active_pallet_id']} and public.rw_active_cartons.rw_run_id = #{self.id.to_s}")
        else
          puts "PALLET: " + record['rw_active_pallet_id'].to_s + "does NOT need re-inspection from build-up"
        end
      end
    end
  end


  def set_inspection_status_for_grade_changes

    qc_reset_query = "SELECT DISTINCT rw_active_pallet_id FROM public.rw_active_cartons
            INNER JOIN public.rw_receipt_cartons ON (public.rw_active_cartons.carton_number = public.rw_receipt_cartons.carton_number)
            INNER JOIN public.grades ON (public.rw_active_cartons.grade_code = public.grades.grade_code)
            INNER JOIN public.grades grades1 ON (public.rw_receipt_cartons.grade_code = grades1.grade_code)
            WHERE ((rw_active_pallet_id is not null AND rw_active_pallet_id <> -1) and grades1.qa_level < grades.qa_level and public.rw_active_cartons.rw_run_id = #{self.id.to_s})"
    puts "GRADE CHANGE TEST QUERY: " + qc_reset_query
    pallet_ids = self.connection.select_all(qc_reset_query)
    if pallet_ids.length() > 0
      pallet_ids.each do |record|
        puts "PALLET: " + record['rw_active_pallet_id'].to_s + " NEEDS re-inspection from grade-change"
        #--------------------------------------------------------------------------------------------------------------
        #Update pallet and all it's cartons: qc_status_code to 'uninspected' and qc_result_status to null +
        #get most recent ppecb_nspection for the pallet and create a copy with cancelled set to true
        #--------------------------------------------------------------------------------------------------------------
        pallet = RwActivePallet.find(record['rw_active_pallet_id'])
        pallet.qc_status_code = 'UNINSPECTED'
        pallet.qc_result_status = nil
        pallet.update
        RwActiveCarton.update_all(ActiveRecord::Base.extend_set_sql_with_request("qc_status_code = 'UNINSPECTED',qc_result_status = null","rw_active_cartons"), "rw_active_pallet_id = #{record['rw_active_pallet_id']} and public.rw_active_cartons.rw_run_id = #{self.id.to_s}")

      end
    else
      puts "NO PALLETS NEED RE-INSPECTION FROM GRADE CHANGES OR NO GRADE CHANGES"
    end

  end


  def complete_bulk_update


  end

  #===========================================================================================
  #This method has to close or complete the current reworks run and 
  #1) create required reworks tables for new cartons and pallets created
  #   in this run (all cartons with reworks_action = 'alt_packed'
  #                    pallets with reworks_action = 'new_pallet'
  #2) create required reclassified cartons or pallets (where reworks action = "reclassified")
  #3) create integration records of following types:
  #   CARTONS:
  #   -> carton_reclassify: for every rw_reclassed_cartons
  #   -> carton_scrap: 1) for every rw_scrap_carton_record
  #                    2) for every rw_receipt_carton that does not exist in rw_active_cartons
  #                       (caused by an alt_pack transaction) 
  #   -> carton_new :for every rw_carton record
  #   -> carton_pallet_ref_update: this involves rw_active cartons that were not
  #                     -> alt_packed or
  #                     -> scrapped
  #                     -> that has been involved in some pallet_building_action
  #                        (rw_pallet_action = "added" or "removed")
  #   PALLETS:
  #   -> pallet_new: for every rw_pallet record
  #   -> pallet_scrap: for every rw_scrap_pallet record
  #===========================================================================================


  def move_bin_asset(asset_item,from_location, to_location, qty_moved, bin_number,run_id)

    #	----------------------
    transaction_type           = TransactionType.find_by_transaction_type_code('move_asset_quantity')
    transaction_business_name  = TransactionBusinessName.find_by_transaction_business_name_code('REWORKS_BIN_RECLASSIFY')

    # inventory_transaction      = InventoryTransaction.new({:transaction_type_code         =>transaction_type.transaction_type_code, :transaction_type_id=>transaction_type.id,
    #                                                        :transaction_business_name_code=>transaction_business_name.transaction_business_name_code, :transaction_business_name_id=>transaction_business_name.id,
    #                                                        :location_from                 =>from_location, :location_to => to_location,:transaction_quantity_plus=>qty_moved,
    #                                                        :transaction_date_time         =>Time.now.to_formatted_s(:db), :reference_number=>bin_number.to_s,
    #                                                        :comments=> run_id.to_s
    #                                                       })


    asset_move_request = AssetMoveRequest.new({:pack_material_product_code=>asset_item,
                                               :transaction_type_code => transaction_type.transaction_type_code,:transaction_type_id => transaction_type.id,
                                               :location_from => from_location,:location_to => to_location,
                                               :transaction_business_name_code => transaction_business_name.transaction_business_name_code,:transaction_business_name_id => transaction_business_name.id,
                                               :reference_number => bin_number.to_s,

                                               :transaction_quantity_plus => qty_moved,:truck_licence_number => "",
                                               :comments => run_id.to_s})


    asset_move_request.save!

     #asset_item                 = AssetItem.find_by_asset_number(asset_item)

     # Inventory::MoveAssetClass.new(asset_item, inventory_transaction).process




  end

  def complete
    required_actions = Array.new

    #work out the build status for each pallet

    begin

      progress_stats = ReworksProgressManager.new(self)
      busy?("complete")

      self.transaction do

        progress_stats.event_generic_action("determining potential qc resets from buildup actions...")
        set_inspection_status_for_built_up_pallets
        progress_stats.event_generic_action("determining potential qc resets from grade reclassifications...")
        set_inspection_status_for_grade_changes
        progress_stats.event_generic_action(nil)

        num_qc_resets = progress_stats.calc_pallets_qc_resets
        progress_stats.run_completion_stats.pallets_qc_resets_req = num_qc_resets

        self.reload #force reload of active cartons, since they were updated from underneath us by previous 2 methods


        self.rw_active_bins.each do |bin|
          if bin.reworks_action.upcase == "RECLASSIFIED"
            progress_stats.event_bin_reclassified

            original_bin = Bin.find(bin.bin_id)
            from_pack_material_product =original_bin.pack_material_product

            #Spec from GF: if asset item (type of bin) has changed (bin.pm_code):
            #  1) reduce the current asset item's aggregate qty at the bin's location  by moving 1 bin to empty 'KROMCO' store
            #  2) increase the new(changed pm) asset items's aggregate qty at the bin's location by 1

            if bin.pack_material_product !=from_pack_material_product
              from_location =  stock_item = StockItem.find_by_inventory_reference(original_bin.bin_number).location_code
              move_bin_asset(from_pack_material_product.pack_material_product_code,from_location,"KROMCO",1,original_bin.bin_number,self.id)
              move_bin_asset(bin.pack_material_product.pack_material_product_code,"KROMCO",from_location,1,original_bin.bin_number,self.id)

            end


          elsif bin.reworks_action.upcase == "TIPPED"
            stock_item =StockItem.find_by_inventory_reference(bin.bin_number)
              if stock_item
                Inventory.move_stock("REWORKS", self.id.to_s, "REWORKS", [bin.bin_number])
                Inventory.remove_stock(nil, "BIN", "REWORKS", self.id.to_s, "REWORKS", [bin.bin_number], "KROMCO")
              end


          elsif bin.reworks_action.upcase == "BULK_TIPPED"
            stock_item =StockItem.find_by_inventory_reference(bin.bin_number)
              if stock_item
                Inventory.move_stock("REWORKS", self.id.to_s, "REWORKS", [bin.bin_number])
                Inventory.remove_stock(nil, "BIN", "REWORKS", self.id.to_s, "REWORKS", [bin.bin_number], "KROMCO")
              end

            progress_stats.event_bin_tipped

          end


          if bin.weight_changed
            progress_stats.event_bin_reclassified
            stock_type =StockItem.find_by_inventory_reference(bin.bin_number).stock_type_code
            if stock_type == "PRESORT" && bin.bin.mix_ps_bin == 'MIX_PS_BIN'
              bin.set_child_weights
            end

          end

          reclassed_bin = RwReclassedBin.new
          bin.export_attributes(reclassed_bin, true)
          reclassed_bin.create

          bin.export_attributes(bin.bin, true)
          bin.bin.update

          #create integration record
          #outbox_record = NewOutboxRecord.new("bin_reclassified",bin.bin)

        end

        deferred_pallet_updates = Array.new #for triggers that depend on carton updates happening first
        self.rw_active_pallets.each do |pallet|
          set_build_status(pallet)
          if pallet.build_up_balance
            new_account = Pallet.set_account(pallet.pallet_number, true, true)
            pallet.account_code = new_account
            pallet.set_oldest_pack_date_time

            if pallet.carton_quantity_actual == 0 && pallet.build_up_balance < 0
              pallet.exit_ref = 'SCRAPPED_FROM_RW_BUILDUP'


            end


          end

          pallet.process_status = "PALLETIZED"
          if pallet.reworks_action.upcase == "NEW_PALLET" && pallet.get_carton_count > 0
            progress_stats.event_pallet_created
            new_pallet = RwPallet.new
            pallet.export_attributes(new_pallet, true, ['is_depot_pallet', 'consignment_note_number'])
            new_pallet.date_time_created = Time.now
            new_pallet.create
            #new mes pallet
            new_mes_pallet = Pallet.new
            pallet.export_attributes(new_mes_pallet, true, ['is_depot_pallet', 'consignment_note_number'])
            new_mes_pallet.rw_create_datetime = Time.now
            new_mes_pallet.create
            pallet.pallet = new_mes_pallet

            pallet.update
            #------------------------------------------------------------------------------------------------
            #update cartons of this pallet to have correct pallet_id- the one just created
            #cartons already have correct pallet_number (it can be created at add time), but
            #pallet_id can only be created at run_complete time, because the new pallet is only created now
            #------------------------------------------------------------------------------------------------
            pallet.rw_active_cartons.each do |ctn|

              ctn.pallet_id = new_mes_pallet.id
              ctn.update

            end


            Inventory.create_stock(nil, "PALLET", nil, nil, "REWORKS", self.id.to_s, "REWORKS", [new_mes_pallet.pallet_number])
          elsif (pallet.reworks_action == "ALT_PACKED"||pallet.build_up_balance) && pallet.reworks_action != "reclassified"
            progress_stats.event_pallet_reclassified if pallet.reworks_action == "ALT_PACKED"
            if pallet.build_up_balance && pallet.build_up_balance != 0
              progress_stats.event_pallet_built_up
            end
            pallet.pallet.qc_status_code = pallet.qc_status_code
            pallet.pallet.qc_result_status = pallet.qc_result_status
            pallet.pallet.carton_quantity_actual = pallet.carton_quantity_actual
            pallet.pallet.cpp = pallet.cpp
            pallet.pallet.account_code   = pallet.account_code
            pallet.pallet.build_status = pallet.build_status
            pallet.pallet.update


            if pallet.reworks_action == "ALT_PACKED"
              progress_stats.event_pallet_reclassified
              pallet.export_attributes(pallet.pallet, true)
              pallet.pallet.update

            end
          elsif pallet.reworks_action == "reclassified"
            progress_stats.event_pallet_reclassified
            pallet.export_attributes(pallet.pallet, true, ['is_depot_pallet', 'consignment_note_number','load_detail_id','exit_ref'])
            reclassed_pallet = RwReclassedPallet.new
            pallet.export_attributes(reclassed_pallet, true, ['is_depot_pallet', 'consignment_note_number','load_detail_id','exit_ref'])
            reclassed_pallet.create
            #pallet.pallet.update   deferred:
            deferred_pallet_updates << pallet
            if pallet.build_up_balance && pallet.build_up_balance != 0
              progress_stats.event_pallet_built_up
            end
            #outbox_record = NewOutboxRecord.new("pallet_update",pallet.pallet)

          end

        end

        #----------------------------------------------------------------------------------------------------------
        #pallets to delete: alt-packed and scrapped pallets- pallets that must be deleted in legacy db
        #----------------------------------------------------------------------------------------------------------
        get_all_deleted_pallets().each do |pallet|
          #create integration record TODO: UNCOMMENT THIS LINE
          progress_stats.event_pallet_scrapped
          pallet.pallet.exit_ref = "scrapped" #TODO: UNCOMMENT THIS LINE
          pallet.pallet.carton_quantity_actual = 0
          pallet.pallet.update
          #outbox_record = NewOutboxRecord.new("pallet_deleted",pallet.pallet)
          stock_item =StockItem.find_by_inventory_reference(pallet.pallet_number)
          if stock_item


            Inventory.remove_stock(nil, "PALLET", "REWORKS", self.id.to_s, "REWORKS", [pallet.pallet_number])


          end
        end
        #---------------------------------------------------------------------------------------------------------------
        #Go through active cartons table: create reworks table records for alt_packed and reclassified
        #records. Records in active cartons table, that have not been reclassed, scrapped (in which case
        # they would not be in active table) or alt-packed, must be checked for pallet reference changes
        # (resulting from 'add_to_pallet' and 'remove_from_pallet' build-up actions). If pallet ref changes took
        # place, integration record must be created for it. Pallet ref changed could also have taken place on cartons
        # involved in reclassification or alt pack, but in this case the pallet ref will be updated anyway
        # as part of the normal integration transaction for such types
        #--------------------------------------------------------------------------------------------------------------
        self.rw_active_cartons.each do |carton|

          raise "CARTON: #{carton.carton_number} HAS NO VALUE FOR TRACK_INDICATOR. <BR> IF YOU CHANGED THE PRODUCTION RUN, MAKE SURE THE RMT_SETUP HAS A A VALUE FOR OUT_TRACK_INDICATOR_CODE"  if !carton.track_indicator_code || carton.track_indicator_code.strip() == ""

          if carton.reworks_action.upcase == "RECLASSIFIED"

            if !carton.rw_active_pallet_id

              required_actions.push(carton.carton_number.to_s)
            else
              reclassed_carton = RwReclassedCarton.new
              progress_stats.event_carton_reclassified
              carton.export_attributes(reclassed_carton, true, ['is_depot_carton', 'intake_header_number'])
              reclassed_carton.date_time_created = Time.now
              reclassed_carton.production_run_id = carton.production_run_id
              reclassed_carton.create
              #update our carton
              #puts "orig carton id: " + carton.carton.id.to_s
              if carton.rw_pallet_action
                carton.export_attributes(carton.carton, true, ['is_depot_carton', 'intake_header_number'])
                progress_stats.event_carton_pallet_ref_changed
              else
                carton.export_attributes(carton.carton, true, ['pallet_id', 'pallet_number', 'is_depot_carton', 'intake_header_number'])
              end

              #puts "RECLASSIFY: CTN NUMBER = " + carton.carton.carton_number.to_s + "; ID = " + carton.carton.id.to_s + " (this num: " + carton.carton_number.to_s + ")"
              carton.carton.update
              puts reclassed_carton.carton_number.to_s
              #create integration record
              #outbox_record = NewOutboxRecord.new("carton_reclassified",reclassed_carton)
            end
          elsif carton.reworks_action.upcase == "ALT_PACKED"||carton.reworks_action.upcase == "ALT_PACKED_FROM_CARTON"
            if !(carton.rw_pallet_action && (carton.rw_pallet_action.upcase == "REMOVED"||carton.rw_pallet_action.upcase == "PALLET_SCRAPPED"))
              new_carton = RwCarton.new
              progress_stats.event_carton_created
              new_carton.date_time_created = Time.now
              carton.export_attributes(new_carton, true)
              new_carton.create

              #create new carton in our system
              new_mes_carton = Carton.new
              new_mes_carton.rw_create_datetime = Time.now
              carton.export_attributes(new_mes_carton, true)
              new_mes_carton.create

              #create integration record
              #outbox_record = NewOutboxRecord.new("rw_carton_new",new_mes_carton)
            end
          elsif carton.rw_pallet_action && (carton.rw_pallet_action.upcase == "ADDED")
            #update mes record
            progress_stats.event_carton_pallet_ref_changed
            carton.carton.pallet = carton.rw_active_pallet.pallet
            carton.carton.pallet_number = carton.rw_active_pallet.pallet_number
            puts "CARTON PALLET ACTION: CTN NUMBER = " + carton.carton.carton_number.to_s + "; ID = " + carton.carton.id.to_s + " (this num: " + carton.carton_number.to_s + ")"

            carton.carton.update

            #create integration record
            #outbox_record = NewOutboxRecord.new("carton_pallet_ref_change",carton.carton)
          elsif carton.rw_pallet_action && (carton.rw_pallet_action.upcase == "REMOVED"||carton.rw_pallet_action.upcase == "PALLET_SCRAPPED")
            #update mes record
            integrate_scrapped_carton(carton)
          end
        end

        #----------------------------------------------------------------------------------------------------------
        #cartons to delete: alt-packed and scrapped cartons- cartons that must be deleted in legacy db
        #----------------------------------------------------------------------------------------------------------
        get_all_deleted_cartons().each do |carton|
          progress_stats.event_carton_scrapped
          integrate_scrapped_carton(carton)
        end

        #update deferred pallet updatres
        deferred_pallet_updates.each do |deferred_plt|
          deferred_plt.pallet.update
        end

        get_all_deleted_rebins().each do |rebin|
          progress_stats.event_bin_scrapped
          rebin.bin.exit_ref = "scrapped"
          rebin.bin.exit_reference_date_time= Time.now
          rebin.bin.update
          stock_item =StockItem.find_by_inventory_reference(rebin.bin_number)
          if stock_item

            Inventory.move_stock("REWORKS", self.id.to_s, "REWORKS", [rebin.bin_number])
            Inventory.remove_stock(nil, "BIN", "REWORKS", self.id.to_s, "REWORKS", [rebin.bin_number], "KROMCO")

          end
        end

        #---------------------------------------------------------------------------
        #Get a list of all pallets where qc_status_code = 'UNINSPECTED'
        #If it's not a new pallet, create a ppecb_inspection_reset integration flow +
        #Create a new ppecb_inspection record, copy of most recent for pallet and
        #set it's cancelled field value to true + date_time_cancelled
        #----------------------------------------------------------------------------
        reset_pallets = RwActivePallet.find_by_sql("select * from rw_active_pallets where rw_run_id = #{self.id.to_s} and UPPER(qc_status_code) = 'UNINSPECTED' AND upper(reworks_action) <> 'NEW_PALLET' AND upper(reworks_action) <> 'ALT_PACKED'")
        reset_pallets.each do |reset_pallet|
          progress_stats.event_pallet_qc_reset
          #NewOutboxRecord.new("pallet_qc_reset",reset_pallet)
          if reset_pallet.carton_quantity_actual > 0
            last_inspection = PpecbInspection.most_recent_inspection?(reset_pallet.rw_active_cartons[0].carton_number)
            if last_inspection
              new_inspection = PpecbInspection.new
              last_inspection.export_attributes(new_inspection, true)
              new_inspection.cancelled_inspection_id = last_inspection.id
              new_inspection.cancelled = true
              new_inspection.create
            end
          end
        end

        update_cartons_pallets       #that is: of pallets that were not recieved explicitly
        update_scrapped_cartons_pallets


        self.rw_active_pallets.reload

        if self.rw_active_pallets && self.rw_active_pallets.length > 0
          pallet_numbers_order_upgrade=self.rw_active_pallets.map{|p|p.pallet_number}
        end

      #update the pallets of cartons that were received as cartons (i.e without pallets) and reclassed


        self.rw_active_cartons.delete_all
        self.rw_active_pallets.delete_all
        self.rw_run_end_datetime = Time.now
        self.rw_run_status_code = "complete"
        self.rw_active_bins.delete_all


        archive_receipt_objects

        self.update

        if required_actions.length > 0
          raise "Some cartons do not have a pallet id. You must scrap these cartons or add them to a pallet to complete the run. They are: <br>" + required_actions.join("<BR>")
        end

        if pallet_numbers_order_upgrade
          Order.get_and_upgrade_prelim_orders(pallet_numbers_order_upgrade)
        end
      end
    rescue
      puts $!.backtrace.join("\n").to_s
      #RAILS_DEFAULT_LOGGER.info ("REWORKS COMPLETION ERROR: " + $!.backtrace.join("\n").to_s)
      err = $!.message
      err = "exception occurred.See error log for details" if !err
      progress_stats.run_completion_stats.error = err
      progress_stats.reset_stats
      raise "Complete run failed: <BR>" + $!

    ensure
      progress_stats.run_completion_stats.done = true
      progress_stats.run_completion_stats.persist
      progress_stats = nil
      done
    end

  end


  #updates pallets of cartons that were received as cartons- i.e. for which no pallets were received
  def update_cartons_pallets
      unreceived_plt_nums = RwActiveCarton.find_by_sql("select distinct pallet_number from rw_active_cartons where updated_at is not null and upper(rw_receipt_unit) = 'CARTON' and rw_run_id = #{self.id}").map{|c|c.pallet_number}

      unreceived_plt_nums.each do |pallet_num|
        pallet = Pallet.find_by_pallet_number(pallet_num)

        #receive pallet
        received_pallet = RwReceiptPallet.new
        pallet.export_attributes(received_pallet,true)
        received_pallet.pallet = pallet
        received_pallet.rw_run = self
        received_pallet.rw_receipt_datetime = Time.now
        received_pallet.create


        #update pallet_id on receipt cartons
        ActiveRecord::Base.connection.execute("update rw_receipt_cartons set rw_receipt_pallet_id = #{received_pallet.id} where pallet_number = '#{pallet_num}'")

        #find most recently updated carton and update pallet from ctn state
        ctn = RwActiveCarton.find_by_sql("select * from rw_active_cartons where pallet_number = '#{pallet_num}' and updated_at is not null order by updated_at desc limit 1")[0]


        #calculate carton_qty,build_status and cpp on pallet
        pallet.carton_quantity_actual = pallet.get_carton_count
        ext_fg = ExtendedFg.find_by_extended_fg_code(ctn.extended_fg_code)
        carton_pack = FgProduct.find_by_fg_product_code(ext_fg.fg_code).carton_pack_product.carton_pack_product_code
        err = pallet.set_build_status(carton_pack)
        if err
          err += " <BR>pallet: #{pallet.pallet_number} <BR> carton: #{ctn.carton_number}"
          raise err
        end

        ctn.update_pallet(pallet,false,false)    #this will also re-calc the account code(inside which method the db update of pallet is done)

        #create active pallet

        active_pallet = RwActivePallet.new
        pallet.export_attributes(active_pallet,true)
        active_pallet.rw_receipt_pallet = received_pallet
        active_pallet.reworks_action = "reclassified"
        active_pallet.rw_run_id = self.id
        active_pallet.create


        #create reclassed pallets
        reclassed_pallet = RwReclassedPallet.new
        pallet.export_attributes(reclassed_pallet, true, ['is_depot_pallet', 'consignment_note_number'])
        reclassed_pallet.rw_run_id = self.id
        reclassed_pallet.create


      end


  end


  def update_scrapped_cartons_pallets
    unreceived_plt_nums = RwScrapCarton.find_by_sql("select distinct pallet_number from rw_scrap_cartons where rw_run_id = #{self.id}").map{|c|c.pallet_number}

    unreceived_plt_nums.each do |pallet_num|
      pallet = Pallet.find_by_pallet_number(pallet_num)
      next if pallet.exit_ref

      #find oldest carton and update pallet from ctn state
      ctns = Carton.find_by_sql("select * from cartons where pallet_number = '#{pallet_num}' and exit_ref is null order by id asc limit 1")
      if ctns.length > 0
        ctn = ctns[0]
        else
         pallet.carton_quantity_actual = 0
         pallet.build_status = "PARTIAL"
         pallet.update
         return
      end


      #calculate carton_qty,build_status and cpp on pallet
      pallet.carton_quantity_actual = pallet.get_carton_count
      ext_fg = ExtendedFg.find_by_extended_fg_code(ctn.extended_fg_code)
      carton_pack = FgProduct.find_by_fg_product_code(ext_fg.fg_code).carton_pack_product.carton_pack_product_code
      err = pallet.set_build_status(carton_pack)
      if err
        err += " <BR>pallet: #{pallet.pallet_number} <BR> carton: #{ctn.carton_number}"
        raise err
      else
        pallet.update
      end



    end




  end



  def carton_of_reworks_pallet?(carton)
    return RwActivePallet.find_by_pallet_number_and_rw_run_id(carton.pallet_number, self.id) != nil

  end

  def integrate_scrapped_carton(carton)
    #update pallet carton qty if carton was not removed from reworks pallet first (in which case qty will be resolved) AND
    #if pallet has not been scrapped
    #Note: any scrappped carton that belonged to a palllet in reworks, would have resulted in a
    #       pallet build-up action
    if !carton_of_reworks_pallet?(carton)
      if !RwScrapPallet.find_by_pallet_number_and_rw_run_id(carton.pallet_number, self.id)
        pallet = Pallet.find_by_pallet_number(carton.pallet_number)
        pallet.update_attribute("carton_quantity_actual", pallet.carton_quantity_actual - 1)
      end

    end

    carton.carton.exit_reference = "scrapped"
    carton.carton.pallet_id = nil
    carton.carton.pallet_number = nil
    carton.carton.exit_date_time = Time.now
    carton.carton.update
    #create integration record
    #outbox_record = NewOutboxRecord.new("carton_deleted",carton.carton)

  end

  def archive_receipt_objects

    cartons_query = "insert into rw_receipt_cartons_histories select * from rw_receipt_cartons where rw_receipt_cartons.rw_run_id = #{self.id.to_s};"
    pallets_query = "insert into rw_receipt_pallets_histories select * from rw_receipt_pallets where rw_receipt_pallets.rw_run_id = #{self.id.to_s};"
    bins_query = "insert into rw_receipt_bins_histories select * from rw_receipt_bins where rw_receipt_bins.rw_run_id = #{self.id.to_s};"

    cartons_delete_query = "delete from rw_receipt_cartons where rw_receipt_cartons.rw_run_id = #{self.id.to_s};"
    pallets_delete_query = "delete from rw_receipt_pallets where rw_receipt_pallets.rw_run_id = #{self.id.to_s};"
    bins_delete_query = "delete from rw_receipt_bins where rw_receipt_bins.rw_run_id = #{self.id.to_s};"

    #archive
    self.connection.execute(cartons_query)
    self.connection.execute(pallets_query)
    self.connection.execute(bins_query)

    #delete
    self.connection.execute(cartons_delete_query)
    self.connection.execute(pallets_delete_query)
    self.connection.execute(bins_delete_query)

  end

  #---------------------------------------------------------------------------------------
  #This method returns all cartons that were alt_packed. Calculation is
  #based on fact that any receipt carton that is alt_packed or scrapped will be deleted
  #in the rw_active_cartons table, but remains in the rw_receipts table
  #---------------------------------------------------------------------------------------
  def get_all_deleted_cartons

    query = "SELECT
            public.rw_receipt_cartons.id,public.rw_receipt_cartons.carton_id,public.rw_receipt_cartons.carton_number,public.rw_receipt_cartons.pallet_number
            FROM
            public.rw_active_cartons
            right outer JOIN public.rw_receipt_cartons ON
           (public.rw_active_cartons.rw_receipt_carton_id = public.rw_receipt_cartons.id)
           where ( public.rw_active_cartons.rw_receipt_carton_id is null AND 
                  public.rw_receipt_cartons.rw_run_id = '#{self.id}')"

    return RwReceiptCarton.find_by_sql(query)

  end


  def get_all_deleted_rebins

    query = "SELECT
            public.rw_receipt_bins.id,public.rw_receipt_bins.bin_id,public.rw_receipt_bins.bin_number
            FROM
            public.rw_active_bins
            right outer JOIN public.rw_receipt_bins ON
           (public.rw_active_bins.rw_receipt_bin_id = public.rw_receipt_bins.id)
           where ( public.rw_active_bins.rw_receipt_bin_id is null AND
                  public.rw_receipt_bins.rw_run_id = '#{self.id}')"

    return RwReceiptBin.find_by_sql(query)

  end

  def get_all_deleted_pallets

    query = "SELECT
            public.rw_receipt_pallets.id,public.rw_receipt_pallets.pallet_number,public.rw_receipt_pallets.pallet_id
            FROM
            public.rw_active_pallets
            right outer JOIN public.rw_receipt_pallets ON
           (public.rw_active_pallets.rw_receipt_pallet_id = public.rw_receipt_pallets.id)
           where ( public.rw_active_pallets.rw_receipt_pallet_id is null AND 
                  public.rw_receipt_pallets.rw_run_id = '#{self.id}')"

    return RwReceiptPallet.find_by_sql(query)

  end


  def validate

    ModelHelper::Validations.validate_combos([{:rw_run_type_code => self.rw_run_type_code}], self)

  end


  def after_create

    self.rw_run_start_datetime = Time.now
    self.rw_run_status_code = "editing"
    self.rw_run_name = "RW_(" + self.rw_run_type_code + ")_" + Time.now.strftime("%d_%b_%Y") + "_" + self.id.to_s
    self.update

  end

  def self.complete_intake_header(header_id)
    header = IntakeHeadersProduction.find(header_id)
    rw_run = RwRun.find(header.rw_run_id)
    rw_run.update_attributes!({:rw_run_status_code=>"complete", :rw_run_end_datetime=>Time.now.to_formatted_s(:db)})

    rw_reclassed_intake_headers_production = RwReclassedIntakeHeadersProduction.new
    header.export_attributes(rw_reclassed_intake_headers_production,true)
    rw_reclassed_intake_headers_production.save

#  header.update_attributes!({:header_status=>header_status}) #???????????????????????

    cartons_query = "insert into rw_reclassed_cartons

  (
     production_run_id ,
  pallet_id ,
  carton_label_station_code ,
  carton_number ,
  erp_station ,
  erp_pack_point ,
  commodity_code ,
  carton_mark_code ,
  target_market_code ,
  variety_short_long ,
  fg_code_old ,
  quarantine ,
  inspection_type_code ,
  carton_label_code ,
  carton_pack_station_code ,
  order_number ,
  pack_date_time ,
  actual_size_count_code ,
  grade_code ,
  old_pack_code ,
  qc_status_code ,
  treatment_code ,
  chemical_status_code ,
  product_class_code ,
  erp_cultivar ,
  track_indicator_code ,
  pc_code ,
  cold_store_code ,
  inventory_code ,
  farm_code ,
  spray_program_code ,
  carton_fruit_nett_mass ,
  quantity ,
  pi ,
  pick_reference ,
  line_code  ,
  shift_code ,
  remarks ,
  organization_code ,
  quality_group_code ,
  iso_week_code ,
  season_code ,
  puc ,
  exit_reference ,
  exit_date_time ,
  pallet_sequence_number ,
  fg_product_code ,
  date_time_created ,
  date_time_erp_xmit ,
  production_run_code ,
  carton_template_id ,
  packer_number ,
  account_code ,
  egap ,
  is_inspection_carton ,
  sell_by_code ,
  qc_datetime_out ,
  qc_datetime_in ,
  rw_run_id ,
  rw_reclassed_datetime ,
  rw_run_completed_datetime ,
  n_labels_printed ,
  items_per_unit ,
  units_per_carton ,
  fg_mark_code ,
  extended_fg_code ,
  unit_pack_product_code ,
  gtin ,
  qc_result_status ,
  ppecb_inspection_id ,
  carton_fruit_nett_mass_actual ,
  pallet_number ,
  mapped_pallet_sequence_id ,
  intake_header_id ,
  is_depot_carton ,
  encrypt_pick_ref ,
  rw_reclassed_intake_headers_production_id,
  created_at,updated_at,created_by,updated_by,affected_by_program,affected_by_function,affected_by_env
  )

  select

    cartons.production_run_id ,
  cartons.pallet_id ,
  cartons.carton_label_station_code ,
  cartons.carton_number ,
  cartons.erp_station ,
  cartons.erp_pack_point ,
  cartons.commodity_code ,
  cartons.carton_mark_code ,
  cartons.target_market_code ,
  cartons.variety_short_long ,
  cartons.fg_code_old ,
  cartons.quarantine ,
  cartons.inspection_type_code ,
  cartons.carton_label_code ,
  cartons.carton_pack_station_code ,
  cartons.order_number ,
  cartons.pack_date_time ,
  cartons.actual_size_count_code ,
  cartons.grade_code ,
  cartons.old_pack_code ,
  cartons.qc_status_code ,
  cartons.treatment_code ,
  cartons.chemical_status_code ,
  cartons.product_class_code ,
  cartons.erp_cultivar ,
  cartons.track_indicator_code ,
  cartons.pc_code ,
  cartons.cold_store_code ,
  cartons.inventory_code ,
  cartons.farm_code ,
  cartons.spray_program_code ,
  cartons.carton_fruit_nett_mass ,
  cartons.quantity ,
  cartons.pi ,
  cartons.pick_reference ,
  cartons.line_code  ,
  cartons.shift_code ,
  cartons.remarks ,
  cartons.organization_code ,
  cartons.quality_group_code ,
  cartons.iso_week_code ,
  cartons.season_code ,
  cartons.puc ,
  cartons.exit_reference ,
  cartons.exit_date_time ,
  cartons.pallet_sequence_number ,
  cartons.fg_product_code ,
  cartons.date_time_created ,
  cartons.date_time_erp_xmit ,
  cartons.production_run_code ,
  cartons.carton_template_id ,
  cartons.packer_number ,
  cartons.account_code ,
  cartons.egap ,
  cartons.is_inspection_carton ,
  cartons.sell_by_code ,
  cartons.qc_datetime_out ,
  cartons.qc_datetime_in ,
  #{rw_run.id} ,
  '#{Time.now.to_formatted_s(:db)}' ,
  NULL ,
  cartons.n_labels_printed ,
  cartons.items_per_unit ,
  cartons.units_per_carton ,
  cartons.fg_mark_code ,
  cartons.extended_fg_code ,
  cartons.unit_pack_product_code ,
  cartons.gtin ,
  cartons.qc_result_status ,
  cartons.ppecb_inspection_id ,
  cartons.carton_fruit_nett_mass_actual ,
  cartons.pallet_number ,
  cartons.mapped_pallet_sequence_id ,
  cartons.intake_header_id ,
  cartons.is_depot_carton ,
  cartons.encrypt_pick_ref ,
  #{rw_reclassed_intake_headers_production.id},
  '#{Time.now.to_formatted_s(:db)}',null,'#{ActiveRequest.get_active_request.user}',null,'#{ActiveRequest.get_active_request.program}','#{ActiveRequest.get_active_request.function}','#{ActiveRequest.get_active_request.env}'

  from cartons JOIN pallets on cartons.pallet_id = pallets.id JOIN rw_reclassed_pallets on cartons.pallet_number = rw_reclassed_pallets.pallet_number where pallets.consignment_note_number = '#{header.consignment_note_number}';"

    pallets_query = "insert into rw_reclassed_pallets

  (
   fg_product_code ,
 build_status ,
 ca_cold_room_code ,
 quarantine ,
 inspection_code ,
 consignment_note_number ,
 final_status_code ,
 pallet_type_code ,
 oldest_pack_date_time ,
 print_status ,
 size_count_code ,
 carton_mark_code ,
 target_market_code ,
 grade_code ,
 marketing_variety_code ,
 old_pack_code ,
 thermocouple ,
 pallet_label_code ,
 qc_status_code ,
 carton_quantity_actual ,
 pi ,
 country_origin_code ,
 inventory_code ,
 pick_reference_code ,
 pc_code ,
 commodity_code ,
 pallet_format_product_code ,
 organization_code ,
 label_standard_code ,
 inspect_type_code ,
 cold_store_type_code ,
 farm_code ,
 erp_cultivar ,
 quality_group_code ,
 class_code ,
 date_time_created ,
 date_time_erp_xmit ,
 pallet_type_id ,
 pallet_format_product_id ,
 pallet_label_setup_id ,
 pallet_template_id ,
 process_status ,
 qc_result_status ,
 actual_size_count_code ,
 cold_store_code ,
 pallet_build_status_id ,
 pallet_process_status_id ,
 pallet_qc_status_id ,
 rw_run_id ,
 rw_reclassed_datetime ,
 rw_run_completed_datetime ,
 reworks_action ,
 pt_product_characteristics ,
 remark ,
 carton_setup_id ,
 production_run_id ,
 ppecb_inspection_id ,
 cpp ,
 pallet_number ,
 load_detail_id ,
 holdover_quantity ,
 holdover ,
 is_new_pallet ,
 pallet_reno_ref ,
 is_mapped ,
 zero_printed_carton_labels ,
 rw_reclassed_intake_headers_production_id,
 created_at,updated_at,created_by,updated_by,affected_by_program,affected_by_function,affected_by_env
)

  select

  fg_product_code ,
 build_status ,
 ca_cold_room_code ,
 quarantine ,
 inspection_code ,
 consignment_note_number ,
 final_status_code ,
 NULL ,
 oldest_pack_date_time ,
 print_status ,
 size_count_code ,
 carton_mark_code ,
 target_market_code ,
 grade_code ,
 marketing_variety_code ,
 old_pack_code ,
 thermocouple ,
 pallet_label_code ,
 qc_status_code ,
 carton_quantity_actual ,
 pi ,
 country_origin_code ,
 inventory_code ,
 pick_reference_code ,
 pc_code ,
 commodity_code ,
 pallet_format_product_code ,
 organization_code ,
 label_standard_code ,
 inspect_type_code ,
 NULL ,
 farm_code ,
 erp_cultivar ,
 quality_group_code ,
 class_code ,
 date_time_created ,
 date_time_erp_xmit ,
 pallet_type_id ,
 pallet_format_product_id ,
 pallet_label_setup_id ,
 pallet_template_id ,
 process_status ,
 qc_result_status ,
 actual_size_count_code ,
 cold_store_code ,
 NULL ,
 NULL ,
 NULL ,
 #{rw_run.id} ,
 '#{Time.now.to_formatted_s(:db)}',
 NULL ,
 'reconfigured' ,
 pt_product_characteristics ,
 remark ,
 carton_setup_id ,
 production_run_id ,
 ppecb_inspection_id ,
 cpp ,
 pallet_number ,
 load_detail_id ,
 holdover_quantity ,
 holdover ,
 is_new_pallet ,
 pallet_reno_ref ,
 is_mapped ,
 zero_printed_carton_labels ,
 #{rw_reclassed_intake_headers_production.id},
 '#{Time.now.to_formatted_s(:db)}',null,'#{ActiveRequest.get_active_request.user}',null,'#{ActiveRequest.get_active_request.program}','#{ActiveRequest.get_active_request.function}','#{ActiveRequest.get_active_request.env}'

  from pallets where pallets.consignment_note_number = '#{header.consignment_note_number}';"

    self.connection.execute(pallets_query)
    self.connection.execute(cartons_query)

    rw_run.rw_active_cartons.delete_all
    rw_run.rw_active_pallets.delete_all



    rw_run.archive_receipt_objects

  end

  def RwRun.receive_intake_header(header, run_type, user)
#  Pallet.transaction do
    rw_run = RwRun.new
    rw_run.username = user
    rw_run.rw_run_status_code = "editing"
    #  rw_run.start_time = Time.now.to_formatted_s(:db)
    if (run_type == "INTAKE_HEADER_MARKED_FOR_DELETION")
      rw_run.rw_run_type_code = "INTAKE_HEADER_MARKED_FOR_DELETION"

      #    header.update_attributes!({:revision_number=>99,:header_status=>"INTAKE_HEADER_MARKED_FOR_DELETION"})
      revision_number = 99
      header_status = "INTAKE_HEADER_MARKED_FOR_DELETION"
    elsif (run_type == "INTAKE_HEADER_RECONFIGURING")
      rw_run.rw_run_type_code = "INTAKE_HEADER_RECONFIGURING"

      #    header.update_attributes!({:revision_number=>header.revision_number + 1,:header_status=>"INTAKE_HEADER_RECONFIGURING"})
      revision_number = header.revision_number + 1
      header_status = "INTAKE_HEADER_RECONFIGURING"
    end
    rw_run.save
    header.update_attributes!({:rw_run_id=>rw_run.id, :revision_number=>revision_number, :header_status=>header_status})

    rw_receipt_intake = RwReceiptIntakeHeadersProduction.new
    header.export_attributes(rw_receipt_intake,true)
    rw_receipt_intake.save

    cartons_query = "insert into rw_receipt_cartons

    (
    rw_receipt_intake_headers_production_id,
    production_run_id ,
    pallet_id ,
    carton_label_station_code ,
    carton_number ,
    erp_station ,
    erp_pack_point ,
    commodity_code ,
    carton_mark_code ,
    target_market_code ,
    variety_short_long ,
    fg_code_old ,
    quarantine ,
    inspection_type_code ,
    carton_label_code ,
    carton_pack_station_code ,
    order_number ,
    pack_date_time ,
    actual_size_count_code ,
    grade_code ,
    old_pack_code ,
    qc_status_code ,
    treatment_code ,
    chemical_status_code ,
    product_class_code ,
    erp_cultivar ,
    track_indicator_code ,
    pc_code ,
    cold_store_code ,
    inventory_code ,
    farm_code ,
    spray_program_code ,
    carton_fruit_nett_mass ,
    quantity ,
    pi ,
    pick_reference ,
    line_code ,
    shift_code ,
    remarks ,
    organization_code ,
    quality_group_code ,
    iso_week_code ,
    season_code ,
    puc ,
    exit_reference ,
    exit_date_time ,
    pallet_sequence_number ,
    fg_product_code ,
    date_time_created ,
    date_time_erp_xmit ,
    production_run_code ,
    carton_template_id ,
    packer_number ,
    account_code ,
    egap ,
    is_inspection_carton ,
    sell_by_code ,
    qc_datetime_out ,
    qc_datetime_in ,
    rw_run_id ,
    carton_id ,
    rw_receipt_datetime ,
    rw_run_complete_datetime ,
    rw_receipt_pallet_id ,
    reworks_action ,
    rw_pallet_action ,
    rw_receipt_unit ,
    alt_packed_datetime ,
    n_labels_printed ,
    items_per_unit ,
    units_per_carton ,
    fg_mark_code ,
    extended_fg_code ,
    unit_pack_product_code ,
    gtin ,
    qc_result_status ,
    ppecb_inspection_id ,
    carton_fruit_nett_mass_actual ,
    pallet_number ,
    mapped_pallet_sequence_id ,
    intake_header_id ,
    is_depot_carton ,
    intake_header_number ,
    encrypt_pick_ref,
    created_at,updated_at,created_by,updated_by,affected_by_program,affected_by_function,affected_by_env
    )

    select

    #{rw_receipt_intake.id.to_s} ,
    cartons.production_run_id ,
    cartons.pallet_id ,
    cartons.carton_label_station_code ,
    cartons.carton_number ,
    cartons.erp_station ,
    cartons.erp_pack_point ,
    cartons.commodity_code ,
    cartons.carton_mark_code ,
    cartons.target_market_code ,
    cartons.variety_short_long ,
    cartons.fg_code_old ,
    cartons.quarantine ,
    cartons.inspection_type_code ,
    cartons.carton_label_code ,
    cartons.carton_pack_station_code ,
    cartons.order_number ,
    cartons.pack_date_time ,
    cartons.actual_size_count_code ,
    cartons.grade_code ,
    cartons.old_pack_code ,
    cartons.qc_status_code ,
    cartons.treatment_code ,
    cartons.chemical_status_code ,
    cartons.product_class_code ,
    cartons.erp_cultivar ,
    cartons.track_indicator_code ,
    cartons.pc_code ,
    cartons.cold_store_code ,
    cartons.inventory_code ,
    cartons.farm_code ,
    cartons.spray_program_code ,
    cartons.carton_fruit_nett_mass ,
    cartons.quantity ,
    cartons.pi ,
    cartons.pick_reference ,
    cartons.line_code ,
    cartons.shift_code ,
    cartons.remarks ,
    cartons.organization_code ,
    cartons.quality_group_code ,
    cartons.iso_week_code ,
    cartons.season_code ,
    cartons.puc ,
    cartons.exit_reference ,
    cartons.exit_date_time ,
    cartons.pallet_sequence_number ,
    cartons.fg_product_code ,
    cartons.date_time_created ,
    cartons.date_time_erp_xmit ,
    cartons.production_run_code ,
    cartons.carton_template_id ,
    cartons.packer_number ,
    cartons.account_code ,
    cartons.egap ,
    cartons.is_inspection_carton ,
    cartons.sell_by_code ,
    cartons.qc_datetime_out ,
    cartons.qc_datetime_in ,
    #{rw_run.id.to_s} ,
    cartons.id as carton_id ,
    '#{Time.now.to_formatted_s(:db)}' ,
    NULL ,
    rw_receipt_pallets.id ,
    'received',
    NULL ,
    cartons.rw_receipt_unit ,
    NULL ,
    cartons.n_labels_printed ,
    cartons.items_per_unit ,
    cartons.units_per_carton ,
    cartons.fg_mark_code ,
    cartons.extended_fg_code ,
    cartons.unit_pack_product_code ,
    cartons.gtin ,
    cartons.qc_result_status ,
    cartons.ppecb_inspection_id ,
    cartons.carton_fruit_nett_mass_actual ,
    cartons.pallet_number ,
    cartons.mapped_pallet_sequence_id ,
    cartons.intake_header_id ,
    cartons.is_depot_carton ,
    cartons.intake_header_number ,
    cartons.encrypt_pick_ref,
    '#{Time.now.to_formatted_s(:db)}',null,'#{ActiveRequest.get_active_request.user}',null,'#{ActiveRequest.get_active_request.program}','#{ActiveRequest.get_active_request.function}','#{ActiveRequest.get_active_request.env}'

    from cartons JOIN pallets on cartons.pallet_id = pallets.id JOIN rw_receipt_pallets on cartons.pallet_number=rw_receipt_pallets.pallet_number where pallets.consignment_note_number = '#{header.consignment_note_number}';"

    pallets_query = "insert into rw_receipt_pallets

    (
    rw_receipt_intake_headers_production_id ,
    fg_product_code ,
    build_status ,
    ca_cold_room_code ,
    quarantine ,
    inspection_code ,
    consignment_note_number ,
    final_status_code ,
    pallet_type_code ,
    oldest_pack_date_time ,
    print_status ,
    size_count_code ,
    carton_mark_code ,
    target_market_code ,
    grade_code ,
    marketing_variety_code ,
    old_pack_code ,
    thermocouple ,
    pallet_label_code ,
    qc_status_code ,
    carton_quantity_actual ,
    pi ,
    country_origin_code ,
    inventory_code ,
    pick_reference_code ,
    pc_code ,
    commodity_code ,
    pallet_format_product_code ,
    organization_code ,
    label_standard_code ,
    inspect_type_code ,
    cold_store_type_code ,
    farm_code ,
    erp_cultivar ,
    quality_group_code ,
    class_code ,
    date_time_created ,
    date_time_erp_xmit ,
    pallet_type_id ,
    pallet_format_product_id ,
    pallet_label_setup_id ,
    pallet_template_id ,
    process_status ,
    qc_result_status ,
    actual_size_count_code ,
    cold_store_code ,
    pallet_build_status_id ,
    pallet_process_status_id ,
    pallet_qc_status_id ,
    date_time_completed ,
    rw_run_id ,
    pallet_id ,
    rw_receipt_datetime ,
    rw_run_complete_datetime ,
    rw_build_pallet_id ,
    alt_packed_datetime ,
    alt_packed_destroyed_datetime ,
    pt_product_characteristics ,
    remark ,
    carton_setup_id ,
    production_run_id ,
    fg_code_old ,
    ppecb_inspection_id ,
    cpp ,
    pallet_number ,
    load_detail_id ,
    holdover_quantity ,
    holdover ,
    is_new_pallet ,
    pallet_reno_ref ,
    is_mapped ,
    zero_printed_carton_labels,
     created_at,updated_at,created_by,updated_by,affected_by_program,affected_by_function,affected_by_env
  )

    select

    #{rw_receipt_intake.id.to_s},
    fg_product_code ,
    build_status ,
    ca_cold_room_code ,
    quarantine ,
    inspection_code ,
    consignment_note_number ,
    final_status_code ,
    NULL ,
    oldest_pack_date_time ,
    print_status ,
    size_count_code ,
    carton_mark_code ,
    target_market_code ,
    grade_code ,
    marketing_variety_code ,
    old_pack_code ,
    thermocouple ,
    pallet_label_code ,
    qc_status_code ,
    carton_quantity_actual ,
    pi ,
    country_origin_code ,
    inventory_code ,
    pick_reference_code ,
    pc_code ,
    commodity_code ,
    pallet_format_product_code ,
    organization_code ,
    label_standard_code ,
    inspect_type_code ,
    NULL ,
    farm_code ,
    erp_cultivar ,
    quality_group_code ,
    class_code ,
    date_time_created ,
    date_time_erp_xmit ,
    pallet_type_id ,
    pallet_format_product_id ,
    pallet_label_setup_id ,
    pallet_template_id ,
    process_status ,
    qc_result_status ,
    actual_size_count_code ,
    cold_store_code ,
    NULL ,
    NULL ,
    NULL ,
    date_time_completed ,
    #{rw_run.id.to_s},
    id as pallet_id,
    '#{Time.now.to_formatted_s(:db)}' ,
    NULL ,
    NULL ,
    NULL ,
    NULL ,
    pt_product_characteristics ,
    remark ,
    carton_setup_id ,
    production_run_id ,
    fg_code_old ,
    ppecb_inspection_id ,
    cpp ,
    pallet_number ,
    load_detail_id ,
    holdover_quantity ,
    holdover ,
    is_new_pallet ,
    pallet_reno_ref ,
    is_mapped ,
    zero_printed_carton_labels,
    '#{Time.now.to_formatted_s(:db)}',null,'#{ActiveRequest.get_active_request.user}',null,'#{ActiveRequest.get_active_request.program}','#{ActiveRequest.get_active_request.function}','#{ActiveRequest.get_active_request.env}'

    from pallets where pallets.consignment_note_number = '#{header.consignment_note_number}';"

    self.connection.execute(pallets_query)
    self.connection.execute(cartons_query)
#  end

  end
end
