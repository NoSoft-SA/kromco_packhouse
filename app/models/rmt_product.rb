class RmtProduct < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
	belongs_to :variety
	belongs_to :size
	belongs_to :treatment
	belongs_to :ripe_point
	belongs_to :product_class
	belongs_to  :product
    belongs_to :track_slms_indicator
    has_many :bins
                           
 
 attr_accessor :ripe_point_description


  def after_create
    integrate_rmt_product_into_MAF('PST-01')
    integrate_rmt_product_into_MAF('PST-02')
  end

  def integrate_rmt_product_into_MAF(unit)
    begin
      if (self.rmt_product_type_code.to_s.upcase=='PRESORT')
        code_article_client = "#{self.product_class_code}_#{self.treatment_code}_#{self.size_code}"

        http = Net::HTTP.new(Globals.bin_scanned_mssql_server_host(unit), Globals.bin_created_mssql_presort_server_port(unit))
        request = Net::HTTP::Post.new("/select")
        parameters = {'method' => 'select', 'statement' => Base64.encode64("select * from [productionv50].[dbo].[Articleclient] where [productionv50].[dbo].[Articleclient].[Code_Articleclient]='#{code_article_client}'")}
        request.set_form_data(parameters)
        response = http.request(request)
        puts "---\n#{response.code} - #{response.message}\n---\n"

        if '200' == response.code
          res = response.body.split('resultset>').last.split('</res').first
          if ((results = Marshal.load(Base64.decode64(res))).length > 0)
            return
          end
        else
          err = response.body.split('</message>').first.split('<message>').last
          errmsg = "MAF rmt_product_code intergration unique check failed: The http code is #{response.code}. Message: #{err}."
          logger.error ">>>> #{errmsg}"
          raise errmsg
          return
        end


        http = Net::HTTP.new(Globals.bin_scanned_mssql_server_host(unit), Globals.bin_created_mssql_presort_server_port(unit))
        request = Net::HTTP::Post.new("/exec")
        parameters = {'method' => 'insert', 'statement' => Base64.encode64("INSERT INTO [productionv50].[dbo].[Articleclient] ([Code_articleclient],[Nom_articleclient]) VALUES('#{code_article_client}','#{code_article_client}')")}
        request.set_form_data(parameters)
        response = http.request(request)

        if response.code != '200'
          err = response.body.split('</message>').first.split('<message>').last
          errmsg = " \"INSERT INTO [productionv50].[dbo].[Articleclient]\". The http code is #{response.code}. Message: #{err}."
          raise errmsg
        end
      end
    rescue
      raise "SQL MF Automatic Integration returned an error: #{$!.message}"
    end
  end


  def after_find
 self.ripe_point_description = self.ripe_point.ripe_point_description if self.ripe_point
end


def before_update
 if self.rmt_product_type_code == "orchard_run"
    self.treatment_type_code = "PRE_HARVEST"
 elsif self.rmt_product_type_code == "rebin"
   self.treatment_type_code = "PACKHOUSE"
 elsif self.rmt_product_type_code.to_s.upcase == "PRESORT"
   self.treatment_type_code = "PRESORT"   
 end
 set_product_code
end

def before_create
#create a product of type raw material
  if self.rmt_product_type_code == "orchard_run"
    self.treatment_type_code = "PRE_HARVEST"
 elsif self.rmt_product_type_code == "rebin"
   self.treatment_type_code = "PACKHOUSE"
 elsif self.rmt_product_type_code.to_s.upcase == "PRESORT"
   self.treatment_type_code = "PRESORT"   
 end
 set_product_code
 product = Product.new
 product.product_type = ProductType.find_by_product_type_code("RMT")
 product.product_code = self.rmt_product_code
 product.uom = Uom.find_by_uom_code("KG")
 product.product_type_code = "RMT"
 product.save
 self.product = product

end
 
 #NAE 20151228 add actual and short_rmt-product_codes
