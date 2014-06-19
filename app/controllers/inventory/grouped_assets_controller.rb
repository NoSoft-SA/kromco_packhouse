class Inventory::GroupedAssetsController < ApplicationController

  def program_name?
    "grouped_assets"
  end

  def bypass_generic_security?
    true
  end

#===================================
#===================================
#== Start of the Bin control app  ==
#===================================
#===================================
  def new_asset_class
    session[:current_asset_item] = nil
#    session[:current_asset_location_code] = nil
    session[:query]              = nil
    @is_edit                     = false
    @content_header_caption      = "'create new asset class'"
    @action                      = 'create_asset_item'
    @caption                     = 'create_asset_item'
    render_new_asset_class
  end

  def render_new_asset_class
    puts "@is_edit = " + @is_edit.to_s
    render :inline=>%{
      <%= build_asset_item_form(@asset_item,@action,@caption,@is_edit) %>
    }, :layout=>'content'
  end

  def edit_asset_class
    @asset_item                  = AssetItem.find(params[:id])
    session[:current_asset_item] = params[:id]
    render_edit_asset_class
  end

  def render_edit_asset_class
    @content_header_caption = "'edit new asset class'"
    @is_edit                = true
    @action                 = 'edit_asset_item'
    @caption                = 'edit_asset_item'
    @asset_item.set_virtual_attributes
    render_new_asset_class
  end

  def asset_item_pack_material_type_code_combo_changed
    pack_material_type_code                                             = get_selected_combo_value(params)
    session[:asset_item_form][:pack_material_type_code_combo_selection] = pack_material_type_code
    @pack_material_sub_type_codes                                       = PackMaterialSubType.find_by_sql("select pack_material_subtype_code	from pack_material_sub_types join pack_material_types on pack_material_sub_types.pack_material_type_id = pack_material_types.id	where pack_material_types.pack_material_type_code = '#{pack_material_type_code}'").map { |g| [g.pack_material_subtype_code] }
    @pack_material_sub_type_codes.unshift("<empty>")
    render :inline=>%{
      <%=select('asset_item','pack_material_sub_type_code',@pack_material_sub_type_codes) %>
      <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_asset_item_pack_material_sub_type_code'/>
      <%= observe_field('asset_item_pack_material_sub_type_code', :update=>'ownership_cell', :url=>{:action=>session[:asset_item_form][:pack_material_sub_type_code_observer][:remote_method]}, :loading=>"show_element('img_asset_item_pack_material_sub_type_code');", :complete=>session[:asset_item_form][:pack_material_sub_type_code_observer][:on_completed_js]) %>
    }
  end

  def asset_item_pack_material_subtype_code_changed
    pack_material_sub_type_code                                             = get_selected_combo_value(params)
    session[:asset_item_form][:pack_material_sub_type_code_combo_selection] = pack_material_sub_type_code
    @ownership_codes                                                        = PackMaterialProduct.find_by_sql("select distinct ownership from pack_material_products where pack_material_type_code = '#{session[:asset_item_form][:pack_material_type_code_combo_selection]}' and pack_material_sub_type_code = '#{session[:asset_item_form][:pack_material_sub_type_code_combo_selection]}'").map { |g| [g.ownership] }
    @ownership_codes.unshift("<empty>")

    @pack_material_product_codes = PackMaterialProduct.find_by_sql("select pack_material_product_code from pack_material_products where pack_material_type_code = '#{session[:asset_item_form][:pack_material_type_code_combo_selection]}' and pack_material_sub_type_code = '#{pack_material_sub_type_code}'").map { |g| [g.pack_material_product_code] }
    @pack_material_product_codes = ["<empty>"] if @pack_material_product_codes.length == 0
    render :inline=>%{<%=select('asset_item','ownership',@ownership_codes) %>
                       <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_asset_item_ownership'/>
                       <%= observe_field('asset_item_ownership', :update=>'pack_material_product_code_cell', :url=>{:action=>session[:asset_item_form][:ownership_observer][:remote_method]}, :loading=>"show_element('img_asset_item_ownership');", :complete=>session[:asset_item_form][:ownership_observer][:on_completed_js]) %>

                       <script>
                           <%= update_element_function(
                            "pack_material_product_code_cell", :action => :update,
                            :content => select('asset_item','pack_material_product_code',@pack_material_product_codes))%>
                       </script>
    }
  end

  def asset_item_ownership_changed
    ownership                                             = get_selected_combo_value(params)
    session[:asset_item_form][:ownership_combo_selection] = ownership
    puts "session[:asset_item_form][:pack_material_type_code_combo_selection] = " + session[:asset_item_form][:pack_material_type_code_combo_selection].to_s
    puts "session[:asset_item_form][:pack_material_sub_type_code_combo_selection] = " + session[:asset_item_form][:pack_material_sub_type_code_combo_selection].to_s
    @pack_material_product_codes = PackMaterialProduct.find_by_sql("select pack_material_product_code from pack_material_products where pack_material_type_code = '#{session[:asset_item_form][:pack_material_type_code_combo_selection]}' and pack_material_sub_type_code = '#{session[:asset_item_form][:pack_material_sub_type_code_combo_selection]}' and ownership = '#{ownership}'").map { |g| [g.pack_material_product_code] }
    @pack_material_product_codes = ["<empty>"] if @pack_material_product_codes.length == 0
    render :inline=>%{<%=select('asset_item','pack_material_product_code',@pack_material_product_codes) %>

    }
  end

  def asset_item_owner_type_changed
    owner_type                                             = get_selected_combo_value(params)
    session[:asset_item_form][:owner_type_combo_selection] = owner_type
    @owners                                                = PartiesRole.find_by_sql("select party_name from parties_roles where party_type_name='#{owner_type}' and role_name='ASSET_OWNER'").map { |g| [g.party_name] } #and role_name='ASSET_OWNER'
    render :inline=>%{<%=select('asset_item','owner',@owners) %>}
  end

  def create_asset_item
    if (params[:asset_item][:pack_material_type_code] == "" || params[:asset_item][:pack_material_type_code] == nil)
      validations_error = "Validation failed: pack_material_type_code can't be blank "
    elsif (params[:asset_item][:pack_material_sub_type_code] == "" || params[:asset_item][:pack_material_sub_type_code] == nil)
      validations_error = "Validation failed: pack_material_sub_type_code can't be blank  "
    elsif (params[:asset_item][:pack_material_product_code] == "" || params[:asset_item][:pack_material_product_code] == nil)
      validations_error = "Validation failed: pack_material_product_code can't be blank "
    elsif (params[:asset_item][:owner_type] == "" || params[:asset_item][:owner_type] == nil)
      validations_error = "Validation failed: owner_type can't be blank "
    elsif (params[:asset_item][:owner] == "" || params[:asset_item][:owner] == nil)
      validations_error = "Validation failed: owner can't be blank"
    end

    if (validations_error != nil)
      throw_validation_error(validations_error)
    else
      asset_items = AssetItem.find_by_sql("select * from asset_items where inventory_reference='#{params[:asset_item][:pack_material_product_code]}'")
      if asset_items.length > 0
        flash[:notice] = "record cannot be save: there already exist an asset with reference = '#{params[:asset_item][:pack_material_product_code]}'"
        new_asset_class
      end

      #	----------------------
      #	 Define lookup fields
      #	----------------------
      transaction_type          = TransactionType.find_by_transaction_type_code('create_asset_class')
      transaction_business_name = TransactionBusinessName.find_by_transaction_business_name_code('ASSET_MAINTENANCE')
      reference_number          = MesControlFile.next_seq_web(MesControlFile.const_get("ASSET_TRANS_NUM"))
      pack_material_product     = PackMaterialProduct.find_by_pack_material_product_code(params[:asset_item][:pack_material_product_code])
      owner_party_role          = PartiesRole.find_by_party_type_name_and_party_name_and_role_name(params[:asset_item][:owner_type], params[:asset_item][:owner], 'ASSET_OWNER')

      inventory_transaction     = InventoryTransaction.new({:transaction_type_code         =>transaction_type.transaction_type_code,
                                                            :transaction_business_name_code=>transaction_business_name.transaction_business_name_code, :transaction_date_time=>Time.now.to_formatted_s(:db),
                                                            :transaction_type_id           =>transaction_type.id, :reference_number=>reference_number,
                                                            :transaction_business_name_id  =>transaction_business_name.id}) #:location_to=>location_code,

      asset_type                = AssetType.new({:asset_type_code         =>'GROUPED', :pack_material_product_code=>params[:asset_item][:pack_material_product_code],
                                                 :pack_material_product_id=>pack_material_product.id, :created_on=>Time.now.to_formatted_s(:db)})

      ActiveRecord::Base.transaction do
        asset_type.save!

        @asset_item                           = AssetItem.new({:parties_role_id  =>owner_party_role.id, :asset_type_id=>asset_type.id, :party_name=>owner_party_role.party_name,
                                                               :parties_role_name=>owner_party_role.role_name, :inventory_reference=>reference_number, :asset_number=>params[:asset_item][:pack_material_product_code],
                                                               :location_code    =>session[:current_asset_location_code]})

        session[:current_asset_location_code] = nil

        Inventory::CreateAssetClass.new(@asset_item, inventory_transaction).process

