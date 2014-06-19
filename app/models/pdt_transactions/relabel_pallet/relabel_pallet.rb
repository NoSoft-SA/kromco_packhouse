class RelabelPallet < PrintPalletLabelBase
  def build_default_screen
    screen_definition = super
    temp = PdtScreenDefinition.new(screen_definition,nil,PdtScreenDefinition.const_get("ENTERDATA"),nil,nil)
    temp.buttons["B1Submit"] = "relabel_pallet_submit"
    temp.screen_attributes["current_menu_item"] = "1.7.6"
    result_screen = temp.get_output_xml()
    return result_screen
  end

  def relabel_pallet
    build_default_screen
  end

  def relabel_pallet_submit
    begin
      ActiveRecord::Base.transaction do
        if((error = validate_input) == "")#Base class
          scanned_pallet = Pallet.find_by_pallet_number(@pallet_number)
          new_pallet = Pallet.new()
          scanned_pallet.export_attributes(new_pallet)
          gen_pallet_num = MesControlFile.next_seq(3)[0]
          new_pallet.pallet_number  = (gen_pallet_num.to_s + RwActivePallet.calc_check_digit(gen_pallet_num.to_s))
          puts "ISERTING --------- " + new_pallet.pallet_number.to_s
          new_pallet.create

#          scanned_pallet.pallet_reno_ref = new_pallet.pallet_number
#          scanned_pallet.exit_ref = 're_labeled'
          scanned_pallet.update_attributes({:pallet_reno_ref=>new_pallet.pallet_number,:exit_ref=>'re_labeled'})
          
          Carton.update_all(ActiveRecord::Base.extend_set_sql_with_request("pallet_number='#{new_pallet.pallet_number.to_s}',pallet_id=#{new_pallet.id}","cartons"), "pallet_number='#{@pallet_number.to_s}'")
#          scanned_pallet.cartons.each do |carton|
#            #carton.update_attributes({:pallet_number=>new_pallet.pallet_number,:pallet_id=>new_pallet.id})
#          end

        else
         result_screen = PDTTransaction.build_msg_screen_definition(error,nil,nil,nil)
          return result_screen
        end

        stock_item = StockItem.find_by_inventory_reference(scanned_pallet.pallet_number)
        stock_item.inventory_reference = new_pallet.pallet_number
        inventory_transaction = InventoryTransaction.new
        inventory_transaction.reference_number = "relabel_pallet_submit"
        inventory_transaction.transaction_date_time = Time.now.to_formatted_s(:db)
          transaction_type = TransactionType.find_by_transaction_type_code("update_stock")
        inventory_transaction.transaction_type_code = transaction_type.transaction_type_code
        inventory_transaction.transaction_type_id = transaction_type.id
        transaction_business_name = TransactionBusinessName.find_by_transaction_business_name_code("relabel_pallet")
         if transaction_business_name
           inventory_transaction.transaction_business_name_id = transaction_business_name.id
           inventory_transaction.transaction_business_name_code = transaction_business_name.transaction_business_name_code
         end
         Inventory::UpdateStock.new(inventory_transaction,stock_item).process
         @pallet_number = new_pallet.pallet_number
         print_pallet_label_trans()
         self.set_transaction_complete_flag
         result_screen = PDTTransaction.build_msg_screen_definition("have a nice",nil,nil,["pallet relabeled successfully","new pallet number :",@pallet_number])
         return result_screen
      end
    rescue
      puts $!.to_s
      puts "BLEW UP = " + $!.backtrace.join("\n").to_s
      error = ["Unexpected exception:","pallet could not be relabelled"]
      result_screen = PDTTransaction.build_msg_screen_definition("y = " + @pallet_number.to_s,nil,nil,error)
      return result_screen
    end
  end

end