def set_product_code
   
   if self.rmt_product_type_code == "orchard_run"||self.rmt_product_type_code.to_s.upcase == "PRESORT"
    self.rmt_product_code = self.commodity_code + "_" + self.variety_code + "_" + self.treatment_code + "_" + self.product_class_code + "_" + self.ripe_point_code + "_" + self.size_code
    
    if self.rmt_product_type_code == "orchard_run"
       self.actual_rmt_product_code = self.rmt_product_code	
       self.short_rmt_product_code = self.commodity_code + "_" + self.variety_code + "_" + self.treatment_code + "_" + self.product_class_code + "_" + self.size_code
	   
    elsif  self.rmt_product_type_code.to_s.upcase == "PRESORT" 
	   RAILS_DEFAULT_LOGGER.info("XMAS size_code.length: " + size_code.length.to_s)
	   RAILS_DEFAULT_LOGGER.info("XMAS self.size_code.slice(0..self.size_code.length()-2): " +self.size_code.slice(0..self.size_code.length()-2))
	
	if self.product_class_code != "2L" && self.product_class_code != "3" &&  self.size_code != 'ALL' && (self.size_code.slice(size_code.length-1, size_code.length-1) == "A" || self.size_code.slice(size_code.length-1, size_code.length-1) == "L")
	   RAILS_DEFAULT_LOGGER.info("XMAS ONE")
	   self.actual_rmt_product_code = self.commodity_code + "_" + self.variety_code + "_" + self.treatment_code + "_" + self.product_class_code + "_" + self.ripe_point_code + "_" +  self.size_code.slice(0..self.size_code.length()-2)
	   self.short_rmt_product_code = self.commodity_code + "_" + self.variety_code + "_" + self.treatment_code + "_" + self.product_class_code + "_" +  self.size_code.slice(0..self.size_code.length()-2)
	else
	   self.actual_rmt_product_code = self.rmt_product_code
	   RAILS_DEFAULT_LOGGER.info("XMAS TWO")
           self.short_rmt_product_code = self.commodity_code + "_" + self.variety_code + "_" + self.treatment_code + "_" + self.product_class_code + "_" + self.size_code			
	end
    end
   
   else
       self.rmt_product_code = self.commodity_code + "_" + self.variety_code + "_" + self.treatment_code + "_" + self.product_class_code + "_" + self.ripe_point_code + "_" + self.size_code + "_" + self.bin_type
       self.actual_rmt_product_code = self.commodity_code + "_" + self.variety_code + "_" + self.treatment_code + "_" + self.product_class_code + "_" + self.ripe_point_code + "_" + self.size_code
       self.short_rmt_product_code = self.commodity_code + "_" + self.variety_code + "_" + self.treatment_code + "_" + self.product_class_code + "_" + self.size_code 
   end
end


def before_destroy
  self.product.destroy

end
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
      if(self.rmt_product_type_code.to_s.upcase == "PRESORT")
        self.treatment_type_code = "PRESORT"
      elsif self.rmt_product_type_code == "orchard_run"
        self.product_class_code = "OR"
        self.treatment_type_code = "PRE_HARVEST"
      else
        self.treatment_type_code = "PACKHOUSE"
      end

           #self.size_code = "UNS" if !self.size_code
      if !self.size_code
          self.size_code = "UNS" 
	  self.size_id = Size.find_by_size_code(self.size_code).id		  
      end
 
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:ripe_point_code => self.ripe_point_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_ripe_point
	 end
	 
	
	if is_valid &&  self.rmt_product_type_code != "orchard_run" &&  self.rmt_product_type_code.to_s.upcase != "PRESORT"
		 is_valid = ModelHelper::Validations.validate_combos([{:size_code => self.size_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid && self.rmt_product_type_code != "orchard_run" &&  self.rmt_product_type_code.to_s.upcase != "PRESORT"
		 is_valid = set_size
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:product_class_code => self.product_class_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_product_class
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:commodity_group_code => self.commodity_group_code},{:commodity_code => self.commodity_code},{:variety_code => self.variety_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_variety
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:treatment_code => self.treatment_code}],self) 
	end
	
	if is_valid && self.rmt_product_type_code != "orchard_run" &&  self.rmt_product_type_code.to_s.upcase != "PRESORT"
		 is_valid = ModelHelper::Validations.validate_combos([{:bin_type => self.bin_type}],self) 
	end
	
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_treatment
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end
 

