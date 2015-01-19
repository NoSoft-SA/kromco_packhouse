class MesscadaFacility < ActiveRecord::Base

  #MM122014 - messcada changes
  has_many :messcada_servers#, :dependent => :destroy

   validates_presence_of :code, :desc_short

  def validate
    if self.new_record?
        validate_uniqueness
    end
  end

  def validate_uniqueness
    exists = MesscadaFacility.find_by_code(self.code)
    if exists != nil
      errors.add_to_base("There already exists a record with the code value of fields: '#{self.code}' ")
    end
  end

  def before_save

  end

  def after_save

  end

end