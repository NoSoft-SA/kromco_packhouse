class OutboxEntry < ActiveRecord::Base
  attr_accessor :data
 
  def friendly_date
    return self.created_on.strftime("%d/%b/%Y %H:%M:%S")
  end
  
  def set_data
    self.data = self.record
  end
  
#  def joined_field
#    self.record_id.to_s + "-" + self.object_type.to_s
#  end
 
end