def validate_uniqueness
 
  if self.rmt_product_type_code == "orchard_run"||self.rmt_product_type_code.to_s.upcase == "PRESORT"
	 exists = RmtProduct.find_by_commodity_group_code_and_commodity_code_and_variety_code_and_size_code_and_product_class_code_and_ripe_point_code_and_treatment_code(self.commodity_group_code,self.commodity_code,self.variety_code,self.size_code,self.product_class_code,self.ripe_point_code,self.treatment_code)
     errors.add_to_base("There already exists a record with the combined values of fields: 'commodity_group_code' and 'commodity_code' and 'variety_code' and 'size_code' and 'product_class_code' and 'ripe_point_code' and 'treatment_code' ")if exists
  else
                                      
     exists = RmtProduct.find_by_commodity_group_code_and_commodity_code_and_variety_code_and_size_code_and_product_class_code_and_ripe_point_code_and_treatment_code_and_bin_type(self.commodity_group_code,self.commodity_code,self.variety_code,self.size_code,self.product_class_code,self.ripe_point_code,self.treatment_code,self.bin_type)
     errors.add_to_base("There already exists a record with the combined values of fields: 'commodity_group_code' and 'commodity_code' and 'variety_code' and 'size_code' and 'product_class_code' and 'ripe_point_code' and 'treatment_code' and 'bin_type' ") if exists
  end
 
end


  def RmtProduct.create_if_needed(type_code,commodity_group_code,commodity_code,variety_code,size_code,class_code,ripe_point_code,treatment_code,bin_type = nil)
    
    if type_code == "orchard_run"
      class_code = "OR"
      rmt_product = RmtProduct.find_by_commodity_group_code_and_commodity_code_and_variety_code_and_size_code_and_product_class_code_and_ripe_point_code_and_treatment_code(commodity_group_code,commodity_code,variety_code,size_code,class_code,ripe_point_code,treatment_code)
    elsif type_code.to_s.upcase == "PRESORT"
      rmt_product = RmtProduct.find_by_commodity_group_code_and_commodity_code_and_variety_code_and_size_code_and_product_class_code_and_ripe_point_code_and_treatment_code(commodity_group_code,commodity_code,variety_code,size_code,class_code,ripe_point_code,treatment_code)
         
    else
      
      rmt_product = RmtProduct.find_by_commodity_group_code_and_commodity_code_and_variety_code_and_size_code_and_product_class_code_and_ripe_point_code_and_treatment_code_and_bin_type(commodity_group_code,commodity_code,variety_code,size_code,class_code,ripe_point_code,treatment_code,bin_type)
    end
    
    if !rmt_product
    
      rmt_product = RmtProduct.new
      rmt_product.commodity_group_code = commodity_group_code
      rmt_product.commodity_code = commodity_code
      rmt_product.variety_code = variety_code
      rmt_product.rmt_product_type_code = type_code
      rmt_product.size_code = size_code
      rmt_product.size_id = Size.find_by_size_code(size_code).id		      
      rmt_product.product_class_code = class_code
      rmt_product.ripe_point_code = ripe_point_code
      rmt_product.treatment_code = treatment_code
      rmt_product.bin_type = bin_type
      rmt_product.bin_type = "KROMC" if type_code == "rebin" && (!bin_type ||bin_type == "")
      if !rmt_product.save
        raise "Rmt product creation failed: " + rmt_product.errors.full_messages.to_s
      end
      
    end
    
    return rmt_product

  end
  
  
