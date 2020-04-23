class LoadOrder < ActiveRecord::Base
  belongs_to :city, :foreign_key => 'destination_city_id'
#	===========================
# 	Association declarations:
#	===========================


  belongs_to :order
  belongs_to :vehicle_job
  belongs_to :load
  has_many :load_details, :dependent=> :destroy


   def get_shipping_agent_party_name
     sql = "select parties_roles.party_name  from load_orders lo join orders on orders.id=lo.order_id

     join load_voyages on load_voyages.load_id =lo.load_id
     join parties_roles on load_voyages.shipping_agent_party_role_id =parties_roles.id
     where lo.id = #{self.id}"

     shipper = ActiveRecord::Base.connection.select_one(sql)
     return shipper['party_name'] if shipper

   end
  

#	============================
#	 Validations declarations:
#	============================
#	=====================
#	 Complex validations:
#	=====================
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
#		 is_valid = ModelHelper::Validations.validate_combos([{:id => self.id},{:vehicle_job_number => self.vehicle_job_number}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_vehicle_job
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:load_number => self.load_number}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_load
#	 end
  end

#	===========================
#	 foreign key validations:
#	===========================

  def before_create
    self.revision_number = 0
  end

  def get_revision_number
    if self.revision_number == nil ||  self.revision_number == ""
      return 0
    else
      return self.revision_number
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

  def set_vehicle_job

    vehicle_job = VehicleJob.find_by_id_and_vehicle_job_number(self.id, self.vehicle_job_number)
    if vehicle_job != nil
      self.vehicle_job = vehicle_job
      return true
    else
      errors.add_to_base("combination of: 'id' and 'vehicle_job_number'  is invalid- it must be unique")
      return false
    end
  end

  def set_load

    load = Load.find_by_load_number(self.load_number)
    if load != nil
      self.load = load
      return true
    else
      errors.add_to_base("value of field: 'load_number' is invalid- it must be unique")
      return false
    end
  end

#	===========================
#	 lookup methods:
#	===========================
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
#	Lookup methods for the foreign composite key of id field: vehicle_job_id
#	------------------------------------------------------------------------------------------

  def self.get_all_ids

    ids = VehicleJob.find_by_sql('select distinct id from vehicle_jobs').map { |g| [g.id] }
  end


  def self.get_all_vehicle_job_numbers

    vehicle_job_numbers = VehicleJob.find_by_sql('select distinct vehicle_job_number from vehicle_jobs').map { |g| [g.vehicle_job_number] }
  end


  def self.vehicle_job_numbers_for_id(id)

    vehicle_job_numbers = VehicleJob.find_by_sql("Select distinct vehicle_job_number from vehicle_jobs where id = '#{id}'").map { |g| [g.vehicle_job_number] }

    vehicle_job_numbers.unshift("<empty>")
  end


end
