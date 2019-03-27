module PartyManager::CityHelper


  def build_city_form(city,action,caption,is_edit = nil,is_create_retry = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define a set of observers for each composite foreign key- in effect an observer per combo involved
    #  in a composite foreign key
    #  --------------------------------------------------------------------------------------------------
    session[:city_form]= Hash.new
    #country_codes = Country.for_select(:code_and_name)
    country_codes = ActiveRecord::Base.connection.select_all("select id ,country_code from countries where country_code='ZA'").map{|d|[d['country_code'],d['id']]}
        #  ---------------------------------
    #   Define fields to build form from
    #  ---------------------------------
    field_configs = []
    field_configs << {:field_type => 'TextField',
                      :field_name => 'city_code'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'city_name'}

    #  ----------------------------------------------------------------------------------------------------
    #  Combo field to represent foreign key (country_id) on related table: countries
    #  -----------------------------------------------------------------------------------------------------
    field_configs << {:field_type => 'DropDownField',
                      :field_name => 'country_id',
                      :settings => {:list => country_codes, :label_caption => 'country_code'}}


    build_form(city,field_configs,action,'city',caption,is_edit)

  end


  def build_city_search_form(city,action,caption,is_flat_search = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define an observer for each index field
    #  --------------------------------------------------------------------------------------------------
    session[:city_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    #Observers for search combos
    #  ----------------------------------------
    #   Define search fields to build form from
    #  ----------------------------------------
    field_configs = []
    city_codes = City.find_by_sql('select distinct city_code from cities').map{|g|[g.city_code]}
    city_codes.unshift("<empty>")
    field_configs << {:field_type => 'DropDownField',
                      :field_name => 'city_code',
                      :settings => {:list => city_codes}}

    build_form(city,field_configs,action,'city',caption,false)

  end



  def build_city_grid(data_set,can_edit,can_delete)

    column_configs = []
    column_configs << {:field_type => 'text',:field_name => 'city_code'}
    column_configs << {:field_type => 'text',:field_name => 'city_name'}
    column_configs << {:field_type => 'text',:field_name => 'country_code'}
    # column_configs <<  {:field_type => 'text', :field_name => 'active', :data_type => 'boolean',  :col_width => 80, :colour_rules => [[lambda {|a|  a == 'f' || a == false  }, :red]]}

    #  ----------------------
    #  define action columns
    #  ----------------------
    if can_edit
      column_configs << {:field_type => 'action',:field_name => 'edit city',
                         :settings =>
      {:link_text => 'edit',
       :target_action => 'edit_city',
       :id_column => 'id'}}
    end

    if can_delete
      column_configs << {:field_type => 'action',:field_name => 'delete city',
                         :settings =>
      {:link_text => 'delete',
       :target_action => 'delete_city',
       :id_column => 'id'}}
    end
    return get_data_grid(data_set,column_configs)
  end

end