#        DONE INTERNALLY INT THE LINE ABOVE i.e. asset_item & asset_location WILL BE CREATED IN THE SAME 
#        if(session[:location_item_inventory_transaction] != nil)
#        #      Inventory::CreateNewLocation(session[:location_item_inventory_transaction],asset_item).process
#          session[:location_item_inventory_transaction] = nil
#        end        
      end
      session[:current_asset_location_code] = nil
      session[:current_asset_item] = @asset_item.id
      render_edit_asset_class
    end
  end

  def delete_asset_location
    #	----------------------
    #	 Define lookup fields
    #	----------------------
#    session[:current_asset_location_code] = Location.find(params[:location][:location_code]).location_code
    asset_location = AssetLocation.find(params[:id])
    location = Location.find(asset_location.location_id)
    transaction_type                      = TransactionType.find_by_transaction_type_code('delete_asset_location')
    transaction_business_name             = TransactionBusinessName.find_by_transaction_business_name_code('ASSET_MAINTENANCE')
    reference_number                      = MesControlFile.next_seq_web(MesControlFile.const_get("ASSET_TRANS_NUM"))#[2011] - Hans

    inventory_transaction                   = InventoryTransaction.new({:transaction_type_code         =>transaction_type.transaction_type_code, :transaction_type_id=>transaction_type.id,
                                                                        :transaction_business_name_code=>transaction_business_name.transaction_business_name_code, :transaction_business_name_id=>transaction_business_name.id,
                                                                        :location_from                   =>location.location_code, #:transaction_quantity_plus=>nil,
                                                                        :transaction_date_time         =>Time.now.to_formatted_s(:db), :reference_number=>reference_number
                                                                       })#[2011] - Hans

    asset_item                              = AssetItem.find(session[:current_asset_item])
    asset_item.location_code = location.location_code
    Inventory::DeleteAssetLocation.new(asset_item,inventory_transaction).process
    session[:alert] = "asset location deleted successfully"
    render :inline=>%{
          <script>
            window.opener.frames[1].location.href = '/inventory/grouped_assets/edit_asset_class/<%=session[:current_asset_item]%>';
            window.close();
          </script>
        }
  end
  def create_asset_location
    session[:current_asset_item] = params[:id] if params[:id]
    render :inline=>%{<%= build_asset_location_form(@location,'add_location_to_asset','add')%>}, :layout=>'content'
  end

  def add_location_to_asset
#    puts "params[:location][:location_code].to_s = " + params[:location][:location_code].to_s
#    if ((asset_locn = AssetLocation.find_by_location_id(params[:location][:location_code]) != nil))
    if ((asset_locn = AssetLocation.find_by_location_id_and_asset_item_id(params[:location][:location_code],params[:id]) != nil))#[2011]
      render :inline=>%{
          <script>
            alert('this location already exist for this location');
            window.close();
          </script>
        }
      return
    end

    #	----------------------
    #	 Define lookup fields
    #	----------------------
