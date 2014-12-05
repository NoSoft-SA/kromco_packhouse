class MesscadaModule < ActiveRecord::Base

  #MM112014 - messcada changes
  belongs_to :messcada_cluster
  has_many :messcada_peripherals #, :dependent => :destroy

end