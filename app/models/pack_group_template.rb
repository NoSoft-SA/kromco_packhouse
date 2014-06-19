class PackGroupTemplate < ActiveRecord::Base

  belongs_to :sizer_template
  has_many :pack_group_template_outlets, :dependent => :destroy,:order => "id"
  
  attr_accessor :bypass_before_save,:do_not_create_outlets
  
   validates_numericality_of :color_sort_percentage
   #validates_presence_of :grade_code
   
   #---------------------------------------------------
   #Sizer template must be set externally by controller
   #---------------------------------------------------
   
   
   def validate
    ModelHelper::Validations.validate_combos([{:grade_code => self.grade_code}],self,true)  
   
   end
   
   
   def before_save
     puts self.bypass_before_save.to_s
     if !self.bypass_before_save
     
      self.pack_group_number = PackGroupTemplate.next_group_number(self.sizer_template.id)
      self.commodity_code = self.sizer_template.commodity_code
      self.rmt_variety_code = self.sizer_template.rmt_variety_code
      self.sizer_template_code = self.sizer_template.template_name
     end
   
   end
   
   def after_create
    create_outlets if !self.do_not_create_outlets
   end
  
  #------------------------------------------------------------------------------------------
 #IF THIS RECORD HAS NO 'PACK_GROUP_TEMPLATE_OUTLET' RECORDS BELONGING TO IT:
 #  1)Use the pack_group_counts_config table to get a list (in order- order by id)
 #    of all counts(to be used by all groups)for the commodity
 #  2)Create a set of pack_group template outlet records- one per count found in 2
 #------------------------------------------------------------------------------------------
  
  def create_outlets
    if self.pack_group_template_outlets.length == 0
      counts = PackGroupsCountsConfig.find_all_by_commodity_code(self.commodity_code,:order => 'position')
      if counts.length == 0
        raise "No sequence of counts('pack_groups_counts_configs' table) have been defined for commodity '#{self.commodity_code}'.
               <br> Use the program called 'pack_groups_counts_configs'(usually under 'tools') to define the list(and order of) size_counts
               <br>to use for allocating drops to counts per pack_group"
      end
      
     
      counts.each do |count|
        pgo = PackGroupTemplateOutlet.new
        pgo.pack_group_template_id = self.id
       
        if count.size_code
          pgo.size_code = count.size_code
        else
          pgo.standard_size_count_value = count.standard_size_count_value
        end
        
        pgo.create
      end
    
    end
  
  end
  
  
 
  
    def PackGroupTemplate.next_group_number(sizer_template_id)
  
    query = "SELECT max(pack_group_templates.pack_group_number)as maxval
           FROM
           public.pack_group_templates where 
           (pack_group_templates.sizer_template_id = '#{sizer_template_id}')"
           
   val = connection.select_one(query)
   if val["maxval"]== nil
     return 1
   else
    return val["maxval"].to_i + 1
   end
 end
end
