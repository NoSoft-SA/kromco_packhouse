class MesscadaFacility < ActiveRecord::Base

  #MM112014 - messcada changes
  has_many :messcada_servers #, :dependent => :destroy

end