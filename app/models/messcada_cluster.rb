class MesscadaCluster < ActiveRecord::Base

  #MM112014 - messcada changes
  belongs_to :messcada_server
  has_many :messcada_modules #, :dependent => :destroy

end