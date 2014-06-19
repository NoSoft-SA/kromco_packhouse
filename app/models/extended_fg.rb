class ExtendedFg < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 

#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 self.units_per_carton = "*" if !self.units_per_carton ||self.units_per_carton.to_s == "0"
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:fg_code => self.fg_code}],self) 
	 end
	 
	 if is_valid
	   is_valid = ModelHelper::Validations.validate_combos([{:fg_mark_code => self.fg_mark_code}],self) 
	 end
	 
	  is_valid = ModelHelper::Validations.validate_combos([{:marketing_org_code => self.marketing_org_code}],self) 
	
	 
	if is_valid
	  #must be fg_code(with upc quantity inserted before upc part of fg) + org + fg_mark code)
	  puts "MY FG: " + self.fg_code
	  fg_product = FgProduct.find_by_fg_product_code(self.fg_code)
	  new_fg = fg_product.item_pack_product_code + "_" + self.units_per_carton.to_s + fg_product.unit_pack_product_code + "_" + fg_product.carton_pack_product_code
	  self.extended_fg_code = new_fg + "_" + self.marketing_org_code + "_" + self.fg_mark_code
	  puts self.units_per_carton
	  puts "MY ext fg:" + self.extended_fg_code
	  fg_product = FgProduct.find_by_fg_product_code(self.fg_code)
	  self.grade_code = fg_product.item_pack_product.grade_code
	  self.standard_size_count_value = fg_product.item_pack_product.standard_size_count_value
	  self.commodity_code = fg_product.item_pack_product.commodity_code
	
	end
	 
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
	 
	 
end


def ExtendedFg.get_all_by_commodity_and_rmt_variety(commodity,rmt_variety)

   query = "SELECT 
            public.extended_fgs.extended_fg_code
            FROM
            public.item_pack_products
            INNER JOIN public.varieties ON (public.item_pack_products.marketing_variety_id = public.varieties.marketing_variety_id)
            INNER JOIN public.fg_products ON (public.item_pack_products.id = public.fg_products.item_pack_product_id)
            INNER JOIN public.extended_fgs ON (public.fg_products.fg_product_code = public.extended_fgs.fg_code)
            WHERE
            (public.varieties.commodity_code = '#{commodity}') AND 
            (public.varieties.rmt_variety_code = '#{rmt_variety}')"


   return ExtendedFg.find_by_sql(query)


end
 
 def ExtendedFg.create_if_needed(fg_product_code,ext_fg_code,fg_mark_code,units_per_carton,org,old_fg,tu_gross_mass = nil)
   puts "ExtendedFg.create_if_needed called: "
   puts "passed-in ext code is: " + ext_fg_code
   units_per_carton = "*" if ! units_per_carton||units_per_carton.strip == ""
   #record = ExtendedFg.find_by_fg_code_and_fg_mark_code_and_units_per_carton_and_marketing_org_code(fg_product_code,fg_mark_code,units_per_carton,org)
   record = ExtendedFg.find_by_extended_fg_code(ext_fg_code)
   if !record
     record= ExtendedFg.new
     record.fg_code = fg_product_code
     puts "FGC: " + record.fg_code
     record.fg_mark_code = fg_mark_code
     record.units_per_carton = units_per_carton
     record.old_fg_code = old_fg
     record.tu_gross_mass = tu_gross_mass if tu_gross_mass
     record.marketing_org_code = org
     if !record.save
      raise "Extended fg code could not be created. Reason(s): " + record.errors.full_messages.to_s
     end
     puts "new ext fg created."
   else
     puts "passed-in ext fg exists" 
     if tu_gross_mass
       record.tu_gross_mass = tu_gross_mass 
       record.update
     end
     
     
   end
   return record
 end
 

def validate_uniqueness
	 #exists = ExtendedFg.find_by_fg_code_and_fg_mark_code_and_units_per_carton_and_marketing_org_code(self.fg_code,self.fg_mark_code,self.units_per_carton,self.marketing_org_code)
	 
	 exists = ExtendedFg.find_by_extended_fg_code(self.extended_fg_code)
	 if exists != nil 
	    #if the name differs, ignore error: due to historical reasons the '*' system were implemented later
	    if self.extended_fg_code == exists.extended_fg_code
		  errors.add_to_base("There already exists a record with the combined values of fields: 'fg_code' and 'fg_mark_code' and 'units_per_carton' and 'marketing_org_code' ")
	    end
	end
	
	 
	 puts "VV creating new ext fg..."
     puts "VV FG code: " + self.fg_code
     puts "VV FG Mark: " + self.fg_mark_code
     puts "VV units: " + self.units_per_carton.to_s
     puts "VV marketing org: " + self.marketing_org_code
end
#	===========================
#	 foreign key validations:
#	===========================
#	===========================
#	 lookup methods:
#	===========================

def ExtendedFg.get_extended_fg_codes(fg_code_old=nil,item_pack_product_code=nil,organization=nil,carton_mark_code=nil)
  query = "SELECT DISTINCT extended_fgs.extended_fg_code FROM (extended_fgs JOIN fg_marks ON(extended_fgs.fg_mark_code=fg_marks.fg_mark_code) "
  query += " JOIN fg_products ON(extended_fgs.fg_code=fg_products.fg_product_code)) "
  query += " WHERE extended_fgs.old_fg_code"
  if fg_code_old == nil
    query += " LIKE '%' AND fg_products.item_pack_product_code"
  else
    query += "='#{fg_code_old}' AND fg_products.item_pack_product_code"
  end
  if item_pack_product_code == nil
    query += " LIKE '%' AND fg_marks.tu_mark_code"
  else
    if item_pack_product_code.to_s != ""
      query += "='#{item_pack_product_code}' AND fg_marks.tu_mark_code"
    else
      query += " LIKE '%' AND fg_marks.tu_mark_code"
    end
  end
  if carton_mark_code == nil
    query += " LIKE '%' AND extended_fgs.marketing_org_code"
  else
    if carton_mark_code.to_s != ""
      query +="='#{carton_mark_code}' AND extended_fgs.marketing_org_code"
    else
      query += " LIKE '%' AND extended_fgs.marketing_org_code"
    end
  end
  if organization == nil
    query += " LIKE '%'"
  else
    query += "='#{organization}'"
  end

  puts query

  result_set = ActiveRecord::Base.connection.select_all(query)
  extended_fg_codes = Array.new
  if result_set.length != 0
    result_set.each do |record|
      extended_fg_codes.push record["extended_fg_code"]
    end
  end
  extended_fg_codes.unshift("<empty>")
  return extended_fg_codes
end


end
