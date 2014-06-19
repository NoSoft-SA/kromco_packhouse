class ListItem
  attr_accessor :persisted_lists_folder,:list_id,:list_name,:position#,:persisted_object

  def initialize()
  end

  def self.find_by_position_and_list_id_and_list_name(position, list_id,list_name,persisted_lists_folder)
    if(FileTest.exists?(persisted_lists_folder + list_name + "_" + list_id.gsub(".", "_") + "/" + position.to_s + ".txt"))
      list_item = ListItem.new
      list_item.list_id = list_id
      list_item.list_name = list_name
      list_item.position = position
      list_item.persisted_lists_folder = persisted_lists_folder
      return list_item
    end
  end

  def save
    File.new(self.persisted_lists_folder + self.list_name + "_" + self.list_id.gsub(".", "_") + "/" + self.position.to_s + ".txt", "w+").close if self.persisted_lists_folder
#    if self.persisted_lists_folder
#      File.open(self.persisted_lists_folder + self.list_name + "_" + self.list_id.gsub(".", "_") + "/" + self.position.to_s + ".txt", "w+") do |f|
#         Marshal.dump(self.unpersisted_object,f) if self.unpersisted_object
#         f.close
#       end
#    end
  end

  def self.find_all_by_list_id_and_list_name(list_id,list_name,persisted_lists_folder)
    collection = Array.new
    if(FileTest.exists?(persisted_lists_folder + list_name + "_" + list_id.gsub(".", "_")))
      Dir.foreach(persisted_lists_folder + list_name + "_" + list_id.gsub(".", "_")) do |entry|
        if File.stat(persisted_lists_folder + list_name + "_" + list_id.gsub(".", "_") + "/" + entry).directory? == false
         list_item = ListItem.new
         list_item.list_id = list_id
         list_item.list_name = list_name
         list_item.position =  collection.size
         list_item.persisted_lists_folder = persisted_lists_folder
         collection.push(list_item)
        end
      end
    end
    return collection
  end

  def get_persisted_object
    File.open(self.persisted_lists_folder + self.list_name + "_" + self.list_id.gsub(".", "_") + "/" + self.position.to_s + ".txt") do |f|
     if(File.size(self.persisted_lists_folder + self.list_name + "_" + self.list_id.gsub(".", "_") + "/" + self.position.to_s + ".txt") > 0)
      return Marshal.load(f)
     else
       return nil
     end
     f.close
   end
  end

  def update_persisted_object(unpersisted_object)
      File.open(self.persisted_lists_folder + self.list_name + "_" + self.list_id.gsub(".", "_") + "/" + self.position.to_s + ".txt", "w+") do |f|
       Marshal.dump(unpersisted_object,f)
       f.close
     end
  end

  def delete
    File.delete(self.persisted_lists_folder + self.list_name + "_" + self.list_id.gsub(".", "_") + "/" + self.position.to_s + ".txt")
  end

  def rename(name)
    File.rename(self.persisted_lists_folder + self.list_name + "_" + self.list_id.gsub(".", "_") + "/" + self.position.to_s + ".txt", self.persisted_lists_folder + self.list_name + "_" + self.list_id.gsub(".", "_") + "/" + name.to_s + ".txt")
  end

  def exists?
    if(FileTest.exists?(self.persisted_lists_folder + self.list_name + "_" + self.list_id.gsub(".", "_") + "/" + self.position.to_s + ".txt"))
      return true
    else
      return false
    end
  end

  def cancel_clear_combo_prompts
    true
  end

end
