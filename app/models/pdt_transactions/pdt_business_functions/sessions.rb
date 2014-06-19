 #----------------------------------------------------
 # DUPLICATION
 #----------------------------------------------------
  def persisted_session_deep_copy(persisted_object)
    unpersisted_rails_object = Marshal.load(persisted_object)
    return copy = Marshal.dump(unpersisted_rails_object)
  end
 #----------------------------------------------------

  class PersistedList


	  #==================================================================================================
	  #This class aims to provide a version of an Array class that maintains it's state(list) only in a database - NOT IN MEMORY
	  #To work it requires:  1] a parent table (that represents the container of list items) Fields: name, list_id, size,id(rails id)
	  #                                 2] a child table to hold the items in the list. Fields: position, persisted_object,id(rails id)
	  #
	  # Note:   1] This list is NOT dynamically sizable- it is created with set amount of items (in db), but can be shrunk by certain methods  , e.g. shift
	  #             2] Whenever a list_item is returned to a caller (via any method that can return items, e.g [] or shift), we return a ruby object that is
	   #                   re--created from the 'persisted_object' field value of
	  #                 the list_item, by calling our private load_object method.
	  #             3] Whenever a list_item is saved or replaced in the list, we first persist the ruby object by calling our private dump_object method(),
	  #                    then we assign the persisted object to the persisted_object
	  #                    field of the list_item in question and then update the list_item record
	  #             4] NB: any code inside this class that gets a list of list_items in db, must NEVER include the persisted_object field in the resultset- EXCEPT, the each method. Other methods should
	  #                 only ever  get tthe persisted value if client code needs it
	  #
	  #
	  #     LUX note:  keep jsession_store as is- as a text file, but inside it, simply create a PersistedList instead of normal array. Then call the EXACT same methods
	  #                      that you were calling on the session array- now just on the PersistedList. Very important not to store any actual data of persisted objects as instance
	  #                      variables inside this class
	  #
	  #=================================================================================================
	   attr_accessor :list_name,:list_id,:size, :persisted_lists_folder

   private
   def self.dump_object(unpersisted_object)
	   #takes any ruby object and do a marshal.dump
     return Marshal.dump(unpersisted_object) if unpersisted_object != nil
   end


   private
   def self.load_object(persisted_object)
	   #re-create a ruby object by doing a marshal.load on a persisted object
     loaded_object = Marshal.load(persisted_object)
     if loaded_object
       return loaded_object
     else
       Hash.new
     end
   end

   public
   def initialize(size,list_id,list_name,persisted_lists_folder)
	    #See if a record in lists table exist for the given name(list_name) and list_id. If not, create a new list record
	   #gets the list_item records for the list- create additional list_items, upto amount, if the existing amount of list_items is less than amount

     @list_name = list_name
     @list_id = list_id
     @size = size
     @persisted_lists_folder = persisted_lists_folder

     begin
         ActiveRecord::Base.transaction do
           list = List.find_by_name_and_list_id(list_name,list_id,persisted_lists_folder)
            if list == nil
             list = List.new
             list.list_id = list_id
             list.name = list_name
             list.size = size
             list.persisted_lists_folder = persisted_lists_folder
             list.save
             list_items_num = 0
            else
             list_items_num = list.size
            end

           size.times do
             list_item = ListItem.find_by_position_and_list_id_and_list_name(list_items_num, list_id,list_name,persisted_lists_folder)
             if list_item == nil
               list_item = ListItem.new
               list_item.list_id = list_id
               list_item.list_name = list_name
               list_item.position =  list_items_num
               list_item.persisted_lists_folder = persisted_lists_folder
               list_item.save
             end
             list_items_num += 1
           end

      end
     rescue
       raise $!
     end
   end

   public
   def length
      list = List.find_by_name_and_list_id(self.list_name,self.list_id,self.persisted_lists_folder)
      if(list)
        return list.size
      else
        return 0
      end
   end

   public
   def size
      length
   end

   public
   def [](i)
