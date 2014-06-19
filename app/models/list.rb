class List
  attr_accessor :list_id,:name,:size,:persisted_lists_folder

  def initialize()
  end

  def self.find_by_name_and_list_id(list_name,list_id,persisted_lists_folder)
    if(FileTest.exists?(persisted_lists_folder + list_name + "_" + list_id.gsub(".", "_")))
      list = List.new
      list.list_id = list_id
      list.name = list_name
      list.persisted_lists_folder = persisted_lists_folder
      list.size = list.length
      return list
    end
  end

  def save
    Dir.mkdir(self.persisted_lists_folder  + self.name + "_" + self.list_id.gsub(".", "_")) if self.persisted_lists_folder
  end

  def length
    length = 0
    if(self.persisted_lists_folder != nil && FileTest.exists?(self.persisted_lists_folder + self.name + "_" + self.list_id.gsub(".", "_")))
      Dir.foreach(self.persisted_lists_folder + self.name + "_" + self.list_id.gsub(".", "_")) do |entry|
       if File.stat( self.persisted_lists_folder + self.name + "_" + self.list_id.gsub(".", "_") + "/" + entry ).directory? == false
         length += 1
       end
      end
    end
    return length
  end
#
##	===========================
## 	Association declarations:
##	===========================
#  has_many :list_items, :dependent=>:destroy
#
#
#
##	============================
##	 Validations declarations:
##	============================
#	validates_numericality_of :size
##	=====================
##	 Complex validations:
##	=====================
#def validate
##	first check whether combo fields have been selected
#	 is_valid = true
#end

#	===========================
#	 foreign key validations:
#	===========================
#	===========================
#	 lookup methods:
#	===========================



end