#    location = Location.find(params[:location][:location_code])
    session[:current_asset_location_code] = Location.find(params[:location][:location_code]).location_code
    transaction_type                      = TransactionType.find_by_transaction_type_code('create_asset_location')
    transaction_business_name             = TransactionBusinessName.find_by_transaction_business_name_code('ASSET_MAINTENANCE')
    reference_number                      = MesControlFile.next_seq_web(MesControlFile.const_get("ASSET_TRANS_NUM"))

    inventory_transaction                 = InventoryTransaction.new({:transaction_type_code         =>transaction_type.transaction_type_code,
                                                                      :transaction_business_name_code=>transaction_business_name.transaction_business_name_code, :transaction_date_time=>Time.now.to_formatted_s(:db),
                                                                      :transaction_type_id           =>transaction_type.id, :reference_number=>reference_number,
                                                                      :transaction_business_name_id  =>transaction_business_name.id}) #:location_to=>location.location_code,

    if (session[:current_asset_item] != nil)
      asset_item               = AssetItem.find(session[:current_asset_item])
      asset_item.location_code = session[:current_asset_location_code] #HANS - used by inv_model to create asset_locn...set_location()
      Inventory::AssetClassNewLocation.new(asset_item, inventory_transaction).process
      render :inline=>%{
          <script>
            window.opener.frames[0].location.reload(true);
            window.close();
          </script>
        }
      return
    else
      render :inline=>%{
          <script>
            window.close();
          </script>
        }
      return
    end

  end

  def build_error_div(validations_error)
    valication_error_container = "
        <table id='validation_error_container' border='0' style='background: whitesmoke;font-family: verdana;font-size: 12px;border-collapse: collapse;width: 100%;height: 100px;width: 500px;border: red solid 2px;'>
          <tr style='font-weight: bold;color: white;height: 25px;background: #CC3333;'>
            <td> 1 error prohibited this record from being saved</td>
          </tr>
          <tr style='height: 10px;'>
            <td>&nbsp;&nbsp;&nbsp;There were problems with the following fields</td>
          </tr>
          <tr style='height: 75px;'>
            <td style='padding-left: 50px;'>
              <li>#{validations_error}</li>
            </td>
          </tr>
        </table>
        <script>
          flash = document.getElementById('validation_error_container').parentNode;
          flash.style.border = 'none';
          flash.style.background = 'white';
        </script>
      "
  end

  def throw_validation_error(validations_error)
    @freeze_flash  = true
    flash[:notice] = build_error_div(validations_error)
    new_asset_class
  end

  def render_asset_locations_grid
    return if authorise_for_web(program_name?, 'read') == false

    if params[:page]!= nil

      session[:asset_locations_page] = params['page']

      list_asset_locations

      return
    else
      session[:asset_locations_page] = nil
    end
