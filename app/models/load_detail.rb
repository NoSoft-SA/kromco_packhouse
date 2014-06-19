class LoadDetail < ActiveRecord::Base

#	===========================
# 	Association declarations:
#	===========================


#	belongs_to :uom
#	belongs_to :order
#	belongs_to :fg_product
#	belongs_to :extended_fg
#	belongs_to :order_product_type
  belongs_to :load_order
  belongs_to :order_product
  has_many :pallets, :dependent => :destroy

#	============================
#	 Validations declarations:
#	============================

  validates_numericality_of :required_quantity
#	validates_numericality_of :dispatched_quantity
#	validates_numericality_of :available_quantities
#	=====================
#	 Complex validations:
#	=====================


  #
  #   subtotal for each product in an order,
  #   displayed on the grid
  #

  def LoadDetail.create_load_details(selected_order_products,load_id)
    load_order=LoadOrder.find_by_load_id(load_id)
    for order_product in selected_order_products
      order_product_attributes =order_product.attributes
      load_detail = LoadDetail.new
      load_detail.order_id = load_order.order_id
      load_detail.load_id = load_order.load_id
      load_detail.load_order_id =load_order.id
      load_detail.order_product_id=order_product.id
      sequence_number= calc_load_detail_sequence_number(load_order)
      load_detail.update_attribute(:sequence_number, sequence_number)
      load_detail.save
      for attr in order_product_attributes
        if load_detail.attributes.has_key?("#{attr[0]}")
          if attr[0]!= 'id' || attr[0]!= "sequence_number"
            load_detail.update_attribute(:"#{attr[0]}", "#{attr[1]}")
          end
        end
      end
    end
  end

  def LoadDetail.calc_load_detail_sequence_number(load_order)
      max_sequence =LoadDetail.find_by_sql("SELECT MAX(sequence_number) FROM load_details where load_order_id = #{load_order.id.to_i} ")
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


  def fields_not_to_clean
    ["cartons_lookup_sql"]
  end

  def selected_pallets(selected_pallets, parameter_field_values)
    ActiveRecord::Base.transaction do
    order=Order.find_by_sql("select orders.* from orders
                         inner join load_orders on load_orders.order_id=orders.id
                         where load_orders.id=#{self.load_order_id}")[0]
    load_id = self.load_id
    @load = Load.find("#{load_id}")
    #Pallet.find_by_sql("UPDATE pallets SET load_detail_id = null WHERE load_detail_id  = '#{self.id}'")
    pallet_numbers = Array.new
    for pallet in selected_pallets
      Pallet.find_by_sql(ActiveRecord::Base.extend_update_sql_with_request("UPDATE pallets SET load_detail_id = '#{self.id}' WHERE id  = '#{pallet['id']}'"))
      pallet_numbers << pallet['pallet_number']
    end
    for value in parameter_field_values

      split_field_name = "#{value[:field_name]}".split('.')
      field_name=split_field_name[1]
      attributes = self.attributes

      if attributes.has_key?("#{field_name}")
        self.send(:attributes=, "#{ field_name}" => "#{value[:field_value]}")
      end
    end
    subtotal = self.subtotal?
    self.update_attribute(:sub_total, "#{subtotal}")
    total= @load.total?
    @load.update_attribute(:total, "#{total}")
    actual_quantity = @load.actual_quantity
    @load.update_attribute(:actual_quantity, "#{actual_quantity}")
    holdover_quantity =  self.set_holdover_quantity
    self.update_attribute(:holdover_quantity, "#{holdover_quantity }")
    actual_cartons = self.set_actual_carton_count
    self.update_attribute(:actual_quantity, "#{ actual_cartons }")

    order_pallet_nums=Pallet.find_by_sql("select pallets.* from pallets
                                       join load_details on (pallets.load_detail_id = load_details.id)
                                       join loads on (loads.id = load_details.load_id)
                                       join load_orders on (loads.id = load_orders.load_id)
                                       where load_orders.order_id = '#{order.id}'").map{|p|p.pallet_number}

    Order.get_and_upgrade_prelim_orders(order_pallet_nums)
  end
  end


  def subtotal?
   
    sum_price_of_extended_fg_code=LoadDetail.find_by_sql("
        select coalesce(sum(extended_fgs.price),NULL,0) AS sum_price_of_extended_fg_code
        FROM cartons
        INNER JOIN extended_fgs  ON cartons.extended_fg_code= extended_fgs.extended_fg_code
        INNER JOIN pallets on cartons.pallet_id = pallets.id
        where pallets.load_detail_id = '#{self.id}'
        GROUP BY cartons.extended_fg_code")[0]['sum_price_of_extended_fg_code']
         
 end

  def set_holdover_quantity

#    pallets = Pallet.find_by_sql("SELECT * from pallets WHERE load_detail_id = '#{self.id }' AND holdover_quantity IS NOT NULL")
#    if pallets.empty?
#      holdover_quantity = 0
#      return holdover_quantity
#    else
#      holdover_quantity= 0
#      for pallet in pallets
#        h_quantity = pallet['holdover_quantity']
#        holdover_quantity  = holdover_quantity + h_quantity
#      end
#      return holdover_quantity
#    end
   holdover_quantity = Pallet.find_by_sql(
           "select count(public.cartons.id) as holdover_quantity from cartons
            inner join pallets on pallets.id =cartons.pallet_id where pallets.load_detail_id = #{self.id} AND holdover IS TRUE ")[0]['holdover_quantity']
   
  end

  def set_actual_carton_count
    load_detail_id = self.id
    non_holdover=Carton.find_by_sql("select count(cartons.*) as actual_cartons from cartons
          inner join pallets on pallets.id=cartons.pallet_id
          inner join load_details on load_details.id = pallets.load_detail_id
          where
          pallets.load_detail_id = #{self.id.to_s} ")[0]['actual_cartons']

   holdover = Pallet.find_by_sql("select SUM(pallets.holdover_quantity) as pallets_holdover from pallets
                                  where
                                  pallets.load_detail_id = #{self.id.to_s} AND pallets.holdover is true")[0]['pallets_holdover']

    actual_quantity =non_holdover.to_i + holdover.to_i


    return  actual_quantity


  end

  def calc_available_quantities(selected_pallets)
    pallet_numbers =Array.new
    for pallet in selected_pallets
      pallet_number = pallet['pallet_number']
      pallet_numbers << pallet_number
    end
    query = "SELECT COUNT(*) AS cartons FROM cartons WHERE pallet_number = pallet_number"
    str_sql = Carton.get_by_pallet_numbers2(query, pallet_numbers)
    available_quantities = Carton.find_by_sql(str_sql)
    available_quantities = available_quantities[0]['cartons']
    return available_quantities
  end


  def validate
#	first check whether combo fields have been selected
#	 is_valid = true
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:order_number => self.order_number},{:customer_party_role_id => self.customer_party_role_id}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_order
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:extended_fg_code => self.extended_fg_code}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_extended_fg
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:uom_code => self.uom_code}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_uom
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:order_product_code => self.order_product_code}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_order_product_type
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:fg_product_code => self.fg_product_code}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_fg_product
#	 end
  end

#	===========================
#	 foreign key validations:
#	===========================
  def set_uom

    uom = Uom.find_by_uom_code(self.uom_code)
    if uom != nil
      self.uom = uom
      return true
    else
      errors.add_to_base("combination of: 'uom_code'  is invalid- it must be unique")
      return false
    end
  end

  def set_order

    order = Order.find_by_order_number_and_customer_party_role_id(self.order_number, self.customer_party_role_id)
    if order != nil
      self.order = order
      return true
    else
      errors.add_to_base("combination of: 'order_number' and 'customer_party_role_id'  is invalid- it must be unique")
      return false
    end
  end

  def set_fg_product

    fg_product = FgProduct.find_by_fg_product_code(self.fg_product_code)
    if fg_product != nil
      self.fg_product = fg_product
      return true
    else
      errors.add_to_base("combination of: 'fg_product_code'  is invalid- it must be unique")
      return false
    end
  end

  def set_extended_fg

    extended_fg = ExtendedFg.find_by_extended_fg_code(self.extended_fg_code)
    if extended_fg != nil
      self.extended_fg = extended_fg
      return true
    else
      errors.add_to_base("combination of: 'extended_fg_code'  is invalid- it must be unique")
      return false
    end
  end

  def set_order_product_type

    order_product_type = OrderProductType.find_by_order_product_code(self.order_product_code)
    if order_product_type != nil
      self.order_product_type = order_product_type
      return true
    else
      errors.add_to_base("value of field: 'order_product_code' is invalid- it must be unique")
      return false
    end
  end

#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: uom_id
#	------------------------------------------------------------------------------------------

  def self.get_all_uom_codes

    uom_codes = Uom.find_by_sql('select distinct uom_code from uoms').map { |g| [g.uom_code] }
  end


#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: order_id
#	------------------------------------------------------------------------------------------

  def self.get_all_order_numbers

    order_numbers = Order.find_by_sql('select distinct order_number from orders').map { |g| [g.order_number] }
  end


  def self.get_all_customer_party_role_ids

    customer_party_role_ids = Order.find_by_sql('select distinct customer_party_role_id from orders').map { |g| [g.customer_party_role_id] }
  end


  def self.customer_party_role_ids_for_order_number(order_number)

    customer_party_role_ids = Order.find_by_sql("Select distinct customer_party_role_id from orders where order_number = '#{order_number}'").map { |g| [g.customer_party_role_id] }

    customer_party_role_ids.unshift("<empty>")
  end


#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: fg_products_id
#	------------------------------------------------------------------------------------------

  def self.get_all_fg_product_codes

    fg_product_codes = FgProduct.find_by_sql('select distinct fg_product_code from fg_products').map { |g| [g.fg_product_code] }
  end


#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: extended_fgs_id
#	------------------------------------------------------------------------------------------

  def self.get_all_extended_fg_codes

    extended_fg_codes = ExtendedFg.find_by_sql('select distinct extended_fg_code from extended_fgs').map { |g| [g.extended_fg_code] }
  end


end
