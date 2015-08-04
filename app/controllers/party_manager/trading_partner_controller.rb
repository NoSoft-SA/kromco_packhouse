class PartyManager::TradingPartnerController < ApplicationController

  def program_name?
    "trade"
  end

  def bypass_generic_security?
    true
  end

  def list_trading_partners
    return if authorise_for_web(program_name?, 'read') == false

    if params[:page]!= nil

      session[:trading_partners_page] = params['page']

      render_list_trading_partners

      return
    else
      session[:trading_partners_page] = nil
    end

    list_query = "select trading_partners.*,currencies.currency_code,incoterms.incoterm_code,parties_roles.party_type_name as party,parties_roles.party_name as trading_partner_name,target_markets.target_market_code,users.user_name as marketer, dfpt_levy_types.dfpt_levy_type_code
               from trading_partners
               inner join parties_roles on trading_partners.parties_role_id=parties_roles.id
               left join incoterms on trading_partners.incoterm_id=incoterms.id
               left join currencies on trading_partners.currency_id=currencies.id
               left join target_markets on trading_partners.target_market_id=target_markets.id
		     left join dfpt_levy_types on dfpt_levy_types.id = trading_partners.dfpt_levy_type_id
               left join users on trading_partners.marketer_user_id=users.id
               order by trading_partners.id desc"

    session[:query]="ActiveRecord::Base.connection.select_all(\"#{list_query}\")"

    render_list_trading_partners
  end


  def render_list_trading_partners
    @pagination_server = "list_trading_partners"
    @can_edit = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])
    @current_page = session[:trading_partners_page]
    @current_page = params['page']||= session[:trading_partners_page]
    @trading_partners = eval(session[:query]) if !@trading_partners
    @use_jq_grid = true

    render :inline => %{
		<% grid = build_trading_partner_grid(@trading_partners,@can_edit,@can_delete)%>
		<% grid.caption = 'list of all trading_partners'%>
		<% @header_content = grid.build_grid_data %>

		<% @pagination = pagination_links(@trading_partner_pages) if @trading_partner_pages != nil %>
		<%= grid.render_html %>
		<%= grid.render_grid %>
	}, :layout => 'content'
  end

  def search_trading_partners_flat
    return if authorise_for_web(program_name?, 'read')== false
    @is_flat_search = true
    render_trading_partner_search_form
  end

  def render_trading_partner_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
    render :inline => %{
		<% @content_header_caption = "'search  trading_partners'"%> 

		<%= build_trading_partner_search_form(nil,'submit_trading_partners_search','submit_trading_partners_search',@is_flat_search)%>

		}, :layout => 'content'
  end

  def search_trading_partners_hierarchy
    return if authorise_for_web(program_name?, 'read')== false

    @is_flat_search = false
    render_trading_partner_search_form(true)
  end


  def submit_trading_partners_search
    @trading_partners = dynamic_search(params[:trading_partner], 'trading_partners', 'TradingPartner')
    if @trading_partners.length == 0
      flash[:notice] = 'no records were found for the query'
      @is_flat_search = session[:is_flat_search].to_s
      render_trading_partner_search_form
    else
      render_list_trading_partners
    end
  end


  def delete_trading_partner
    begin
      return if authorise_for_web(program_name?, 'delete')== false
      if params[:page]
        session[:trading_partners_page] = params['page']
        render_list_trading_partners
        return
      end
      id = params[:id]
      if id && trading_partner = TradingPartner.find(id)
        trading_partner.destroy
        session[:alert] = ' Record deleted.'
        render_list_trading_partners
      end
    rescue
      handle_error('record could not be deleted')
    end
  end

  def new_trading_partner
    return if authorise_for_web(program_name?, 'create')== false
    render_new_trading_partner
  end

  def create_trading_partner
    begin
      if params[:trading_partner][:party_type_name]== ""
        params[:trading_partner][:party_type_name]=nil
      end
      if params[:trading_partner][:incoterm_id]== ""
        params[:trading_partner][:incoterm_id]=nil
      end
      if params[:trading_partner][:currency_id]== ""
        params[:trading_partner][:currency_id]=nil
      end
      if params[:trading_partner][:contact_name]== ""

      end
      if params[:trading_partner][:target_market_id]== ""
        params[:trading_partner][:target_market_id]=nil
      end
      if params[:trading_partner][:dfpt_levy_type_id]== ""
        params[:trading_partner][:dfpt_levy_type_id]=nil
      end
      if params[:trading_partner][:marketer_user_id]== ""
        params[:trading_partner][:marketer_user_id]=nil
      end
      if params[:trading_partner][:trading_partner_name]== "" || params[:trading_partner][:trading_partner_name]==""
        params[:trading_partner][:trading_partner_name]=nil
      end

      if params[:trading_partner][:party_type_name]==nil ||
          params[:trading_partner][:trading_partner_name]==nil # ||
                                                               #params[:trading_partner][:incoterm_id]=="" ||
                                                               #params[:trading_partner][:currency_id]==nil||
                                                               #params[:trading_partner][:target_market_id]==nil ||
                                                               #params[:trading_partner][:marketer_user_id]==nil
        @trading_partner = TradingPartner.new
        @trading_partner.party_type_name = params[:trading_partner][:party_type_name]
        @trading_partner.trading_partner_name = params[:trading_partner][:trading_partner_name]
        @trading_partner.incoterm_id = params[:trading_partner][:incoterm_id]
        @trading_partner.currency_id = params[:trading_partner][:currency_id]
        @trading_partner.target_market_id = params[:trading_partner][:target_market_id]
        @trading_partner.dfpt_levy_type_id = params[:trading_partner][:dfpt_levy_type_id]	
        @trading_partner.marketer_user_id = params[:trading_partner][:marketer_user_id]
        @trading_partner.remarks = params[:trading_partner][:remarks]
        @is_create_retry=true
        flash[:error]= "all fields in bold are required "
        new_trading_partner and return
                                                               #render :inline => %{<script>
                                                               #       location.href = '/party_manager/trading_partner/new_trading_partner/;
                                                               #      </script>} and return
      end
      trading_partner=TradingPartner.find_by_parties_role_id(params[:trading_partner][:parties_role_id])
              if trading_partner
                flash[:error]= ":trading_partner_name #{params[:trading_partner][:trading_partner_name]}, already exists"
                @is_create_retry = true
                render_new_trading_partner and return
              end
      ActiveRecord::Base.transaction do
        if params[:trading_partner][:party_type_name] == 'PERSON'
          if params[:trading_partner][:trading_partner_name].index(" ")|| !(params[:trading_partner][:trading_partner_name].index("_"))
            person_data = params[:trading_partner][:trading_partner_name].split(" ")
          elsif  params[:trading_partner][:trading_partner_name].index("_")
            person_data = params[:trading_partner][:trading_partner_name].split("_")
          end

          if person_data.length() < 2
            @trading_partner = TradingPartner.new
            @trading_partner.party_type_name = params[:trading_partner][:party_type_name]
            @trading_partner.trading_partner_name = params[:trading_partner][:trading_partner_name]
            @trading_partner.incoterm_id = params[:trading_partner][:incoterm_id]
            @trading_partner.currency_id = params[:trading_partner][:currency_id]
            @trading_partner.target_market_id = params[:trading_partner][:target_market_id]
            @trading_partner.dfpt_levy_type_id = params[:trading_partner][:dfpt_levy_type_id]	    
            @trading_partner.marketer_user_id = params[:trading_partner][:marketer_user_id]
            @trading_partner.remarks = params[:trading_partner][:remarks]

            flash[:error]= ":trading_partner_name,enter first_name, then a space, then last name"
            @is_create_retry=true
            new_trading_partner and return
          else
            person = Person.find_by_first_name_and_last_name(person_data[0].strip(), person_data[1].strip())
            if !person
              person = Person.create!({:first_name => person_data[0], :last_name => person_data[1]})
            end
            params[:trading_partner][:trading_partner_name].gsub!(" ", "_")
          end
        else
          org = Organization.find_by_short_description(params[:trading_partner][:trading_partner_name])
          if !org
            org = Organization.create!({:short_description => params[:trading_partner][:trading_partner_name]})
          end

        end

        parties_role = PartiesRole.find_by_party_name_and_party_type_name_and_role_name(params[:trading_partner][:trading_partner_name], params[:trading_partner][:party_type_name], 'TRADING PARTNER')
        if !parties_role
          # parties_role = PartiesRole.create!({:party_type_name => self.party_type_name,:party_name => self.trading_partner_name,:role_name => 'TRADING PARTNER' })
          parties_role = PartiesRole.new
          parties_role.party_type_name=params[:trading_partner][:party_type_name]
          parties_role.party_name= params[:trading_partner][:trading_partner_name]
          parties_role.role_name ='TRADING PARTNER'
          parties_role.save
        end

        params[:trading_partner][:parties_role_id] = parties_role.id