#
#    list_query      = "@asset_location_pages = Paginator.new self, AssetLocation.count, @@page_size,@current_page
#	 @locations = Location.find_by_sql(\"select locations.id,locations.location_type_code,locations.location_code,locations.parent_location_code,
#                      locations.units_in_location,locations.location_maximum_units,locations.location_status,
#                      locations.current_job_reference_id,count(asset_locations.location_id) as assets_in_location
#                      from locations
#                      join asset_locations on locations.id = asset_locations.location_id
#                      where asset_locations.asset_item_id = #{params[:id]}
#                      GROUP BY locations.id,locations.location_type_code,locations.location_code,
#                      locations.parent_location_code, locations.units_in_location,
#                      locations.location_maximum_units,locations.location_status,
#                      locations.current_job_reference_id
#                      LIMIT \#\{@asset_location_pages.items_per_page\} OFFSET \#\{@asset_location_pages.current.offset\}\")"
#
    list_query      = "@asset_location_pages = Paginator.new self, AssetLocation.count, @@page_size,@current_page
	 @locations = Location.find_by_sql(\"select locations.id,locations.location_type_code,locations.location_code,locations.parent_location_code,
                      locations.units_in_location,locations.location_maximum_units,locations.location_status,
                      locations.current_job_reference_id,asset_locations.location_quantity as assets_in_location,asset_locations.id as asset_location_id
                      from locations
                      join asset_locations on locations.id = asset_locations.location_id
                      where asset_locations.asset_item_id = #{params[:id]}
                      GROUP BY locations.id,locations.location_type_code,locations.location_code,
                      locations.parent_location_code, locations.units_in_location,
                      locations.location_maximum_units,locations.location_status,
                      locations.current_job_reference_id,asset_locations.location_quantity,asset_locations.id
                      ORDER BY locations.location_code ASC
                      LIMIT \#\{@asset_location_pages.items_per_page\} OFFSET \#\{@asset_location_pages.current.offset\}\")"#[2011]
    session[:query] = list_query
    list_asset_locations
  end

  def list_asset_locations
    @can_edit   = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])
    @current_page = session[:asset_locations_page] if session[:asset_locations_page]
    @current_page = params['page'] if params['page']
    @locations = eval(session[:query]) if !@locations
    @asset_class_id = params[:id]


    render :inline => %{
      <% grid = build_asset_location_grid(@locations,@can_edit,@can_delete)%>
      <% grid.height = '230' %>
      <% grid.caption    = 'asset locations' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>

    }, :layout => 'content'
  end

  def search_asset_classes
    #system "C:\\Documents and Settings\\Luxolo\\Desktop\\KromcoJasperPrinting\\print_report.bat"
    
    return if authorise_for_web(program_name?, 'read')== false

    dm_session[:parameter_fields_values] = nil
    dm_session['se_layout']              = 'content'
    @content_header_caption           = "'search asset classes'"
    dm_session[:redirect]                = true
    build_remote_search_engine_form("search_asset_classes.yml", "submit_asset_classes_search")
  end

  def submit_asset_classes_search
    @asset_classes = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    if (@asset_classes.length > 0)
      render_found_asset_classes
    else
      render :inline => %{
                            <script>
                              alert('no records were found');
                              window.close();
                            </script>
                          }, :layout => 'content'
    end
  end

  def render_found_asset_classes
    @can_edit   = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])

    session[:query] = "@asset_class_pages = Paginator.new self, AssetItem.count, @@page_size,@current_page
                       @asset_classes = AssetItem.find_by_sql(dm_session[:search_engine_query_definition])"
    
        render :inline => %{
         <% grid = build_list_asset_classes_grid(@asset_classes,@can_edit,@can_delete)%>
          <% grid.caption    = '' %>
          <% @header_content = grid.build_grid_data %>

          <%= grid.render_html %>
          <%= grid.render_grid %>
          }, :layout => 'content'


  end

  def search_asset_item_transaction_history
    return if authorise_for_web(program_name?, 'read')== false
    render_search_asset_item_transaction_history
  end


  def render_search_asset_item_transaction_history
    @asset_item = AssetItem.find(params[:id])
    latest_inventory_transaction = InventoryTransaction.find_by_sql("select inventory_transactions.*
      FROM inventory_transactions JOIN inventory_transaction_assets ON inventory_transactions.id = inventory_transaction_assets.inventory_transaction_id
      JOIN asset_items ON asset_items.id=inventory_transaction_assets.asset_item_id
      where asset_items.asset_number='#{@asset_item.asset_number}'
      ORDER BY inventory_transaction_assets.created_on DESC LIMIT 1")[0]

    @transaction_type_codes = TransactionType.find(:all).map{|d| d.transaction_type_code}
    @transaction_type_codes.unshift("")
    @transaction_type_codes.unshift(latest_inventory_transaction.transaction_type_code) if latest_inventory_transaction
    @transaction_business_name_code = latest_inventory_transaction.transaction_business_name_code if latest_inventory_transaction
    @location_codes = Location.find_by_sql("select distinct location_code from asset_locations inner join locations on locations.id = asset_locations.location_id").map{|d| d.location_code}
    @location_codes.unshift(" ")
    render :template =>'inventory/grouped_assets/search_asset_item_transaction_history', :layout => 'content'
  end
  
  def submit_asset_item_transaction_history_search

    if(params['created_on_date_from'].to_s.strip=="" || params['created_on_date_to'].to_s.strip=="")
      flash[:error] = 'created_on value must be filled in completely'
      params[:id] = params[:asset_item_id]
      render_search_asset_item_transaction_history
      return
    end
    
    lower_bound = "'#{params['created_on_date_from']}'"

    upper_bound = "'#{params['created_on_date_to']}'"

    transaction_type_code = "like '%'"
    transaction_type_code = " = '#{params['transaction_type_code']['transaction_type_code']}'" if params['transaction_type_code']['transaction_type_code'].to_s.strip != ""

    transaction_business_name_code = "like '%'"
    transaction_business_name_code = " = '#{params['transaction_business_name_code']}'" if params['transaction_business_name_code'].to_s.strip != ""

    location_code = "like '%'"
    location_code = " = '#{params['location_code']['location_code']}'" if params['location_code']['location_code'].to_s.strip != ""

    asset_number = "like '%'"
    asset_number = " = '#{params['asset_number']}'" if params['asset_number'].to_s.strip != ""

    limit = " limit #{params['limit']} " if params['limit'].to_s.strip != ""

    query = "(select inventory_transaction_assets.asset_number, inventory_transactions.*
            from inventory_transaction_assets, inventory_transactions
            where ((inventory_transaction_assets.asset_number  #{asset_number}) AND
            (inventory_transactions.transaction_date_time BETWEEN #{lower_bound} AND #{upper_bound}) AND
            (inventory_transactions.transaction_type_code #{transaction_type_code} ) AND
            (inventory_transactions.transaction_business_name_code #{transaction_business_name_code} ) AND
            (inventory_transactions.location_to #{location_code} OR inventory_transactions.location_from #{location_code}) AND
            ( inventory_transactions.id = inventory_transaction_assets.inventory_transaction_id))
             #{limit})

            union

            select asset_items.asset_number,inventory_transactions.*
            from inventory_transactions
                JOIN asset_items ON asset_items.inventory_transaction_id=inventory_transactions.id
            where ((asset_items.asset_number #{asset_number}) AND
            (inventory_transactions.transaction_date_time > #{lower_bound} AND inventory_transactions.transaction_date_time < #{upper_bound}) AND
            (inventory_transactions.transaction_type_code #{transaction_type_code} ) AND
            (inventory_transactions.transaction_business_name_code #{transaction_business_name_code} ) AND
            (inventory_transactions.location_to #{location_code} OR inventory_transactions.location_from #{location_code})
            )

"
    session[:query] = "@transaction_history_pages = Paginator.new self, InventoryTransaction.count, @@page_size,@current_page
                       @transaction_histories = InventoryTransaction.find_by_sql(\"#{query}\")"
    
    @transaction_histories = InventoryTransaction.find_by_sql(query)
    submit_transaction_history_search
  end


  def submit_transaction_history_search
#    @transaction_histories = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    if (@transaction_histories.length > 0)
      render_found_transaction_histories
    else
      render :inline => %{
                            <script>
                              alert('no records were found');
                              window.close();
                            </script>
                          }, :layout => 'content'
    end
  end

  def render_found_transaction_histories
    @can_edit   = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])


        render :inline => %{
         <% grid = build_list_transaction_histories_grid(@transaction_histories,@can_edit,@can_delete)%>
        <% grid.caption    = 'found transactions' %>
        <% @header_content = grid.build_grid_data %>

        <%= grid.render_html %>
        <%= grid.render_grid %>
        }, :layout => 'content'


    end



  def view_asset_location_transaction_history
    @asset_location_id = params[:id]
    render :inline => %{
      <!--script src = "/javascripts/cache/content_js.js"></script-->
      <% form_tag '/inventory/grouped_assets/submit_asset_location_transaction_history_search' do |f|%>
            <tr>
              <td style="border: thin black dotted;text-align: center;">Field Name</td>
              <td style="border: thin black dotted;text-align: center;">Value</td>
            </tr>
            <tr>
              <td>
                <label> created on </label>
              </td>
              <td>
                <label class="date_range_from">from:</label> <input type="text" id="created_on_datefrom_txt" name="created_on_date_from" size="20" value="" class="datepicker_from" /><br />
                <label class="date_range_to">to:</label> <input type="text" id="created_on_dateto_txt" name="created_on_date_to" size="20" value="" class="datepicker_to" />
              </td>
            </tr>            
            <tr>
              <td>
                <label style="font-weight: bold;color: blue;"> limit </label>
              </td>
              <td>
                <input type="text" id="limit" name="limit" size="30" value="1000"/>
              </td>
            </tr>
            <tr>
              <td></td>
              <td>
                <input type="hidden" id="asset_location_id" name="asset_location_id" value="<%= @asset_location_id %>" />
              </td>
            </tr>
            <tr>
              <td></td>
              <td> <button><img src='/images/exec2.png'/>execute query</button></td>
            </tr>
          </table>
      <% end %>
    }, :layout => 'content'
  end

  def submit_asset_location_transaction_history_search
    asset_locn = AssetLocation.find(params[:asset_location_id])
    if(params['created_on_date_from'].to_s.strip=="" || params['created_on_date_to'].to_s.strip=="")
      flash[:error] = 'created_on value must be filled in completely'
      params[:id] = id
      view_asset_location_transaction_history
      return
    end
    
    query = " select locations.location_code,
              inventory_transaction_assets.asset_number,
              inventory_transaction_locations.transaction_quantity,inventory_transaction_assets.created_on,

              inventory_transactions.transaction_type_code,
              inventory_transactions.transaction_quantity_minus,inventory_transactions.transaction_quantity_plus,
              inventory_transactions.location_from,inventory_transactions.location_to,inventory_transactions.transaction_business_name_code

              from asset_locations
              join inventory_transaction_locations on inventory_transaction_locations.asset_location_id = asset_locations.id
              join inventory_transaction_assets on inventory_transaction_assets.id = inventory_transaction_locations.inventoy_transaction_asset_id
              join inventory_transactions on inventory_transactions.id = inventory_transaction_assets.inventory_transaction_id
              join locations on locations.id = asset_locations.location_id

              join asset_items on asset_items.id = asset_locations.asset_item_id
              where ((locations.id = #{asset_locn.location_id})
              AND (asset_items.id = #{asset_locn.asset_item_id})
              AND (inventory_transaction_assets.created_on BETWEEN '#{params['created_on_date_from']}' AND '#{params['created_on_date_to']}'))"

    session[:query] = "@asset_location_transaction_history_pages = Paginator.new self, AssetLocation.count, @@page_size,@current_page
                       @asset_location_transaction_histories = AssetLocation.find_by_sql(\"#{query}\")"

    @asset_location_transaction_histories = AssetLocation.find_by_sql(query)
    render_found_asset_location_transaction_histories
  end


  def render_found_asset_location_transaction_histories
    if (@asset_location_transaction_histories.length > 0)

        render :inline => %{
          <% grid = build_list_asset_location_transaction_histories_grid(@asset_location_transaction_histories,@can_edit,@can_delete)%>
          <% grid.caption    = 'asset locations' %>
          <% @header_content = grid.build_grid_data %>

          <%= grid.render_html %>
          <%= grid.render_grid %>
          }, :layout => 'content'

    else
      render :inline => %{
                            <script>
                              alert('no records were found');
                              window.close();
                            </script>
                          }, :layout => 'content'
    end
  end

  def add_assets
    session[:current_location] = params[:id]
    render :inline=>%{
      <% @content_header_caption="'add assets to location: #{Location.find(session[:current_location]).location_code}'" %>
      <%= build_add_remove_assets_form(@asset_item,'add_qty_to_location','add',true) %>
    }, :layout => 'content'
  end

  def add_qty_to_location
    @location = Location.find(session[:current_location])#AssetLocation.find_by_asset_item_id_and_location_id(session[:current_asset_item],session[:current_location])#
#    if (@location.location_maximum_units == nil)
#      @freeze_flash  = true
#      flash[:notice] = build_error_div("Validation failed: location maximum units has a null value - WHAT TO DO-Hans")
#      params[:id]    = @location.id
#      add_assets
#      return
#    elsif ((@location.units_in_location + params[:asset_item][:quantity_received].to_i) > @location.location_maximum_units)
#      flash[:notice] = build_error_div("Validation failed: location maximum units is exceeded")
#      params[:id]    = @location.id
#      add_assets
#      return
    if (params[:asset_item][:bus_transaction_type] == "")
      flash[:notice] = build_error_div("Validation failed: please select a value for field bus_transaction_type")
      params[:id]    = @location.id
      add_assets
      return
    elsif (params[:asset_item][:quantity_received].to_i < 0)
      flash[:notice] = build_error_div("Validation failed: :quantity_received cannot be negative")
      params[:id]    = @location.id
      add_assets
      return
    end


#    farm                                    = Farm.find_by_farm_code(params[:asset_item][:farm_code])
    inventory_receipt_type                  = InventoryReceiptType.find_by_inventory_receipt_type_code('asset_maintenance') #HARD-CODED - Hans???

    inventory_receipt                       = InventoryReceipt.new({:receipt_date_time=>Time.now.to_formatted_s(:db),
                                                                    :quantity_received=>params[:asset_item][:quantity_received].to_i, :quantity_on_farms=>params[:asset_item][:quantity_on_farms],
                                                                    :truck_code       =>params[:asset_item][:truck_code], :reference_number=>params[:asset_item][:reference_number],
                                                                    :comments         =>params[:asset_item][:comments], :inventory_receipt_type_id=>inventory_receipt_type.id})

    #	----------------------
    #	 Define lookup fields
    #	----------------------
    transaction_type                        = TransactionType.find_by_transaction_type_code('add_asset_quantity')
    transaction_business_name               = TransactionBusinessName.find_by_transaction_business_name_code(params[:asset_item][:bus_transaction_type])

    inventory_transaction                   = InventoryTransaction.new({:transaction_type_code         =>transaction_type.transaction_type_code, :transaction_type_id=>transaction_type.id,
                                                                        :transaction_business_name_code=>params[:asset_item][:bus_transaction_type], :transaction_business_name_id=>transaction_business_name.id,
                                                                        :location_to                   =>@location.location_code, :transaction_quantity_plus=>params[:asset_item][:quantity_received].to_i,
                                                                        :transaction_date_time         =>Time.now.to_formatted_s(:db), :reference_number=>params[:asset_item][:reference_number]
                                                                        #:inventory_receipt_id=>inventory_receipt.id,#Remove - Done internally
                                                                       })
    inventory_transaction.inventory_receipt = inventory_receipt
    params[:id] = session[:current_location]
    session[:current_location]              = nil

    asset_item                              = AssetItem.find(session[:current_asset_item])
    begin
      Inventory::ChangeAssetClassQuantity.new(asset_item, inventory_transaction).process
      render :inline=>%{
          <script>
            window.opener.frames[1].location.href = '/inventory/grouped_assets/edit_asset_class/<%=session[:current_asset_item]%>';
            window.close();
          </script>
        }
    rescue
      flash[:notice] = build_error_div($!.to_s)      
      add_assets
      return
    end
  end

  def remove_assets
    session[:current_location] = params[:id]
    render :inline=>%{
      <% @content_header_caption="'remove assets from location: #{Location.find(session[:current_location]).location_code}'" %>
      <%= build_add_remove_assets_form(@asset_item,'remove_qty_from_location','remove',false) %>
    }, :layout => 'content'
  end

  def remove_qty_from_location
    @location = Location.find(session[:current_location])
    @asset_item_location = AssetLocation.find_by_asset_item_id_and_location_id(session[:current_asset_item],session[:current_location])
#    if (@location.location_maximum_units == nil)
#      @freeze_flash  = true
#      flash[:notice] = build_error_div("Validation failed: location maximum units has a null value - WHAT TO DO : IS this check necessary??-Hans")
#      params[:id]    = @location.id
#      remove_assets
#      return
    if ((@asset_item_location.location_quantity < params[:asset_item][:quantity_removed].to_i))
      flash[:notice] = build_error_div("Validation failed: quantity to be removed[#{params[:asset_item][:quantity_removed]}] exceeds qty in location[#{@asset_item_location.location_quantity}]")
      params[:id]    = @location.id
      remove_assets
      return
    elsif (params[:asset_item][:bus_transaction_type] == "")
      flash[:notice] = build_error_div("Validation failed: please select a value for field bus_transaction_type")
      params[:id]    = @location.id
      remove_assets
      return
    elsif (params[:asset_item][:quantity_removed].to_i < 0)
      flash[:notice] = build_error_div("Validation failed: :quantity_removed cannot be negative")
      params[:id]    = @location.id
      remove_assets
      return
    end

#    farm                                  = Farm.find_by_farm_code(params[:asset_item][:farm_code])
    inventory_issue                       = InventoryIssue.new({:issue_date_time=>Time.now.to_formatted_s(:db),
                                                                :quantity_issued  =>params[:asset_item][:quantity_removed].to_i,
                                                                :reference_number =>params[:asset_item][:reference_number],
                                                                :quantity_on_farms=>params[:asset_item][:quantity_on_farms],
                                                                :truck_code       =>params[:asset_item][:truck_code], :comments=>params[:asset_item][:comments]
                                                               })

    #	----------------------
    #	 Define lookup fields
    #	----------------------
    transaction_type                      = TransactionType.find_by_transaction_type_code('remove_asset_quantity')
    transaction_business_name             = TransactionBusinessName.find_by_transaction_business_name_code(params[:asset_item][:bus_transaction_type])

    inventory_transaction                 = InventoryTransaction.new({:transaction_type_code         =>transaction_type.transaction_type_code, :transaction_type_id=>transaction_type.id,
                                                                      :transaction_business_name_code=>params[:asset_item][:bus_transaction_type], :transaction_business_name_id=>transaction_business_name.id,
                                                                      :location_to                   =>@location.location_code, :transaction_quantity_minus=>params[:asset_item][:quantity_removed].to_i,
                                                                      :transaction_date_time         =>Time.now.to_formatted_s(:db), :reference_number=>params[:asset_item][:reference_number]
                                                                     })
    inventory_transaction.inventory_issue = inventory_issue

    session[:current_location]            = nil

    asset_item                            = AssetItem.find(session[:current_asset_item])
    begin
      Inventory::ChangeAssetClassQuantity.new(asset_item, inventory_transaction).process
      render :inline=>%{
          <script>
            window.opener.frames[1].location.href = '/inventory/grouped_assets/edit_asset_class/<%=session[:current_asset_item]%>';
            window.close();
          </script>
        }
    rescue
      flash[:notice] = build_error_div($!.to_s)
      remove_assets
      return
    end
  end

  def move_asset_quantity
    session[:current_location] = params[:id]
    render :inline=>%{
      <% @content_header_caption="'move assets from location: #{Location.find(session[:current_location]).location_code}'" %>
      <%= build_move_assets_form(@asset_item,'move_qty_to_location','move') %>
    }, :layout => 'content'
  end

  def move_qty_to_location
    @location = Location.find(session[:current_location])
    @asset_item_location = AssetLocation.find_by_asset_item_id_and_location_id(session[:current_asset_item],session[:current_location])
#    if (@asset_item_location.location_maximum_units == nil)
#      @freeze_flash  = true
#      flash[:notice] = build_error_div("Validation failed: location maximum units has a null value - WHAT TO DO : IS this check necessary??-Hans")
#      params[:id]    = @asset_item_location.id
#      move_asset_quantity
#      return
    if false# ((@asset_item_location.location_quantity < params[:asset_item][:qty_to_move].to_i))
      flash[:notice] = build_error_div("Validation failed: quantity to move[#{params[:asset_item][:qty_to_move]}] ecxceedes qty in location[#{@asset_item_location.location_quantity}]")
      params[:id]    = @location.id
      move_asset_quantity
      return
    elsif (params[:asset_item][:bus_transaction_type] == "")
      flash[:notice] = build_error_div("Validation failed: please select a value for field bus_transaction_type")
      params[:id]    = @location.id
      move_asset_quantity
      return
    elsif (params[:asset_item][:qty_to_move].to_i < 0)
      flash[:notice] = build_error_div("Validation failed: qty_to_move cannot be negative")
      params[:id]    = @location.id
      move_asset_quantity
      return
    end

    #	----------------------
    #	 Define lookup fields
    #	----------------------
    transaction_type           = TransactionType.find_by_transaction_type_code('move_asset_quantity')
    transaction_business_name  = TransactionBusinessName.find_by_transaction_business_name_code(params[:asset_item][:bus_transaction_type])

    inventory_transaction      = InventoryTransaction.new({:transaction_type_code         =>transaction_type.transaction_type_code, :transaction_type_id=>transaction_type.id,
                                                           :transaction_business_name_code=>params[:asset_item][:bus_transaction_type], :transaction_business_name_id=>transaction_business_name.id,
                                                           :location_from                 =>@location.location_code, :location_to=>params[:asset_item][:to_location],
                                                           :truck_licence_number       =>params[:asset_item][:truck_code],:transaction_quantity_plus=>params[:asset_item][:qty_to_move].to_i,
                                                           :transaction_date_time         =>Time.now.to_formatted_s(:db), :reference_number=>params[:asset_item][:reference_number],
                                                           :comments=>params[:asset_item][:comments]
                                                          })

    asset_item                 = AssetItem.find(session[:current_asset_item])
    begin
      Inventory::MoveAssetClass.new(asset_item, inventory_transaction).process

      if(params[:asset_item][:bus_transaction_type].to_s.upcase == "INTAKE_DELIVERY")
        delivery = Delivery.find_by_delivery_number(params[:asset_item][:reference_number])
        if(delivery)
          delivery_route_step = DeliveryRouteStep.find_by_route_step_code_and_delivery_id("empty_bins_loaded", delivery.id)
          delivery_route_step.update_attributes({:date_activated=>DateTime.now,:date_completed=>DateTime.now}) if(delivery_route_step)
        end
      end
      render :inline=>%{
          <script>
            window.opener.frames[1].location.href = '/inventory/grouped_assets/edit_asset_class/<%=session[:current_asset_item]%>';
            window.close();
          </script>
        }
    rescue
      flash[:notice] = build_error_div($!.to_s)
      params[:id] = session[:current_location]
      move_asset_quantity
      return
    end
    session[:current_location] = nil
    puts "IT ERADICATES"
  end

  def view_stock
    @asset_item_id = session[:current_asset_item]
    @stock         = Bin.find_by_sql("select * from bins
                              JOIN asset_items ON bins.bin_number = asset_items.asset_number
                              JOIN asset_locations ON asset_items.id = asset_locations.asset_item_id
                              where asset_items.id = #{@asset_item_id}")
    if (@stock.length > 0)
      render :inline => %{
      <% grid = build_view_stock_grid(@stock)%>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
    else
      render :inline => %{
                            <script>
                              alert('no records were found');
                              window.close();
                            </script>
                          }, :layout => 'content'
    end
  end

  def delete_asset_class
    asset_item = AssetItem.find(params[:id])
    asset_locn_quantities = 0
    asset_item.asset_locations.map{|asset_locn| (asset_locn_quantities += asset_locn.location_quantity)}
    if(asset_locn_quantities == 0)
      if(asset_item.destroy)
        flash[:notice] = "asset class record deleted successfully"
      else
        flash[:error] = "could not delete asset class record"
      end      
    else
      flash[:error] = "could not delete asset class record: this asset has already been distributed to some locations"
    end
    render :inline => %{}, :layout => 'content'
  end

  def view_bins_moved_report
#    delivery = Delivery.find_by_delivery_number(params[:id].split("!")[0])
#    report_parameters= "output=pdf&delivery_id=#{delivery.id}"

    report_unit ="reportUnit=/RMT/Bins_Moved&"
    report_parameters= "output=pdf&inventory_transaction_id=#{params[:id]}"
    @url = Globals.get_jasper_server_report_server_ip + Globals.get_jasper_server + report_unit +Globals.get_jasperserver_username_password +  report_parameters

    render :inline => %{
              <script>
                window.location.href = "<%= @url %>";
              </script>
      }, :layout => 'content'
  end

  def view_bins_removed_report
    report_unit ="reportUnit=/RMT/Bins_Issued&"
    report_parameters= "output=pdf&inventory_transaction_id=#{params[:id]}"
    @url = Globals.get_jasper_server_report_server_ip + Globals.get_jasper_server + report_unit +Globals.get_jasperserver_username_password +  report_parameters

    render :inline => %{
              <script>
                window.location.href = "<%= @url %>";
              </script>
      }, :layout => 'content'
  end

  def view_bins_added_report
    report_unit ="reportUnit=/RMT/Bins_Received&"
    report_parameters= "output=pdf&inventory_transaction_id=#{params[:id]}"
    @url = Globals.get_jasper_server_report_server_ip + Globals.get_jasper_server + report_unit +Globals.get_jasperserver_username_password +  report_parameters

    render :inline => %{
              <script>
                window.location.href = "<%= @url %>";
              </script>
      }, :layout => 'content'
  end

  def view_latest_asset_transaction
    query = "
      select inventory_transactions.*,inventory_transactions.id as inventory_transaction_id
      from inventory_transactions
          JOIN asset_items ON asset_items.inventory_transaction_id=inventory_transactions.id
      where asset_items.id=#{session[:current_asset_item]}
    "
    session[:query] = "@transaction_history_pages = Paginator.new self, InventoryTransaction.count, @@page_size,@current_page
                       @transaction_histories = InventoryTransaction.find_by_sql(\"#{query}\")" 
    inventory_transaction = InventoryTransaction.find_by_sql(query)

    @transaction_histories = Array.new
    inventory_transaction.map{|o| @transaction_histories.push(o.attributes)}
    if (@transaction_histories.length > 0)
      render_found_transaction_histories
    end
  end

  def search_stock_transaction_histories
    render :inline => %{
      <% @content_header_caption="'search stock transaction histories" %>
      <%= build_stock_transaction_histories_search_form(@inventory_transaction,'list_stock_transaction_histories','find') %>
      }, :layout => 'content'
  end

  def list_stock_transaction_histories
    if(params[:inventory_transaction][:transaction_date_time_date2from].to_s.strip=="" || params[:inventory_transaction][:transaction_date_time_date2to].to_s.strip=="")
      flash[:error] = 'transaction_date_time must be filled in completely'
      params[:id] = id
      search_stock_transaction_histories
      return
    end

    location_code = ""
    if(params[:inventory_transaction][:location_code].to_s.strip !="")
      location_code = "AND (inventory_transactions.location_to  = '#{params[:inventory_transaction][:location_code]}' OR inventory_transactions.location_from  = '#{params[:inventory_transaction][:location_code]}')"
    end

    inventoy_reference = ""
    if(params[:inventory_transaction][:inventory_reference].to_s.strip !="")
      inventoy_reference = "AND (stock_items.inventory_reference  = '#{params[:inventory_transaction][:inventory_reference]}')"
    end

    stock_type_code = ""
   if(params[:inventory_transaction][:stock_type_code].to_s.strip !="")
      stock_type_code = "AND (stock_items.stock_type_code  = '#{params[:inventory_transaction][:stock_type_code]}')"
   end

   transaction_business_name_code = ""
   if(params[:inventory_transaction][:transaction_business_name_code].to_s.strip !="")
     transaction_business_name_code = "AND (inventory_transactions.transaction_business_name_code = '#{params[:inventory_transaction][:transaction_business_name_code]}')"
   end

   transaction_type_code = ""
   if(params[:inventory_transaction][:transaction_type_code].to_s.strip !="")
     transaction_type_code = "AND (inventory_transactions.transaction_type_code  = '#{params[:inventory_transaction][:transaction_type_code]}')"
   end

   pack_material_product_code = ""
   if(params[:inventory_transaction][:pack_material_product_code].to_s.strip !="")
     pack_material_product_code = "AND (pack_material_products.pack_material_product_code = '#{params[:inventory_transaction][:pack_material_product_code]}')"
   end

    query = "
      (select inventory_transactions.location_to,inventory_transactions.reference_number,inventory_transactions.transaction_business_name_code,inventory_transactions.transaction_date_time,inventory_transactions.transaction_quantity_minus,inventory_transactions.transaction_quantity_plus,inventory_transactions.transaction_type_code,
      inventory_transaction_stocks.location_from
      ,stock_items.stock_type_code,stock_items.inventory_reference ,pack_material_products.pack_material_product_code

      from inventory_transaction_stocks
      join inventory_transactions on inventory_transactions.id = inventory_transaction_stocks.inventory_transaction_id
      join stock_items on stock_items.id = inventory_transaction_stocks.stock_item_id
      join bins on bins.bin_number = stock_items.inventory_reference
      join pack_material_products on pack_material_products.id = bins.pack_material_product_id

      where (
       (inventory_transactions.transaction_date_time BETWEEN '#{params[:inventory_transaction][:transaction_date_time_date2from]}' AND '#{params[:inventory_transaction][:transaction_date_time_date2to]}')
      #{location_code}
      #{stock_type_code}
      #{inventoy_reference}
      #{transaction_business_name_code}
      #{transaction_type_code}
      #{pack_material_product_code}
      )
      ORDER BY inventory_transactions.transaction_date_time ASC
      )
      "
    puts "NKWILI : #{query}"
    @inventory_transactions = InventoryTransaction.find_by_sql(query)
    render_list_stock_transaction_histories
  end

  def render_list_stock_transaction_histories
    if (@inventory_transactions.length > 0)
     @content_header_caption           = "''"
     render :inline => %{
      <% grid = build_list_stock_transaction_histories_grid(@inventory_transactions)%>
      <% grid.caption    = 'stock transactions history' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
    else
      render :inline => %{
                            <script>
                              alert('no records were found');
                              window.close();
                            </script>
                          }, :layout => 'content'
    end
  end

  def search_stock_locations_histories
    return if authorise_for_web(program_name?, 'read')== false

    dm_session[:parameter_fields_values] = nil
    dm_session['se_layout']              = 'content'
    @content_header_caption           = "'search stock locations histories'"
    dm_session[:redirect]                = true
    build_remote_search_engine_form("search_stock_locations_histories.yml", "submit_stock_locations_histories_search")
  end

  def submit_stock_locations_histories_search
    @stock_locations_histories = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    if (@stock_locations_histories.length > 0)
      render_found_stock_locations_histories
    else
      render :inline => %{
                            <script>
                              alert('no records were found');
                              window.close();
                            </script>
                          }, :layout => 'content'
    end
  end

  def render_found_stock_locations_histories
    @can_edit   = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])

    session[:query] = "@stock_locations_history_pages = Paginator.new self, StockLocationsHistory.count, @@page_size,@current_page
                       @stock_locations_histories = StockLocationsHistory.find_by_sql(dm_session[:search_engine_query_definition])"

     @content_header_caption           = "''"
     render :inline => %{
          <% grid = build_stock_locations_histories_grid(@stock_locations_histories,@can_edit,@can_delete)%>
          <% grid.caption    = 'stock_locations_histories' %>
          <% @header_content = grid.build_grid_data %>

          <%= grid.render_html %>
          <%= grid.render_grid %>
          }, :layout => 'content'
  end

  def reprocess_failed_assets_moves

    #puts Dir.getwd + "/run_failed_move_assets_reprocess.sh"

    file_name = "run_failed_move_assets_reprocess_" + Time.now.strftime("%m_%d_%Y_%H_%M_%S") + ".sh"
    file = File.new(file_name, "w")
    file.puts "cd #{Dir.getwd}/run_failed_move_assets_reprocess.sh"
    file.puts "ruby script/runner 'load \"failed_move_assets_reprocess.rb\"' 1 false"
    file.close

    @result = eval "\` sh " + file_name + "\`"
    File.delete file_name

    @progress = []
    render :inline => %{
          <% @content_header_caption = "'FAILED ASSET MOVE PROGRESS'"%>
          <%= @result %>
          }, :layout => 'content'
  end

end