#	===========================
#	 foreign key validations:
#	===========================
def set_variety
   
   if self.rmt_product_type_code == "orchard_run"
	variety = Variety.find_by_commodity_group_code_and_commodity_code_and_rmt_variety_code(self.commodity_group_code,self.commodity_code,self.variety_code)
	 if variety != nil 
		 self.variety = variety
		 return true
	 else
		errors.add_to_base("combination of: 'commodity_group_code' and 'commodity_code' and 'variety_code'  is invalid- not found in database")
		 return false
	 end
   elsif self.rmt_product_type_code.to_s.upcase == "PRESORT"
	variety = Variety.find_by_commodity_group_code_and_commodity_code_and_rmt_variety_code(self.commodity_group_code,self.commodity_code,self.variety_code)
	 if variety != nil 
		 self.variety = variety
		 return true
	 else
		errors.add_to_base("combination of: 'commodity_group_code' and 'commodity_code' and 'variety_code'  is invalid- not found in database")
		 return false
	end
	 
  else
   
    variety = Variety.find_by_commodity_group_code_and_commodity_code_and_marketing_variety_code(self.commodity_group_code,self.commodity_code,self.variety_code)
	 if variety != nil 
		 self.variety = variety
		 return true
	 else
		errors.add_to_base("combination of: 'commodity_group_code' and 'commodity_code' and 'variety_code'  is invalid- not found in database")
		 return false
	end
  end
end
 
def set_size
    
    puts self.size_code.to_s
	size = Size.find_by_size_code(self.size_code)
	 if size != nil 
		 self.size = size
		 return true
	 else
		errors.add_to_base("'size_code' is invalid- not found in database")
		 return false
	end
end
 
def set_treatment
    puts self.treatment_type_code
	treatment = Treatment.find_by_treatment_code_and_treatment_type_code(self.treatment_code,self.treatment_type_code)
	 if treatment != nil 
		 self.treatment = treatment
		 return true
	 else
		errors.add_to_base("'treatment_code' is invalid- not found in database")
		 return false
	end
end
 
def set_ripe_point

	ripe_point = RipePoint.find_by_ripe_point_code(self.ripe_point_code)
	 if ripe_point != nil 
		 self.ripe_point = ripe_point
		 return true
	 else
		errors.add_to_base("'ripe_point_code' is invalid- not found in database")
		 return false
	end
end
 
def set_product_class
   
	product_class = ProductClass.find_by_product_class_code(self.product_class_code)
	 if product_class != nil 
		 self.product_class = product_class
		 return true
	 else
		errors.add_to_base("'product_class_code' is invalid- not found in database")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: variety_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_commodity_group_codes

	commodity_group_codes = Variety.find_by_sql('select distinct commodity_group_code from varieties').map{|g|[g.commodity_group_code]}
end



def self.get_all_commodity_codes

	commodity_codes = Variety.find_by_sql('select distinct commodity_code from varieties').map{|g|[g.commodity_code]}
end



def self.commodity_codes_for_commodity_group_code(commodity_group_code)

	commodity_codes = Variety.find_by_sql("Select distinct commodity_code from varieties where commodity_group_code = '#{commodity_group_code}'").map{|g|[g.commodity_code]}

	commodity_codes.unshift("<empty>")
 end



def self.get_all_variety_codes

	variety_codes = Variety.find_by_sql('select distinct variety_code from varieties').map{|g|[g.variety_code]}
end



def self.variety_codes_for_commodity_code_and_commodity_group_code(commodity_code, commodity_group_code)

	variety_codes = Variety.find_by_sql("Select distinct variety_code from varieties where commodity_code = '#{commodity_code}' and commodity_group_code = '#{commodity_group_code}'").map{|g|[g.variety_code]}

	variety_codes.unshift("<empty>")
 end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: size_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_size_codes

	size_codes = Size.find_by_sql('select distinct size_code from sizes').map{|g|[g.size_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: treatment_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_treatment_codes

	treatment_codes = Treatment.find_by_sql('select distinct treatment_code from treatments').map{|g|[g.treatment_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: ripe_point_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_ripe_point_codes

	ripe_point_codes = RipePoint.find_by_sql('select distinct ripe_point_code from ripe_points').map{|g|[g.ripe_point_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: product_class_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_product_class_codes

	product_class_codes = ProductClass.find_by_sql('select distinct product_class_code from product_classes').map{|g|[g.product_class_code]}
end






end
