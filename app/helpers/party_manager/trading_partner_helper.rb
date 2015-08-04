module PartyManager::TradingPartnerHelper
 
 
 def build_trading_partner_form(trading_partner,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:trading_partner_form]= Hash.new
	incoterm_codes = Incoterm.find_by_sql('select distinct(incoterm_code) ,id from incoterms order by incoterm_code desc').map{|g|[g.incoterm_code,g.id]}
	incoterm_codes.unshift("<empty>")
	currency_codes = Currency.find_by_sql('select distinct currency_code ,id from currencies order by currency_code desc').map{|g|[g.currency_code,g.id]}
	currency_codes.unshift("<empty>")
	target_market_codes = TargetMarket.find_by_sql('select distinct id,target_market_code from target_markets order by target_market_code desc ').map{|g|[g.target_market_code,g.id]}
	target_market_codes.unshift("<empty>")
  marketers=User.find_by_sql("select id,users.user_name from users where department_name='Marketing' order by user_name desc").map{|g|[g.user_name,g.id]}
  marketers.unshift("<empty>")
  dfpt_levy_type_codes = DfptLevyType.find_by_sql('select distinct id,dfpt_levy_type_code from dfpt_levy_types order by dfpt_levy_type_code desc').map{|g|[g.dfpt_levy_type_code,g.id]}
  dfpt_levy_type_codes.unshift("<empty>")
  if trading_partner
    if trading_partner.parties_role_id
      parties_role = PartiesRole.find(trading_partner.parties_role_id)
      supplier_party_types = [parties_role.party_type_name]
      supplier_party_types.delete("<empty>")
    else
      supplier_party_types =[['ORGANIZATION'],['PERSON']]
      supplier_parties_roles = [["choose a value from paty type names code above",nil]]
    end

    else
  supplier_party_types = [['ORGANIZATION'],['PERSON']]
  supplier_parties_roles = [["choose a value from paty type names code above",nil]]
  end


#
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = []
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (parties_role_id) on related table: parties_roles
#	----------------------------------------------------------------------------------------------
    field_configs << {:field_type => 'LabelField',:field_name => 'role',
                          :settings=>{:show_label=>true,:static_value=>'TRADING_PARTNER'}}

    field_configs << {:field_type => 'DropDownField',
        						:field_name => 'party_type_name?required',
        						:settings => {:list => supplier_party_types, :label_caption=>'party type name'}}

    field_configs << {:field_type => 'TextField',
    						:field_name => 'trading_partner_name?required'}

    field_configs << {:field_type => 'TextField',
        						:field_name => 'remarks'}
 
#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (incoterm_id) on related table: incoterms
#	-----------------------------------------------------------------------------------------------------
	field_configs << {:field_type => 'DropDownField',
						:field_name => 'incoterm_id',
						:settings => {:list => incoterm_codes, :label_caption=>'incoterm code'}}

 
#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (currency_id) on related table: currencies
#	-----------------------------------------------------------------------------------------------------
	field_configs << {:field_type => 'DropDownField',
						:field_name => 'currency_id',
						:settings => {:list => currency_codes, :label_caption=>'currency code'}}

 
	field_configs << {:field_type => 'TextField',
						:field_name => 'contact_name'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (target_market_id) on related table: target_markets
#	----------------------------------------------------------------------------------------------
	field_configs << {:field_type => 'DropDownField',
						:field_name => 'target_market_id',
						:settings => {:list => target_market_codes, :label_caption=>'target market code'}}
						
	field_configs << {:field_type => 'DropDownField',
						:field_name => 'dfpt_levy_type_id',
						:settings => {:list => dfpt_levy_type_codes, :label_caption=>'dfpt levy type code'}}						

    field_configs << {:field_type => 'DropDownField',
    						:field_name => 'marketer_user_id',
    						:settings => {:list => marketers, :label_caption=> 'marketer'}
    						}
    field_configs << {:field_type => 'CheckBox',
    						:field_name => 'active'
    						}
	build_form(trading_partner,field_configs,action,'trading_partner',caption,is_edit)

end
 
 
 def build_trading_partner_search_form(trading_partner,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:trading_partner_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["trading_partner_target_market_id"])
	#Observers for search combos
 
	target_market_ids = TradingPartner.find_by_sql('select distinct target_market_id from trading_partners').map{|g|[g.target_market_id]}
	target_market_ids.unshift("<empty>")
	if is_flat_search
	else
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = []
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs << {:field_type => 'DropDownField',
						:field_name => 'target_market_id',
						:settings => {:list => target_market_ids}}
 
	build_form(trading_partner,field_configs,action,'trading_partner',caption,false)

end



 def build_trading_partner_grid(data_set,can_edit,can_delete)

	column_configs = []
  column_configs << {:field_type => 'text',:field_name => 'trading_partner_name',:column_width=> 120}
  column_configs << {:field_type => 'text',:field_name => 'remarks',:column_width=> 125}
  column_configs << {:field_type => 'text',:field_name => 'party'}
  column_configs << {:field_type => 'text',:field_name => 'incoterm_code'}
  column_configs << {:field_type => 'text',:field_name => 'target_market_code'}
  column_configs << {:field_type => 'text',:field_name => 'dfpt_levy_type_code'}  
  column_configs << {:field_type => 'text',:field_name => 'marketer'}
  column_configs << {:field_type => 'text',:field_name => 'contact_name'}
  column_configs << {:field_type => 'text',:field_name => 'active'}

  column_configs << {:field_type => 'text',:field_name => 'id'}

#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs << {:field_type => 'action',:field_name => 'edit trading_partner',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_trading_partner',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs << {:field_type => 'action',:field_name => 'delete trading_partner',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_trading_partner',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs,nil,true)
end

end
