class MesscadaServer < ActiveRecord::Base

  #MM112014 - messcada changes
  belongs_to :messcada_facility
  has_many :messcada_clusters #, :dependent => :destroy

end