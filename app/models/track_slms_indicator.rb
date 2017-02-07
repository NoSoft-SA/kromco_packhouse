class TrackSlmsIndicator < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :variety
	belongs_to :commodity
	belongs_to :season
	belongs_to :track_indicator_type
    belongs_to :rmt_product
#	============================
#	 Validations declarations: 
#	============================
	validates_presence_of :track_slms_indicator_code
  validates_uniqueness_of :track_slms_indicator_code
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:commodity_group_code => self.commodity_group_code},{:commodity_code => self.commodity_code},{:rmt_variety_code => self.rmt_variety_code},{:marketing_variety_code => self.marketing_variety_code}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:commodity_code => self.commodity_code},{:rmt_variety_code => self.rmt_variety_code},{:marketing_variety_code => self.marketing_variety_code}],self)
#	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_variety
	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:commodity_code => self.commodity_code}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_commodity
	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:season_code => self.season_code},{:commodity_code => self.commodity_code}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_season
	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:track_indicator_type_code => self.track_indicator_type_code}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_track_indicator_type
	 end
end

  def after_create
    begin
    if(self.commodity_code.to_s.upcase=='AP')
      http = Net::HTTP.new(Globals.bin_scanned_mssql_server_host, Globals.bin_created_mssql_presort_server_port)
      request = Net::HTTP::Post.new("/exec")
      parameters = {'method' => 'insert', 'statement' => Base64.encode64("INSERT INTO [productionv50].[dbo].[Clone] ([Code_clone],[Code_variete],[Nom_clone]) VALUES('#{self.track_slms_indicator_code}','#{self.track_slms_indicator_code}','#{self.track_slms_indicator_description}')")}
      request.set_form_data(parameters)
      response = http.request(request)

      if response.code != '200'
        err = response.body.split('</message>').first.split('<message>').last
        errmsg = " \"NSERT INTO [productionv50].[dbo].[Clone]\". The http code is #{response.code}. Message: #{err}."
        raise errmsg
      end
    end 
    rescue
      raise "SQL MF Automatic Integration returned an error: #{$!.message}"
    end
  end

#	===========================
#	 foreign key validations:
#	===========================
def set_variety
  if(self.variety_type=="rmt_variety") && self.marketing_variety_code
    variety = Variety.find_by_rmt_variety_code_and_marketing_variety_code(self.rmt_variety_code,self.marketing_variety_code)
    if(!variety)
   		errors.add_to_base("combination of: 'rmt_variety_code[#{self.rmt_variety_code}]' and 'marketing_variety_code[#{self.marketing_variety_code}]'  not found in varieties")
       return false
    end
  elsif(self.variety_type=="marketing_variety")
    variety = Variety.find_all_by_marketing_variety_code(self.marketing_variety_code)[0]
    if(!variety)
      errors.add_to_base("'marketing_variety_code[#{self.marketing_variety_code}]' not found in varieties")
       return false
    end
    self.rmt_variety_code = variety.rmt_variety_code
  end

  self.variety = variety
  return true
end
 
def set_commodity
	commodity = Commodity.find_by_commodity_code(self.commodity_code)
	 if commodity != nil 
		 self.commodity = commodity
   end
  return true
#		 return true
#	 else
#		errors.add_to_base("'commodity_code' not found in commodities")
#		 return false
#	end
end

  
def set_season
  season = Season.find_by_season_code(self.season_code)
	 if season != nil 
		 self.season = season
   end
  return true
#	 else
#    errors.add_to_base("'season_code not found in season")
#		 return false
#	end
end
 
def set_track_indicator_type
	track_indicator_type = TrackIndicatorType.find_by_track_indicator_type_code(self.track_indicator_type_code)
	 if track_indicator_type != nil 
		 self.track_indicator_type = track_indicator_type
   end
	 return true
#	 else
#		errors.add_to_base(" 'track_indicator_type_code'  not found in track_indicator_types")
#		 return false
#	end
end
 
#	===========================
#	 lookup methods:
#	===========================
def TrackSlmsIndicator.get_required_marketing_variety_id(marketing_variety_code)
  marketing_variety = MarketingVariety.find_by_marketing_variety_code(marketing_variety_code)
  if(marketing_variety)
    return marketing_variety.id
  end
  return nil
end
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



def self.get_all_rmt_variety_codes

	rmt_variety_codes = Variety.find_by_sql('select distinct rmt_variety_code from varieties').map{|g|[g.rmt_variety_code]}
end



def self.rmt_variety_codes_for_commodity_code_and_commodity_group_code(commodity_code, commodity_group_code)

	rmt_variety_codes = Variety.find_by_sql("Select distinct rmt_variety_code from varieties where commodity_code = '#{commodity_code}' and commodity_group_code = '#{commodity_group_code}'").map{|g|[g.rmt_variety_code]}

	rmt_variety_codes.unshift("<empty>")
 end



