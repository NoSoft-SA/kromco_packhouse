# To change this template, choose Tools | Templates
# and open the template in the editor.

module InventoryFacade::FacadeTestHelper
  def build_find_pdt_program_form(program,action,caption)
    field_configs = Array.new
    field_configs << {:field_type => 'TextField',
                :field_name => 'display_name'}

    field_configs << {:field_type => 'TextField',
                :field_name => 'class_name'}

    build_form(program,field_configs,action,'program',caption,nil)
  end

  def build_pdt_program_grid(data_set)
    column_configs = Array.new
    column_configs << {:field_type => 'text',:field_name => 'program_name'}
    column_configs << {:field_type => 'text',:field_name => 'display_name'}
    column_configs << {:field_type => 'text',:field_name => 'class_name'}

  #	----------------------
  #	define action columns
  #	----------------------
#      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view',
#        :settings =>
#           {:link_text => 'view',
#          :target_action => 'view_pdt_program',
#          :id_column => 'program_name'}}

   return get_data_grid(data_set,column_configs)
  end

  def build_create_stock_from(stock,action,caption)
    #	---------------------------------
    #	 Define fields to build form from
    #	---------------------------------
      field_configs = Array.new

      field_configs[field_configs.length] = {:field_type => 'TextField',
                :field_name => 'owner_party_role_id'}

      field_configs[field_configs.length] = {:field_type => 'TextField',
                :field_name => 'stock_tpe'}

      field_configs[field_configs.length] = {:field_type => 'TextField',
                :field_name => 'farm_code'}

      field_configs[field_configs.length] = {:field_type => 'TextField',
                :field_name => 'truck_code'}

      field_configs[field_configs.length] = {:field_type => 'TextField',
                :field_name => 'trans_name'}

      field_configs[field_configs.length] = {:field_type => 'TextField',
                :field_name => 'trans_id'}

      field_configs[field_configs.length] = {:field_type => 'TextField',
                :field_name => 'location'}

      field_configs[field_configs.length] = {:field_type => 'TextField',
                :field_name => 'stock_ids'}


      build_form(stock,field_configs,action,'stock',caption,nil)
  end

  def build_move_stock_from(stock,action,caption)
    transaction_business_names = TransactionBusinessName.find(:all).map{|b|[b.transaction_business_name_code]}
    #	---------------------------------
    #	 Define fields to build form from
    #	---------------------------------
      field_configs = Array.new

      field_configs[field_configs.length] = {:field_type => 'DropDownField',
                :field_name => 'trans_name',
                :settings => {:list=>transaction_business_names}}

      field_configs[field_configs.length] = {:field_type => 'TextField',
                :field_name => 'trans_id'}

      field_configs[field_configs.length] = {:field_type => 'TextField',
                :field_name => 'location_to'}

      field_configs[field_configs.length] = {:field_type => 'TextField',
                :field_name => 'stock_ids'}

      build_form(stock,field_configs,action,'stock',caption,nil)
  end

  def build_undo_stock_from(stock,action,caption)
    #	---------------------------------
    #	 Define fields to build form from
    #	---------------------------------
      field_configs = Array.new

      field_configs[field_configs.length] = {:field_type => 'TextField',
                :field_name => 'reference_number'}

      field_configs[field_configs.length] = {:field_type => 'TextField',
                :field_name => 'transaction_business_name'}

      field_configs[field_configs.length] = {:field_type => 'TextField',
                :field_name => 'stock_ids'}

      build_form(stock,field_configs,action,'stock',caption,nil)
  end

  def build_remove_stock_from(stock,action,caption)
    #	---------------------------------
    #	 Define fields to build form from
    #	---------------------------------
      field_configs = Array.new

      field_configs[field_configs.length] = {:field_type => 'TextField',
                :field_name => 'truck_code'}

      field_configs[field_configs.length] = {:field_type => 'TextField',
                :field_name => 'stock_type'}

      field_configs[field_configs.length] = {:field_type => 'TextField',
                :field_name => 'trans_name'}

      field_configs[field_configs.length] = {:field_type => 'TextField',
                :field_name => 'trans_id'}

      field_configs[field_configs.length] = {:field_type => 'TextField',
                :field_name => 'location'}

      field_configs[field_configs.length] = {:field_type => 'TextField',
                :field_name => 'stock_ids'}


      build_form(stock,field_configs,action,'stock',caption,nil)
  end

  def build_undo_remove_stock_from(stock,action,caption)
    #	---------------------------------
    #	 Define fields to build form from
    #	---------------------------------
      field_configs = Array.new

      field_configs[field_configs.length] = {:field_type => 'TextField',
                :field_name => 'trans_name'}

      field_configs[field_configs.length] = {:field_type => 'TextField',
                :field_name => 'reference_number'}

      field_configs[field_configs.length] = {:field_type => 'TextField',
                :field_name => 'stock_ids'}


      build_form(stock,field_configs,action,'stock',caption,nil)
  end
end
