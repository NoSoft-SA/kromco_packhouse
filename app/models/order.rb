class Order < ActiveRecord::Base

  attr_accessor :customer_contact_name,
                :customer_credit_rating,
                :customer_credit_rating_timestamp,
                :customer_memo_pad,
                :customer_party_name,
                :customer_order_number,
                :discount_percentage,
                :order_id,
                :user,
                :restore_tm

#  has_many :order_customer_detail
  has_one :order_customer_detail, :dependent => :destroy
  has_many :order_products, :dependent => :destroy
  has_many :load_orders, :dependent => :destroy

  belongs_to :credit_rating
  belongs_to :order_type
  belongs_to :document_destination
  belongs_to :depot

  STATUS_DELETION_RECVD = 'DELETION_RECVD'
  def notify_marketer_order_created(msg,subj,recepient)
      RAILS_DEFAULT_LOGGER.info("SENDING MAIL FOR order_created")
      easy_order_mail_log=EasyOrderMailLog.new
      easy_order_mail_log.order_number=self.order_number
      easy_order_mail_log.date_created=Time.now
      easy_order_mail_log.subject=subj
      easy_order_mail_log.recepient=recepient
      easy_order_mail_log.save
      email =  EasyOrderNotice.create_notify_marketer_order_created(msg,subj,recepient)
      email.set_content_type("text/html")
      EasyOrderNotice.deliver(email)

      RAILS_DEFAULT_LOGGER.info("SENT MAIL FOR early_order_created")
    end

  def notify_price(msg)
    easy_order_mail_log=EasyOrderMailLog.new
    easy_order_mail_log.order_number=self.order_number
    easy_order_mail_log.date_created=Time.now
    easy_order_mail_log.subject="Order Price notification: #{self.order_number}"
    easy_order_mail_log.save
    email = EasyOrderNotice.create_notify_price(msg, self.order_number)
    email.set_content_type("text/html")
    EasyOrderNotice.deliver(email)

    RAILS_DEFAULT_LOGGER.info("SENT MAIL FOR NOTIFY_PRICE")

  end

  def Order.notify_early_order_stock_complete(msg,subj)
    RAILS_DEFAULT_LOGGER.info("SENDING MAIL FOR early_order_stock_complete")
    easy_order_mail_log=EasyOrderMailLog.new
    easy_order_mail_log.date_created=Time.now
    easy_order_mail_log.subject=subj
    easy_order_mail_log.save
    email = EasyOrderNotice.create_notify_can_upgrade(msg,subj)
    email.set_content_type("text/html")
    EasyOrderNotice.deliver(email)

    RAILS_DEFAULT_LOGGER.info("SENT MAIL FOR early_order_stock_complete")
  end



  def notify_early_order_created(msg,subj)
    RAILS_DEFAULT_LOGGER.info("SENDING MAIL FOR early_order_created")
    easy_order_mail_log=EasyOrderMailLog.new
    easy_order_mail_log.date_created=Time.now
    easy_order_mail_log.subject=subj
    easy_order_mail_log.order_number=self.order_number
    easy_order_mail_log.save
    email = EasyOrderNotice.create_notify_order_created(msg,subj)
    email.set_content_type("text/html")
    EasyOrderNotice.deliver(email)

    RAILS_DEFAULT_LOGGER.info("SENT MAIL FOR early_order_created")
  end

    def notify_order_updated_by_marketer(msg,subj)
    RAILS_DEFAULT_LOGGER.info("SENDING MAIL FOR early_order_updated_by_marketer")
    easy_order_mail_log=EasyOrderMailLog.new
    easy_order_mail_log.date_created=Time.now
    easy_order_mail_log.subject=subj
    easy_order_mail_log.order_number=self.order_number
    easy_order_mail_log.save
    email = EasyOrderNotice.create_notify_order_updated(msg,subj)
    email.set_content_type("text/html")
    EasyOrderNotice.deliver(email)

    RAILS_DEFAULT_LOGGER.info("SENT MAIL FOR early_order_updated_by_marketer")
  end


  def delete_order
    if self.restore_tm
      if self.changed_tm==true || self.changed_tm=="t"
        self.revert_tm
      end
    end
    self.destroy
  end

  def Order.get_orders(pallet_numbers)
    pallet_nums=[]
    for pallet_num in pallet_numbers
      pallet_nums << "'#{pallet_num}'"
    end
    pallet_nums=pallet_nums.join(",")
    orderz =Order.find_by_sql("select orders.*
                     from orders
                     inner join  load_orders on load_orders.order_id=orders.id
                     inner join  load_details on load_details.load_order_id=load_orders.id
                     inner join  pallets on pallets.load_detail_id=load_details.id
                     inner join order_types on orders.order_type_id=order_types.id
                     where pallets.pallet_number  in (#{pallet_nums}) and (order_types.order_type_code='MO' or order_types.order_type_code='MQ') ")
    orders =[]
    oderz ={}
    if !orderz.empty?
      for o in orderz
        orders << o if !oderz.has_key?(o['order_number'])
        oderz[o['order_number']]=[o['order_number']]
      end
    end
    return orders
  end

  def get_order_pallets(order)
    order_pallets =Pallet.find_by_sql("select pallets.*
             from pallets
             inner join load_details on pallets.load_detail_id=load_details.id
             inner join load_orders on load_details.load_order_id=load_orders.id
             inner join  orders on load_orders.order_id=orders.id
             left join stock_items on stock_items.inventory_reference=pallets.pallet_number
             where orders.id=#{order.id} ")
#    order_pallets=[]
#        oderz ={}
#        if !order_all_pallets.empty?
#          for o in order_all_pallets
#            order_pallets << o if !oderz.has_key?(o['pallet_number'])
#            oderz[o['pallet_number']]=[o['pallet_number']]
#          end
    return order_pallets
  end

  def order_pallets_in_stock?(order_pallets, order)
    pallet_nums =order_pallets.map { |p| "'#{p.pallet_number}'" }.join(",")
    order_pallet_nums=order_pallets.map { |p| "'#{p.pallet_number}'" }
    stock_pallets =[]
    stock_pallets =Pallet.find_by_sql("
     select pallets.*
     from pallets
     inner join stock_items on stock_items.inventory_reference=pallets.pallet_number
     where pallets.exit_ref is null and pallets.qc_result_status='PASSED' and
     stock_items.inventory_reference in (#{pallet_nums}) and  (stock_items.destroyed is null or stock_items.destroyed is false) ")
    if order_pallets.length == stock_pallets.length
      return true
    else
      return nil
    end

  end

  def order_pallets_in_reworks?(order_pallets)
    pallet_nums =order_pallets.map { |p| "'#{p.pallet_number}'" }.join(",")
    order_pallet_nums=order_pallets.map { |p| "'#{p.pallet_number}'" }
    stock_pallets =[]
    reworks_cartons=RwReceiptCarton.find_by_sql("select rw_receipt_cartons.* from rw_receipt_cartons where pallet_number in (#{pallet_nums})")
    reworks_pallets =Pallet.find_by_sql("
     select pallets.*
     from pallets
     inner join stock_items on stock_items.inventory_reference=pallets.pallet_number
     where  ((stock_items.location_code like '%REWORKS%' OR stock_items.location_code like '%PACKHSE%' OR stock_items.location_code like '%PART_PALLETS%' )and
     stock_items.inventory_reference in (#{pallet_nums}))")
    if reworks_pallets.empty? && reworks_cartons.empty?
      return true
    else
      return nil
    end
  end

  def Order.get_and_upgrade_prelim_orders(pallet_numbers,test_upgrade_pallets=nil,test_order=nil)
    @msg=nil
    if test_order
      orders=[test_order]
    else
      orders=Order.get_orders(pallet_numbers)
    end

    if !orders.empty?
      to_be_upgraded=[]
      to_downgrade =[]
      for order in orders
        if test_upgrade_pallets
          order_pallets=test_upgrade_pallets
        else
          order_pallets=order.get_order_pallets(order)
        end
        can_upgrade =order.order_pallets_in_stock?(order_pallets, order)
        in_reworks =order.order_pallets_in_reworks?(order_pallets)
        if can_upgrade && in_reworks
          to_be_upgraded << order
        else
          to_downgrade << order
        end
      end
      o=Order.new
      if !to_be_upgraded.empty?
        o.upgrade_orders(to_be_upgraded)
      elsif !to_downgrade.empty?
        if test_order && test_order.not_all_pallets_is_stock==true
          if  !can_upgrade && !in_reworks
            @msg="Order cannot upgrade:pallets not in stock and some in reworks"
          elsif !in_reworks && can_upgrade
            @msg="Order cannot upgrade: pallets in reworks"
          elsif !can_upgrade && in_reworks
            @msg="Order cannot upgrade: pallets not in stock"
          end
        else
          o.downgrade_orders(to_downgrade)
        end
      end

    end
    return @msg
  end

  def upgrade_orders(to_be_upgraded)

    order_ids =to_be_upgraded.map { |j| j.id }.join(",")

    to_b_upgraded=Order.find_by_sql("select orders.*, order_customer_details.customer_contact_name,order_customer_details.customer_memo_pad ,parties_roles.party_name||' - '||parties_roles.remarks as trading_partner
                                     from orders
                                    join order_customer_details on order_customer_details.order_id=orders.id
                                     left  join parties_roles on orders.consignee_party_role_id=parties_roles.id
                                     left  join trading_partners on trading_partners.parties_role_id=parties_roles.id
                                    where  orders.id in (#{order_ids}) and orders.not_all_pallets_is_stock=true")

    if !to_b_upgraded.empty?
      to_b_upgraded_ids=to_b_upgraded.map { |j| j.id }.join(",")
      order_numbers=to_b_upgraded.map { |j| "Order number:#{j.order_number}<br> "+  " "+ "Customer:#{j['trading_partner']}<br>" +" "+ "Loading_date:#{j.loading_date.to_date if j.loading_date}<br>" +" " + "Memo_pad:#{j['customer_memo_pad']}<br>"  }.join(",")
      subj=to_b_upgraded.map { |j| j.order_number }.join(",")
      ActiveRecord::Base.connection.execute("update orders set not_all_pallets_is_stock=false where id in (#{to_b_upgraded_ids})")
      puts "========================THE FOLLOWING ORDERS WHERE UPGRADED====================================="
      puts " #{order_numbers}"
      msg = "The following orders are ready for upgrade:<br>  #{order_numbers},
                Pallets have just been received in stock OR pallets have just been released from reworks "
      email =Order.notify_early_order_stock_complete(msg,subj)
    end

  end

  def downgrade_orders(to_downgrade)
    downgrade=[]
    for order in to_downgrade
      if order.not_all_pallets_is_stock==false || order.not_all_pallets_is_stock=="f"
        downgrade << order
      end
    end
    if !downgrade.empty?

      order_ids =downgrade.map { |j| j.id }.join(",")
      to_b_downgraded=Order.find_by_sql("select * from orders where  id in (#{order_ids}) and not_all_pallets_is_stock=false")

      if !to_b_downgraded.empty?
        to_b_downgraded_ids=to_b_downgraded.map { |j| j.id }.join(",")
        order_numbers= to_b_downgraded.map { |j| j.order_number }.join(",")
        ActiveRecord::Base.connection.execute("update orders set not_all_pallets_is_stock=true where id in (#{to_b_downgraded_ids})")
        puts "=====================THE FOLLOWING ORDERS WHERE DOWNGRADED,Some Pallets are not in stock or are in reworks==============================="
        puts "=========#{order_numbers}=============="
        msg = "The following orders have been downgraded:  #{order_numbers},
         Some Pallets are not in stock or are in reworks "
        email =Order.notify_early_order_stock_complete(msg,order_numbers)
      end
    end
  end


  #def before_destroy
  #  if self.restore_tm
  #    if self.changed_tm==true || self.changed_tm=="t"
  #      self.revert_tm
  #    end
  #  end
  #end

  def revert_tm
    pallets_qry ="select pallets.*
                         from pallets
                         inner join load_details on pallets.load_detail_id=load_details.id
                         inner join load_orders on load_details.load_order_id=load_orders.id
                         inner join  orders on load_orders.order_id=orders.id
                         where orders.id=#{self.id} "
    pallets   =        ActiveRecord::Base.connection.select_all(pallets_qry)
    pallet_ids=pallets.map { |k| k.id }.join(",") if !pallets.empty?

    order_products=OrderProduct.find_by_sql("select order_products.* from order_products
    inner join load_details on load_details.order_product_id=order_products.id
    inner join load_orders on load_details.load_order_id=load_orders.id
    where load_orders.order_id=#{self.id}")
    order_product_ids=order_products.map { |k| k.id }.join(",") if !order_products.empty?

    load_details=OrderProduct.find_by_sql("select load_details.* from load_details
    inner join load_orders on load_details.load_order_id=load_orders.id
    where load_orders.order_id=#{self.id}")
    load_detail_ids=load_details.map { |k| k.id }.join(",") if !load_details.empty?
    ActiveRecord::Base.transaction do
      if self.restore_tm
        ActiveRecord::Base.connection.execute("update pallets set target_market_code=orig_target_market_code,load_detail_id = null,remarks1=null ,remarks2=null,remarks3=null ,remarks4=null,remarks5=null where id in (#{pallet_ids})") if !pallets.empty?
       else
        ActiveRecord::Base.connection.execute("update pallets set target_market_code=orig_target_market_code where id in (#{pallet_ids})") if !pallets.empty?
      end
      ActiveRecord::Base.connection.execute("update cartons set target_market_code=orig_target_market_code where pallet_id in (#{pallet_ids})") if !pallets.empty?


      ActiveRecord::Base.connection.execute("update pallets set orig_target_market_code=null where id in (#{pallet_ids})") if !pallets.empty?
      ActiveRecord::Base.connection.execute("update cartons set orig_target_market_code=null where pallet_id in (#{pallet_ids})") if !pallets.empty?

      ActiveRecord::Base.connection.execute("update order_products set target_market_code=orig_target_market_code where id in (#{order_product_ids})") if !order_products.empty?
      ActiveRecord::Base.connection.execute("update load_details set target_market_code=orig_target_market_code where id in (#{load_detail_ids})") if !load_details.empty?

      ActiveRecord::Base.connection.execute("update order_products set orig_target_market_code=null where id in (#{order_product_ids})") if !order_products.empty?
      ActiveRecord::Base.connection.execute("update load_details set orig_target_market_code=null where id in (#{load_detail_ids})") if !load_details.empty?

      ActiveRecord::Base.connection.execute("update orders set changed_tm=false where id =#{self.id}")


    end
  end

  def change_tm(target_market)
    # update orig_tm of all cartons and pallets to current values
    # update order.changed_tm to trading_partner.target_market
    # update target_market of pallets and cartons to trading_partner.target_market
    pallets =Pallet.find_by_sql("select pallets.*
                     from pallets
                     inner join load_details on pallets.load_detail_id=load_details.id
                     inner join load_orders on load_details.load_order_id=load_orders.id
                     inner join  orders on load_orders.order_id=orders.id
                     where orders.id=#{self.id} and pallets.orig_target_market_code is null")
    #pallet_nums=pallets.map { |k|"'#{k.pallet_number}'"  }.join(",") if !pallets.empty?
    #if !pallets.empty?()
    #  msg=get_invalid_ctns_for_tm_grade(pallet_nums,target_market)
    #  if msg
    #    return msg
    #  end
    #end
    pallet_ids=pallets.map { |k| k.id }.join(",") if !pallets.empty?

    order_products=OrderProduct.find_by_sql("select order_products.* from order_products
    inner join load_details on load_details.order_product_id=order_products.id
    inner join load_orders on load_details.load_order_id=load_orders.id
    where load_orders.order_id=#{self.id}")
    order_product_ids=order_products.map { |k| k.id }.join(",") if !order_products.empty?

    load_details=OrderProduct.find_by_sql("select load_details.* from load_details
    inner join load_orders on load_details.load_order_id=load_orders.id
    where load_orders.order_id=#{self.id}")
    load_detail_ids=load_details.map { |k| k.id }.join(",") if !load_details.empty?

    ActiveRecord::Base.transaction do

      ActiveRecord::Base.connection.execute("update pallets set orig_target_market_code=pallets.target_market_code where id in (#{pallet_ids})") if !pallets.empty?
      ActiveRecord::Base.connection.execute("update cartons set orig_target_market_code=cartons.target_market_code where pallet_id in (#{pallet_ids})") if !pallets.empty?

      ActiveRecord::Base.connection.execute("update pallets set target_market_code='#{target_market.target_market_code}' where id in (#{pallet_ids})") if !pallets.empty?
      ActiveRecord::Base.connection.execute("update cartons set target_market_code='#{target_market.target_market_code}' where pallet_id in (#{pallet_ids})") if !pallets.empty?

      ActiveRecord::Base.connection.execute("update order_products set orig_target_market_code=order_products.target_market_code where id in (#{order_product_ids})") if !order_products.empty?
      ActiveRecord::Base.connection.execute("update load_details set orig_target_market_code=load_details.target_market_code where id in (#{load_detail_ids})") if !load_details.empty?

      ActiveRecord::Base.connection.execute("update order_products set target_market_code='#{target_market.target_market_code}' where id in (#{order_product_ids})") if !order_products.empty?
      ActiveRecord::Base.connection.execute("update load_details set target_market_code='#{target_market.target_market_code}' where id in (#{load_detail_ids})") if !load_details.empty?


      ActiveRecord::Base.connection.execute("update orders set changed_tm=true where id =#{self.id}")

    end
#return nil
  end

  def get_invalid_ctns_for_tm_grade(pallet_nums,target_market)
    valid_grades_for_tm=Grade.find_by_sql("select distinct grades.grade_code from grades
                                          inner join grade_target_markets on grade_target_markets.grade_id=grades.id
                                          inner join target_markets on grade_target_markets.target_market_id=#{target_market.id}")
    if !valid_grades_for_tm.empty?
      grades=valid_grades_for_tm.map{|g|"'#{g.grade_code}'"}
      cartons=Carton.find_by_sql("select cartons.* from cartons
                                    inner join pallets on cartons.pallet_id=pallets.id
                                    where cartons.pallet_number in (#{pallet_nums}) and cartons.grade_code not in (#{grades.join(",")})")
    else
      return [0,1,3]
    end


    if !cartons.empty?
      if cartons.length > 50
        return [grades]
      else
        carton_numbers=cartons.map{|l|l.carton_number}
        return [carton_numbers,grades]
      end

    else
      return nil
    end


        end



  def set_virtual_atrr
    if (self.order_customer_detail)
      self.customer_contact_name = self.order_customer_detail.customer_contact_name
      self.customer_credit_rating = self.order_customer_detail.customer_credit_rating
      self.customer_credit_rating_timestamp = self.order_customer_detail.customer_credit_rating_timestamp
      self.customer_memo_pad = self.order_customer_detail.customer_memo_pad
      self.customer_order_number = self.order_customer_detail.customer_order_number
      self.discount_percentage = self.order_customer_detail.discount_percentage
    end
  end

  def validate
    is_valid = true

    if is_valid
      is_valid = ModelHelper::Validations.validate_combos([{:order_type_id => self.order_type_id}], self)

      is_valid = ModelHelper::Validations.validate_combos([{:consignee_party_role_id => self.consignee_party_role_id}], self)

      is_valid = ModelHelper::Validations.validate_combos([{:customer_party_role_id => self.customer_party_role_id}], self)

      is_valid = ModelHelper::Validations.validate_combos([{:depot_id => self.depot_id}], self)

    end
  end

  def validate_uniqueness
    exists = Order.find_by_order_number_and_customer_party_role_id(self.order_number, self.customer_party_role_id)
    if exists != nil
      errors.add_to_base("There already exists a record with the combined values of fields: 'order_number' and 'customer_party_role_id' ")
    end
  end

  attr_accessor :total, :required_total

  ORDER_CREATED = 'Order Created'

  def def_value
    @def_value = 0
  end

  def resend_hwe_sales(load_order_rec)
    @load_order = load_order_rec
    EdiOutProposal.send_doc(@load_order, 'HCS', :organization_code => 'KR', :hub_address => '031')

  end


  def ship_delivery(load_id)

    Order.transaction do
      order_id = self.id.to_i
      pallets = Pallet.find_by_sql("select pallets.* from pallets
                                         join load_details on (pallets.load_detail_id = load_details.id)
                                         join loads on (loads.id = load_details.load_id)
                                         join load_orders on (loads.id = load_orders.load_id)
                                         where load_orders.load_id = '#{load_id}'")

      order_type_code=OrderType.find(self.order_type_id).order_type_code
      if order_type_code == "DP"
        depot_code = "031"
        season_code = pallets[0]['season_code'].split(//)
        last_dig_season_code = season_code.last.to_s
        dispatch_consignment = "%06d" % MesControlFile.next_seq_web(16).to_s
        dispatch_consignment_number = depot_code.to_s + last_dig_season_code + dispatch_consignment
        dispatch_consignment_number = dispatch_consignment_number
        cust_party_name = PartiesRole.find(self.consignee_party_role_id).party_name
	cust_remarks = PartiesRole.find(self.consignee_party_role_id).remarks
      end
      if order_type_code == "CU"
        first_xter = "D"
        customer_party_name = PartiesRole.find(self.customer_party_role_id).party_name
        cust_party_name = PartiesRole.find(self.consignee_party_role_id).party_name
	cust_remarks = PartiesRole.find(self.consignee_party_role_id).remarks
        depot_code = "031"
        dispatch_delivery_note = "%04d" % MesControlFile.next_seq_web(31).to_s
        dispatch_consignment_number = first_xter + customer_party_name + depot_code + dispatch_delivery_note
      end

      @load_order = LoadOrder.find_by_sql("SELECT * FROM load_orders WHERE load_id = '#{load_id}'")
      @load_order = @load_order[0]
      @load_order.update_attribute(:dispatch_consignment_number, "#{dispatch_consignment_number}")
      pallet_numbers=Array.new
      for @pallet in pallets
        @pallet.update_attribute(:exit_ref, "#{dispatch_consignment_number}")
        pallet_numbers << @pallet.pallet_number
      end

      #EdiOutProposal.send_doc(@load_order, 'HCS')
      EdiOutProposal.send_doc(@load_order, 'PO')


      Inventory.remove_stock(nil, 'PALLET', "SHIP_DISPATCH_DELIVERY", @load_order.id, 'IN_TRANSIT', pallet_numbers)

      @load = Load.find("#{@load_order['load_id']}")
      @load.set_status("SHIPPED")
      shipped_date_time = Time.now
      @load.update_attribute(:shipped_date_time, shipped_date_time)

      loads=Load.find_by_sql("select loads.* from loads
                            inner join load_orders on load_orders.load_id=loads.id
                            where load_orders.order_id=#{self.id}")
      if !loads.empty?
        load_statuses =loads.map { |l| l.load_status }

        other_statuses=[]
        for status in load_statuses
          other_statuses << status if status!="SHIPPED"
        end
        if other_statuses.empty?
          self.set_status("SHIPPED")
        end
      end
      order_products_prices=OrderProduct.find_by_sql("
                           select order_products.* from order_products
                           where order_id=#{self.id} and (price_per_carton is not null and price_per_carton > 0.00 )
                          ")
      if !order_products_prices.empty?
        self.price_check=true
        self.update
        msg="order products for order : #{self.order_number} have a price.  Customer: #{cust_party_name} - #{cust_remarks}"
        self.notify_price(msg)
      end
    end

  end

  def resend_po(load_order_rec)
    @load_order = load_order_rec
    party_name = PartiesRole.find(self.customer_party_role_id).party_name
    EdiOutProposal.send_doc(@load_order, 'PO', :organization_code => party_name, :hub_address => self.depot_code)


  end

  def resend_po_to_marketing(load_order_rec)
    @load_order = load_order_rec
    party_name = PartiesRole.find(self.customer_party_role_id).party_name
    EdiOutProposal.send_doc(@load_order, 'PO', :organization_code => party_name, :hub_address => 'ETI')

  end

  def resend_pf(load_order_rec)
    @load_order = load_order_rec

    party_name = PartiesRole.find(self.customer_party_role_id).party_name
    EdiOutProposal.send_doc(@load_order, 'PF', :organization_code => party_name, :hub_address => 'ETI')

  end

  def create_loads
    Order.transaction do
      order_id = self.id.to_i
      @load = Load.new
      @load.load_number = MesControlFile.next_seq_web(9)
      @load.load_status = "LOAD_CREATED"
      @load.save
      @load_status_history = LoadStatusHistory.new
      @load_status_history.load_id = @load.id
      @load_status_history.load_status = "LOAD_CREATED"
      @load_status_history.save

      @load_order = LoadOrder.new
      @load_order.order_id = self.id
      @load_order.load_id = @load.id
      @load_order.save

      #--------------------------------calculate max sequence number-------------------------

      max_sequence =LoadOrder.find_by_sql("SELECT MAX(sequence_number) FROM load_orders")
      max_sequence = max_sequence[0].attributes['max']
      max_sequence = max_sequence.to_i
      if  max_sequence == nil
        next_sequence = 1
        @load_order.update_attribute(:sequence_number, "#{next_sequence}")
      else
        next_sequence = max_sequence + 1
        @load_order.update_attribute(:sequence_number, "#{next_sequence}")
      end

      #order_products      = OrderProduct.find_by_sql("SELECT * FROM order_products WHERE order_id = '#{order_id}'")
      #for order_product in order_products
      #  @load_details          = LoadDetail.new
      #  @load_details.load_id  = @load.id
      #  @load_details.order_id = self.id
      #  @load_details.save
      #  #------------copying order_products attributes to  load_details record----------------------------
      #  order_product_attributes =order_product.attributes
      #  for attr in order_product_attributes
      #    if @load_details.attributes.has_key?("#{attr[0]}") && attr[0] != 'id'
      #      @load_details.update_attribute(:"#{attr[0]}", "#{attr[1]}")
      #    end
      #  end
      #  #------------breaking item_pack_product_code values to fields on load_details record------------------
      #  item_pack_code                         =order_product['item_pack_product_code']
      #  item_pack_product                      = item_pack_code.split(/_/)
      #  item_pack_product_hash                 = Hash.new
      #  item_pack_product_hash                 = {"commodity_code"         => "#{item_pack_product[0]}",
      #                                            "marketing_variety_code" =>"#{item_pack_product[1]}",
      #                                            "product_class_code"     =>"#{item_pack_product[2]}",
      #                                            "grade_code"             =>"#{item_pack_product[3]}",
      #                                            "actual_count"           =>"#{item_pack_product[4]}",
      #                                            "basic_pack_code"        =>"#{item_pack_product[5]}",
      #                                            "cosmetic_code_name"     =>"#{item_pack_product[6]}",
      #                                            "size_ref"               => "#{item_pack_product[7]}"
      #  }
      #
      #
      #  @load_details['commodity_code']        = item_pack_product_hash["commodity_code"]
      #  @load_details['marketing_variety_code']= item_pack_product_hash["marketing_variety_code"]
      #  @load_details['product_class_code']    = item_pack_product_hash["product_class_code"]
      #  @load_details['grade_code']            = item_pack_product_hash["grade_code"]
      #  @load_details['actual_count']          = item_pack_product_hash["actual_count"]
      #  @load_details['basic_pack_code']       = item_pack_product_hash["basic_pack_code"]
      #  @load_details['cosmetic_code_name']    = item_pack_product_hash["cosmetic_code_name"]
      #  @load_details['size_ref']              = item_pack_product_hash["size_ref"]
      #
      #  #@load_details['required_quantity']= order_product['required_quantity']
      #  #--------------foreign_key_to_order_products and load_orders-------------------------
      #  @load_details.update_attribute(:order_product_id, "#{order_product.attributes['id']}")
      #  @load_details.update_attribute(:load_order_id, "#{@load_order['id']}")
      #  @load_details.update_attribute(:load_id, "#{@load.id}")
      #
      #
      #end
    end

    return @load

  end

  def log_pallets
    log = PalletDocumentLog.new
    dispatch_consignment_number = self.load_orders[0].dispatch_consignment_number
    query = "insert into pallet_document_logs (pallet_id,document_number,document_type,program_name,user_name,created_at)
                      select pallets.id, pallets.exit_ref,'dispatch','dispatch','#{self.user}','#{Time.new().to_formatted_s(:db)}'
                     from pallets where pallets.exit_ref = '#{dispatch_consignment_number}'"
    self.connection.execute(query)

  end

  def complete_order
    Order.transaction do
      @order_customer_detail = OrderCustomerDetail.find_by_order_id(self.id)
      order_amount = self.calculate_order_amount(self.order_number)
      result = self.do_credit_check()
      if result = "PASSED" || "AUTHORISED"
        @order_customer_detail.update_attribute(:customer_credit_rating, "#{result}")
        credit_rating_timestamp = Time.now
        @order_customer_detail.update_attribute(:customer_credit_rating_timestamp, "#{ credit_rating_timestamp}")
      else
        @order_customer_detail.update_attribute(:customer_credit_rating, "#{result}")
        flash[:notice]= "CANNOT COMPLETE ORDER:CREDIT CHECK RETURNED"+ "#{result}"
      end
      order_status = self.set_status("COMPLETED")
    end

  end

  def selected_items(selected_item_packs, parameter_fields_values)
    Order.transaction do
      order_id = self.id

      for item_pack in selected_item_packs
        @order_product = OrderProduct.new
        @order_product.order_id = self.id
        @order_product.save
        for field_name in parameter_fields_values
          splitted_field_name = "#{field_name[:field_name]}".split('.')
          field_name_field_name=splitted_field_name[1]
          if @order_product.attributes.has_key?("#{field_name_field_name}")
            @order_product.update_attribute("#{field_name_field_name}", "#{field_name[:field_value]}") if  !field_name_field_name.upcase.index("PRICE")
          end
        end
#        price_per_carton              = item_pack['carton_count'].to_i* item_pack['carton_weight']
#        item_pack['price_per_carton'] = "#{price_per_carton}"
#        subtotal                      = item_pack['carton_count'].to_f * item_pack['price_per_kg'].to_f * item_pack['carton_weight'].to_f
#        subtotal                      = "%.2f" %subtotal
#        @order_product.update_attribute(:subtotal, "#{subtotal}")
#        @order_product.update_attribute(:order_id, "#{order_id}")
#        @order_product.update_attribute(:price_per_kg, "#{item_pack['price_per_kg']}")
#        @order_product.update_attribute(:carton_weight, "#{item_pack['carton_weight']}")
#        @order_product.update_attribute(:price_per_carton, "#{item_pack['price_per_carton']}")
        @order_product.update_attribute(:available_quantities, "#{item_pack['carton_count']}")
        #@order_product.update_attribute(:carton_count, "#{item_pack['carton_count']}")

        @order_product.update_attributes({:item_pack_product_code=>item_pack['item_pack_product_code'],:old_fg_code=>item_pack['old_fg_code']})
        sequence_number = self.calc_order_product_sequence_number
        @order_product.update_attribute(:sequence_number, "#{sequence_number}")
      end
    end

  end

  def import_pallets(pallet_numberz)
    pallet_numbers=[]
    pallet_numberz.each_key {
        |key| pallet_numbers << key }
    self.transaction do
      order_type =OrderType.find(self.order_type_id).order_type_code
      if order_type=="MO" || order_type=="MQ"
        query ="SELECT count(public.cartons.id) AS carton_count,coalesce(public.item_pack_products.price_per_kg,NULL,0) as price_per_kg ,public.cartons.carton_fruit_nett_mass AS carton_weight,
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
                where(cartons.pallet_number= cartons.pallet_number  and pallets.load_detail_id is null)
                GROUP BY public.cartons.pallet_number,pallets.build_status,item_pack_products.commodity_code,
                item_pack_products.marketing_variety_code,cartons.target_market_code,item_pack_products.grade_code,
                cartons.inventory_code,cartons.puc,cartons.iso_week_code,cartons.season_code,cartons.inspection_type_code,
                cartons.pick_reference,pallets.pallet_format_product_code,cartons.pc_code,extended_fgs.old_fg_code,
                item_pack_products.actual_count,item_pack_products.size_ref,extended_fgs.extended_fg_code, pallets.load_detail_id,
                pallets.id, public.item_pack_products.price_per_kg, public.item_pack_products.item_pack_product_code,public.cartons.carton_fruit_nett_mass "
      else
        query ="SELECT count(public.cartons.id) AS carton_count,coalesce(public.item_pack_products.price_per_kg,NULL,0) as price_per_kg ,public.cartons.carton_fruit_nett_mass AS carton_weight,
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
                where(cartons.pallet_number= cartons.pallet_number and pallets.consignment_note_number is not null and pallets.load_detail_id is null)
                GROUP BY public.cartons.pallet_number,pallets.build_status,item_pack_products.commodity_code,
                item_pack_products.marketing_variety_code,cartons.target_market_code,item_pack_products.grade_code,
                cartons.inventory_code,cartons.puc,cartons.iso_week_code,cartons.season_code,cartons.inspection_type_code,
                cartons.pick_reference,pallets.pallet_format_product_code,cartons.pc_code,extended_fgs.old_fg_code,
                item_pack_products.actual_count,item_pack_products.size_ref,extended_fgs.extended_fg_code, pallets.load_detail_id,
               pallets.id, public.item_pack_products.price_per_kg, public.item_pack_products.item_pack_product_code,public.cartons.carton_fruit_nett_mass "
      end
      # pallet_numbers=pallet_numbers.split
      #inspection_result = Pallet.inspection_status(pallet_numbers)
      str_sql = Carton.get_by_pallet_numbers(query, pallet_numbers)
      pseudo_pallets = Pallet.connection.select_all("#{str_sql}")
      raise "Error: No valid pallets found!. QUERY IS:" + str_sql if pseudo_pallets.length == 0
      puts "PALLET NUMBERS-ORDER:<BR> #{pallet_numbers.join("<BR>")}"
      puts "pseudo_pallets-ORDER:<BR> " + "#{pseudo_pallets.length()}"
      result =self.reverse_engineer_order(pseudo_pallets, pallet_numberz)
    end

  end

  def calc_order_product_sequence_number
    max_sequence =OrderProduct.find_by_sql("SELECT MAX(sequence_number) FROM order_products where order_id = #{self.id.to_s} ")
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


  #def reverse_engineer_order(pseudo_pallets, remarks)
  #  Order.transaction do
  #    #------------------------------------------------------------------------
  #    #update the {order_quantity} field value of the [order] record to the sum of {carton_count} field of passed-in
  #    #pseudo_pallets
  #    #------------------------------------------------------------------------
  #    required_quantity =0
  #    for pallet in pseudo_pallets
  #      required_quantity = required_quantity + pallet['carton_count'].to_i
  #    end
  #    self.update_attribute(:required_quantity, "#{required_quantity}")
  #    required_quantity = required_quantity.to_i
  #    #--------------------------------------------------------------------------------------
  #    #create new [loads] record
  #    #--------------------------------------------------------------------------------------
  #    load = Load.new
  #    if load.load_number == nil
  #      load.load_number = MesControlFile.next_seq_web(9)
  #    end
  #    load.load_status="LOAD_CREATED"
  #    load.save
  #    load_status_history = LoadStatusHistory.new
  #    load_status_history.load_id = @load.id
  #    load_status_history.load_status = "LOAD_CREATED"
  #    load_status_history.save
  #    #      load_status          = @load.set_status('LOAD_CREATED')
  #    #--------------------------------------------------------------------------------------
  #    #create a new load_orders record
  #    #--------------------------------------------------------------------------------------
  #    load_order = LoadOrder.new
  #    load_order.load_id = @load.id
  #    load_order.order_id = self.id
  #    load_order.save
  #
  #    #--------------------------------------------------------------------------------------
  #    # for each item_pack_product group in grouped list created
  #    #  calculate and set value for {subtotal} field as follows:
  #    # {required_qty} * pseudo_pallet.price_per_kg * pseudo_pallet.carton_weight}
  #    #(use values any pseudo_pallet in current group)
  #    #-------------------------------------------------------------------------------------
  #    item_pack_product_groups =pseudo_pallets.group(['item_pack_product_code'], nil, true)
  #    extended_fg_group_sub_totals = 0
  #    for item_pack_product_group in item_pack_product_groups
  #      group_required_quantity = 0
  #      for pseudo_pallet in item_pack_product_group
  #        group_required_quantity += pseudo_pallet['carton_count'].to_i
  #      end
  #      #--------------------------------------------------------------------------------------------
  #      #break down the item_pack_product_code into fields that exit on [order_product]
  #      #--------------------------------------------------------------------------------------------
  #      existing_order_product=OrderProduct.find_by_sql("select * from order_products where item_pack_product_code='#{item_pack_product_group[0]['item_pack_product_code']}' and order_id=#{order.id}")
  #      if existing_order_product.empty?
  #
  #        order_product = OrderProduct.new
  #        order_product.order_id = self.id
  #        order_product.save
  #
  #        pseudo_pallet_attributes =item_pack_product_group[0]
  #
  #        for pseudo_pallet_attribute in pseudo_pallet_attributes
  #
  #          if  order_product.attributes.has_key?("#{pseudo_pallet_attribute[0]}") && pseudo_pallet_attribute[0] != 'id'
  #            order_product.update_attribute(:"#{pseudo_pallet_attribute[0]}", "#{pseudo_pallet_attribute[1]}")
  #          end
  #
  #        end
  #        item_pack_code =pseudo_pallet_attributes['item_pack_product_code']
  #        item_pack_product = item_pack_code.split(/_/)
  #        item_pack_product_hash = Hash.new
  #        item_pack_product_hash = {"commodity_code" => "#{item_pack_product[0]}",
  #                                  "marketing_variety_code" => "#{item_pack_product[1]}",
  #                                  "product_class_code" => "#{item_pack_product[2]}",
  #                                  "grade_code" => "#{item_pack_product[3]}",
  #                                  "actual_count" => "#{item_pack_product[4]}",
  #                                  "basic_pack_code" => "#{item_pack_product[5]}",
  #                                  "cosmetic_code_name" => "#{item_pack_product[6]}",
  #                                  "size_ref" => "#{item_pack_product[7]}"
  #        }
  #        order_product['commodity_code'] = item_pack_product_hash["commodity_code"]
  #        order_product['marketing_variety_code']= item_pack_product_hash["marketing_variety_code"]
  #        order_product['product_class_code'] = item_pack_product_hash["product_class_code"]
  #        order_product['grade_code'] = item_pack_product_hash["grade_code"]
  #        order_product['actual_count'] = item_pack_product_hash["actual_count"]
  #        order_product['basic_pack_code'] = item_pack_product_hash["basic_pack_code"]
  #        order_product['cosmetic_code_name'] = item_pack_product_hash["cosmetic_code_name"]
  #        order_product['size_ref'] = item_pack_product_hash["size_ref"]
  #        order_product['order_number'] = self.attributes['order_number']
  #        order_product.update_attribute(:required_quantity, "#{group_required_quantity}")
  #        order_product.update_attribute(:available_quantities, "#{group_required_quantity}")
  #      else
  #        order_product=existing_order_product[0]
  #      end
  #
  #      subtotal = 0
  #      sum_carton_weight = 0
  #      for pallet in item_pack_product_group
  #        price_per_kg =pallet['price_per_kg'].to_f
  #        carton_weight = pallet['carton_weight'].to_f
  #        pallet_total = pallet['carton_count'].to_f * price_per_kg * carton_weight
  #        subtotal += pallet_total
  #        sum_carton_weight +=carton_weight
  #      end
  #
  #
  #      price_per_carton = item_pack_product_group[0]['price_per_kg'].to_f * (sum_carton_weight/item_pack_product_group.length())
  #      price_per_carton = "%.2f" % price_per_carton
  #      subtotal ="%.2f" %subtotal
  #      order_product.update_attribute(:subtotal, "#{subtotal}")
  #      order_product.update_attribute(:price_per_carton, "#{price_per_carton}")
  #      price_per_kg = "%.2f" % item_pack_product_group[0]['price_per_kg']
  #      order_product.update_attribute(:price_per_kg, "#{price_per_kg }")
  #      average_carton_weight = sum_carton_weight/item_pack_product_group.length()
  #      average_carton_weight = "%.2f" %average_carton_weight
  #      order_product.update_attribute(:carton_weight, "#{average_carton_weight}")
  #      sequence_number = self.calc_order_product_sequence_number
  #      order_product.update_attribute(:sequence_number, "#{sequence_number}")
  #
  #      #----------------------------------------------------------------------------------
  #      #create load_detail record
  #      #calculate and update the {subtotal} field of the [load_detail] record as follows:
  #      #use Carton.get_by_pallet_nums(..<pallet_nums in current group>.)
  #      #method to generate a query to work out total cost for this group. Query structure:
  #      #join cartons with extended_fgs and group cartons by extended_fg_code
  #      #where pallet_number is <or clause for each pallet num> and use
  #      # a sql numeric function to work out pallet total: sum(extended_fgs.price)
  #      #for each [pseudo_pallet] record in the current group:
  #      #*update the {load_detail_id} value of each pallet represented by the current pseudo_pallet record
  #      #----------------------------------------------------------------------------------
  #      order_product_attributes =order_product.attributes
  #      load_detail = LoadDetail.new
  #      load_detail.order_id = self.id
  #      load_detail.load_id = load.id
  #      load_detail.load_order_id =load_order.id
  #      load_detail.order_product_id=order_product.id
  #      load_detail.save
  #
  #      for attr in order_product_attributes
  #
  #        if load_detail.attributes.has_key?("#{attr[0]}")
  #          if attr[0]!= 'id' && attr[0]!=order_id
  #            load_detail.update_attribute(:"#{attr[0]}", "#{attr[1]}")
  #          end
  #        end
  #
  #      end
  #
  #      pallet_numbers = Array.new
  #      load_detail_id = load_detail.id
  #      remarks_hash ={}
  #      for pseud_pallet in item_pack_product_group
  #        remark =remarks[pseud_pallet['pallet_number']]
  #        marks =remark.split(",")
  #        updates=[]
  #        j =0
  #        for mrk in marks
  #          updates << "remarks#{j} =" + "'#{mrk}'" if j!=0
  #          j = j+ 1
  #        end
  #        updates << "load_detail_id =" + load_detail_id.to_s
  #        updates =updates.join(",")
  #        remarks_hash[marks[0]]=updates
  #        pallet_numbers << marks[0]
  #        for o in remarks_hash
  #          self.connection.execute("update pallets set #{o[1]} where pallet_number='#{o[0]}' ")
  #        end
  #      end
  #
  #      sub_total = load_detail.subtotal?
  #      actual_quantity = load_detail.set_actual_carton_count
  #      holdover_quantity = load_detail.set_holdover_quantity
  #      load_detail.update_attributes!({:sub_total => sub_total,
  #                                      :required_quantity => required_quantity,
  #                                      :actual_quantity => actual_quantity,
  #                                      :holdover_quantity => holdover_quantity
  #                                     })
  #    end
  #
  #    #-----------------------------------------------------------------------------------------------------------------
  #    #calculate and update the {total} field of [load] record, by calling load.total? ( It is the sum of all {subtotal}
  #    # field values of the [load_details] belonging to this load)
  #    #------------------------------------------------------------------------------------------------------------------
  #    actual_quantity = self.actual_quantity
  #    required_quantity = self.required_quantity
  #    total = self.total?
  #    load.update_attributes!({:sub_total => sub_total,
  #                             :required_quantity => required_quantity,
  #                             :total => total
  #                            })
  #  end
  #end

  def get_by_pallet_numbers(from_clause, where_or_clause, closing_clause)
    str_sql = from_clause + "where" +"(" + where_or_clause + ")" + closing_clause
    extended_fgs_prices = Carton.find_by_sql("#{str_sql}")
    group_sub_total = 0
    for pallet in extended_fgs_prices
      group_sub_total = group_sub_total + pallet['sum_price_of_extended_fg_code']
    end
    return group_sub_total
  end


  def after_save
    self.depot_code=Depot.find(self.depot_id).depot_code
    self.update
    if self.order_customer_detail
      #      after_save_ocd_sync
      #      self.order_customer_detail.order_id = self.id
      unless [self.discount_percentage, self.customer_credit_rating,
      self.customer_contact_name, self.customer_credit_rating_timestamp,
      self.customer_order_number, self.customer_memo_pad].all? { |a| a.nil? }
        self.order_customer_detail.discount_percentage = self.discount_percentage
        self.order_customer_detail.customer_credit_rating = self.customer_credit_rating
        self.order_customer_detail.customer_contact_name = self.customer_contact_name
        self.order_customer_detail.customer_credit_rating_timestamp = self.customer_credit_rating_timestamp
        self.order_customer_detail.customer_order_number = self.customer_order_number
        self.order_customer_detail.customer_memo_pad = self.customer_memo_pad
        self.order_customer_detail.save
      end
    else
      self.order_customer_detail = OrderCustomerDetail.new
      #      after_save_ocd_sync
      self.order_customer_detail.order_id = self.id
      self.order_customer_detail.discount_percentage = self.discount_percentage
      self.order_customer_detail.customer_credit_rating = self.customer_credit_rating
      self.order_customer_detail.customer_contact_name = self.customer_contact_name
      self.order_customer_detail.customer_credit_rating_timestamp = self.customer_credit_rating_timestamp
      self.order_customer_detail.customer_order_number = self.customer_order_number
      self.order_customer_detail.customer_memo_pad = self.customer_memo_pad
      self.order_customer_detail.save!
    end

    true
  end


  def required_total
    required_total = 0
    self.order_products.each do |order_product|
      required_total += order_product.required_quantity
    end

    return required_total
  end

  def order_amount
    session_order_id = self.id
    order_amount = self.calculate_order_amount(session_order_id)

    return order_amount
  end

  def calculate_order_amount(session_order_id)
    order_products = OrderProduct.find_by_sql("SELECT * from order_products WHERE order_id ='#{session_order_id }' ")
    if order_products.empty?
      order_amount = 0
      return order_amount
    else
      order_amount = OrderProduct.find_by_sql("SELECT SUM(subtotal) AS ordertotal FROM order_products where order_id ='#{session_order_id }'")
      order_amount = order_amount[0].attributes['ordertotal']
      if order_amount == nil
        return 0
      else
        return order_amount
      end
    end
  end


=begin

  Credit check was put here, but will be moved at a later stage

=end
  #___________________________________________________________#
  #   Do credit check
  #
  #   returns @approved = true or false
  #   returns @message = "message from financial systems"
  #___________________________________________________________#
  def do_credit_check()

    @message = "PASSED"
    @message2 = "AUTHORISED"
    return @message
#    @approved = nil

#    order_customer_detail = OrderCustomerDetail.find(:all, :conditions => "order_id = " + self.id.to_s)
#
#    # get result by doing check with financial systems
#
#    if result != nil
#      # do credit check, return result
#      if result == 1
#        @approved = true
#        @message = "PASSED"
#      else
#        if result == 3
#          @approved = true
#          @message = "AUTHORISED"
#        else
#          if  result == 2
#            @approved = false
#            @message = "Cannot complete order, Customer Credit not Approved"
#          end
#        end
#      end
#
#    else
#      @approved = false
#      @message = "Couldn't connect to financial system"
#    end
#    returning values = [] do
#      values << @approved
#      values << @message
#    end
  end


  def editable?
    if self.order_status == "Order Created"
      return true
    else
      return false
    end
  end


#	===========================
#	 foreign key validations:
#	===========================
  def set_credit_rating
    credit_rating = CreditRating.find_by_credit_code(self.credit_code)
    if credit_rating != nil
      self.credit_rating = credit_rating
      return true
    else
      errors.add_to_base("value of field: 'credit_code' is invalid- it must be unique")
      return false
    end
  end

  def set_order_type

    order_type = OrderType.find_by_order_type_code(self.order_type_code)
    if order_type != nil
      self.order_type = order_type
      return true
    else
      errors.add_to_base("value of field: 'order_type_code' is invalid- it must be unique")
      return false
    end
  end

  def set_document_destination

    document_destination = DocumentDestination.find_by_id(self.id)
    if document_destination != nil
      self.document_destination = document_destination
      return true
    else
      errors.add_to_base("value of field: 'id' is invalid- it must be unique")
      return false
    end
  end

  def set_depot

    depot = Depot.find_by_depot_code(self.depot_code)
    if depot != nil
      self.depot = depot
      return true
    else
      errors.add_to_base("value of field: 'depot_code' is invalid- it must be unique")
      return false
    end
  end


  def pallets_not_on_consignment?
    query = "SELECT
              pallets.pallet_number
            FROM
              public.orders,
              public.loads,
              public.load_orders,
              public.pallets,
              public.load_details
            WHERE
              load_orders.load_id = loads.id AND
              load_orders.order_id = orders.id AND
              pallets.load_detail_id = load_details.id AND
              load_details.load_order_id = load_orders.id AND
              pallets.consignment_note_number IS NULL  AND
              orders.id = #{self.id.to_s}"

    invalid_pallets = self.connection.select_all(query)
    return invalid_pallets


  end

  def set_status(new_status)

    if new_status.upcase == "SHIPPED"
      inv_pallets = pallets_not_on_consignment?
      if  inv_pallets.length() > 0
        invalid_pallets= inv_pallets.map { |p| p['pallet_number'] }
        err = "The following pallets(on order: #{self.order_number}) does not belong to a consignment:<BR> #{invalid_pallets.join(",")} "
        raise err
      end
      log_pallets
    end

    @order_status_history = OrderStatusHistory.new
    @order_status_history['order_id'] = self.id
    @order_status_history['order_status'] = new_status
    @order_status_history['date_created'] =Time.now
    @order_status_history.save
    self.order_status = new_status
    self.update
    return new_status

  end

  # An LI EDI can mark the Order for deletion by setting the status.
  # Check to see if this Order is due to be deleted.
  def to_be_deleted
    self.order_status == STATUS_DELETION_RECVD
  end

#	===========================
#	 lookup methods:
#	===========================

#def order_type_code
#  order_product_type.order_type_code = OrderProductType.find(:order_type_id => self.order_type_id).order_type_code
#end

end