def self.get_all_marketing_variety_codes

	marketing_variety_codes = Variety.find_by_sql('select distinct marketing_variety_code from varieties').map{|g|[g.marketing_variety_code]}
end



def self.marketing_variety_codes_for_rmt_variety_code_and_commodity_code_and_commodity_group_code(rmt_variety_code, commodity_code, commodity_group_code)

	marketing_variety_codes = Variety.find_by_sql("Select distinct marketing_variety_code from varieties where rmt_variety_code = '#{rmt_variety_code}' and commodity_code = '#{commodity_code}' and commodity_group_code = '#{commodity_group_code}'").map{|g|[g.marketing_variety_code]}

	marketing_variety_codes.unshift("<empty>")
 end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: commodity_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_commodity_codes

	commodity_codes = Commodity.find_by_sql('select distinct commodity_code from commodities').map{|g|[g.commodity_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: season_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_season_codes

	season_codes = Season.find_by_sql('select distinct season_code from seasons').map{|g|[g.season_code]}
end



def self.get_all_commodity_codes

	commodity_codes = Season.find_by_sql('select distinct commodity_code from seasons').map{|g|[g.commodity_code]}
end



def self.commodity_codes_for_season_code(season_code)

	commodity_codes = Season.find_by_sql("Select distinct commodity_code from seasons where season_code = '#{season_code}'").map{|g|[g.commodity_code]}

	commodity_codes.unshift("<empty>")
 end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: track_indicator_type_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_track_indicator_type_codes

	track_indicator_type_codes = TrackIndicatorType.find_by_sql('select distinct track_indicator_type_code from track_indicator_types').map{|g|[g.track_indicator_type_code]}
end

def set_track_slms_variety
   track_slms_variety = TrackSlmsVariety.find_by_track_slms_indicator_id(self.id)
   if !track_slms_variety
     track_slms_variety = TrackSlmsVariety.new
     track_slms_variety.track_slms_indicator_id = self.id
   end

   track_slms_variety.rmt_variety_id = self.variety.id
   track_slms_variety.marketing_variety_id = TrackSlmsIndicator.get_required_marketing_variety_id(self.marketing_variety_code)
   track_slms_variety.season_id = self.season.id
   track_slms_variety.track_indicator_type_id = self.track_indicator_type.id
   track_slms_variety.save
end

#MM012017
# Best approach is to define an instance method on track_slms_indicators called: 'find_starch_ripeness_indicator(opt_cat_count, pre_opt_cat_count, post_opt_cat_count)
# {
# input: the amounts of fruit that falls into the 3 ripeness categories
# processing: find all the 'starch_ripeness_indicator_match_rule' records for the track-indicator's rmt-variety
# Every record consists of 3 rules or range expressions, one for each ripeness category. Every expression must be evaluated for the
# passed-in matching ripeness category. E.g. if the passed-in quantity for the opt_cat_count is 4, and the expression for same
# category is: < 1 & < 5, then the rule passes/matches. If all 3 expressions are true for their passed-in quantities, then the rule
# record is a match. If a rule record is a match, and no other rule records are matches, then return the matching rule record's
# match_ripess_indicator (which is a trck-slms-indicator record id)
# If no matches are found, or more than one, return an appropriate error message (include details)
#
# }

  def self.find_starch_ripeness_indicator(opt_cat_count, pre_opt_cat_count, post_opt_cat_count,rmt_variety_id)
    x = pre_opt_cat_count
    y = opt_cat_count
    z = post_opt_cat_count
    matched_rules = []
    indicator_match_rules = StarchRipenessIndicatorMatchRule.find_by_sql("select * from starch_ripeness_indicator_match_rules where rmt_variety_id =  #{rmt_variety_id}")
    indicator_match_rules.each do |match_rule|
      matched_rules.push(match_rule.match_ripeness_indicator_id) if eval(match_rule.pre_opt_cat_count) && eval(match_rule.opt_cat_count) && eval(match_rule.post_opt_cat_count)
    end
    check_matched_rules(matched_rules)
  end

  def self.check_matched_rules(matched_rules)
    case matched_rules.length
      when 0
        starch_ripeness_indicator = "Track_slms_indicator passed-in quantities entered failed to match any starch_ripeness_indicator_match_rules <br> Please notify the System Administrator"
      when 1
        starch_ripeness_indicator = matched_rules[0]
      else
        starch_ripeness_indicator = "Track_slms_indicator passed-in quantities entered returned more than 1 matched starch_ripeness_indicator_match_rules <br> "
    end
    return starch_ripeness_indicator
  end

end