#     #OUR:  find the list_items record for parent where position = i. If i.persisted_object == nil, return null. If a record is found, re-create a ruby object from the persisted_object field of the list item by
#      #passing the persisted_object as an argument to load_object

     begin
        list_items = ListItem.find_all_by_list_id_and_list_name(self.list_id,self.list_name,self.persisted_lists_folder)
         for list_item in list_items
         if list_item.position == i
           if list_item.get_persisted_object == nil
             return Hash.new
           else
             return list_item.get_persisted_object
           end
         end
       end

       return Hash.new
     rescue
       raise $!
     end
   end

   public
   def []=(i,j)
	#OUR: get the list_items record at position i and replace the persisted_object field value with i  (after having persisted i by calling dump_object(i))and update the db record. If i = nil, update persisted_object to be null in db
     begin
       list_item = ListItem.find_by_position_and_list_id_and_list_name(i, self.list_id,self.list_name,self.persisted_lists_folder)
       if(list_item)
        list_item.update_persisted_object(j)
       end
     rescue
       raise $!
     end
   end

   public
   def each
	   #---------------
	   #CLASSIC example:
	   #---------------
            # for i in 0..self.length() -1
             #  yield self[i]
           #end

	    #---------------------------
	    #OUR
	    #---------------------------
	    #get list of  list_items for the list, ordered by position. Loop throug the resultset. For each item, yield the ruby object re-created from the 'persisted_object' ( by calling load_object) field of the item
      #@report = Report.find_all_by_report_type_and_reference_id(report_type,reference_id.to_i,:order => 'version_number DESC')[0]
     begin
       list_items = ListItem.find_all_by_list_id_and_list_name(self.list_id,self.list_name,self.persisted_lists_folder)
       for list_item in list_items
         yield list_item.get_persisted_object
       end
     rescue
       raise $!
     end
   end

   public
   def shift
         #CLASSIC: Returns the first element(i.e. array[0]) of self and removes it (shifting all other elements down by one). Returns nil if the array is empty

	  #-----------
	  #OUR
	  #------------
	  #gets a deep_copy of  first(position 0) list_item(it's persisted_object field value) and then deletes its db record. Update the position value of each remaining list_item to be current_position -1
	  #return the deep_copy of list_items's persisted_object  to caller. If  persisted object is null, return nil
    ActiveRecord::Base.transaction do
      list = List.find_by_name_and_list_id(self.list_name,self.list_id,self.persisted_lists_folder)
      if(list)
        position = 0
         list_item = ListItem.find_by_position_and_list_id_and_list_name(position, self.list_id,self.list_name,self.persisted_lists_folder)
         copy = list_item.get_persisted_object
         list_item.delete

         position += 1
        self.size.times do
          list_item = ListItem.find_by_position_and_list_id_and_list_name(position, self.list_id,self.list_name,self.persisted_lists_folder)
          list_item.rename((position-1).to_s)
          position += 1
         end

        return copy
      end
    end
   end

   public
   def unshift(object)
	#CLASSIC: Prepends objects to the front of array. other elements up one

	 #------------
	 #OUR
	 #------------
	 #get all list_items for list, and update the position of each list_item to be current position + 1. Delete the list_item with biggest position value if it is now bigger than @amount
	 # create a new list_item for object(object is the 'persisted_object' of a class) and set its position value as 0
     ActiveRecord::Base.transaction do
        list = List.find_by_name_and_list_id(self.list_name,self.list_id,self.persisted_lists_folder)
        if(list)
          position = self.size - 1
          self.size.times do
            list_item = ListItem.find_by_position_and_list_id_and_list_name(position, self.list_id,self.list_name,self.persisted_lists_folder)
            list_item.rename((position+1).to_s)            
            position -= 1
          end

          list_item = ListItem.new
          list_item.list_id = self.list_id
          list_item.list_name = self.list_name
          list_item.position =  0
          list_item.persisted_lists_folder = self.persisted_lists_folder
          list_item.save
          list_item.update_persisted_object(object)
      end

     end
   end

   public
   def pop
     #CLASSIC: Removes the last element from self and returns it, or nil if the array is empty

     #--------
     #OUR
     #--------
     # find the list_item with max position and return a deep_copy of its persisted object. Then delete the db record

      list_item = ListItem.find_by_position_and_list_id_and_list_name((self.size-1), self.list_id,self.list_name,self.persisted_lists_folder)
      if list_item
        persisted_object = list_item.get_persisted_object
       list_item.delete
       return persisted_object
     end
   end

   public
   def push(unpersisted_object)
     #CLASSIC: Appends the given argument(s) to the end of arr (as with a stack).

      list_item = ListItem.new
      list_item.list_id = self.list_id
      list_item.list_name = self.list_name
      list_item.position = self.size
      list_item.persisted_lists_folder = self.persisted_lists_folder
      list_item.save
      list_item.update_persisted_object(unpersisted_object)
   end

   public
   def clear_list
#     #OUR: delete the list with name and id and all it's dependent list_items records

     list = List.find_by_name_and_list_id(self.list_name,self.list_id,self.persisted_lists_folder)
      if(list)
        position = 0
        self.size.times do
          list_item = ListItem.find_by_position_and_list_id_and_list_name(position, self.list_id,self.list_name,self.persisted_lists_folder)
          if list_item
           list_item.delete
          end
          position += 1
        end
      end
   end

   public
   def update(position,unpersisted_object)
     #Only use if want to persist state changes to a list item immediately.
      list_item = ListItem.find_by_position_and_list_id_and_list_name(position, self.list_id,self.list_name,self.persisted_lists_folder)
      list_item.update_persisted_object(unpersisted_object)
   end
 end