class MesscadaPeripheralPrinter < ActiveRecord::Base

  #MM122014 - messcada changes
  belongs_to :messcada_peripheral

  validates_presence_of :label_mode,:gtin_mode,:do_maximum_label,:render_amount

  # def validate
  #   if self.new_record?
  #     validate_uniqueness
  #   end
  # end
  #
  # def validate_uniqueness
  #   exists = MesscadaPeripheralPrinter.find_by_code(self.code)
  #   if exists != nil
  #     errors.add_to_base("There already exists a record with the code value of fields: '#{self.code}' ")
  #   end
  # end

  def before_save
    peripheral = MesscadaPeripheral.find(self.messcada_peripheral_id)
    self.peripheral_code = peripheral.code

  end

  def after_save

  end

end