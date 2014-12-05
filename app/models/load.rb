class Load < ActiveRecord::Base

#	===========================
# 	Association declarations:
#	===========================

  belongs_to :load_type

  has_many :load_orders, :dependent => :destroy
  has_many :load_vehicles, :dependent => :destroy
  has_many :load_containers, :dependent => :destroy
  has_many :load_voyages, :dependent => :destroy
  has_many :load_details, :dependent => :destroy
  has_many :load_status_histories, :dependent => :destroy

#	============================
#	 Validations declarations:
#	============================
  validates_presence_of :load_number
#	validates_numericality_of :dispatch_consignment_number
  validates_numericality_of :load_number
#------------------------------------------------12/09/2012--------------------------------------------------------------------------------
  def import_pallets(pallet_numberz,container=nil)
    pallet_numbers=[]
    pallet_numberz.each_key {
        |key| pallet_numbers << key.strip }

    ActiveRecord::Base.transaction do

      order_type=OrderType.find_by_sql("select order_types.order_type_code
                                         from order_types
                                         inner join orders on orders.order_type_id=order_types.id
                                         inner join load_orders on load_orders.order_id=orders.id
                                         inner join loads on load_orders.load_id=loads.id
                                       where load_orders.load_id=#{self.id}")[0].order_type_code
      if order_type.strip=="MO" || order_type.strip=="MQ"
        #count(public.cartons.id) AS carton_count
        query ="SELECT count(public.cartons.id) AS carton_count,public.cartons.carton_fruit_nett_mass AS carton_weight,pallets.carton_quantity_actual,
                  pallets.id,cartons.pallet_number,pallets.build_status,pallets.load_detail_id,item_pack_products.commodity_code,
                  item_pack_products.marketing_variety_code,cartons.target_market_code,item_pack_products.grade_code,cartons.inventory_code,
                  cartons.puc,cartons.iso_week_code,cartons.season_code,cartons.inspection_type_code,cartons.pick_reference,
                  pallets.pallet_format_product_code,cartons.pc_code,extended_fgs.old_fg_code,item_pack_products.actual_count,
                  item_pack_products.size_ref,extended_fgs.extended_fg_code,public.item_pack_products.item_pack_product_code
                  FROM public.cartons
                  INNER JOIN public.extended_fgs ON (public.cartons.extended_fg_code=public.extended_fgs.extended_fg_code)
                  INNER JOIN public.fg_products ON (public.fg_products.fg_product_code=public.extended_fgs.fg_code)
                  INNER JOIN public.item_pack_products ON (public.fg_products.item_pack_product_id=public.item_pack_products.id)
                  INNER JOIN public.pallets ON (public.cartons.pallet_id=public.pallets.id)
                  where(cartons.pallet_number= cartons.pallet_number) and pallets.load_detail_id is null
                  GROUP BY public.cartons.pallet_number,pallets.build_status,item_pack_products.commodity_code,
                  item_pack_products.marketing_variety_code,cartons.target_market_code,item_pack_products.grade_code,
                  cartons.inventory_code,cartons.puc,cartons.iso_week_code,cartons.season_code,cartons.inspection_type_code,
                  cartons.pick_reference,pallets.pallet_format_product_code,cartons.pc_code,extended_fgs.old_fg_code,
                  item_pack_products.actual_count,item_pack_products.size_ref,extended_fgs.extended_fg_code, pallets.load_detail_id,
                 pallets.id, public.item_pack_products.item_pack_product_code,public.cartons.carton_fruit_nett_mass,pallets.carton_quantity_actual "
      else
        #count(public.cartons.id) AS carton_count
        query ="SELECT count(public.cartons.id) AS carton_count,public.cartons.carton_fruit_nett_mass AS carton_weight,pallets.carton_quantity_actual ,
                  pallets.id,cartons.pallet_number,pallets.build_status,pallets.load_detail_id,item_pack_products.commodity_code,
                  item_pack_products.marketing_variety_code,cartons.target_market_code,item_pack_products.grade_code,cartons.inventory_code,
                  cartons.puc,cartons.iso_week_code,cartons.season_code,cartons.inspection_type_code,cartons.pick_reference,
                  pallets.pallet_format_product_code,cartons.pc_code,extended_fgs.old_fg_code,item_pack_products.actual_count,
                  item_pack_products.size_ref,extended_fgs.extended_fg_code,public.item_pack_products.item_pack_product_code
                  FROM public.cartons
                  INNER JOIN public.extended_fgs ON (public.cartons.extended_fg_code=public.extended_fgs.extended_fg_code)
                  INNER JOIN public.fg_products ON (public.fg_products.fg_product_code=public.extended_fgs.fg_code)
                  INNER JOIN public.item_pack_products ON (public.fg_products.item_pack_product_id=public.item_pack_products.id)
                  INNER JOIN public.pallets ON (public.cartons.pallet_id=public.pallets.id)
                  INNER JOIN public.stock_items ON (public.pallets.pallet_number=public.stock_items.inventory_reference)
                  where(cartons.pallet_number= cartons.pallet_number)and pallets.consignment_note_number is not null and pallets.load_detail_id is null
                  GROUP BY public.cartons.pallet_number,pallets.build_status,item_pack_products.commodity_code,
                  item_pack_products.marketing_variety_code,cartons.target_market_code,item_pack_products.grade_code,
                  cartons.inventory_code,cartons.puc,cartons.iso_week_code,cartons.season_code,cartons.inspection_type_code,
                  cartons.pick_reference,pallets.pallet_format_product_code,cartons.pc_code,extended_fgs.old_fg_code,
                  item_pack_products.actual_count,item_pack_products.size_ref,extended_fgs.extended_fg_code, pallets.load_detail_id,
                 pallets.id, public.item_pack_products.item_pack_product_code,public.cartons.carton_fruit_nett_mass,pallets.carton_quantity_actual "
      end
      str_sql = Carton.get_by_pallet_numbers(query, pallet_numbers)
      pallets = Pallet.connection.select_all("#{str_sql}")
      returned_pallets=pallets.map { |k| k['pallet_number'] }
      invalid_pallets=[]
      error=[]
      if pallets.length != pallet_numbers.length
        if pallets.empty?
          invalid_pallets = pallet_numbers
        else
          for num in pallet_numbers
            invalid_pallets << num if !returned_pallets.include?(num)
          end
        end

        invalid_palletsi=invalid_pallets.join(",")

        raise "Error: These pallets are invalid! #{invalid_palletsi} ,QUERY IS:" + str_sql if !invalid_pallets.empty?
      end
      raise "Error: No valid pallets found!. QUERY IS:" + str_sql if pallets.length == 0
      puts "PALLET NUMBERS-ORDER:<BR> #{pallet_numbers.join("<BR>")}"
      puts "pseudo_pallets-ORDER:<BR> " + "#{pallets.length()}"
      reverse_engineer_order(pallets, pallet_numberz,container)
    end

  end

  def calc_order_product_sequence_number(order)
    max_sequence =OrderProduct.find_by_sql("SELECT MAX(sequence_number) FROM order_products where order_id = #{order.id.to_s} ")
    max_sequence = max_sequence[0].attributes['max']
    max_sequence = max_sequence.to_i
    if  max_sequence == nil
      next_sequence = 1
      return next_sequence
    else
      next_sequence = max_sequence + 1
      return next_sequence
    end

  end


  def reverse_engineer_order(pseudo_pallets, remarks,container=nil)
    ActiveRecord::Base.transaction do
      load_order = LoadOrder.find_by_load_id(self.id)
      order=Order.find(load_order.order_id)
      #------------------------------------------------------------------------
      #update the {order_quantity} field value of the [order] record to the sum of {carton_count} field of passed-in
      #pseudo_pallets
      #------------------------------------------------------------------------
      required_quantity =0
      for pallet in pseudo_pallets
        required_quantity = required_quantity + pallet['carton_quantity_actual'].to_i
      end
      self.update_attribute(:required_quantity, "#{required_quantity}")


      #--------------------------------------------------------------------------------------
      # for each item_pack_product group in grouped list created
      #  calculate and set value for {subtotal} field as follows:
      # {required_qty} * pseudo_pallet.price_per_kg * pseudo_pallet.carton_weight}
      #(use values any pseudo_pallet in current group)
      #-------------------------------------------------------------------------------------
      item_pack_product_groups =pseudo_pallets.group(['item_pack_product_code','old_fg_code'], nil, true)
      extended_fg_group_sub_totals = 0
      order_plt_nums=[]
      for item_pack_product_group in item_pack_product_groups
        group_required_quantity = 0
        carton_count=0
        price_per_kg=nil
        price_per_carton=nil
        subtotal=0
        for pseudo_pallet in item_pack_product_group
          group_required_quantity += pseudo_pallet['carton_quantity_actual'].to_i
          carton_count +=pseudo_pallet['carton_count'].to_i
        end
        #--------------------------------------------------------------------------------------------
        #break down the item_pack_product_code into fields that exit on [order_product]
        #--------------------------------------------------------------------------------------------
        #existing_order_product=OrderProduct.find_by_item_pack_product_code_and_order_id(item_pack_product_group[0]['item_pack_product_code'],order.order_id)
        existing_order_product=OrderProduct.find_by_sql("select * from order_products where (item_pack_product_code='#{item_pack_product_group[0]['item_pack_product_code']}' and old_fg_code='#{item_pack_product_group[0]['old_fg_code']}' and order_id=#{order.id})")
        if existing_order_product.empty?
          order_product = OrderProduct.new
          order_product.order_id = order.id
          order_product.save

          pseudo_pallet_attributes =item_pack_product_group[0]

          for pseudo_pallet_attribute in pseudo_pallet_attributes

            if  order_product.attributes.has_key?("#{pseudo_pallet_attribute[0]}") && pseudo_pallet_attribute[0] != 'id' && !pseudo_pallet_attribute[0].upcase.index("PRICE") && pseudo_pallet_attribute[0]!='price_per_kg' && pseudo_pallet_attribute[0]!='carton_weight'
              order_product.update_attribute(:"#{pseudo_pallet_attribute[0]}", "#{pseudo_pallet_attribute[1]}")
            end

          end
          item_pack_code =pseudo_pallet_attributes['item_pack_product_code']
          item_pack_product = item_pack_code.split(/_/)
          item_pack_product_hash = Hash.new
          item_pack_product_hash = {"commodity_code" => "#{item_pack_product[0]}",
                                    "marketing_variety_code" => "#{item_pack_product[1]}",
                                    "product_class_code" => "#{item_pack_product[2]}",
                                    "grade_code" => "#{item_pack_product[3]}",
                                    "actual_count" => "#{item_pack_product[4]}",
                                    "basic_pack_code" => "#{item_pack_product[5]}",
                                    "cosmetic_code_name" => "#{item_pack_product[6]}",
                                    "size_ref" => "#{item_pack_product[7]}"
          }
          sequence_number = self.calc_order_product_sequence_number(order)
          order_product['commodity_code'] = item_pack_product_hash["commodity_code"]
          order_product['marketing_variety_code']= item_pack_product_hash["marketing_variety_code"]
          order_product['product_class_code'] = item_pack_product_hash["product_class_code"]
          order_product['grade_code'] = item_pack_product_hash["grade_code"]
          order_product['actual_count'] = item_pack_product_hash["actual_count"]
          order_product['basic_pack_code'] = item_pack_product_hash["basic_pack_code"]
          order_product['cosmetic_code_name'] = item_pack_product_hash["cosmetic_code_name"]
          order_product['size_ref'] = item_pack_product_hash["size_ref"]
          order_product['order_number'] = self.attributes['order_number']

          latest_shipped_similar_order_product=OrderProduct.find_by_sql("select op.* from order_products op
            join orders o on op.order_id=o.id
            where op.item_pack_product_code='#{order_product.item_pack_product_code}' and op.old_fg_code='#{order_product.old_fg_code}'  and o.consignee_party_role_id=#{order.consignee_party_role_id}
            and o.order_status='SHIPPED' order by o.id desc")[0]

          if latest_shipped_similar_order_product
            price_per_kg=latest_shipped_similar_order_product.price_per_kg
            price_per_carton=latest_shipped_similar_order_product.price_per_carton
            subtotal =  price_per_carton * carton_count   if  price_per_carton
          end
          order_product.update_attributes(:price_per_kg=>price_per_kg ,:price_per_carton=>price_per_carton,:required_quantity=>carton_count, :carton_count=>carton_count,:subtotal=> subtotal,
                                          :available_quantities=> carton_count,:sequence_number=>sequence_number)

        else
          order_product=existing_order_product[0]
          latest_shipped_similar_order_product=OrderProduct.find_by_sql("select op.* from order_products op
            join orders o on op.order_id=o.id
            where op.item_pack_product_code='#{order_product.item_pack_product_code}' and op.old_fg_code='#{order_product.old_fg_code}'  and o.consignee_party_role_id=#{order.consignee_party_role_id}
            and o.order_status='SHIPPED' order by o.id desc ")[0]
          carton_count = order_product.carton_count + carton_count
          if latest_shipped_similar_order_product
            price_per_kg=latest_shipped_similar_order_product.price_per_kg
            price_per_carton=latest_shipped_similar_order_product.price_per_carton
            subtotal =  price_per_carton * carton_count   if  price_per_carton
          end

          order_product.update_attributes(:price_per_kg=>price_per_kg ,:price_per_carton=>price_per_carton,:required_quantity=>carton_count, :carton_count=>carton_count,:subtotal=> subtotal,
                                          :available_quantities=> carton_count,:sequence_number=>sequence_number)
        end
        order_product_attributes =order_product.attributes
        load_detail = LoadDetail.new
        load_detail.order_id = order.id
        load_detail.load_id = self.id
        load_detail.load_order_id =load_order.id
        load_detail.order_product_id=order_product.id
        load_detail.save
        for attr in order_product_attributes

          if load_detail.attributes.has_key?("#{attr[0]}")
            if attr[0]!= 'id' && attr[0]!=order.id
              load_detail.update_attribute(:"#{attr[0]}", "#{attr[1]}")
            end
          end

        end

        pallet_numbers = Array.new
        load_detail_id = load_detail.id
        plt_remarks={}
        for pseud_pallet in item_pack_product_group
          plt_remarks={}
          order_plt_nums << pseud_pallet['pallet_number']
          remark=remarks[pseud_pallet['pallet_number']]
          marks =remark.split(",")
          if container
            marks.delete_at(1)
          end

          updates=[]
          j=0
          for mrk in marks
            updates << "remarks#{j} =" + "'#{mrk}'" if j!=0
            j = j+ 1
          end
          updates << "load_detail_id =" + load_detail_id.to_s
          updates=updates.join(",")
          plt_remarks[marks[0]]=updates
          pallet_numbers << marks[0]
          for plt in plt_remarks
            self.connection.execute("update pallets set #{plt[1]} where (pallet_number='#{plt[0].strip}') ")
            puts "=========load_detail_id: #{load_detail_id}====#{plt[0]} ========"
          end

        end

        sub_total= load_detail.subtotal?
        #actual_quantity = load_detail.set_actual_carton_count
        holdover_quantity = load_detail.set_holdover_quantity
        #load_detail.update_attributes!({:actual_quantity => actual_quantity,
        #                                :holdover_quantity => holdover_quantity,
        #                                :required_quantity => actual_quantity,
        #                                :available_quantities => actual_quantity
        #                               })

      end

      #-----------------------------------------------------------------------------------------------------------------
      #calculate and update the {total} field of [load] record, by calling load.total? ( It is the sum of all {subtotal}
      # field values of the [load_details] belonging to this load)
      #------------------------------------------------------------------------------------------------------------------
      actual_quantity = self.actual_quantity
      required_quantity = self.required_quantity
      total = self.total?
      self.update_attributes!({:actual_quantity => actual_quantity,
                               :required_quantity => required_quantity,
                               :total => total
                              })

      Order.get_and_upgrade_prelim_orders(order_plt_nums)
    end

  end

  def calc_order_product_sequence_number(order)
    max_sequence =OrderProduct.find_by_sql("SELECT MAX(sequence_number) FROM order_products where order_id = #{order.id.to_s} ")
    max_sequence = max_sequence[0].attributes['max']
    max_sequence = max_sequence.to_i
    if  max_sequence == nil
      next_sequence = 1
      return next_sequence
    else
      next_sequence = max_sequence + 1
      return next_sequence
    end

  end

  def get_by_pallet_numbers(from_clause, where_or_clause, closing_clause)
    str_sql = from_clause + "where" +"(" + where_or_clause + ")" + closing_clause
    extended_fgs_prices = Carton.find_by_sql("#{str_sql}")
    group_sub_total = 0
    for pallet in extended_fgs_prices
      group_sub_total = group_sub_total + pallet['sum_price_of_extended_fg_code']
    end
    return group_sub_total
  end

#------------------------------------------------------------------------------------------------------------------------------------------

  def complete_load
    Order.transaction do
      order_id = LoadOrder.find_by_sql("SELECT order_id from load_orders WHERE load_id = '#{self.id}'")
      order_id = order_id[0].attributes['order_id']
      @order= Order.find("#{order_id}")
      @order_customer_detail = OrderCustomerDetail.find_by_order_id("#{@order.id}")


      load_details = LoadDetail.find_by_sql("SELECT * FROM load_details WHERE load_id ='#{self.id}' ")
      if for load_detail in load_details
           if load_detail.attributes['holdover_quantity'] > 0
             load_detail_id = load_detail.attributes['id'].to_i
             pallet_numbers = Pallet.find_by_sql("select pallet_number from pallets where load_detail_id = '#{load_detail_id}'")
             pallet_numbers_array = Array.new
             for pallet in pallet_numbers
               pallet_numbers_array << pallet.attributes['pallet_number']
             end
             pallet_numbers_ = pallet_numbers_array.join(",").to_s
             message1 = " load could not be completed ,load detail" + " " + "#{load_detail_id}" + " " + "has positive hold_over_quantity on pallets" + "#{pallet_numbers}"

           end
      end
      end

      if message1 != nil
        return message1
      end


      result = @order.do_credit_check()
      if result = "PASSED" || "AUTHORISED"
        @order_customer_detail.update_attribute(:customer_credit_rating, "#{result}")
        credit_rating_timestamp = Time.now
        @order_customer_detail.update_attribute(:customer_credit_rating_timestamp, "#{ credit_rating_timestamp}")
      else
        @order_customer_detail.update_attribute(:customer_credit_rating, "#{result}")
        #flash[:notice]= "CANNOT COMPLETE ORDER:CREDIT CHECK RETURNED"+ "#{result}"
      end

      self.set_status("COMPLETED")


      if self.load_status == "COMPLETED"
        message = "COMPLETED"
        return message
      end

    end

  end

  def set_status(new_status)
    @load_status_history = LoadStatusHistory.new
    @load_status_history.load_id = self.id
    @load_status_history.load_status = new_status
    @load_status_history.save
    self.load_status = new_status
    self.update
  end


  def total?
    load_id = self.id.to_i
    total = Load.find_by_sql("SELECT SUM(sub_total) AS OrderTotal FROM load_details where load_id ='#{load_id}'")
    total = total[0].attributes['ordertotal']
    return total
  end

  def actual_quantity
    load_id = self.id.to_i
    actual_quantity = LoadDetail.find_by_sql("SELECT SUM(actual_quantity) AS actual_quantity FROM load_details where load_id ='#{load_id }'")
    actual_quantity = actual_quantity[0]['actual_quantity']
    return actual_quantity
  end

  def required_quantity
    load_id = self.id.to_i
    required_quantity = LoadDetail.find_by_sql("SELECT SUM( required_quantity) AS  required_quantity FROM load_details where load_id ='#{load_id}'")
    required_quantity = required_quantity[0].attributes['required_quantity']
    return required_quantity
  end

  def update_load_detail
    Order.transaction do
      load_details = LoadDetail.find_by_sql("SELECT * FROM load_details WHERE load_id = '#{self.id}'")
      if !load_details.empty?
        for @load_details in load_details
          holdover_quantity = @load_details.set_holdover_quantity
          @load_details.update_attribute(:holdover_quantity, "#{holdover_quantity }")
          actual_cartons =@load_details.set_actual_carton_count
          @load_details.update_attribute(:actual_quantity, "#{ actual_cartons }")
          sub_total = @load_details.subtotal?
          @load_details.update_attribute(:sub_total, "#{sub_total}")
        end
      end


    end

  end


#	===========================
#	 lookup methods:
#	===========================


end