#----------------------------------------------------------------------------------



        @trading_partner = TradingPartner.new(params[:trading_partner])
        @trading_partner.save
      end
      if @trading_partner

        redirect_to_index("'new record created successfully'", "'create successful'")
      else
        @is_create_retry = true
        render_new_trading_partner
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def render_new_trading_partner
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'create new trading_partner'"%> 

		<%= build_trading_partner_form(@trading_partner,'create_trading_partner','create_trading_partner',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def edit_trading_partner
    return if authorise_for_web(program_name?, 'edit')==false
    id = params[:id]
    if id && @trading_partner = TradingPartner.find(id)
      parties_role = PartiesRole.find(@trading_partner.parties_role_id)
      @trading_partner.trading_partner_name = parties_role.party_name
      @trading_partner.party_type_name = parties_role.party_type_name
      session[:edit_trading_partner]=@trading_partner

      render_edit_trading_partner

    end
  end


  def render_edit_trading_partner
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'edit trading_partner'"%> 

		<%= build_trading_partner_form(@trading_partner,'update_trading_partner','update_trading_partner',true)%>

		}, :layout => 'content'
  end

  def update_trading_partner
    begin

      id = params[:trading_partner][:id]
      if params[:trading_partner][:party_type_name]== ""
        params[:trading_partner][:party_type_name]=nil
      end
      if params[:trading_partner][:incoterm_id]== ""
        params[:trading_partner][:incoterm_id]=nil
      end
      if params[:trading_partner][:currency_id]== ""
        params[:trading_partner][:currency_id]=nil
      end
      if params[:trading_partner][:contact_name]== ""

      end
      if params[:trading_partner][:target_market_id]== ""
        params[:trading_partner][:target_market_id]=nil
     end
      if params[:trading_partner][:dfpt_type_levy_id]== ""
        params[:trading_partner][:dfpt_type_levy_id]=nil
      end
      if params[:trading_partner][:marketer_user_id]== ""
        params[:trading_partner][:marketer_user_id]=nil
      end
      if params[:trading_partner][:trading_partner_name]== "" || params[:trading_partner][:trading_partner_name]==""
        params[:trading_partner][:trading_partner_name]=nil
      end

      if params[:trading_partner][:party_type_name]==nil ||
          params[:trading_partner][:trading_partner_name]==nil # ||
        @trading_partner = TradingPartner.find(id)
        parties_role = PartiesRole.find(@trading_partner.parties_role_id)
        @trading_partner.trading_partner_name = parties_role.party_name
        @trading_partner.party_type_name = parties_role.party_type_name
        @is_create_retry=true
        flash[:error]= "all fields in bold are required "
        render_edit_trading_partner and return

      end
      #----------------------------------------
      ActiveRecord::Base.transaction do
      @trading_partner =session[:edit_trading_partner]

      if params[:trading_partner][:party_type_name] == 'PERSON'
        #-----------------validate name--------------------------------------
        if params[:trading_partner][:trading_partner_name].index(" ")|| !(params[:trading_partner][:trading_partner_name].index("_"))
          person_data_1 = params[:trading_partner][:trading_partner_name].split(" ")
        elsif  params[:trading_partner][:trading_partner_name].index("_")
          person_data_1 = params[:trading_partner][:trading_partner_name].split("_")
        end
        if person_data_1.length() < 2
          @trading_partner
          flash[:error]= ":trading_partner_name,enter first_name, then a space, then last name"
          @is_create_retry=true
          render_edit_trading_partner and return
        end
        params[:trading_partner][:trading_partner_name].gsub!(" ", "_")
        #--------------------------------------------------------------------
        if session[:edit_trading_partner].trading_partner_name.index(" ")|| !(session[:edit_trading_partner].trading_partner_name.index("_"))
          person_data = session[:edit_trading_partner].trading_partner_name.split(" ")
        elsif  session[:edit_trading_partner].trading_partner_name.index("_")
          person_data = session[:edit_trading_partner].trading_partner_name.split("_")
        end
        person = Person.find_by_first_name_and_last_name(person_data[0].strip(), person_data[1].strip())
        person.first_name=person_data_1[0]
        person.last_name=person_data_1[1]
        person.update
      else
        org = Organization.find_by_short_description(session[:edit_trading_partner].trading_partner_name)
        org.short_description=params[:trading_partner][:trading_partner_name]
        org.update

      end
      party=Party.find_by_party_name_and_party_type_name(session[:edit_trading_partner].trading_partner_name, session[:edit_trading_partner].party_type_name)
      party.party_name=params[:trading_partner][:trading_partner_name]
      party.save

      @trading_partner.update_attributes(params[:trading_partner])

      end

      #-----------------------------------------
      session[:edit_trading_partner]=nil
      list_trading_partners


    rescue
      handle_error('record could not be saved')
    end
  end


  def trading_partner_id_changed
    id = get_selected_combo_value(params)
    session[:trading_partner_form][:id_combo_selection] = id
    @role_names = TradingPartner.role_names_for_id(id)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
    render :inline => %{
		<%= select('trading_partner','role_name',@role_names)%>

		}

  end


#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(trading_partners)
#	-----------------------------------------------------------------------------------------------------------

end
